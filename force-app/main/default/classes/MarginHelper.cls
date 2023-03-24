public with sharing class MarginHelper {
    public MarginHelper() {}

    public static void validateMargin(List<Margin__c> marginList){
        for(Margin__c margin : marginList){

            String message = '';
            if(!validateMarginAccountParameters(margin)){
                message += '-- Selecione UMA conta OU UM grupo de conta';
            }
            if(!validateMarginLocationParameters(margin)){
                message += '-- Selecione UM pais OU UM estado OU UMA cidade';
            }
            if(!validateMarginProductParameters(margin)){
                message += '-- Selecione UM produto OU UMA hierarquia de produto';
            }

            if(String.isNotEmpty(message)){
                margin.addError(message);
            }
        }
    }

    public static Boolean validateMarginProductParameters(Margin__c margin){
        if((String.isBlank(margin.ProductHierarchy__c) && String.isBlank(margin.Product__c)) || 
           (String.isNotBlank(margin.ProductHierarchy__c) && String.isNotBlank(margin.Product__c))){
            return false;
        }
        return true;
    }

    public static Boolean validateMarginAccountParameters(Margin__c margin){
        if((String.isBlank(margin.Account__c) && String.isBlank(margin.AccountGroup__c)) ||
           (String.isNotBlank(margin.Account__c) && String.isNotBlank(margin.AccountGroup__c))){
            return false;
        }
        return true;
    }

    public static Boolean validateMarginLocationParameters(Margin__c margin){
        if((String.isBlank(margin.Country__c) && String.isBlank(margin.State__c) && String.isBlank(margin.City__c)) ||
        (String.isNotBlank(margin.Country__c) && String.isNotBlank(margin.State__c) && String.isNotBlank(margin.City__c)) ||
        (String.isBlank(margin.Country__c) && String.isNotBlank(margin.State__c) && String.isNotBlank(margin.City__c)) ||
        (String.isNotBlank(margin.Country__c) && String.isBlank(margin.State__c) && String.isNotBlank(margin.City__c)) ||
        (String.isNotBlank(margin.Country__c) && String.isNotBlank(margin.State__c) && String.isBlank(margin.City__c))){
            return false;
        }
        return true;
    }

    public static Map<Margin__c, Integer> calculateMarginScore(List<Margin__c> marginList){
        Map<Margin__c, Integer> marginToScoreMap = new Map<Margin__c, Integer>();

        for(Margin__c margin : marginList){
            Integer score = 0;

            if (String.isNotEmpty(margin.Product__c)){
                score += 2000;
            }
            else if (String.isNotEmpty(margin.ProductHierarchy__c)){
                score += 1000;
            }

            if (String.isNotEmpty(margin.Account__c)){
                score += 200;
            }
            else if (String.isNotEmpty(margin.AccountGroup__c)){
                score += 100;
            }

            if (String.isNotEmpty(margin.City__c)){
                score += 30;
            }
            else if (String.isNotEmpty(margin.State__c)){
                score += 20;
            }
            else if (String.isNotEmpty(margin.Country__c)){
                score += 10;
            }

            marginToScoreMap.put(margin, score);
        }

        return marginToScoreMap;
    }
}