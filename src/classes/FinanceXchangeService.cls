/**
* 為替レート取得機能サビース
* Ver1.0 為替レートAPIで為替レート取得する
* Ver1.1 レート取得区分追加（買、売、中点）
* Ver1.2 為替レートはUSD→JPY固定取得から組織の通貨コード→JPYを取得機能対応
**/
public without sharing class FinanceXchangeService implements Schedulable {
	

	private static final String QueryTemplate = 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22$_FROMCURRENCY_$$_TOCURRENCY_$%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=';
	
	private static final String RESUT_KEY_QUERY = 'query';
	private static final String RESUT_KEY_Q_RESULT = 'results';
	private static final String RESUT_KEY_Q_R_RATE = 'rate';
	
	private static final String RESUT_KEY_Q_R_R_ASK= 'Ask';
	private static final String RESUT_KEY_Q_R_R_RATE= 'Rate';
	private static final String RESUT_KEY_Q_R_R_BID= 'Bid';
	// スケジュール起動
    public void execute(SchedulableContext SC) {
    	//FinanceXchangeService service = new FinanceXchangeService ();
    	// Ver1.2 為替レートはUSD→JPY固定取得から組織の通貨コード→JPYを取得機能対応 BEGIN
    	//String fromCurrency = 'USD';
    	String fromCurrency = CommBaseCtrl.getCurrency();
    	// Ver1.2 為替レートはUSD→JPY固定取得から組織の通貨コード→JPYを取得機能対応 END
    	String toCurrency = 'JPY';
    	Date rateDate = Date.today();
    	FinanceXchangeService.setExchangeRate(fromCurrency, toCurrency, rateDate);
    }
    // 為替レート取得区分：買いレート
    private static final String CONST_RATE_KB_1 = '1';
    // 為替レート取得区分：中点
	private static final String CONST_RATE_KB_2 = '2';
	// 為替レート取得区分：売りレート
	private static final String CONST_RATE_KB_3 = '3';
	@future(callout=true)
	public static void setExchangeRate (String fromCurrency, String toCurrency, Date rateDate){
		// 処理結果フラグ（TRUE：処理正常終了)
		Boolean rsFlg = true;
		Decimal exchangeRate = 0;
		String nameKey = fromCurrency + toCurrency + '_' + (DateTime.newInstance(rateDate.year(), rateDate.month(), rateDate.day())).format(CommBaseCtrl.getDateFormat());
		try {
			// 為替レート取得区分取得
			String strRateKbn = CommUtils.isBlank(CommDefine__c.getOrgDefaults().ExchangeRateApiRateKbn__c) 
								? CONST_RATE_KB_2 
								: CommDefine__c.getInstance().ExchangeRateApiRateKbn__c;
			String rateKbnKey = RESUT_KEY_Q_R_R_RATE;
			if (strRateKbn == CONST_RATE_KB_1) rateKbnKey = RESUT_KEY_Q_R_R_ASK;	// 買うレート
			else if (strRateKbn == CONST_RATE_KB_3) rateKbnKey = RESUT_KEY_Q_R_R_BID;	// 買うレート
			
			// 同じ日付、同じ名前の為替レートが存在する場合、先に削除する
			String endpointurl = QueryTemplate.replace('$_FROMCURRENCY_$', fromCurrency)
											  .replace('$_TOCURRENCY_$',   toCurrency);
	        Http http = new Http();
	        Httprequest searchRequest = new Httprequest();
	        searchRequest.setEndpoint(endpointurl);
	        searchRequest.setMethod( 'GET');
	        searchRequest.setTimeout(60000);
	        
			// Rate取得する 	
			Httpresponse searchResponse = http.send(searchRequest);
            String jsonString = searchResponse.getBody();

            Map<String,Object>rs1 = (Map<String,Object>)JSON.deserializeUntyped(jsonString);
            Map<String,Object> queryMap = (Map<String,Object>)rs1.get(RESUT_KEY_QUERY);
            Map<String,Object> resultMap = (Map<String,Object>)queryMap.get(RESUT_KEY_Q_RESULT);
            Map<String, Object> rsRateMap = (Map<String,Object>)resultMap.get(RESUT_KEY_Q_R_RATE);
            exchangeRate = CommUtils.nullToZero(String.valueOf(rsRateMap.get(rateKbnKey)));
		} catch (Exception ex){
			sendMail(rateDate, ex,null,null,null);
			return;
		}
		// SavePoint
		Savepoint sp = Database.setSavepoint();
		try {
			// 2019/09/15 Security Check BY zyz BEGIN
			if (!CommSecurityUtils.isDeleteable(ExchangeRate__c.getSObjectType())) {
				return;
			}
			// 2019/09/15 Security Check BY zyz END
			// 関連処理LOCKする
			List<ExchangeRate__c> existRateList = [select id from ExchangeRate__c where Name = :nameKey And RateDate__c = :rateDate for update];
			if (!existRateList.isEmpty()) delete existRateList;
			
			// 為替レート登録する
			ExchangeRate__c newRate = new ExchangeRate__c(
				Name = nameKey,
				FromCurrency__c = fromCurrency,
				ToCurrency__c = toCurrency,
				RateDate__c = rateDate,
				Rate__c = exchangeRate
			);
			insert newRate;
		
        } catch (Exception ex){
            
            Database.rollback(sp);
            rsFlg = false;
        	// レート取得後のメール送信
        	sendMail(rateDate, ex,null,null,null);
        	return;
        	//throw New CommException('処理エラーが発生しました。('+ex.getmessage()+')');
        }
        // レート取得後のメール送信
        sendMail(rateDate, null,exchangeRate,fromCurrency,toCurrency);
	}
	
	// 処理結果の送信処理
	private static void sendMail(Date pdate, Exception e,Decimal newRate, String fromCurrency, String toCurrency) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		// メール情報を設定する
		String alertMessage = '';
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if (CommUtils.isBlank(mailAdds)) return;
		
		if (e != null) {
			// エラーが発生しました
			//為替レートの取得に失敗しました。
			alertMessage += Label.MSG_006_0325 +'\n\n';
			//エラー内容：
			alertMessage += Label.MSG_006_0326 + String.valueOf(e);
		} else {
			//為替レートの取得が正常に完了しました。
			alertMessage += Label.MSG_006_0327 + '\n\n';
			//日付:
			//(USDー＞JPY)の為替レート:
			//alertMessage += Label.MSG_006_0328 + pdate.format()+ Label.MSG_006_0329 + newRate;
			alertMessage += Label.MSG_006_0328 + pdate.format()+ '('+ fromCurrency +'ー＞'+toCurrency+')' +Label.MSG_006_0329 + newRate;
		}
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		//為替レート取得結果の通知
		//正常
		//エラー
		mail.setSubject('['+UserInfo.getOrganizationName()+']'+ Label.MSG_006_0330 +'('+(e == null ? Label.MSG_006_0331:Label.MSG_006_0332)+')');
		mail.setPlainTextBody(alertMessage);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest())
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		
	}
	
}