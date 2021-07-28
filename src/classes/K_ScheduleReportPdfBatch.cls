/**
* 予定表情報定期出力バッチ
* 2017/01/17 INIT
* 2017/05/12 指定の時間に予定表を投稿し、その後予定表に変更があった時だけ、元投稿へのコメントに新しい予定表を貼り付けてように改善対応
* 2017/05/12 投稿した予定表の変更箇所は色つけように改善対応
* 2017/05/12 店舗毎の予定表を異なるChatterグループ内に投稿できるように改善対応
**/
public with sharing class K_ScheduleReportPdfBatch implements Database.Batchable<ShopInformation__c>, Database.Stateful ,Database.AllowsCallouts{
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	/*
	private list<string> chatterGroupIdLst;
	public K_ScheduleReportPdfBatch(list<string> pChatterGroupIdLst){
		chatterGroupIdLst = pChatterGroupIdLst;
	}
	*/
	// 今回バッチ処理開示時間
	private DateTime scheduleStartTm;
	public K_ScheduleReportPdfBatch(DateTime startDt){
		scheduleStartTm = startDt;
	}
	// 2017/05/12 PDFpost等机能对应 END By Wgch
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<ShopInformation__c> start(Database.BatchableContext BC){
		// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
		// Chatterポストグループは未定義の場合、処理を行わない
		//if (chatterGroupIdLst == null || chatterGroupIdLst.isEmpty()) return new list<ShopInformation__c>();
		// 2017/05/12 PDFpost等机能对应 END By Wgch
		// 店舗単位の
		List<ShopInformation__c> shops = [	
					SELECT 
	                Id
	                , Name
	                , ShopCode__c
	                From ShopInformation__c order by Seq__c limit 100];
	   // Dumy Shop Info Create
	   if (shops.isEmpty()) shops.add(new ShopInformation__c());
	   return shops;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<ShopInformation__c> shops){
		/*
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where id = :chatterGroupIdLst and isarchived = false];
		if (chatterGroups.isEmpty()) {
			return;
		}
		*/
		// 店舗毎の予定表を異なるChatterグループ内に投稿できるように改善対応
		List<String> spCdLst = new List<String>();
		// 获取当前店铺code 和 店铺Name
		for (ShopInformation__c shop : shops) {
			spCdLst.add(CommUtils.nullToBlank(shop.ShopCode__c));
		}
		// 該当店舗投稿用Chatterグループ定義対象ID
		map<string, list<id>> shopUnitChaterGroupMap = initOutputPdfDefine(spCdLst);
		// 今回スケジールからバッチ起動時間システム時間
		if (scheduleStartTm == null) scheduleStartTm = DateTime.now();
		Date batchQueryDt = scheduleStartTm.date();
		String queryDt = scheduleStartTm.format('yyyyMMdd');
		// バッチ処理情報格納用リスト
		List<ReservationListWork__c> batchInfoLst = new list<ReservationListWork__c>();
		try {
			// 2018/03/07 Security Check BEGIN
			List<String> chkFieldsLst = new List<String>{'versiondata','title','pathonclient','origin'};
			Map<String,Schema.SObjectField> mm = Schema.SObjectType.ContentVersion.fields.getMap();
			if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
				return ;
			}
			// 2018/03/07 Security Check END
			// 2019/09/15 Security Check BY zyz BEGIN
			List<String> chkFieldLst = new List<String>{'entrydate__c','batchlasttm__c'};
			Map<String,Schema.SObjectField> m = Schema.SObjectType.ReservationListWork__c.fields.getMap();
			if (!CommSecurityUtils.isCanUpsertable(chkFieldLst, m)) {
				return ;
			}
			// 2019/09/15 Security Check BY zyz END
	    	// ポスト要情報を格納する
			for (ShopInformation__c shop : shops) {
				String shopCode = CommUtils.nullToBlank(shop.ShopCode__c);
				// 該当店舗のPDF出力タグ存在する・しない判断する
				if (!isOutputPdf(shopCode)) continue;
				// 該当店舗の投稿用Chatterグループ定義対象が非存在の場合
				if (!shopUnitChaterGroupMap.containsKey(shopCode)) {
					setSendMailAddress(shopCode);
					continue;
				}
				// 投稿用ChatterグループIDを取得する
				List<Id> chatterGroups = shopUnitChaterGroupMap.get(shopCode);
	   			// 該当グループは既にFeeditemをポスト済みの場合、再度ポストする場合、元投稿へのコメントとして、ポストする
	   			map<Id, Id> groupIdToFeedIdMap = new map<Id, Id>();
	   			for (Id gpId : chatterGroups) {groupIdToFeedIdMap.put(gpId, null);}
	   			// 前回バッチ実施時間を格納する
	   			DateTime preBatchExcDt = null;
	   			// 
	   			K_ScheduleReportPdf pdfCtrl = null;
				// バッチ処理情報を格納する
				List<ReservationListWork__c> reservationList = [Select Id,BatchLastTm__c,DateType__c,ShopInfoRef__r.ShopCode__c,FoodSumType__c,FeedItemId__c,EntryDate__c from ReservationListWork__c 
									where FoodSumType__c = null And EntryDate__c =: batchQueryDt And DateType__c =:K_ScheduleReportPdf.BATCH 
									And ShopInfoRef__r.ShopCode__c =: shopCode limit 1];
				// 今日抽出あり、なし判断
				if(reservationList.isEmpty()){
					// 如果没有有效的数据，就去确认 看当店铺是否有效的预约数据 IF有就 post
					pdfCtrl = new K_ScheduleReportPdf(shopCode,queryDt,true,null,scheduleStartTm);
					pdfCtrl.init();
					// 插入纪录该店铺当前的执行时间等信息
					batchInfoLst.add(inReservationListWork(scheduleStartTm,shop));
				} else {
					ReservationListWork__c res = reservationList[0];
					preBatchExcDt = res.BatchLastTm__c;
					//  如果有有效的数据，就去确认 该店铺是否有变更， IF有就 post
					pdfCtrl = new K_ScheduleReportPdf(shopCode,queryDt,false,preBatchExcDt,scheduleStartTm);
					pdfCtrl.init();
					batchInfoLst.add(upReservationListWork(scheduleStartTm,res));
				}
				// 該当PDFは未変更の場合、次の処理を行わない
				if(!K_ScheduleReportPdf.isBatchStartFlg) continue;
				// 前回ポストしたFEEDITEM情報をチェックする
				if (!reservationList.isEmpty()) {
					// バッチ処理情報
					ReservationListWork__c res = reservationList[0];
					// 前回ポストしたFeeditem情報をチェックする、存在すると、該当Feeditemの子データとして、ポストする
					if(!CommUtils.isBlank(res.FeedItemId__c)) {
						Map<Id,Id> preGpToFeedIdMap = (Map<Id,Id>)JSON.deserializeStrict(CommUtils.nullToBlank(res.FeedItemId__c),Map<Id,Id>.class);
						// 該当IDは存在チェックを行う
						Map<Id,FeedItem> existItemMap = new map<Id, FeedItem>([select id from Feeditem Where id = :preGpToFeedIdMap.values()]);
						// 前回のグループIDと現在定義のグループIDを整合性チェックする
						for (id gpId : chatterGroups) {
							if (preGpToFeedIdMap.containsKey(gpId)) {
								Id FeeditemId = preGpToFeedIdMap.get(gpId);
								if (existItemMap.containsKey(FeeditemId)) {
									groupIdToFeedIdMap.put(gpId, FeeditemId);
								}
							}
						}
					}
				}
				
				// PDF出力する
				PageReference pdf = Page.K_ScheduleReportPdf;//pdfCtrl.getCurrPageInfo();
				pdf.getParameters().put('sp',shopCode);
				pdf.getParameters().put('dt',queryDt);
				pdf.getParameters().put('bltm',CommUtils.nullToBlank(scheduleStartTm.getTime()));
				if (preBatchExcDt != null) {
					pdf.getParameters().put('preBltm',CommUtils.nullToBlank(preBatchExcDt.getTime()));
				}
				Blob k_pdf = null;
				if (!Test.isRunningTest()){
					// 該当予定表のPDFファイルを作成する
				    k_pdf = pdf.getContentAsPDF();
				}
				else{
					// テストクラスするため
				    k_pdf = Blob.valueof('Some random String');
				}			
				if(k_pdf == null || k_pdf.size() == 0) continue;
				// 該当予定表ファイルはChatterへポストファイル作成する
				//DateTime nowTime = DateTime.now();
				String timeStr = scheduleStartTm.format('yyyyMMddHHmmss');	
				String shopName = CommUtils.nullToBlank(shop.Name);
				String preNameKey = CommUtils.isBlank(shopName) ? '' : shopName + '_';
			 	// 予定表PDFはアップロードする
				ContentVersion cv = new ContentVersion(); 
				cv.Origin = 'H';
				cv.PathOnClient= preNameKey + timeStr +'_autopdf.pdf';
				cv.Title = preNameKey + timeStr; 
				cv.VersionData = k_pdf;
				List<FeedItem> feedItems = new List<FeedItem>();
				//Set<Id> groupsSet = new Set<Id>();
	        	// 指定のグループへポストする
	    		for (Id gpId : chatterGroups) {
	    			//groupsSet.add(gpId);
    				if(groupIdToFeedIdMap.get(gpId) != null) continue;
					FeedItem contentFI = new FeedItem();
				    contentFI.Type = 'ContentPost';
				    contentFI.title = preNameKey + timeStr +'_FilePDF';
				    contentFI.Body = '予定表PDF'+ (CommUtils.isBlank(shopName) ? '' : '('+shopName+')');
					contentFI.ParentId = gpId;
				 	feedItems.add(contentFI);
	    		}
		    	insert cv;
		    	/*
	    		// 去掉不存在的FeedItemId
	    		for(String key : groupIdToFeedIdMap.keySet()){
					if(!groupsSet.contains(key)) groupIdToFeedIdMap.remove(key);
				}*/
				list<FeedComment> insertFeedComments = new list<FeedComment>();
		    	for(Id feedItemId : groupIdToFeedIdMap.values()){
		    		if(feedItemId == null) continue;
					FeedComment contentFC = new FeedComment();
				    contentFC.CommentBody = '予定表PDF'+ (CommUtils.isBlank(shopName) ? '' : '('+shopName+')');
					contentFC.FeedItemId = feedItemId; 
					contentFC.RelatedRecordId = cv.id;
				 	insertFeedComments.add(contentFC);
		    	}
		    	if (!insertFeedComments.isEmpty()) insert insertFeedComments;
			
	    		// ファイルを一括アップロード処理
	    		list<FeedItem> insertFeedItems = new list<FeedItem>();
        		for (FeedItem item : feedItems) {
        			item.RelatedRecordId = cv.id;
        			insertFeedItems.add(item);
        		}
	       		if (!insertFeedItems.isEmpty()) insert insertFeedItems;
	       		for (FeedItem item : insertFeedItems) {
	       			if (groupIdToFeedIdMap.containskey(item.ParentId)) {
	       				groupIdToFeedIdMap.put(item.ParentId, item.Id);
	       			}
	       		}
	       		if (!groupIdToFeedIdMap.isEmpty()) {
	       			// ポストしたFEEDITEM情報を格納する
	       			upInsertReservation(groupIdToFeedIdMap, batchInfoLst[batchInfoLst.size()-1]);
	       		}
	       		// バッチの関連データを処理する
				// 今回取得の比較用情報はDBへ反映する
				pdfCtrl.saveSummaryToWorkDb(shop);
				
			}// End For Shop
			if (!batchInfoLst.isEmpty()) upsert batchInfoLst;
		} catch (Exception e) {
			system.debug(loggingLevel.info, 'BATCH EXECUTE='+e.getStackTraceString());
			throw e;
		}
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// 次のスケジュールを起動する
		// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
		// 传时间参数: 目的: 判断是否为第一次启动
		K_ScheduleReportPdfSchedule schedule= new K_ScheduleReportPdfSchedule(scheduleStartTm);
		// 2017/05/12 PDFpost等机能对应 END By Wgch
		DateTime nowTime = DateTime.now().addMinutes(getInterVal());
		// 起動ＣＲＯＮを設定する
		String timeStr = nowTime.format('yyyyMMddHHmmss');
		String yy = timeStr.substring(0,4);
		String mm = timeStr.substring(4,6);
		String dd = timeStr.substring(6,8);
		String hh = timeStr.substring(8,10);
		String ms = timeStr.substring(10,12);
		String ss = timeStr.substring(12,14);
		String sch = ss + ' ' +
					 ms + ' ' +
					 hh + ' ' +
					 dd + ' ' +
					 mm + ' ' +
					' ? ' + yy;
		String jobName = 'K_ScheduleReportPdfSchedule_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
		String jobId = system.schedule(jobName, sch, schedule);
	}
	// Xml配置文件
	public Integer getInterVal(){
		// デフォル値は２時間単位予定表ファイルを自動ポスト
		Integer intervalLength = 120;
		try{
			List<Document> sr = [select body, name from Document where DeveloperName = 'ScheduleReportFieldsXml'];
			if (sr.isEmpty()) return intervalLength;
			Blob xmlBody = sr[0].Body;
			String strXmlBody = xmlBody.toString();
			Dom.Document doc = new Dom.Document();
			doc.load(strXmlBody);
			Dom.XMLNode root = doc.getRootElement();
			Dom.XmlNode pdfOutPutFields = root.getChildElement('EXPORTPDF_BATCHCONFIG', null);
			if (pdfOutPutFields != null) {
				Dom.XmlNode watchBatchTimeField =  pdfOutPutFields.getChildElement('INTERVAL', null);
				if (watchBatchTimeField != null) {
					// 按分钟为单位获取
					Integer locIntervalLength = CommUtils.nullToIntZero(CommUtils.nullToBlank(watchBatchTimeField.getText()));
					// 最初５分単位情報出力する
					if (locIntervalLength < 5) locIntervalLength = 5;
					intervalLength = locIntervalLength;
				}
			}
		} catch(Exception e){
			//throw new CommException('XML定義情報(予定表カスタマイズ)の設定情報不正:'+e.getMessage());
			system.debug(loggingLevel.info, 'BATCH getInterVal()='+e.getStackTraceString());
		}
		return intervalLength;
	}
	// 指定店舗のPDF出力する・しないフラグを判断する
	public boolean isOutputPdf(String shopCode) {
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('ScheduleReportFieldsXml',shopCode);
		// 指定店舗関連のPDF出力詳細をチェックする
		Dom.XmlNode pdfNode =  targetNode.getChildElement('EXPORTPDF', null);
		return (pdfNode != null);
	}
	// 2017/05/12 PDFpost等机能对应 BEGIN By Wgch
	// 指定店舗のPDF出力する・しないフラグを判断する
	public map<string, list<id>> initOutputPdfDefine(List<String> spCdLst) {
		// 店舗単位のChatterグループIDを取得する
		map<string, list<string>> shopGrpNmsMap = new map<string, list<string>>();
		Set<String> spCdSet = new Set<String>();
		spCdSet.addAll(spCdLst);
		try{
			List<Document> sr = [select body, name from Document where DeveloperName = 'ScheduleReportFieldsXml'];
			if (!sr.isEmpty()){
				Blob xmlBody = sr[0].Body;
				String strXmlBody = xmlBody.toString();
				Dom.Document doc = new Dom.Document();
				doc.load(strXmlBody);
				Dom.XMLNode root = doc.getRootElement();
				Dom.XmlNode pdfOutPutFields = root.getChildElement('EXPORTPDF_BATCHCONFIG', null);
				if (pdfOutPutFields != null) {
					Dom.XmlNode postDefineField =  pdfOutPutFields.getChildElement('POSTDEFINE', null);
					if (postDefineField != null) {
						for(Dom.XMLNode postNode : postDefineField.getChildElements()){
							if(postNode.getName().equalsIgnoreCase('GROUPNAME')){
								String shopCd = CommUtils.nullToBlank(postNode.getAttribute('SHOPCODE', null));
								if (!spCdSet.contains(shopCd)) continue;
								String val = CommUtils.nullToBlank(postNode.getText());
								//if (CommUtils.isBlank(val)) continue;
								List<String> gruopNmLst = new List<String>();
								// 对gruopNm处理
								for(String gruopNm : val.split(',')){
									if(CommUtils.isBlank(gruopNm)) continue;
									gruopNmLst.add(CommUtils.nullToBlank(gruopNm));
								}
								if(!shopGrpNmsMap.containsKey(shopCd)) shopGrpNmsMap.put(shopCd,gruopNmLst);
								else shopGrpNmsMap.get(shopCd).addAll(gruopNmLst);
							}
						}
					}
				}
			}
		} catch(Exception e){
			//throw new CommException('XML定義情報(予定表カスタマイズ)の設定情報不正:'+e.getMessage());
			system.debug(loggingLevel.info, 'isOutputPdf['+spCdSet+']='+e.getStackTraceString());
		}
		// 共通定義のグループ名
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.KSCH_ChatterGroupNameType);
		for (String spcd : spCdLst) {
			if (!shopGrpNmsMap.containsKey(spcd)) {
				shopGrpNmsMap.put(spcd,chatterGroupNamesLst);
			}
		}
		// グループ名により、関連のグループIDを取得する
		set<string> grNmSet = new set<string>();
		for (List<String> groupNms : shopGrpNmsMap.values()) {
			grNmSet.addAll(groupNms);
		}
		// 該当店舗投稿用Chatterグループ定義対象ID
		map<string, list<id>> shopGroupMap = new map<string, list<id>>();
		if (!grNmSet.isEmpty()) {
			map<string,id> groupNmToIdsMap = new map<string, id>();
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where Name in:grNmSet and isarchived = false];
			for (CollaborationGroup grp : chatterGroups) {
				groupNmToIdsMap.put(grp.Name, grp.Id);
			}
			for (String spcd : spCdLst) {
				//該当店舗のグループ名を定義されている
				if (!shopGrpNmsMap.containsKey(spcd)) continue;
				for (String grpNm : shopGrpNmsMap.get(spCd)) {
					Id grpId = groupNmToIdsMap.get(grpNm);
					if (grpId == null) continue;
					if (!shopGroupMap.containsKey(spcd)) shopGroupMap.put(spcd, new list<id>());
					shopGroupMap.get(spcd).add(grpId);
				}
			}
		}
		return shopGroupMap;
	}
	// 第一次或第二天新规数据处理
	public ReservationListWork__c inReservationListWork(DateTime scheduleStartDt,ShopInformation__c shop) {
		// 纪录该店铺batch最终更新数据表数据
		ReservationListWork__c res = new ReservationListWork__c(
			 FeedItemId__c = '',
			 DateType__c = K_ScheduleReportPdf.BATCH,
			 BatchLastTm__c = scheduleStartDt,
			 EntryDate__c = scheduleStartDt.date(),
			 ShopInfoRef__c = shop.Id
		);
		return res;
	}
	// 更新最后batch执行时间
	public ReservationListWork__c upReservationListWork(DateTime batchLastTm,ReservationListWork__c res) {
		res.BatchLastTm__c = batchLastTm;
		res.EntryDate__c = batchLastTm.date();
		return res;
	}
	// 更新 FeedItemId 变化信息
	public ReservationListWork__c upInsertReservation(Map<Id,Id> feedItemIdMap,ReservationListWork__c res) {
		res.FeedItemId__c = JSON.serialize(feedItemIdMap);
		return res;
	}
	// 2017/05/12 PDFpost等机能对应 END By Wgch
	/**
	* メール通知先のアドレス宛を設定する
	**/
	public void setSendMailAddress(String shopCode){
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// メール情報を設定する
		String plusMsg = CommUtils.isBlank(shopCode) ? '' : '店舗コード['+shopCode+']';
		String errMsg = '予定表PDFポスト用チャターグループを未定義またはアーカイブされるため、予定表PDFポスト失敗になりました。'+plusMsg+'\n\n';
		//エラー内容：
		if (CommUtils.isBlank(mailAdds)) return;
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		//スケジュール処理エラーの通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ Label.MSG_036_0015);
		mail.setPlainTextBody(errMsg);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}