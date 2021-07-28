/**
* 指定期間を超える支払明細に対して、消込されない場合、エラーリストをChatterへポストする
**/
public with sharing class BulkProcessNoPaymentAlertBatch  implements Database.Batchable<Sobject>, Database.Stateful, Schedulable {
    // 店舗コード
    private final String gShopCode;             
    // 売上計上日日[開始]
    private String gBegYmd;
    // 売上計上日[終了日]
    private String gEndYmd;
    // スケジュールからバッチ起動する
    private Boolean isFromSchedule; 
    // エラー処理リストを格納する
    private List<NoPaymentInfo> gErrLst;
    // 消込対象データリストSQL
    // 未入金　かつ　期限設定の支払明細を取得する
    private static String Query = 'select id, Field29__c, Field1__c,PayProductRef__r.PayLimitDays__c,RelAccount__r.Salesday__c,ShopCodeCal__c,PayProductName__c from TTend__c where PayProductRef__r.PayLimitDays__c > 0 and ClearFlg__c != true ';
    // スケジュールから起動されれう場合
    public BulkProcessNoPaymentAlertBatch () {
     	 // システム日と処理日の差異日数
      	Integer days = CommDefine__c.getOrgDefaults().SchedulePayCheckDays__c == null ? 0 : CommDefine__c.getOrgDefaults().SchedulePayCheckDays__c.intValue();
      	Date startDate = (Date.today().addDays(days));
        gBegYmd = CommUtils.dateToYYYYMMDD(startDate);
        gEndYmd = CommUtils.dateToYYYYMMDD(startDate);
        gShopCode = null;
    }
    // バッチから起動される場合
    // またはスケジュールからバッチの起動
    public BulkProcessNoPaymentAlertBatch (String pShopCd, Date pSaleBegDate, Date pSaleEndDate) {
        gBegYmd = CommUtils.dateToYYYYMMDD(pSaleBegDate);
        gEndYmd = CommUtils.dateToYYYYMMDD(pSaleEndDate);
        gShopCode = pShopCd;
        gErrLst = new List<NoPaymentInfo>();
    }
    // ***********************************
    // スケジュール処理開始
    // ***********************************
    public void execute(SchedulableContext SC) {
        BulkProcessNoPaymentAlertBatch batch = new BulkProcessNoPaymentAlertBatch(
        	gShopCode, 
        	CommUtils.stringToDate(gBegYmd), 
        	CommUtils.stringToDate(gEndYmd)
        );
        DataBase.executeBatch(batch);
    }
    
    // ***********************************
    // バッチ処理開始
    // ***********************************
    public Database.QueryLocator start(Database.BatchableContext BC){
        String whereSQL = (CommUtils.isBlank(gShopCode)) ? '' : (' And ShopCodeCal__c = :gShopCode ');
        whereSQL += ' And (RelAccount__r.Name >= :gBegYmd And  RelAccount__r.Name <= :gEndYmd) ';
        //並び順情報を設定する
        String orderSQL = ' Order By ShopCodeCal__c, RelAccount__r.Name, Name';
System.debug(loggingLevel.info, 'SQL='+Query + whereSQL + orderSQL);
System.debug(loggingLevel.info, 'gBegYmd='+gBegYmd);
System.debug(loggingLevel.info, 'gEndYmd='+gEndYmd);
        return Database.getQueryLocator(Query + whereSQL + orderSQL);
    }
    // ***********************************
    // バッチロジック処理開始
    // ***********************************
    public void execute(Database.BatchableContext BC, List<TTend__c> scope){
        // 支払明細に未入金　かつ期限超える場合、アラート情報を集める
        Date sysDt = Date.today();
        for (TTend__c td : scope) {
            // 売上計上日
            Date salesDt = td.RelAccount__r.Salesday__c;
            // システム日
            Integer days = salesDt.daysBetween(sysDt);
            // 制限日数を超える場合、エラー対象になる
            if (td.PayProductRef__r.PayLimitDays__c < days) gErrLst.add(new NoPaymentInfo(td));
        }
    }
    
    // ***********************************
    // バッチ終了処理開始
    // ***********************************
    public void finish(Database.BatchableContext BC){
        // Chatterのグループへポストする
        // メール通信する
        if (gErrLst != null) sendAlertMessage(gErrLst);
    }
    /**
    * メール送信機能対応:
    **/
    private void sendAlertMessage(List<NoPaymentInfo> pErrLst) {
        
        // 連携結果履歴に記録する
        // メール情報を設定する
        //　商品在庫バッチが以下の通リ終了しましたのでお知らせいたします。
        String mailBodyStr = '\n\n' + '未入金チェック処理が以下の通リ終了しましたのでお知らせいたします。';
        mailBodyStr += '\n' + 'チェック対象売上日期間:'+gBegYmd+'-'+gEndYmd;
        // 店舗別未入金の対象リスト
        map<String,List<Integer>> shopInfMap = new map<String, List<Integer>>();
        for (Integer i=0; i<pErrLst.size();i++) {
            String spcd = pErrLst[i].shopcd;
            if (!shopInfMap.containsKey(spcd)) shopInfMap.put(spcd, new List<Integer>());
            shopInfMap.get(spcd).add(i);
        }
        List<String> shopSortLst = new List<String>(shopInfMap.keySet());
        shopSortLst.sort();
        for (String spcd : shopSortLst) {
        	List<Integer> arrIdxs = shopInfMap.get(spcd);
            if (!CommUtils.isBlank(spcd)) mailBodyStr += '\n\n' + '店舗コード:'+spcd;
            mailBodyStr += '\n' + '未入金件数：'+arrIdxs.size()+'件';
            for (Integer idx : arrIdxs) {
                // 未支払の詳細情報を取得する
                NoPaymentInfo inf = pErrLst[idx];
                mailBodyStr += '\n会計：'+CommConst.SF_PROR_BASEURL+'/'+inf.accountId;
                mailBodyStr += '\n未入金('+inf.payName+')：'+CommUtils.numberFormat(inf.payAmount);
                mailBodyStr += '\n';
            }
        }
        // 送信対象データ場合、データなしメッセージを送信する
        if (pErrLst.isEmpty()) mailBodyStr += '\n' + '未入金件数：0件';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //POS取込バッチ処理結果の通知
        mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ '未入金チェック処理バッチ結果の通知');
        mail.setPlainTextBody(mailBodyStr);
        // Chatterへポストする　
        sendMsgToChatter(mail, mailBodyStr);
        // テストクラスの場合、実施しない 
        // メール送信
        String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
        // メールアドレス未設定する場合、メール送信しない
        if (CommUtils.isBlank(mailAdds)) return;
        String[] toAddresses = mailAdds.split(',');
        mail.setToAddresses(toAddresses);
        // 送信できるがどうか、チェックを行う
        Boolean canSendMail = true;
        try {
            Messaging.reserveSingleEmailCapacity(toAddresses.size());
        } catch (Exception e){ canSendMail = false; }
        // 送信可能の場合、メール送信を行う
        if(!Test.isRunningTest() && canSendMail) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
    /**
    * ChatterGroup送信機能対応:
    **/
    private void sendMsgToChatter(Messaging.SingleEmailMessage mail, String pMsgBody) {
        // 
        List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.PAY_ChatterCheckType);
        List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
        if (chatterGroups.isEmpty()) return;

        String msgBody = mail.getSubject();
        msgBody += pMsgBody;
        
        List<FeedItem> feedItems = new List<FeedItem>();

        for (CollaborationGroup cGroup : chatterGroups) {
            
            FeedItem post = new FeedItem();
            post.Type = 'TextPost';
            post.Body = msgBody;
            post.ParentId = cGroup.Id;
            feedItems.add(post);
        }
        // テスト以外、メッセージをポストする
        if(!Test.isRunningTest() && !feedItems.isEmpty()) insert feedItems;
    }
    class NoPaymentInfo {
        public NoPaymentInfo(TTend__c td) {
            shopcd = CommUtils.nullToBlank(td.ShopCodeCal__c);
            accountId = td.Field1__c;
            payName = CommUtils.nullToBlank(td.PayProductName__c);
            payAmount = CommUtils.nullToZero(td.Field29__c);
        }
        public String shopcd{get;set;}
        public String accountId{get;set;}//会計ID
        public String payName{get;set;}//支払商品名
        public Decimal payAmount{get;set;}//$支払　金額
    }
}