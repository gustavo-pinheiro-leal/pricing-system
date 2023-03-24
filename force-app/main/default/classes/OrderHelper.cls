public with sharing class OrderHelper {
    public OrderHelper() {}

    public static void checkError(Map<Id, Order> oldRecords, Map<Id, Order> newRecords){
        for(Order order : newRecords.values()){
            Order oldRecord = oldRecords.get(order.Id);

            if(order.AccountId != oldRecord.AccountId){
                order.addError('A conta não pode ser alterada.');
            }

            if(oldRecord.Status == 'Activated'){
                order.addError('O status do pedido está ativo, portanto não pode mais ser alterado.');
            }
        }
    }

    public static List<OrderItem> checkRecalcItems(Map<Id, Order> oldRecords, Map<Id, Order> newRecords){
        Set<Id> orderIds = new Set<Id>();

        for(Order order : newRecords.values()){
            Order oldRecord = oldRecords.get(order.Id);

            Boolean parametersAreDifferent = ((order.DistributionCenter__c != oldRecord.DistributionCenter__c) ||
                                              (order.AccountAddress__c != oldRecord.AccountAddress__c));

            if(parametersAreDifferent){
                orderIds.add(order.Id);
            }
        }

        List<OrderItem> orderItemList = [
            SELECT Id, OrderId, Product2Id, TaxPercentage__c, Product2.ProductHierarchy__c
            FROM OrderItem
            WHERE OrderId IN: orderIds
        ];

        List<OrderItem> updatedOrderItemList = OrderItemHelper.taxSelection(orderItemList);
        updatedOrderItemList =  OrderItemHelper.freightSelection(updatedOrderItemList);
        updatedOrderItemList =  OrderItemHelper.marginSelection(updatedOrderItemList);

        return updatedOrderItemList;
    }
}
