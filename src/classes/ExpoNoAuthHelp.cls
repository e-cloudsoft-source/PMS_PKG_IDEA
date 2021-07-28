public without sharing class ExpoNoAuthHelp {
	private static String nologo64 = 'data:image/jpeg;base64,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';
	public static ReportLogo__c getReportTitleInfo(String spcd) {
		try{
			// EXPO店舗自設定ロゴあり
			ReportLogo__c logo = getShopInfoLogo(spcd);
			if (logo != null) return logo;
			// EXPO店舗自設定ロゴなし
			return CommRepUtils.getReportTitleInfo(spcd);
		} catch (Exception e) {
			String errorMessage = 'Shop Code Not Found. [' + spcd + ']';
			return new ReportLogo__c(ReportLogo__c = nologo64);
		}
	}
	// 既存店舗ロゴ取得
	public static ReportLogo__c getShopInfoLogo(String spcd){
		ReportLogo__c logo = null;
		// 店舗リスト
		List<ShopInformation__c> shops = [select id,shopcode__c from ShopInformation__c where shopcode__c = :spcd];
		if (!shops.isEmpty()) {
			// 該当店舗取得
			ShopInformation__c shop = shops[0];
			// ロゴ名取得
			String logoName = ExpoCommonConst.getShopCodeLogoName(shop.shopCode__c);
			// ロゴフィルート取得
			List<Attachment> rsAtt = [select Name,Body,ParentId from attachment where parentId = :shop.id and name = :logoName];
			// ロゴあり
			if (!rsAtt.isEmpty()) {
				Attachment newLog = rsAtt[0];
				logo = new ReportLogo__c();
				String src = '/servlet/servlet.FileDownload?file=' + newLog.id;
				logo.ReportLogo__c = src;
				return logo;
			}
		}
		return logo;
	} 
	// ロゴイメージ作成
	private static String createHTMLImgBySrc(String src){
		String imgHtml = '<img alt="ユーザが追加した画像" src=\"' + src + '\" target="_blank" rel="nofollow"></img>';
		return imgHtml;
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ BEGIN
	public static String getLogoUrl() {
		// EXPO
		List<Document> docLst = [select id, LastModifiedDate from document where DeveloperName = 'Expologo' limit 1];
		if (docLst.isEmpty()) {
			// JINYAロゴファイルを取得する
			docLst = [select id, LastModifiedDate from document where DeveloperName = 'Jinyalogo' limit 1];
		}
		document doc = docLst[0];
		return '/servlet/servlet.ImageServer?id='+doc.Id+'&oid='+ UserInfo.getOrganizationId() + '&lastMod='+doc.LastModifiedDate.getTime();
		
	}
	// 2018/10/06 システムロゴ情報を取得する WSQ END
	// 2019/08/15 商品の詳細情報を削除、削除した商品復元 BY zyz BEGIN
	public static String clearMaster(list<String> idLst,String expoUserName) {
		// 2019/09/15 Security Check BY zyz BEGIN
		if (!CommSecurityUtils.isDeleteable(AccountMaster__c.getSObjectType())) {
			return '';
		}
		// 2019/09/15 Security Check BY zyz END
		String messageStr = '';
		try{
			if(!idLst.isEmpty()){
				list<AccountMaster__c> deleteLst = [Select Id, Name, isDeleted,ExpoDeleteUser__c From AccountMaster__c Where Id =: idLst];
				for(AccountMaster__c acc: deleteLst){
					acc.ExpoDeleteUser__c = expoUserName;
				}
				// 为了更新商品数据的删除user
				if(!deleteLst.isEmpty()) {
					update deleteLst;
					delete deleteLst;
				}
			}
		} catch(Exception e){
			messageStr = CommUtils.getFieldValidationMessage(e.getMessage());
		}
		return messageStr;
	}
	// 2019/08/15 商品の詳細情報を削除、削除した商品復元 BY zyz END
	// 2019/09/19 Security Check BY WSQ BEGIN
	public static List<String> geAreaCsvInfo () {
		list<string> areaLst = new list<string>();
		for (Document doc : [select name,DeveloperName,body from Document where folder.DeveloperName = 'CsvTemplate' and DeveloperName = 'ExpoAreaMst2019']) {
			areaLst.add(doc.body.tostring());
		}
		return areaLst;
	}
	// 2019/09/19 Security Check BY WSQ END
}