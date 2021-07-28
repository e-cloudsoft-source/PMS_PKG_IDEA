trigger OrderItemCommTrigger on OrderItem__c (after insert) {
	// after insert
	if(Trigger.isInsert && Trigger.isAfter){
		OrderItemTriggerProcess orderItem = new OrderItemTriggerProcess();
		orderItem.setStockInfo(trigger.new, Trigger.old, CommConst.TriggerMethod.IsInsert);
	}
}