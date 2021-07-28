public with sharing class ShopInformationTriggerProcess {

	public void autoSetupShopInfomation(ShopInformation__c[] newList, ShopInformation__c[] oldList, CommConst.TriggerMethod action){
		List<ShopInformation__c> updLst = new List<ShopInformation__c>();
		Integer idx = 0;
		List<Integer> targetLst = new List<Integer>();
		for (ShopInformation__c nw : newList) {
			if (CommUtils.isBlank(nw.ShopCode__c)) {
				targetLst.add(idx);
			}
			idx++;
		}
		if (!targetLst.isempty()) {
			map<Integer, String> numMap = CommLogicProcess.getBulkAutoNumer(targetLst);
			for (Integer key : numMap.keySet()) {
				newList[key].ShopCode__c = 'EP'+numMap.get(key);
			}
		}
	}
}