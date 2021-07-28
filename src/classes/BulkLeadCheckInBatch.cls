/**
* 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応
**/
public with sharing class BulkLeadCheckInBatch implements Schedulable, Database.Batchable<Lead__c>, Database.Stateful{
	public BatchVariableInfo bItem; // 全局变量Item
	public BulkLeadCheckInBatch(String shopCode, Date checkInDate){
		bItem = new BatchVariableInfo(shopCode, checkInDate);
		parseConfigXml();
	}
	// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH BEGIN
	public BulkLeadCheckInBatch(){}
	public BulkLeadCheckInBatch(Set<String> shopCodeSet, Date checkInDate){
		bItem = new BatchVariableInfo(shopCodeSet, checkInDate); // 初期全局变量
		parseConfigXml(); // 获取xml信息
	}
	// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
	public BulkLeadCheckInBatch(String shopCode, Date checkInDate, Set<String> accIdSet){
		bItem = new BatchVariableInfo(shopCode, checkInDate, accIdSet); // 初期全局变量
		parseConfigXml(); // 获取xml信息
	}
	// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
	// ***********************************
	// スケジュール処理開始
	// ***********************************
	public void execute(SchedulableContext SC) {
		Set<String> shopCodeSet = new Set<String>();
		// スケジュールから起動する場合、全て店舗を処理する
		for (ShopInformation__c shop : [ SELECT Id, Name, ShopCode__c From ShopInformation__c Order by Seq__c limit 100]) {
			shopCodeSet.add(CommUtils.nullToBlank(shop.ShopCode__c));
		}
		// システム日と処理日の差異日数
      	Integer days = CommDefine__c.getOrgDefaults().ScheduleBulkAccountPaymentDays__c == null ? 0 : CommDefine__c.getOrgDefaults().ScheduleBulkAccountPaymentDays__c.intValue();
      	// スケジュール実施開始日
      	Date startDate = (Date.today().addDays(days));
		// バッチを起動する
		BulkLeadCheckInBatch batch = new BulkLeadCheckInBatch(shopCodeSet, startDate);
		// バッチ処理設定
		Id batchJobId = DataBase.executeBatch(batch, BatchControlCenter.PRO_LEAD_NOMAX);
		// スケジュールABORTする　
		System.abortJob(SC.getTriggerId());
	}
	// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH END
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<Lead__c> start(Database.BatchableContext BC){
		List<Lead__c> noCheckInLeadLst = new List<Lead__c>();
		Set<String> leadIndexIdSet = new Set<String>(); // 预约IndexId集合
		Set<String> leadIndexSubIdSet = new Set<String>(); // 预约IndexSubId集合
		Set<Decimal> roomGroupNoSet = new Set<Decimal>(); // 预约RoomGroupNo集合
		Map<String, List<Lead__c>> oneRoomLeadMap = new Map<String, List<Lead__c>>();
		// 宴会のレコードタイプ
		Id enkaiRecTypeId = CommLogicProcess.getLeadEnkaiRecType();
		List<Lead__c> leadLst = [Select Id, Field298__c, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c From Lead__c
														Where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
														And DAY_ONLY(convertTimezone(EntryTime__c)) =: bItem.checkInDate
														// 宴会場は自動チェックイン処理を行わない
														And RecordTypeId != :enkaiRecTypeId
														And Rroom__r.ShopInfoRef__r.ShopCode__c =: bItem.shopCode
														Order By EntryTime__c];
		
		for (Lead__c leadItem : leadLst) {
			leadIndexIdSet.add(leadItem.LeadIndexRef__c); // 预约IndexId集合
			leadIndexSubIdSet.add(leadItem.LeadIndexSubId__c); // 预约IndexSubId集合
			roomGroupNoSet.add(leadItem.RoomGroupNo__c); // 预约RoomGroupNo集合
			if(bItem.configXmlItem.autoCheckInFlg && leadItem.Field298__c == null) noCheckInLeadLst.add(leadItem);
		}
		// 获取同一房间的相关预约
		List<Lead__c> oneRoomLeadLst = [ Select Id, LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c From Lead__c 
														Where LeadIndexRef__c =: leadIndexIdSet
														And LeadIndexSubId__c =: leadIndexSubIdSet
														And RoomGroupNo__c =: roomGroupNoSet
														And CancelBool__c !=: CommConst.LEAD_ST_CANCEL_FLG 
														Order By EntryTime__c ];
		for(Lead__c leadItem : oneRoomLeadLst){
			// ONEROOMの識別キー
			String key = leadItem.LeadIndexRef__c + '_' + leadItem.LeadIndexSubId__c + '_' + leadItem.RoomGroupNo__c;
			if(!oneRoomLeadMap.containsKey(key)) oneRoomLeadMap.put(key, new List<lead__c>());
			oneRoomLeadMap.get(key).add(leadItem);
		}
		for(String key : oneRoomLeadMap.keySet()){
			List<Lead__c> wkOneRoomLeadLst = oneRoomLeadMap.get(key);
			for(Integer i = 0; i < wkOneRoomLeadLst.size(); i++){ // 泊数Info处理
				Lead__c oneRoomLead = wkOneRoomLeadLst[i];
				// 2019/05/15 最終泊の設定対応 WGCH BEGIN
				// LeadNightInfo leadNightItem = new LeadNightInfo(oneRoomLead, (i+1), (wkOneRoomLeadLst.size() > 1));
				Integer leadNight = i+1;
				LeadNightInfo leadNightItem = new LeadNightInfo(oneRoomLead, (i+1), (wkOneRoomLeadLst.size() > 1), (wkOneRoomLeadLst.size() == leadNight));
				// 2019/05/15 最終泊の設定対応 WGCH END
				bItem.leadNightInfoMap.put(oneRoomLead.Id, leadNightItem);
			}
		}
		return noCheckInLeadLst;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<Lead__c> noCheckInLeadLst){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'field298__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		List<Lead__c> newLeadLst = new List<Lead__c>();
		try {
			for(Lead__c leadItem : noCheckInLeadLst){ // 预约CheckIn处理
				leadNightInfo leadNightItem = bItem.leadNightInfoMap.get(leadItem.Id);
				if(leadNightItem.leadNight < 2 && !bItem.configXmlItem.firstNightCheckInFlg) continue;
			 	leadItem.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			 	newLeadLst.add(leadItem);
			}
			bItem.leadCheckInSize += newLeadLst.size(); // 集计已CheckIn的件数
			if(!newLeadLst.isEmpty()) update newLeadLst;
		} catch(Exception e){
			bItem.leadCheckInSize -= newLeadLst.size(); // 集计已CheckIn的件数
		}
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// バッチスケジュールを起動する
		BulkAccountPaymentBatch batch = new BulkAccountPaymentBatch(bItem);
		// バッチ処理設定
		DataBase.executeBatch(batch, BatchControlCenter.PRO_ACC_NOMAX);
		// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH BEGIN
		if(!bItem.shopCodeSet.isEmpty()){
			// バッチを起動する
			BulkLeadCheckInBatch ldBatch = new BulkLeadCheckInBatch(bItem.shopCodeSet, bItem.checkInDate);
			// バッチ処理設定
			Id batchJobId = DataBase.executeBatch(ldBatch, BatchControlCenter.PRO_LEAD_NOMAX);
		}
		// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH END 
	}
	// XML情報分析と格納
	private void parseConfigXml() {
		bItem.configXmlItem = new ConfigXmlInfo();
		try{
			// 格納用変数クリアする
			BillSimpleHelp help = new BillSimpleHelp(bItem.shopCode);
			Map<String, String> PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
			// 支付商品信息集计处理
			Map<String, PaymentInfo> paymentInfoMap = new Map<String, PaymentInfo>();
			BillSimplePaymentCtrl billSimplePayment = new BillSimplePaymentCtrl();
			billSimplePayment.getInitXmlDefineInfo();
			for(BillSimplePaymentCtrl.Product product : billSimplePayment.exitProdLst){
				if(product.productItem != null){ // 支付商品集计
					PaymentInfo paymentItem = new PaymentInfo(product.productItem.productId, product.productItem.prodcutName, product.productItem.prodcutCode, product.productItem.actionType, product.productItem.paymentType, PAYMENT_MATCH_MAP.get(product.productItem.paymentType));
					paymentInfoMap.put(paymentItem.paymentCd, paymentItem);
				}
			}
			// XML READ
			Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc('BatchRequstConfigXml', bItem.shopCode);
			if(shopRoot == null) return;
			Dom.XmlNode accPayBatchFields = shopRoot.getChildElement('ACCPAY_BATCH', null);
			if(accPayBatchFields != null){
				// AUTOCHECKINFLG
				Dom.XmlNode autoCheckInFlgFields = accPayBatchFields.getChildElement('AUTOCHECKINFLG', null);
				// FIRSTNIGHTCHECKINFLG
				Dom.XmlNode firstNightCheckInFlgFields = accPayBatchFields.getChildElement('FIRSTNIGHTCHECKINFLG', null);
				// FIRSTNIGHTPAYMENTCODE
				Dom.XmlNode firstNightPaymentCodeFields = accPayBatchFields.getChildElement('FIRSTNIGHTPAYMENTCODE', null);
				// NNIGHTPAYMENTCODE
				Dom.XmlNode nNightPaymentCodeFields = accPayBatchFields.getChildElement('NNIGHTPAYMENTCODE', null);
				// 2019/05/15 最終泊の設定対応 WGCH BEGIN
				Dom.XmlNode lastNightPaymentCodeFields = accPayBatchFields.getChildElement('LASTNNIGHTPAYMENTCODE', null);
				// 2019/05/15 最終泊の設定対応 WGCH END
				if (autoCheckInFlgFields != null) { // 预约 自动CheckIn除第一泊以外Flg,True:开启,False:关闭
					bItem.configXmlItem.autoCheckInFlg = Boolean.valueOf( CommUtils.nullToBlank(autoCheckInFlgFields.getText()) );
				}
				if (firstNightCheckInFlgFields != null) { // 预约 前提AUTOCHECKINFLG 为 True => 自动CheckIn第一泊Flg, True:开启,False:关闭
					bItem.configXmlItem.firstNightCheckInFlg = Boolean.valueOf( CommUtils.nullToBlank(firstNightCheckInFlgFields.getText()) );
				}
				if (firstNightPaymentCodeFields != null) { // 0泊/1泊时支付商品Code
					String pCode = CommUtils.nullToBlank(firstNightPaymentCodeFields.getText());
					if(paymentInfoMap.containsKey(pCode)) bItem.configXmlItem.firstNightPaymentItem = paymentInfoMap.get(pCode);
				}
				if (nNightPaymentCodeFields != null) { // 多泊时支付商品Code
					String pCode = CommUtils.nullToBlank(nNightPaymentCodeFields.getText());
					if(paymentInfoMap.containsKey(pCode)) bItem.configXmlItem.nNightPaymentItem = paymentInfoMap.get(pCode);
				}
				// 2019/05/15 最終泊の設定対応 WGCH BEGIN
				if (lastNightPaymentCodeFields != null) { // 多泊时支付商品Code
					String pCode = CommUtils.nullToBlank(lastNightPaymentCodeFields.getText());
					if(!CommUtils.isBlank(pCode)){
						bItem.configXmlItem.lastNightPaymentFlg = true; // 只要设置上TAB就认为最终泊设定功能打开
						if(paymentInfoMap.containsKey(pCode)) bItem.configXmlItem.lastNightPaymentItem = paymentInfoMap.get(pCode);
					}
				}
				// 2019/05/15 最終泊の設定対応 WGCH END
			}
		} catch(Exception e){}
	}
	// Batch全局变量集合Info
	public class BatchVariableInfo{
		/*
		* 预约处理变量
		*/
		public String shopCode; // 店铺CODE
		public Date checkInDate; // 处理日(到着日)
		public Integer leadCheckInSize; // 已经checkIn的预约件数
		// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH BEGIN
		public Set<String> shopCodeSet; // 剩余为执行的shopCodeSet
		// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH END
		public Map<String, LeadNightInfo> leadNightInfoMap; // 当天的所有预约的数据集
		/*
		* 会计处理变量
		*/
		public Id rsvAccId; // 売上Id
		public Decimal taxRate; // 消费税
		public List<Id> accAcountIdLst; // 会计Id
		public Map<Id, AccountAcount__c> accAcountMap; // 所有会计
		/*
		* Xml配置变量
		*/
		public ConfigXmlInfo configXmlItem; // Xml配置数据集
		// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH BEGIN
		/*
		public BatchVariableInfo(String shopCode, Date checkInDate){
			this.shopCode = shopCode;
			this.checkInDate = checkInDate;
			leadCheckInSize = 0;
			leadNightInfoMap = new Map<String, LeadNightInfo>();
		}
		*/
		public BatchVariableInfo(String shopCode, Date checkInDate){
			init();
			this.shopCode = shopCode;
			this.checkInDate = checkInDate;
		}
		public BatchVariableInfo(Set<String> spcdSet, Date checkInDate){
			init();
			for(String spcd : spcdSet){ // 获取有效店铺code
				shopCode = spcd;
				break;
			}
			spcdSet.remove(shopCode); // 去掉当前code
			this.shopCodeSet = spcdSet;
			this.checkInDate = checkInDate;
		}
		public void init(){
			shopCode = '';
			leadCheckInSize = 0;
			shopCodeSet = new Set<String>();
			leadNightInfoMap = new Map<String, LeadNightInfo>();
		}
		// 2019/01/30 支払いメディアの一括自動入力のスケジュール処理機能対応 WGCH END
		// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH BEGIN
		public Set<String> accIdSet;
		public BatchVariableInfo(String shopCode, Date checkInDate, Set<String> accIdSet){
			init();
			this.shopCode = shopCode;
			this.checkInDate = checkInDate;
			this.accIdSet = accIdSet;
		}
		// 2019/06/28 支払いメディアの対象の予約の一覧表示機能 WGCH END
	}
	// Xml 配置文件数据Info
	public class ConfigXmlInfo{
		public Boolean autoCheckInFlg; // 除第一泊以外CheckInFlg
		public Boolean firstNightCheckInFlg; // 前提autoCheckInFlg为True => 第一泊CheckInFlg
		public PaymentInfo firstNightPaymentItem; // 0泊/一泊 => 支付商品信息
		public PaymentInfo nNightPaymentItem; // 多泊 => 支付商品信息
		// 2019/05/15 最終泊の設定対応 WGCH BEGIN
		public Boolean lastNightPaymentFlg; // 最终泊设定flg
		public PaymentInfo lastNightPaymentItem; // 最終泊 => 支付商品信息
		// 2019/05/15 最終泊の設定対応 WGCH BEGIN
		public ConfigXmlInfo(){
			autoCheckInFlg = firstNightCheckInFlg = false;
			firstNightPaymentItem = new PaymentInfo();
			nNightPaymentItem = new PaymentInfo();
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			lastNightPaymentFlg = false;
			lastNightPaymentItem = new PaymentInfo();
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
		}
	}
	// 支付商品数据Info
	public class PaymentInfo{
		public String paymentId; // 支付商品Id
		public String paymentNm; // 支付商品名
		public String paymentCd; // 支付商品Code
		public String actionTp; // 商品処理種別
		public String paymentTp; // 支付商品支付处理种别
		public String mediaType; // 支付商品Media种别
		public Boolean isInvalidFlg{get{ return CommUtils.isBlank(paymentId) || 
												CommUtils.isBlank(paymentNm) || 
												CommUtils.isBlank(paymentCd) || 
												CommUtils.isBlank(actionTp) || 
												CommUtils.isBlank(paymentTp) || 
												CommUtils.isBlank(mediaType); }}
		public PaymentInfo(){
			paymentId = paymentNm = paymentCd = actionTp = paymentTp = mediaType = '';
		}
		public PaymentInfo(String id, String name, String code, String actionType, String pType, String mType){
			paymentId = id;
			paymentNm = name;
			paymentCd = code;
			actionTp = actionType;
			paymentTp = pType;
			mediaType = CommUtils.nullToBlank(mType);
		}
	}
	// 预约数据Info
	public class LeadNightInfo{
		public Lead__c lead; // 预约
		public Integer leadNight; // 当前预约是第几泊
		public Boolean leadNightsFlg; // 当前预约是不是多泊Flg
		// 2019/05/15 最終泊の設定対応 WGCH BEGIN
		public Boolean leadLastNightFlg; // 当前预约是不是 最終泊Flg
		// public LeadNightInfo(Lead__c lead, Integer leadNight, Boolean leadNightsFlg){
		public LeadNightInfo(Lead__c lead, Integer leadNight, Boolean leadNightsFlg, Boolean leadLastNightFlg){
		// 2019/05/15 最終泊の設定対応 WGCH END
			this.lead = lead;
			this.leadNight = leadNight;
			this.leadNightsFlg = leadNightsFlg;
			// 2019/05/15 最終泊の設定対応 WGCH BEGIN
			this.leadLastNightFlg = leadLastNightFlg;
			// 2019/05/15 最終泊の設定対応 WGCH END
		}
	}
}