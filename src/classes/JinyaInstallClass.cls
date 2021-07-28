/*********************************************
* PMSインストール後のSCRIPT処理
* 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加
*********************************************/
global class JinyaInstallClass implements InstallHandler {
	private Version previousVersion;
    global void onInstall(InstallContext context) {
    	// 2017/02/21 Field Security Check BEGIN
	    List<String> chkFields = new List<String>{'RoomTypeStartDateMode__c','WhiteBoardReport__c','RackRateTablePeopleDefault__c','Tier6Report__c','RoomTypeSaleStatus__c',
	    										'Schedule1DeviationDays__c','MessageIsShowFlg__c','MediaTypeSubscriptionIsShowFlg__c','WatermarkRate__c','LeadSplitDivCode__c',
	    										'LeadIsHiruKey__c','maxrecords_DSP__c','IotSpeechAlertFlg__c','RoomIndicatorInfoNameType__c','IotMessageToChatterFlg__c',
	    										'IotMessageJoinFlg__c','RoomIndicatorInfoMaxLength__c','PersonTMInfoReport__c','PurchaseReport__c','Tier7Report__c','Tier4Report__c',
	    										'RoomTypeReport__c','ReportKScheduleCookInfoDiv__c','RoomIndicatorBusinessHourMM__c','RoomSortDiv__c','ExchangeTaxRate__c','ReportKScheduleCookFieldSortDiv__c',
	    										'ReceiptDtIsShowFlg__c','ExchangeRateApiRateKbn__c','EnglishTaxLabel__c','RoomTypeDateLinkFlg__c','Posreg__c','ShopPlanSetupFlg__c',
	    										'CustomTimeReport__c','ContactUsageCountDiv__c','Schedule2DeviationDays__c','RoomTypeRoomIsShow__c','RenpakuBatchCheckinIsCanFlg__c',
	    										'SchedulePcaResultSendType__c','SchedulePcaCsvHeaderIsShowFlg__c','RackRateTableTierDefault__c','ReportKScheduleCookInfoCode__c',
	    										'maxrecords_DB__c','CashRegisterSwitchCode__c','CaseRollupBookRepNm__c','UnitPriceDefKb__c','RoomTypeMessageIsShowFlg__c','TimeTableProcessLimit__c',
	    										'CTI_Call_Columns_xml_Name__c','RoomTypeSeminarIsShow__c','BookingReportStampIsShowFlg__c','BookingMansDef__c','BookingFemailsDef__c',
	    										'BookingChildrenDef__c','BookingAppSwitchCode__c','BillReportStampIsShowFlg__c','BillInputSwitchCode__c','BatchNroomsCheckInFlg__c',
	    										'ApplicationFormReportPopupIsShow__c','ApplicationFormPDFSwitchCode__c','AdvancesReceivedChk__c','AccountUseDateMode__c',
	    										'AccountSoftSyncCsvType__c','AccountSignatureFieldIsShow__c','AccountSaleDateSetupDiv__c','AccountReportSortKbn__c','AccountReportComment__c',
	    										'AccountReceiptDateDefValSetFlg__c','AccountProviso__c','AccountPrintType__c','AccountPopupIsShow__c','AccountOldManModeFlg__c',
												'AccountNoTaxCalFlg__c','AccountIsShowCopy__c','AccountInversionLine__c','AccountDetailSortCode__c','A1CookingReport__c','POSNo__c','RoomUseEbFlg__c',
												'RoundType__c','TimerSecond__c','GuestRooms__c'};
	    Map<String,Schema.SObjectField> m = Schema.SObjectType.CommDefine__c.fields.getMap();
	    if (!CommSecurityUtils.isCanUpdateable(chkFields, m)) {
			return;
	    }
	    // 2017/02/21 Field Security Check End
	    // 2017/02/23 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'ReportLogo__c','Name'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.ReportLogo__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		List<String> insChkFieldsLst = new List<String>{'TaxRate__c'};
		Map<String,Schema.SObjectField> insmm = Schema.SObjectType.JMST__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFieldsLst, insmm)) {
			return;
		}
		if (!CommSecurityUtils.isCanCreateable(chkFields, m)) {
			return;
		}
		// 2017/02/23 Field Security Check End by wx
    	// 前VERSION
    	previousVersion = context.previousVersion();
    	// 2015/03/25 勤怠情報初期化する
    	List<WorkTimeDefine__c> wkDefLst = [select id from WorkTimeDefine__c limit 1];
    	if (wkDefLst.isEmpty()) {
    		WorkTimeDefine__c newItem = new WorkTimeDefine__c(Name = '共通(削除禁止)');
    		insert newItem;
    	}
    	List<CommDefine__c> existComDefList = Database.query(CommSqlUtils.generateQueryString('CommDefine__c') + ' limit 1');
    	if (existComDefList.isEmpty()) {
            // カスタム設定情報を設定する
            CommDefine__c comDef = new CommDefine__c();
            comDef.POSNo__c = '0000';
            comDef.TimerSecond__c = 60;
            comDef.GuestRooms__c = 20;
            comDef.RoundType__c = 0;
            comDef.AppNS__c = 'ps__';
            // E/B機能非起動
            comDef.RoomUseEbFlg__c = false;
            comDef.RoomTypeReport__c = '$0001 客室タイプ別予約表';
            comDef.A1CookingReport__c = '#02$6002 A1_料理関連[今月]';
            comDef.WhiteBoardReport__c = '$$0003 WhiteBoard予定表';
            comDef.CustomTimeReport__c = '$$0040 カスタム時間割';
            comDef.Tier4Report__c = '$0011 客室割当状況 - 昼と夕 [Tier4]';
            comDef.Tier6Report__c = '$0011 客室割当状況 - 昼と夕 [Tier6]';
            comDef.Tier7Report__c = '$0011 客室割当状況 - 昼と夕 [Tier7]';
            comDef.PurchaseReport__c = '$0001 仕入高[調理]';
            comDef.PersonTMInfoReport__c = '$当月の個人勤怠情報';
            comDef.Posreg__c = '0';
            comDef.UnitPriceDefKb__c = 2;
            //2014/08/11 Ver4.52 CTI列XML構成ファイル
            comDef.CTI_Call_Columns_xml_Name__c = 'CTI Call Columns xml V1.1';
            
            /*Get the contact, Account, Phone reference ids from reservation object.*/
             /*Map<String, String> resRefMap = getResRefDetails();
            comDef.ResContRef__c = (resRefMap.get('contRef')!=null) ? resRefMap.get('contRef') : '';
            comDef.ResAccRef__c = (resRefMap.get('accRef')!= null ) ? resRefMap.get('accRef') : '';
            comDef.ResPhoneRef__c = (resRefMap.get('phoneRef')!=null) ? resRefMap.get('phoneRef') :'';
            */
            // 2017/08/31 活動関連取込先レポートID自動設定用 BEGIN
            setActivityRefAccountReportId(comDef);
            // 2017/08/31 活動関連取込先レポートID自動設定用 END
            // 2018/05/29 初期値自動設定不具合の改修 BEGIN
            comDef.ExchangeTaxRate__c = 8;
            // 2018/05/29 初期値自動設定不具合の改修 END
            insert comDef;
            // 消費税マスたの自動設定
            JMST__c taxDef1 = new JMST__c();
            taxDef1.TaxRate__c = 0;
            insert taxDef1;
            // 2014/03/20 消費税５％自動設定を外す
            /*
            JMST__c taxDef2 = new JMST__c();
            taxDef2.TaxRate__c = 5;
            insert taxDef2;
			*/
            // レポートの画像：初期値設定を行う
          //String img = 'data:image/jpeg;base64,' + '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';
            String img = 'data:image/jpeg;base64,' + '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';
            ReportLogo__c item1 = new ReportLogo__c();
            item1.Name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
            item1.ReportLogo__c = '<img src="' + img + '" />';
            insert item1;
    	} else {
    		// 更新を行う
    		CommDefine__c updObj = existComDefList[0];
	    	// 20120925 Release Setup
			if (CommUtils.isBlank(updObj.RoomTypeReport__c)) {
			 	updObj.RoomTypeReport__c = '$0001 客室タイプ別予約表';
			}
			if (CommUtils.isBlank(updObj.A1CookingReport__c)) {
			 	updObj.A1CookingReport__c = '#02$6002 A1_料理関連[今月]';
			}
			if (CommUtils.isBlank(updObj.WhiteBoardReport__c)) {
			 	updObj.WhiteBoardReport__c = '$$0003 WhiteBoard予定表';
			}
			if (CommUtils.isBlank(updObj.CustomTimeReport__c)) {
			 	updObj.CustomTimeReport__c = '$$0040 カスタム時間割';
			}
			if (CommUtils.isBlank(updObj.Tier4Report__c)) {
			 	updObj.Tier4Report__c = '$0011 客室割当状況 - 昼と夕 [Tier4]';
			}
			if (CommUtils.isBlank(updObj.Tier6Report__c)) {
			 	updObj.Tier6Report__c = '$0011 客室割当状況 - 昼と夕 [Tier6]';
			}
			if (CommUtils.isBlank(updObj.Tier7Report__c)) {
			 	updObj.Tier7Report__c = '$0011 客室割当状況 - 昼と夕 [Tier7]';
			}
			if (CommUtils.isBlank(updObj.PurchaseReport__c)) {
			 	updObj.PurchaseReport__c = '$0001 仕入高[調理]';
			}
			if (CommUtils.isBlank(updObj.PersonTMInfoReport__c)) {
			 	updObj.PersonTMInfoReport__c = '$当月の個人勤怠情報';
			}
			// 20120930 Release Setup
			if (CommUtils.isBlank(updObj.Posreg__c)) {
				updObj.Posreg__c = '0';
			}
			// 20121004 Release Setup
			if (updObj.UnitPriceDefKb__c == null) {
				updObj.UnitPriceDefKb__c = 2;
			}
			// 20130529 Release Setup
			// RoomIndicator表示する文字数
			if (updObj.RoomIndicatorInfoMaxLength__c == null) {
				updObj.RoomIndicatorInfoMaxLength__c = 4;
			}
			// お部屋表示順
			if (updObj.RoomSortDiv__c == null) {
				// １：NAMEで並べる
				updObj.RoomSortDiv__c = '1';
			}
			// 予約人数（男性/女性/子供）
			if (updObj.BookingMansDef__c == null) updObj.BookingMansDef__c = 1;
			if (updObj.BookingFemailsDef__c == null) updObj.BookingFemailsDef__c = 0;
			if (updObj.BookingChildrenDef__c == null) updObj.BookingChildrenDef__c = 0;
			// 中継アプリから自動連携する場合、該当フラグはTRUE場合、部屋割り当て実行する
			// 2014/08/07 部屋タイプ　VS　部屋が１VS1の場合、部屋自動割り当て制御フラグ追加
			//if (updObj.AdvancesReceivedChk__c == null) updObj.AdvancesReceivedChk__c = false;
			if (isInstalledVersionBefore(new Version(4, 53))) {
				updObj.AdvancesReceivedChk__c = true;
			}
			// 2013/07/20 会計書反転明細制御
			if (updObj.AccountInversionLine__c == null) updObj.AccountInversionLine__c = true;
			// ルームインジケータ表示情報制御
			if (updObj.RoomIndicatorInfoNameType__c == null) updObj.RoomIndicatorInfoNameType__c = 1;
			// 2013/07/26 会計書老人モード追加
			if (updObj.AccountOldManModeFlg__c == null) updObj.AccountOldManModeFlg__c = false;
			// 2013/07/30 営業日切替時間パラメータ設定
			//if (updObj.RoomIndicatorBusinessHour__c == null) updObj.RoomIndicatorBusinessHour__c = 12;
			// 2013/08/09 営業日切替時間パラメータ設定:HHMM分まで対応する
			if (updObj.RoomIndicatorBusinessHourMM__c == null) updObj.RoomIndicatorBusinessHourMM__c = '1200';
			// 2013/08/30 一括予約入力基本情報切替パラメータ
			if (updObj.BookingAppSwitchCode__c == null) updObj.BookingAppSwitchCode__c = '1';
			// 2013/09/18 親部屋集める/分割するフラグ
			if (updObj.LeadSplitDivCode__c == null) updObj.LeadSplitDivCode__c = 2;
			// 2013/09/24 自動チェックイン対象区分
			if (updObj.BatchNroomsCheckInFlg__c == null) updObj.BatchNroomsCheckInFlg__c = true;
			// 2013/09/26 但し書き内容内容内容設定
			if (updObj.AccountProviso__c == null) updObj.AccountProviso__c = '宿泊代,飲食代,駐車場代';
			// 2013/10/09 予約ポップのセミナー入力可・不可制御フラグ
			if (updObj.RoomTypeSeminarIsShow__c == null) updObj.RoomTypeSeminarIsShow__c = false;
			// 2013/10/14 連絡事項表示・非表示制御フラグ
			if (updObj.MessageIsShowFlg__c == null) updObj.MessageIsShowFlg__c = true;
			// 2013/10/17 スケジュール１処理日偏差値/スケジュール２処理日偏差値
			if (updObj.Schedule1DeviationDays__c == null) updObj.Schedule1DeviationDays__c = 0;
			if (updObj.Schedule2DeviationDays__c == null) updObj.Schedule2DeviationDays__c = 0;
			// 2013/10/18 予約ポップの部屋項目表示・非表示制御フラグ
			if (updObj.RoomTypeRoomIsShow__c == null) updObj.RoomTypeRoomIsShow__c = false;
			// 2013/10/30 会計支払のMedia種別に「予約金」表示・非表示制御
			if (updObj.MediaTypeSubscriptionIsShowFlg__c == null) updObj.MediaTypeSubscriptionIsShowFlg__c = false;
			// 2013/10/30 すかし度
			if (updObj.WatermarkRate__c == null) updObj.WatermarkRate__c = false;
			// 2013/10/31 予定表料理集計表示方式
			if (updObj.ReportKScheduleCookInfoDiv__c == null) updObj.ReportKScheduleCookInfoDiv__c = false;
			// 2013/10/31 会計書統合印刷表示フラグ
			if (updObj.AccountPrintType__c == null) updObj.AccountPrintType__c = false;
			// 2013/11/13 会計書のポップアップWINDOW表示、非表示制御フラグ
			if (updObj.AccountPopupIsShow__c == null) updObj.AccountPopupIsShow__c = false;
			// 2013/12/09 レジカード制御コード
			if (updObj.CashRegisterSwitchCode__c == null) updObj.CashRegisterSwitchCode__c = '4';
			// 2013/12/23 予定表料理集計コード[項目「昼」別で料理集計を行う]
			if (updObj.ReportKScheduleCookInfoCode__c == null) updObj.ReportKScheduleCookInfoCode__c = '1';
			// 2013/12/30 CTI関連定数Default値設定
			if (updObj.maxrecords_DB__c == null) updObj.maxrecords_DB__c = 5;
			if (updObj.maxrecords_DSP__c == null) updObj.maxrecords_DSP__c = 5;
			// 2014/01/29 Tier関連初期値自動設定
			if (updObj.RackRateTableTierDefault__c == null) updObj.RackRateTableTierDefault__c = 'Tier4';
			if (updObj.RackRateTablePeopleDefault__c == null) updObj.RackRateTablePeopleDefault__c = '1';
			// Ver4.20 以前のVersionからVerionUPする場合,「控」制御フラグ初期値設定を行う
			if (isInstalledVersionBefore(new Version(4, 20))) {
				// 2014/02/05 会計書PDFについての(控)を出力制御初期値設定
				updObj.AccountIsShowCopy__c = true;
			}
			// 2015/01/19 Version4.84から
			if (updObj.AccountDetailSortCode__c == null) updObj.AccountDetailSortCode__c = '1';
			// 2014/03/29 Version4.27から[予定表料理項目商品並べ順表示方式]
			if (updObj.ReportKScheduleCookFieldSortDiv__c == null) updObj.ReportKScheduleCookFieldSortDiv__c = '1';
			// 2014/04/01 Version4.28から[会計の売上計上日設定区分]
			if (updObj.AccountSaleDateSetupDiv__c == null) updObj.AccountSaleDateSetupDiv__c = '1';
			// 2014/06/02 Version4.40から[予約ポップ開始日モード]
			if (updObj.RoomTypeStartDateMode__c == null) updObj.RoomTypeStartDateMode__c = '1';
			// 2014/06/16 Version4.41かあ
			if (isInstalledVersionBefore(new Version(4, 41))) {
				// 2014/06/16 予約ポップ連絡事項表示・非表示フラグ初期値設定
				updObj.RoomTypeMessageIsShowFlg__c = true;
			}
			// 2014/07/02 Ver4.44から
			if (updObj.RoomTypeSaleStatus__c == null) updObj.RoomTypeSaleStatus__c = '通常:1,休館,貸切';
			// 2014/07/24 Ver4.47から[お客様利用回数集計区分]
			if (updObj.ContactUsageCountDiv__c == null) updObj.ContactUsageCountDiv__c = '1';
			// 2014/07/30 Ver4.49から[内消費税英語表示文言]
			if (updObj.EnglishTaxLabel__c == null) updObj.EnglishTaxLabel__c = 'Sales Tax&Hotel Tax';
			// 2014/08/01 Ver4.49から[日本円の消費税]初期値設定[外貨組織は日本円消費税変換する場合、該当項目は更新が必要、増税日以後の既存の予約、会計の日本消費税項目内容更新が必要]
			if (updObj.ExchangeTaxRate__c == null) updObj.ExchangeTaxRate__c = 8;
			// 2014/08/02 Ver4.50から[為替レート取得バッチレート設定区分]
			if (updObj.ExchangeRateApiRateKbn__c == null) updObj.ExchangeRateApiRateKbn__c = '2';
			//2014/08/11 Ver4.52 CTI列XML構成ファイル.
			if (updObj.CTI_Call_Columns_xml_Name__c == null) updObj.CTI_Call_Columns_xml_Name__c = 'CTI Call Columns xml V1.1';
            
            // 2015/01/14 Ver4.82以後、会計書コメント文
            if (updObj.AccountReportComment__c == null) updObj.AccountReportComment__c = '宿泊税等が加算される場合には別途記載をいたしております。';
            // 2015/01/14 見積書ハンコ表示・非表示/ 請求書ハンコ表示・非表示 初期値設定
			if (isInstalledVersionBefore(new Version(4, 83))) {
				// 2015/01/14 請求書ハンコ表示・非表示初期値設定
				updObj.BookingReportStampIsShowFlg__c = true;
				// 2015/01/14 見積書ハンコ表示・非表示初期値設定
				updObj.BillReportStampIsShowFlg__c = true;
				// 2014/01/16 予定確認書ポップ表示・非表示制御
				updObj.ApplicationFormReportPopupIsShow__c = true;
			}
			// 2015/01/15 予約確認書レイアウト制御コード
			if (updObj.ApplicationFormPDFSwitchCode__c == null) updObj.ApplicationFormPDFSwitchCode__c = '2';
            // 2015/02/12 会計編集画面レイアウト切替制御パラメータ
            if (updObj.BillInputSwitchCode__c == null) updObj.BillInputSwitchCode__c = '1';
            // Version6.5以前のVersionは自動TRUEに設定する
            if (isInstalledVersionBefore(new Version(6, 6))) {
            // 2015/03/04 バッチスケジュール(PCA連携)CSVヘッダー付加する・しないフラグ
            	updObj.SchedulePcaCsvHeaderIsShowFlg__c = true;
            }
            // 2015/03/11 PCA連携結果通知制御コード初期設定を行う
            if (updObj.SchedulePcaResultSendType__c == null) updObj.SchedulePcaResultSendType__c = '1';
            /*Map<String, String> resRefMap = getResRefDetails();
            
			if (updObj.ResContRef__c == null) updObj.ResContRef__c = (resRefMap.get('contRef')!= null)? resRefMap.get('contRef') : '';
			if (updObj.ResAccRef__c == null) updObj.ResAccRef__c = (resRefMap.get('accRef') !=null)? resRefMap.get('accRef'):'';
			if (updObj.ResPhoneRef__c == null) updObj.ResPhoneRef__c = (resRefMap.get('phoneRef')!=null)? resRefMap.get('phoneRef'):'';*/
			// 2015/05/02 連泊予約一括チェックイン機能制御フラグ
			if (isInstalledVersionBefore(new Version(15, 17))) {
				updObj.RenpakuBatchCheckinIsCanFlg__c = true;
			}
			// 2015/07/02 会計書の署名表示・非表示制御フラグ
			if (isInstalledVersionBefore(new Version(15, 45))) {
				updObj.AccountSignatureFieldIsShow__c = true;
			}
			// 2015/07/02 利用日モード
			if (updObj.AccountUseDateMode__c == null) updObj.AccountUseDateMode__c = '3';
			// 2015/11/02 会計連携用CSV出力種別
			if (updObj.AccountSoftSyncCsvType__c == null) updObj.AccountSoftSyncCsvType__c = '1';
			// 2016/01/12 会計の領収証日付値の自動設定制御
			if (isInstalledVersionBefore(new Version(16, 0))) {
				updObj.AccountReceiptDateDefValSetFlg__c = true;
			}
			// 2016/01/29 POS取込の対象ファイルの一意の名前
			if (updObj.ShopPlanSetupFlg__c == null) updObj.PosFileKeyDef__c = 'ttotal,ttend,titem';
			// 2016/03/04 会計の税抜金額端数処理区分制御(既にVersion < 16.9)
			if (isInstalledVersionBefore(new Version(16, 9))) {
				updObj.AccountNoTaxCalFlg__c = true;
			}
			// 2016/02/19 予約ポップの日付から遷移先の制御フラグ
			if (updObj.RoomTypeDateLinkFlg__c == null) updObj.RoomTypeDateLinkFlg__c = '1';
			// 2016/04/28 レポート_現金合せ履歴レポート名
			if (updObj.CaseRollupBookRepNm__c == null) updObj.CaseRollupBookRepNm__c = '現金合せ履歴';
			// 2016/05/03 タイムテーブル画面初期表示の部屋数
			if (updObj.TimeTableProcessLimit__c == null) updObj.TimeTableProcessLimit__c = 130;
			// 2016/06/28 入金日表示・非表示制御 
			if (updObj.ReceiptDtIsShowFlg__c == null) updObj.ReceiptDtIsShowFlg__c = '2';
			// 2016/09/09 会計書、請求書明細表示順
			if (updObj.AccountReportSortKbn__c == null) updObj.AccountReportSortKbn__c = '2';
			// 2016/10/11 IOT機能制御パラメータの追加
			// (既にVersion < 16.53)
			if (isInstalledVersionBefore(new Version(16, 53))) {
				updObj.IotMessageToChatterFlg__c = true;	// IOT機能通知チャターへポスト制御
				updObj.IotMessageJoinFlg__c = false;		// IOT機能通知文言ジョイン機能
				updObj.IotSpeechAlertFlg__c = true;		// IOT音声通知機能
			}
			// ご予約昼の太陽マークが表示する時刻を定義できる機能対応 :ご予約昼の太陽マークが表示する時刻定義
			if (updObj.LeadIsHiruKey__c == null) updObj.LeadIsHiruKey__c = '"15:00","14:30","14:00","13:30","13:00","12:30","12:00","11:30","11:00","10:30","10:00","9:30","09:30","9:00","09:00","8:30","08:30","8:00","08:00"';
			// (既にVersion < 17.34)
			if (isInstalledVersionBefore(new Version(17, 34))) {
				// 2017/05/11 IOT機能通知文言定義の追加
				updObj.IotMessageCustomDef__c = 'WaterQuqntity:Warning Message @location 水量 @valueリットル;WaterTemperature:Warning Message @location 水温 @value度;Persons:Warning Message @location 人数 @value人';
			}
			// 2017/08/31 活動関連取込先レポートID自動設定用 BEGIN
            setActivityRefAccountReportId(updObj);
            // 2017/08/31 活動関連取込先レポートID自動設定用 END
            // (既にVersion < 17.58)
            // 2017/09/05 在庫通知データ作成フラグ
            if (isInstalledVersionBefore(new Version(17, 58))) {
                updObj.StockDataCreateFlg__c = true;
            }
            // 2017/09/25 会計書一括ビル最大部屋数
            if (updObj.AccountReportBulkPrintMaxRooms__c == null) updObj.AccountReportBulkPrintMaxRooms__c = 75;
            // 2017/09/13 レジカードサインタイプ定義の追加
            if (updObj.CashRegisterSignType__c == null) updObj.CashRegisterSignType__c = CommConst.APPOTION_CARREG_SING_TYPE_POPUP;
             // (既にVersion < 17.71)
            // 2017/10/25 宿帳自動作成フラグ
            if (isInstalledVersionBefore(new Version(17, 71))) {
                updObj.CashRegisterAutoCreateFlg__c = true;
            }
            // (既にVersion < 17.73)
            // 2017/11/09 項目変更履歴自動作成フラグ
            if (isInstalledVersionBefore(new Version(17, 90))) {
                updObj.ItemChangeHistoryAutoCreateFlg__c = true;
            }
			// 2018/05/28 Version18.28から
			if (isInstalledVersionBefore(new Version(18, 28))) {
				// 予約ポップ連絡事項表示・非表示フラグ初期値設定
				updObj.RoomTypeMessageIsShowFlg__c = true;
				// ルームインジケータ連絡事項表示・非表示フラグ
				updObj.MessageIsShowFlg__c = true;
			}
			// 2018/08/21 在庫変更履歴検索キー自動設定バッチ実施追加 BEGIN
			// 2018/09/10 データ自動FIX機能を一時CLOSEする
			/*
			try {
				StockChangeHisotryDataFixBatch batch = new StockChangeHisotryDataFixBatch(context.installerId());
				DataBase.executeBatch(batch, 2000);
			} catch (Exception e){}
			*/
			// 2018/08/21 在庫変更履歴検索キー自動設定バッチ実施追加 END 
			// 2018/10/17 予約ポップ「年月」表示箇所コード BEGIN
			// デフォルト：1
			// 1:右、2:左
			if (CommUtils.isBlank(updObj.RoomTypeDatePosition__c)) {
				updObj.RoomTypeDatePosition__c = '1';
			}
			// 2018/10/17 予約ポップ「年月」表示箇所コード END
			// 2018/11/30 レジカード一括印刷機能追加 by zyz BEGIN 
			// デフォルト：1
			if (CommUtils.isBlank(updObj.RoomIndicatorCashRegisterCode__c)) {
				updObj.RoomIndicatorCashRegisterCode__c = '1';
			}
			// 2018/11/30 レジカード一括印刷機能追加 by zyz END
            // 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH BEGIN
            if (updObj.RoomIndicatorRoomTypeSelectFlg__c == null) updObj.RoomIndicatorRoomTypeSelectFlg__c = 0;
            // 2018/11/08 未割り当てウインドウの予約も該当部屋タイプのみ情報を表示する WGCH END
            // 2019/10/28 軽減税率、合計明細内容非表示設定フラグ 初期値設定 WSQ BEGIN
            if (CommUtils.isBlank(updObj.ReducedTaxRowIsHideMode__c)) updObj.ReducedTaxRowIsHideMode__c = '1,1,1';
            // 2019/10/28 軽減税率、合計明細内容非表示設定フラグ 初期値設定 WSQ END
            // 2019/10/28 軽減税率、合計明細内容非表示設定フラグ 初期値設定 WSQ BEGIN
			if (CommUtils.isBlank(updObj.ReducedTaxProportionMode__c)) updObj.ReducedTaxProportionMode__c = '0';
            // 2019/10/28 軽減税率、合計明細内容非表示設定フラグ 初期値設定 WSQ END
			update updObj;

    	}

    	// 最新リリース情報はChatterに通知する
    	String currentVersion = System.requestVersion().major() + '.' + System.requestVersion().minor();
    	User installUser = [ Select name, LanguageLocaleKey From User where id = :context.installerId()];
		//Adding a Text post
		FeedItem post = new FeedItem();
		post.Type = 'LinkPost';
		post.title = 'VERSION: ' + currentVersion;
		post.ParentId = context.installerId(); //eg. Installer
		if (installUser.LanguageLocaleKey == 'ja') {
			post.Body = '#JINYA-CONNECT 陣屋コネクトからバージョンアップのお知らせです。';
		} else {
			post.Body = '#JINYA-CONNECT Release updated JINYA-CONNECT。';
		}
		// File Name:jinyaconnectversion0348.pdf
		String historyFile = 'jinyaconnectversion' + (System.requestVersion().major() < 10 ? '0' + System.requestVersion().major() : String.valueOf(System.requestVersion().major()));
		historyFile += (System.requestVersion().minor() < 10 ? '0'+System.requestVersion().minor() : String.valueOf(System.requestVersion().minor()));
		// 2016/09/27 ChatterにポストURLを変更する対応 BEGIN
		//post.LinkUrl = 'http://jinya-connect.com/history/'+historyFile+'.pdf';
		post.LinkUrl = 'http://www.jinya-connect.com/databox/data.php/versionup_ja/code';
		// 2016/09/27 ChatterにポストURLを変更する対応 END
		try {
		insert post;
		} catch (Exception e){}
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 BGEIN
		try {
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 END
		//Contact 上様の作成 2014/09/29
        CommLogicProcess.getOrInsertTempContact(); 
        // 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 BGEIN
		} catch (Exception e){}
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 END
    	/*
    	// 新規インストール場合
        if(context.previousVersion() == null) {
            // カスタム設定情報を設定する
            CommDefine__c comDef = new CommDefine__c();
            comDef.POSNo__c = '0000';
            comDef.TimerSecond__c = 60;
            comDef.GuestRooms__c = 20;
            comDef.RoundType__c = 0;
            comDef.AppNS__c = 'ps__';
            // E/B機能非起動
            comDef.RoomUseEbFlg__c = false;
            comDef.RoomTypeReport__c = '$0001 客室タイプ別予約表';
            comDef.Posreg__c = '0';
            comDef.UnitPriceDefKb__c = 1;
            insert comDef;
            // 消費税マスたの自動設定
            JMST__c taxDef1 = new JMST__c();
            taxDef1.TaxRate__c = 0;
            insert taxDef1;
            JMST__c taxDef2 = new JMST__c();
            taxDef2.TaxRate__c = 5;
            insert taxDef2;

            // レポートの画像：初期値設定を行う
            String img = 'data:image/jpeg;base64,' + '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';
            ReportLogo__c item1 = new ReportLogo__c();
            item1.Name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
            item1.ReportLogo__c = '<img src="' + img + '" />';
            insert item1;
        }
	    else if(context.previousVersion().compareTo(new Version(1,0)) == 0) {

	    }
	    if(context.isUpgrade()) {
	    	
	    	// 20120925 Release Setup
			if (CommUtils.isBlank(CommDefine__c.getOrgDefaults().RoomTypeReport__c)) {
			 	CommDefine__c.getOrgDefaults().RoomTypeReport__c = '$0001 客室タイプ別予約表';
			}
			// 20120930 Release Setup
			if (CommUtils.isBlank(CommDefine__c.getOrgDefaults().Posreg__c)) {
				CommDefine__c.getOrgDefaults().Posreg__c = '0';
			}
			// 20121004 Release Setup
			if (CommDefine__c.getOrgDefaults().UnitPriceDefKb__c == null) {
				CommDefine__c.getOrgDefaults().UnitPriceDefKb__c = 1;
			}
			
	    }*/
	    if(context.isPush()) {
	    	// 20120925 Relase Setup
			if (CommUtils.isBlank(CommDefine__c.getOrgDefaults().RoomTypeReport__c)) {
			 	CommDefine__c.getOrgDefaults().RoomTypeReport__c = '$0001 客室タイプ別予約表';
			}
	    }
 		// 2017/06/06 PUSHTOPICの自動作成機能対応 BEGIN
 		/*
 		// Push Topic Call Popup window setup
	    List<pushtopic> callPushTopic = Database.query('select id from pushtopic where name = \'CallInformation\' limit 1');
	    PushTopic pushTopic  = new PushTopic();
 		if(!callPushTopic.isEmpty()){
 			pushTopic  = new PushTopic(Id = callPushTopic[0].Id);
 		}
		else{
			pushTopic.Name = 'CallInformation';
			pushTopic.ApiVersion = 27.0;
			pushTopic.NotifyForOperations = 'All';
			pushTopic.NotifyForFields = 'Referenced';
		}
		// 2014/10/20 DNO__c項目を追加する
		pushTopic.Query = 'SELECT Id, ps__DNO__c, ps__SNO__c, ps__NAM__c, ps__isRSNP__c, ps__RSN_Code__c, ps__isDCD1__c, ps__DT4__c, ps__DT1__c, ps__DT0__c, ps__Call_Time__c, ps__LNO__c, ps__Account__c, ps__Contact__c, ps__Company_name__c, ps__contact_Name__c, ps__No_of_Matching_Customers__c,ps__IsCustomerUpdated__c,ps__CallType__c,ps__CarModel__c,ps__CarColor__c,ps__MessageUUID__c, ps__Contact_KatakanaCal__c FROM ps__Call_Information__c';
		//pushTopic.NotifyForOperationCreate = true;
		//pushTopic.NotifyForOperationUpdate = true;
		//pushTopic.NotifyForFields = 'Referenced';
		upsert pushTopic;
		*/
		setupCtiStramingTopic(false);
		// 2017/06/06 PUSHTOPICの自動作成機能対応 END
		// スタッフ勤怠ステータス監視TOPIC定義
		setupStramingTopic();
        // 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 BGEIN
		try {
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 END
		// TL連携機能AGT情報の自動設定
		autoGeneralTlAccountInfo();
        // 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 BGEIN
		} catch (Exception e){}
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 END
		// 会計支払商品「基準」
		autoGeneralStandPayAccMaster();
		// Discussion Config Info 自動作成[2016/12/30 Release]
		autoGeneraldiscussionInfo();
        // 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 BGEIN
		try {
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 END
		// 2017/05/11 IOT機能通知文言定義の追加
		autuGeneralIotIconFile();
        // 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 BGEIN
		} catch (Exception e){}
		// 2017.05.31 標準オブジェクトに対して、データ作成処理エラー無視処理機能追加 END
		// 2018/06/04 データ状態定義共通定義定義初期化 BEGIN
		// 2018/06/04 初期化自動設定を行う
		(new DataFixManagerUtils()).init();
		// 2018/06/04 データ状態定義共通定義定義初期化 END
		// 2019/02/28 ユーザ「デイフォル店舗コード」項目を自動設定機能 FUTURE BEGIN
		// 既にVersion < 19.9
		if (isInstalledVersionBefore(new Version(19, 10))) {
			UserUtil.syncShopcodeToDefShopCode();
		}
		// 2019/02/28 ユーザ「デイフォル店舗コード」項目を自動設定機能 FUTURE END
		// 2019/04/15 Version19.19から  FUTURE BEGIN
		if (previousVersion == null || isInstalledVersionBefore(new Version(19, 19))) {
			try {
				JinyaInstallClassHelpBatch schedult = new JinyaInstallClassHelpBatch();
				DateTime nowTime = DateTime.now().addSeconds(30);
				// 起動ＣＲＯＮを設定する
				String timeStr = nowTime.format('yyyyMMddHHmmss');
				String yy = timeStr.substring(0,4);
				String mm = timeStr.substring(4,6);
				String dd = timeStr.substring(6,8);
				String hh = timeStr.substring(8,10);
				String ms = timeStr.substring(10,12);
				String ss = timeStr.substring(12,14);
				String sch = ss + ' ' +
				       ms + ' ' +
				       hh + ' ' +
				       dd + ' ' +
				       mm + ' ' +
				       ' ? ' + yy;
				String jobName = 'AREAMSTIMPORT_' + DateTime.now().format('yyyyMMddHHmmssSSS') + '|' + String.valueof(Crypto.getRandomLong());
				String jobId = system.schedule(jobName, sch, schedult);
			} catch (Exception e){} 
		}
		// 2019/04/15 Version19.19から  FUTURE END
    }
    
    /* This method will return Contact Lookup, Account Lookup and Phone number field ids from Reservation object.*/
    /*private Map<String, String> getResRefDetails(){
    		Map<String, String> resRefMap = new Map<String, String> ();
    	try{
    		
    		List<RecordType> bookingRecTypeList = [Select id , name From RecordType where DeveloperName = 'BookingRecType'];
    		 
    		// Map<String, Schema.RecordTypeInfo> recTypeMap =  Lead__c.SObjectType.getDescribe().getRecordTypeInfosByName();
    		 if(bookingRecTypeList!=null  && bookingRecTypeList.size() >0){
					String recTypeId = bookingRecTypeList[0].id;
					 	
					//Get the field describe values for Contact lookup from reservation object.
			    	Schema.DescribeFieldResult contactDesc = Schema.sObjectType.Lead__c.fields.Relcontact__c;
			    	Schema.DescribeFieldResult accDesc = Schema.sObjectType.Lead__c.fields.refAccount__c;
			    	Schema.DescribeFieldResult phoneDesc = Schema.sObjectType.Lead__c.fields.ContactPhone__c;
				   		
				    ///Get the page reference for Lead__c object
					PageReference p = new PageReference('/' + Lead__c.SObjectType.getDescribe().getKeyPrefix() + '/e?nooverride=1&RecordType='+recTypeId);
					String html = p.getContent().toString();
					Map<String, String> labelToId = new Map<String, String>();
					Matcher m = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?(.*?)</label>').matcher(html);
					while (m.find()) {
					   String label = m.group(3);
					    String id = m.group(1);
					    labelToId.put(label, id);
					}
					
					resRefMap.put('contRef', labelToId.get(contactDesc.getLabel()));
					resRefMap.put('accRef', labelToId.get(accDesc.getLabel()));
					resRefMap.put('phoneRef', labelToId.get(phoneDesc.getLabel()));
					System.debug('resRefMap:: '+resRefMap);
    		 }
    	}catch(Exception e){
    		System.debug('Error occured while getting Contact reference from lead__c object '+e);
    	}
    	return resRefMap;
    	
    }*/
    
	private Boolean isInstalledVersionBefore(Version version) {
        return previousVersion != null && previousVersion.compareTo(version) < 0;
    }
    
    private void setupStramingTopic() {
    	
    	map<String, String> topicQueryMap = new map<String, String>{
    		'TimeManagement'=>'select Id, ps__WorkDay__c, ps__WorkBeginTime__c, ps__WorkEndTime__c, ps__OutingTime__c, ps__EnteringTime__c, ps__OutingTime2__c, ps__EnteringTime2__c, ps__OutingTime3__c, ps__EnteringTime3__c, ps__WorkerRef__c from ps__TimeManagement__c ',
    		'RestTimeManagement'=>'select ps__EnteringTime__c, Id, ps__LateNightRestTime__c, Name, ps__OutingTime__c, ps__RestMinuteSum__c, ps__WorkerRefCal__c,ps__WorkDayCal__c  from ps__RestTimeManagement__c ',
    		'MessageInformation'=>'Select Id, ps__MessageHelpUrl__c, ps__Message__c, ps__MessageCode__c, ps__MessageLevel__c, ps__MessageSub1__c, ps__MessageType__c, Name, LastModifiedDate from ps__MessageInformation__c',
    		'pushroomtypeinventorylist'=>'select id, ps__RoomTypeCodeCal__c, ps__RoomTypeNameCal__c, ps__StockChangeDateCal__c, ps__RemainingCount__c,ps__ShopCodeCal__c, ps__RoomTypeRef__c, ps__SalesStatusLst__c,ps__QtyOfStock__c from ps__GuestRoomStock__c'
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
			,'InvoiceStatementUpdates'=>'SELECT Id FROM ps__CooperationResult__c where  ps__FunctionType__c = \'レーシト印刷\' and ps__Status__c = \'予約取込待ち\''
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
    	};
    	set<String> topicNameList = topicQueryMap.keySet();
	    List<pushtopic> upsertPushTopic = Database.query('select id, Name from pushtopic where name = :topicNameList');
	    map<String, pushtopic> topicMap = new map<String, pushtopic>();
	    for (pushtopic topic : upsertPushTopic) topicMap.put(topic.Name, topic);
	    
	    for (String topicName : topicNameList) {
	    	if (!topicMap.containsKey(topicName)) {
				PushTopic pushTopic = new PushTopic();
				pushTopic.Name = topicName;
				pushTopic.Query = topicQueryMap.get(topicName);
				// 2018/10/19 APEX VERSION:27->42変更対応 WSQ BEGIN
				//pushTopic.ApiVersion = 27.0;
				//pushTopic.NotifyForOperations = 'All';
				//pushTopic.NotifyForFields = 'Referenced';
				pushTopic.ApiVersion = 42.0;
				pushTopic.NotifyForOperationCreate = true;
				pushTopic.NotifyForOperationUpdate = true;
				// 2018/10/19 APEX VERSION:27->42変更対応 WSQ END
				pushTopic.NotifyForFields = 'Referenced';
				upsertPushTopic.add(pushTopic);
	    	} else {
	    		// 2018/10/19 APEX VERSION:27->42変更対応 WSQ BEGIN
	    		//topicMap.get(topicName).Query = topicQueryMap.get(topicName);
	    		PushTopic pushTopic = topicMap.get(topicName);
	    		pushTopic.Query = topicQueryMap.get(topicName);
				pushTopic.ApiVersion = 42.0;
				pushTopic.NotifyForOperationCreate = true;
				pushTopic.NotifyForOperationUpdate = true;
				pushTopic.NotifyForFields = 'Referenced';
				// 2018/10/19 APEX VERSION:27->42変更対応 WSQ END
	    	}
	    }
	    upsert upsertPushTopic;
    }
    // TL連携用取引先エンジン定義情報の自動作成
    private void autoGeneralTlAccountInfo() {
		String[] names = new List<String>{'JTB','近畿日本ツーリスト','日本旅行','トップツアー','農協観光','名鉄観光','ＪＲ東海ツアーズ','全日空(ANAス カイホリデー分)','ＪＲ北海道','ＪＲ東日本','ＪＲ四国','ＪＲ九州','ＪＲ共同','東武トラベル','JALツアーズ','yoyaQ','フジトラベル','ホワイト・ベアーファ ミリー','WELBOX','ツアーランド・たびらい','ちゅらとく','JREH-GE','e-concierge','RJ-win','Booking.com','スマ宿(H.I.S.)','REVIVE','阪急交通社','ジャル パック','Agoda','Expedia','Pegasus','RatesToGo','共通販売','るるぶトラベル(旧e-Hotel)','オリエンタルランド','e宿','小田急トラベル','HRS','Yahoo!トラベ ル','楽天トラベル','TYMS/R-with\'s','Dynatech','エイチ・アイ・エス','じゃらんnet','Ozmall','Ctrip','ビッグホリデー','宿ぷらざ','エアリーサイト','沖縄 ツーリスト','ぐるなびトラベル','HPDS','宿シス','TENAWAN','一休.com','リザーブゲート','i-honex','ベストリザーブ・宿ぷらざ','予約番','SUITE','WILLER  TRAVEL','ベネフィット・ステーション','予約プロ','Yadvance!','らくだ倶楽部','Smart/Optima','たび寅','JTO','MAPPLEトラベル','全日空(@ホテル・旅作分)','西鉄旅行'};
		String[] status = new List<String>{'有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効','有効'};
		String[] companyCodes = new List<String>{'01','02','03','04','05','06','07','09','11','12','14','15','16','17','19','21','22','23','24','25','26','27','28','29','30','31','32','33','34','46','47','48','49','50','51','53','55','56','57','58','61','62','64','65','66','67','68','69','70','71','72','75','77','78','79','80','81','82','83','84','85','86','87','88','89','90','91','92','93','94','95','97'};
		String[] companyCodesApi =new List<String>{'101','102','103','104','105','106','107','109','111','112','114','115','116','117','119','121','122','123','124','125','126','127','128','129','130','131','132','133','134','146','147','148','149','150','151','153','155','156','157','158','161','162','164','165','166','167','168','169','170','171','172','175','177','178','179','180','181','182','183','184','185','186','187','188','189','190','191','192','193','194','195','197'};
		String[] companyTypes = new List<String>{'リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','リアル','ネット','リアル','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','リアル','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','リアル','ネット','ネット','ネット','リアル','ネット','ネット','リアル','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','ネット','リアル'};
		// 既存の取引先情報を取得する[名前昇順、旅行会社分類（NULLは先に表示）]
		List<Account> existTravlAccount = [select id,name,ContractStatus__c,AccountType__c,SalesOfficeCompanyCodeTL__c,SalesOfficeCompanyCodeTLAPI__c,SalesOfficeCompanyType__c from Account where AccountType__c = :CommConst.ACCOUNT_TYPE_TRAVEL And (name in :names or SalesOfficeCompanyCodeTL__c in :companyCodes) and parentId = null order by name, SalesOfficeCompanyType__c NULLS FIRST, SalesOfficeCompanyCodeTLAPI__c NULLS FIRST];
        map<String, Account> existAccMap = new map<String, Account>();
        map<String, Account> tlCodeExistMap = new map<string, Account>();
        for (Account acc : existTravlAccount) {
        	// 同じ名前の取引先情報を存在すると、更新を行う
        	existAccMap.put(acc.name, acc);
        	if (!CommUtils.isBlank(acc.SalesOfficeCompanyCodeTL__c)){
        		tlCodeExistMap.put(acc.SalesOfficeCompanyCodeTL__c, acc);
        	}
        }
        List<Account> accList = new List<Account>();
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'salesofficecompanytype__c','salesofficecompanycodetlapi__c','salesofficecompanycodetl__c','accounttype__c','contractstatus__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.GuestRoomStock__c.fields.getMap();
        if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        for (Integer i = 0; i<names.size();i++) {
        	Account accItem = null;
        	// TLのコードと一致する場合
        	if (tlCodeExistMap.containsKey(companyCodes[i])) {
        		accItem = tlCodeExistMap.get(companyCodes[i]); 
        	} else if (existAccMap.containsKey(names[i])) {
        		accItem = existAccMap.get(names[i]);
        	} else {
        		accItem = new Account(Name = names[i]); 
        	}
        	//accItem.Name = names[i];
            accItem.ContractStatus__c = status[i];
            accItem.AccountType__c = CommConst.ACCOUNT_TYPE_TRAVEL;
            accItem.SalesOfficeCompanyCodeTL__c = companyCodes[i];
            accItem.SalesOfficeCompanyCodeTLAPI__c = companyCodesApi[i];
            accItem.SalesOfficeCompanyType__c = companyTypes[i];
         	accList.add(accItem);
        }
        if (!accList.isEmpty()) upsert accList;
    }
    private void autoGeneralStandPayAccMaster() {
    	// 会計支払商品を自動作成を行う
    	//String[] names = new List<String>{'現金','カード','売掛金','クーポン','値引','予約金'};
    	String[] names = new List<String>{Label.CONST_012_0438,Label.CONST_012_0439,Label.CONST_012_0440,Label.CONST_012_0441,Label.CONST_012_0442,Label.CONST_012_0443};
    	String[] codes = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
    	String[] pays = new List<String>{'現金','カード','売掛金','クーポン','値引','予約金'};
    	// 2016/05/2同じ会計商品コード存在チェック方法変更
    	//List<AccountMaster__c> accMasterLst = [select id,name,Field3__c from AccountMaster__c where Field3__c in :codes and ActionType__c = :CommConst.PROD_ACTION_TYPE_PY and PaymentType__c != null];
    	List<AccountMaster__c> accMasterLst = [select id,name,Field3__c from AccountMaster__c where Field3__c in :codes];
    	map<string, AccountMaster__c> accMaps = new map<String, AccountMaster__c>();
    	for (AccountMaster__c acc : accMasterLst) { accMaps.put(acc.Field3__c, acc); }
    	List<AccountMaster__c> newAccMst = new List<AccountMaster__c>();
    	for (Integer i = 0; i<codes.size();i++) {
    		String code = codes[i];
    		if (accMaps.containsKey(code)) continue;
    		AccountMaster__c accMst = new AccountMaster__c(
    			Name = names[i],
    			Field3__c = code,
    			ActionType__c = CommConst.PROD_ACTION_TYPE_PY,
    			PaymentType__c = pays[i]
    		);
    		newAccMst.add(accMst);
    	}
    	if (!newAccMst.isempty()) insert newAccMst;
    }
    
    private void autoGeneraldiscussionInfo() {
    	list<JinyaConfig__c> jinyaConfig = [select name, value__c from JinyaConfig__c where name = 'discussionforumurl' limit 1];
    	if (jinyaConfig.isEmpty()) {
    		JinyaConfig__c item = new JinyaConfig__c(
				name= 'discussionforumurl',
				Value__c = 'https://52.192.199.237/login/sfsso'
			
			);
			insert item;
    	}
    }
    // IOTメッセージ用アイコン自動設定機能 BEGIN
    public void autuGeneralIotIconFile() {
    	// 2019/09/15 Security Check BY zyz BEGIN
    	List<String> chkFieldsLst = new List<String>{'versiondata','title','pathonclient','origin'};
    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.ContentVersion.fields.getMap();
    	if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
    		return ;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	List<String> iconFileKey = IOTInformationSync.getIotIconTypeList();
    	List<Document> docs = [select id,DeveloperName,body from Document where DeveloperName in :iconFileKey];
    	Map<String,Document> existFileDocMap = new map<String, Document>();
    	for (Document doc : docs) {
    		existFileDocMap.put(doc.DeveloperName, doc);
    	}
    	if (!existFileDocMap.isEmpty()) {
    		// 関連のファイルは既に存在するがどうかチェックする
    		List<ContentVersion> cvs = [select id,ContentDocumentId,Title from ContentVersion where IsLatest = true and Title in :existFileDocMap.keyset()];
    		for (ContentVersion cv : cvs) {
    			existFileDocMap.remove(cv.Title);
    		}
    		// CSVはNULLじゃない場合
    		List<ContentVersion> newCvs = new List<ContentVersion>();
    		if (!existFileDocMap.isEmpty()) {
    			for (String key : existFileDocMap.keySet()) {
    				ContentVersion cv  = new ContentVersion();
    				cv.Origin = 'H';
    				cv.PathOnClient = key;
    				cv.Title = key;
    				cv.VersionData = existFileDocMap.get(key).body;
    				newCvs.add(cv);
    			}
    			if (!newCvs.isEmpty()) insert newCvs;
    			set<id> newCsIds = new set<id>();
    			for (ContentVersion cv : newCvs) newCsIds.add(cv.Id);
    			List<ContentVersion> insCvs = [select ContentDocumentId from ContentVersion where id = :newCsIds];
    			List<ContentDocumentLink> cvLinks = new List<ContentDocumentLink>();
    			Id orgId = UserInfo.getOrganizationId();
    			for (ContentVersion cv : insCvs) {
	    			ContentDocumentLink newLink = new ContentDocumentLink(
	    				ContentDocumentId = cv.ContentDocumentId,
	    				ShareType = 'V',
	    				Visibility = 'AllUsers',
	    				LinkedEntityId = orgId
	    			);
	    			cvLinks.add(newLink);
    			}
    			if (!cvLinks.isEmpty()) insert cvLinks;
    		}
    	}	
    }
    // IOTメッセージ用アイコン自動設定機能 END
    // 2017/06/06 PUSHTOPICの自動作成機能対応 BEGIN
    // isCheckFlg:TRUEの場合、TOPIC情報が存在すると、次の処理を行わない FALSE:TOPIC情報が存在すると、次の処理を行う
	public static void setupCtiStramingTopic(Boolean isCheckFlg) {
		if(Test.isRunningTest()) return;
 		// Push Topic Call Popup window setup
	    List<pushtopic> callPushTopic = Database.query('select id from pushtopic where name = \'CallInformation\' limit 1');
	    // 既に存在の場合、処理終了
	    if (isCheckFlg && !callPushTopic.isEmpty()) return;
	    PushTopic pushTopic  = new PushTopic();
 		if(!callPushTopic.isEmpty()){
 			pushTopic  = new PushTopic(Id = callPushTopic[0].Id);
 		}
		else{
			pushTopic.Name = 'CallInformation';
			// 2018/10/19 APEX VERSION:27->42変更対応 WSQ BEGIN
			//pushTopic.ApiVersion = 27.0;
			//pushTopic.NotifyForOperations = 'All';
			//pushTopic.NotifyForFields = 'Referenced';
			// 2018/10/19 APEX VERSION:27->42変更対応 WSQ END
		}
		// 2014/10/20 DNO__c項目を追加する
		pushTopic.Query = 'SELECT Id, ps__DNO__c, ps__SNO__c, ps__NAM__c, ps__isRSNP__c, ps__RSN_Code__c, ps__isDCD1__c, ps__DT4__c, ps__DT1__c, ps__DT0__c, ps__Call_Time__c, ps__LNO__c, ps__Account__c, ps__Contact__c, ps__Company_name__c, ps__contact_Name__c, ps__No_of_Matching_Customers__c,ps__IsCustomerUpdated__c,ps__CallType__c,ps__CarModel__c,ps__CarColor__c,ps__MessageUUID__c, ps__Contact_KatakanaCal__c FROM ps__Call_Information__c';
		// 2018/10/19 APEX VERSION:27->42変更対応 WSQ BEGIN
		pushTopic.ApiVersion = 42.0;
		pushTopic.NotifyForOperationCreate = true;
		pushTopic.NotifyForOperationUpdate = true;
		pushTopic.NotifyForFields = 'Referenced';
		// 2018/10/19 APEX VERSION:27->42変更対応 WSQ END
		upsert pushTopic;
	}
    // 2017/06/06 PUSHTOPICの自動作成機能対応 END
    // 2017/08/31 活動関連取込先レポートID自動設定用 BEGIN
    private void setActivityRefAccountReportId(CommDefine__c def) {
        if (CommUtils.isBlank(def.ActivityRefAccountReportId__c)) {
            List<Report> rep = [select id from Report Where DeveloperName = 'R20170831_ActivityRefAccountReport' limit 1];
            if (!rep.isEmpty()) def.ActivityRefAccountReportId__c = rep[0].Id;
        }
    }
    // 2017/08/31 活動関連取込先レポートID自動設定用 END

/**
*2015-11-18 
*テストクラスJinyaInstallClassTestに移行する   
	@isTest(seeAllData=true)
	static void testInstallScript() {
		//delete [select id from pushTopic];
		String[] codes = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
		//delete [select id from AccountMaster__c where Field3__c in :codes and ActionType__c = :CommConst.PROD_ACTION_TYPE_PY and PaymentType__c != null];
  		JinyaInstallClass postinstall = new JinyaInstallClass();
    	Test.testInstall(postinstall, null);
    	Test.testInstall(postinstall, new Version(1,5), true);
   		List<ReportLogo__c> a = [Select id from ReportLogo__c where name =: CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name()];
    	System.assertEquals(a.size(), 1, 'ReportLogo not found');
    	System.assertEquals([select id from pushTopic].size(),3);
    	System.assertEquals([select id from AccountMaster__c where Field3__c in :codes and ActionType__c = :CommConst.PROD_ACTION_TYPE_PY and PaymentType__c != null].size(),codes.size());
	}
*/
}