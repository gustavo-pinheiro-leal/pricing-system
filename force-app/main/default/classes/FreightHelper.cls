public with sharing class FreightHelper {
    public FreightHelper() {}

    public static void validateFreight(List<Freight__c> freightList){
        for(Freight__c freight : freightList){
            if(!validateFreightParameters(freight)){
                freight.addError('Parametros invalidos');
            }
        }
    }

    public static Boolean validateFreightParameters(Freight__c freight){
        if((String.isBlank(freight.ProductHierarchy__c) && String.isBlank(freight.Product__c)) ||
            (String.isBlank(freight.Country__c) && String.isBlank(freight.State__c) && String.isBlank(freight.City__c)) ||
            (String.isNotBlank(freight.ProductHierarchy__c) && String.isNotBlank(freight.Product__c)) ||
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
