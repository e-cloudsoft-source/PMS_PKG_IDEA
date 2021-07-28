@isTest
private class DesignLayoutCtrlTest {
	
	@isTest static void test_method_one() {
		ShopInformation__c shop = TestCommon.createShopInfo();
		shop.ShopCode__c = '02';
		update shop;
		user user = new User (id = UserInfo.getUserId(),Shopcode__c = '');
		update user;
		DesignLayoutCtrl ctrl = new DesignLayoutCtrl();
		ctrl.init();
		ctrl.refreshBranchShopInfo();
		Map<String,Object> newMap = new Map<String,Object>{
			'shapes' => '123',
			'shopCd' => '02',
			'attId' => '',
			'name' => '123'
		};
		Document att = new Document(name ='LAYOUT_TEMP_02_123', DeveloperName= 'LAYOUT_TEMP_02_123',body = blob.valueof('123'),FolderId =UserInfo.getUserId());
		insert att;
		String req = JSON.serialize(newMap);
		DesignLayoutCtrl.remoteCenter('shopSave',req);
		newMap.put('refresh',true);
		DesignLayoutCtrl.remoteCenter('templateSave',JSON.serialize(newMap));
		DesignLayoutCtrl.remoteCenter('refreshAttachments',JSON.serialize(newMap));
		DesignLayoutCtrl.remoteCenter('removeTemplate',req);
		DesignLayoutCtrl.remoteCenter('getAttachment',req);
		newMap.put('attId',att.id);
		DesignLayoutCtrl.remoteCenter('getAttachment',JSON.serialize(newMap));
		DesignLayoutCtrl.remoteCenter('getRoomLst',req);
		newMap.put('validate',true);
		DesignLayoutCtrl.remoteCenter('layoutStatusChange',JSON.serialize(newMap));
		DesignLayoutCtrl.remoteCenter('updateShopDocSetting',req);
		DesignLayoutCtrl.getDefLayoutList('02');
	}
	
	@isTest static void test_method_two() {
		// Implement test code
		createConfigDoc();
		DesignLayoutCtrl ctrl = new DesignLayoutCtrl();
		ctrl.init();
		Map<String,Object> newMap = new Map<String,Object>{
			'shapes' => '123',
			'shopCd' => '02',
			'attId' => '',
			'name' => '123'
		};
		newMap.put('refresh',true);
		newMap.put('upsertFlg',true);
		DesignLayoutCtrl.remoteCenter('templateSave',JSON.serialize(newMap));
		newMap.put('descr','Color');
		newMap.put('value','#ecece');
		String req = JSON.serialize(newMap);
		DesignLayoutCtrl.remoteCenter('updateShopDocSetting',req);
		DesignLayoutCtrl.getDefLayoutList('02');
	}
	static Document createConfigDoc(){
		String domString = '<?xml version="1.0" encoding="UTF-8"?><root>	<SHOP>		<SHOPCODE></SHOPCODE> <SHAPE></SHAPE></SHOP></root>';
    	Document item = new Document();
    	item.Name = 'RoomLayoutConfig';
    	item.DeveloperName = item.Name;
    	item.FolderId = UserInfo.getUserId();
    	item.Body = Blob.valueOf(domString);
    	insert item;
    	return item;
	}
	
}