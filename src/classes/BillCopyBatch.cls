/*********************************************
* 請求書一括自動作成バッチ
* 2019/03/19 機能改善対応
*		請求書宛名はコピー元からコピーできるように改善
*		12ヶ月分の予約がまとめて作成出来る
*********************************************/
public with sharing class BillCopyBatch implements  Database.Batchable<Sobject>, Database.Stateful{
	// 2019/03/19 機能改善対応(無効ソースを削除) WSQ BEGIN
	//private CommLogUtils log;
	// 2019/03/19 機能改善対応(無効ソースを削除) WSQ END
	private String Query;					// 検索SOQL
	private static final integer CONST_BATCH_EXECUTE_COUNT = 1;
	private AccountAcount__c acc;//請求書自動起動ページのパラメータ情報を格納用
	private List<Id> leadIds;
	private List<String> result;
	private Set<Id> accountIdSet;
	// メール情報を設定する
	private	String baseURL = 'https://login.salesforce.com';
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
	public static String MAIL_LEAD_HEAD{get{
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
		// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
		if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
		// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
			return Schema.sObjectType.Lead__c.fields.Departure__c.getlabel();
		}
		return Schema.sObjectType.Lead__c.fields.EntryTime__c.getlabel();
	}private set;}
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
	private final String MessageLine = '売上計上日/' + MAIL_LEAD_HEAD + ':';
	private boolean isLeadFlag = true;
	// 2019/03/19 機能改善対応 WSQ BEGIN
	private Integer remaindCnt;//残り作成予定の月数
	// インスタンス化
	// ids : 起動画面に選択した予約ID値
	// formInput: 起動画面に設定したパラメータ値格納(コメント、ハンコ表示etc)
	// loopSize: 起動画面からまとめて作成したい月数
	// バッチリクエストから新規起動されるがどうか機能
	public BillCopyBatch(List<Id> ids,AccountAcount__c formInput, Integer loopSize, List<String> pResult){
		// 残り作成予定の月数
		remaindCnt = loopSize;
	// 2019/03/19 機能改善対応 WSQ END
		Query = CommSqlUtils.generateQueryString('lead__c',new List<String>{'Relcontact__r.name'});
		//定数
		Query += ' where id = :leadIds';
		// 2019/03/19 機能改善対応(無効ソースを削除) WSQ BEGIN
		//log = new CommLogUtils('BillCopyBatch',true); 
		// 2019/03/19 機能改善対応(無効ソースを削除) WSQ END
		acc = formInput;
		leadIds = ids;
		accountIdSet = new Set<Id>();
		result = (pResult == null ? new List<String>() : pResult);
		// 売上計上日情報を設定する
		result.add(MessageLine+CommUtils.dateToYYYYMMDD(acc.SalesDate__c));
	}
	// 2019/03/19 機能改善対応 WSQ BEGIN
	private BillCopyBatch(List<Id> pLeadIds, Set<Id> accountIds,AccountAcount__c formInput, Integer loopSize, List<String> pResult){
		// 画面選択した予約ID
		leadIds = pLeadIds; 
		// 残り作成予定の月数
		remaindCnt = loopSize;
		//Query = 'select id,comment__c from AccountAcount__c where id in:accountIdSet';
		// 請求宛名:AccountName__c,領収証宛名:AccountReceiptName__c,但し書き内容:AccountProviso__c
		Query = 'select id,comment__c,AccountReceiptName__c,AccountName__c,AccountProviso__c,Relreserve__c from AccountAcount__c where id in:accountIdSet';
		// 2019/03/19 機能改善対応 WSQ END
		accountIdSet = accountIds;
		acc = formInput;
		isLeadFlag = false;
		result = pResult;
	}
	// ***********************************
	// バッチ処理開始  
	// ***********************************
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
	/*
	public Database.QueryLocator start(Database.BatchableContext BC){
		//指定予約コピー
		return Database.getQueryLocator(Query);
	}
	*/
	public List<Sobject> start(Database.BatchableContext BC){
		if (!isLeadFlag) {
			String leadIdPrefix = Lead__c.sObjectType.getDescribe().getKeyPrefix();
			Set<Id> pLeadSet = new Set<Id>();
			Set<Id> pAccountSet = new Set<Id>();
			Set<Id> orgAccountSet = accountIdSet;
			for (Id accId : accountIdSet) {
				if (CommUtils.nullTOBlank(accId).startsWith(leadIdPrefix)) pLeadSet.add(accId);
				else pAccountSet.add(accId);
			}
			map<String,Lead__c> leadMap= new map<String,Lead__c>();
			for(Lead__c lead : [select id,AccountReceiptName__c,AccountProviso__c,Relcontact__r.name from Lead__c where id in:pLeadSet and Field298__c != :CommConst.LEAD_GUEST_ST_CI]) {
				leadMap.put(lead.id,lead);
			}
			accountIdSet = pAccountSet;
			Map<String,AccountAcount__c> accMap = new Map<String,AccountAcount__c>();
			for (AccountAcount__c acc : Database.query(Query)) {
				accMap.put(acc.id,acc);
			}
			List<Sobject> results = new List<Sobject>();
			for (id leadId : orgAccountSet) {
				if (accMap.containsKey(leadId)) results.add(accMap.get(leadId));
				else if (leadMap.containsKey(leadId)) results.add(leadMap.get(leadId));
			}
			return results;
		} 
		//指定予約コピー
		return Database.query(Query);
	} 
	// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy EMD
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<Sobject> scope){
		if (isLeadFlag) excuteLead(scope[0]);
		else excutePdf(scope[0]);
	}
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		// 2019/03/19 機能改善対応 WSQ BEGIN
		// 請求書一括作成
		if (isLeadFlag) {
			// 請求書作成バッチを起動する
			//BillCopyBatch pdfBatch = new BillCopyBatch(accountIdSet,acc);
			BillCopyBatch pdfBatch = new BillCopyBatch(leadIds,accountIdSet,acc,remaindCnt,result);
			Database.executeBatch(pdfBatch,1);
		
		} else if (remaindCnt > 1) {
			// 作成目標数減算する
			remaindCnt --;
			// 画面から指示月日は月末がどうか判断する、月末場合、まとめて作成の日付も月末に設定する
			Date curDate = acc.SalesDate__c;
			// 月末の場合
			if (curDate.day() == Date.daysInMonth(curDate.year(),curDate.month())) {
				// 次の計上日も月末に設定する
				Date wkDate = curDate.addMonths(1);
				acc.SalesDate__c = Date.newInstance(wkDate.year(), wkDate.month(), Date.daysInMonth(wkDate.year(), wkDate.month()));
			} else {
				// 次の月の売上計上日を設定する
				acc.SalesDate__c = curDate.addMonths(1);
			}
			// 次の月の予約と会計データを作成する
			BillCopyBatch leadBatch = new BillCopyBatch(leadIds,acc,remaindCnt,result);
			Database.executeBatch(leadBatch,1);
		// 2019/03/19 機能改善対応 WSQ END
		// メール送信	
		} else {
			sendMail(system.today());
		}
	} 
	// 指定コピー元からご予約データを作成する
	private void excuteLead(Sobject sobj){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'field310__c','leadindexsubid__c','leadreceiptdate__c','name','entrytime__c',
													'departure__c','field298__c','plandetailsyncinfo__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		List<String> chkFieldLst = new List<String>{'issuedate__c'};
		Map<String,Schema.SObjectField> m = Schema.SObjectType.AccountAcount__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldLst, m)) {
			return ;
		}
		List<String> chkinFieldsLst = new List<String>{'refbooking__c','usedate__c'};
		Map<String,Schema.SObjectField> insmm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkinFieldsLst, insmm)) {
			return ;
		}
		List<String> chkindeFieldsLst = new List<String>{'rooms__c','nights__c','departuredate__c','entrydate__c'};
		Map<String,Schema.SObjectField> insdemm = Schema.SObjectType.LeadINdex__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkindeFieldsLst, insdemm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		Lead__c billLead = (Lead__c) sobj;
		Lead__c cloneBillLead = billLead.clone(false,false);
		// subLeadIndex取得
		String subIndexQuery = CommSqlUtils.generateQueryString('Leadindex__c');
		String subId = billLead.LeadIndexSubId__c;
		String leadId = billLead.id;
		subIndexQuery += ' where id = :subId';
		list<LeadINdex__c> leadindexLst = Database.query(subIndexQuery);
		LeadINdex__c cloneLeadSub = null;
		Savepoint sp = Database.setSavepoint();   
		try{
			// 2019/05/15 ⑩請求書重複作成できるの改善 by zy BEGIN
			// 指定日予約存在チェック
			List<Lead__c> exitLeads = [select id,name,Field298__c,LeadReceiptDate__c from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) = :acc.SalesDate__c and LeadIndexRef__c = :billLead.LeadIndexRef__c and Relcontact__c = :billLead.Relcontact__c and Rroom__c = :billLead.Rroom__c];
			if (!exitLeads.isEmpty()) {
				Lead__c newLead = exitLeads[0];
				// 予約未チェックイン
				if (CommUtils.isblank(newLead.Field298__c)){
					accountIdSet.add(newLead.id);
					// 画面設定の発行日付設定
					if (newLead.LeadReceiptDate__c != acc.IssueDate__c) {
						newLead.LeadReceiptDate__c = acc.IssueDate__c;
						update newLead;
					}
					return;
				// 予約チェックイン
				} else {
					List<AccountAcount__c> accounts = [select id,IssueDate__c from AccountAcount__c where Relreserve__c = :newLead.id];
					if (!accounts.isEmpty()){
						AccountAcount__c newAcc = accounts[0];
						accountIdSet.add(newAcc.id);
						// 画面設定の発行日付設定
						if (newAcc.IssueDate__c != acc.IssueDate__c) {
							newAcc.IssueDate__c = acc.IssueDate__c;
							update newAcc;
						}
					} else {
						// 画面設定の発行日付設定
						if (newLead.LeadReceiptDate__c != acc.IssueDate__c) {
							newLead.LeadReceiptDate__c = acc.IssueDate__c;
							update newLead;
						}
						accountIdSet.add(newLead.id);
					}
					return;
				}
			}
			// 2019/05/15 ⑩請求書重複作成できるの改善 by zy END
			if (!leadindexLst.isEmpty()) {
				cloneLeadSub = leadindexLst[0].clone(false,false);
				cloneLeadSub.EntryDate__c = acc.SalesDate__c;//画面指定の売上計上日で到着日を設定する
				cloneLeadSub.DepartureDate__c = cloneLeadSub.EntryDate__c.addDays(1);
				if (cloneLeadSub.Nights__c > 1) cloneLeadSub.Nights__c = 1;
				cloneLeadSub.Rooms__c = 1;
				insert cloneLeadSub;
			}
			
			// SUB INDEX
			cloneBillLead.LeadIndexSubId__c = cloneLeadSub == null ? null : cloneLeadSub.id;
			// 予約初期化
			cloneBillLead.EntryTime__c = Datetime.newinstance(cloneLeadSub.EntryDate__c,CommUtils.stringtotime(cloneBillLead.Field4__c));
			cloneBillLead.Departure__c = Datetime.newinstance(cloneLeadSub.EntryDate__c.addDays(CommUtils.nullToIntZero(cloneLeadSub.Nights__c))
											,CommUtils.stringtotime(cloneBillLead.Field3__c));
			cloneBillLead.Field298__c = null;
			// プラン連動しない項目を設定する
	        cloneBillLead.Field310__c = null;
			cloneBillLead.PlanDetailSyncInfo__c = CommConst.CONST_PLANITEM_NOEXPAND;
			String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
			cloneBillLead.name = cloneBillLead.Relcontact__r.name + cloneBillLead.EntryTime__c.format('yyyyMMdd');
			if (billLead.name.startsWith(LEAD_NAME_PREFIX)) cloneBillLead.name = LEAD_NAME_PREFIX + cloneBillLead.name;
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			if (CommUtils.isblank(billLead.Field298__c)) {
				// 画面設定の発行日付設定
				cloneBillLead.LeadReceiptDate__c = acc.IssueDate__c;
			}
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
			insert cloneBillLead;
			// 見積明細設定作成
			String bookingEstQuery = CommSqlUtils.generateQueryString('BookingEstimateItem__c');
			bookingEstQuery += ' where refBooking__c = :leadId and ParentBookingItemRef__c = null';
			List<BookingEstimateItem__c> bookItems = Database.query(bookingEstQuery);
			List<BookingEstimateItem__c> cloneItems = new List<BookingEstimateItem__c>();
			// 利用日取得
			Date defUseDate = cloneBillLead.EntryTime__c.date();
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH BEGIN
			// if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI) {
			if (CommConst.APPOTION_ACC_SALESDATE_DIV_CODE != CommConst.APPOTION_ACC_SALESDATE_DIV_CODE_CI && !CommConst.BOOKEST_USERDATE_FLG) {
			// 2019/09/15 新規予約ウインドウ、見積明細設定画面の利用日は常に到着日で設定する機能対応 WGCH END
				defUseDate = cloneBillLead.Departure__c.Date();
			}
			for (BookingEstimateItem__c book : bookItems) {
				BookingEstimateItem__c cloneBooking = book.clone(false,false);
				cloneBooking.refBooking__c = cloneBillLead.id;
				// 利用日設定
				cloneBooking.UseDate__c = defUseDate;
				cloneItems.add(cloneBooking);
			}
			if (!cloneItems.isEmpty()) insert cloneItems;
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			if (CommUtils.isblank(billLead.Field298__c)) {
				accountIdSet.add(cloneBillLead.id);
				return;
			} else {
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
			// 予約チェックイン
			cloneBillLead.Field298__c = CommConst.LEAD_GUEST_ST_CI;
			// 会計データ自動作成
			update cloneBillLead;
			// 該当予約の会計取得
			// コピーにより、新規作成の会計情報
			List<AccountAcount__c> accounts = [select id from AccountAcount__c where Relreserve__c = :cloneBillLead.id];
			// コピー元の会計情報
			List<AccountAcount__c> orgAccounts = [select id,relaccount__c,AccountName__c,AccountReceiptName__c,AccountProviso__c from AccountAcount__c where Relreserve__c = :billLead.id];
			if (!accounts.isEmpty()) {
				AccountAcount__c objAcc = accounts[0];
			    ApexPages.StandardController contrl = new ApexPages.StandardController(objAcc);
		        BillSimpleInputCtrl ctrl = new BillSimpleInputCtrl(contrl);
		        ctrl.batchExcuteFlag = true;
		        ctrl.initAction();
		        // 画面設定のコメント
		        ctrl.oAcountSobj.comment__c = acc.comment__c;
		        // 画面設定の発行日付設定
		        ctrl.oAcountSobj.IssueDate__c = acc.IssueDate__c;
		        // 2019/03/19 請求書宛名はコピー元からコピーできるように改善 WSQ BEGIN
		        // 請求書＆領収書レイアウト有効フラグtrue,但し設定
		        //if (CommConst.Bill_RCPTISSHOW_FLG && orgAccounts[0] != null)
		        //	ctrl.oAcountSobj.AccountProviso__c = orgAccounts[0].AccountProviso__c;
		        if (!orgAccounts.isEmpty()) {
		        	// コピー元会計情報を取得する
		        	AccountAcount__c orgAcc = orgAccounts[0]; 
					//請求宛名
		        	if (!CommUtils.isBlank(orgAcc.AccountName__c)) ctrl.oAcountSobj.AccountName__c = CommUtils.nullToBlank(orgAcc.AccountName__c);
					//領収証宛名
		        	if (!CommUtils.isBlank(orgAcc.AccountReceiptName__c)) ctrl.oAcountSobj.AccountReceiptName__c = CommUtils.nullToBlank(orgAcc.AccountReceiptName__c);
					//領収証但し 
		        	if (!CommUtils.isBlank(orgAcc.AccountProviso__c)) ctrl.oAcountSobj.AccountProviso__c = CommUtils.nullToBlank(orgAcc.AccountProviso__c);
		        }
		        // 2019/03/19 請求書宛名はコピー元からコピーできるように改善 WSQ END
		        // 会計保存
		        ctrl.upsertData();
		        accountIdSet.add(objAcc.id);
			}
			}
		}catch(Exception e){
			DataBase.rollback(sp);
		}
	}
	// コピー元でコピーした会計データ経由で、請求書PDFファイルを作成機能
	private void excutePdf(Sobject sobj){
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
		Id objectId = sobj.id;
		String objName = objectId.getSObjectType().getDescribe().getName();
		Lead__c leadObj = null;AccountAcount__c objAcc = null;
		if (objName == 'ps__Lead__c') leadObj = (Lead__c) sobj;
		else objAcc = (AccountAcount__c) sobj;
		// AccountAcount__c objAcc = (AccountAcount__c) sobj;
		// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		String body = '';
		try{
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			if (leadObj != null) {
				body += 'ご予約/会計:' + baseURL + '/' + leadObj.id + '\n';
				String pageName = '/apex/LeadBillPDF';
				Map<String,String> paramMap = new Map<String,String>();
				paramMap.put('id',leadObj.id);
				paramMap.put('stampFlg',CommUtils.nullToBlank(acc.IsNewLayout__c));//ページのハンコ表示・非表示フラグ項目
				paramMap.put('comment',CommUtils.nullToBlank(acc.comment__c));//ページのコメント
				// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
				if (Commconst.Bill_LETTER_FLG && acc.PaymentFlg__c) paramMap.put('letter',CommUtils.nullToBlank(acc.PaymentFlg__c));// 請求書の送付状出力・出力しない切替選択機能フラグ
				// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
				PdfAutoSaveUtil.syncLeadPdfToAttachment(paramMap,leadObj.id,pageName);
				body = '[' + leadObj.Relcontact__r.name + ']\n';
		        body += 'ご予約/会計:' + baseURL + '/' + leadObj.id + '\n';
				List<Attachment> atts = [select id from Attachment where ParentId = :leadObj.id and ContentType = 'application/pdf' order by CreatedDate];
				if (!atts.isEmpty()) body += '請求書PDF:' + baseURL + '/' + atts[0].id + '\n';
			} else {
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
			body += 'ご予約/会計:' + baseURL + '/' + objAcc.id + '\n';
			String pageName = '/apex/BillPDF';
			Map<String,String> paramMap = new Map<String,String>();
			paramMap.put('stampFlg',CommUtils.nullToBlank(acc.IsNewLayout__c));//ページのハンコ表示・非表示フラグ項目
			paramMap.put('bulkid',CommUtils.nullToBlank(objAcc.id));//画面からコピー先の会計ID
			paramMap.put('id',objAcc.id);
			// 2019/03/19 請求書宛名はコピー元からコピーできるように改善 WSQ BEGIN
			//paramMap.put('comment',CommUtils.nullToBlank(objAcc.comment__c));// BugFix
			paramMap.put('comment',CommUtils.nullToBlank(acc.comment__c));//ページのハンコ表示・非表示フラグ項目
			// 2019/03/19 請求書宛名はコピー元からコピーできるように改善 WSQ END
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			if (Commconst.Bill_LETTER_FLG && acc.PaymentFlg__c) paramMap.put('letter',CommUtils.nullToBlank(acc.PaymentFlg__c));// 請求書の送付状出力・出力しない切替選択機能フラグ
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
			PdfAutoSaveUtil.syncBillPdfToAttachment(paramMap,objAcc.id,pageName);
			List<AccountAcount__c> accs = [select id,relaccount__r.name from AccountAcount__c where id = : objAcc.id];
			if (!accs.isEmpty()) {
				body = '[' + accs[0].relaccount__r.name + ']\n';
		        body += 'ご予約/会計:' + baseURL + '/' + objAcc.id + '\n';
				List<Attachment> atts = [select id from Attachment where ParentId = :objAcc.id and ContentType = 'application/pdf' order by CreatedDate];
				if (!atts.isEmpty()) body += '請求書PDF:' + baseURL + '/' + atts[0].id + '\n';
			}
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy BEGIN
			}
			// 2019/05/15 チェックインをかけた予約しかコピーができませんが、チェックインをかけない段階での予約コピーはできませんでしょうか by zy END
		} catch(exception e) {		
		} 
        result.add(body);
	}
	// Apexでエラー情報を送信を行う
	private void sendMail(Date procDate) {
		//　ScheduleResultMailAddress__c
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		// 2019/03/19 請求書宛名はコピー元からコピーできるように改善 WSQ BEGIN
		// バッチスケジュール結果送信宛値が未設定場合、処理中止(BUGFIX)
		if (CommUtils.isBlank(mailAdds)) return;
		// 2019/03/19 請求書宛名はコピー元からコピーできるように改善 WSQ END
		// 計算統計する　
		Integer resultSize = 0;
		// メール情報を設定する
		String body = '';
		for (String s : result) {
			body += s + '\n';	
			// 売上計上日:XXXX　のメッセージは件数集計から抜き
			if (!s.startsWith(MessageLine)) resultSize++;
		}
		String mailBodyStr = '処理結果詳細	BEGIN';
		mailBodyStr += '\n自動作成請求書件数：' + resultSize + '(件)\n';
		mailBodyStr += 	body;
		mailBodyStr += '処理結果詳細END';
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = CommUtils.nullToBlank(mailAdds).split(',');
		mail.setToAddresses(toAddresses);
		mail.setSubject('[請求書自動作成] バッチ処理結果の通知['+UserInfo.getOrganizationName()+']');
		mail.setPlainTextBody(mailBodyStr);
system.debug(logginglevel.info,'mailBodyStr::::' + mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			try {
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			} catch(Exception e){}
		}
	}
}