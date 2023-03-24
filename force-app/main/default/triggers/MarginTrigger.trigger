trigger MarginTrigger on Margin__c (before insert) {

    MarginTriggerHandler handler = new MarginTriggerHandler(
        Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap
    );

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert();       
        }
    }
}