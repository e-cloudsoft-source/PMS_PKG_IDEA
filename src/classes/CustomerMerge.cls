/**
* お客様情報マージ機能
* 2014/09/09 お客様情報物理削除機能変更、関連データ移行処理に関して、Futrue→１TRANに纏めて処理
* 2014/09/19 顧客情報マージの関連リスト訂正修正
* 2015/05/22 項目加算モード機能を追加する
* 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため
* 2019/06/15 お客様と関連リスト、複数マージできるように改善
*/
global with sharing class CustomerMerge {
	// マージ先お客様のID情報を格納する
	public Id newContactId{get; set;}
	// マージされるお客様のID（マージ元）
	public Id oldContactId{get; set;}
	// 検索キー[お客様検索情報]
	public String findKey{get; set;}
	// 項目処理方式[JSON化]
	public String fieldEditModeMapJson{get{return JSON.serialize(fieldEditModeMap);}}
	public static String MODE_EDIT_TYPE_ADD{get{return 'ADD';}}	// 加算モード
	public static String MODE_EDIT_TYPE_REP{get{return 'REP';}}	// 上書きモード
	// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH BEGIN
	/** お客様から自定義表示予定の項目リスト */
	public List<String> vFieldsApiLst {get; private set;}	 // カスタム表示する項目のラベル名を定義する<JSONKEY, LABEL>
	public Map<String, String> customLabelMap {get; private set;}	 // カスタム表示する項目のラベル名を定義する<JSONKEY, LABEL>
	private Set<String> queryFieldsSet = new Set<String>();  // 最新的FieldsSet
	// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH END
	// 初期化する
	public CustomerMerge (ApexPages.StandardController ctrl){
		newContactId = ctrl.getId();
	}
	// 重複するお客様情報を検索する
	// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH BEGIN
	private static final String queryFieldsStr = 'Id,Name,AccountId,phone,email,fax,KanaName1__c,KanaName2__c,Katakana__c,Name1__c,MailingCountry, MailingState, MailingCity, MailingStreet';
	// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH END
	private static final String queryWhereStr = ' Where IsDelete__c != true And Id != :newContactId ';
	// 検索結果情報を格納する
	public List<Contact> contacts{get; private set;}
	// 検索条件により、Mergeすお客様情報を検索する
	private Boolean preQueryConcatInfo() {
		if (CommUtils.isBlank(findKey) || (findKey.trim().length() < 2)) {
			//フリーワード検索文字は最低 2 文字指定してください。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0399));
			return false;
		}
		return true;
	}
	public Boolean initHaveErrFlg{get; private set;}
	//2017/11/09 マージ後で自動閉じる機能　by zy BEGIN
	public boolean autoCloseFlag{get; private set;}
	//2017/11/09 マージ後で自動閉じる機能　by zy END
	public void initAction() {
		initHaveErrFlg = false;
		List<Contact> newContact = [select id,name,phone,IsDelete__c from contact where id = :newContactId];
		if (newContact.isEmpty()) {
			//指定しているお客様情報は削除されました。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0400));
			initHaveErrFlg = true;
			return;
		}
		if (newContact[0].IsDelete__c) {
			//指定しているお客様情報は既に論理削除ので、マージ処理ができません。
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0401));
			initHaveErrFlg = true;
			return;
		}
		findKey = newContact[0].Name + ' ' + CommUtils.nullToBlank(newContact[0].phone);
		queryConcatInfo();
	}
	// 画面条件を指定して、検索処理を行う
	public void queryConcatInfo () {
		if (!preQueryConcatInfo()) {
			return;
		}
		findKey = findKey.replace('"','\\"');
		// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH BEGIN
		if(vFieldsApiLst == null) reloadXmlInf(UserUtil.CurrentUser.ShopCode__c);
		String wQueryFieldsStr = '';
		if(!queryFieldsSet.isEmpty()){
			for(String field : queryFieldsSet){
				// xml自定义API
				wQueryFieldsStr += field + ',';
			}
			wQueryFieldsStr = wQueryFieldsStr.removeEnd(',');
		} else wQueryFieldsStr = queryFieldsStr;
		// String pString = 'FIND \''+string.escapeSingleQuotes(findKey)+'\' IN ALL FIELDS RETURNING Contact('+queryFieldsStr+queryWhereStr+')';
		// 2019/09/15 Security Check BY wsq BEGIN
		//String pString = 'FIND \''+string.escapeSingleQuotes(findKey)+'\' IN ALL FIELDS RETURNING Contact('+wQueryFieldsStr+queryWhereStr+')';
		String pString = 'FIND \''+string.escapeSingleQuotes(findKey)+'\' IN ALL FIELDS RETURNING Contact('+string.escapeSingleQuotes(wQueryFieldsStr)+queryWhereStr+')';
		// 2019/09/15 Security Check BY wsq END
		// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH END
		List<List <sObject>> myQuery = search.query(pString);
		contacts = (List<Contact>)myQuery[0];
	}
	
	// 指定にお客様IDの関連リストをマージ先お客様へ入替えする
	// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
	global class MergeResult {
		public MergeResult() {
			message = '';
			nextIds = new List<String>();
		}
		public List<String> nextIds{get;set;}
		public String message{get;set;}
	}
	//public void mergerRelList() {
	// １件つづお客様情報をマージする
	@remoteAction
	global static MergeResult mergerRelList(String newContactId, String[] oldContactIds ) {
		// 処理結果を格納する
		MergeResult mergeRs = new MergeResult();
		String oldContactId = oldContactIds[0];
		for (Integer i = 1; i < oldContactIds.size(); i++) {
			mergeRs.nextIds.add(oldContactIds[i]);
		}
	// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
		// 指定のお客様情報をマージする
		List<Contact> oldContacts = [select id,LastName from contact where id = :oldContactId limit 1 for update ];
		if (oldContacts.isEmpty()) {
			//選択したのマージ元お客様情報を見つかりません。
			// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
			//Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0402));
			//return;
			mergeRs.message = Label.MSG_012_0402;
			return mergeRs;
			// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
		}
		List<Contact> masterContacts = [select id,LastName from contact where id = :newContactId limit 1 for update ];
		if (masterContacts.isEmpty()) {
			//マージ先お客様情報を見つかりません。
			// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
			//Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, Label.MSG_012_0403));
			//return;
			mergeRs.message = Label.MSG_012_0403;
			return mergeRs;
			// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
		}
		Savepoint sp = Database.setSavepoint();
		try {
			// 情報をマージする
//			updateRelData(oldContactId, newContactId);
			// 2017/04/13 Sobject Security Check BEGIN
			if (!CommSecurityUtils.isDeleteable(Contact.getSObjectType())){
				// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
				//return;
				mergeRs.message = 'アクセス権限ありません。';
				return mergeRs;
				// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
			}
			// 2017/04/13 Sobject Security Check END
			Database.MergeResult results = Database.merge(masterContacts[0], oldContactId, true);
			if (!results.isSuccess()) {
				List<Database.Error> errors = results.getErrors();
				// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
				//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errors[0].getMessage()));
				DataBase.rollback(sp);
				//return;
				mergeRs.message = errors[0].getMessage();
				// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
			}
			/* 2014/09/09 お客様情報物理削除機能変更、関連データ移行処理に関して、Futrue→１TRANに纏めて処理
			// お客様情報は論理削除に更新を行う
			// マージ元のお客様情報は論理削除する
			oldContacts[0].IsDelete__c = true;
			oldContacts[0].MergeNewId__c = newContactId;
			String newLastName = '[論理削除済]_' +  oldContacts[0].LastName;
			newLastName = newLastName.left(80);
			oldContacts[0].LastName = newLastName;
			update oldContacts;
			*/
//			delete oldContacts;
		} catch (Exception e) {
			DataBase.rollback(sp);
			// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
			//Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			//return;
			mergeRs.message = e.getMessage();
			// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
		}
		// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ BEGIN
		return mergeRs;
		// 最新情報を取得する
		//queryConcatInfo();
		// 2019/06/15 お客様と関連リスト、複数マージできるように改善 WSQ END
	}
	// マージ先のお客様詳細画面へ遷移する
	public Pagereference gotoBack() {
		Pagereference page = new Pagereference('/' + newContactId);
		return page;
	} 
	/* 2014/09/09 お客様情報物理削除機能変更、関連データ移行処理に関して、Futrue→１TRANに纏めて処理
	@future
	private static void updateRelData (Id oldContactId, Id newContactId) {
	*/
	private void updateRelData (Id oldContactId, Id newContactId) {
		/** Merage API利用するので、下記処理削除
		//Savepoint sp = Database.setSavepoint();
		//try {
		// 予約インデクス
		List<LeadIndex__c> leadIdxs = [select contactRef__c from LeadIndex__c where contactRef__c = :oldContactId];
		for (LeadIndex__c rs : leadIdxs) {
			rs.contactRef__c = newContactId;
		}
		update leadIdxs;
		// 予約[]
		List<Lead__c> leads = [select Relcontact__c From Lead__c where Relcontact__c = :oldContactId];
		for (Lead__c rs : leads) {
			rs.Relcontact__c = newContactId;
		}
		update leads;
		// 予約見積明細[BookingEstimateItem__c]->[発注者]？？
		//List<BookingEstimateItem__c> estItems = [select from BookingEstimateItem__c where ]
		// 会計[AccountAcount__c]
		List<AccountAcount__c> accAcounts = [select relaccount__c from AccountAcount__c where relaccount__c = :oldContactId];
		for (AccountAcount__c rs : accAcounts) {
			rs.relaccount__c = newContactId;
		}
		update accAcounts;
		// 宿泊者名簿[BookingGuest__c]
		List<BookingGuest__c> books = [select ContactRef__c from BookingGuest__c where ContactRef__c = :oldContactId];
		for (BookingGuest__c rs : books) {
			rs.ContactRef__c = newContactId;
		}
		update books;
		// 宿帳
		List<Yadochou__c> yados = [select Field15__c from Yadochou__c where Field15__c = :oldContactId];
		for (Yadochou__c rs : yados) {
			rs.Field15__c = newContactId;
		}
		update yados;
		// 宿帳明細
		List<Guestbookcustomer__c> yadoItems = [select customer__c from Guestbookcustomer__c where customer__c = :oldContactId];
		for (Guestbookcustomer__c rs : yadoItems) {
			rs.customer__c = newContactId;
		}
		update yadoItems;
		// 入金
		List<deposit__c> deps = [select deposit__c from deposit__c where deposit__c = :oldContactId];
		for (deposit__c rs : deps) {
			rs.deposit__c = newContactId;
		}
		update deps;
		// アンケート[Customersurvey__c]【anquete__c】
		List<Customersurvey__c> surveys = [Select Id,anquete__c from Customersurvey__c where anquete__c = :oldContactId];
		for (Customersurvey__c rs : surveys) {
			rs.anquete__c = newContactId;
		}
		update surveys;
		// Call information[Call_information__c]
		List<Call_information__c> ctiInfs = [Select Id,Contact__c from Call_information__c where Contact__c = :oldContactId];
		for (Call_information__c rs : ctiInfs) {
			rs.Contact__c = newContactId;
		}
		update ctiInfs;
		// 住所[AccountAddress__c]
		List<AccountAddress__c> addrs = [Select Id,ContactRef__c from AccountAddress__c where ContactRef__c = :oldContactId];
		for (AccountAddress__c rs : addrs) {
			rs.ContactRef__c = newContactId;
		}
		update addrs;
		// 顧客ランク
		List<CustomerRANK__c> ranks = [Select Id,RelContact__c from CustomerRANK__c where RelContact__c = :oldContactId];
		for (CustomerRANK__c rs : ranks) {
			rs.RelContact__c = newContactId;
		}
		update ranks;
		// 2014/09/26
		// ケース
		List<Case> cases = [select ContactId from Case where ContactId = :oldContactId];
		for (Case rs : cases) {
			rs.ContactId = newContactId;
		}
		update cases;
		// 活動予定
		List<Event> events = [select WhoId from Event where WhoId = :oldContactId And GroupEventType = null];
		for (Event rs : events) {
			rs.WhoId = newContactId;
		}
		update events;
		List<Task> taskoa = [select WhoId from Task where WhoId = :oldContactId];
		for (Task rs : taskoa) {
			rs.WhoId = newContactId;
		}
		update taskoa;
		// メモ & 添付ファイル
		List<Note> sNote = [select ParentId, Title, IsPrivate, Body from Note where ParentId = :oldContactId];
		List<Note> oeList = new List<Note>();
		for (Note rs : sNote) {
			Note cWhatId = rs.clone(false,true);
			cWhatId.ParentId = newContactId;
			oeList.add(cWhatId);
		}
		insert oeList;
		List<Attachment> attachment = [select ParentId, Name, IsPrivate, ContentType, Body, BodyLength, Description from Attachment where ParentId = :oldContactId];
		List<Attachment> oaList = new List<Attachment>();
		for (Attachment rs : attachment) {
			Attachment cWhatId = rs.clone(false,true);
			cWhatId.ParentId = newContactId;
			oaList.add(cWhatId);
		}
		insert oaList;
		// 住所
		List<AccountAddress__c> nAccountAddress = [select ContactRef__c from AccountAddress__c where ContactRef__c = :oldContactId];
		for (AccountAddress__c rs : nAccountAddress) {
			rs.ContactRef__c = newContactId;
		}
		update nAccountAddress;
		// 商談
		List<OpportunityContactRole> nOpportunityContactRole = [select ContactId from OpportunityContactRole where ContactId = :oldContactId];
		for (OpportunityContactRole rs : nOpportunityContactRole) {
			rs.ContactId = newContactId;
		}
		update nOpportunityContactRole;
		*/
		/*
		} catch (Exception e) {
			DataBase.rollback(sp);
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return;
		}*/
	}
	
	// お客様自身情報をマージする場合、初期化処理を行う
	public void initMergetFieldPage() {
		// merge contact id get
		// 2020/07/30 マージのエラー修正 BY zyz BEGIN
		// newContactId = ApexPages.currentPage().getParameters().get('nwid');
		String newContactIdStr = ApexPages.currentPage().getParameters().get('nwid');
		if (CommUtils.isBlank(newContactIdStr)) {
		// 2020/07/30 マージのエラー修正 BY zyz END
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Error!!'));
			return;
		}		
		// 2020/07/30 マージのエラー修正 BY zyz BEGIN	
		newContactId = ID.valueOf(newContactIdStr);
		// oldContactId = ApexPages.currentPage().getParameters().get('odid');
		String oldContactIdStr = ApexPages.currentPage().getParameters().get('odid');
		if (CommUtils.isBlank(oldContactIdStr)) {
		// 2020/07/30 マージのエラー修正 BY zyz END
			Apexpages.addMessage(new Apexpages.Message(ApexPages.severity.ERROR, 'Error!!'));
			return;
		}
		// 2020/07/30 マージのエラー修正 BY zyz BEGIN	
		oldContactId = ID.valueOf(oldContactIdStr);
		// 2020/07/30 マージのエラー修正 BY zyz END
		reloadXmlInf(UserUtil.CurrentUser.ShopCode__c);
		readContactInf();
		//2017/11/09 マージ後で自動閉じる機能　by zy BEGIN
		initCookieInfo();
		//2017/11/09 マージ後で自動閉じる機能　by zy END
	}
	
	
	// マージ先のお客様情報を維持する
	public Contact newContact{get; private set;}
	// マージ元のお客様情報を維持する
	public Contact oldContact{get; private set;}
	// 最新お客様情報を取得する
	public void readContactInf() {
		String queryFields = '';
		//String.valueOf(mergeFieldsList).replace('(','').replace(')','');
		for (String fieldkey : mergeFieldsList) queryFields += fieldkey + ',';
		queryFields = queryFields.removeEnd(','); 
		// 2019/09/15 Security Check BY wsq BEGIN
		//String queryString = ' Select ' + queryFields + ' From contact where (Id = :newContactId or Id = :oldContactId) ';
		String queryString = ' Select ' + String.escapeSingleQuotes(queryFields) + ' From contact where (Id = :newContactId or Id = :oldContactId) ';
		// 2019/09/15 Security Check BY wsq END
		Map<id, Contact> contactMaps = new Map<Id, Contact>((List<Contact>)Database.query(queryString));
		newContact = contactMaps.get(newContactId);
		oldContact = contactMaps.get(oldContactId);
	}
	
	// Merge Default Field Define
	private static final String ConstMergeFields = 'LastName,FirstName,Katakana__c,KanaName1__c,Name1__c,Phone,AccountId';
	public Map<String, String> editableFieldsMap{get; private set;}
	public List<String> mergeFieldsList{get; private set;}
	public Map<String, String> fieldEditModeMap{get; private set;}
	private void reloadXmlInf (String pShopCode) {
   		// 拡張予約項目を定義する
   		/* すべて可変の項目は画面に表示する
    	List<Document> sr = [select body, name from Document where DeveloperName = 'ContactInfoMergeFields'];
    	if (sr.isEmpty()) return;
    	Blob xmlBody = sr[0].Body;
    	String strXmlBody = xmlBody.toString();
//System.debug(LoggingLevel.INFO, 'strXmlBody:::'+strXmlBody);	
    	Dom.XmlNode targetNode, firstNode = null;
		Dom.Document doc = new Dom.Document();
		doc.load(strXmlBody);
		Dom.XMLNode root = doc.getRootElement();
		for(Dom.XMLNode shop : root.getChildElements()) {
			// 各店舗情報はＸＭＬから取得する
			Dom.XmlNode shopcode =  shop.getChildElement('SHOPCODE', null);
			// 店舗コードを取得する
			String strShopCode = CommUtils.nullToBlank(shopcode.getText());
			if (firstNode == null) firstNode = shop;
			// ログインユーザの店舗コードと一致する場合
			if (strShopCode == pShopCode) {
				targetNode = shop;
				break;
			}
		}
		// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
		targetNode = targetNode == null ? firstNode : targetNode;
		if (targetNode == null) return;
		*/
		// 編集できる項目一覧を取得する
		editableFieldsMap = new Map<String, String>();
		// 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため BEGIN
		/*
		Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Contact.fields.getMap();
		for(String fieldName : fieldsMap.keySet()) {
			Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
			if(sField.isUpdateable()) {
           		editableFieldsMap.put(sField.getLocalName(), sField.getLabel());
			}
		}*/
		Map<String, Schema.DescribeFieldResult> fieldsMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,true);
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
		// 2014/05/25 加算モード項目リストを取得する
		Dom.XmlNode shopElement =  CommXmlUtils.parseXmlDoc('ContactInfoMergeFields', pShopCode);
		fieldEditModeMap = new Map<String, String>();	// 項目処理種別モード
		
		for(Dom.XmlNode modeNode : shopElement.getChildElements()){
			if(modeNode.getName() ==  'MODE'){
				Dom.XmlNode typeNode = modeNode.getChildElement('TYPE', null);
				String typeStr = typeNode.getText();
				// 加算項目の場合
				if(typeStr == MODE_EDIT_TYPE_ADD){
					Dom.XmlNode fieldsNode = modeNode.getChildElement('FIELDS', null);
					for(Dom.XmlNode fieldNode : fieldsNode.getChildElements()){
						String fieldName = fieldNode.getText();
						fieldEditModeMap.put(fieldName, typeStr);
					}
				}
			}
		}
		// XML定義以外の項目に対して、初期化する
		for (String fieldName : mergeFieldsList) {
			if (fieldEditModeMap.containsKey(fieldName)) continue;
			fieldEditModeMap.put(fieldName, MODE_EDIT_TYPE_REP);
		}
		// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH BEGIN
		vFieldsApiLst = new List<String>();
		customLabelMap = new Map<String, String>();
		// 店舗情報はＸＭＬから取得する
		Dom.XmlNode viewListFields =  shopElement.getChildElement('VIEWLISTFIELDS', null);
		if(viewListFields != null){
			// 默认字段
			for(String field : queryFieldsStr.split(',')){
				queryFieldsSet.add(CommUtils.nullToBlank(field).toLowerCase());
			}
			String viewFieldsStr = CommUtils.nullToBlank(viewListFields.getText()).deleteWhitespace();
			// カスタム表示用項目を初期化する
			List<String> vFieldsSplits = CommUtils.isBlank(viewFieldsStr) ? new List<String>() : viewFieldsStr.split(',');
			Set<String> otheraddressSet = new Set<String>{'othercountry','otherstate','othercity','otherstreet'};
			// XMLに定義された表示項目リスト取得、処理を行う
			for (String item : vFieldsSplits) {
				String[] keySplits = item.split(':');
				if (keySplits.size() != 2) {
					//表示項目書式の設定が不正です[API名:項目ラベル]
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				      Label.MSG_041_0031));
				    break;
				}
				String key = keySplits[0].toLowerCase();
				String lab =  keySplits[1];
				if(key == 'otheraddress') queryFieldsSet.addAll(otheraddressSet);
				else if(key != 'mailingaddress') queryFieldsSet.add(key);
				if(!customLabelMap.containsKey(key)){
					vFieldsApiLst.add(key);
					// 表示ラベルを定義する
					customLabelMap.put(key, lab);
				}
			}
		}
		// 2017/10/31 検索結果一覧画面に表示する項目はカスタマイズ by WGCH END
	}
	@remoteAction
	global static String mergetContatInfo(String toContactId, String fromContactId, String fromFields, String toFields) {
		return '';
	}	
	@remoteAction
	global static String mergetContatInfo2(String toContactId, String fromContactId, String fromFields, String toFields, String fileModeTypes) {
		// 指定のお客様マージする項目を情報マージする
		try {
			//マージ項目情報を設定されないので、マージ不可
			if (CommUtils.isBlank(fromFields)) return Label.MSG_012_0404;
			String queryString = ' Select ' + fromFields + ' From contact where (Id = :fromContactId) ';
			List<Sobject> fromContacts = Database.query(queryString);
			if (fromContacts.isEmpty()) {
				//マージ処理エラーが発生しました。マージ元お客様情報を見つかりません。
				return Label.MSG_012_0409;
			}
			Sobject fromContact = fromContacts[0];
			queryString = ' Select ' + toFields + ' From contact where (Id = :toContactId) ';
			List<Sobject> toContacts = Database.query(queryString);
			if (toContacts.isEmpty()) {
				//マージ処理エラーが発生しました。マージ先お客様情報を見つかりません。
				return Label.MSG_012_0388;
			}
			Sobject toContact = toContacts[0];
			String[] fromFieldsLst = fromFields.split(',');
			String[] toFieldsLst = toFields.split(',');
			String[] modeTypeLst = fileModeTypes.split(',');
			Sobject newContact = new Contact(Id = toContactId);
			//2016/06/20 string add 機能追加　by zy BEGIN
			Map<String, Schema.DescribeFieldResult> fieldTypeMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,true);
			//2016/06/20 string add 機能追加　by zy END
			for (Integer i=0;i<fromFieldsLst.size(); i++) {
				String fromKey = fromFieldsLst[i];
				String toKey = toFieldsLst[i];
				String modeType = modeTypeLst[i];
				if (modeType == MODE_EDIT_TYPE_ADD) {
					//2016/06/20 string add 機能追加　by zy BEGIN
					// 項目タイプを取得する
					Schema.DescribeFieldResult fd = fieldTypeMap.get(toKey);
					if (fd == null) continue;
					Schema.DisplayType fieldType = fd.getType();
					if(fieldType == Schema.DisplayType.Integer ||
			            fieldType == Schema.DisplayType.Double ||
			            fieldType == Schema.DisplayType.Percent ||
			            fieldType == Schema.DisplayType.Currency ) {
						// 加算
						newContact.put(toKey, 	CommUtils.nullToZero(fromContact.get(fromKey)) + 
												CommUtils.nullToZero(toContact.get(toKey)) );
			        }
			        // 文字列連携を行う
			        else {
			        	integer maxLen = fd.getLength();
			        	String midStr = ((fieldType == Schema.DisplayType.TextArea) ? (fd.isHtmlFormatted() ? '<br/>' : '\n') : '');
			        	String writeStr = 	CommUtils.nullToblank(toContact.get(toKey)) + 
			        						midStr +
			        						CommUtils.nullToblank(fromContact.get(fromKey));
			        	// 連結
			        	writeStr = writeStr.left(maxLen);
						newContact.put(toKey, 	writeStr );	
			        }
					//2016/06/20 string add 機能追加　by zy END
				} else {
					// 上書き
					newContact.put(toKey, fromContact.get(fromKey));
				}
			}
			// 2016/05/27 お客様重複管理対応 BEGIN
			//update newContact;
    		Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.AllowSave = true;
			dml.optAllOrNone = true;
			Database.SaveResult sr2 = Database.update(newContact, dml);
			// 2016/05/27 お客様重複管理対応 END
		} catch (Exception e) {
			//マージ処理エラーが発生しました。
			String errMsg = Label.MSG_012_0410 + '\n';
			return (errMsg + e.getMessage());
		}
		return '';
	}
/**
*2015-11-18 
*テストクラスCustomerMergeTestに移行する 
	@isTest(SeeAllData=false)
	static void testMergeListChk() {
		Contact newC = TestCommon.createContact();
		Contact oldC = TestCommon.createContact();
		oldC.LastName = 'MergetName';
		oldC.FirstName = 'OK';
		newC.LastName = oldC.LastName;
		newC.FirstName = oldC.FirstName;
		oldC.Phone = '03-1111-2222';
		newC.Phone = oldC.Phone;
		update newC;
		update oldC;
		List<Id> idLst = new List<Id>();
		idLst.add(newC.Id);
		idLst.add(oldC.Id);
		Test.setFixedSearchResults(idLst);
		ApexPages.StandardController scc = new ApexPages.StandardController(newC);
		CustomerMerge mergeCtrl = new CustomerMerge(scc);
		mergeCtrl.initAction();
		// 検索結果確認する
		List<Contact> contacts = mergeCtrl.contacts;
		System.assertEquals(contacts.size(), 1);
		mergeCtrl.findKey = oldC.LastName;
		mergeCtrl.queryConcatInfo();
		Test.startTest();
		mergeCtrl.oldContactId = oldC.Id;
		mergeCtrl.newContactId = newC.Id;
		mergeCtrl.mergerRelList();
		
		Test.stopTest();
		List<Contact> mergeOld = [select isDelete__c,MergeNewId__c from contact where id = :oldC.Id];
		
		//System.assert(mergeOld.isDelete__c);
		//System.assertEquals(mergeOld.MergeNewId__c, newC.Id);

		System.assert(mergeOld.isEmpty());
		mergeCtrl.findKey = '1';
		mergeCtrl.queryConcatInfo();
		
		
		System.assert(ApexPages.hasMessages(ApexPages.Severity.Error));
		mergeCtrl.gotoBack();
	}

	@isTest(SeeAllData=false)
	static void testMergetContatInfo() {

		List<Document> sr = [select body, name from Document where DeveloperName = 'ContactInfoMergeFields'];
		
		String configXml = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><MODE><TYPE>ADD</TYPE><FIELDS><FIELD>Usage_Charge__c</FIELD><FIELD>Usage_Count__c</FIELD></FIELDS></MODE></SHOP></root>';
		if (sr.isEmpty()) {
			Document newDoc = new Document(
				Name = 'ContactInfoMergeFields',
				DeveloperName = 'ContactInfoMergeFields',
				body = Blob.valueOf(configXml),
				FolderId = UserInfo.getUserId()
			);
			insert newDoc;
 		} else {
			sr[0].Body = Blob.valueOf(configXml);
			update sr;
 		}
		
		Contact newC = TestCommon.createContact();
		Contact oldC = TestCommon.createContact();
		newC.Memo1__c = 'M11_'+CommUtils.getRandom(10);
		newC.Memo2__c = 'M12_'+CommUtils.getRandom(10);
		newC.Memo3__c = 'M13_'+CommUtils.getRandom(10);
		newC.Memo4__c = 'M14_'+CommUtils.getRandom(10);
		newC.Memo5__c = 'M15_'+CommUtils.getRandom(10);
		newC.Memo6__c = 'M16_'+CommUtils.getRandom(10);
		oldC.Memo1__c = 'M21_'+CommUtils.getRandom(10);
		oldC.Memo2__c = 'M22_'+CommUtils.getRandom(10);
		oldC.Memo3__c = 'M23_'+CommUtils.getRandom(10);
		oldC.Memo4__c = 'M24_'+CommUtils.getRandom(10);
		oldC.Memo5__c = 'M25_'+CommUtils.getRandom(10);
		oldC.Memo6__c = 'M26_'+CommUtils.getRandom(10);
		update newC;
		update oldC;
		
		Test.startTest();
		ApexPages.currentPage().getParameters().put('nwid',newC.Id);
		ApexPages.currentPage().getParameters().put('odid',oldC.Id);
		ApexPages.StandardController ctrl = new ApexPages.StandardController (newC);
		CustomerMerge mergeCtrl = new CustomerMerge(ctrl);
		mergeCtrl.initMergetFieldPage();
		
		string mergeFields = 'Memo1__c,Memo2__c,Memo3__c,Memo4__c,Memo5__c';
		String constqueryFields = 'LastName,FirstName,Katakana__c,KanaName1__c,Name1__c,Phone';
		String modeTypes='REP,REP,REP,REP,REP,REP,REP,REP,REP,REP,REP';//上書き
		String rs = CustomerMerge.mergetContatInfo2(mergeCtrl.newContactId, mergeCtrl.oldContactId, constqueryFields + ',' +mergeFields, constqueryFields + ',' +mergeFields, modeTypes);
		System.assert(String.isEmpty(rs));
		Id newId = newC.Id;
		Contact reNew = Database.query('Select ' + constqueryFields + ',' +mergeFields + ' From Contact Where id = :newId');
		System.assertEquals(reNew.LastName, oldC.LastName);
		System.assertEquals(reNew.FirstName, oldC.FirstName);
		System.assertEquals(reNew.Katakana__c, oldC.Katakana__c);
		System.assertEquals(reNew.KanaName1__c, oldC.KanaName1__c);
		System.assertEquals(reNew.Name1__c, oldC.Name1__c);
		System.assertEquals(reNew.Phone, oldC.Phone);
		
		System.assertEquals(reNew.Memo1__c, oldC.Memo1__c);
		System.assertEquals(reNew.Memo2__c, oldC.Memo2__c);
		System.assertEquals(reNew.Memo3__c, oldC.Memo3__c);
		System.assertEquals(reNew.Memo4__c, oldC.Memo4__c);
		System.assertEquals(reNew.Memo5__c, oldC.Memo5__c);
		//System.assertNotEquals(reNew.Memo6__c, oldC.Memo6__c);
	}
	@isTest(SeeAllData=false)
	static void testMergetContatInfo_3() {
		Contact newC = TestCommon.createContact();
		delete newC;
		ApexPages.StandardController scc = new ApexPages.StandardController(newC);
		CustomerMerge mergeCtrl = new CustomerMerge(scc);
		mergeCtrl.initAction();
		System.assert(mergeCtrl.initHaveErrFlg);
	}
*/
	//2017/11/09 マージ後で自動閉じる機能　by zy BEGIN
	// 定義情報はDBへ格納する
	private void initCookieInfo(){
		// DBから設定情報を取得する
        map<string,string> userConfigMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.CMERAGE, UserUtil.CurrentUser.id, UserUtil.CurrentUser.ShopCode__c);
        autoCloseFlag = false;
        String subkey = UserConfigCompCtrl.CMERAGE_SUBTYPE.AUTOCLOSE.name();
        if ( userConfigMap.containsKey(subkey) ) {
        	String cookieVal = CommUtils.nullToBlank(userConfigMap.get(subkey));
        	autoCloseFlag = Boolean.valueOf(cookieVal);
        }
	}
	@remoteaction
	global static void saveCookieValue(String checkFlag){
		String subkey = UserConfigCompCtrl.CMERAGE_SUBTYPE.AUTOCLOSE.name();
		UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.CMERAGE, subkey , checkFlag, UserUtil.CurrentUser.id, UserUtil.CurrentUser.ShopCode__c);
	}
	//2017/11/09 マージ後で自動閉じる機能　by zy END
}