public with sharing class DinnerPDFCtrl {
	
	private final static Double LI_MARGIN_LEFT = 0.26; // left and right
	private final static Double FONT_SIZE = 0.4; // font size
	
	private final static Double SUB_ITEM_MARGIN_LEFT = 0.5; // left
	private final static Double SMALL_BITLE_FONT_SIZE = 0.5; // Small bitle font size
	private final static Double SMALL_BITLE_MARGIN_RIGHT = 0; // small titile margin right
	private final static Double PAGE_WIDTH = 25.8; // page width
	public List<Item> fdLst{get; private set;}
	
	private ApexPages.StandardSetController standardController{get; private set;}
	public DinnerPDFCtrl(ApexPages.StandardSetController controller){
		fdLst = new List<Item>();
		this.standardController = controller;
	}
	// PDF内容初期化
    public void initPdf() {
    	// 画面選択会計商品
    	List<AccountMaster__c> selectedAccountMaster = (List<AccountMaster__c>) standardController.getSelected();
    	Set<Id> accSet = new Set<Id>();
    	for(AccountMaster__c am : selectedAccountMaster){
    		accSet.add(am.id);
    	}
    	FoodDetail__c[] fds = [select BreakName__c, DetailType__c,AccountMasterSubRef__r.name,AccountMasterRef__r.name from FoodDetail__c where AccountMasterRef__c = :accSet order by OrderNo__c];
    	// 料理リスト対応
    	Map<String,List<FoodDetail__c>> foodeMap = new Map<String,List<FoodDetail__c>>();
    	for (FoodDetail__c detail : fds) {
    		if (!foodeMap.containsKey(detail.AccountMasterRef__c)) foodeMap.put(detail.AccountMasterRef__c,new List<FoodDetail__c>());
    		foodeMap.get(detail.AccountMasterRef__c).add(detail);
    	}
    	// 料理内容作成
    	for(AccountMaster__c am : selectedAccountMaster){
	    	if (!foodeMap.containsKey(am.id)) continue;
	    	List<FoodDetail__c> foods = foodeMap.get(am.id);
	    	Item item = new Item(foods[0].AccountMasterRef__r.name);
			for(FoodDetail__c fd : foods){
				String s1 = CommUtils.isBlank(fd.AccountMasterSubRef__r.name) ? fd.BreakName__c : fd.AccountMasterSubRef__r.name;
				Item it = item.add(fd.BreakName__c, s1);
				if(it != null){
					fdLst.add(item);
					item = new Item(item);
					item.add(fd.BreakName__c, s1);
				}
			}
			if(item.subItemsLst.size() <= 0) continue;
			fdLst.add(item);
    	}
    	if(fdLst.size() > 0) fdLst.get(0).isFirstItem = true;
    }
    public static RowStr sqlitStr(String str, Integer numInt){	
		Integer[] chars = str.getChars();
		List<List<String>> rLst = new List<List<String>>();
		for(Integer i = 0; i < chars.size(); i++){
			List<Integer> l = new List<Integer>();
			l.add(chars.get(i));
			if(Math.mod(i, numInt) == 0)
				rLst.add(new List<String>());
			rLst.get(i / numInt).add(String.fromCharArray(l));
		}
		return new RowStr(rLst, str);
	}
	public class RowStr{
		public Integer row{get; set;}
		public Integer size{get; set;}
		public String source{get; set;}
		public List<List<String>> strLst{get; private set;}
		public RowStr(List<List<String>> r, String str){
			this.strLst = r;
			this.source = str;
			this.row = r.size();
			this.size = str.length();
		}
	}
	public class Item {
		public Integer pageNum{get; set;}
		public Boolean isFirstItem{get; set;}
		public RowStr bigTitle{get; set;}
		public List<SmallItem> subItemsLst{get; private set;}
				
		public Double width{get; private set;}
		
		public Item(String name){
			this.bigTitle = sqlitStr(name, 25);
			subItemsLst = new List<SmallItem>();
			isFirstItem = false;
			width = 0;
			pageNum = 0;
		}
		
		public Item(Item item){
			this(item.bigTitle.source);
		}
		
		public Item add(String detailType, String breakName){
			if(detailType == null)return null;
			detailType = detailType.trim();
			if(String.isEmpty(detailType) || String.isEmpty(breakName)) return null;
			Double r = new SmallItem().calcWidth(breakName);
			if(width + r > DinnerPDFCtrl.PAGE_WIDTH) return this;
			for(SmallItem sl : subItemsLst){
				if(detailType.equals(sl.subTitle.source)){
					width += r;
					sl.add(breakName);
					return null;
				}
			}
			
			SmallItem sl2 = new SmallItem(detailType);
			Double dt = sl2.subTitle.row * DinnerPDFCtrl.SMALL_BITLE_FONT_SIZE + DinnerPDFCtrl.SMALL_BITLE_MARGIN_RIGHT;
			r = r > dt ? r : dt;
			r += DinnerPDFCtrl.SUB_ITEM_MARGIN_LEFT;
			if(width + r > DinnerPDFCtrl.PAGE_WIDTH)return this;
			sl2.add(breakName);
			width += r;
			subItemsLst.add(sl2);
			return null;
		}
	}
	
	public class SmallItem {
		public RowStr subTitle{get; set;}			
		public List<RowStr> subDetailsLst{get; private set;}
		
		public SmallItem(String subTitle){
			this.subTitle = sqlitStr(subTitle, 6);
			subDetailsLst = new List<RowStr>();
		}
		
		public SmallItem(){}
		
		public void add(String content){
			RowStr rs = sqlitStr(content, 24);
			subDetailsLst.add(rs);
		}
		
		public Double calcWidth(String content){
			RowStr rs = DinnerPDFCtrl.sqlitStr(content, 25);
			Double r = rs.row * DinnerPDFCtrl.FONT_SIZE + DinnerPDFCtrl.LI_MARGIN_LEFT;
			return r;
		}
	}
}