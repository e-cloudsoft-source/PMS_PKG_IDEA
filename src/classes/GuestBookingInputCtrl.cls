/**
* 宿帳情報を登録する
* 2016/09/26 宿帳情報を入力機能
* 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる
* 2017/03/22 お客様項目をカスタムできるように改善対応
* 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応
* 2018/10/16 宿帳明細入力欄自動作成不要
* 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更
* 2019/10/30 レジカード8のカスタマイズ機能の改善
*/
global with sharing class GuestBookingInputCtrl extends CommBaseCtrl{
    private static final String CONST_STAYPERSONS_ADULTS = '$_STAYPERSON_$'+ Label.CONST_008_0117 +'（'+ Label.CONST_008_0118 +'$_MANS_$ '+ Label.CONST_008_0119 +'$_FEMALE_$$_CHILDS_$）';
    private static final String CONST_STAYPERSONS_CHILDS = Label.CONST_008_0120 +'$_CHILDREN_$'+ Label.CONST_008_0117 +'（A:$_CHILDA_$, B:$_CHILDB_$, C:$_CHILDC_$, D:$_CHILDD_$$_CHILDE_$$_CHILDF_$）';
	// Salesforce Header表示・非表示制御フラグ
	public boolean isShowHeader{get{return !isIncludeMode;}}
	private string leadIndexId{get;private set;}
	//private string gYadoId{get; private set;}
	private Boolean isIncludeMode{get;private set;}
	private ApexPages.StandardController ctrl;
    // 画面予約インデックス選択機能
    public String edtiContactName{get; private set;}
    public Lead__c inputLead{get; private set;}
    // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN
    public String shopCodeStr{get; private set;}
    // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
    public String autoComLeadNoFilter{get{return ' StatusLst__c != \'' + CommUtils.escStr(CommConst.LEAD_ST_CANCEL) + '\' And  ParentLeadIndxRef__c = null ';}}
    // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
    // 宿帳空欄でも明細作成フラグ
    private static final Boolean contactNullCanInsFlg = CommDefine__c.getOrgDefaults().CashRegNullContactCanInsFlg__c;
    // 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
    // 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz BEGIN
    private static final String LEAD_NAME_PREFIX = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
    // 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz END
    // 2018/10/16 宿帳明細入力欄自動作成不要 WSQ BEGIN
    // 宿帳明細入力欄自動作成不要フラグ
    private static final Boolean autoCreateBlankRowFlg = CommDefine__c.getOrgDefaults().CashRegNoCreateBlankRowFlg__c;
    // 2018/10/16 宿帳明細入力欄自動作成不要 WSQ END
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
    public static Boolean RespectFlg{get{return CommConst.RESPECT_ISSHOW_FLG;}}
    // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz BEGIN
    public Boolean CashLogoFlg{get{return CommConst.APPOTION_CARREGISTER_LOGO_FLG;}}
    // 2020/02/29 レジカードのロゴを出力した部屋の「店舗情報」対応 BY zyz END
	public GuestBookingInputCtrl(ApexPages.StandardController controller) {
		ctrl = controller;//;gYadoId = ((Yadochou__c)controller.getRecord()).Id;
	}
    public void init() {
    	map<string,string> parMap = ApexPages.currentPage().getParameters();
    	isIncludeMode = parMap.containsKey('frame');//別のページに含めているがどうか
    	leadIndexId = parMap.get('pid');//予約インデックスID
		inputLead = new Lead__c();
		if (CommUtils.isBlank(leadIndexId)) {
			Yadochou__c pYado = (Yadochou__c)ctrl.getRecord();
			if (!CommUtils.isBlank(pYado.Id)) {
		    	// 予約情報が無ければ、エラーを画面へ戻る
		    	// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN 
		    	// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
				// List<Yadochou__c> currYado = [Select Field1__r.LeadIndexRef__r.ContactNameCal__c,Field1__c,Field1__r.LeadIndexRef__c,LeadIndexId__c,ShopCodeCal__c From Yadochou__c where Id = :pYado.Id And Field1__c != null And Field1__r.LeadIndexRef__c != null];
				List<Yadochou__c> currYado = [Select Field1__r.LeadIndexRef__r.ContactNameCal__c,Field1__c,Field1__r.LeadIndexRef__c,LeadIndexId__c,ShopCodeCal__c,RespectLstCal__c From Yadochou__c where Id = :pYado.Id And Field1__c != null And Field1__r.LeadIndexRef__c != null];
				// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
				// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
				if (currYado.isEmpty()) {
					// TODO
				} else {
					leadIndexId = currYado[0].Field1__r.LeadIndexRef__c;
					// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN 
					shopCodeStr = currYado[0].ShopCodeCal__c;
					// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END 
					//edtiContactName = CommUtils.nullToBlank(currYado[0].Field1__r.LeadIndexRef__r.ContactNameCal__c);
				}
			} 
			// 予約IDが引き渡し場合
			else if (!CommUtils.isBlank(pYado.Field1__c)) {
				// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN 
				List<Lead__c> leads = [select id, leadIndexRef__c,ShopCodeCal__c from Lead__c where id = :pYado.Field1__c];
				// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END 
				if (!leads.isEmpty()) leadIndexId = leads[0].leadIndexRef__c;
				// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN 
				shopCodeStr = leads[0].ShopCodeCal__c;
				// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END 
			}
		}
		if (!CommUtils.isBlank(leadIndexId)) {
			List<LeadIndex__c> existLeadIndexs = [select id,ContactNameCal__c from LeadIndex__c where id = :leadIndexId];
			if (existLeadIndexs.isEmpty()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '有効な予約番号を入力してください。'));
				return;
			} else {
				edtiContactName = CommUtils.nullToBlank(existLeadIndexs[0].ContactNameCal__c);
			}
			inputLead.LeadIndexRef__c = leadIndexId;
			// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN 
			List<Yadochou__c> currYado = [Select Field1__r.LeadIndexRef__c,LeadIndexId__c,ShopCodeCal__c From Yadochou__c where Field1__r.LeadIndexRef__c = :leadIndexId];
			if (!currYado.isEmpty()) shopCodeStr = currYado[0].ShopCodeCal__c;
			// 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
		}
		// 2017/03/22 お客様項目をカスタムできるように改善対応 BEGIN by wx
		parseFieldsXml();
		// 2017/03/22 お客様項目をカスタムできるように改善対応 END by wx
		queryExistInfo();
	}
	// 2017/03/22 お客様項目をカスタムできるように改善対応 BEGIN by wx
	// -------------------------------------------
	// 表示する項目情報を取得、格納を行う
	// -------------------------------------------
	private static final List<String> apiDefaultLst = new List<String>{'Katakana__c', 'Phone', 'Email', 'gender__c'};
	private static final List<String> refreshContactApiLst = new List<String>{'KanaName1__c','Katakana__c','Phone','Email','CompanyNameCal__c','gender__c','Description'};
	public ContactXmlDef parseItem{get;private set;}
	public class ContactXmlDef{
		public ContactXmlDef(){
			// 初期化
			inputLst = new list<ContactField>();
		}
		public String getDateTimeFormatStr() {
			return CommBaseCtrl.getDateTimeFormat();
		}
		public String getDateFormatStr() {
			return CommBaseCtrl.getDateFormat();
		}
		public void addField(ContactField field) {
			if (Commutils.isBlank(field.api)) return;
			inputLst.add(field);
		}
		// XML定義情報を格納する
		public List<ContactField> inputLst{get;private set;}
		public String getYadoQuery() {
			String query = ',Field15__r.Name';
			for (ContactField field : inputLst) {
				query += ',Field15__r.'+field.api;
			}
			return query;
		}
		public String getYadoSubQuery() {
			String query = ',customer__r.Name';
			for (ContactField field : inputLst) {
				query += ',customer__r.'+field.api;
			}
			return query;
		}
		// お客様情報を取得する
		public String refreshContactSql{get;private set;}
		public void setRefreshContactField() {
			refreshContactSql = '';
			// 拡張のAPI項目は一括検索の項目になかった場合、検索リストに追加する
			set<String> dupKeySet = new set<String>();
			// 2017/04/12 不具合改修 自動表示項目内容は重複処理不具合改修 BEGIN
			for (ContactField field : inputLst) {
				dupKeySet.add(field.api);
				refreshContactSql += field.api+',';
			}
			for (String api : refreshContactApiLst) {
				//api = api.toLowerCase();
				if (dupKeySet.contains(api)) continue;
				refreshContactSql +=api+',';
			}
			// 2017/04/12 不具合改修 自動表示項目内容は重複処理不具合改修 END
			refreshContactSql.removeEnd(',');
		}
		public String inputFieldJson{get{
			List<String> fields = new List<String>();
			for (ContactField field : inputLst) {
				fields.add(field.api);
			}
			return JSON.serialize(fields);
		}}
	}
	public class ContactField {
		public ContactField(String pLab, String pApi, DisplayType dtype) {
			label = pLab;
			api = pApi;
			dataType = '';
			style='';
			if (dtype != null) {
				if(dtype == DisplayType.Date){
					dataType = 'Date';
				} else if(dtype == DisplayType.DateTime) {
					dataType = 'DateTime';
				} else if(dtype == DisplayType.textarea){ 
					dataType = 'TextArea';
				} else if(dtype == DisplayType.Boolean){ 
					dataType = 'Boolean';
				}
			}
		}
		public String label{get;set;}
		public String api{get;set;}
		public String dataType{get;set;}
		public String style{get;set;}
	}
	// カスタム定義情報を取得する					
	public void parseFieldsXml() {
		try{
			// XML定義情報を格納する
			parseItem = new ContactXmlDef();
			// 初期化項目定義情報
			List<String> apiFields = apiDefaultLst;
			// 全て編集可能項目リスト情報を取得する
			Map<String, Schema.DescribeFieldResult> contactDefMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false);
			map<string,ContactField> fieldDefMap = new map<string, ContactField>();
			fieldDefMap.put('Name', new ContactField(null,'Name',null));
			// XML定義情報を取得する
			String docName = 'CashRegisterCardPdfConfig';
			String shopCode =  '';
			Dom.XmlNode shopRoot = CommXmlUtils.parseXmlDoc(docName, shopCode);
			// 宿帳UIカスタム項目情報を取得する
			Dom.XmlNode optionsField = shopRoot.getChildElement('YADOTYO_INPUT_UI', null);
			if(OptionsField != null) {
				// 項目API定義情報
				Dom.XmlNode fieldNode = optionsField.getChildElement('FIELDS', null);
				if(fieldNode != null) {
					String apiFieldsStr = CommUtils.nullToBlank(fieldNode.getText()).deleteWhitespace();
					// 过滤重复 定义API 
					if (!CommUtils.isBlank(apiFieldsStr)) apiFields = apiFieldsStr.split(',');
				}
			}
			for (String item : apiFields) {
				// 空白は対象外
				if(CommUtils.isBlank(item)) continue;
				String[] keySplits = item.split(':');
				if(CommUtils.isBlank(keySplits[0])) continue;
				if(keySplits[0].toLowerCase().contains('name')) continue;
				// api转成小写
				//String apiItem = keySplits[0].toLowerCase();
				String apiItem = CommUtils.nullToBlank(keySplits[0]);
				//判断是占位符号或者页面原有项目中不包含此字段的字段
				if(!contactDefMaps.containsKey(apiItem)) continue;
				// XMLに重複定義の場合、次の定義に移動する
				if(fieldDefMap.containsKey(apiItem)) continue;
				// 表示ラベルを定義する
				Schema.DescribeFieldResult dr = contactDefMaps.get(apiItem);
				ContactField field = new ContactField(dr.getLabel(), apiItem, dr.getType());
				if (keySplits.size() > 1 && !CommUtils.isBlank(field.label)) field.label = keySplits[1];
				parseItem.addField(field);
				// API関連定義情報を格納する
				fieldDefMap.put(apiItem, field);
			}

			if (optionsField != null) {
				// 項目幅のサイズを定義する
				Dom.XmlNode columnFields =  optionsField.getChildElement('COLNUMSIZE', null);
				if (columnFields != null) {
					String columnSize = CommUtils.nullToBlank(columnFields.getText()).deleteWhitespace();
					for (String col : columnSize.split(',')){
						if(CommUtils.isBlank(col)) continue;
						String[] colArr = col.split(':');
						if (colArr.size() < 2) continue;
						String api = CommUtils.nullToBlank(colArr[0]);
						String style = CommUtils.nullToBlank(colArr[1]);
						if (CommUtils.isBlank(api) || CommUtils.isBlank(style)) continue;
						if (!fieldDefMap.containsKey(api)) continue;
						ContactField field = fieldDefMap.get(api);
						field.style = 'width:'+style;
					}
				}
			}
			// 定義の情報により、お客様AutoComplete抽出項目を設定する
			parseItem.setRefreshContactField();
		} catch (Exception e) {}
	}
	// 2017/03/22 お客様項目をカスタムできるように改善対応 END by wx  	
    public void confirm() {
		// 
		if (CommUtils.isBlank(inputLead.LeadIndexRef__c)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '有効な予約番号を入力してください。'));
			return;
		}
    	// 指定のIDが存在チェックを行う
    	leadIndexId = inputLead.LeadIndexRef__c;
    	// 予約情報を検索して、画面格納する
    	LeadIndex__c leadIndex = [select ContactNameCal__c from LeadIndex__c where id = :leadIndexId];
    	edtiContactName = CommUtils.nullToBlank(leadIndex.ContactNameCal__c);
    	queryExistInfo();
    }

    // 明細行追加
    public void addNewLine() {
    	//roomGuestList[]
    	String roomIndex = ApexPages.currentPage().getParameters().get('roomIndex');
//System.debug(loggingLevel.info, 'roomIndex:::'+roomIndex);
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		rowSorting(true);
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
    	Integer intIndex = CommUtils.nullToIntZero(roomIndex);
    	OneRoomInfo yadoInfo = roomGuestList[intIndex];
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		// yadoInfo.guestList.add(new OneRoomGuestInfo(yadoInfo.guestList.size()));
		yadoInfo.guestList.add(new OneRoomGuestInfo(yadoInfo.guestList.size(),yadoInfo.yado.Field1__c));
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
	}
	// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
	// 明細行排序
    public void rowSorting(Boolean isShowMemoColFlg) {
    	// 页面当前显示的顺序, contactIdAllLst:为每个Table里按顺序每一行的Id 
		try{
			//rowsNo
			Map<Integer, OneRoomGuestInfo> locSortMap = new Map<Integer, OneRoomGuestInfo>();
			Map<String, List<Integer>> leadGroupRowNoMap = new map<String, List<Integer>>();
			for (OneRoomInfo item : roomGuestList) {
				// 画面表示順により、ソートを行う
				for ( OneRoomGuestInfo it : item.guestList) {
					Integer rowNo = CommUtils.nullToIntZero(it.rowsNo);
					Id leadId = it.leadId;
					locSortMap.put(rowNo,it);
					if (!leadGroupRowNoMap.containsKey(leadId)) leadGroupRowNoMap.put(leadId, new List<Integer>());
					leadGroupRowNoMap.get(leadId).add(rowNo);
				}
			}
			for (OneRoomInfo item : roomGuestList) {
				item.guestList = new List<OneRoomGuestInfo>();
				Id leadId = item.yado.Field1__c;
				if (!leadGroupRowNoMap.containsKey(leadId))	continue;
				List<Integer> rowNoLst = leadGroupRowNoMap.get(leadId);
				rowNoLst.sort();
				for (Integer rowNo : rowNoLst) {
					item.guestList.add(locSortMap.get(rowNo));
				}
			}		
			if(!isShowMemoColFlg) return;
	 		for (OneRoomInfo yadoInfo : roomGuestList) {
	 			Integer no = 0;		 			
 				for (OneRoomGuestInfo guestInfo : yadoInfo.guestList) {	 					
 					if(no == 0) guestInfo.isShowMemoCol = true;
					else guestInfo.isShowMemoCol = false;
					no++;
 				}
	 		}
		} catch (Exception e) {
			String msg = e.getMessage();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(msg)));
		}  	
    }
	// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END    
    // 既存情報を取得する
    public void saveGuestInfo() {
    	
    	// 2017/04/13 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'LastName','FirstName'}; // 'Id',
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Contact.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return;
		}
		if (!CommSecurityUtils.isCanUpdateable(insChkFields, insm)) {
			return;
		}
		// 2017/04/13 Field Security Check End by wx
    	// 2019/09/15 Security Check BY zyz BEGIN
    	if (!CommSecurityUtils.isDeleteable(Yadochou__c.getSObjectType())) {
    		return;
    	}
    	if (!CommSecurityUtils.isDeleteable(Guestbookcustomer__c.getSObjectType())) {
    		return;
    	}
    	// 2019/09/15 Security Check BY zyz END
    	list<Contact> updateContactLst = new list<Contact>();
    	list<Contact> insertContactLst = new list<Contact>();
    	// 同じお客様情報は重複更新回避対応機能
    	set<id> dupContactIdCheckSet = new set<id>();
Savepoint sp = Database.setSavepoint();
try {
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		rowSorting(false);
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
		// 関連のお客様情報を新規・更新処理を行う
    	for (OneRoomInfo yadoInfo : roomGuestList) {
    		// 宿帳情報へ情報反映する
    		for (OneRoomGuestInfo guestInfo : yadoInfo.guestList) {
    			// お客様情報を入れると、新規、更新処理を行う
    			if (guestInfo.isValidata && guestInfo.isChanged()) {
    				Contact c = guestInfo.c;
    				guestInfo.preSaveProcess();
					// 新規対象の場合
					if (CommUtils.isBlank(c.id)) {
						c.Id = null;
						insertContactLst.add(c);
					} 
					// 重複お客様情報が存在する場合、１番目変更されたお客様の情報で更新を行う
					else if (!dupContactIdCheckSet.contains(c.Id)) {
	    				updateContactLst.add(c);
	    				dupContactIdCheckSet.add(c.Id);
    				}
    			}
    		}
    	}
    	// お客様情報は既に存在する場合、該当お客様は直接を使う
    	if (!insertContactLst.isEmpty()) {
			Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.AllowSave = true;
			Database.insert(insertContactLst, dml);
    	}
    	// お客様情報を反映を行う
    	if (!updateContactLst.isEmpty()) {
    		//update updateContactLst;
			Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.AllowSave = true;
			Database.update(updateContactLst, dml);
    	}
		// 宿帳と宿帳明細関連処理を行う
		list<Yadochou__c> deleteYadoLst = new list<Yadochou__c>();
		list<Yadochou__c> updateYadoLst = new list<Yadochou__c>();
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		//list<Guestbookcustomer__c> deleteYadoSubLst = new list<Guestbookcustomer__c>();
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
    	// 宿帳入力明細は無効なデータは外す
    	for (OneRoomInfo yadoInfo : roomGuestList) {
    		//Yadochou__c yado = yadoInfo.yado;
    		list<OneRoomGuestInfo> wkGuestList = new list<OneRoomGuestInfo>();
    		// 明細入力チェックを行う
    		for (OneRoomGuestInfo guestInfo : yadoInfo.guestList) {
				// 削除対象
				if (guestInfo.isDelete) {
					// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
					/*
					// 宿帳明細の対象データを削除する
					if (!CommUtils.isBlank(guestInfo.clink.id)) {
						deleteYadoSubLst.add(guestInfo.clink);
					}*/
					// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
					continue;
				}
				// 無効なデータの場合、次の処理を移動
				if (!guestInfo.isValidata) continue;
				wkGuestList.add(guestInfo);
    		}
    		// 宿帳の関連リストをリセットする
    		yadoInfo.restGuestList(wkGuestList);
    	}
    	// 宿帳情報の更新対象リストを作成する
    	for (OneRoomInfo yadoInfo : roomGuestList) {
    		Yadochou__c yado = yadoInfo.yado;
    		list<OneRoomGuestInfo> wkGuestList = yadoInfo.guestList;
    		if (wkGuestList.isEmpty() && !CommUtils.isBlank(yado.Id)) {
    			deleteYadoLst.add(yado);
    			continue;
    		}
    		for (Integer i = 0 ; i < wkGuestList.size(); i++) {
    			OneRoomGuestInfo guestInfo = wkGuestList[i];
    			if (i == 0) {
    				// １番目のお客様情報は宿帳に格納する
    				yado.Field15__c = guestInfo.c.Id;
    				// 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz BEGIN
   					// 获取页面上修改的顾客名并替换
					String cName = CommUtils.nullToBlank(guestInfo.contactName);
					if(!CommUtils.isBlank(cName)){
						yado.Name = convertYadoName(yado.Name,cName);
					}
    				// 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz END
					// 該当番目の宿帳明細の場合、該当宿帳明細は作成する
					// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
					yado.Field13__c =CommUtils.nullToBlank(yadoInfo.field13);
					/*
	    			if (!CommUtils.isBlank(guestInfo.clink.id)) {
	    				deleteYadoSubLst.add(guestInfo.clink);
	    			}
					*/
	    			// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
	    			updateYadoLst.add(yado);
    			}
    		}
    	}
    	// 削除対象が存在すると、削除する
    	if (!deleteYadoLst.isEmpty()) delete deleteYadoLst;
    	// 宿帳情報を反映を行う
    	if (!updateYadoLst.isEmpty()) upsert updateYadoLst;
//System.debug(loggingLevel.info, 'updateYadoLst::'+updateYadoLst);
    	// 宿帳明細処理を行う
    	List<Guestbookcustomer__c> updateYadoSubLst = new list<Guestbookcustomer__c>();
    	// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
    	List<Id> yadoIdLst = new List<Id>();
    	// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
    	for (OneRoomInfo yadoInfo : roomGuestList) {
    		Yadochou__c yado = yadoInfo.yado;
    		if (yado.id == null) continue;
    		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
	    	yadoIdLst.add(yado.id);
	    	// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
			for (Integer i=1; i<yadoInfo.guestList.size(); i++) {
				OneRoomGuestInfo guestInfo = yadoInfo.guestList[i];
				// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
				//if (guestInfo.isValidata && guestInfo.c.id != null) {
				if (guestInfo.isValidata) {
    				//Guestbookcustomer__c sub = guestInfo.clink;
    				Guestbookcustomer__c sub = new Guestbookcustomer__c();
    			// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
    				sub.GuestbookNmae__c = yado.Id;
    				sub.customer__c = guestInfo.c.id;
    				updateYadoSubLst.add(sub);
    			}
			}
    	}
    	// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
    	//if (!deleteYadoSubLst.isEmpty()) delete deleteYadoSubLst;
		if(!yadoIdLst.isEmpty()) delete [select id,GuestbookNmae__c from Guestbookcustomer__c  where GuestbookNmae__c in: yadoIdLst];   	
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
    	if (!updateYadoSubLst.isEmpty()) upsert updateYadoSubLst;
} catch (Exception e) {
	DataBase.rollBack(sp);
	String msg = e.getMessage();
	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CommUtils.getFieldValidationMessage(msg)));
}    	
    	// 最新情報を再取得する
    	queryExistInfo();
    }
	// 既存予約情報を取得する
	private void queryExistInfo() {
		// 画面入力情報畫面を作成する
		roomGuestList = new list<OneRoomInfo>();
		if (CommUtils.isBlank(leadIndexId)) return;
		//oPage = new PageInfo();
		Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
		// 引き渡し予約インデックスのIDにより、関連のSUBINDEX含め予約「部屋タイプ」の人数により、入力情報を作成する
 		String leadQuery =  'Select Id, Name, Rroom__c,Rroom__r.Name,LeadIndexRef__c,Relcontact__r.name,LeadIndexSubId__c,RoomGroupNo__c,LeadIndexRef__r.Nights__c, EntryTime__c, Field4__c, Field3__c,Departure__c,ReservedStatus__c,Field298__c,StayPersons__c ' +
                            // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz BEGIN
                            ' , ShopCodeCal__c '+
                            // 2019/03/31 部屋タイプにより、店舗情報を出力対応（パラメータで切り替え可能） BY zyz END
                            // 2018/12/15 レジカード改善 BY zyz BEGIN
                            ' , Mans__c, Femails__c, ChildFA__c, Childs__c, ChildC__c, ChildD__c, ChildE__c, ChildF__c, ChildOther__c ' + 
                            // 2018/12/15 レジカード改善 BY zyz END
                            // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
                            ' , RespectLst__c ' +
                            // 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
                            ' From Lead__c ' +
                            ' Where CancelBool__c != :leadCancelFlg ' +
                            ' And LeadIndexRef__c = :leadIndexId '+
                            ' Order by LeadIndexRef__c, LeadIndexSubId__c, RoomGroupNo__c, EntryTime__c ';
		// 該当予約インデックス関連のN泊N部屋の情報により、既存情報を取得する
		List<Lead__c> existLeads = Database.query(leadQuery);
		map<string, list<lead__c>> existLeadsMap = new map<string, list<Lead__c>>();
		list<String> leadsKeys = new list<String>();
		// map<1泊目予約ID,key>
		map<String, Id> firstDayLeadIdMap = new map<String, Id>();
		for (Lead__c lead : existLeads) {
			String key =	CommUtils.nullToBlank(lead.LeadIndexRef__c) + '_' + 
							CommUtils.nullToBlank(lead.LeadIndexSubId__c) + '_' + 
							CommUtils.nullToBlank(lead.RoomGroupNo__c);
			if (!existLeadsMap.containsKey(key)) {
				existLeadsMap.put(key, new List<Lead__c>());
				leadsKeys.add(key);
				firstDayLeadIdMap.put(key,lead.Id);
			}
			existLeadsMap.get(key).add(lead);
		}
		// 削除対象宿帳と宿帳明細情報IDを格納する（無効：お客様は登録重複、お客様項目を未設定する
		// TODO
		// 1泊目のご予約関連の
		map<id, Yadochou__c> existYadoMap = new map<id, Yadochou__c>();
		// map<宿帳ID、宿帳明細>
		map<id, List<Guestbookcustomer__c>> yadoSubMap = new map<id, List<Guestbookcustomer__c>>();
		//set<id> filterDupContactSet = new set<Id>();
		// 2018/12/15 レジカード改善 BY zyz BEGIN
		Integer yadoTrNum = 0;
		map<id, Integer> yadoSubTrMap = new map<id, Integer>();
		// 2018/12/15 レジカード改善 BY zyz END
		if (!firstDayLeadIdMap.isEmpty()) {
			// 予約関連の既存の宿帳情報を取得する
			// 2017/03/22 お客様項目をカスタムできるように改善対応 BEGIN by wx
			/*
			List<Yadochou__c> yadoList = [
										Select Field1__c, Field15__c, Field15__r.Name, Field15__r.Katakana__c, Field15__r.Phone, Field15__r.Email, Field15__r.gender__c,Field13__c,
										(Select Id, customer__c,customer__r.Name,customer__r.Katakana__c,customer__r.Phone,customer__r.Email,customer__r.gender__c From guestbooknameE3VR__r where customer__c != null Order By Name)
										From Yadochou__c where Field1__c in :firstDayLeadIdMap.values() And Field15__c != null];
			*/
			Set<Id> leadIdSet = new Set<Id>();
			leadIdSet.addAll(firstDayLeadIdMap.values());
			// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
			// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
			// String queryYado = 'Select Field1__c,Field13__c,Field15__c,Signature__c,PageSignature__c '+ parseItem.getYadoQuery() ;
			String queryYado = 'Select Field1__c,Field13__c,Field15__c,Signature__c,PageSignature__c,RespectLstCal__c '+ parseItem.getYadoQuery() ;
			// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
			// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
			// 2018/12/15 レジカード改善 BY zyz BEGIN
			//queryYado += ' ,(Select id, customer__c '+ parseItem.getYadoSubQuery() +' From guestbooknameE3VR__r where customer__c != null Order By Name)';
			queryYado += ' ,(Select id, customer__c '+ parseItem.getYadoSubQuery() +' From guestbooknameE3VR__r ';
			if(!contactNullCanInsFlg) queryYado += '  where customer__c != null ';
			queryYado += ' Order By Name) ';
			// 2018/12/15 レジカード改善 BY zyz END
			// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
//			queryYado += ' From Yadochou__c where Field1__c in : leadIdSet And Field15__c != null';
			queryYado += ' From Yadochou__c where Field1__c in : leadIdSet ';
			if (contactNullCanInsFlg != true) queryYado += ' And Field15__c != null';
			// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
			
			// 既存の宿帳情報を画面へマッピングする
//System.debug(loggingLevel.info, 'queryYado='+queryYado);
//System.debug(loggingLevel.info, 'parseItem='+parseItem);
			// for (Yadochou__c yado : yadoList) {
			for (Yadochou__c yado : DataBase.query(queryYado)) {
			// 2017/03/22 お客様項目をカスタムできるように改善対応 END by wx
				// 該当予約の関連宿帳情報は既に格納する、しないチェック
				if (!existYadoMap.containsKey(yado.Field1__c)) {
					existYadoMap.put(yado.Field1__c, yado);
					// 重複のお客様情報をクリアする
					// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
					//Id yadoContactId = yado.Field15__c;
					// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
					List<Guestbookcustomer__c> filterGuestList = new list<Guestbookcustomer__c>();
					// 2018/12/15 レジカード改善 BY zyz BEGIN
					if(contactNullCanInsFlg) yadoTrNum = CommUtils.nullToIntZero(yado.guestbooknameE3VR__r.size());
					// 2018/12/15 レジカード改善 BY zyz END
					for (Guestbookcustomer__c guest : yado.guestbooknameE3VR__r) {
						Id yadoSubContactId = guest.customer__c;
						// 2018/12/15 レジカード改善 BY zyz BEGIN
						filterGuestList.add(guest);
						// 2018/12/15 レジカード改善 BY zyz END
					}
					// 2018/12/15 レジカード改善 BY zyz BEGIN
					yadoSubTrMap.put(yado.Id,yadoTrNum);
					// 2018/12/15 レジカード改善 BY zyz END
					yadoSubMap.put(yado.Id, filterGuestList);
				}
			}
		}
		for (String key : leadsKeys) {
			// １部屋単位の関連宿帳情報を設定する
			// 2018/12/15 レジカード改善 BY zyz BEGIN
			//OneRoomInfo oneRoomInfo = new OneRoomInfo(existLeadsMap.get(key));
			OneRoomInfo oneRoomInfo = new OneRoomInfo(existLeadsMap.get(key),0);
			// 2018/12/15 レジカード改善 BY zyz END
			// 既存の宿帳情報を存在すると、格納する
			Id leadId = firstDayLeadIdMap.get(key);
			if (existYadoMap.containsKey(leadId)) {
				Yadochou__c yado = existYadoMap.get(leadId);
				// 2018/12/15 レジカード改善 BY zyz BEGIN
				oneRoomInfo = new OneRoomInfo(existLeadsMap.get(key),CommUtils.nullToIntZero(yadoSubTrMap.get(yado.Id)));
				// 2018/12/15 レジカード改善 BY zyz END
				oneRoomInfo.merageYadoInfo(yado, yadoSubMap.get(yado.Id));
			}
			roomGuestList.add(oneRoomInfo);
		}
	}
	
	public list<OneRoomInfo> roomGuestList{get; private set;}
	// 部屋割りの宿泊情報を格納する
	public class OneRoomInfo {
		// 2018/12/15 レジカード改善 BY zyz BEGIN
		public OneRoomInfo(List<Lead__c> leads,Integer TrNum) {
		// 2018/12/15 レジカード改善 BY zyz END
			//
			if (!leads.isEmpty()) {
				String stayCiDtStr = leads[0].EntryTime__c.format(CommBaseCtrl.getDateFormat());
				String stayCoDtStr = leads[leads.size()-1].Departure__c.format(CommBaseCtrl.getDateFormat());
				// 泊数と人数
				Date stayCiDt = leads[0].EntryTime__c.date();
				Date stayCoDt = leads[leads.size()-1].Departure__c.Date();
				Integer stayNights = stayCiDt.daysBetween(stayCoDt);
				// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
				// Integer stayPeople = CommUtils.nullToIntZero(leads[0].StayPersons__c);
				stayPeople = CommUtils.nullToIntZero(leads[0].StayPersons__c);
				// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
				// 2018/12/15 レジカード改善 BY zyz BEGIN
				Integer man = CommUtils.nullToIntZero(leads[0].Mans__c);
				Integer femail = CommUtils.nullToIntZero(leads[0].Femails__c);
				Integer childrens = CommUtils.nullToIntZero(leads[0].ChildFA__c) + 
									CommUtils.nullToIntZero(leads[0].Childs__c) + 
									CommUtils.nullToIntZero(leads[0].ChildC__c) + 
									CommUtils.nullToIntZero(leads[0].ChildD__c) + 
									CommUtils.nullToIntZero(leads[0].ChildE__c) + 
									CommUtils.nullToIntZero(leads[0].ChildF__c) +
									CommUtils.nullToIntZero(leads[0].ChildOther__c);
				//headerInfo1 = 'ご利用日時:' + stayCiDtStr + '〜' + stayCoDtStr + '('+stayNights+'泊)  ご宿泊人数:' + stayPeople + '　名様';
				headerInfo1 = 'ご利用日時:' + stayCiDtStr + '〜' + stayCoDtStr + '('+stayNights+'泊)  ご宿泊人数: ' + stayPeople + '名 (' +man+','+femail+','+ childrens +')';
				// 2018/12/15 レジカード改善 BY zyz END
				headerInfo2 = ' 部屋：' + CommUtils.nullToBlank(leads[0].Rroom__r.Name);
				headerInfo3 = CONST_STAYPERSONS_ADULTS
								.replace('$_STAYPERSON_$', String.valueOf(CommUtils.nullToZero(leads[0].StayPersons__c)))
								.replace('$_MANS_$', String.valueOf(CommUtils.nullToZero(leads[0].Mans__c)))
								.replace('$_FEMALE_$', String.valueOf(CommUtils.nullToZero(leads[0].Femails__c)))
								//子:
								.replace('$_CHILDS_$', (childrens > 0 ? (' '+ Label.CONST_008_0121 + String.valueOf(childrens) ) : ''));
				headerInfo3 += ' ' + CONST_STAYPERSONS_CHILDS
							.replace('$_CHILDREN_$', String.valueOf(childrens))
							.replace('$_CHILDA_$', String.valueOf(CommUtils.nullToZero(leads[0].ChildFA__c)))
							.replace('$_CHILDB_$', String.valueOf(CommUtils.nullToZero(leads[0].Childs__c)))
							.replace('$_CHILDC_$', String.valueOf(CommUtils.nullToZero(leads[0].ChildC__c)))
							.replace('$_CHILDD_$', String.valueOf(CommUtils.nullToZero(leads[0].ChildD__c)))
							.replace('$_CHILDE_$', CommUtils.nullToZero(leads[0].ChildE__c) > 0 ? ', E:' + String.valueOf(CommUtils.nullToZero(leads[0].ChildE__c)) : '')
							.replace('$_CHILDF_$', CommUtils.nullToZero(leads[0].ChildF__c) > 0 ? ', F:' + String.valueOf(CommUtils.nullToZero(leads[0].ChildF__c)) : '');
				// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
				leadMrVal = CommUtils.nullToBlank(leads[0].RespectLst__c);
				// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
				yado = new Yadochou__c();
				yado.Field1__c = leads[0].Id;
				yado.Name = leads[0].Name;
				// 指定の人数により、お客様入力行を自動Generalする
				guestRows = stayPeople == 0 ? 5 : stayPeople;
				guestList = new list<OneRoomGuestInfo>();
				// 2018/10/16 宿帳明細入力欄自動作成不要 WSQ BEGIN
				if (autoCreateBlankRowFlg) stayPeople = 0;
				// 2018/10/16 宿帳明細入力欄自動作成不要 WSQ END
				// 2018/12/15 レジカード改善 BY zyz BEGIN
				if(TrNum != 0) stayPeople = TrNum;
				for (Integer i=0; i < stayPeople; i++) {
				// 2018/12/15 レジカード改善 BY zyz END
					// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
					// OneRoomGuestInfo guest = new OneRoomGuestInfo(guestList.size());
					OneRoomGuestInfo guest = new OneRoomGuestInfo(guestList.size(),leads[0].Id);
					// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
					guestList.add(guest);
				}
			}
		}
		// 宿帳情報はマージする
		public void merageYadoInfo (Yadochou__c pYado, List<Guestbookcustomer__c> pGuestList) {
			yado.Id = pYado.Id;
			yado.Field13__c = pYado.Field13__c;
			// DBから取得の特記事項を設定する
			field13 = CommUtils.nullToBlank(pYado.Field13__c);
			// 2017/04/19 署名 zyz BEGIN
			// 2018/07/17 レジカードコード7の署名機能追加 zyz BEGIN
			String yadocode = CommConst.APPOTION_CARREGISTSWITCH_DIV_CODE;
			// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
			if(yadocode !='7' && yadocode !='8') signature = pYado.Signature__c;
			// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
			// 2018/07/17 レジカードコード7の署名機能追加 zyz END
			// 2017/04/19 署名 zyz END
			// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
			Integer signaTypeInt = CommUtils.nullToIntZero(CommConst.APPOTION_CARREG_SING_TYPE);
			// 2018/07/17 レジカードコード7の署名機能追加 zyz BEGIN
			// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
			if(signaTypeInt == 3 || yadocode =='7' || yadocode =='8'){
			// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
			// 2018/07/17 レジカードコード7の署名機能追加 zyz END
				pagesignature = pYado.PageSignature__c;
			}else { pagesignature = null;}
			// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
			// wgch end
			// 宿帳のお客様情報が存在すると、該当お客様情報は明細に設定を行う
			// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
			//if (pYado.Field15__c != null) {
			if (pYado.Field15__c != null || contactNullCanInsFlg) {
			// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
				// 宿帳にお客様情報をリンクしているあり
				// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
				// OneRoomGuestInfo firstContact = new OneRoomGuestInfo(0);
				OneRoomGuestInfo firstContact = new OneRoomGuestInfo(0,pYado.Field1__c);
				// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
				firstContact.mergeGuestInfo(new Guestbookcustomer__c(customer__r = pYado.Field15__r, customer__c = pYado.Field15__c));
				// １番目に宿帳のお客様情報を設定する
				if (guestList.size() > 0) {
					guestList[0] = firstContact;
				} else {
					guestList.add(firstContact);
				}
			}
			Integer checkNum = 1;
			// お客様明細設定する
			if (pGuestList != null) {
				for (Guestbookcustomer__c guest : pGuestList) {
					// 2番目から関連のお客様情報を設定する
					OneRoomGuestInfo guestInfo = null;
					if (guestList.size() > checkNum ) {
						// 明細を設定する
						guestInfo = guestList[checkNum];
					} else {
						// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
						// guestInfo = new OneRoomGuestInfo(guestList.size());
						guestInfo = new OneRoomGuestInfo(guestList.size(),pYado.Field1__c);
						// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
						guestList.add(guestInfo);
					}
					//
					guestInfo.mergeGuestInfo(guest);
					checkNum++;
				}
			}
		}
		public void restGuestList(List<OneRoomGuestInfo> nwGuestList) {
			guestList = nwGuestList;
		}
		// 宿帳の情報
		public Yadochou__c yado{get;private set;}
		// 宿帳の明細情報
		public list<OneRoomGuestInfo> guestList{get; private set;}
		// ご利用日時：XXXX〜XXX ご宿泊人数：N
		public String headerInfo1{get; private set;}
		public String headerInfo2{get; private set;}
		public String headerInfo3{get; private set;}
		public Integer guestRows{get; private set;}
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		public Integer stayPeople{get;set;}
		public String field13{get;set;}
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
		// 2017/04/19 署名 zyz BEGIN
		public String signature{get;set;}
		// 2017/04/19 署名 zyz END
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz BEGIN
		public String leadMrVal{get;set;}
		// 2019/10/15 見積書、請求書、会計書、予約確認書の敬称を選択できるように改善対応 BY zyz END
		// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz BEGIN
		public String pagesignature{get;set;}
		// 2017/09/20 全画面サイン、画像ファイルに保存の改善対応 zyz END
	}
	// 宿帳明細
	public class OneRoomGuestInfo {
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		// public OneRoomGuestInfo(Integer rowNo) {
		public OneRoomGuestInfo(Integer rowNo,String leadIdStr) {
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
			clink = new Guestbookcustomer__c();
			c = new Contact();
			orgC = new Contact();
			if (rowNo == 0) isShowMemoCol = true;
			else isShowMemoCol = false;
			// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
			leadId = leadIdStr;
			rowsNo = 0;
			// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
		}
		public void mergeGuestInfo (Guestbookcustomer__c pClink) {
			if (pClink.Id != null) clink.Id = pClink.Id;
			if (pClink.customer__c != null) {
				c = pClink.customer__r.clone(false,true);
				c.Id = pClink.customer__c;
				orgC = c.clone(true,true);
				contactName = c.Name;
			}
		}
		public Guestbookcustomer__c clink{get;private set;}
		public Contact c{get; private set;}
		private Contact orgC;
		public String contactName{get;set;}
		public void preSaveProcess() {
			if (isValidata) {
				String[] splitName = CommUtils.splitName(contactName);
				c.LastName = splitName[0];
				if (splitName.size()>1) c.FirstName = splitName[1];
			}
		}
		//public Integer rowNo{get;set;}
		public Boolean isShowMemoCol{get; private set;}
		// 有効な予約情報
		public Boolean isValidata{get{
			// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ BEGIN
			// NULLお客様でも登録できるの場合、お客様名有効性チェックを行わない
			//return !CommUtils.isBlank(contactName);
			return (contactNullCanInsFlg ? true : !CommUtils.isBlank(contactName));
			// 2018/10/16 宿帳登録画面、空欄でも宿帳が自動作成できるように改善対応 WSQ END
		}}
		public Boolean isDelete {get{
			return (!CommUtils.isBlank(c.Id) && !isValidata);
		}}
		// お客様情報を変更あり、無しをチェックする
		public Boolean isChanged() {
			if (c.Id == null) return true;
			else {
				// 項目比較する
				Map<String, Object> fieldsToValue = c.getPopulatedFieldsAsMap();
				for (String fieldName : fieldsToValue.keySet()){
					if (orgC.get(fieldName) != c.get(fieldName)) {
						return true;
					}
				}
				// 名前変更の場合
				if (contactName != orgC.Name) return true;
			}
			return false;
		}
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる BEGIN
		public Integer rowsNo{get;set;}
		public String leadId{get;set;}
		// 2017/03/22 宿帳登録画面に、お客様の名前の順番や部屋を変更できる END
	}
	// 2017/04/17 Source Security Fix BEGIN
	public String getApplicationFormReportPopupIsShowStr() {
		return (CommDefine__c.getOrgDefaults().ApplicationFormReportPopupIsShow__c != true ? 'false' : 'true');
	}
	// 2017/04/17 Source Security Fix END
	// 2017/04/12 署名 zyz BEGIN
	@remoteAction
	global static void refreshsignatureInfo (Id yadoId,String png){
	    /*2018/03/08 廃止ソース
		if (!CommUtils.isBlank(yadoId)){
			Yadochou__c queryyado = [select Id,Name,Field1__c,Field15__c,Field11__c,Field12__c,Signature__c,Field13__c,LeadIndexId__c from Yadochou__c where Id =: yadoId];
			if (queryyado != null) {
				queryyado.Signature__c = png;
				update queryyado;
			}
		}*/
	}
	// 2017/04/12 署名 zyz END
	// 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz BEGIN
	// 连泊数据名处理
	@TestVisible private static String convertYadoName (String orgYadoName,String YadoName) {
		// 予約名切替用キー
		orgYadoName = CommUtils.nullToBlank(orgYadoName);
		YadoName = CommUtils.nullToBlank(YadoName);
		//泊目
		String repRegExpKey1 = LEAD_NAME_PREFIX + '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
		//泊目
		String repRegExpKey2 = '([0-9]+-[0-9]+'+ Label.CONST_008_0110 +')';
		String repRegKey = '';
		
		String regexpResult1 = orgYadoName.replaceFirst(repRegExpKey1, repRegKey);
		String newLeadName = regexpResult1.replaceFirst(repRegExpKey2, repRegKey);
		// 更新未成功或者仍然含有●
		if (orgYadoName == newLeadName && newLeadName.startsWith(LEAD_NAME_PREFIX)) {
			// 把所有的●変え空
			newLeadName = newLeadName.replace(LEAD_NAME_PREFIX,'');
		}
		// 替换原宿帐名
		String newYadoName = orgYadoName.replace(newLeadName.trim(),YadoName);
		return newYadoName;
	}
	// 2019/02/15 客様の名前を変更した場合、宿帳もそれに伴って名前が変更 BY zyz END
	// 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz BEGIN
	webservice static String isPlanItem(String code) {
		// 利用禁止
		return '';
	}
	// 2019/05/15 レジカードのタイプ４には自動的に見積明細が記載非表示にする設定がで BY zyz END
}