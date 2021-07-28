/**
* お取引先情報マージ機能
* 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため
*/
global with sharing class AccountMerge {
	// マージ先お客様のID情報を格納する
	public Id newContactId{get; set;}
	// マージされるお客様のID（マージ元）
	public Id oldContactId{get; set;}
	// 検索キー[お客様検索情報]
	public String findKey{get; set;}
	// 初期化する
	public AccountMerge (ApexPages.StandardController ctrl){
		newContactId = ctrl.getId();
	}
	// 重複するお客様情報を検索する
	private static final String queryFieldsStr = 'Id,Name,phone,fax,BillingPostalCode,BillingCountry,BillingState,BillingCity,BillingStreet';
	private static final String queryWhereStr = ' Where Id != :newContactId ';
	// 検索結果情報を格納する
	public List<Account> queryRs{get; private set;}
	// 検索条件により、Mergeすお客様情報を検索する
	private Boolean preQueryConcatInfo() {
		if (CommUtils.isBlank(findKey) || (findKey.trim().length() < 2)) {
			//フリーワード検索文字は最低 2 文字指定してください。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0391));
			return false;
		}
		return true;
	}
	// エラーあり・なし判別フラグ
	public Boolean initHaveErrFlg{get; private set;}
	// 2019/07/15 マージ後で自動閉じる機能　by WSQ BEGIN
	public boolean autoCloseFlag{get; private set;}
	// 2019/07/15 マージ後で自動閉じる機能　by WSQ END
	// 初期化処理
	public void initAction() {
		initHaveErrFlg = false;
		List<Account> newContact = [select id,name,phone from account where id = :newContactId];
		if (newContact.isEmpty()) {
			//指定している取引先情報は削除されました。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0392));
			initHaveErrFlg = true;
			return;
		}
		// 画面に検索条件内容初期化設定
		findKey = newContact[0].Name + ' ' + CommUtils.nullToBlank(newContact[0].phone);
		queryConcatInfo();
	}
	
	// 画面条件を指定して、類似の取引先データを検索処理する
	public void queryConcatInfo () {
		if (!preQueryConcatInfo()) {
			return;
		}
		findKey = findKey.replace('"','\\"');
		String pString = 'FIND \''+string.escapeSingleQuotes(findKey)+'\' IN ALL FIELDS RETURNING Account('+queryFieldsStr+queryWhereStr+')';
System.debug(LoggingLevel.INFO, 'pString:::' + pString);
		List<List <sObject>> myQuery = search.query(pString);
		queryRs = (List<Account>)myQuery[0];
	}
	
	// 指定にお客様IDの関連リストをマージ先お客様へ入替えする
	public void mergerRelList() {
		// 指定のお客様情報をマージする
		List<Account> oldContacts = [select id from account where id = :oldContactId limit 1 for update ];
		if (oldContacts.isEmpty()) {
			//選択したのマージ元取引先情報を見つかりません。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0393));
			return;
		}
		List<Account> masterContacts = [select id from account where id = :newContactId limit 1 for update ];
		if (masterContacts.isEmpty()) {
			//マージ先取引先情報を見つかりません。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0394));
			return;
		}
		Savepoint sp = Database.setSavepoint();
		try {
			/* 2015/07/29 マージ機能改善対応
			// 関連リスト情報をマージする
			updateRelData(oldContactId, newContactId);
			// 既存の取引先情報を削除する
			delete oldContacts;
			*/
			// 2018/03/07 Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(Account.getSObjectType())){
				return;
			}
			// 2018/03/07 Security Check END
			Database.MergeResult results = Database.merge(masterContacts[0], oldContactId, true);
			if (!results.isSuccess()) {
				List<Database.Error> errors = results.getErrors();
				Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errors[0].getMessage()));
				DataBase.rollback(sp);
				return;
			}
		} catch (Exception e) {
			DataBase.rollback(sp);
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return;
		}
		// 最新情報を取得する
		queryConcatInfo();
	}
	// マージ先のお客様詳細画面へ遷移する
	public Pagereference gotoBack() {
		Pagereference page = new Pagereference('/' + newContactId);
		return page;
	}
	/*
	* 関連リスト情報マージ処理を行う
	*/
	private void updateRelData (Id oldContactId, Id newContactId) {
		/** Merage API利用するので、下記処理削除
		// お客様
		List<Contact> contacts = [select AccountId from Contact where AccountId = :oldContactId];
		for (Contact rs : contacts) {
			rs.AccountId = newContactId;
		}
		if (!contacts.isEmpty()) update contacts;
		// 商談
		List<Opportunity> opportunitys = [select AccountId from Opportunity where AccountId = :oldContactId];
		for (Opportunity rs : opportunitys) {
			rs.AccountId = newContactId;
		}
		if (!opportunitys.isEmpty()) update opportunitys;
		// ケース
		List<Case> cases = [select AccountId from Case where AccountId = :oldContactId];
		for (Case rs : cases) {
			rs.AccountId = newContactId;
		}
		if (!cases.isEmpty()) update cases;
		// 活動予定
		List<Event> events = [select WhatId from Event where WhatId = :oldContactId];
		for (Event rs : events) {
			rs.WhatId = newContactId;
		}
		if (!events.isEmpty()) update events;
		List<Task> taskoa = [select WhatId from Task where WhatId = :oldContactId];
		for (Task rs : taskoa) {
			rs.WhatId = newContactId;
		}
		if (!taskoa.isEmpty()) update taskoa;
		// 活動履歴 SKIP
		
		// メモ & 添付ファイル
		List<Note> sNote = [select ParentId, Title, IsPrivate, Body from Note where ParentId = :oldContactId];
		List<Note> oeList = new List<Note>();
		for (Note rs : sNote) {
			Note cWhatId = rs.clone(false,true);
			cWhatId.ParentId = newContactId;
			oeList.add(cWhatId);
		}
		if (!oeList.isEmpty()) insert oeList;
		List<Attachment> attachment = [select ParentId, Name, IsPrivate, ContentType, Body, BodyLength, Description from Attachment where ParentId = :oldContactId];
		List<Attachment> oaList = new List<Attachment>();
		for (Attachment rs : attachment) {
			Attachment cWhatId = rs.clone(false,true);
			cWhatId.ParentId = newContactId;
			oaList.add(cWhatId);
		}
		if (!oaList.isEmpty()) insert oaList;
		// パートナー SKIP
		// Call information[Call_information__c]
		List<Call_information__c> ctiInfs = [Select Id,Account__c from Call_information__c where Account__c = :oldContactId];
		for (Call_information__c rs : ctiInfs) {
			rs.Account__c = newContactId;
		}
		if (!ctiInfs.isEmpty()) update ctiInfs;
		// 予約関連[請求先]
		List<Lead__c> reqLeads = [select Id, refAccount__c from Lead__c where refAccount__c = :oldContactId];
		for (Lead__c rs : reqLeads) {
			rs.refAccount__c = newContactId;
		}
		if (!reqLeads.isEmpty()) update reqLeads;
		// 予約関連[旅行会社情報]
		List<Lead__c> travLeads = [select Id, SalesOfficeInfoRef__c from Lead__c where SalesOfficeInfoRef__c = :oldContactId];
		for (Lead__c rs : travLeads) {
			rs.SalesOfficeInfoRef__c = newContactId;
		}
		if (!travLeads.isEmpty()) update travLeads;
		// プランのAGT
		List<Plan__c> plans = [select Id, client__c from Plan__c where client__c = :oldContactId];
		for (Plan__c rs : plans) {
			rs.client__c = newContactId;
		}
		if (!plans.isEmpty()) update plans;
		// リアルAGTのAGT
		List<RealAGT__c> realAgts = [select Id, AccountRef__c from RealAGT__c where AccountRef__c = :oldContactId];
		for (RealAGT__c rs : realAgts) {
			rs.AccountRef__c = newContactId;
		}
		if (!realAgts.isEmpty()) update realAgts;
		// 契約[Contract]
		List<Contract> contracts = [select Id, AccountId from Contract where AccountId = :oldContactId];
		for (Contract rs : contracts) {
			rs.AccountId = newContactId;
		}
		if (!contracts.isEmpty()) update contracts;
		// 仕入[Purchase__c][仕入先]
		List<Purchase__c> purchases = [select Id, Purchasesource__c from Purchase__c where Purchasesource__c = :oldContactId];
		for (Purchase__c rs : purchases) {
			rs.Purchasesource__c = newContactId;
		}
		if (!purchases.isEmpty()) update purchases;
		*/
		// 予約見積明細[発注先]
		/* 未使用するため、更新対象外
		List<BookingEstimateItem__c> estimateItems = [select Id, Supplier__c from BookingEstimateItem__c where Supplier__c = :oldContactId];
		for (BookingEstimateItem__c rs : estimateItems) {
			rs.Supplier__c = newContactId;
		}
		if (!estimateItems.isEmpty()) update estimateItems;
		*/
	}
	
	// お客様自身情報をマージする場合、初期化処理を行う
	public void initMergetFieldPage() {
		// merge account id get
		newContactId = ApexPages.currentPage().getParameters().get('nwid');
		if (CommUtils.isBlank(newContactId)) {
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Error!!'));
			return;
		}		
		oldContactId = ApexPages.currentPage().getParameters().get('odid');
		if (CommUtils.isBlank(oldContactId)) {
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Error!!'));
			return;
		}
		reloadXmlInf(UserUtil.CurrentUser.ShopCode__c);
		readContactInf();
		// 2019/07/15 マージ後で自動閉じる機能　by WSQ BEGIN
		initCookieInfo();
		// 2019/07/15 マージ後で自動閉じる機能　by WSQ END
	}
	
	
	// マージ先のお客様情報を維持する
	public Account newContact{get; private set;}
	// マージ元のお客様情報を維持する
	public Account oldContact{get; private set;}
	// 最新お客様情報を取得する
	public void readContactInf() {
		String queryFields = '';
		//String.valueOf(mergeFieldsList).replace('(','').replace(')','');
		for (String fieldkey : mergeFieldsList) queryFields += fieldkey + ',';
		queryFields = queryFields.removeEnd(','); 
		// 2019/09/15 Security Check BY wsq BEGIN
		//String queryString = ' Select ' + queryFields + ' From account where (Id = :newContactId or Id = :oldContactId) ';
		String queryString = ' Select ' + String.escapeSingleQuotes(queryFields) + ' From account where (Id = :newContactId or Id = :oldContactId) ';
		// 2019/09/15 Security Check BY wsq END
		Map<id, Account> contactMaps = new Map<Id, Account>((List<Account>)Database.query(queryString));
		newContact = contactMaps.get(newContactId);
		oldContact = contactMaps.get(oldContactId);
	}
	
	// Merge Default Field Define
	private static final String ConstMergeFields = 'Phone';
	public Map<String, String> editableFieldsMap{get; private set;}
	public List<String> mergeFieldsList{get; private set;}
	private void reloadXmlInf (String pShopCode) {
		// 編集できる項目一覧を取得する
		editableFieldsMap = new Map<String, String>();
		// 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため BEGIN
		/*
		Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Account.fields.getMap();
		for(String fieldName : fieldsMap.keySet()) {
			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			if(sField.isUpdateable()) {
           		editableFieldsMap.put(sField.getLocalName(), sField.getLabel());
			}
		}*/
		Map<String, Schema.DescribeFieldResult> fieldsMap = CommSqlUtils.getAllFieldLst(Account.sObjectType,true);
		for(String fieldName : fieldsMap.keySet()) {
			editableFieldsMap.put(fieldName, fieldsMap.get(fieldName).getLabel());
		}
		// 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため END

		// 画面に既存の予約項目重複処理
		List<String> constFieldsList = ConstMergeFields.deleteWhitespace().split(',');
		Set<String> dupliateSet = new Set<String>(constFieldsList);
		// 店舗情報はＸＭＬから取得する
		/*
		Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
		String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
		List<String> fieldsSplits = strFields.split(',');
		*/
		// 重複する項目は無くす
		// 予約に固定使用する項目APIから無くす
		for (String extendField : editableFieldsMap.keySet()) {
			if (!dupliateSet.contains(extendField) ) constFieldsList.add(extendField);
		}
		mergeFieldsList = new List<String>();
		for (String fieldName : constFieldsList) {
			if (!editableFieldsMap.containsKey(fieldName)) continue;
			mergeFieldsList.add(fieldName);
		}
//System.debug(Logginglevel.INFO, 'mergeFieldsList::' + mergeFieldsList);
	}
	@remoteAction
	global static String mergetContatInfo(String toContactId, String fromContactId, String fromFields, String toFields) {
		// 指定のお客様マージする項目を情報マージする
		try {
			//マージ項目情報を設定されないので、マージ不可
			if (CommUtils.isBlank(fromFields)) return Label.MSG_012_0395;
			String queryString = ' Select ' + fromFields + ' From Account where (Id = :fromContactId) ';
			List<Sobject> fromContacts = Database.query(queryString);
			if (fromContacts.isempty()) {
				//マージ処理エラーが発生しました。マージ元取引先情報を見つかりません。
				return Label.MSG_012_0389;
			}
			Sobject fromContact = fromContacts[0];
			queryString = ' Select ' + toFields + ' From Account where (Id = :toContactId) ';
			List<Sobject> toContacts = Database.query(queryString);
			if (toContacts.isEmpty()) {
				//マージ処理エラーが発生しました。マージ先取引先情報を見つかりません。
				return Label.MSG_012_0390;
			}
			String[] fromFieldsLst = fromFields.split(',');
			String[] toFieldsLst = toFields.split(',');
			Sobject newContact = new Account(Id = toContactId);

			for (Integer i=0;i<fromFieldsLst.size(); i++) {
				String fromKey = fromFieldsLst[i];
				String toKey = toFieldsLst[i];
				newContact.put(toKey, fromContact.get(fromKey));
			}
			update newContact;
		} catch (Exception e) {
			//マージ処理エラーが発生しました。
			String errMsg = Label.MSG_012_0387 + '\n';
			return (errMsg + e.getMessage());
		}
		return '';
	}
/**
*2015-11-18 
*テストクラスAccountMergeに移行する	
	// テストクラス実施
	@isTest(SeeAllData=false)
	static void testMergeListChk() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
		Account ToAccounts = FrAccounts.clone(false,true);
		insert ToAccounts;
		Id toAccountId = ToAccounts.Id;
		Id [] fixedSearchResults= new Id[1];
       	fixedSearchResults[0] = toAccountId;
		Test.setFixedSearchResults(fixedSearchResults);
		// お客様
		Contact contacts = TestCommon.createContact();
		contacts.AccountId = ToAccounts.Id;
		update contacts;
		// 商談
		Opportunity opps = new Opportunity(
			Name = '商談情報' + CommUtils.getRandom(10),
			CloseDate = Date.today(),
			StageName = 'Prospecting',
			AccountId = toAccountId
		);
		insert opps;
		// ケース
		Case newCase = new Case(
			Origin = 'Phone',
			AccountId = toAccountId
		);
		insert newCase;
		// 活動予定
		Event newEvent = new Event(
			Subject = 'Send Letter',
			WhatId = toAccountId ,
			DurationInMinutes = 30 ,
			ActivityDateTime = System.now().addDays(2)
		);
		insert newEvent;
		Task newTask = new Task(
			Subject = 'Send Letter-Task',
			WhatId = toAccountId
		);
		insert newTask;
		// メモ & 添付ファイル
		Note newNote = new Note (
			ParentId = toAccountId,
			Title    = 'NoteTitle'
		);
		insert newNote;
		
		Blob attBlog = Blob.valueOf('AttText Test Content');
		Attachment newAttach = new Attachment(
			ParentId = toAccountId,
			Name = 'TestJsFile',
			ContentType = 'application/x-javascript',
			Body = attBlog
		);
		insert newAttach;
		// Call_information__c
		Call_information__c newCall = new Call_information__c(
			Account__c = toAccountId,
			SNO__c = '0123456789'
		);
		insert newCall;
		// 予約関連[請求先]
		Lead__c reqLead = TestCommon.createBookingLead(Date.today(), null, 1);
		reqLead.refAccount__c = toAccountId;
		update reqLead;
		// 予約関連[旅行会社情報]
		Lead__c travLead = TestCommon.createBookingLead(Date.today(), null, 1);
		travLead.SalesOfficeInfoRef__c = toAccountId;
		update travLead;
		// プランのAGT
		Plan__c plan = TestCommon.createPlan();
		plan.client__c = toAccountId;
		update plan;
		// リアルAGTのAGT
		RealAGT__c agt = new RealAGT__c(
			AccountRef__c = toAccountId,
			AgtMaxRooms__c = 10,
			EndDate__c = Date.today().addDays(10),
			StartDate__c = Date.today()
		);
		insert agt;
		// 契約[Contract]
		Contract newCon = new Contract(
			AccountId = toAccountId,
			StartDate = Date.today(),
			ContractTerm = 3
		);
		insert newCon;
		// 仕入[Purchase__c][仕入先]
		RsvAccount__c rsv = TestCommon.createRsvAccount();
		Purchase__c newPur = new Purchase__c(
			JinyaRevenue__c = rsv.Id,
			Purchasesource__c = toAccountId,
			Denpyoukei__c = 1200000
		);
		insert newPur;
		
		Test.startTest();
		// マージ初期化確認
		ApexPages.currentPage().getParameters().put('Id',FrAccounts.Id);
		ApexPages.StandardController scc = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl = new AccountMerge(scc);
		// 初期化
		ctrl.initAction();
		ctrl.queryConcatInfo();
		List<Account> acc = ctrl.queryRs;
		System.assertEquals(acc.size(), 1, acc);
		// マージ処理を行う
		ctrl.newContactId = FrAccounts.Id;
		ctrl.oldcontactId = ToAccounts.Id;
		// マージ処理実施
		ctrl.mergerRelList();
		Id newId = FrAccounts.Id;
		// 処理結果を確認する
		List<Contact> newContacts = [select id, AccountId from Contact where AccountId = :newId];
		List<Opportunity> newOpps = [select AccountId from Opportunity where AccountId = :newId];
		List<Case> newCases       = [select AccountId from Case where AccountId = :newId];
		List<Event> newEvents     = [select WhatId from Event where WhatId = :newId];
		List<Task> newTasks       = [select WhatId from Task where WhatId = :newId];
		List<Note> newNotse       = [select ParentId from Note where ParentId = :newId];
		List<Attachment> newAtts  = [select ParentId from Attachment where ParentId = :newId];
		List<Call_information__c> newCalls = [Select Id,Account__c from Call_information__c where Account__c = :newId];
		List<Lead__c> newLead1    = [select Id, refAccount__c from Lead__c where refAccount__c = :newId];
		List<Lead__c> newLead2    = [select Id, SalesOfficeInfoRef__c from Lead__c where SalesOfficeInfoRef__c = :newId];
		List<Plan__c> newPlans    = [select Id, client__c from Plan__c where client__c = :newId];
		List<RealAGT__c> newAgts  = [select Id, AccountRef__c from RealAGT__c where AccountRef__c = :newId];
		List<Contract> newContrs  = [select Id, AccountId from Contract where AccountId = :newId];
		List<Purchase__c> newPurs = [select Id, Purchasesource__c from Purchase__c where Purchasesource__c = :newId];
		
		System.assertEquals(newContacts.size(), 1);
		System.assertEquals(newOpps.size(), 1);
		System.assertEquals(newCases.size(), 1);
		System.assertEquals(newEvents.size(), 1);
		System.assertEquals(newTasks.size(), 1);
		System.assertEquals(newNotse.size(), 1);
		System.assertEquals(newAtts.size(), 1);
		System.assertEquals(newCalls.size(), 1);
		
		System.assertEquals(newLead1.size(), 1);
		System.assertEquals(newLead2.size(), 1);
		System.assertEquals(newPlans.size(), 1);
		System.assertEquals(newAgts.size(), 1);
		System.assertEquals(newContrs.size(), 1);
		System.assertEquals(newPurs.size(), 1);
		
		List<Account> delAccs = [select id from Account where Id = :toAccountId];
		System.assert(delAccs.isEmpty());
		Test.stopTest();
	}
	// テストクラス実施
	@isTest(SeeAllData=false)
	static void testMergeFieldChk() {
		// マージ元の取引先情報を作成する
		Account FrAccounts = TestCommon.createNormalAccount();
		// 下記の取引先の関連情報はマージ元(FrAccounts)にコピーする
		Account ToAccounts = FrAccounts.clone(false,true);
		ToAccounts.phone = CommUtils.getRandom(10);
		ToAccounts.fax = CommUtils.getRandom(10);
		insert ToAccounts;
		Test.startTest();
		// マージ初期化確認
		ApexPages.currentPage().getParameters().put('Id',FrAccounts.Id);
		ApexPages.StandardController scc = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl = new AccountMerge(scc);
		// 初期化
		ctrl.initAction();
		ctrl.queryConcatInfo();
		List<Account> acc = ctrl.queryRs;
		
		ApexPages.currentPage().getParameters().put('nwid',FrAccounts.Id);
		ApexPages.currentPage().getParameters().put('odid',ToAccounts.Id);
		
		ApexPages.StandardController scc2 = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl2 = new AccountMerge(scc2);
		ctrl2.initMergetFieldPage();
		
		AccountMerge.mergetContatInfo(FrAccounts.Id, ToAccounts.Id, 'phone,fax','phone,fax');
		ctrl2.readContactInf();
		Account newContact = ctrl2.newContact;
		Account oldContact = ctrl2.oldContact;
		System.assertEquals(newContact.fax, oldContact.fax);
		System.assertEquals(newContact.phone, oldContact.phone);
		
		ApexPages.currentPage().getParameters().put('nwid',null);
		ApexPages.currentPage().getParameters().put('odid',ToAccounts.Id);
		ApexPages.StandardController scc3 = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl3 = new AccountMerge(scc3);
		ctrl3.initMergetFieldPage();
		ApexPages.currentPage().getParameters().put('nwid',FrAccounts.Id);
		ApexPages.currentPage().getParameters().put('odid',null);
		ApexPages.StandardController scc4 = new ApexPages.StandardController(FrAccounts);
		AccountMerge ctrl4 = new AccountMerge(scc4);
		ctrl4.initMergetFieldPage();
	}
	**/
	// 2019/07/15 マージ後で自動閉じる機能　by WSQ BEGIN
	// 定義情報はDBへ格納する
	private void initCookieInfo(){
		// DBから設定情報を取得する
        map<string,string> userConfigMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.AMERAGE, UserUtil.CurrentUser.id, UserUtil.CurrentUser.ShopCode__c);
        autoCloseFlag = false;
        String subkey = UserConfigCompCtrl.AMERAGE_SUBTYPE.AUTOCLOSE.name();
        if ( userConfigMap.containsKey(subkey) ) {
        	String cookieVal = CommUtils.nullToBlank(userConfigMap.get(subkey));
        	autoCloseFlag = Boolean.valueOf(cookieVal);
        }
	}
	@remoteaction
	global static void saveCookieValue(String checkFlag){
		String subkey = UserConfigCompCtrl.AMERAGE_SUBTYPE.AUTOCLOSE.name();
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.AMERAGE, subkey , checkFlag, UserUtil.CurrentUser.id, UserUtil.CurrentUser.ShopCode__c);
	}
	// 2019/07/15 マージ後で自動閉じる機能　by WSQ END
}