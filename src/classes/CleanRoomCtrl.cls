public with sharing class CleanRoomCtrl {
	// 部屋リスト
	public List<AreaInfo> areaInfLst{get;set;}
	// 設定INFO
	public String settingInfoJson{get;set;}
	// 状態とカラーJSON
	public static String cleanLstJson{get;set;}
	// 状態とカラーリスト
	public static List<String> statsLst{get;set;}
	// 店舗コード
	public String branchShopNm{get;set;}
	// 店舗名
	public String curShopName{get;set;}
	// 支店選択リスト
    public List<SelectOption> branchShopLst{get; private set;}
	// 部屋タイプリスト情報
	public List<SelectOption> roomTypeLst{get; private set;}
	// 編集不能フラグ
	public boolean isEditFlag{get;set;}
	// デファルトカラー対応関係
	private static Map<String,String> colorMap = new Map<String,String>();
	private static Set<String> completeStatus;
	// COOKIE設定
	private SettingInfo setInfo;
	// ユーザ情報
	private UserUtil.UserShopInfo userInf;
    public CleanRoomCtrl(){
    	// 初期化
    	initInfo();
    }
    // 画面初期化
    public void init(){
    	doAction();
    }
    public void gotoDate(){
    	// 更新COOKI店舗コード
    	saveCookieSetting(settingInfoJson,UserConfigCompCtrl.KREP_SUBTYPE.SEISOUSPCD.name(),'');
    	doAction();
    }
    // 初期化
    private void initInfo(){
    	branchShopNm = '';
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
		lead = new Lead__c();
		contact = new Contact();
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
    	// 当前ユーザ情報取得
    	userInf = UserUtil.CurrentUserInfo;
    	// ロール設定
    	Boolean profileAuth = true;
    	Boolean userAuth = userInf.u.NoEditCleanStatusFlg__c == false;
    	AuthSetupDef__c authSetup = CommSecurityUtils.getAuthInstance();
    	if (authSetup.id != null) {
    		profileAuth = authSetup.NoEditCleanStatusFlg__c == false;
    		// どちらが権限ある場合、権限ある
    		isEditFlag = (userAuth || profileAuth);
    	} else {
    		// プロファイルの権限設定ない場合、ユーザの権限により設定を行う
    		isEditFlag = userAuth;
    	}
    }
    private void doAction(){
    	// 店舗リスト情報を取得する
    	setInitBranShopLst();
    	// cookie設定
    	cookieSetInfo();
    	// ドキュメント設定処理
    	documentLoad(branchShopNm);
    	// 部屋タイプリスト
    	setInitRoomTypeLst();
    	//　清掃状態取得
    	queryCleanStatus();
    	// 部屋情報取得
    	queryRoomStatus();
    	
    }
    // 該当状態の場合、Chatterグループへ送信メッセージ内容
    // map<グループ名、メッセージ内容>
	private	static Map<String,String> groupToMsgMap;
	// 該当状態の場合、ポスト対象グループ名
	// map<ステータス名、set<グループ名>
	private static Map<String,set<String>> statusGroupMap;
	// グループと関連のID情報を格納する
	private static Map<String, Id> groupNmToIdMap;
	// 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
	public static List<CheckPanel> checkList{get;set;}
	public static RoomsStatus__c roomStatus{get;set;}
	// 2018/08/02 清掃チェックリスト機能追加 by zy END
    // 店舗既存設定取得
    private static void documentLoad(String spcd){
		// 2019/12/15 部屋ステータスの一括更新不要 by zy BEGIN
		quickActionFlg = false;
		// 2019/12/15 部屋ステータスの一括更新不要 by zy END
    	try{
    		groupToMsgMap = new Map<String,String>();
    		statusGroupMap = new Map<String,set<String>>();
    		groupNmToIdMap = new Map<String, Id>();
    		completeStatus = new Set<String>();
    		// 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
    		checkList = new List<CheckPanel>();
    		roomStatus = new RoomsStatus__c();
    		// 2018/08/02 清掃チェックリスト機能追加 by zy END
    		Dom.XMLNode targetNode = CommXmlUtils.parseXmlDoc('CleanRoomConfig',spcd);
    		if (targetNode != null) {
    			//完了状態
	        	Dom.XmlNode completeNode =  targetNode.getChildElement('COMPLETESTATUS', null);
	        	if (completeNode != null) {
	        		completeStatus = new Set<String>();
	        		String[] comStatlist = CommUtils.nullToBlank(completeNode.getText()).split(',');
	        		for (String s : comStatlist) if (!CommUtils.isBlank(s)) completeStatus.add(CommUtils.nullToBlank(s));
	        	}
	        	//カラー設定
	        	Dom.XmlNode colorNode =  targetNode.getChildElement('COLORCONFIG', null);
	        	if (colorNode != null) {
	        		for (Dom.XmlNode color : colorNode.getChildElements()) {
	        			if (color != null) {
	        				String name = CommUtils.nullToBlank(color.getText());
	        				String colorStr = CommUtils.nullToBlank(color.getAttribute('COLOR',null));
	        				if (!CommUtils.isBlank(colorStr)) colorMap.put(name,colorStr);
	        			}
	        		}
	        	}
	        	//通知設定
	        	Dom.XmlNode chatterNode =  targetNode.getChildElement('CHATERCONFIG', null);
	        	if (chatterNode != null) {
	        		for (Dom.XmlNode chatter : chatterNode.getChildElements()) {
	        			if (chatter != null) {
	        				String name = CommUtils.nullToBlank(chatter.getText());
	        				String gpName = CommUtils.nullToBlank(chatter.getAttribute('GROUP',null));
	        				String message = CommUtils.nullToBlank(chatter.getAttribute('MESSAGE',null));
	        				// 設定情報が不正の場合、処理SKIP
	        				if (CommUtils.isBlank(name) || CommUtils.isBlank(gpName) || CommUtils.isBlank(message)) continue;
	        				groupToMsgMap.put(gpName,message);
							// 状態と関連の定義情報を設定する
        					List<String> statusName = name.split(',');
	        				for (String status : statusName) {
	        					status = CommUtils.nullToBlank(status);
	        					if (CommUtils.isBlank(status)) continue;
	        					if (!statusGroupMap.containsKey(status)) statusGroupMap.put(status,new set<string>());
	        					statusGroupMap.get(status).add(gpName);
	        				}
	        			}
	        		}
//system.debug(logginglevel.info,'spcd:::' + spcd);
					if (!groupToMsgMap.isEmpty()) {
						List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :groupToMsgMap.keyset() and isarchived = false];
						for(CollaborationGroup gp : chatterGroups) {
							groupNmToIdMap.put(gp.name,gp.id);
						}
	        		}
	        	}
	        	// 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
	        	//チェックリスト設定
	        	Dom.XmlNode checkNode =  targetNode.getChildElement('CHECKCONFIG', null);
				// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
	        	Map<String, Schema.DescribeFieldResult> rsDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(RoomsStatus__c.sObjectType,false,true);
				Map<String, Schema.DescribeFieldResult> leadDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true);
				Map<String, Schema.DescribeFieldResult> contactDeafaultValuesMaps = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true);
				String leadPrfix = 'lead.';
				String contactPrfix = 'contact.';
				// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
				// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy BEGIN
				Set<Decimal> typeSeqSet = new Set<Decimal>();
				// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy END
	        	if (checkNode != null) {
	        		for (Dom.XmlNode checklistNode : checkNode.getChildElements()) {
	        			if (checklistNode != null) {
							// 2020/06/30 6891 bug fixed by zy BEGIN
							Map<String,String> roomTypeFieldsMap = new Map<String,String>();
							// 2020/06/30 6891 bug fixed by zy END
	        				String status = '';
	        				String fieldStr = '';
	        				String nextStatus = '';
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
							String messageStr = '';
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
	        				Dom.XmlNode stausNode = checklistNode.getChildElement('STATUS',null);
	        				if (stausNode != null) {
	        					status = CommUtils.nullToBlank(stausNode.getText());
	        				}
	        				Dom.XmlNode nextNode = checklistNode.getChildElement('NEXTSTATUS',null);
	        				if (nextNode != null) {
	        					nextStatus = CommUtils.nullToBlank(nextNode.getText());
	        				}
							// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy BEGIN
							String roomType = '';
							for (Dom.XmlNode checklistTagNode : checklistNode.getChildElements()) {
								String nodeName = checklistTagNode.getName();
								if (nodeName == 'FIELDS') {
									String roomSeq = CommUtils.nullToBlank(checklistTagNode.getAttribute('ROOMTYPESEQ',null));
									String fieldContent = CommUtils.nullToBlank(checklistTagNode.getText()).deleteWhitespace().tolowerCase().trim();
									if (CommUtils.isBlank(fieldStr) || CommUtils.isBlank(roomSeq)) {
										fieldStr = fieldContent;
										roomType = roomSeq;
									}
									if (!CommUtils.isBlank(roomSeq)) {
										for (String seqStr : roomSeq.split(',')) typeSeqSet.add(COmmUtils.nullTOZero(seqStr));
										roomTypeFieldsMap.put(roomSeq,fieldContent);
									}
								}
							}
							/*
	        				Dom.XmlNode fieldsNode = checklistNode.getChildElement('FIELDS',null);
	        				if (fieldsNode != null) {
	        					fieldStr = CommUtils.nullToBlank(fieldsNode.getText()).deleteWhitespace().tolowerCase().trim();
	        				}*/
							// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy END
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
							List<PageCustomeFieldHelper.CusField> customLst = new List<PageCustomeFieldHelper.CusField>();
							Dom.XmlNode messageNode = checklistNode.getChildElement('MESSAGE',null);
	        				if (messageNode != null) {
	        					messageStr = CommUtils.nullToBlank(messageNode.getText()).deleteWhitespace().tolowerCase().trim();
								Set<String> exitSet = new Set<String>();
								for (String field : messageStr.split(',')){
									if (exitSet.contains(field)) continue;
									if (field.contains(leadPrfix)){
										Schema.DescribeFieldResult dr = leadDeafaultValuesMaps.get(field.replace(leadPrfix,''));
										if (dr == null) continue;
										customLst.add(new PageCustomeFieldHelper.CusField(dr,false,null,'lead',null));
									} else if (field.contains(contactPrfix)) {
										Schema.DescribeFieldResult dr = contactDeafaultValuesMaps.get(field.replace(contactPrfix,''));
										if (dr == null) continue;
										customLst.add(new PageCustomeFieldHelper.CusField(dr,false,null,'contact',null));
									}
									exitSet.add(field);
								}
	        				}
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
	        				if (!CommUtils.isBlank(status) && !CommUtils.isBlank(fieldStr)) {
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
	        					CheckPanel ckp = new CheckPanel(status,nextStatus,fieldStr,rsDeafaultValuesMaps);
								// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
								// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy BEGIN
								ckp.roomTypes = roomType;
								roomTypeFieldsMap.remove(roomType);
								// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy END
	        					if (!ckp.fieldlst.isEmpty()) checkList.add(ckp);
	        				}
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
							if (!customLst.isEmpty()) checkList[checkList.size() - 1].otherLst = customLst;
							// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
							// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy BEGIN
							if (!roomTypeFieldsMap.isEmpty()) {
								for (String roomSeq : roomTypeFieldsMap.keySet()) {
									CheckPanel childCkp = new CheckPanel(status,nextStatus,roomTypeFieldsMap.get(roomSeq),rsDeafaultValuesMaps);
									childCkp.roomTypes = roomSeq;
									childCkp.otherLst = customLst;
									checkList.add(childCkp);
								}
							}
							// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy END
	        			}
	        		}
	        	}
	        	// 2018/08/02 清掃チェックリスト機能追加 by zy END
				// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy BEGIN
				if (!typeSeqSet.isEmpty()) {
					Map<Decimal,String> seqTypeIdMap = new Map<Decimal,String>();
					for (TypeOfRooms__c rtype : [select id,seq__c from TypeOfRooms__c where seq__c in :typeSeqSet]) {
						seqTypeIdMap.put(CommUtils.nullTOZero(rtype.seq__c),rtype.id);
					}
					if (!seqTypeIdMap.isEmpty()) {
						for (CheckPanel chk : checkList) {
							String roomTypes = CommUtils.nulltoblank(chk.roomTypes);
							List<String> roomKey = new List<String>();
							if (!CommUtils.isBlank(roomTypes)){
								for (String typeStr : roomTypes.split(',')) {
									Decimal typeSeq = CommUtils.nullToZero(typeStr);
									if (seqTypeIdMap.containsKey(typeSeq)) roomKey.add(seqTypeIdMap.get(typeSeq));
								}
							}
							chk.roomTypes = String.join(roomKey,',');
						}
					}
				}
				// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy END
				// 2019/12/15 部屋ステータスの一括更新不要 by zy BEGIN
				//一括設定フラグ
	        	Dom.XmlNode quickNode =  targetNode.getChildElement('QUICKACTION', null);
				if (quickNode != null) {
					quickActionFlg = boolean.valueOf(CommUtils.nullToBlank(quickNode.getText()));
				}
				// 2019/12/15 部屋ステータスの一括更新不要 by zy END
    		}
    	}catch(exception e) {}
    	// 未設定完了状態→最後状態
    	if (completeStatus.isEmpty()) {
    		List<Schema.PicklistEntry> ple = RoomsStatus__c.CleanStatus__c.getDescribe().getPicklistValues();
    		completeStatus.add(ple[ple.size() - 1].getValue());
    	}
    }
    // 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
    class CheckPanel{
    	public String status{get;set;}
    	public String nextStatus{get;set;}
    	public List<PageCustomeFieldHelper.CusField> fieldlst{get;set;}
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
		public List<PageCustomeFieldHelper.CusField> otherLst{get;set;}
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
		// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy BEGIN
		public String roomTypes{get;set;}
		// 2020/06/30 清掃チェック項目を部屋タイプ毎に設定できるように by zy END
    	public CheckPanel(String cleanStatus,String nextCleanS,String fieldStr,Map<String, Schema.DescribeFieldResult> leadDeafaultValuesMaps){
    		status = cleanStatus;
    		nextStatus = nextCleanS;
    		fieldlst = new List<PageCustomeFieldHelper.CusField>();
    		List<String> fileds = fieldStr.split(',');
	    	Set<String> querySet = new Set<String>();
	    	Set<String> excludeSet = new Set<String>{'isstocksynctarget__c','ps__isstocksynctarget__c'};
	    	// 添加参照字段显示信息
	    	for (String fieldName : fileds) {
	    		if (CommUtils.isBlank(fieldName)) continue;
	    		if (querySet.contains(fieldName)) continue;
	    		if (excludeSet.contains(fieldName)) continue;
	    		if (!leadDeafaultValuesMaps.containsKey(fieldName)) continue;
	    		PageCustomeFieldHelper.CusField field = new PageCustomeFieldHelper.CusField();
	    		if (leadDeafaultValuesMaps.containsKey(fieldName)) {
	    			Schema.DescribeFieldResult dr = leadDeafaultValuesMaps.get(fieldName);
	    			if (dr.getType() == DisplayType.Boolean) {
	    				field = new PageCustomeFieldHelper.CusField(dr,false,'','','lead');
	    				querySet.add(fieldName);
	    			}
	    		}
	    		fieldlst.add(field);
	    	}
    	}
    }
    // 2018/08/02 清掃チェックリスト機能追加 by zy END
    // cookie設定
    private void cookieSetInfo(){
    	String cookidSpcd = getCookieShopcd();
    	// 該当COOKIE店舗コード有効チェック
        if (cookidSpcd != null) {
        	for (SelectOption s : branchShopLst) {
        		if (s.getValue() == cookidSpcd) branchShopNm = cookidSpcd;
        	}
        }
        settingInfoJson = '';
    	// Cookieからレイアウトモードを取得する
        String cookieSetInfo = getCookieSetting();
        if (!CommUtils.isBlank(cookieSetInfo)) {
        	setInfo = (SettingInfo)JSON.deserializeStrict(cookieSetInfo,SettingInfo.class);
        	settingInfoJson = JSON.serialize(setInfo);
        }
        curShopName = '';
        try{
        	curShopName = ShopInfoUtil.getShop(branchShopNm).name;
        }catch(exception e) {
        	
        }
    }
    // 部屋タイプリスト
    private void setInitRoomTypeLst() {
    	roomTypeLst = new List<SelectOption>();
	// 2015/09/01 多店舗機能対応 BEGIN
		// List<TypeOfRooms__c> roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        List<TypeOfRooms__c> roomTypeLstRs = new List<TypeOfRooms__c>();
        if (CommUtils.isBlank(branchShopNm) && userInf.isShopCodePlex) {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(userInf.shops);
        }else {
            roomTypeLstRs = (new CommLogicProcess()).getTypeOfRooms(branchShopNm);
        }
	// 2015/09/01 多店舗機能対応 END
		for (TypeOfRooms__c r : roomTypeLstRs) {
    		roomTypeLst.add(new SelectOption(r.Id, r.Name));
		}
    }
    // 店舗リスト情報を取得する
  	private void setInitBranShopLst() {
  		// 店舗リスト情報を取得する
    	// 2015/09/01 多店舗機能対応 BEGIN
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        // 2015/09/01 多店舗機能対応 END
        // 店舗コードの初期値設定を行う
        // URLから店舗コードを設定されているの場合、該当設定値は初期値として、設定する
        if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
        	branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
        } else if (CommUtils.isBlank(branchShopNm)){
        // URLから店舗コードが未設定する場合、該当ユーザーに設定されている店舗コードで初期値設定
	        if (!branchShopLst.isEmpty()) {
	        	// 顧客に設定する支店で初期値に設定する[2013/06/30]
	        	String locShopCode = UserUtil.CurrentUser.ShopCode__c;
	        	for (SelectOption s : branchShopLst) {
	        		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
	        	}
	        	// 2018/08/02 チェックリストロール制御追加　by　zy　BEGIN
	        	//　デファルト店舗コード設定
	        	if (CommUtils.isBlank(branchShopNm)) branchShopNm = branchShopLst[0].getValue();
	        	// 2018/08/02 チェックリストロール制御追加　by　zy　END
	        }
        }
    }
    private String getCookieShopcd(){
    	// DBから設定情報を取得する
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.SEISOU,UserUtil.CurrentUser.id,'');
		String spcd = userBookMap.get(UserConfigCompCtrl.KREP_SUBTYPE.SEISOUSPCD.name());
		return spcd;
    }
    // Cookie情報処理追加
    private String getCookieSetting(){
    	// DBから設定情報を取得する
		map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.SEISOU,UserUtil.CurrentUser.id,branchShopNm);
		String setInnfo = CommUtils.nullToBlank(userBookMap.get(UserConfigCompCtrl.KREP_SUBTYPE.SETINFO.name()));
		return CommUtils.nullToBlank(setInnfo);
    }
    // 保存Cookie情報
    private static void saveCookieSetting(String setInfo,String subType,string spcd){
    	UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.SEISOU,
				subType,CommUtils.nullToBlank(setInfo),UserUtil.CurrentUser.id,spcd);
    }
    //　清掃状態取得
    private static void queryCleanStatus(){
    	Schema.DescribeFieldResult fieldResult = RoomsStatus__c.CleanStatus__c.getDescribe();
    	List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        statsLst = new List<String>();
        List<Map<String,String>> statusInfoLst = new List<Map<String,String>>();
        integer index = 0;
        for( Schema.PicklistEntry f : ple) {
        	String statusName = f.getValue();
            statsLst.add(statusName);
            // 設定カラー
            if (colorMap.containsKey(statusName)) {
            	statusInfoLst.add(new Map<String,String>{'label' => statusName,'color' => colorMap.get(statusName)});
            } else {
            	String color = 'darkcyan';
            	statusInfoLst.add(new Map<String,String>{'label' => statusName,'color' => color});
            	colorMap.put(statusName,color);
            	index++;
            }
        }
        cleanLstJson = JSON.serialize(statusInfoLst);
    }
    // 部屋SQL文
    private static String queryRoom = 'select Name ,Id ,Area__c ,Basu__c ,CapacityHaku__c ,Capacity__c ,Field10__c ,Field11__c ,Field12__c ,Field13__c ,Field14__c ,Field15__c ,Field16__c ,Field17__c ,Field18__c ,Field19__c ,Field1__c ,Field4__c ,Field5__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,Height__c ,ID__c ,LAN__c ,Lat__c ,Left__c ,Lng__c ,Rank_2__c ,Rank_3__c ,Rank_4__c ,Rank_5__c ,Rank__c ,Rnumber__c ,RoomName__c ,Seq__c ,Tier123__c ,Top__c ,UseOfRoom__c ,Width__c ,centreLat__c ,centreLng__c ,furo__c ,heyadashiryou__c ,heyadashiryouryou__c ,kakuzuke__c ,priority__c ,roomimage__c ,rotenburo__c ,TypeRoomRef__c ,Nosmoking__c ,ParentRoomRef__c ,Floor__c ,TypeRoomRef__r.Name from Room__c';
    // 部屋にお客様名・予約名表示制御フラグの初期値設定する
    private static Integer roomNameType = CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c == null ? 1 : CommDefine__c.getOrgDefaults().RoomIndicatorInfoNameType__c.intValue();
    // 部屋表示順フラグ定数定義
    private static final String ROOM_SORT_NAME_DIV = '1';
    private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;

    // 部屋情報取得
    private void queryRoomStatus(){
    	Date todayDt = System.today();
    	areaInfLst = new List<AreaInfo>();
    	String queryWhere =  ' where ShopInfoRef__r.ShopCode__c = :branchShopNm and UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'';
    	String queryOrder = ' Order By AREA__c asc, Floor__c asc, ';
        if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
        	queryOrder += ' Seq__c asc ';
        } else {
        	queryOrder += ' DisplayNo__c asc ';
        }
    	List<Room__c> rooms = Database.query(queryRoom + queryWhere + queryOrder);
    	Set<String> areaSet = new Set<String>();
    	Set<String> floorSet = new Set<String>();
    	List<RoomInfo> roominfs = new List<RoomInfo>();
    	// フロアリスト
   		Set<String> hideFloorSet = new Set<String>();
   		if (setInfo != null && setInfo.hideFloor != null) {
   			hideFloorSet = new Set<String>(setInfo.hideFloor);
   		}
   		// 部屋リスト
   		Set<String> roomSet = new Set<String>();
    	for (Room__c s: rooms) {
        	String areaNm = CommUtils.nullToBlank(s.Area__c);
            // 新た場所に切り替えする場合
            if (!areaSet.contains(areaNm)) {
            	areaSet.add(areaNm);
            	// リスト情報を格納する
                AreaInfo newArea = new AreaInfo(areaNm);
                areaInfLst.add(newArea);
                // 新規Floor初期化
                floorSet.clear();
            }
            // Floor情報が存在チェックを行う
            if (!floorSet.contains(s.Floor__c)) {
            	FloorInfo floor = new FloorInfo();
            	floor.noShowFlag = hideFloorSet.contains(s.Floor__c);
            	areaInfLst.get(areaSet.size()-1).addFoorRoomInfo(floor);
            	floorSet.add(s.Floor__c);
            }
            // Room Info Add
            FloorInfo floorRoom = areaInfLst[areaSet.size()-1].floorRoomLst[floorSet.size()-1];
            RoomInfo room = new RoomInfo(s, CommUtils.nullToBlank(roomNameType));
            floorRoom.addRoom(room);
            roominfs.add(room);
            roomSet.add(s.id);
        } // End For
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ BEGIN
        //Map<Id,List<RoomsStatus__c>> roomStMap = RoomStatusManager.getCleanStatusLst(todayDt,roomSet,null);
        Map<Id,List<RoomsStatus__c>> roomStMap = RoomStatusManager.getCleanStatusLst((CommConst.LEAD_ROOM_ST_ISKEEPCLEANFLG ? null : todayDt),roomSet,null);
        // 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ END
        setRelateInfos(roominfs,roomStMap,roomSet);
    }
    // 相关信息作成
   	private static void setRelateInfos(List<RoomInfo> roominfs,Map<Id,List<RoomsStatus__c>> roomStMap,Set<String> roomSet){
   		Date todayDt = system.today();
   		 // 既存の予約データを取得する
        Map<Id, Lead__c> roomLeadMap = queryLeadInfo(roomSet);
   		for (RoomInfo rs : roominfs) {
   			String roomId = rs.sobj.id;
   			// 清掃状態初期化
   			rs.cleanStatus = statsLst[0];
   			// 部屋状態管理の設定
   			if (roomStMap.containsKey(roomId) && !roomStMap.get(roomId).isEmpty()) {
   				RoomsStatus__c rst = roomStMap.get(roomId)[0];
   				rs.statusId = rst.id;
   				if (!CommUtils.isBlank(rst.CleanStatus__c)) rs.cleanStatus = rst.CleanStatus__c;
   				if (rst.result__c == CommConst.LEAD_ROOM_ST_UNCLEAN) rs.noShowFlag = false;
   			}
   			rs.cleanColor = colorMap.get(rs.cleanStatus);
   			// 予約データが存在する場合
			if (roomLeadMap.containsKey(roomId)) {
				Lead__c lead = roomLeadMap.get(roomId);
    		    //お部屋ステータス：[未清掃]
				if (lead.Field299__c == CommConst.LEAD_ROOM_ST_UNCLEAN) {
					rs.roomStatus = '[' + Label.MSG_008_0013 + ']';
				}
				// 予約ステータス[チェックイン完/外出中/滞在中]
				String status = lead.Field298__c;
				if( status == CommConst.LEAD_GUEST_ST_CI ||
                    status == CommConst.LEAD_GUEST_ST_OUT ||
                    status == CommConst.LEAD_GUEST_ST_BATH){
					// 出発日は今の日付の場合：出発予定
					if (lead.LeadIndexRef__r.DepartureDate__c == todayDt) {
						rs.roomStatus = '[' + Label.MSG_008_0010 + ']';
					}
					// 滞在
					else{
						rs.roomStatus =  '[' + Label.MSG_008_0009 + ']';
					}
				}
				else if(lead.Field298__c == CommConst.LEAD_GUEST_ST_CO ) {		// チェックインＡＮＤチェックアウトボタンで切り替え表示するため、ステータスはチェックアウトすると、出発状態を表示する
					// 出発予定
					rs.roomStatus =  '[' + Label.MSG_008_0011 + ']';
				}
				else{
					// 空室「顧客存在、未チェックイン場合」
					rs.roomStatus =  '[' + Label.MSG_008_0042 + ']';
					
				}
			}else{
				// 空室「予約データがない場合」
				rs.roomStatus =  '[' + Label.MSG_008_0008 + ']';
			}
   		}
   	}
   	@remoteaction
   	public static Object remoteQueryInfo(String dataType,String reqInfo){
   		List<Object> result = new List<Object>();
   		// 清掃明細更新する
   		if (dataType == 'upsertCleanDetail') {
   			return upsertCleanDetail(reqInfo);
   		// COOKIE保存情報
   		} else if (dataType == 'saveCookieSetinfo') {
   			return saveCookieSetinfo(reqInfo);
   		// 更新清掃明細
   		} else if (dataType == 'refreshCleanDetail') {
   			return refreshCleanDetail(reqInfo);
   		// 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
   		// 既存チェックリスト取得
   		} else if (dataType == 'getChkInfo') {
   			return getChkInfo(reqInfo);
   		}
   		// 2018/08/02 清掃チェックリスト機能追加 by zy END
   		return result;
   	}
   	// 清掃明細更新する
   	private static object upsertCleanDetail(String reqInfo){
   		RequestInfo info = (RequestInfo)JSON.deserialize(reqInfo,RequestInfo.class); 
   		List<RoomsStatus__c> details = new List<RoomsStatus__c>();
   		List<FeedItem> feedItems = new List<FeedItem>();
   		List<String> roomIds = new List<String>();
   		// 部屋リスト状態更新
   		if (info.roomids != null && !info.roomids.isEmpty() ) {
   			Date todayDt = system.today();
   			String curStatus = info.status;
   			documentLoad(info.spcd);
   			// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ BEGIN
   			//Map<Id,List<RoomsStatus__c>> roomStMap = RoomStatusManager.getCleanStatusLst(todayDt,new Set<String>(info.roomids),new List<String>{'RoomRef__r.name'});
   			Map<Id,List<RoomsStatus__c>> roomStMap = RoomStatusManager.getCleanStatusLst((CommConst.LEAD_ROOM_ST_ISKEEPCLEANFLG ? null : todayDt),new Set<String>(info.roomids),new List<String>{'RoomRef__r.name'});
   			// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ END
   			Set<String> backRoomSet = new Set<String>();
   			roomIds = info.roomids;
   			// 該当部屋は該当グループに既にポスト済み識別フラグ
   			set<string> postedFlgSet = new set<string>();
   			// 2018/08/02 チェックリスト機能追加 by zy BEGIN
   			List<ChkField> chkLst = info.checklist;
   			// 2018/08/02 チェックリスト機能追加 by zy END
   			for (String roomId : info.roomids) {
   				if (roomStMap.containsKey(roomId)) {
   					// 該当部屋に対して、管理している部屋状態データ
   					List<RoomsStatus__c> rsts = roomStMap.get(roomId);
   					if (rsts != null) {
   						for (RoomsStatus__c rs : rsts) {
   							// 2018/08/02 チェックリストロール制御追加　by　zy　BEGIN
   							// 清掃ステータス変更の場合
   							boolean statusChgFlag = rs.CleanStatus__c != curStatus;
   							// 2018/08/02 チェックリストロール制御追加　by　zy　END
		   					rs.CleanStatus__c = curStatus;
		   					if (!CommUtils.isBlank(rs.CleanStatus__c) && completeStatus.contains(rs.CleanStatus__c)) {
					   			rs.Result__c = CommConst.LEAD_ROOM_ST_CLEANED;
				   			// 清掃済み→未清掃の設定の場合
				   			} else {
				   				// １つデータ変更
				   				if (!backRoomSet.contains(roomId)) {
				   					rs.Result__c = CommConst.LEAD_ROOM_ST_UNCLEAN;
				   					backRoomSet.add(roomId);
					   			}
		   					}
		   					// 2018/08/02 チェックリスト機能追加 by zy BEGIN
		   					if (chkLst != null) {
				   				for (ChkField field : chkLst) {
				   					rs.put(field.fieldNm,field.checked);
				   				}
				   			}
				   			// 2018/08/02 チェックリスト機能追加 by zy END
		   					// 該当状態はグループポスト情報を定義される場合
		   					// 2018/08/02 チェックリストロール制御追加　by　zy　BEGIN
   							if (statusGroupMap.containsKey(curStatus) && statusChgFlag) {
   							// 2018/08/02 チェックリストロール制御追加　by　zy　END
   								// 該当ステータスに対して、メッセージとポスト対象グループ情報を取得する
   								for (String gpName : statusGroupMap.get(curStatus)) {
   									// 該当グループは無効のグループの場合、処理対象外
   									if (!groupNmToIdMap.containskey(gpName)) continue;
   									// 該当グループ名は対応のメッセージが非存在の場合、処理対象外
   									if (!groupToMsgMap.containsKey(gpName)) continue;
   									// 該当グループへ該当部屋の関連情報を既にポスト済み場合、処理対象外
   									String key = gpName + '_' + roomId;
   									if (postedFlgSet.contains(key)) continue;
   									postedFlgSet.add(key);
   									// グループへ情報ポストする
   									String message = groupToMsgMap.get(gpName);
									message = message.replace('@room',rs.RoomRef__r.name)
													 .replace('@status',curStatus);
									// Chatterポスト情報を設定する
									FeedItem post = new FeedItem();
						   			post.Type = 'TextPost';
								    post.Body = message;
								    post.ParentId = groupNmToIdMap.get(gpName);
									feedItems.add(post);
   								}
				   			}
		   					details.add(rs);
   						}
   					}
   				}
   			}
   			if (!details.isEmpty()) update details;
   			if (!feedItems.isEmpty()) insert feedItems;
   		}
   		return refreshByRoomIds(roomIds);
   	}
   	// COOKIE保存情報
   	private static Object saveCookieSetinfo(String reqInfo){
   		try {
   			SettingInfo	setInfo = (SettingInfo)JSON.deserializeStrict(reqInfo,SettingInfo.class);
   			if (setInfo != null) {
   				saveCookieSetting(JSON.serialize(setInfo),UserConfigCompCtrl.KREP_SUBTYPE.SETINFO.name(),setInfo.spcd);
   			}
   		} catch(Exception e){}
   		return null;
   	}
   	// 更新清掃明細
   	private static object refreshCleanDetail(String reqInfo){
   		RequestInfo info = (RequestInfo)JSON.deserialize(reqInfo,RequestInfo.class); 
   		List<RoomInfo> roominfos = new List<RoomInfo>();
   		if (info != null && info.roomids != null) {
   			if (!info.roomids.isEmpty()) {
   				roominfos = refreshByRoomIds(info.roomids);
   			}
   		}
   		return roominfos;
   	}
   	// 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
   	// チェック情報取得
   	private static object getChkInfo(String reqInfo){
   		RequestInfo info = (RequestInfo)JSON.deserialize(reqInfo,RequestInfo.class); 
   		String statusId = info.statusid;
   		List<String> fieldLst = info.fieldLst;
   		List<ChkField> chekLst = new List<ChkField>();
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
		// SQL文
   		String queryStatus = 'select id,name,RoomRef__c';
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
   		if (fieldLst != null) {
	   		for (String fieldNm : fieldLst) {
	   			queryStatus += ',' + fieldNm;
	   		}
   		}
   		queryStatus += ' from RoomsStatus__c ';
   		queryStatus += ' where id=:statusId';
   		List<RoomsStatus__c> rs = Database.query(queryStatus);
   		if (!rs.isEmpty()) {
   			RoomsStatus__c roomStatus = rs[0];
   			for (String fieldNm : fieldLst) {
   				ChkField cf = new ChkField();
   				cf.fieldNm = fieldNm;
   				cf.checked = Boolean.valueOf(CommUtils.nullToBlank(roomStatus.get(fieldNm)));
   				chekLst.add(cf);
   			}
			// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
			// 指定清掃状態のカスタム字段内容取得
			chekLst.addAll(processCustomFieldSet(roomStatus.RoomRef__c,info.leadLst,info.contactLst));
			// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
   		}
   		return chekLst;
   	}
   	// 2018/08/02 清掃チェックリスト機能追加 by zy END
   	private static List<RoomInfo> refreshByRoomIds(List<String> roomIds){
   		List<RoomInfo> roominfos = new List<RoomInfo>();
   		Date todayDt = system.today();
   		// 清掃明細状態初期化
   		queryCleanStatus();
   		Set<String> roomSet = new Set<String>(roomIds);
   		String queryWhere = ' where id = :roomSet';
   		List<Room__c> rooms = Database.query(queryRoom + queryWhere);
   		// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ BEGIN
   		//Map<Id,List<RoomsStatus__c>> roomStMap = RoomStatusManager.getCleanStatusLst(todayDt,roomSet,null);
   		Map<Id,List<RoomsStatus__c>> roomStMap = RoomStatusManager.getCleanStatusLst((CommConst.LEAD_ROOM_ST_ISKEEPCLEANFLG ? null : todayDt),roomSet,null);
   		// 2018/8/28 ルームインジケーターのチェックアウトから日をまたぐと未清掃が反映 BY WSQ END
   		for (Room__c r : rooms) {
   			roominfos.add(new RoomInfo(r, CommUtils.nullToBlank(roomNameType)));
   		}
   		// 清掃情報作成
		setRelateInfos(roominfos,roomStMap,roomSet);
		return roominfos;
   	}
   	// 予約SQL文
   	private static String QueryLeadHeader = 'id,Name,Rroom__r.Name,Mans__c,Femails__c,ChildC__c,ChildD__c,ChildE__c,ChildFA__c,ChildF__c,Childs__c,StayPersons__c,RecordType.Name, Rroom__c,Field276__c, Relcontact__r.Name, Relcontact__r.Katakana__c, Relcontact__r.KanaName1__c ,Relcontact__r.KanaName2__c ,ReservedStatus__c, LeadIndexSubId__c, LeadIndexRef__c, LeadIndexRef__r.DepartureDate__c, EntryTime__c, Field4__c, Departure__c, Field3__c, Field310__c, Field298__c, Field299__c,DayNightCal__c,NoCleanRoomFlg__c';
   	private static Map<Id, Lead__c> queryLeadInfo (Set<String> roomSet) {
		Date searchDt = system.today();
        // 宿泊のレコードタイプを取得する
        List<Id> recTypeLst = getLeadBookingRecTypeLst();
        // 昼12時過ぎすると、到着日は当日のデータを表示する、12時前の場合、到着日は前日のデータを表示する
        String queryWhere = ' Where DAY_ONLY(convertTimezone(EntryTime__c)) = ' + String.valueOf(searchDt);
        queryWhere += ' And CancelBool__c != ' + CommConst.LEAD_ST_CANCEL_FLG;
        queryWhere += ' And Rroom__c = :roomSet ';
        // 到着時刻順番で表示する
        String queryOrder = ' Order By Field4Cal__c asc ';
        String queryStr = 'Select ' + QueryLeadHeader + ' From Lead__c '+ queryWhere + queryOrder;
        // Map<RoomId, Lead>
        Map<Id, List<Lead__c>> roomLeadsMap = new Map<Id, List<Lead__c>>();
        Map<Id, Lead__c> roomLeadMap = new Map<Id, Lead__c>();
        // 現状のシステム時刻を取得する
        String nowTime = System.now().format('yyyyMMddHH:mm');
        // 画面から予約情報TOPに切り替え指定の場合
        
        // 開始日、終了日はSUBINDEXから取得、設定を行う
        List<Lead__c> existLeads = Database.query(queryStr);
        Set<String> subIdxSet = new Set<String>();
        // 2018/07/24 ルームインジケータで複数部屋のリスト表示 zyz BEGIN
        Set<Id> leadIndexIdSet = new Set<Id>();
        map<Id,String> leadRoomNMMap = new map<Id,String>();
        // 2018/07/24 ルームインジケータで複数部屋のリスト表示 zyz END
        for (Lead__c lead : existLeads) {
            // 2018/07/24 ルームインジケータで複数部屋のリスト表示 zyz BEGIN
            if (leadIndexIdSet.contains(lead.LeadIndexRef__c)){
            	String roomNMStr = leadRoomNMMap.get(lead.LeadIndexRef__c);
            	roomNMStr = roomNMStr + ',' + lead.Rroom__r.Name;
            	leadRoomNMMap.put(lead.LeadIndexRef__c,roomNMStr); 
            } else{
            	leadIndexIdSet.add(lead.LeadIndexRef__c); 
            	leadRoomNMMap.put(lead.LeadIndexRef__c,lead.Rroom__r.Name); 
            }
            // 2018/07/24 ルームインジケータで複数部屋のリスト表示 zyz END
            // SUBINDEXのIDを格納する
            if(!CommUtils.isBlank(lead.LeadIndexSubId__c)) subIdxSet.add(lead.LeadIndexSubId__c);
            // １部屋に予約数統計する
            if (!roomLeadsMap.containsKey(lead.Rroom__c)) roomLeadsMap.put(lead.Rroom__c, new List<Lead__c>());
            roomLeadsMap.get(lead.Rroom__c).add(lead);
        }
        // 部屋単位に複数予約情報が存在する場合、該当予約の到着時刻と出発時刻を格納する
        // 部屋毎、存在する部屋数設定を行う
        for (Id roomId : roomLeadsMap.keySet()) {
            List<Lead__c> leads = roomLeadsMap.get(roomId);
            // 2017/02/23 一括レジカード印刷対応　BEGIN
            if (!leads.isEmpty()) {
	            String leadIdsStr = '';
	            for (Lead__c lead : leads) {
	            	leadIdsStr += lead.id + ',';
	            }
            }
            // 2017/02/23 一括レジカード印刷対応　END
            String times = '';
            // 所属する予約の時刻リストを設定する
            for (Lead__c lead : leads) {
                String timeStr = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c + '||'
                                +lead.Departure__c.format('yyyyMMdd') + lead.Field3__c;
                times += timeStr + ',';
            }
            // 
        }
        
        Map<Id, LeadIndex__c> subIdxMap = new Map<Id, LeadIndex__c>();
        // 予約SUBINDEX関連情報を取得する
        for (LeadIndex__c subIdx : [select Id, DepartureDate__c from LeadIndex__c where id in :subIdxSet]) {
        	subIdxMap.put(subIdx.Id, subIdx);
        }

        //for (Lead__c lead : Database.query(queryStr)) {
        for (Lead__c lead : existLeads) {
            // 該当予約関連のSUBINDEX設定情報を設定する
            if (subIdxMap.containsKey(lead.LeadIndexSubId__c)) lead.LeadIndexRef__r = subIdxMap.get(lead.LeadIndexSubId__c);
            // すでに設定済みの場合、同じ部屋は以外の予約データは対象外
            if (roomLeadMap.containsKey(lead.Rroom__c)) continue;
        }
        // 画面から個別指定以外の予約データに対して、システム時間は宿泊時間の予約情報を設定、画面に表示する
        for (Lead__c lead : existLeads) {
            // すでに設定済みの場合、同じ部屋は以外の予約データは対象外
            if (roomLeadMap.containsKey(lead.Rroom__c)) continue;
            // 画面から個別予約情報はTOPに表示する設定の場合
            // システム時刻は該当予約の到着時刻と出発時刻間の場合、該当予約は画面TOPに表示する
            String startDtime = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c;
            String endDtime = lead.Departure__c.format('yyyyMMdd') + lead.Field3__c;
            if (startDtime <= nowTime && nowTime <= endDtime) {
                roomLeadMap.put(lead.Rroom__c, lead);
            }
        }
        // 部屋に表面に表示予約情報は未設定する場合、設定を行う
        for (Id roomId : roomLeadsMap.keySet()) {
            //　画面から個別指定される場合い
            if (roomLeadMap.containsKey(roomId)) continue;
            // 予約リストを取得する、システム時刻は初め到着時刻により、早い場合、最初の予約は画面に表示する、その以外の場合、最後の予約データは画面に表示する
            List<Lead__c> leads = roomLeadsMap.get(roomId);
            for (Lead__c lead : leads) {
                // システム時間により、次の予約情報を表示する
                String startDtime = lead.EntryTime__c.format('yyyyMMdd') + lead.Field4__c;
                if (startDtime >= nowTime ) {
                    roomLeadMap.put(roomId, lead);
                    break;
                }
            }
            // 最後の予約情報は画面へ表示する
            if (!roomLeadMap.containsKey(roomId)) {
                roomLeadMap.put(roomId, leads[leads.size()-1]);
            }
        }
        // 部屋単位の時間リスト情報を格納する
        
        return roomLeadMap;
    }
    // 宿泊の対象データ表示機能
    public static List<Id> getLeadBookingRecTypeLst () {
		Id bookRecTypeId = CommLogicProcess.getLeadBookingRecType();
	    Id baseRecTypeId = CommLogicProcess.getLeadBaseRecType();
	    List<Id> recTypeLst = new List<Id>{bookRecTypeId, baseRecTypeId};
	    return recTypeLst;
    }
   	class AreaInfo{
   		public String areaName{get;set;}
   		public List<FloorInfo> floorRoomLst{get;set;}
   		public AreaInfo(String name){
   			areaName = name;
   			floorRoomLst = new List<FloorInfo>();
   		}
   		public void addFoorRoomInfo(FloorInfo floor){
   			floorRoomLst.add(floor);
   		}
   	}
   	class FloorInfo{
   		public String floorName{get;set;}
   		public List<RoomInfo> roomLst{get;set;}
   		public boolean noShowFlag{get;set;}
   		public FloorInfo(){
   			roomLst = new List<RoomInfo>();
   		}
   		public void addRoom(RoomInfo info){
   			if (CommUtils.isBlank(floorName)) floorName = info.sobj.floor__c;
   			roomLst.add(info);
   		}
   	}
   	class RoomInfo{
   		String roomId;
   		public Room__c sobj{get;set;}
   		public String cleanStatus{get;set;}
   		public String cleanColor{get;set;}
   		public String roomStatus{get;set;}
   		public boolean noShowFlag{get;set;}
   		public String statusId{get;set;}
   		public RoomInfo(Room__c s , String nameType){
   			sobj = s;
   			roomId = s.id;
   			noShowFlag = true;
   		}
   	}
   	// 設定情報
   	class SettingInfo{
   		// 非表示フロア
   		List<String> hideFloor;
   		// フロア部屋表示数
   		String showsize;
   		// 店舗コード
   		String spcd;
   		// 部屋タイプリスト
   		List<String> roomTypes;
   		// 清掃済み表示フラグ
   		boolean cleanOver;
   	}
   	// 通信用情報
   	class RequestInfo{
    	// 部屋id
    	String roomid;
    	// 清掃状態
    	String status;
    	// 店舗コード
    	String spcd;
    	// 部屋idリスト
   		List<String> roomids;
   		// 2018/08/02 清掃チェックリスト機能追加 by zy BEGIN
   		// 部屋状態ID
   		String statusid;
   		// 項目リスト
   		List<String> fieldLst;
   		// チェックリスト
   		List<ChkField> checklist;
   		// 2018/08/02 清掃チェックリスト機能追加 by zy END
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
		List<String> leadLst;
		List<String> contactLst;
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
    }
    // 2018/08/02 チェックリスト機能追加 by zy BEGIN
    class ChkField{
    	String fieldNm;
    	boolean checked;
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
		String content;
		String datatype;
		String name;
		String fieldtype;
		public void init(String fieldName,Map<String, Schema.DescribeFieldResult> sobjectMap,String type,sObject sobj){
			// 字段名
			fieldNm = fieldName;
			// 字段区分
			datatype = type;
			// 字段情報取得
			Schema.DescribeFieldResult dr = sobjectMap.get(fieldName.toLowerCase());
			if (dr != null) {
				// 字段タイプ取得
				Schema.DisplayType drType = dr.getType();
				// 字段値
				content = CommUtils.nullToBlank(CommUtils.ConvByFielType(sobj.get(fieldName),drType));
				// 参照対象特殊処理
				referenceProcess(this,dr,drType,sobj);
				// 字段タイプ設定
				fieldtype = CommUtils.nullToBlank(drType);
			}
		}
		// 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
    }
    // 2018/08/02 チェックリスト機能追加 by zy END
    // 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy BEGIN
	// 予約対象
	public Lead__c lead{get;set;}
	// お客様対象
	public contact contact{get;set;}
	// 参照対象特殊処理
	private static void referenceProcess(ChkField cf,Schema.DescribeFieldResult dr,Schema.DisplayType drType,Sobject obj){
		// 参照対象チェック
		if (drType == Schema.DisplayType.Reference) {
			// 参照対象取得
			Sobject newSobject = obj.getsobject(dr.getRelationshipName());
			// 字段「name」設定
			if (newSobject != null) cf.name = CommUtils.nullToBlank(newSobject.get('name'));
			else cf.name = '';
		}
	}
	// 指定清掃状態のカスタム字段内容取得
	private static List<ChkField> processCustomFieldSet(String roomId,List<String> leadLst,List<String> contactLst){
		List<ChkField> chekLst = new List<ChkField>();
		// 指定日
		Datetime todayDt = system.now();
		// 予約開始日
		Date startDt = system.today();
		// 予約終了日
		Date endDt = startDt.addDays(1);
		// カスタム情報字段作成
		List<String> fieldArr = new List<String>();
		// 既存字段集合
		Set<String> exitField = new Set<String>{'id','entrytime__c'};
		// 予約SQL文作成
		String leadSQL = 'select id,EntryTime__c,';
		// 予約字段集合
		Map<String, Schema.DescribeFieldResult> leadSobjectMap = CommSqlUtils.getAllFieldLst(Lead__c.sObjectType,false,true,true);
		// お客様字段集合
		Map<String, Schema.DescribeFieldResult> contactSobjectMap = CommSqlUtils.getAllFieldLst(Contact.sObjectType,false,true,true);
		// 参照字段
		String drName = 'relcontact__c';
		Schema.DescribeFieldResult drContact = leadSobjectMap.get(drName);
		if (drContact != null) drName = drContact.getRelationshipName() + '.';
		// 予約カスタム字段処理
		processField(exitField,fieldArr,leadLst,leadSobjectMap,'');
		// お客様カスタム字段処理
		processField(exitField,fieldArr,contactLst,contactSobjectMap,drName);
		if (!fieldArr.isEmpty()) {
			// カスタム字段作成
			leadSQL += String.join(fieldArr,',');
			// 最後「,」削除
			leadSQL = leadSQL.removeEnd(',');
			// 指定予約条件設定
			leadSQL += ' from Lead__c where DAY_ONLY(convertTimezone(EntryTime__c)) >= :startDt And DAY_ONLY(convertTimezone(EntryTime__c)) < :endDt and Rroom__c =:roomId and Field298__c != \'' + CommConst.LEAD_GUEST_ST_OUT + '\' order by EntryTime__c asc ';
			// 該当清掃の部屋の予約を取得
			List<Lead__c> leads = Database.query(leadSQL); 
			// 予約存在の場合
			if (!leads.isEmpty()) {
				Lead__c lead = null;
				// 予約チェック
				for (Lead__c colLead : leads) {
					if(colLead.EntryTime__c <= todayDt && lead != null) lead = colLead;
				}
				if (lead == null) lead = leads[leads.size() -1];
				if (lead != null) {
					// 予約情報作成
					for (String leadfield : leadLst) {
						// 表示字段初期化
						ChkField cf = new ChkField();
						cf.init(leadfield,leadSobjectMap,'lead',lead);
						chekLst.add(cf);
					}
					if (!contactLst.isEmpty()) {
						// 参照お客様対応
						Contact con = (Contact)lead.getSobject('relContact__r');
						// お客様情報作成
						for (String contactField : contactLst) {
							// 表示字段初期化
							ChkField cf = new ChkField();
							cf.init(contactField,contactSobjectMap,'contact',con);
							chekLst.add(cf);
						}
					}
				}
			}
		}
		return chekLst;
	}
	// カスタム字段処理
	private static void processField(Set<String> exitField, List<String> fieldArr,List<String> sobjectFields,Map<String, Schema.DescribeFieldResult> sobjectMap,String prefixName){
		// 字段リストフィルター
		for (String leadfield : sobjectFields) {
			// 該当字段名
			String lowerField = leadfield.tolowerCase();
			// 参照字段対応
			if (!CommUtils.isBlank(prefixName)) leadfield = prefixName + leadfield;
			// 字段重複チェック、SQL用字段作成
			if (!exitField.contains(leadfield.toLowerCase())) fieldArr.add(leadfield);
			// 重複集合追加
			exitField.add(leadfield.toLowerCase());
			// 字段情報取得
			Schema.DescribeFieldResult dr = sobjectMap.get(lowerField);
			// 参照字段の場合
			if (dr != null && dr.getType() == Schema.DisplayType.Reference) {
				// 参照字段「name」作成
				String referenceField = prefixName + dr.getRelationshipName() + '.name';
				// 参照特殊の字段追加
				if (!exitField.contains(referenceField.toLowerCase())) fieldArr.add(referenceField);
				// 重複集合特殊字段追加
				exitField.add(referenceField.toLowerCase());
			}
		}
	}
    // 2019/10/15 インスペ項目にお客様特記事項、部屋セット備考、予約人数を表示。 by zy END
	// 2019/12/15 部屋ステータスの一括更新不要 by zy BEGIN
	public static boolean quickActionFlg{get;set;}
	// 2019/12/15 部屋ステータスの一括更新不要 by zy END
}