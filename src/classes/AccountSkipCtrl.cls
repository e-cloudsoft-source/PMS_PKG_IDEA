public with sharing class AccountSkipCtrl extends CommBaseCtrl{
	// 会計明細【画面】
	public List<BillSimpleInputCtrl.TranItem> oTranSobjLst{get; private set;}
	public LIst<BillSimpleInputCtrl.TranItem> oStickyHeadList{get;private set;}
	// 支払メニューのレイアウト設定情報格納
	public BillSimplePaymentCtrl.PageLayout payLayoutInfo{get; private set;}
	// 会計基本情報[現在画面の会計情報]
	public AccountAcount__c oAcountSobj{get; private set;}
	// 予約基本情報
	public Lead__c orgLeadSobj{get; private set;}
	// 下拉列表信息
	public String leadGroupDataSourceLstJson{get; private set;}
	// select Info
	public String oldAccountId{get; set;}
	public String newAccountId{get; set;}
	public String selectTranIdJson{get; set;}
	public String selectTTendIdJson{get; set;}
	public Boolean autoPrintFlg{get; private set;}
	/**************************
	* 会計飛ばし
	***************************/
	public AccountSkipCtrl(ApexPages.StandardController controller) {
		BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(controller);
		ctrl.initAction();
		oTranSobjLst = new List<BillSimpleInputCtrl.TranItem>();
		for(BillSimpleInputCtrl.TranItem item : ctrl.oTranSobjLst){
			if(item.sobj.UseDate__c == null) continue;
			oTranSobjLst.add(item);
		}
		oStickyHeadList = ctrl.oStickyHeadList;
		// Style
		payLayoutInfo = ctrl.payLayoutInfo;
		// 当前会计信息
		oAcountSobj = ctrl.oAcountSobj;
		// 当前会计ID
		oldAccountId = oAcountSobj.Id;
		// 当前会计对应的预约
		orgLeadSobj = ctrl.orgLeadSobj;
		// レシートに自動印刷开关
		autoPrintFlg = ctrl.autoPrintFlg;
		// 当前会计对应的到着日
		Date eEntryDate = orgLeadSobj.Entrytime__c.date();
		// 到着日前一日
		Date bEntryDate = orgLeadSobj.Entrytime__c.addDays(-1).date();
		// 正常な会計情報
		String ACC_TRADE_NORMAL = CommConst.ACC_TRADE_NORMAL;
		String accSelectStr = ' Select Id, Relreserve__c, Relreserve__r.Name, Relreserve__r.Entrytime__c, Relreserve__r.Rroom__c, Relreserve__r.Rroom__r.Name From AccountAcount__c ';
		String accWhereStr = ' Where Relreserve__c != null And Field39__c =: ACC_TRADE_NORMAL';
		// 予約２０万以上の対応 by zy BEGIN
		// And (DAY_ONLY(convertTimezone(Relreserve__r.EntryTime__c)) =: bEntryDate Or DAY_ONLY(convertTimezone(Relreserve__r.EntryTime__c)) =: eEntryDate) 
		// 2020/08/30 部屋状態管理インデックス機能対応 WGCH BEGIN
		Boolean isFixedFlg1 = DataFixManagerUtils.getInstance().LeadFixed1__c;
		Integer queryBegDtInt = CommUtils.nullToIntZero(CommUtils.dateToYYYYMMDD(bEntryDate)); // 到着日のインデックス
		Integer queryEndDtInt = CommUtils.nullToIntZero(CommUtils.dateToYYYYMMDD(eEntryDate)); // 到着日前一日のインデックス
		Integer cancelLeadFlg = CommConst.LEAD_ST_CANCEL_FLG; // キャンセルフラグ
		String spcd = ctrl.oShopCode; // 店舗コード
		if(isFixedFlg1) accWhereStr += ' And ( Relreserve__r.EntryDateIntKey__c >= :queryBegDtInt and Relreserve__r.EntryDateIntKey__c <=: queryEndDtInt) ';
   		else accWhereStr += ' And (DAY_ONLY(convertTimezone(Relreserve__r.EntryTime__c)) >=: bEntryDate and DAY_ONLY(convertTimezone(Relreserve__r.EntryTime__c)) <=: eEntryDate) ';
   		// キャンセルフラグ
   		accWhereStr += 'And Relreserve__r.CancelBool__c != :cancelLeadFlg';
   		if (!CommUtils.isBlank(spcd)) {
   			accWhereStr += ' and ShopCode__c = :spcd';
   		}
		// 予約２０万以上の対応 by zy END
		// XML自定义Where条件
		if(!CommUtils.isBlank(ctrl.accXmlWhereStr)){
			accWhereStr += ' And ( ' + CommUtils.nullToBlank(ctrl.accXmlWhereStr) + ' ) ';
		}
		String accOrderByStr = ' Order by Relreserve__r.Rroom__r.Seq__c Asc, Name Desc ';
		String accQueryStr = accSelectStr + accWhereStr + accOrderByStr;
		// 预约下拉列表数据集合Lst
		List<LeadGroupDataSource> leadGroupDataSourceLst = new List<LeadGroupDataSource>();
		// 防止一个预约对应的多笔会计的情况下
		Set<String> leadIdSet = new Set<String>();
		// 到着日Lst排序用
		List<String> entrytimeFrmLst = new List<String>();
		// 到着日分组Map
		Map<String, List<AccountAcount__c>> accGroupMap = new Map<String, List<AccountAcount__c>>();
		// 查询处理有效的会计数据信息
		for(AccountAcount__c acc : DataBase.query(accQueryStr)){
			// 过滤当前会计
			if(acc.Id == oldAccountId || leadIdSet.contains(acc.Relreserve__c)) continue;
			// 过滤同一笔预约下的多笔会计
			leadIdSet.add(acc.Relreserve__c);
			// 到着日
			String entrytimeFrm = acc.Relreserve__r.Entrytime__c.format('yyyy/MM/dd');
			// 根据到着日分组处理
			if(!accGroupMap.containsKey(entrytimeFrm)){
				accGroupMap.put(entrytimeFrm, new List<AccountAcount__c>());
				// 集计到着日
				entrytimeFrmLst.add(entrytimeFrm);
			}
			// 到着日 Group
			accGroupMap.get(entrytimeFrm).add(acc);
		}
		// 到着日 sort
		entrytimeFrmLst.sort();
		// 到着日 倒序显示 2021/12/13、2021/12/12
		for(Integer i = entrytimeFrmLst.size() - 1; i >= 0; i--){
			// 当前到着日
			String entrytimeFrm = entrytimeFrmLst[i];
			// 当前到着日对应的数据集合结构IN THE CLASS
			LeadGroupDataSource leadGroupItem = new LeadGroupDataSource();
			// GROUP显示的信息[例: 2021/12/13]
			leadGroupItem.text = entrytimeFrm;
			// GROUP内包含的信息
			for(AccountAcount__c acc : accGroupMap.get(entrytimeFrm)){
				// 预约信息
				LeadDataSource leadItem = new LeadDataSource();
				// 预约对应的会计Id
				leadItem.accid = CommUtils.nullToBlank(acc.Id);
				// 下拉列表展现的信息[例: 401（2-1泊目 陣屋太郎）]
				leadItem.roomnm = CommUtils.nullToBlank(acc.Relreserve__r.Rroom__r.Name);
				leadItem.text = leadItem.roomnm + '(' + CommUtils.nullToBlank(acc.Relreserve__r.Name) + ')';
				// 预约信息集计
				leadGroupItem.items.add(leadItem);
			}
			// GROUP信息集计
			leadGroupDataSourceLst.add(leadGroupItem);
		}
		// GROUP信息集合JSON转化
		leadGroupDataSourceLstJson = Json.serialize(leadGroupDataSourceLst);
	}
	// 会计明细向指定会计合并处理
	public void updateTranDetail(){
		// 要处理的会计明细Id信息
		List<String> selectTranIdLst = (List<String>)Json.deserialize(selectTranIdJson, List<String>.class);
		// 要处理的会计支付Id信息
		List<String> selectTTendIdLst = (List<String>)Json.deserialize(selectTTendIdJson, List<String>.class);
		// 指定合并的会计
		List<AccountAcount__c> accountLst = [Select Id, frs__c From AccountAcount__c Where Id =: newAccountId];
		if(accountLst.isEmpty()) return;
		AccountAcount__c toAccountSobj = accountLst[0];
		List<Tran1__c> newTran1Lst = [Select RowNo__c From Tran1__c Where Field1__c =: newAccountId And RowNo__c != null order by RowNo__c Desc];
		// 最大RowNo处理
		Decimal newMaxRowNo = 0;
		if(!newTran1Lst.isEmpty()){
			newMaxRowNo = CommUtils.nullToZero(newTran1Lst[0].RowNo__c);
		}
		List<TTend__c> newTtendLst = [Select RowNo__c From TTend__c Where Field1__c =: newAccountId And RowNo__c != null order by RowNo__c Desc];
		if(!newTtendLst.isEmpty()){
			newMaxRowNo = newMaxRowNo > CommUtils.nullToZero(newTtendLst[0].RowNo__c) ? newMaxRowNo : CommUtils.nullToZero(newTtendLst[0].RowNo__c);
		}
		// 需要合并的会计明细信息
		List<Tran1__c> tran1Lst = new List<Tran1__c>();
		if(!selectTranIdLst.isEmpty()){
			tran1Lst = [Select Id, RowNo__c, Field1__c, RelAccount__c From Tran1__c Where Id in: selectTranIdLst]; // And Field1__c =: oldAccountId
			for(Tran1__c tran : tran1Lst){
				newMaxRowNo++;
				// RowNo.
				tran.RowNo__c = newMaxRowNo;
				// 会計ID
				tran.Field1__c = toAccountSobj.Id;
				// 売上ID
				tran.RelAccount__c = toAccountSobj.frs__c;
			}
		}
		// 需要合并的会计支付信息
		List<TTend__c> ttendLst = new List<TTend__c> ();
		if(!selectTTendIdLst.isEmpty()){
			ttendLst = [Select Id, RowNo__c, Field1__c, RelAccount__c From TTend__c Where Id in: selectTTendIdLst]; // And Field1__c =: oldAccountId
			for(TTend__c ttend : ttendLst){
				newMaxRowNo++;
				// RowNo.
				ttend.RowNo__c = newMaxRowNo;
				// 会計ID
				ttend.Field1__c = toAccountSobj.Id;
				// 売上ID
				ttend.RelAccount__c = toAccountSobj.frs__c;
			}
		}
		if(!tran1Lst.isEmpty()) update tran1Lst;
		if(!ttendLst.isEmpty()) update ttendLst;
		// POSレジ連携時の挙動
		/*
		ApexPages.StandardController controller = new ApexPages.StandardController(new AccountAcount__c(Id = toAccountSobj.Id));
		BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(controller);
		ctrl.initAction();
		ctrl.print(selectTranIdLst, selectTTendIdLst);
		*/
	}
	public class LeadGroupDataSource{
		public LeadGroupDataSource(){
			text = '';
			expanded = true;
			items = new List<LeadDataSource>();
		}
		public String text{get; set;}
		public Boolean expanded{get; set;}
		public List<LeadDataSource> items{get; set;}
	}
	public class LeadDataSource{
		public LeadDataSource(){
			accid = roomnm = text = '';
		}
		public String accid{get; set;}
		public String roomnm{get; set;}
		public String text{get; set;}
	}
}