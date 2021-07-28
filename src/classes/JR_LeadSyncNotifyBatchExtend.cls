public with sharing class JR_LeadSyncNotifyBatchExtend implements Database.Batchable < Sobject > , Database.Stateful, Database.AllowsCallouts {
    private CommLogUtils log;
    private final String Query; // 検索SOQL
    //定数
    private static final string CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT = JR_ServiceCtrl.CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT; //'予約取込';
    private static final string CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT; //'予約取込待ち';
    private static final string CONST_RESULT_STATUS_TYPE_XML_IMPORT = JR_ServiceCtrl.CONST_RESULT_STATUS_TYPE_XML_IMPORT; //'XML取込完了';
    //private static final integer CONST_BATCH_EXECUTE_COUNT = 1;
    private static final String SERVICE_KEY = JR_ServiceCtrl.SERVICE_KEY;
    // バッチ重複起動されるチェック
    private boolean isDupFlg = false;
    public JR_LeadSyncNotifyBatchExtend() {
        // 機能種別 = 予約取込 && ステータス = XML取込完了 && 処理種別 = JR
        Query = 'Select Id,Status__c,Name,ErrorCount__c,ProcessLog__c,ErrorContent__c,ManageID__c,ShopCode__c From CooperationResult__c where FunctionType__c = :CONST_RESULT_FUNCTION_TYPE_LEAD_IMPORT and Status__c = :CONST_RESULT_STATUS_TYPE_XML_IMPORT and ParentRef__c = null And ProcessingType__c = :SERVICE_KEY ';
        log = new CommLogUtils('JR_LeadSyncNotifyBatchExtend', true);
    }
    // ***********************************
    // バッチ処理開始  
    // ***********************************
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // 2016/12/14 バッチ重複起動されるチェック
        isDupFlg = (BI_JR_ServiceConfigHelp.isLeadDupStartCheck(BC.getJobId()));
        if (isDupFlg) return Database.getQueryLocator('select id from CooperationResult__c limit 0');
        // JR側へ未通知の管理IDをJRへ送信を行う対象
        return Database.getQueryLocator(Query);
    }
    // ***********************************
    // バッチロジック処理開始
    // ***********************************
    public void execute(Database.BatchableContext BC, List < CooperationResult__c > scope) {
        // 2017/02/21 Field Security Check BEGIN
        List<String> chkFields = new List<String>{'ErrorCount__c','Status__c','ProcessLog__c','ErrorContent__c'};
        Map < String, Schema.SObjectField > m = Schema.SObjectType.CooperationResult__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
            return;
        }
        // 2017/02/21 Field Security Check END
        // Batch Size is 1
        if (scope.isEmpty()) return;
        // 予約取り込み完了通知処理開始
        log.write_method_start('execute');
        // 連携結果[管理]情報を取得する
        CooperationResult__c parentCoo = scope[0];
        // 該当連携結果の店舗コード情報を取得する
        String shopCode = CommUtils.nullToBlank(parentCoo.ShopCode__c);
        if (!BI_JR_ServiceConfigHelp.isContractShop(shopCode)) return;
        // 2016/08/08 JRの通信API処理結果はNGでも次の処理を続ける処理できるように変更 BEGIN
        String preLogMsg = CommUtils.nullToBlank(parentCoo.ProcessLog__c);
        if (!CommUtils.isBLank(preLogMsg)) preLogMsg += '\n';
        // 2016/08/08 JRの通信API処理結果はNGでも次の処理を続ける処理できるように変更 END
        Boolean isOkFlg = false;
        // 最大５回まで通知APIを呼び出す、
        for (Integer i = 1; i <= 5; i++) {
            log.write_log('******6.3予約確認 API 呼出開始[' + i + ']******');
            JR_ServiceCtrl.ConfirmBookingReply rep = callOutputCompleteService(parentCoo.ManageID__c, shopCode);
            // 処理結果が成功の場合[該当予約関連のAPI]
            if (rep.commonResponse.isSuccess) {
                log.write_log('******6.3予約確認 API 呼出終了[' + i + ']******');
                // 2016/08/08 JRの通信API処理結果はNGでも次の処理を続ける処理できるように変更 BEGIN
                parentCoo.ProcessLog__c = removeOverLogString(preLogMsg + log.getAllLog());
                // 2016/08/08 JRの通信API処理結果はNGでも次の処理を続ける処理できるように変更 END
                // 通知完了すると、ステータスを変更する
                parentCoo.Status__c = CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT; // 予約取込待ち
                update parentCoo;

                // 該当管理IDの関連のステータスはXML→SFDCに取込準備を行う
                List < CooperationResult__c > childrens = [select id, Status__c from CooperationResult__c where ParentRef__c =: parentCoo.id And Status__c =: CONST_RESULT_STATUS_TYPE_XML_IMPORT];
                for (CooperationResult__c coop: childrens) {
                    coop.Status__c = CONST_RESULT_STATUS_TYPE_LEAD_WAIT_IMPORT;
                }
                update childrens;
                // 通知API処理
                isOkFlg = true;
                break;
            } else {
                log.write_error('処理[' + i + ']失敗:' + rep.commonResponse.errorDescription);
            }
        }
        if (!isOkFlg) {
            String orgErrMsg = parentCoo.ErrorContent__c;
            parentCoo.ErrorCount__c = CommUtils.nullToZero(parentCoo.ErrorCount__c) + 1;
            parentCoo.ErrorContent__c = CommLogUtils.removeOverLogString(log.getLastError(), 255);
            // 処理明細情報を記録する
            parentCoo.ProcessLog__c = removeOverLogString(preLogMsg + log.getAllLog());
            parentCoo.Status__c = '連携対象外';
            // 今回の処理結果を記録する
            update parentCoo;
        }
        log.write_method_end();
    }
    // ***********************************
    // バッチ終了処理開始
    // ***********************************
    public void finish(Database.BatchableContext BC) {
        // 2016/12/14 バッチ重複起動されるチェック
        if (isDupFlg != null && isDupFlg) return;
        // 2016/12/14 該当バッチは処理中止するがどうかチェック
        if (BI_JR_ServiceConfigHelp.isLeadBatchStopCheck()) return;
        // 予約処理バッチを起動する
        JR_LeadSyncProcessBatch batch = new JR_LeadSyncProcessBatch();
        ID batchprocessid = Database.executeBatch(batch, 1);
    }

    // JR側へ管理IDで処理完了通知を行う
    private JR_ServiceCtrl.ConfirmBookingReply callOutputCompleteService(String outputId, String shopCd) {
        JR_ServiceCtrl ctrl = new JR_ServiceCtrl(log);
        JR_ServiceCtrl.ConfirmBookingReply rep = null;
        //防止管理ID重复
        outputId = JR_ServiceCtrl.setManagerDataId(outputId);

        // DEBUG MODE以外の場合、JR側へ完了通知APIを呼出する
        if (!BI_JR_ServiceConfigHelp.getCommConfig().bIsDebug) {
            rep = ctrl.callConfirmBookingService(shopCd, outputId);
        } else {
            rep = new JR_ServiceCtrl.ConfirmBookingReply();
            rep.commonResponse = new JR_ServiceCtrl.JR_ResultInfoItem();
            rep.commonResponse.setFail('[DEBUG ERR MESSAGE]');
        }
        return rep;
    }
    /**
     * メール通知先のアドレス宛を設定する
     **//*
    private void setSendMailAddress(CooperationResult__c coop) {
        // メール送信
        String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
        if (CommUtils.isBlank(mailAdds)) mailAdds = UserInfo.getUserEmail();
        String[] toAddresses = mailAdds.split(',');
        coop.MailSendAddress1__c = toAddresses[0];
        if (toAddresses.size() > 1) coop.MailSendAddress2__c = toAddresses[1];
        if (toAddresses.size() > 2) coop.MailSendAddress3__c = toAddresses[2];
        if (toAddresses.size() > 3) coop.MailSendAddress4__c = toAddresses[3];
        if (toAddresses.size() > 4) coop.MailSendAddress5__c = toAddresses[4];
    }*/
    /**
     * ログは最大格納値を超えると、最後から格納する
     **/
    private String removeOverLogString(String log) {
        // 最後のログ情報を保留する
        return CommLogUtils.removeOverLogString(log, 131072, true);
    }
}