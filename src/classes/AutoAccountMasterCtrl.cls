global with sharing class AutoAccountMasterCtrl {
	@remoteAction
	global static void referenecInfo (Id accId){
		if (!CommUtils.isBlank(accId)){
			ProductItemUtils.viewInfo(accId);
		}
	}
}