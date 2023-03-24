public with sharing class OrderItemHelper {
    public OrderItemHelper() {}

    public static void checkError(List<OrderItem> orderItemList){
        Set<Id> orderIds = new Set<Id>();

        for(OrderItem orderItem : orderItemList){
            orderIds.add(orderItem.OrderId);
        }

        List<Order> orderList = [
            SELECT Id, Status
            FROM Order
            WHERE Id IN: orderIds
        ];

        for(OrderItem orderItem : orderItemList){
            if(orderItem.Quantity <= 0 ){
                orderItem.addError('Quantidade deve ser maior que zero');
            }
            else if(orderItem.UnitPrice <= 0 ){
                orderItem.addError('Preço deve ser maior que zero');
            }

            if(orderItem.TaxPercentage__c == null || orderItem.FreightValue__c == null || orderItem.PercentageMargin__c == null){
                orderItem.addError('Não está autorizada a venda deste produto devido a falta de parâmetros, contactar o time de pricing.');
            }

            for(Order order : orderList){
                if(orderItem.OrderId == order.Id && order.Status == 'Activated'){
                    orderItem.addError('O status do pedido está ativo, portanto não pode mais ser alterado');
                }
            }
        }
    }

    public static List<OrderItem> taxSelection(List<OrderItem> orderItemList){
        Map<Id, Order> orderMap = getOrders(orderItemList);

        List<Product2> productList = getProducts(orderItemList);

        Map<OrderItem, Tax__c> orderItemToTax = searchTax(orderItemList, orderMap, productList);

        for(OrderItem orderItem : orderItemToTax.keySet()){
            Tax__c tax = orderItemToTax.get(orderItem);

            if(tax != null){
                orderItem.TaxPercentage__c = tax.TaxOverCost__c;
            }
        }

        return new List<OrderItem>(orderItemToTax.keySet());
    }

    public static List<OrderItem> freightSelection(List<OrderItem> orderItemList){
        Map<Id, Order> orderMap = getOrders(orderItemList);

        List<Product2> productList = getProducts(orderItemList);

        Map<OrderItem, Freight__c> orderItemToFreight = searchFreight(orderItemList, orderMap, productList);

        for(OrderItem orderItem : orderItemToFreight.keySet()){
            Freight__c freight = orderItemToFreight.get(orderItem);

            if(freight != null){
                orderItem.FreightValue__c = freight.Value__c;
            }
        }

        return new List<OrderItem>(orderItemToFreight.keySet());
    }

    public static List<OrderItem> marginSelection(List<OrderItem> orderItemList){
        Map<Id, Order> orderMap = getOrders(orderItemList);

        List<Product2> productList = getProducts(orderItemList);

        Map<OrderItem, Margin__c> orderItemToMargin = searchMargin(orderItemList, orderMap, productList);

        for(OrderItem orderItem : orderItemToMargin.keySet()){
            Margin__c margin = orderItemToMargin.get(orderItem);

            if(margin != null){
                orderItem.PercentageMargin__c = margin.Value__c;
            }
        }

        return new List<OrderItem>(orderItemToMargin.keySet());
    }

    public static Map<OrderItem, Tax__c> searchTax (List<OrderItem> orderItemList, Map<Id, Order> orderMap, List<Product2> productList){
        Set<Id> productIds = new Set<Id>();
        Set<Id> distributionIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        for(Order order : orderMap.values()){
            distributionIds.add(order.DistributionCenter__c);
            stateIds.add(order.AccountAddress__r.City__r.State__c);
        }

        for(Product2 product : productList){
            productIds.add(product.Id);
        }

        List<Tax__c> taxList = [
            SELECT Id, Product__c, DistributionCenter__c, State__c, Status__c, TaxOverCost__c
            FROM Tax__c
            WHERE (Product__c IN: productIds) AND (DistributionCenter__c IN: distributionIds) AND (State__c IN: stateIds) AND (Status__c = 'Aprovado')
            ORDER BY TaxOverCost__c
        ];

        Map<OrderItem, Tax__c> orderItemToTax = new Map<OrderItem, Tax__c>();

        for(OrderItem orderItem : orderItemList){
            orderItemToTax.put(orderItem, null);

            for(Tax__c tax : taxList){
                if(matchTax(tax, orderItem, orderMap)){
                    orderItemToTax.put(orderItem, tax);
                    break;
                }
            }
        }

        return orderItemToTax;
    }

    public static Map<OrderItem, Freight__c> searchFreight (List<OrderItem> orderItemList, Map<Id, Order> orderMap, List<Product2> productList){
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();
        Set<Id> distributionIds = new Set<Id>();

        for(Product2 product : productList){
            productIds.add(product.Id);
            productHierarchyIds.add(product.ProductHierarchy__c);
        }

        for(Order order : orderMap.values()){
            cityIds.add(order.AccountAddress__r.City__c);
            stateIds.add(order.AccountAddress__r.City__r.State__c);
            countryIds.add(order.AccountAddress__r.City__r.State__r.Country__c);
            distributionIds.add(order.DistributionCenter__c);
        }

        List<Freight__c> freightList = [
            SELECT Id, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, Status__c, Value__c, DistributionCenter__c
            FROM Freight__c
            WHERE ((Product__c IN: productIds) OR (ProductHierarchy__c IN: productHierarchyIds)) AND ((City__c IN: cityIds) OR (State__c IN: stateIds) OR (Country__c IN: countryIds)) AND (Status__c = 'Aprovado')
            ORDER BY Value__c
        ];

        Map<OrderItem, Freight__c> orderItemToFreightMap = new Map<OrderItem, Freight__c>();

        for(OrderItem orderItem : orderItemList){
            
            orderItemToFreightMap.put(orderItem, null);
            
            List<Freight__c> selectedFreights = new List<Freight__c>();
            
            for (Freight__c freight : freightList){
                if(matchFreight(freight, orderItem, orderMap)){
                    selectedFreights.add(freight);
                }
            }
            
            Map<Freight__c, Integer> freightsWithScore = FreightHelper.calculateFreightScore(selectedFreights);

            Integer currentScore = 0;

            for (Freight__c freight : freightsWithScore.keySet()){

                Integer freightScore = freightsWithScore.get(freight);

                if(orderItemToFreightMap.get(orderItem) == null){
                    orderItemToFreightMap.put(orderItem, freight);
                    currentScore = freightScore;
                }
                else if(currentScore < freightScore){
                    orderItemToFreightMap.put(orderItem, freight);
                    currentScore = freightScore;
                }
            }
        }

        return orderItemToFreightMap;

    }

    public static Map<OrderItem, Margin__c> searchMargin (List<OrderItem> orderItemList, Map<Id, Order> orderMap, List<Product2> productList){
        Set<Id> productIds = new Set<Id>();
        Set<Id> productHierarchyIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        Set<Id> countryIds = new Set<Id>();
        Set<Id> distributionIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accountGroupIds = new Set<Id>();

        for(Product2 product : productList){
            productIds.add(product.Id);
            productHierarchyIds.add(product.ProductHierarchy__c);
        }

        for(Order order : orderMap.values()){
            cityIds.add(order.AccountAddress__r.City__c);
            stateIds.add(order.AccountAddress__r.City__r.State__c);
            countryIds.add(order.AccountAddress__r.City__r.State__r.Country__c);
            distributionIds.add(order.DistributionCenter__c);
            accountIds.add(order.AccountId);
            accountGroupIds.add(order.Account.AccountGroup__c);
        }

        List<Margin__c> marginList = [
            SELECT Id, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, Status__c, Value__c, DistributionCenter__c, Account__c, AccountGroup__c
            FROM Margin__c
            WHERE ((Product__c IN: productIds) OR (ProductHierarchy__c IN: productHierarchyIds)) AND ((Account__c IN: accountIds) OR (AccountGroup__c IN: accountGroupIds)) AND ((City__c IN: cityIds) OR (State__c IN: stateIds) OR (Country__c IN: countryIds)) AND (Status__c = 'Aprovado')
            ORDER BY Value__c
        ];

        Map<OrderItem, Margin__c> orderItemToMarginMap = new Map<OrderItem, Margin__c>();

        for(OrderItem orderItem : orderItemList){
            
            orderItemToMarginMap.put(orderItem, null);
            
            List<Margin__c> selectedMargins = new List<Margin__c>();
            
            for (Margin__c margin : marginList){
                if(matchMargin(margin, orderItem, orderMap)){
                    selectedMargins.add(margin);
                }
            }
            
            Map<Margin__c, Integer> marginsWithScore = MarginHelper.calculateMarginScore(selectedMargins);

            Integer currentScore = 0;

            for (Margin__c margin : marginsWithScore.keySet()){

                Integer marginScore = marginsWithScore.get(margin);

                if(orderItemToMarginMap.get(orderItem) == null){
                    orderItemToMarginMap.put(orderItem, margin);
                    currentScore = marginScore;
                }
                else if(currentScore < marginScore){
                    orderItemToMarginMap.put(orderItem, margin);
                    currentScore = marginScore;
                }
            }
        }

        return orderItemToMarginMap;

    }

    public static Boolean matchTax (Tax__c tax, OrderItem orderItem, Map<Id, Order> orderMap){
        return (tax.Product__c == orderItem.Product2Id) &&
            (tax.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c) &&
            (tax.State__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__r.State__c);
    }

    public static Boolean matchFreight (Freight__c freight, OrderItem orderItem, Map<Id, Order> orderMap){
        return (((freight.Product__c == orderItem.Product2Id) || (freight.ProductHierarchy__c == orderItem.Product2.ProductHierarchy__c)) && 
                ((freight.City__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__c) || 
                (freight.State__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__r.State__c) ||
                (freight.Country__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__r.State__r.Country__c)) &&
                ((freight.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c)));
    }

    public static Boolean matchMargin (Margin__c margin, OrderItem orderItem, Map<Id, Order> orderMap){
        return (((margin.Product__c == orderItem.Product2Id) || (margin.ProductHierarchy__c == orderItem.Product2.ProductHierarchy__c)) &&
                ((margin.Account__c == orderMap.get(orderItem.OrderId).AccountId || margin.AccountGroup__c == orderMap.get(orderItem.OrderId).Account.AccountGroup__c)) &&
                ((margin.City__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__c) ||
                (margin.State__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__r.State__c) ||
                (margin.Country__c == orderMap.get(orderItem.OrderId).AccountAddress__r.City__r.State__r.Country__c)) &&
                ((margin.DistributionCenter__c == orderMap.get(orderItem.OrderId).DistributionCenter__c)));
    }

    public static List<Product2> getProducts (List<OrderItem> orderItemList){
        Set<Id> productIdSet = new Set<Id>();

        for(OrderItem orderItem : orderItemList){
            productIdSet.add(orderItem.Product2Id);
        }

        List<Product2> productList = [
            SELECT Id, ProductHierarchy__c
            FROM Product2
            WHERE Id IN: productIdSet
        ];

        return productList;
    }

    public static Map<Id, Order> getOrders (List<OrderItem> orderItemList){
        Set<Id> orderIdSet = new Set<Id>();

        for(OrderItem orderItem : orderItemList){
            orderIdSet.add(orderItem.OrderId);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, DistributionCenter__c, AccountAddress__r.City__r.State__c, AccountAddress__r.City__c, AccountAddress__r.City__r.State__r.Country__c, AccountId, Account.AccountGroup__c
            FROM Order
            WHERE Id IN: orderIdSet
        ]);

        return orderMap;
    }
}
