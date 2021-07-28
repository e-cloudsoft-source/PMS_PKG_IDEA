global with sharing class UserConfigCompCtrl {
    // KREP:予定表機能用、ROOM：ルームインジケータ機能用、CMERAGE：お客様マージ機能、ESTIMATE：見積
   	// 2018/02/07 マルチタスク対応　by　zy　BEGIN
    global enum FUNCTION_TYPE{KREP,ROOM,CMERAGE,ESTIMATE,TASK
    // 2018/07/30 清掃状態リスト追加 by zy BEGIN
    	,SEISOU
     // 2018/07/30 清掃状態リスト追加 by zy END
     // 2018/10/03 棚卸し画面追加 by zy BEGIN
    	,TANAO
     // 2018/10/03 棚卸し画面追加 by zy END
     // 2018/11/30 レジカード一括印刷追加 by zyz BEGIN
    	,YADOCHOU//2018/11/30 未使用の状態、宿帳機能関連利用
     // 2018/11/30 レジカード一括印刷追加 by zyz END
     // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
     	,TIMETABLE
     // 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
     	//2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw BEGIN
     	,INDICATOR
     	//2019/2/15 ルームインジケータの部屋タイプ絞り込み機能を、タイムテーブルと同じように、複数タイプ指定できるようにして欲しい by cxw END
     	// 2019/07/15 マージ後で自動閉じる機能　by WSQ BEGIN
     	,AMERAGE
     	// 2019/07/15 マージ後で自動閉じる機能　by WSQ END
        // 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy BEGIN
        ,READONLY
        // 2019/07/31 20190527.04.タイムテーブル、ルームインジケータ、マルチタスク機能編集モードと読み込み専用モード対応必要 by zy END
	    // 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy BEGIN
	    ,K_REPORT
        // 2019/08/15 予定表の部屋タイプ絞り込みは予定表内のフィルター機能が改善ほしい by zy END
        // 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
        ,COOK
        // 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
    }
    // 2018/02/07 マルチタスク対応　by　zy　END
    // RESIZE:列RESIZE、HIDCOL:項目隠す、GROUPTYPE:予定別・予約番号別、BOOKMARK：ブックマーク
    // 2017/11/29 発注書、検収書、受注請書、納品書の発注先と元を切替できるように改善 WGCH BEGIN
    // 2017/12/21 通过user记录设定 WGCH BEGIN
    // 2018/02/07 マルチタスク対応　by　zy　BEGIN
    // 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
    // ACCSPCD:会計書出力の店舗選択、BILLSPCD:請求書出力の店舗選択
    public enum KREP_SUBTYPE{RESIZE,HIDCOL,GROUPTYPE,BOOKMARK,SWAPFLG,NOACCFLG,VIEWMODE,ACCSPCD,BILLSPCD
    						// 2018/07/13 プロジェックト設定COOKIE保存　by　zy BEGIN
    						,PROJECTMAIN
    						// 2018/07/13 プロジェックト設定COOKIE保存　by　zy END
    						// 2018/07/30 清掃状態リスト追加 by zy BEGIN
    						,SETINFO,SEISOUSPCD
    						// 2018/07/30 清掃状態リスト追加 by zy END
    						// 2018/10/03 棚卸し画面追加 by zy BEGIN
    						,TANAO
     						// 2018/10/03 棚卸し画面追加 by zy END
     						// 2018/10/06 棚卸し画面写真追加 by zy BEGIN
     						,TANAOMODE
     						// 2018/10/06 棚卸し画面写真追加 by zy END
     						// 2018/11/15 顾客最后操作的内容，自动记录 by zy BEGIN
    						,PROJECTFIELD
    						,PROJECTLAYOUT
    						,PROJECTFIELDSORT
    						,PROJECTTYPE
    						,PROJECTVIEWFLG
    						,PROJECTUSER
    						// 2018/11/15 顾客最后操作的内容，自动记录 by zy END
					     	// 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw BEGIN
					     	,FONTSIZE
					     	// 2018/12/30 拡大機能[+/-]ボタンにより、ZOOMのバーにより、全体はズーム機能 by cxw END
					     	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy BEGIN
					     	,DEPARTCODES
					     	// 2019/01/15 タイムテーブルを開いた際、デフォルトで表示される部屋タイプを指定できるようにする by zy END
                            // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy BEGIN
                            ,LEADSTATUS
                            // 2019/05/30 タイムテーブルの期間設定（31日表示、7日表示など）が保持されないに関してby zy END
                            // 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH BEGIN
                            // 主明细板块KEY
                            ,GRID
                            // 料理WINDOW第一个板块KEY
                            ,SUMMARY
                            // 料理WINDOW第一个明细多天板块KEY
                            ,SUMMARYDETL
                            // 料理WINDOW第二个明细板块KEY
                            ,SUMMARY2
                            // 料理WINDOW第二个明细多天板块KEY
                            ,SUMMARY2DETL
                            // 2019/06/14 フィルターを各アカウント毎に保持できる様にして欲しい対応 WGCH END
                            // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz BEGIN
                            ,BILLERASE
                            // 2019/07/15 入金消込機能ソートを保持の改善 BY zyz END
                            // 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
                            ,SPCD
                            // 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
                            // 2019/09/15 指定日自动记忆機能対応 WGCH BEGIN
                            ,CHECKINDAY
                            // 2019/09/15 指定日自动记忆機能対応 WGCH END
                            // 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
                            ,INFO
                            // 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
    }
    // 2018/03/30 会計書の店舗切替を保存 WGCH END
    // 2018/02/07 マルチタスク対応　by　zy　END
    // 2017/12/21 通过user记录设定 WGCH END
    // 2017/11/29 発注書、検収書、受注請書、納品書の発注先と元を切替できるように改善 WGCH END
    // お客様マージ機能
    public enum CMERAGE_SUBTYPE{AUTOCLOSE}
    // 2019/07/15 マージ後で自動閉じる機能　by WSQ BEGIN
    // 取引先マージ機能
    public enum AMERAGE_SUBTYPE{AUTOCLOSE}
    // 2019/07/15 マージ後で自動閉じる機能　by WSQ END
    // 予定表関連自動格納処理
    @remoteaction
    global static void saveKrepConfig(string subtype, string configstr, string userid, String spcd) {
        saveConfig(FUNCTION_TYPE.KREP.name(), subtype, configstr, userid, spcd);
    }
    // 定義情報の共通保存する(2017/11/09)
    @remoteaction
    global static void saveCommConfig(FUNCTION_TYPE funtype, string subtype, string configstr, string userid, String spcd) {
        saveConfig(funtype.name(), subtype, configstr, userid, spcd);
    }
    // 2018/03/30 会計書の店舗切替を保存 WGCH BEGIN
    webservice static void webSaveKrepConfig(string subtype, string configstr, string userid, String spcd) {
        saveConfig(FUNCTION_TYPE.KREP.name(), subtype, configstr, userid, spcd);
    }
    // 2018/03/30 会計書の店舗切替を保存 WGCH END
    private static void saveConfig(string pKey, string subtype, string configstr, string userid, String spcd) {
        
        // 新た定義情報を格納する
        List<UserConfig__c> userConfigs = [select id ,ConfigInfo__c from UserConfig__c where UserRef__c = :userid and FunctionType__c = :pkey and FunctionSubType__c = :subtype and ShopCode__c = :spcd order by LastModifiedDate desc limit 1];
        if (userConfigs.isEmpty()) {
            UserConfig__c config = new UserConfig__c(
                FunctionType__c = pKey,
                FunctionSubType__c = subtype,
                ConfigInfo__c = configstr,
                ShopCode__c = spcd,
                UserRef__c = userid
            );
            userConfigs.add(config);
        } else {
	        for (UserConfig__c config : userConfigs) {
	            config.ConfigInfo__c = configstr;
	        }
        }
        if (!userConfigs.isEmpty()) upsert userConfigs;
    }
    // 該当ユーザーのカスタマイズ情報を全部取得、返却する
    public static map<String,String> getKrepConfig(Id userid,String spcd) {
        return getConfig(userid, FUNCTION_TYPE.KREP.name(), spcd);
    }
    // 定義情報の共通取得(2017/11/09)
    public static map<String,String> getCommConfig(FUNCTION_TYPE funtype,Id userid,String spcd) {
        return getConfig(userid, funtype.name(), spcd);
    }
    // 店舗別のユーザー単位のカスタマイズ定義情報
    private static map<String,String> getConfig(Id userid, String pKey, String spcd) {
        map<string,string> rsMap = new map<string, string>();
        List<UserConfig__c> userConfigs = [select id ,FunctionSubType__c,ConfigInfo__c from UserConfig__c where UserRef__c = :userid and FunctionType__c = :pkey and ShopCode__c = :spcd order by LastModifiedDate desc];
        for (UserConfig__c config : userConfigs) {
            String subKey = CommUtils.nullToBlank(config.FunctionSubType__c);
            if (!rsMap.containsKey(subKey)) rsMap.put(subKey, config.ConfigInfo__c);
        }
        return rsMap;
    }
}