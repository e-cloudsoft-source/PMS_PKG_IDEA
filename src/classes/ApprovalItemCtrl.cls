global with sharing class ApprovalItemCtrl extends CommBaseCtrl {
	// 稟議ID
	public String approvalId{get;set;}
	// 显示行数
	private static final Integer LIST_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
    													? 5 
    													: CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
	
    public ApprovalItemCtrl(ApexPages.StandardController controller){
    	// 获取稟議ID
    	approvalId = controller.getId();
    	// 获取明细数据
    	getApprovalItem();
    }
    // 初期数据取得
    public void getApprovalItem() {
    	// 初期化
    	AppEstItemlst = new list<AppEstItem>();
		list<ApprovalItem__c> queryList = [select Id,Name,refApproval__c,TankawithoutTaxSys__c,GoukeinoneTax__c,
												Tankanonetax__c,ProductName__c,
												RowNo__c,ServiceRate__c,UnitPriceDefKb__c,SpTotal__c,UnitPriceTax__c,
												refAccountMaster__c,refAccountMaster__r.Name,TaxRate__c,Amount__c,UnitPrice__c
												from ApprovalItem__c where refApproval__c=:approvalId order By RowNo__c,Name];
		Integer rowNo = 0;
		for(ApprovalItem__c item : queryList){
			AppEstItemlst.add(new AppEstItem(item,rowNo));
			rowNo++;
		}
        Integer appendRsSize = LIST_INPUT_DEF_ROWS - Math.Mod(AppEstItemlst.size(), LIST_INPUT_DEF_ROWS);
        for (Integer i = 0; i < appendRsSize; i++) {
            AppEstItemlst.add(new AppEstItem(new ApprovalItem__c(refApproval__c = approvalId),AppEstItemlst.size()));
        }
    }
    // 页面保存按钮响应
    public Pagereference upsertData() {
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'unitpricetax__c','tankawithouttaxsys__c','sptotal__c','productname__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.ApprovalItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return null;
		}
		List<String> chkFieldLst = new List<String>{'amountexc__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Approvaldocuments__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldLst, m)) {
			return null;
		}
		if (!CommSecurityUtils.isDeleteable(ApprovalItem__c.getSObjectType())) {
			return null;
		}
		// 2019/09/15 Security Check BY zyz END
		// 登録されている明細データを処理を行う
		List<ApprovalItem__c> updList = new List<ApprovalItem__c>();
		List<ApprovalItem__c> delList = new List<ApprovalItem__c>();
		// 見積画面明細替え
		Map<String,ApprovalItem__c> estItemMap = new Map<String,ApprovalItem__c>();
		List<Approvaldocuments__c> Approval = [select id, Name,DraftDt__c,AmountExc__c from Approvaldocuments__c where Id=:approvalId] ;
		
		if (!Approval.isEmpty()) {
			for ( ApprovalItem__c item : [select Id,Name,refApproval__c,TankawithoutTaxSys__c,GoukeinoneTax__c,
											Tankanonetax__c,ProductName__c,
											RowNo__c,ServiceRate__c,UnitPriceDefKb__c,SpTotal__c,UnitPriceTax__c,
											refAccountMaster__c,refAccountMaster__r.Name,TaxRate__c,Amount__c,UnitPrice__c
											from ApprovalItem__c where refApproval__c=:approvalId order By RowNo__c,Name]) {
				estItemMap.put(item.id,item);
			}
		}
		for (AppEstItem obj: AppEstItemlst) {
			if (obj.sobj.Id != null) estItemMap.remove(obj.sobj.id);
			if (!obj.isValidata) {
                if (obj.sobj.Id != null) delList.add(obj.sobj);
                obj.clear();
                continue;
			}
			obj.sobj.ProductName__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;
			updList.add(obj.sobj);
		}
		if (!estItemMap.isEmpty()) {
			delList.addAll(estItemMap.values());
		}
		updList = autoSetupFieldValue(updList);
		if (!delList.isEmpty()) delete delList;
		if (!updList.isEmpty()) upsert updList;
		Approval[0].AmountExc__c =  CommUtils.nullToZero(totalIncTax);
		update Approval;
		// 更新後の最新情報を取得する
		getApprovalItem();
    	return null;
    	
    }
    private Decimal totalIncTax{get;set;} // 总计值(税拔)
    // 数据计算处理
	private list<ApprovalItem__c> autoSetupFieldValue(list<ApprovalItem__c> newLst){
		Decimal totalInc = 0; // 总计值
		totalIncTax = 0;
		// 计算消费税使用 taxRate:取得的第一个不为0的税率，amountTax:税率不为0商品的合计值
		Decimal taxRate = 0;
		Decimal amountTax = 0;
		list<ApprovalItem__c> applist = new list<ApprovalItem__c>();
        Integer locPointLen = CommUtils.getPointLen();
        map<String,Decimal> totalMap = new map<String,Decimal>();
        map<String,Decimal> totalExcMap = new map<String,Decimal>();
		for (ApprovalItem__c nw: newLst) {
			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(nw.UnitPriceDefKb__c));
      	  	String searchKey = CommUtils.nullToZero(nw.UnitPrice__c) + '_' + CommUtils.nullToZero(nw.Amount__c) + '_' + nw.TaxRate__c  + '_' + nw.ServiceRate__c + '_' + CommUtils.nullToIntZero(nw.UnitPriceDefKb__c);
			priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);

			if (!totalMap.containsKey(searchKey)){
				nw.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax;
				nw.SpTotal__c = priceInfo.priceIncTax;	
				totalMap.put(searchKey,nw.SpTotal__c);
			} else {
				nw.SpTotal__c = totalMap.get(searchKey);
				nw.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax;
			}

            if (locPointLen > 0) {
            	if (!totalExcMap.containsKey(searchKey)){
	           	 	nw.TankawithoutTaxSys__c = priceInfo.unitPriceIncServiceExcTax;    	 	
	           	 	totalExcMap.put(searchKey,nw.TankawithoutTaxSys__c);
            	} else {
            		nw.TankawithoutTaxSys__c = totalExcMap.get(searchKey);
            	}
            }
            nw.UnitPriceTax__c = priceInfo.unitPriceTax; //商品单价単価（税込、サービス料込）
            if(taxRate <= 0) taxRate = CommUtils.nullToIntZero(nw.TaxRate__c);
            if(CommUtils.nullToIntZero(nw.TaxRate__c) > 0) amountTax += CommUtils.nullToIntZero(nw.SpTotal__c);
			totalInc += priceInfo.priceIncTax;
			applist.add(nw);
		}
		Decimal Tax = (amountTax > 0 ? CommUtils.RoundProcess(amountTax / (1 + taxRate / 100) * (taxRate / 100), locPointLen) : 0);
		totalIncTax = totalInc - Tax;
		return applist;
	}
	// 行追加触发
	public Pagereference addBookingItem() {
		Map<Integer, AppEstItem> locSortMap = new Map<Integer, AppEstItem>();
		for (AppEstItem item : AppEstItemlst) {
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.sobj.rowNo__c),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
		
		AppEstItemlst.clear();
		// RowIndex再設定する 
		for (Integer key : sortKeyLst) {
			AppEstItem orgItem = locSortMap.get(key);
			orgItem.index = AppEstItemlst.size();
			AppEstItemlst.add(orgItem);
		}
    	for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
    		AppEstItemlst.add(new AppEstItem(new ApprovalItem__c(refApproval__c = approvalId),AppEstItemlst.size()));
    	}
		return null;
	}
    
    public list<AppEstItem> AppEstItemlst{get;set;}
	// 明細情報格納
	global class AppEstItem {
		// 初期化する
		public AppEstItem(ApprovalItem__c s, Integer rsIndex) {
			sobj = s;
			index = rsIndex;
			rowNo = String.valueOf(rsIndex);
			s.rowNo__c = rsIndex;
			// 商品名
			productNm = CommUtils.isBlank(sobj.ProductName__c) ? s.refAccountMaster__r.Name : sobj.ProductName__c;
            orgProductNm = s.refAccountMaster__r.Name;
			// 数量
			prodNums = CommUtils.deleteRightZero(CommUtils.nullToBLank(s.Amount__c));
			// 単価
			unitPrice = CommUtils.deleteRightZero(CommUtils.nullToBLank(s.UnitPrice__c), CommUtils.getPointLen());
            // 合計金額（税込）
            amoutIncTax = s.SpTotal__c;
            // 合計金額（税抜）
            amoutExcTax = s.GoukeinoneTax__c;
            // 単価定義区分を設定する
            if(CommUtils.isBlank(s.UnitPriceDefKb__c)) s.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
            
			itemId = s.Id;
			refAppId = s.refApproval__c;
		}
		public void clear() {
			productNm = null;
			servicePriceIncTax = null;
			specialTax = null;
			prodNums = null;
			amoutExcTax = null;
			amoutIncTax = null;
		}
		// 明細格納する
		public ApprovalItem__c sobj{get; private set;}
		// 明細Index
		public Integer index{get; private set;}
		// 
		public String itemId{get; set;}
		public String refAppId{get; set;}
		// 商品名
		public String productNm{get;set;}
		// 会計商品マスタの商品名
		public String orgProductNm{get;set;}
		// サービス料金(税込)
		public Decimal servicePriceIncTax{get;set;}
		// 特別料金
		public Decimal specialTax{get;set;}
		public String rowNo{get;set;}
		// 単価
		public String unitPrice{get;set{
			unitPrice = value;
			sobj.UnitPrice__c = CommUtils.nullToZero(unitPrice);
		}}
		// 数量
		public String prodNums{get;set{
			prodNums = value;
			sobj.Amount__c = CommUtils.nullToZero(prodNums);
			}}
		// 会計明細単位の合計金額（税抜）
		public Decimal amoutExcTax{get; set;}
		// 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
        	amoutIncTax = value;
        	if (value !=null && value != sobj.SpTotal__c) sobj.SpTotal__c = value;}}
		public Boolean isValidata{get{
			// 商品コード != null && 単価 != null && 数量 != null
            return (!CommUtils.isBlank(sobj.refAccountMaster__c) &&
                    sobj.UnitPrice__c != null &&
                    sobj.Amount__c != null);
		}}
	}
	
	@remoteAction
	global static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
		return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true, true);
	}
}