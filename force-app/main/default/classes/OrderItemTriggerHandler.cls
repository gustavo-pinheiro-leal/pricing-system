public with sharing class OrderItemTriggerHandler {

    List<OrderItem> oldRecords {get;set;} 
    List<OrderItem> newRecords {get;set;}
    Map<Id, OrderItem> oldMap {get;set;} 
    Map<Id, OrderItem> newMap {get;set;} 

    public OrderItemTriggerHandler(List<OrderItem> oldRecords, List<OrderItem> newRecords, Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap) {
        this.oldRecords = oldRecords;
        this.newRecords = newRecords;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public void beforeInsert(){
        OrderItemHelper.taxSelection(this.newRecords);
        OrderItemHelper.freightSelection(this.newRecords);
        OrderItemHelper.marginSelection(this.newRecords);
        OrderItemHelper.checkError(this.newRecords);
    }

    public void beforeUpdate(){
        OrderItemHelper.checkError(this.newRecords);
    }
}