public with sharing class FreightHelper {
    public FreightHelper() {}

    public static void validateFreight(List<Freight__c> freightList){
        for(Freight__c freight : freightList){

            String message = '';

            if(!validateFreightLocationParameters(freight)){
                message += '-- Selecione UM pais OU UM estado OU UMA cidade';
            }
            if(!validateFreightProductParameters(freight)){
                message += '-- Selecione UM produto OU UMA hierarquia de produto';
            }

            if(String.isNotEmpty(message)){
                freight.addError(message);
            }
        }
    }

    public static Boolean validateFreightProductParameters(Freight__c freight){
        if((String.isBlank(freight.ProductHierarchy__c) && String.isBlank(freight.Product__c)) ||
           (String.isNotBlank(freight.ProductHierarchy__c) && String.isNotBlank(freight.Product__c))){
            return false;
        }

        return true;
    }

    public static Boolean validateFreightLocationParameters(Freight__c freight){
        if((String.isBlank(freight.Country__c) && String.isBlank(freight.State__c) && String.isBlank(freight.City__c)) ||
        (String.isNotBlank(freight.Country__c) && String.isNotBlank(freight.State__c) && String.isNotBlank(freight.City__c)) ||
        (String.isBlank(freight.Country__c) && String.isNotBlank(freight.State__c) && String.isNotBlank(freight.City__c)) ||
        (String.isNotBlank(freight.Country__c) && String.isBlank(freight.State__c) && String.isNotBlank(freight.City__c)) ||
        (String.isNotBlank(freight.Country__c) && String.isNotBlank(freight.State__c) && String.isBlank(freight.City__c))){
            return false;
        }

        return true;
    }

    public static Map<Freight__c, Integer> calculateFreightScore(List<Freight__c> freightList){
        Map<Freight__c, Integer> freightToScoreMap = new Map <Freight__c, Integer>();

        for(Freight__c freight : freightList){
            Integer score = 0;

            if(String.isNotEmpty(freight.Product__c)){
                score += 2000;
            }
            else if(String.isNotEmpty(freight.ProductHierarchy__c)){
                score += 1000;
            }

            if(String.isNotEmpty(freight.City__c)){
                score += 30;
            }
            else if(String.isNotEmpty(freight.State__c)){
                score += 20;
            }
            else if(String.isNotEmpty(freight.Country__c)){
                score += 10;
            }

            freightToScoreMap.put(freight, score);    
        }

        return freightToScoreMap;
    }
}
