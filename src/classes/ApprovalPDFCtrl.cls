public with sharing class ApprovalPDFCtrl {
	public id approvalId{get;set;}
	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
	public static boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} private set;}
	// 2019/07/30 軽減税率機能対応 WGCH END
    public ApprovalPDFCtrl(ApexPages.StandardController controller){
    	bulkPageList = new list<OneStamp>();
    	allPageLst = new list<PageItem>();
    	// 対象データID
    	approvalId = controller.getId();
    	// 既存データを取得する
    	list<Approvaldocuments__c> ApprovalList = [select Id,Name,CreatedDate,
		        										RowNo__c,Kamoku__c,DraftUser__c,DraftDt__c,DraftDepart__c,
		        										AmountExc__c,LastProcessDt__c,Purpose__c,ApprovalProgress__c,
		        										DraftUser__r.Name
		        										from Approvaldocuments__c where Id =:approvalId];
		if (ApprovalList.isEmpty()) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'レコードは削除されました。'));
			return;
		}
		// 稟議明細
		getApprovalDetail();
		// 既存データ
		for(Approvaldocuments__c a : ApprovalList){
			for (Integer index =0; index < purLst.size(); index++) {
				Integer breakLine = index - (allPageLst.isEmpty() ? 0 : 1) * 7 - (allPageLst.size() > 1 ? allPageLst.size() -1 : 0 ) * 28;
				if(breakLine == 0){
	                PageItem prodRep = new PageItem(a);
	                prodRep.addItem(purLst[index]);
					allPageLst.add(prodRep);
					prodRep.currPages = allPageLst.size();
				}else{
					PageItem prodRep = allPageLst[allPageLst.size() - 1];
	                prodRep.addItem(purLst[index]);
				}
			}
	        if (allPageLst.isEmpty()) {
	        	PageItem prodRep = new PageItem(a);
	        	allPageLst.add(prodRep);
	        }
	        PageItem lastPage = allPageLst[allPageLst.size()-1];
	        // 明細行数確認する
	        Integer breakNum = (lastPage.currPages == 1 ? 7 :28);
	        if (lastPage.onePageList.size() < breakNum) {
	            Integer dumyLen =breakNum - lastPage.onePageList.size();
	            for (Integer i = 0; i < dumyLen; i++) {
	                purItem dumyItem = new purItem(new ApprovalItem__c(),purLst.size()+i+1, pointlen);
	                lastPage.addItem(dumyItem);
	            }
	        }
		}
		// 申請中と承認済みのデータを取得する
		set<id> processIdSet = new set<id>();
		list<ProcessInstance>  processlist= [select id,CreatedDate,LastModifiedById,ProcessDefinitionId,SubmittedById,SubmittedBy.Name,SubmittedBy.Department,SystemModstamp,Status from ProcessInstance where TargetObjectId =: approvalId order by CreatedDate desc limit 1];
		for(ProcessInstance p : processlist){
			if(p.Status !='Rejected') processIdSet.add(p.Id);
		}
		if (processIdSet.isEmpty()) return;
		// 承認プロセスの内容詳細を取得する
		list<ProcessInstanceStep>  processSteplist= [SELECT Actor.Name,CreatedDate,CreatedBy.Department,SystemModstamp,ProcessInstance.Status FROM ProcessInstanceStep where ProcessInstanceId =:processIdSet AND StepStatus =:'Approved' order by SystemModstamp asc];
		PageItem onePage = allPageLst[0];
		Integer valNum = 1;
		for(ProcessInstanceStep s : processSteplist){
			if(s.ProcessInstance.Status != 'Approved') valNum = 0;
			String timeStr = s.SystemModstamp.format('yyyy.MM.dd HH:mm:ss');
			onePage.addStamp(new StampItem(s.Actor.Name,timeStr,s.CreatedBy.Department,valNum));
			valNum++;
		}  	
		
    }
    // 数据取舍处理
    private Integer pointlen{get; private set;}
    private void getApprovalDetail(){
    	// 根据稟議获取稟議明細
		list<ApprovalItem__c> queryList = [select Id,Name,refApproval__c,TankawithoutTaxSys__c,GoukeinoneTax__c,
												UnitPriceDefKbCal__c,Tankanonetax__c,ProductName__c,
												RowNo__c,ServiceRate__c,UnitPriceDefKb__c,SpTotal__c,UnitPriceTax__c,
												refAccountMaster__c,refAccountMaster__r.Name,TaxRate__c,Amount__c,UnitPrice__c
												from ApprovalItem__c where refApproval__c=:approvalId order By RowNo__c,Name];
    	String currencyInf = UserInfo.getDefaultCurrency();
    	pointlen = CommUtils.getPointLen(currencyInf);
    	purLst = new List<purItem>();
    	amountExc = 0;
    	// 计算消费税使用 taxRate:取得的第一个不为0的税率，amountTax:税率不为0商品的合计值
    	Decimal taxRate = 0;
    	Decimal amountTax = 0;
    	Tax = 0;
    	if (queryList.isEmpty()) return ;
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	Decimal taxUnitPrice = 0;
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	// 仕入明细处理
    	for(ApprovalItem__c pur : queryList){
    		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    		if(isReducedTaxFlg){
    			// 数量
	            Decimal qty = CommUtils.nullToZero(pur.Amount__c);
    			CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo(CommUtils.nullToIntZero(pur.UnitPriceDefKbCal__c));
	            CommLogicProcess.HotelTaxInfo hotelTaxItem = CommLogicProcess.getHotelTaxInfo(null, null, CommUtils.nullToZero(pur.UnitPrice__c), qty, pur.TaxRate__c, pur.ServiceRate__c, priceInfo, null);
	            // 重置最新的PriceInfo
	            priceInfo = hotelTaxItem.priceInfo;
	            // 最终单价重置
	            pur.UnitPriceTax__c = priceInfo.unitPriceTax;
	            // 最终消费税重置
	            taxUnitPrice += priceInfo.priceTax * qty;
	            // BRK行—合计值-赋值
	            pur.SpTotal__c = pur.UnitPriceTax__c * qty;
    		}
    		// 2019/07/30 軽減税率機能対応 WGCH END
    		amountExc += CommUtils.nullToIntZero(pur.SpTotal__c);
    		if(taxRate <= 0) taxRate = CommUtils.nullToIntZero(pur.TaxRate__c);
    		if(CommUtils.nullToIntZero(pur.TaxRate__c) > 0) amountTax += CommUtils.nullToIntZero(pur.SpTotal__c);
    		purLst.add(new purItem(pur,CommUtils.nullToIntZero(pur.RowNo__c)+1,pointlen));
    	}
    	// 计算内消费税
    	Tax = (amountTax > 0 ? CommUtils.RoundProcess(amountTax / (1 + taxRate / 100) * (taxRate / 100), pointLen) : 0);
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	if(isReducedTaxFlg) Tax = taxUnitPrice;
    	// 2019/07/30 軽減税率機能対応 WGCH END
    }
    // 数值格式化
    public String numberFormat{get{return CommBaseCtrl.getNumberFormat();}}
    // 货币符号
    public String getCurrencySybmol(){ return CommBaseCtrl.getCurrencySybmol();}
    public Decimal amountExc{get;set;}			// 合計金額
    public Decimal Tax{get;set;}				// 内消費税
    public transient List<OneStamp> bulkPageList{get;private set;}
    public class OneStamp {
    	public OneStamp() {
    		allPageList = new list<PageItem>();	
    	}
    	public Boolean isFirstPage{get;set;}
    	public list<PageItem> allPageList{get;private set;}
    }
    // 数据
    public List<PageItem> allPageLst{get;set;}
    public class PageItem{
    	public Approvaldocuments__c sobj{get; private set;}
    	// 承认印章list
    	public list<StampItem> stampLst{get;set;}
    	// 仕入明细商品list
    	public list<purItem> onePageList{get; private set;}
    	public PageItem(Approvaldocuments__c app){
    		onePageList = new List<purItem>();
    		stampLst = new list<StampItem>();
    		sobj = app;
    		currPages = 1;
    	}
    	// 仕入明细数据
		public void addItem(purItem item) {
			onePageList.add(item);
		}
		//印章数据
		public void addStamp(StampItem item) {
			stampLst.add(item);
		}
		// 現在表示してページ数
		public Integer currPages{get;set;}
		public Boolean isFirstPage{get{
		  return currPages == 1;
		}}
    }
    // 承认申请印章显示的数据
    public class StampItem{
    	public String nameStr{get;set;} 	// 承认者
    	public String dateStr{get;set;} 	// 日期时间
    	public String departStr{get;set;} 	// 部门(暂时不使用，不确认是否需要调整)
    	public Integer indexNo{get;set;} 	// 印章序号(确认是否是最终承认)
    	public StampItem(String US,String DT,String UD,Integer indexRow){
    		indexNo = indexRow;
    		nameStr = US;
    		dateStr = DT;
    		departStr = UD;
    	}
    }
    // 仕入明细数据处理
    private List<purItem> purLst;
    public class purItem {
    	public Integer rowNo{get;set;}				// 序号
    	public String AccName{get;set;}				// 品名
    	public Decimal unitPrice{get;set;}			// 单价
    	public Decimal quantity{get;set;}			// 数量
    	public Decimal amout{get;set;}				// 小计
    	public Boolean isAccountMasterFlg{get;set;}	// 商品是否存在(不存在时显示为空，无商品数量)
    	public purItem(ApprovalItem__c pur, Integer index,Integer pPointLen) {
    		isAccountMasterFlg = true;
    		if (pur.id == null) isAccountMasterFlg = false;
    		rowNo = index;
    		AccName = CommRepUtils.getPdfMaxShowStringNew(CommUtils.isBlank(pur.ProductName__c) ? pur.refAccountMaster__r.Name : pur.ProductName__c,1,25);
    		unitPrice = CommUtils.nullToIntZero(pur.UnitPriceTax__c);
    		quantity = CommUtils.nullToIntZero(pur.Amount__c);
    		amout = CommUtils.nullToIntZero(pur.SpTotal__c);
    	}
    }
}