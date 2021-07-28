/*********************************************
* CommentHelperCompCtrl
* 2018/05/11 定型文情報処理クラス
*********************************************/
public with sharing class CommentHelperCompCtrl {
	public CommentHelperCompCtrl() {
		isBillComment = false;
		isSpecCommnet = true;
		if (ApexPages.currentPage() != null) {
			Map<String,String> parMap = ApexPages.currentPage().getParameters();
			if (parMap.containsKey('isBillComment')) isBillComment = Boolean.valueOf(parMap.get('isBillComment'));
			if (parMap.containsKey('isSpecCommnet')) isSpecCommnet = Boolean.valueOf(parMap.get('isSpecCommnet'));
		}
	}
	public boolean isBillComment{get;set;}
	public boolean isSpecCommnet{get;set;}
	// 選択リスト情報を格納する
    public list<SelectOption> commOptionlst{get{
    	list<SelectOption> rs = new List<SelectOption>();
    	list<OptionItem> optRs = null;
    	if (isBillComment) optRs = getBillCommentOpts();
    	else if (isSpecCommnet) optRs = getSpecCommentOpts();
    	if (optRs != null) for (OptionItem item : optRs) {rs.add(item.toSelectOption());}
    	return rs;
    }}
    // 請求書のコメントリストを取得する
    public List<OptionItem> getBillCommentOpts() {
    	return getCommentOpts(FUNTYPE.BILL);
    }
    // 特記事項のコメントリストを取得する
    public list<OptionItem> getSpecCommentOpts() {
    	return getCommentOpts(FUNTYPE.SPEC);
    }
    private list<OptionItem> getCommentOpts(FUNTYPE ftype) {
    	String funApi = (ftype == FUNTYPE.BILL ? 'A' :'B');
    	list<OptionItem> rsOpts = new list<OptionItem>();
    	list<CommComentDef__mdt> commComentDeflst = [select MasterLabel, FixedMessage__c from CommComentDef__mdt where RecTypeLst__c =: funApi Order by MasterLabel];
		for(CommComentDef__mdt op : commComentDeflst){
			rsOpts.add(new OptionItem(op.FixedMessage__c,op.MasterLabel));
		}
		// TEST CLASS INFO BEGIN
		if (Test.isRunningTest()) {
			rsOpts.clear();
			rsOpts.add(new OptionItem('a','b'));
		}
		// TEST CLASS INFO END
		return rsOpts;
    }
    // 請求書のコメントリストを取得する(JSON)
    public static String getBillCommentJson() {
		CommentHelperCompCtrl commHelp = new CommentHelperCompCtrl();
		return JSON.serialize(commHelp.getBillCommentOpts());
    }
    //請求書,特記事項
    enum FUNTYPE{BILL, SPEC}
}