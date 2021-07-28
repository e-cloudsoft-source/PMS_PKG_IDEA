public with sharing class PaginationUtil {

	private Apexpages.Standardsetcontroller ssc; //改ページコントローラ
	//public String pageNumber{get;set;} //入力ページ番号
	public list<String> displayColums{get;set;}

	public transient Boolean mesgFlg{get;set;}

	public PaginationUtil(list<Sobject> lst,Integer pageSize){
		ssc = new Apexpages.Standardsetcontroller(lst);
		ssc.setPageSize(pageSize);
		//pageNumber = pageNum;
	}
	public PaginationUtil(Apexpages.Standardsetcontroller pssc,Integer pageSize){
		ssc = pssc;
		ssc.setPageSize(pageSize);
	}
	public Integer getPageSize() {
		return ssc.getPageSize();
	}
	public Integer getStartRsNo() {
		return ( ssc.getResultSize() == 0 ? 0 : (ssc.getPageNumber() - 1) * ssc.getPageSize() + 1);
	}
	public Integer getEndRsNo() {
		Integer rsSize = ssc.getPageNumber() * ssc.getPageSize();
		return (rsSize > ssc.getResultSize() ? ssc.getResultSize() : rsSize);
	}
	public Integer getTotalRs() {
		return ssc.getResultSize();
	}
    /*
     * 機能： 改ページ：最初ページ
     */
    public void firstPage(){
        ssc.first();//改ページ：最初ページ
        //pageNumber = pageNum;
    }
    /*
     * 機能： 改ページ：最後ページ
     */
    public void lastPage(){
        ssc.last();//改ページ：最後ページ
        //pageNumber = pageNum;
    }
    /*
     * 機能： 改ページ：前ページ
     */
    public void previousPage(){
        ssc.previous();//改ページ：前ページ
        //pageNumber = pageNum;
    }
    /*
     * 機能： 改ページ：次のページ
     */
    public void nextPage(){
        ssc.next();//改ページ：次のページ
        //pageNumber = pageNum;
    }
    /*
     * 機能： 改ページ：指定したページ番号のページ
     *//*
    public void changePage(){
        Integer toPageNum;
        try{
            //数値に転換する
            toPageNum = Integer.valueOf(pageNumber);
            //総ページを超える場合、最後ページへ
            if(toPageNum > Integer.valueOf(pageCount)) {
            	toPageNum = Integer.valueOf(pageCount);
            	pageNumber = pageCount;
            }

            if(toPageNum < 1) {
            	toPageNum = 1;
            	pageNumber = '1';
            }

        }catch(exception e){
            //数値以外の場合、エラーメッセージを表示して終了する
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'ページ番号に数字を入力してください。'));
            mesgFlg = true;
            return;
        }
        ssc.setPageNumber(toPageNum);//改ページ：指定したページ番号のページ
    }*/

    //総ページ数
    public String pageCount {
        get {
            return  String.valueOf(Math.Ceil(double.valueOf(ssc.getResultSize())/double.valueOf(ssc.getPageSize())).intValue());
        }
        set;
    }
    //現在のページ番号
    public String pageNum {
        get {
            return  String.valueOf(ssc.getPageNumber());
        }
        set;
    }

    public list<Sobject> records{
    	get {
            return  ssc.getRecords();
        }
        set;
    }
}