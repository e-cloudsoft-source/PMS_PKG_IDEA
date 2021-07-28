/**
* 予約ポップ：新規予約ウインドウ機能対応
* 2020/07/30 入湯税の自動入力機能について改善
*/
public with sharing class BookingLeadWindow extends CommBaseCtrl {
    public List<SectionInfo> pageLst{get;set;}
    public Integer staysNums{get;set;}
    public Integer bookingRooms{get;set;}
    public String contactName{get;set;}
    @TestVisible private Lead__c newCustomLead;
    @TestVisible private Contact newContact;            // 新規お客様情報を格納変数
    public Boolean isHaveSeminar{get; private set;}
    // 会計支払方法
    public List<Selectoption> paymentTypeLst{get; private set;}
    public Boolean isHaveRoom{get; private set;}
    public Boolean customLeadbookingCreateOK{get;set;}
    public Boolean isHaveStartDays{get;set;}
    public boolean isHaveStayPerson{get;set;}
    //2017/02/28 新版本対応　by zy BEGIN
    public boolean isHaveEbInfo{get;set;}
    //2017/02/28 新版本対応　by zy END
    public Boolean isHaveBookingRooms{get;set;}
    public Boolean isPlanDetailFlag{get;set;}
    // 室料登録用商品情報を維持する
    private AccountMaster__c roomPriceInfo = null;
    // Hidden項目・到着日
    public String startDays{get;set;}
    // 処理日付
    private Date processDay;
    // 部屋名
    public String roomName{get;set;}
    //  2016/12/21 连接plan页面替换标准页面  begin by wx  
    public String planName{get;set;}
    //  2016/12/21 连接plan页面替换标准页面  end by wx  
    public boolean oldVersionFlag{get;set;}
    public Map<String,Sobject> sobjectMap{get;set;}
    public Map<String,String> fieldLabelMap{get;set;}
    public Map<String,String> fieldObjectMap{get;set;}
    public map<String,boolean> fieldRequiredMap{get;set;}
    public map<String,String> pathToFieldMap{get;set;}
    public Map<String,String> fieldTypeMap{get;set;}
    public Map<String,String> styleMap{get;set;}
    public BookingTimeTable__c startTable{get;set;}
    public BookingTimeTable__c endTable{get;set;}
    private Map<String,String> paramMap;
    // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
    public BookingLeadWindow(){
    	paramMap = Apexpages.currentpage().getparameters();
    	refeshDomNode(paramMap.get('curSpcd'));
    }
    public String xmlShopCode{get;set{
    	paramMap = Apexpages.currentpage().getparameters();
    	String spcd = null;
    	for (String key : paramMap.keySet()) {
    		if (key.contains('branchShopCd')) spcd = paramMap.get(key);
    	}
    	if (spcd != null) refeshDomNode(spcd);
    }}
    // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
    // 返金キー情報格納用
    public String refundItemString{get{return JSON.serialize(BillSimpleHelp.getRefundItemStr());}}
    // 支払ボタンに定義する情報は格納する、該当支払いは支払いMediaと変換定義情報が可能
    // 前受金の場合、自動→会計処理種別は「前受金」、その以外の場合、「支払」情報を定義する
    // XMLの定義情報から取得する
    private Map<String, String> PAYMENT_MATCH_MAP = new Map<String, String>();
    public String payTypeConvertJson{get{return JSON.serialize(PAYMENT_MATCH_MAP);}}
    private List<String> fieldsSplits;
    //private static final Integer LIST_INPUT_MAX_ROWS = 27;
    private static final Integer LIST_INPUT_DEF_ROWS = ( CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) == 0 
                                                        ? 27 
                                                        : CommUtils.nullToIntZero(CommConst.APPOTION_DETAIL_DEF_INPUTLINES) );
    
     // ************************
    // 支店選択リスト
    // ************************
    private Map<String,ShopInformation__c> shopInfoMap;
    private UserUtil.UserShopInfo userInf;
    // 2014/11/27 指定オブジェクトの項目情報は
    //private map<String, Schema.SObjectField> modelDeafaultValuesMap = Lead__c.getSObjectType().getDescribe().fields.getMap();
    //private Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap;
    private static final String LeadConstFields  = 'Relcontact__c,refTypeOfRooms__c,Rroom__c,EntryTime__c,Departure__c,Field310__c,Field315__c,Comment3__c,rooms,staysNums,bookingRooms';
    private static final String defaultRequired = 'Relcontact__c,Name,Field4__c,Field3__c,StayPersons__c,Field2__c';
    //2017/02/28 新版本対応　by zy BEGIN
    //2017/03/01 default設定　by　zy　BEGIN
    private static final Map<String,String> defWindowMap = new Map<String,String>{'SeminarOrderFlg__c' => 'SeminarOrderFlg','ExtraBedChk__c' => 'ExtraBedChk','staysNums' => 'staysNums'};
    //2017/03/01 default設定　by　zy　END
    //2017/02/28 新版本対応　by zy END
    private static final String planFieldName = 'Field310__c';
    private static final String blankString = '$_blank_$';
    // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix BEGIN
    public String curRows{get;set;}
    // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix END
    // 2016/12/07 予約ポップ新規後一画面へ遷移 BEGIN by zh
    public String indexId{get;private set;}
    // 予約ポップ新規後一画面へ自動遷移制御
    public boolean RoomTypeGotoBookingFlexApp{get{return CommDefine__c.getOrgDefaults().RoomTypeGoBookingFlexAppFlg__c;}}
    // 予約ポップ新規後一画面へ遷移する・しない切替選択機能制御
    public boolean RoomTypeGotoBookingFlexAppConfirm{get{return CommDefine__c.getOrgDefaults().RoomTypeGoBookingFlexAppConfirmFlg__c;}}
    // 2016/12/07 予約ポップ新規後一画面へ遷移 END by zh 
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
    public Integer defStaysNums{get;set;}
    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
    // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
	public String OPTION_MODE{get{ return CommConst.OPTION_MODE;}}
	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    public void getInitXmlNode(){
    	// 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
        // refeshDomNode();
        // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
    }
    private List<SectionInfo> getDefaultPage(){
    	//2017/02/28 新版本対応　by zy BEGIN
        // アプリのE/B機能起動がどうかフラグを設定する
        //isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
        //isHaveSeminar = CommConst.APPOTION_ISSHOW_SEMINAR;
        //2017/02/28 新版本対応　by zy BEGIN
        String defaultFields = 'Relcontact__c,refTypeOfRooms__c,Name,EntryTime__c,Relcontact__r.Katakana__c,Field4__c,Relcontact__r.KanaName1__c,Departure__c,Relcontact__r.Phone,Field3__c,StayPersons__c';
        if (isHaveSeminar) defaultFields += ',SeminarOrderFlg__c';
        else defaultFields += ',' + blankString;
        defaultFields += ',staysNums';
        if (isHaveEbInfo) defaultFields += ',ExtraBedChk__c';
        else defaultFields += ',' + blankString;
        defaultFields += ',bookingRooms,$_blank_$';
        if (isHaveRoom) defaultFields += ',Rroom__c,$_blank_$';
        if (!isPlanDetailFlag)defaultFields += ',Field310__c,$_blank_$';
        defaultFields += ',Field315__c,$_blank_$,Field2__c,$_blank_$,Segment__c,$_blank_$';
        List<SectionInfo> defaultLst = new List<SectionInfo>();
        SectionInfo defaultPg = new SectionInfo();
        defaultPg.columnsInt = 2; 
        List<String> defaultFieldLst = new List<String>();
        defaultFieldLst.addAll(defaultFields.split(','));
        defaultPg.add(defaultFieldLst);
        fieldsSplits.addAll(defaultFieldLst);
        defaultLst.add(defaultPg);
        //LeadConstFields.add('refTypeOfRooms__c');
        //oldVersionFlag = true;
        return defaultLst;
    } 
    // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
    // 店舗コード変更前
    private String beforeSpcd;
    private void refeshDomNode(String spcd){
        spcd = CommUtils.nullToBlank(spcd);
    	if (beforeSpcd == spcd) return ;
    	beforeSpcd = spcd;
   // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
        // 列数定義タグ存在チェック[2016/07/06]
        staysNums = 1;
        bookingRooms = 1;
        contactName = '';
        //  2016/12/21 连接plan页面替换标准页面  begin by wx
        planName = '';
        //  2016/12/21 连接plan页面替换标准页面  end by wx
        //init
        //2017/02/28 新版本対応　by zy BEGIN
        // アプリのE/B機能起動がどうかフラグを設定する
        isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
        isHaveSeminar = CommConst.APPOTION_ISSHOW_SEMINAR;
        // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
        isBasePlanFlag = false;
        // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
        //2017/02/28 新版本対応　by zy END
        isHaveStartDays = true;
        isPlanDetailFlag = false;
        isHaveBookingRooms = true;
        isHaveStayPerson = false;
        oldVersionFlag = false;
        Integer showVersion = CommConst.APPOTION_NEWBOOKING_VER;
        oldVersionFlag = (showVersion != 2);
        newContact = new Contact();
        // 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy BEGIN
        newCustomLead = (Lead__c)Lead__c.sObjectType.newSObject(CommLogicProcess.getLeadBookingRecType(), true);
        // new Lead__c();
        // 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy END
        fieldsSplits = new List<String>();
        pageLst = new List<SectionInfo>();
        customLeadbookingCreateOK = false;
        endTable = new BookingTimeTable__c();
        startTable = new BookingTimeTable__c();
        fieldTypeMap = new Map<String,String>();
        fieldLabelMap = new Map<String,String>();
        fieldObjectMap = new Map<String,String>();
        styleMap = new Map<String,String>();
        pathToFieldMap = new map<String,String>();
        Set<String> excuteSet = new Set<String>();
        Set<String> requiredSet = new Set<String>();
        fieldRequiredMap = new map<String,boolean>();
        userInf = UserUtil.CurrentUserInfo;
        Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,true);
        // 2016/08/01 店舗設定情報を取得する
        shopInfoMap = ShopInfoUtil.getShopInfoMap();
        // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
    	// チェックイン時刻、チェックアウト時刻
        //newCustomLead.Field4__c = CommConst.DEF_CHECKIN_TIME;
        //newCustomLead.Field3__c = CommConst.DEF_CHECKOT_TIME;
        // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
        ShopInfoUtil.ShopLeadInfo shopInfo = ShopInfoUtil.getShopDefInfo(spcd);
        // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
        newCustomLead.Field4__c = shopInfo.defCheckInTimeStr;
		newCustomLead.Field3__c = shopInfo.defCheckOtTimeStr;
		defStaysNums = shopInfo.defStayNums;
		// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
        // 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy BEGIN
        // 予約レコードタイプを設定する
        // newCustomLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
        // 2020/06/15 予約ポップのデフォルト字段エラー修正 by zy END
        isHaveRoom = CommConst.APPOTION_ISSHOW_ROOM;
        // 画面に既存の予約項目重複処理
        List<String> constFieldsList = LeadConstFields.deleteWhitespace().split(',');
        Set<String> dupliateSet = new Set<String>(constFieldsList);
        // 室料自動設定用会計商品名を取得する
        String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
        // 2014/01/27 料金自動設定用商品情報を取得する
        if (!CommUtils.isBlank(roomPriceProdName)) {
           List<AccountMaster__c> accMsts = ProductItemUtils.getRoomRateProduct(roomPriceProdName);
           if (!accMsts.isEmpty()) roomPriceInfo = accMsts[0];
        }
        //2017/02/28 新版本対応　by zy BEGIN
        //新版本不check此flag
        if (!oldVersionFlag) { 
        	isHaveSeminar = true;
        	isHaveEbInfo = true;
        }
        //2017/02/28 新版本対応　by zy END
        // 拡張予約項目を定義する
        String xmlName = (oldVersionFlag ? 'RoomTypeInventoryLeadInputExtendFieldsXml' : 'RoomTypeInventoryLeadInputExtendFieldsXml_V2');
        // 格納用変数クリアする
        // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
        BillSimpleHelp help = new BillSimpleHelp(spcd);
        // 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
        PAYMENT_MATCH_MAP = help.getPaymentTypeToMediaLabMap();
        try{
        	// 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy BEGIN
       		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc(xmlName,spcd);
        	// 2019/03/29 不具合対応、予約ポップ画面に項目連動不可の対応	by zy END
        //String versionStr = '';
        if (targetNode == null) {
            pageLst.addAll(getDefaultPage());
        } else {
            /*
            //version 
            Dom.XmlNode versionNode = targetNode.getChildElement('VERSION', null);
            if (versionNode == null) {
                pageLst.addAll(getDefaultPage());
            } else {
                versionStr = versionNode.getText();
                if(versionStr != '2.0') pageLst.addAll(getDefaultPage());
            }*/
            //プラン明細フラグ
            Dom.XmlNode mitumoriNode =  targetNode.getChildElement('MITUMORIFLAG', null);
            if(mitumoriNode != null) {
                String mitumoriContent = mitumoriNode.getText();
                isPlanDetailFlag = boolean.valueOf(mitumoriContent);
                // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
                if (isPlanDetailFlag) {
                    isBasePlanFlag = boolean.valueOf(CommUtils.nullToBlank(mitumoriNode.getAttribute('BASEPLANFLAG',null)));
                }
                // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
            }
            if (oldVersionFlag) pageLst.addAll(getDefaultPage());
            
            SectionInfo firstPg = new SectionInfo();
            // 店舗情報はＸＭＬから取得する
            Dom.XmlNode shopFields =  targetNode.getChildElement('FIELDS', null);
            String strFields = (shopFields == null ? '' : CommUtils.nullToBlank(shopFields.getText()).deleteWhitespace());
            Set<String> nowFieldSet = new Set<String>(fieldsSplits);
            List<String> oneSectionPageStringLst = new List<String>();
//system.debug(logginglevel.info,'nowFieldSet:::' + nowFieldSet);
            // 項目幅のサイズを定義する
            Dom.XmlNode columnFields =  targetNode.getChildElement('COLNUMSIZE', null);
            if (columnFields != null) {
                String columnSize = CommUtils.nullToBlank(columnFields.getText()).deleteWhitespace();
                for (String col : columnSize.split(',')){
                    if(CommUtils.isBlank(col)) continue;
                    String[] colArr = col.split(':');
                    if ( colArr.size() >= 2) styleMap.put(colArr[0],'width:'+colArr[1]);
                }
            }
            // セクションの項目レイアウトを定義する
            for (String fieldName : strFields.split(',')) {
                if (fieldName == blankString || !nowFieldSet.contains(fieldName)){ 
                    fieldsSplits.add(fieldName);
                    nowFieldSet.add(fieldName);
                    oneSectionPageStringLst.add(fieldName);
                }
            }
            // 店舗情報はＸＭＬから取得する
            requiredSet = new set<string>();
            Dom.XmlNode requiredFields =  targetNode.getChildElement('REQUIREDFIELDS', null);
            if (requiredFields != null) {
                String requiredFieldsDef = CommUtils.nullToBlank(requiredFields.getText().deleteWhitespace());
                if (!CommUtils.isBlank(requiredFieldsDef)) requiredSet.addAll(requiredFieldsDef.split(','));
            }
            firstPg.add(oneSectionPageStringLst);
            
//system.debug(logginglevel.info,'isPlanDetailFlag:::' + isPlanDetailFlag);
            //if(versionStr == '2.0') {
            if (!oldVersionFlag) {
                Dom.XmlNode colnumsNode = targetNode.getChildElement('SHOW_COL', null);
                if (colnumsNode != null) {
                    firstPg.columnsInt = CommUtils.nullToIntZero(colnumsNode.getText().deleteWhitespace());
                }
                
                //排除字段
                Dom.XmlNode exuteFields =  targetNode.getChildElement('EXUTEFIELD', null);
                if (exuteFields != null) {
                    String excuteStrFields = (shopFields == null ? '' : CommUtils.nullToBlank(exuteFields.getText()).deleteWhitespace());
                    if (!CommUtils.isBlank(excuteStrFields)) excuteSet.addAll(excuteStrFields.split(','));
                }
                //其他layout对应
                for ( Dom.XmlNode c : shopFields.getChildElements()) {
                    if(c.getName() == 'SECTION'){
                        SectionInfo p = new SectionInfo();
                        p.title = c.getAttribute('TITLE',null);
                        p.columnsInt = CommUtils.nullToIntZero( c.getAttribute('COLNUM',null));
                        String childFields = CommUtils.nullToBlank(c.getText()).deleteWhitespace();
                        List<String> splitFields = childFields.split(',');
                        oneSectionPageStringLst = new List<String>();
                        for (String fieldName : splitFields) {
                            if (fieldName == blankString || !nowFieldSet.contains(fieldName)){  
                                fieldsSplits.add(fieldName);
                                nowFieldSet.add(fieldName);
                                oneSectionPageStringLst.add(fieldName);
                            }
                        }
                        p.add(oneSectionPageStringLst);
                        pageLst.add(p);
                    }
                }
            } else {
                Dom.XmlNode colnumsNode = targetNode.getChildElement('COLNUMS', null);
                if (colnumsNode != null) {
                    firstPg.columnsInt = CommUtils.nullToIntZero(colnumsNode.getText().deleteWhitespace());
                }
            }
            pageLst.add(firstPg);
        }
	    }catch(Exception e){
	    	pageLst.addAll(getDefaultPage());
	    	oldVersionFlag = true;
	    }
        sobjectMap = new Map<String,Sobject>();
        for (Schema.DescribeFieldResult dr : modelDeafaultValuesMap.values()) {
            if(dr.getType() == DisplayType.Reference){
                SObjectType referenceObj = dr.getReferenceTo()[0];
                Sobject obj = referenceObj.newSObject();
                sobjectMap.put(dr.getRelationshipName(),obj);
            } 
        }
        
        // 2016/07/12 BEGIN
        //List<Schema.FieldSetMember> yoyakuFieldLst = SObjectType.Lead__c.FieldSets.NewBookingFieldSet.getFields();
        Map<String,String> fieldToRefKeyMap = new Map<String,String>();
        //Map<String,Schema.FieldSetMember> fieldSetMap = new Map<String,Schema.FieldSetMember>();
        //2017/03/01 お客様項目タイプ対応　by　zy　BEGIN
        contactFieldType = '';
        Map<String, Schema.DescribeFieldResult> contactFieldMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
        //2017/03/01 お客様項目タイプ対応　by　zy　END
        //for(Schema.FieldSetMember field : yoyakuFieldLst) {
        for(String path : requiredSet) {
            //String path = field.getFieldPath();
            if (path.contains('__r')) {
                for (String refKey : sobjectMap.keySet()) {
                    if (path.contains(refKey)) {
                        String fieldNm = path.replace(refKey+'.','');
                        pathToFieldMap.put(path,fieldNm);
                        fieldToRefKeyMap.put(path,refKey);
                    }
                }
            } else pathToFieldMap.put(path,path);
            //fieldSetMap.put(path,field);
        }
        // 2017/04/07 見積もり明細のフラグ　フェルダー「プラン」不表示する　by　zy BEGIN
        if (isPlanDetailFlag) dupliateSet.remove('Field310__c');
         // 2017/04/07 見積もり明細のフラグ　フェルダー「プラン」不表示する　by　zy END
        //除外
        for (String field : excuteSet){
            if (field == 'staysNums') isHaveStartDays = false;
            if (field == 'bookingRooms') isHaveBookingRooms = false;
            dupliateSet.remove(field);
            for (integer i = 0 ; i < fieldsSplits.size() ; i++) {
                String fieldNm = fieldsSplits[i];
                if (field == fieldNm) fieldsSplits.remove(i);
            }
            for (SectionInfo s : pageLst) {
                
                for (integer i = 0 ; i < s.fieldLst.size() ; i++) {
                    String fieldNm = s.fieldLst[i];
                    if (field == fieldNm) s.fieldLst.remove(i); 
                }
            }
        }
        // デフォルト値自動設定
        if(requiredSet.isEmpty()) requiredSet.addAll(defaultRequired.split(','));
        if (!oldVersionFlag) {
            requiredSet.add('EntryTime__c');
            requiredSet.add('Departure__c');
        }
        //老版本下 comment 在最后
        if (oldVersionFlag){
            SectionInfo defaultCommentPg = new SectionInfo();
            defaultCommentPg.columnsInt = 1;
            defaultCommentPg.add(new Set<String>{'Comment3__c'});
            
            fieldsSplits.add('Comment3__c');
            pageLst.add(defaultCommentPg);
        }
        //system.debug(logginglevel.info,'fieldToRefKeyMap:::' + fieldToRefKeyMap);
//system.debug(logginglevel.info,'fieldsSplits:::' + fieldsSplits);
        sobjectMap.put('Relcontact__r',newContact);
        // 予約に固定使用する項目APIから無くす
        for (String extendField : fieldsSplits) {
//system.debug(logginglevel.info,'extendField1:::' + extendField);
            //if (CommUtils.isBlank(extendField)) continue;
            if(extendField == 'StayPersons__c') isHaveStayPerson = true;
            if(!styleMap.containsKey(extendField)) styleMap.put(extendField,'');
            //是否包含参照关系
            if (extendField.contains('__r')) {
                for (String refKey : sobjectMap.keySet()) {
                    if (extendField.contains(refKey)) {
                        String fieldNm = extendField.replace(refKey+'.','');
                        pathToFieldMap.put(extendField,fieldNm);
                        fieldToRefKeyMap.put(extendField,refKey);
                        //2017/03/01 お客様項目タイプ対応　by　zy　BEGIN
                        if(contactFieldMap.containsKey(fieldNm.toLowerCase())){ 
                        	contactFieldType = checkAndAddFiledName(contactFieldMap.get(fieldNm.toLowerCase()),contactFieldType);
                        }
                        //2017/03/01 お客様項目タイプ対応　by　zy　END
                        break;
                    }
                }
            }
            String refName = fieldToRefKeyMap.get(extendField);
//system.debug(logginglevel.info,'refName:::' + refName);
//system.debug(logginglevel.info,'extendField:::' + extendField);
            //Schema.SObjectField f;
            Schema.DescribeFieldResult dr;
            if (modelDeafaultValuesMap.containsKey(extendField)) {
                dr = modelDeafaultValuesMap.get(extendField);
                fieldObjectMap.put(extendField,'Lead__c');
                if (!pathToFieldMap.containsKey(extendField)) pathToFieldMap.put(extendField,extendField);
            } else if (!CommUtils.isBlank(refName) && sobjectMap.containsKey(refName)){
                //f = sobjectMap.get(refName).getSObjectType().getDescribe().fields.getMap().get(pathToFieldMap.get(extendField));
                dr = CommSqlUtils.getAllFieldLst(sobjectMap.get(refName).getSObjectType(), true).get(pathToFieldMap.get(extendField));
                fieldObjectMap.put(extendField,refName);
                //fieldObjectMap.put(extendField,sobjectMap.get(refName).getSObjectType());
            }
            //if (f != null){   
            if (dr != null) {
//system.debug(logginglevel.info,'pathToFieldMap:::' + pathToFieldMap.get(extendField));
                //排除不可更新字段
                //Schema.DescribeFieldResult dr = f.getDescribe();
//system.debug(logginglevel.info,'dr.isUpdateable():::' + dr.isUpdateable());
                if(!dr.isUpdateable()){
                    for (SectionInfo s : pageLst) {
                        for (integer i = 0 ; i < s.fieldLst.size() ; i++) {
                            String fieldNm = s.fieldLst[i];
                            if (extendField == fieldNm) s.fieldLst.remove(i); 
                        }
                    }
                    dupliateSet.remove(extendField);
                    continue;
                }
                fieldLabelMap.put(extendField,dr.getLabel());
                //是否为空
                if (requiredSet.contains(extendField)) {
                    fieldRequiredMap.put(extendField,true);
                }else fieldRequiredMap.put(extendField,isRequired(dr));  
                //
                //2017/02/28 eb 対応　by　zy　BEGIN
                if (defWindowMap.containsKey(extendField)){
                	fieldTypeMap.put(extendField,defWindowMap.get(extendField));
                	continue;
                }
                //2017/02/28 eb 対応　by　zy　END
                if(dr.getType() == DisplayType.Boolean) {
                    fieldTypeMap.put(extendField,'boolean');
                }else if (dupliateSet.contains(extendField)){
                    fieldTypeMap.put(extendField,extendField.replace('__c',''));
//system.debug(logginglevel.info,'dupliateSet:::' + extendField);
                } else
                    fieldTypeMap.put(extendField,'custom');
//system.debug(logginglevel.info,'extendField:::' + extendField);        
            } else if (dupliateSet.contains(extendField)){
                fieldTypeMap.put(extendField,extendField.replace('__c',''));
                if (requiredSet.contains(extendField))  fieldRequiredMap.put(extendField,true);
                else fieldRequiredMap.put(extendField,false);
            } else {
                if (extendField == blankString) {
                    fieldTypeMap.put(extendField,'blank');
                    continue;
                }
                for (SectionInfo s : pageLst) {
                    for (integer i = 0 ; i < s.fieldLst.size() ; i++) {
                        String fieldNm = s.fieldLst[i];
                        if (extendField == fieldNm) s.fieldLst.remove(i); 
                    }
                }
            }
            dupliateSet.remove(extendField);
        }
        // 元画面常に表示される項目に対して、デフォルト値設定を行う
        for (String fieldName : dupliateSet) {
            if (CommUtils.isBlank(fieldName)) continue;
//system.debug(logginglevel.info,'dupliateSet-fieldName:::' + fieldName);
            String typeStr = fieldName.replace('__c','');
            if(!styleMap.containsKey(fieldName)) styleMap.put(fieldName,'');
            //fieldLst.add(fieldName);
            if (modelDeafaultValuesMap.containsKey(fieldName)) {
                //Schema.SObjectField f = modelDeafaultValuesMap.get(fieldName);
                //Schema.DescribeFieldResult dr = f.getDescribe();
                Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(fieldName);
                //fieldTypeMap.put(fieldName,typeStr);
                fieldObjectMap.put(fieldName,'Lead__c');
                fieldLabelMap.put(fieldName,dr.getLabel());
                // 2016/09/14 不具合修正
                fieldRequiredMap.put(fieldName,isRequired(dr));
                fieldTypeMap.put(fieldName,typeStr);
                pageLst[0].fieldLst.add(fieldName);
            //} else {
           	//2017/03/01 default設定　by　zy　BEGIN
            } else if (defWindowMap.containsKey(fieldName)) {
            	fieldRequiredMap.put(fieldName,requiredSet.contains(fieldName));
            	fieldTypeMap.put(fieldName,defWindowMap.get(fieldName));
            	pageLst[0].fieldLst.add(fieldName);
            }
            //2017/03/01 default設定　by　zy　END
        }
//system.debug(logginglevel.info,'fieldRequiredMap:::' + fieldRequiredMap);
        
        //見積明細あり場合下
        if (isPlanDetailFlag) {
        	for (SectionInfo s : pageLst) {
    			for (integer i = 0 ; i < s.fieldLst.size() ; i++){
	    			if (s.fieldLst[i] == planFieldName ){

	    				if (s.columnsInt > 1)
	    					s.fieldLst[i] = blankString;
	               		else
	               			s.fieldLst.remove(i);
	                } 
                }
        	}
        }
//system.debug(logginglevel.info,'pageLst:::' + pageLst);
        sobjectMap.put('Lead__c',newCustomLead);
        // 支払方法リスト初期化する[2012/08/22追加：予約から会計に自動作成する場合、自動的に支払側の支払データを作成する]
        paymentTypeLst = new List<Selectoption>();
        Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        refreshItem();
    }
    public boolean isRequired(Schema.DescribeFieldResult dr) {
    	return !dr.isNillable() && dr.isCreateable() && !dr.isDefaultedOnCreate();
    }
    public void refreshItem(){
        oBookEstLst = new List<BookEstItem>();
        if (oBookEstLst.size() < LIST_INPUT_DEF_ROWS) {
            Integer appendRsSize = LIST_INPUT_DEF_ROWS - oBookEstLst.size();
            // 2行目まで設定を行う
            for (Integer i = 0; i < appendRsSize; i++) {
                oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size()));
            }
        }
        // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix BEGIN 
        curRows = String.valueOf(LIST_INPUT_DEF_ROWS);
        // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix END
    }
    public class SectionInfo{
        public Integer columnsInt{get;set;}
        public List<String> fieldLst{get;set;}
        public String title{get;set;}
        public boolean isHeadShowFlag{get{ return !CommUtils.isblank(title);}}
        public SectionInfo(){
            columnsInt = 2;
            fieldLst = new List<String>(); 
        }
        public void add(Set<String> fLst){
            fieldLst.addAll(fLst);
        }
        public void add(List<String> fLst){
            fieldLst.addAll(fLst);
        }
    }
    
    // お客様情報新規登録・更新を行う
    private void upsertContact() {
//System.debug(Logginglevel.INFo, 'contactName:::'+contactName);
//System.debug(Logginglevel.INFo, 'newContact.Id:::'+newContact.Id);
//System.debug(Logginglevel.INFo, 'newCustomLead.Relcontact__c:::'+newCustomLead.Relcontact__c);
        // 顧客情報の新規作成
        if (newContact.Id == null) {
            String[] names = CommUtils.splitName(contactName);
            newContact.LastName = names[0];
            newContact.FirstName = names[1];
    	// 2017/03/01 お客様关联的自定义字段更新 Fix by zh BEGIN
        }else {
			List<String> splitContactFields = contactFieldType.split(',');
			Map<String, Schema.DescribeFieldResult> contactDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
	    	for (String fieldConName : splitContactFields) {
	    		if (CommUtils.isBlank(fieldConName)) continue;
	    		List<String> fildSp = fieldConName.split(':');
	    		String fieldCName = fildSp[0].toLowerCase();
	    		String fieldKey = fieldCName.toLowerCase();
	    		if (contactDeafaultValuesMaps.containsKey(fieldKey)){
		    		Schema.DescribeFieldResult result = contactDeafaultValuesMaps.get(fieldKey);
					if( newContact.get(fieldCName) == null){
						if(result.getType() == DisplayType.String || result.getType() == DisplayType.textarea
		    			|| result.getType() == DisplayType.Phone|| result.getType() == DisplayType.Email)
		    				newContact.put(fieldCName,'');
		    			else newContact.put(fieldCName,null);
					}
	    		}		    		
//system.debug(logginglevel.info,'newContact:::' + newContact);
	    	}
    	}
        // 2017/03/01 お客様关联的自定义字段更新 Fix by zh END
		// 2016/10/19 お客様重複管理機能対応 BEGIN
        //upsert newContact;
    	newContact = (new CommLogicProcess()).upsertDuplicateErrorProcess(newContact);
    	// 2016/10/19 お客様重複管理機能対応 END
        newCustomLead.Relcontact__c = newContact.Id;
    }
    
    // データ登録の事前チェック
    private Boolean preBookingCreate() {
        // 処理に必須な項目が未入力の場合、処理を中止する
        // お客様/予約名/予約チャネル
        List<String> constFieldsList = LeadConstFields.deleteWhitespace().split(',');
        constFieldsList.addAll(fieldRequiredMap.keySet());
        Map<String, Schema.DescribeFieldResult> modelDeafaultValuesMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,true);
        Set<String> oldVersionSet = new Set<String>{'EntryTime__c','Departure__c'};
        for (String fieldName : constFieldsList){
//system.debug(logginglevel.info,'fieldName:::' + fieldName);
            if(fieldName == 'Rroom__c') continue;
            if(fieldName == 'Relcontact__c' && !CommUtils.isBlank(contactName)) continue;
            if(oldVersionFlag && oldVersionSet.contains(fieldName)) continue;
            if (fieldRequiredMap.containsKey(fieldName) && fieldRequiredMap.get(fieldName)){
                if(modelDeafaultValuesMap.containsKey(fieldName) && (newCustomLead.get(fieldName) == null || newCustomLead.get(fieldName) == '')){
//system.debug(logginglevel.info,'newCustomLead.get(fieldName):::' + newCustomLead.get(fieldName));
                    if((fieldName == 'EntryTime__c' && startTable.Checkinday__c != null) || (fieldName == 'Departure__c' && endTable.Checkinday__c != null) 
                        || (fieldName == planFieldName && isPlanDetailFlag)){
                        continue;
                    }
                    //Schema.SObjectField f = modelDeafaultValuesMap.get(fieldName);
                    //Schema.DescribeFieldResult dr = f.getDescribe();
                    Schema.DescribeFieldResult dr = modelDeafaultValuesMap.get(fieldName);
                    //必須項目を入力してください。ApexPages.Severity.ERROR, dr.getLabel() + ':'
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.MSG_003_0105));
                    return false;
                    
                }
            }
        }
        // 日帰りの場合、到着日と出発日の時刻チェックを行う
        if (staysNums == 0) {
            // 2013/09/16 TIME:[H:M]書式対応ため、下記処理を追加する
            Time startTime = CommUtils.stringToTime(newCustomLead.Field4__c);
            Time endTime = CommUtils.stringToTime(newCustomLead.Field3__c);
            //if (newLead.Field4__c >= newLead.Field3__c) {
            if (startTime >= endTime) {
                //出発時刻には到着時刻以降の時刻を指定して下さい
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_003_0106));
                return false;
            }
        }
        // Defautl値設定
        if (staysNums == null) staysNums = 0;
        
        // 2013/10/28 部屋割り当て可能チェックを行う
        if (!CommUtils.isBlank(newCustomLead.Rroom__c)) {
//system.debug(logginglevel.info,'newCustomLead.Rroom__c:::' + newCustomLead.Rroom__c);
            Date startDt = Date.parse(startDays);
            // 日帰りする場合、条件統一ため、０から１に変更する
            Date endDt = startDt.addDays(staysNums == 0 ? 1 : staysNums);
            List<Lead__c> existLeads = [ select Id from Lead__c
                where CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
                    And DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt
                    And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt
                    And Rroom__c = :newCustomLead.Rroom__c ];
             if (!existLeads.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_0010));
                return false;
             }
        }
        
        if (!CommUtils.isBlank(newCustomLead.Relcontact__c)) newContact.Id = newCustomLead.Relcontact__c;
        return true;
    }
    private void setLeadDefaultValue() {
        
        if (CommUtils.isBlank(contactName)) {
            Contact c = CommLogicProcess.getOrInsertTempContact();
            newCustomLead.Relcontact__c = c.Id;
            newContact.Id = c.Id;
        } else {
            upsertContact();
        }
        if (CommUtils.isBlank(newCustomLead.Name)) {
            // 仮予約
            newCustomLead.Name = Label.CONST_012_0458;
        }
        // 部屋数は見設定の場合、１部屋数を自動設定する
        if (bookingRooms == null) bookingRooms = 1;
    }
    /**
    * 宿泊の予約データを登録処理
    **/ 
    public PageReference bookingLeadCreate() {
//system.debug(logginglevel.info,'bookingLeadCreate:::' + newCustomLead);
        // 事前チェックを行う
        if (!preBookingCreate()) {
            //doAction(0);
            return null;
        }
        // 2017/02/24 Field Security Check BEGIN by wx
		List<String> insChkFields = new List<String>{'RoomGroupNo__c','Relcontact__c','name','LeadIndexRef__c',
													'FIeld3__c','Field4__c','Departure__c','EntryTime__c','ReservedContact__c',
													'StayPersons__c','ReservedDate__c'};
		Map<String,Schema.SObjectField> insm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFields, insm)) {
			return null;
		}
		List<String> insChkFieldsLst = new List<String>{'Comment__c','Payment__c','Segment__c','Channel__c','LeadName__c',
													'Rooms__c','Nights__c','EventSource__c','contactRef__c','DepartureTime__c',
													'DepartureDate__c','EntryTime__c','EntryDate__c'};
		Map<String,Schema.SObjectField> insmm = Schema.SObjectType.LeadIndex__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(insChkFieldsLst, insmm)) {
			return null;
		}
		// 2017/02/24 Field Security Check End by wx
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'plansycnflag__c','field310__c','recordtypeid','relcontact__c','roomgroupno__c',
													'staypersons__c','field3__c','reserveddate__c','name','field4__c','reservedcontact__c',
													'leadindexref__c','entrytime__c','departure__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.Lead__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return null;
		}
		// 2019/09/15 Security Check BY zyz END
        // Hidden項目から到着日を取得する
        Date defaultDate;
        if (!CommUtils.isBlank(startDays))
            defaultDate = Date.parse(startDays);
//system.debug(logginglevel.info,'newCustomLead1:::' + newCustomLead);
        newCustomLead = (Lead__c)sobjectMap.get('Lead__c');
        newContact = (Contact)sobjectMap.get('Relcontact__r');
//system.debug(logginglevel.info,'newCustomLead:::' + newCustomLead);
        /* 2013/01/21 到着時間と出発時間、設定によて、自動取得、設定を行う */
        //Datetime defCheInDt = Datetime.newInstance(defaultDate, CommConst.defCheckInTime);
        //Datetime defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), CommConst.defCheckOtTime);
        Datetime defCheInDt ;
        if (defaultDate != null)
            defCheInDt = Datetime.newInstance(defaultDate, converHHMMtoTime(newCustomLead.Field4__c));
        Datetime defCheOutDt;
        if (defaultDate != null) 
            defCheOutDt = Datetime.newInstance(defaultDate.addDays(1), converHHMMtoTime(newCustomLead.Field3__c));
        Savepoint sp = Database.setSavepoint();
        try{
            // 初期値自動設定を行う
            setLeadDefaultValue();
            // 更新用リスト
            //if (!CommUtils.isBlank(newLead.Relcontact__c)) newContact.Id = newLead.Relcontact__c;
            // 2013/10/07お客様情報を自動登録機能追加する
            //upsertContact();
            // プラン自動作成[ベースプランを選べてそのまま予約データを登録する場合、ベースプランCLONEして、新プランを作成して、予約に登録する]
            // 2014/06/20 プラン自動作成が外す
            // 挿入用リスト
            List<Lead__c> insList = new List<Lead__c>();
            // 予約受付日を処理当日に指定
            newCustomLead.ReservedDate__c = Datetime.now();
            // 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
            LeadIndex__c newLeadIndex = new LeadIndex__c();
            if (defCheInDt != null)
                newLeadIndex.EntryDate__c = defCheInDt.date();
            if (defCheInDt != null)
                newLeadIndex.EntryTime__c = defCheInDt.format('HH:mm');
    //      newLeadIndex.EntryTime__c = newLead.Field4__c;
    //      newLeadIndex.DepartureDate__c = defCheOutDt.addDays(staysNums).date();
    //      newLeadIndex.DepartureTime__c = defCheOutDt.addDays(staysNums).format('HH:mm');
            if (defCheInDt != null)
                newLeadIndex.DepartureDate__c = defCheInDt.addDays(staysNums).date();
            if (defCheOutDt != null)
                newLeadIndex.DepartureTime__c = defCheOutDt.format('HH:mm');
    //      newLeadIndex.DepartureTime__c = newLead.FIeld3__c;
            // 顧客ID + RandomID
            // 2012/12/20 -> Null Setup
            //newLeadIndex.ID__c = CommUtils.nullToBlank(newLead.Relcontact__c) + '_' + Crypto.getRandomLong();
            newLeadIndex.contactRef__c = newCustomLead.Relcontact__c;
    
            newLeadIndex.EventSource__c = 'FromUI';
            newLeadIndex.Nights__c = staysNums;
            newLeadIndex.Rooms__c = bookingRooms;
            newLeadIndex.LeadName__c = newCustomLead.name;
            // 予約チャネル
            newLeadIndex.Channel__c = newCustomLead.Field2__c;
            // セグメント
            newLeadIndex.Segment__c = newCustomLead.Segment__c;
            // 支払方法
            newLeadIndex.Payment__c = newCustomLead.Field315__c;
            // 特記事項
            newLeadIndex.Comment__c = newCustomLead.Comment3__c;
            insert newLeadIndex;
    
            newCustomLead.LeadIndexRef__c = newLeadIndex.Id;
            // 2016/12/07 予約ポップ新規後一画面へ遷移 BEGIN by zh
        	indexId = newCustomLead.LeadIndexRef__c ;
        	// 2016/12/07  予約ポップ新規後一画面へ遷移 END by zh
            // 予約インデックス情報を作成する 2012/08/23 ADD END
            // 予約の内容を作成する
            String leadName = newCustomLead.name;
            // また、人数とプランも一つの予約データのみに取り込み、他の予約データは、人数ゼロ、プランなし、と設定する
            String strRoomDelegatePrefix = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomDelegatePrefix__c);
            if (!isHaveStayPerson) {
                // 大人人員(男性)
                Decimal oterPerson = (CommUtils.nullToZero(newCustomLead.Mans__c) 
                                        + CommUtils.nullToZero(newCustomLead.Femails__c) 
                                        + CommUtils.nullToZero(newCustomLead.ChildFA__c) 
                                        + CommUtils.nullToZero(newCustomLead.Childs__c) 
                                        + CommUtils.nullToZero(newCustomLead.ChildC__c));
                if (oterPerson > 0) newCustomLead.StayPersons__c = oterPerson;
            }
            // 予約人数は０に自動設定する
            if (newCustomLead.StayPersons__c == null) newCustomLead.StayPersons__c = 0;
            // 自動設定内容
            // 受付日
            newCustomLead.ReservedDate__c = System.now();
            // 受付者
            newCustomLead.ReservedContact__c = UserInfo.getName();
            // 日帰り場合
            if (staysNums == 0) {
                if (defCheInDt != null) {
                	// 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 BEGIN
                	//newCustomLead.EntryTime__c = defCheInDt.addDays(0);
                	//newCustomLead.Departure__c = defCheInDt.addDays(0);
                	Datetime curDatetime = defCheInDt.addDays(0);
                    newCustomLead.EntryTime__c = curDatetime;
                    Datetime curChkoutTime = Datetime.newInstance(curDatetime.date(), converHHMMtoTime(newCustomLead.Field3__c));
                    newCustomLead.Departure__c = curChkoutTime;
                    // 2017/11/07 店舗別泊数、到着時刻、出発時刻初期値自動設計できるように改善対応 END
                }
                for(Integer j = 0; j < bookingRooms; j ++ ){
                     Lead__c cloneLead =  newCustomLead.clone(false, true);
                    // 2013/07/20 UPDATE
                    cloneLead.RoomGroupNo__c = j;
                    if(j == 0) cloneLead.name = (bookingRooms > 1 ? strRoomDelegatePrefix : '') + cloneLead.name;
                    else setLeadValue(cloneLead);
                    insList.add(cloneLead);
                }
            } else {
                // 1泊以上場合
                for(Integer i = 0; i < staysNums; i ++){
                	//泊目
                    if (staysNums > 1) newCustomLead.name = String.valueOf(staysNums) + '-' + (i+1) + Label.CONST_003_0131 +' ' + leadName;
                    if (defCheInDt != null) {
                        newCustomLead.EntryTime__c = defCheInDt.addDays(i);
                        newCustomLead.Departure__c = defCheOutDt.addDays(i);
                    }
                    // 到着時刻
                    newCustomLead.Field4__c = newLeadIndex.EntryTime__c;//newLead.EntryTime__c.format('HH:mm');
                    // 出発時刻
                    newCustomLead.FIeld3__c = newLeadIndex.DepartureTime__c;//newLead.Departure__c.format('HH:mm');
                    for(Integer j = 0; j < bookingRooms; j ++ ){
                           Lead__c cloneLead =  newCustomLead.clone(false, true);
                            // 2013/07/20 UPDATE
                            cloneLead.RoomGroupNo__c = j;
                            if(j == 0) cloneLead.name = (bookingRooms > 1  ? strRoomDelegatePrefix : '') +  cloneLead.name;
                            else setLeadValue(cloneLead);
                            insList.add(cloneLead);
                    }
                }
    
            }
//system.debug(logginglevel.info,'insList:::' + insList);
        // DB操作を行う

            // 2012/12/22 WSQ ADD
            // SUBINDEX自動作成
            CommLogicProcess logic = new CommLogicProcess();
            logic.autoCreateIndexSub(insList);
            // データの更新
//              update updList;
            // データの挿入
            insert insList;
            // 料金表情報にて、予約情報見積もり明細自動設定を行う
            autoCreateBookingEstItems(insList, newLeadIndex.EntryDate__c,newLeadIndex.DepartureDate__c);
            // 画面データを再構築する
            //doAction(0);
	    // 2019/06/14 4.2.予約ポップからベースプランを選択した状態で新規予約作成をすると、予約見積明細に該当のプランが登録された状態で予約を取ることができますが、 by zy BEGIN
            if (!CommUtils.isBlank(basePlanId)) {
                List<Lead__c> leads = new List<Lead__c>();
                for (Lead__c lead : insList) {
                    if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
                        lead.Field310__c = basePlanId;
                        lead.planSycnFlag__c = true;
                        leads.add(lead);
                        break;
                    }
                    lead.Field310__c = basePlanId;
                    lead.planSycnFlag__c = true;
                    leads.add(lead);
                }
                if (!leads.isEmpty()) update leads;
            }
	    // 2019/06/14 4.2.予約ポップからベースプランを選択した状態で新規予約作成をすると、予約見積明細に該当のプランが登録された状態で予約を取ることができますが、 by zy END
        }catch (Exception e){
        	// 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 BEGIN
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            String errMsg = e.getMessage();
            if(!CommUtils.isFieldValidationMessage(errMsg)) Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
            // 2017/05/04 自施設の予約や会計しか変更できないように権限管理機能 END
            Database.rollback(sp);
            customLeadbookingCreateOK = false;
            return null;
        }
        // 2013/06/24 ADD BEGIN
        // Data Create OK
        customLeadbookingCreateOK = true;
//system.debug(logginglevel.info,'customLeadbookingCreateOK:::' + customLeadbookingCreateOK);
        // 設定情報をクリアする【注意：クリアしないと、常にContact　IDを更新されない】
        newContact = new Contact();
        sobjectMap.put('Relcontact__r',newContact);
        refreshItem();
        return null;
    }
    // インナークラス・データ
    public class dispRecord{
        public Id roomTypeId{get;set;}
        public String roomTypeNm{get;set;}
        public List<GuestRoomStock__c> roomList{get;set;}
        public dispRecord(){
            roomList = new List<GuestRoomStock__c>();
        }
    }


    // 旅行会社情報
    public class TrvaleRecord {
        public Id travelId                  {get; set;}
        public String travelName        {get; set;}
        private List<dispRecord> roomTypes{get; set;}
        private Map<Id, dispRecord> existRecMap;
        public TrvaleRecord() {
            roomTypes = new List<dispRecord>();
            existRecMap = new Map<Id, dispRecord>();
        }
        public dispRecord getDispRecord(Id roomTypeId) {
            if (!existRecMap.containsKey(roomTypeId))  {
                dispRecord rec = new dispRecord();
                existRecMap.put(roomTypeId, rec);
                roomTypes.add(rec);
            }
            return existRecMap.get(roomTypeId);
        }

        public List<dispRecord> getRoomTypes() {
            return roomTypes;
        }
    }
    
    /**
    * HH:MM 文字列からTIMEに変換処理
    **/
    private Time converHHMMtoTime(String timeStr) {
        //if (String.isEmpty(timeStr) || timeStr.length() != 5) return Time.newInstance(0,0,0,0);
        //Integer HH = Integer.valueOf(timeStr.subString(0,2));
        //Integer MM = Integer.valueOf(timeStr.subString(3,5));
        //return Time.newInstance(HH, MM, 0, 0);
        return CommUtils.stringToTime(timeStr);
    }
    private void setLeadValue( Lead__c cloneLead){
        // 予約データの分割に登録する
        if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
        // 親部屋に集めるの場合、下記処理を行う
        cloneLead.Comment3__c = null;
         // 代表部屋以外のデータ
        cloneLead.StayPersons__c = 0;
        // 大人人員(男性)
        cloneLead.Mans__c = 0;
        // 大人人員(女性)
        cloneLead.Femails__c = 0;
        // 子供A人数
        cloneLead.ChildFA__c = 0;
         // 子供B人数
        cloneLead.Childs__c = 0;
         // 子供C人数
        cloneLead.ChildC__c = 0;
        // プラン情報 <- NULL
        cloneLead.Field310__c = null;
    }
        // プランなしの予約データに対して、料金表にて、見積もり明細データを作成する
    private void autoCreateBookingEstItems(List<Lead__c> leads, Date stDate, Date edDat) {
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'refbooking__c','productname__c'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.BookingEstimateItem__c.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        // 料金情報設定用商品が非存在する場合、処理中止
        //if (roomPriceInfo == null) return;
        refreshBookingOrder();
        // 予約の料金表情報を設定する
        List<Lead__c> targets = new List<Lead__c>();
        // 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
  		if (!leads.isEmpty()) {
	  		String mainKey = CommUtils.nullToBlank(leads[0].LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(leads[0].LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(leads[0].RoomGroupNo__c);
			// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
	        for (Lead__c lead : leads) {
	        	// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
	  			// 集めるの場合対応
	        	if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_UNION) {
	        		String curKey = CommUtils.nullToBlank(lead.LeadIndexRef__c) 
						+ '_' +	CommUtils.nullToBlank(lead.LeadIndexSubId__c) 
						+ '_' +	CommUtils.nullToZero(lead.RoomGroupNo__c);
	        		if (mainKey != curKey ) continue;
	        	}
		        // 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
	            //if (CommConst.APPOTION_LEADSPLIT_DIV_CODE == CommConst.APPOTION_LEADSPLIT_DIV_CODE_SPLIT) return;
	            // 予約人数は０の場合、見積もり明細作成対象外
	            // プラン未設定 && 予約人数は０以上場合、室料の見積もり明細を自動作成する
	            //  2016/12/21 连接plan页面替换标准页面  begin by wx                       
	            //if (lead.Field310__c == null && CommUtils.nullToZero(lead.StayPersons__c) > 0) {
	            if (CommUtils.isBlank(lead.Field310__c)) { //  && CommUtils.nullToZero(lead.StayPersons__c) > 0
	            //  2016/12/21 连接plan页面替换标准页面  end by wx  
	                targets.add(lead);
	            }
	        }
        // 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy BEGIN
  		}
  		// 2018/01/26 予約人數が０の場合、登録の明細は見積明細へ反映できない by zy END
        // 自動料金設定する予約データがない場合、処理終了
        if (targets.isEmpty()) return;
        List<BookingEstimateItem__c> updLst = new List<BookingEstimateItem__c> ();
        // 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
        // 处理预约信息数据集合分类
        CommLogicProcess.ProLeadInfo proLead = CommLogicProcess.getProLeadInfo(targets);
        // 2020/07/30 入湯税の自動入力機能について改善 zyz END
        if (!oBookEstLst.isEmpty()){
            for (BookEstItem obj : oBookEstLst) {
                // 商品登録と、有効なデータで登録する
                if (!obj.isValidata) {
                    obj.clear();
                    continue;
                }
                // 予約親予約IDを設定する
                // 商品名称（または券名称）
                obj.sobj.ProductName__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;
                // 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
                if(!CommUtils.isBlank(obj.bTaxToPlanRowIndex)) proLead.proBookEst.proAccMstIdSet.add(obj.sobj.refAccountMaster__c);
                // 2020/07/30 入湯税の自動入力機能について改善 zyz END
                updLst.add(obj.sobj);
                // 2014/08/05 宿泊税自動設定機能外す END
            }
//system.debug(logginglevel.info,'updLst:::' + updLst);
        }
        // 見積明細リストに有効な明細が非存在　OR　旧レイアウトに見積明細非表示の場合
        if (updLst.isEmpty()) {
        	// 料金情報設定用商品が非存在する場合、処理中止
        	if (roomPriceInfo == null) return;
            // これから、料金表設定情報にて、見積もり明細情報を作成する
            // 店舗単位の期間範囲のTier情報を取得する
            String queryRRDetailHeader = ' Select SearchKey__c, Tier__c, ShopInfoRef__c, ShopInfoRef__r.ShopCode__c,PriceSetupDate__c From RackRateTableDetail__c ';
            String queryRRDetailString = queryRRDetailHeader + ' Where PriceSetupDate__c >=:stDate And PriceSetupDate__c <= :edDat ';
            // 店舗条件
            // 2015/09/01 多店舗機能対応 BEGIN
            if (!CommUtils.isBlank(xmlShopCode)) {
                queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c = :xmlShopCode ';
            }else if (userInf.isShopCodePlex) {
                Set<String> shopSt = userInf.shopSt;
                queryRRDetailString += ' And ShopInfoRef__r.ShopCode__c in :shopSt';
            }
            // 2015/09/01 多店舗機能対応 END
            // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
            RackRateUtils.RackDetailUtils rackDetail = RackRateUtils.getRackDetaiInfo(DataBase.query(queryRRDetailString));
            Set<String> tierSet = rackDetail.tierSet;
            // 2018/03/27 店舗なしの不具合改修 BEGIN
            //Id shopId = shopInfoMap.get(xmlShopCode).id;
            Id shopId = (shopInfoMap.containsKey(xmlShopCode)) ? shopInfoMap.get(xmlShopCode).Id : null;
            // 2018/03/27 店舗なしの不具合改修 END
            // 該当期間のTIER設定配列を格納する
            
            // 期間単位のTier情報を取得する
            /*
            Map<Date, String> setupTierMap = new Map<Date, String>();
            Set<String> tierSet = new Set<String>();
            system.debug(logginglevel.info,'queryRRDetailString:::' + queryRRDetailString);
            // 支店コード_日付/TIER
            for (RackRateTableDetail__c detail : DataBase.query(queryRRDetailString)) {
                // 2016/03/29 Tier機能はダミデータは取得表示対象外の対応 BEGIN
                String key = CommUtils.nullToBlank(detail.ShopInfoRef__c) + '_' + detail.PriceSetupDate__c;
                //CommUtils.nullToBlank(branchShopNm) + '_' + detail.PriceSetupDate__c;
                // 存在しているゴミデータを回避するため、検索キーをチェックを追加する
                String searchKey = CommUtils.nullToBlank(detail.SearchKey__c);
                if (!CommUtils.isBlank(searchKey) && searchKey != key) continue;    // ゴミデータは設定しない
                // 2016/03/29 Tier機能はダミデータは取得表示対象外の対応 END
                setupTierMap.put(detail.PriceSetupDate__c, detail.Tier__c);
                tierSet.add(detail.Tier__c);
            }*/
            // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
            // 料金表からDefaultの料金情報を取得する
            Id roomTypeId = newCustomLead.refTypeOfRooms__c;
            
            // 料金表からTier関連金額を取得する
            String defTier = getDefTier(xmlShopCode);
            tierSet.add(defTier);
            // 人数
            String persons = CommUtils.nullToBlank(newCustomLead.StayPersons__c);
            
            // 同じ部屋タイプ、同じTIER、人数で、料金情報を取得する
            List<RackRateTable__c> raceRateMst = [select id, Name,Tier__c, Price__c from RackRateTable__c where RoomTypeRel__c = :roomTypeId And Tier__c in :tierSet And Persons__c = :persons ]; 
            // 同じ部屋タイプ、同じ人数で、各TIER情報を取得する
            Map<String, Decimal> tierMstMap = new Map<String, Decimal>();
            for (RackRateTable__c raceRate : raceRateMst) {
                tierMstMap.put(raceRate.Tier__c,  raceRate.Price__c);
            }
//system.debug(logginglevel.info,'targets:::' + targets);
            List<BookingEstimateItem__c> insertEstItems = new List<BookingEstimateItem__c>();
            for (Lead__c lead : targets) {
                // 到着日
                Date keyDate = lead.EntryTime__c.date();
                // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　BEGIN
                // String tierKey = setupTierMap.containsKey(keyDate) ? setupTierMap.get(keyDate) : defTier;
                String tierKey = rackDetail.getCurTier(keyDate,shopId,roomTypeId);
                if (CommUtils.isBlank(tierKey)) tierKey = defTier;
                // 2018/03/12 ラックレート部屋タイプ別の対応　by　zy　END
                Decimal priceVal = (tierMstMap.containsKey(tierKey) ? tierMstMap.get(tierKey) : 0);
                // 日付から料金情報を取得する
                BookingEstimateItem__c item = new BookingEstimateItem__c(
                    refBooking__c = lead.Id,
                    refAccountMaster__c = roomPriceInfo.Id,
                    Amount__c = newCustomLead.StayPersons__c,
                    UnitPrice__c = priceVal
                );
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
                if(CommLogicProcess.proBathTaxAccMst(proLead, lead, item, staysNums)) continue;
                // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
                insertEstItems.add(item);
            }
            if (!insertEstItems.isEmpty()) insert insertEstItems;
       } else {
            List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
            for (Integer i = 0  ; i < targets.size() ; i++ ){
            	Lead__c lead = targets[i];
                for (BookingEstimateItem__c item : updLst){
                    BookingEstimateItem__c cloneItem = item.clone(false, true);
                    if (cloneItem.ActionType__c == ACTTYPE_AR || cloneItem.ActionType__c == ACTTYPE_PAY) {
                    	if ( i != 0 ) continue;
                    }
                    cloneItem.refBooking__c = lead.Id;
                    // 2020/07/30 入湯税の自動入力機能について改善 WGCH BEGIN
                    if(CommLogicProcess.proBathTaxAccMst(proLead, lead, cloneItem, staysNums)) continue;
                    // 2020/07/30 入湯税の自動入力機能について改善 WGCH END
                    insLst.add(cloneItem);
                }
            }
system.debug(logginglevel.info,'insLst:::' + insLst);
            if (!insLst.isEmpty()) insert insLst;
       }
    }
    private String getDefTier(String shopCd) {
        if (shopInfoMap.containsKey(shopCd)) {
            return  CommUtils.isBLank((shopInfoMap.get(shopCd)).TierDefault__c) 
                    ? CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c )
                    : CommUtils.nullToBlank( (shopInfoMap.get(shopCd)).TierDefault__c );
        } else {
            return CommUtils.nullToBlank( CommDefine__c.getOrgDefaults().RackRateTableTierDefault__c );
        }
    }
    // プラン明細情報を取得する
    @remoteAction
    public static List<ProductItemUtils.PlanDetail> getPlanDetailListById(String planId) {
        return ProductItemUtils.getPlanDetailList(planId);
    }
    // 商品コードにより、会計商品情報を取得する
    @remoteAction
    public static List<ProductItemUtils.ProductItem> getArrayProductItemInfo(String prodCode) {
    	// 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        // return ProductItemUtils.getArrayProdcutItemByCodeOp(prodCode, true, true);
        return ProductItemUtils.getArrayProdcutItemByCodeOp(prodCode, true, true, true);
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    }
    /**
    * 顧客情報最新取得を行う
    **/
    // SOQL顧客情報項目定義
    
    private static final String queryContStr = CommSqlUtils.generateQueryString('Contact');
    //'Select Id, Phone, Name1__c, Name, Memo6__c, Memo5__c, Memo4__c, Memo3__c, Memo2__c, Memo1__c, Katakana__c, KanaName2__c, KanaName1__c,Account.Name,ApplicantName__c,ApplicantPhone__c From Contact ';
    @remoteAction
    public static ContactInfo refreshContcatInfo(String contactId, String contactName) {
        String whereStr = ' where id = \'' + CommUtils.escStr(contactId) + '\' ';
        whereStr += ' And Name = \'' + CommUtils.escStr(contactName) + '\' limit 1';
        List<Contact> contactLst = Database.query(queryContStr + whereStr);
        if (contactLst.isEmpty()) {
            return new ContactInfo(new Contact());
        } else {
            return new ContactInfo(contactLst[0]);
        }
    }
    public class ContactInfo {
        public ContactInfo(Contact c){
            KanaName = CommUtils.nullToBlank(c.KanaName1__c);
            KatakanaName = CommUtils.nullToBlank(c.Katakana__c);
            phone = CommUtils.nullToBlank(c.Phone);
            contact = c;
        }
        public String KanaName{get;set;}    // カタカナ
        public String KatakanaName{get;set;} //ひらがな、
        public String phone{get;set;}       // Phone
        public Contact contact{get;set;}
    }
    // 2016/06/05 編集できる項目一覧を戻る BEGIN
    /*
    public Map<String, Schema.DescribeFieldResult> getAllFieldLst(SObjectType objectType, Boolean isCanWrite) {
        // 設定情報を取得
        Schema.DescribeSObjectResult d = objectType.getDescribe();
        //return descResult.fields.getMap().keySet();
        Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
        // 戻る値変数を初期化する
        Map<String, Schema.DescribeFieldResult> fieldsDescMap = new map<String, Schema.DescribeFieldResult> ();
        for(String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult sField = fieldsMap.get(fieldName).getDescribe();
            if (isCanWrite && !sField.isCreateable()) continue;
            // 2016/06/14 NSは項目APIに追加して、Localのカスタマイズ項目と同じAPI名を回避するため BEGIN
            String locFieldName = sField.getLocalName();
            if (fieldsDescMap.containsKey(locFieldName)) {
                // 既存のAPIのFULLNAME確認する
                Schema.DescribeFieldResult preField = fieldsDescMap.get(locFieldName);
                // PackageのAPIとLocalのAPI名は一致存在する場合
                String preFullFieldName = preField.getName();
                // 一致しない場合、既に格納しているAPIはPACKAGEのAPI項目です
                if (preFullFieldName != locFieldName) {
                    // PACKAGE項目はFULLNAMEで設定する
                    fieldsDescMap.put(preFullFieldName, preField);
                    // LOCALのカスタマイズ項目は格納する
                    fieldsDescMap.put(locFieldName, sField);
                } 
                // 一致場合、既存のAPIはLOCALのカスタマイズAPI項目です
                else {
                    String currFullFieldName = sField.getName();
                    // FullNameでPackage項目を格納する
                    fieldsDescMap.put(currFullFieldName, sField);
                }
            } else {
                fieldsDescMap.put(locFieldName, sField);
            }
        }
        return fieldsDescMap;
    }
    */
    // 2016/06/05 編集できる項目一覧を戻る END
    
    // ****************************
    // すでに設定済み明細一覧情報を取得する
    // leadId:リードID
    public List<BookEstItem> oBookEstLst{get; private set;}
    // 2019/07/30 軽減税率機能対応 WGCH BEGIN
    public Boolean isReducedTaxFlg{get{ return CommConst.REDUCED_TAXRATE_FLG;} set;}
    // 2019/07/30 軽減税率機能対応 WGCH END
    // 見積もり明細行目追加
    // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix BEGIN
    //public Pagereference addBookingItem() {
    public void addBookingItem() {
system.debug(logginglevel.info,'oBookEstLst:::' + oBookEstLst.size());
		if(CommUtils.isBlank(curRows)){
			system.debug(logginglevel.info,'curRows:::' + curRows);
    		if (oBookEstLst.size() > LIST_INPUT_DEF_ROWS) {
    			List<BookEstItem> orgBookingLst = new List<BookEstItem>();
	            for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
	            	orgBookingLst.add(oBookEstLst[i]);
	            }
	            oBookEstLst = orgBookingLst;
	            curRows = String.valueOf(LIST_INPUT_DEF_ROWS);
	        }
    		
    	}
    	refreshBookingOrder();
    	//2017/01/16 行追加共通化　by　zy BEGIN
        // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
    	Integer addInputRows = LIST_INPUT_DEF_ROWS;
    	// 2020/06/01 6438 bug fix BY zyz BEGIN
        if(addRowsMan != null && addRowsMan != 0) {
        	if(addInputRows >= addRowsMan) addRowsMan = LIST_INPUT_DEF_ROWS;
        	addInputRows = Math.Ceil(addRowsMan/LIST_INPUT_DEF_ROWS).intValue() * LIST_INPUT_DEF_ROWS;
        }
        // 2020/06/01 6438 bug fix BY zyz END
        addRowsMan = null;
    	// for (Integer i = 0; i < LIST_INPUT_DEF_ROWS; i++) {
    	for (Integer i = 0; i < addInputRows; i++) {
    	// 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
	    	BookEstItem estItem = new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size());
	    	estItem.addRowStr = 'rowStr';
	        oBookEstLst.add(estItem);
	        curRows = String.valueOf(CommUtils.nullToIntZero(curRows)+1);
    	}
		//2017/01/16 行追加共通化　by　zy END
        system.debug(logginglevel.info,'oBookEstLst:::' + oBookEstLst.size());
        //oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(),oBookEstLst.size()));
        //return null;
    }
    private void refreshBookingOrder(){
    	// 2016/10/26 顺序保持 fix BEGIN
		Map<Integer, BookEstItem> locSortMap = new Map<Integer, BookEstItem>();
		for (BookEstItem item : oBookEstLst) {
			system.debug(logginglevel.info,'item.sobj.rowNo__c:::' + item.sobj.rowNo__c);
			// 画面表示順により、ソートを行う
			locSortMap.put(CommUtils.nullToIntZero(item.sobj.rowNo__c),item);
		}
		List<Integer> sortKeyLst = new List<Integer>();
		sortKeyLst.addAll(locSortMap.keySet());
		sortKeyLst.sort();
		system.debug(logginglevel.info,'sortKeyLst:::' + sortKeyLst);
		oBookEstLst.clear();
		//RowIndex再設定する BEGIN
		for (Integer key : sortKeyLst) {
			BookEstItem orgItem = locSortMap.get(key);
			if ( LIST_INPUT_DEF_ROWS > oBookEstLst.size()) orgItem.addRowStr = '';
			else orgItem.addRowStr = 'rowStr';
			orgItem.index = oBookEstLst.size();
			oBookEstLst.add(orgItem);
		}
		//RowIndex再設定する END
		// 2016/10/26 顺序保持 fix END	
    }
    // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix END
    // 見積書の宛名
    // 会計種別：プラン
    public String ACTTYPE_PLAN{get{return CommConst.PROD_ACTION_TYPE_PL;}}
    public String ACTTYPE_PAY{get{return CommConst.PROD_ACTION_TYPE_PY;}}   // 支払
    public String ACTTYPE_AR {get{return CommConst.PROD_ACTION_TYPE_AR;}}   // 前受金
    // 支払メディア種別
    public String MEDIA_TYPE_COPON      {get{return CommConst.MEDIA_TYPE_11;}}
    public String MEDIA_TYPE_DISCOUNT   {get{return CommConst.MEDIA_TYPE_12;}}
    // 2015/12/24 入金確認自動チェック制御機能の追加
    public Boolean isAccountPaidFlg{get{return CommDefine__c.getOrgDefaults().AccountPaidFlg__c;}}
    // 見積明細情報格納
    public class BookEstItem {
        // 初期化する
        public BookEstItem(BookingEstimateItem__c s, Integer rsIndex) {
			// 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix BEGIN
			addRowStr = '';
			// 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix END
            sobj = s;
            index = rsIndex;
            rowNo = String.valueOf(rsIndex);
            s.rowNo__c = rsIndex;
            // 商品名
            productNm = CommUtils.isBlank(sobj.ProductName__c) ? s.refAccountMaster__r.Name : sobj.ProductName__c;
            orgProductNm = s.refAccountMaster__r.Name;
            // 数量
            //prodNums = s.Amount__c;
            prodNums = CommUtils.deleteRightZero(CommUtils.nullToBLank(s.Amount__c));
            // 単価
            unitPrice = CommUtils.deleteRightZero(CommUtils.nullToBLank(s.UnitPrice__c), CommUtils.getPointLen());
            //2017/03/13 特別税fix by zy BEGIN
            //String specialTasStr = CommUtils.deleteRightZero( CommUtils.nullToZero(s.SpecialTax__c).format(), CommUtils.getPointLen());
            //2017/03/13 特別税fix by zy END
            // 特別税
            //specialTax = CommUtils.isBlank(specialTasStr) ? null : CommUtils.nullToZero(specialTasStr);
            // 合計金額（税込）
            amoutIncTax = s.SpTotal__c;
            // == null ? 0 : CommUtils.nullToZero(s.SpTotal__c);
            // 合計金額（税抜）
            amoutExcTax = s.GoukeinoneTax__c == null ? null : s.GoukeinoneTax__c;
            //if (s.id == null) clear();
            isPlanProduct = false;
            itemId = s.Id;
            leadId = s.refBooking__c;
            // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 BEGIN
            if (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {  
                initPlanInfo = 0;
                // 既存の会計明細情報を取得する
                //for (Tran1__c sobj: sobj.ParentTran1Ref__r) {
                    //initPlanInfo += CommUtils.nullToZero(sobj.Field20__c);
                //}
            }
            // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 END
        }
        public void clear() {
            productNm = null;
            servicePriceIncTax = null;
            specialTax = null;
            prodNums = null;
            amoutExcTax = null;
            amoutIncTax = null;
        }
        // 見積明細格納する
        public BookingEstimateItem__c sobj{get; private set;}
        // 明細Index
        public Integer index{get; private set;}
        // 
        public String itemId{get; set;}
        public String leadId{get; set;}
        // 商品名
        public String productNm{get;set;}
        // 会計商品マスタの商品名
        public String orgProductNm{get;set;}
        // サービス料金(税込)
        public Decimal servicePriceIncTax{get;set;}
        //2017/03/13 特別税fix by zy BEGIN
        // 特別料金
        //public Decimal specialTax;
        public Decimal specialTax{get{
			if (sobj.SpecialTax__c == null) return null;
			String specialTasStr = CommUtils.deleteRightZero( CommUtils.nullToZero(sobj.SpecialTax__c).format(), CommUtils.getPointLen());
			return CommUtils.nullToZero(specialTasStr);}set;}
       	//2017/03/13 特別税fix by zy END
        public String rowNo{get;set;}
        // 単価
        public String unitPrice{get;set{
            unitPrice = value;
            sobj.UnitPrice__c = CommUtils.nullToZero(unitPrice);
        }}
        // 数量
        public String prodNums{get;set{
            prodNums = value;
            sobj.Amount__c = CommUtils.nullToZero(prodNums);
            }}
        // 会計明細単位の合計金額（税抜）
        public Decimal amoutExcTax{get; set;}
        // 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
            amoutIncTax = value;
            if (value !=null && value != sobj.SpTotal__c) sobj.SpTotal__c = value;}}
        public Boolean isValidata{get{
            // 商品コード != null && 単価 != null && 数量 != null
            return (!CommUtils.isBlank(sobj.refAccountMaster__c) &&
                    sobj.UnitPrice__c != null &&
                    sobj.Amount__c != null);
        }}
        // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 BEGIN
        public Decimal initPlanInfo{get; set;}
        // 2015/11/11 プラン明細課税、非課税混在合計金額計算対応 END
        public Boolean isPlanProduct{get{return (sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_PL ? true : false);} set;}
        // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix BEGIN
        public String addRowStr{get; set;}
        // 2016/10/24 点击行追加→点击cancel→再次打开新规窗口→見積明細恢复初始行数 fix END
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
		public String gOptionInfoJson{get {if(gOptionInfoJson == null) gOptionInfoJson = ''; return gOptionInfoJson ;} set;}
		public Boolean isSetOptionFlg{get {if(isSetOptionFlg == null) isSetOptionFlg = false; return isSetOptionFlg ;} set;}
		public Boolean showDetailFlg{get {if(showDetailFlg == null) showDetailFlg = false; return showDetailFlg ;} set;}
		public String key{get {if(key == null) key = ''; return key ;} set;}
		public String nwOrderNums{get {if(nwOrderNums == null) nwOrderNums = '1'; return nwOrderNums ;} set;}
		// 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
		// 2020/07/30 入湯税の自動入力機能について改善 zyz BEGIN
		public String bTaxAccMstId{get {if(bTaxAccMstId == null) bTaxAccMstId = ''; return bTaxAccMstId;} set;}
		public String bTaxToPlanRowIndex{get {if(bTaxToPlanRowIndex == null) bTaxToPlanRowIndex = ''; return bTaxToPlanRowIndex;} set;}
		// 2020/07/30 BUG-FIX-#7106 WGCH BEGIN
		public String oldOrderNums{get {if(oldOrderNums == null) oldOrderNums = '1'; return oldOrderNums ;} set;}
		// 2020/07/30 BUG-FIX-#7106 WGCH END
		// 2020/07/30 入湯税の自動入力機能について改善 zyz END
    }
    /**
    * 会計商品情報を取得
    **/
    @remoteAction
    public static ProductItemUtils.ProductItem getProductItemInfo(String prodCode) {
        return ProductItemUtils.getSingProdcutItemByCode(prodCode);
    }
    @remoteAction
    public static List<ProductItemUtils.ProductItem> getArrayProductItemInfoNoPlan(String prodCode) {
        return ProductItemUtils.getArrayProdcutItemByCode(prodCode, true);
    }
    // 商品コードにより、会計商品情報を取得する
    @remoteAction
    public static List<ProductItemUtils.ProductItem> getArrayProductDetailItemInfo(String prodCode) {
        // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
        /*
        // 2017/10/17 商品情報店舗別を検索を行う by zh END
        // 検索SQL取得
		String queryStr = CommSqlUtils.generateQueryString('AccountMaster__c',new String[]{'(Select AccountMasterRef__c, Price__c, TaxRate__c ,AccountMasterRef__r.ActionType__c From PlanProdcutRef__r where TaxRate__c = 0 or TaxRate__c = null)'});
		//queryStr += ' Where BasePlanFlg__c = false And IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And Field3__c like \'' + CommUtils.escStr(prodCd) + '%\'';
		queryStr += ' Where IsClosed__c != true And ActionType__c != \'' + CommUtils.escStr(CommConst.PROD_ACTION_TYPE_NO) + '\' And ( Field3__c like \'' + CommUtils.escStr(prodCode) + '%\' OR Name like \'' + CommUtils.escStr(prodCode) + '%\') ' ;
		
		queryStr += ' order by Field4__c,OP__c, Field3__c ';
		//queryStr += ' limit 1000 '; 
		// 商品情報を検索を行う
		List<AccountMaster__c> accMstLst = Database.query(queryStr);
		if (accMstLst.isEmpty()) {
			return new List<ProductItemUtils.ProductItem>();
		}
		Set<Id> accIdSet = new Set<Id>();
		for (AccountMaster__c ac : accMstLst) {
			accIdSet.add(ac.id);
		} 
		set<Id> hadRoomFlagSet = new Set<id>();
		for (PlanDetail__c detail : [Select AccountMasterRef__c, Price__c, TaxRate__c,PlanProdcut__c,AccountMasterRef__r.ActionType__c From PlanDetail__c  where  PlanProdcut__c = :accIdSet]){
        	AccountMaster__c acc = new AccountMaster__c(ActionType__c = detail.AccountMasterRef__r.ActionType__c);
        	if (RackRateUtils.isRoomRateProduct(acc)){
        		if (CommUtils.nullToZero(detail.Price__c) == 0){
        			if (!hadRoomFlagSet.contains(detail.PlanProdcut__c))
        				hadRoomFlagSet.add(detail.PlanProdcut__c);
        		}
        	}
        }
		List<ProductItemUtils.ProductItem> items = new List<ProductItemUtils.ProductItem>();
		for (AccountMaster__c ac : accMstLst) {
			ProductItemUtils.ProductItem p = new ProductItemUtils.ProductItem(ac);
			if (hadRoomFlagSet.contains(ac.id)) p.hadRoomFlag = true;
			items.add(p);
		}
        
//system.debug(logginglevel.info,'items:::' + items);
        return items;
        // 2017/10/17 商品情報店舗別を検索を行う by zh BEGIN
        */
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        // return ProductItemUtils.getArrayProdcutItemByCode(prodCode, false, false);
        return ProductItemUtils.getArrayProdcutItemByCodeOp(prodCode, false, false, true);
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        // 2017/10/17 商品情報店舗別を検索を行う by zh END
    }
    // プラン関連の商品明細を取得する
    // accId:会計ID/会計商品（プラン）ID
    /**
    * planId : プランID
    * tierPrice　: tier 
    * rateFLagStr : true 室料設定、false 自動计算
    **/
    @RemoteAction
    public static List<PlanDetail> getAccountMstLstByPlan(String planId,String tierPrice) {
        // 会計IDが存在する場合、既に登録された登録情報から情報を展開する
        // 会計IDが非存在場合、
        List<PlanDetail> rsLst = new List<PlanDetail>();
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        // List<PlanDetail__c> detailLst = [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c from PlanDetail__c where PlanProdcut__c = :planId];
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        // List<PlanDetail__c> detailLst = [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c,ServiceRate__c from PlanDetail__c where PlanProdcut__c = :planId];
        List<PlanDetail__c> detailLst = [select AccountMasterRef__c, AccountMasterRef__r.name, AccountMasterRef__r.ActionType__c,Price__c,TaxRate__c,ServiceRate__c,OptionAccMstFLG__c from PlanDetail__c where PlanProdcut__c = :planId];
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
        // 2019/07/30 軽減税率機能対応 WGCH END
        Decimal tierPriceDec = CommUtils.nullToZero(tierPrice);
        for (PlanDetail__c pd : detailLst) {
            PlanDetail item = new PlanDetail();
            AccountMaster__c acc = new AccountMaster__c(ActionType__c = pd.AccountMasterRef__r.ActionType__c);
            Decimal roomPrice = pd.Price__c;
            if (tierPriceDec > 0 ){
	            if (RackRateUtils.isRoomRateProduct(acc)){
	                if (!CommUtils.isBlank(tierPrice) && roomPrice == 0) 
	                    roomPrice = tierPriceDec;
	            }
            }
//system.debug(logginglevel.info,'roomPrice：：：'  + roomPrice); 
            item.prodPrice = CommUtils.deleteRightZero(CommUtils.nullToZero(roomPrice).format(), CommUtils.getPointLen());
            item.prodName = CommUtils.nullToBlank(pd.AccountMasterRef__r.name);
            //item.prodPrice = CommUtils.nullToZero(pd.Price__c).format();
            item.sobjId = pd.Id;
            item.prodId = pd.AccountMasterRef__c;
            item.planId = pd.Id;
            item.actionType = pd.AccountMasterRef__r.ActionType__c;
            item.prodTaxRate = CommUtils.nullToZero(pd.TaxRate__c);
            // 2019/07/30 軽減税率機能対応 WGCH BEGIN
            item.prodServiceRate = CommUtils.nullToZero(pd.ServiceRate__c);
            // 2019/07/30 軽減税率機能対応 WGCH END
            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
            item.optionAccMstFlg = pd.OptionAccMstFLG__c == null ? false : pd.OptionAccMstFLG__c;
            // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
            rsLst.add(item);
        }
        return rsLst;
    }
    // プラン明細情報を維持する
    public class PlanDetail {
        public String prodName{get; set;}
        public String prodPrice{get; set;}
        public String sobjId{get;set;}
        public String prodId{get;set;}
        public String planId{get;set;} // プラン明細ID
        public String actionType{get;set;}
        public Decimal prodTaxRate;
        // 2019/07/30 軽減税率機能対応 WGCH BEGIN
        public Decimal prodServiceRate;
        // 2019/07/30 軽減税率機能対応 WGCH END
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH BEGIN
        public Boolean optionAccMstFlg{get;set;}
        // 2020/05/29 エステなど商品を追加したプラン機能 WGCH END
    }
    //2017/03/01 お客様項目タイプ対応　by　zy　BEGIN
    //お客様項目タイプ
    public String contactFieldType{get;set;}
    /*
	* 判断字段是否是特殊类型
	*/
	private String checkAndAddFiledName(Schema.DescribeFieldResult dr, String  mapFields){
		system.debug(logginglevel.info,'dr.getType():::' + dr.getType());
		if(dr.getType() == DisplayType.Date){
			mapFields += dr.getName() + ':' +  'Date,';
		} else if(dr.getType() == DisplayType.DateTime) {
			mapFields += dr.getName() + ':' +  'DateTime,';
		} else if(dr.getType() == DisplayType.textarea){ 
			mapFields += dr.getName() + ':' +  'TextArea,';
		} 
		else if(dr.getType() == DisplayType.Boolean){ 
			mapFields += dr.getName() + ':' +  'Boolean,';
		// 2017/03/01 お客様关联的自定义字段更新 Fix by zh BEGIN
		} else
			mapFields += dr.getName() + ':' +  ',';
		// 2017/03/01 お客様关联的自定义字段更新 Fix by zh END
		return mapFields;
	}
	//2017/03/01 お客様項目タイプ対応　by　zy　END
    // 2019/04/30 増税仮対応 WGCH BEGIN
    // 增税商品json数据 
    public String taxIncMstItemJson{get { return CommLogicProcess.getTaxIncMstJson();} private set;}
    // 2019/04/30 増税仮対応 WGCH END
    // 2019/06/14 4.2.予約ポップからベースプランを選択した状態で新規予約作成をすると、予約見積明細に該当のプランが登録された状態で予約を取ることができますが、 by zy BEGIN
    public String basePlanId{get;set;}
    // 2019/06/14 4.2.予約ポップからベースプランを選択した状態で新規予約作成をすると、予約見積明細に該当のプランが登録された状態で予約を取ることができますが、 by zy END
        // 2019/10/02 PlanHeader算法切换对应 WGCH BEGIN
	public static boolean planBrkToHeaderCalFlg{get{ return CommConst.PLAN_BRKTOHEADER_CAL_FLG;} private set;}
	// 2019/10/02 PlanHeader算法切换对应 WGCH END
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH BEGIN
    public Integer addRowsMan{get;set;}
    public Boolean isBasePlanFlag{get;set;}
    // 2020/04/30 複数のプランとそれぞれのプランの人数を選択し機能対応 WGCH END
}