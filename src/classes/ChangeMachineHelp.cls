/*
* 釣銭機のヘルプ
*/
public with sharing class ChangeMachineHelp {
	private String oShopCode;
	private Set<String> includeSet;
	private boolean shopDiff;
	private map<String,Object> ipMap;
	private map<String,String> priceMap;
	private map<String,boolean> switchMap;
	// 2017/07/20 指令添加 by zy BEGIN
	// 指定枚数放出指令是否开启
	private boolean meisuuSettingFlag ;
	// 2017/07/20 指令添加 by zy END
	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
	private boolean autoSaveAndPrintFlag;
	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
	public static final String PAGETYPE_ACCOUNT = 'ACCOUNT';
	public static final String PAGETYPE_CASH = 'CASH';
    public ChangeMachineHelp (String shopCode) {
    	oShopCode = shopCode;
    	ipMap = new map<String,Object>();
    	priceMap = new map<String,String>();
    	includeSet = new Set<String>();
    	switchMap = new map<String,boolean>();
    	shopDiff = false;
    	// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
		printMap = new  Map<String,Map<String,Object>>();
		// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
    	init();
    }
    public ChangeMachineHelp (String shopCode,boolean shopflag) {
    	oShopCode = shopCode;
    	ipMap = new map<String,Object>();
    	priceMap = new map<String,String>();
    	includeSet = new Set<String>();
    	switchMap = new map<String,boolean>();
    	shopDiff = shopflag;
    	// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
		printMap = new  Map<String,Map<String,Object>>();
		// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
    	init();
    }
    public map<String,Object> getIpMap(){
    	return ipMap;
    }
    public String getIpMapJson(String pageType){
    	boolean switchFlag = switchMap.get(pageType);
    	if (switchFlag == null || !switchFlag) return '';
    	if (ipMap.isEmpty())
    		return '';
    	else 
    		return JSON.serialize(ipMap);
    }
    public map<String,String> getPriceMap(){
    	return priceMap;
    }
    // 2017/07/20 指令添加 by zy BEGIN
    public boolean getIsMeisuuSettingFlag(){
    	return meisuuSettingFlag;
    }
    // 2017/07/20 指令添加 by zy END
    // 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
    public boolean getAutoSaveAndPrintFlag(){
    	return autoSaveAndPrintFlag;
    }
    // 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
    // 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
    private boolean openDoorFlag;
    public boolean getOpenDoorFlag(){
    	return openDoorFlag;
    }
     // 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
    // 2018/04/09 釣銭機入金方式更新 BY ZY BEGIN
    // 是否变回原来的stop方式停止入金
	private Boolean oldWayFlag = false;
	public boolean getOldWayFlag(){
		return oldWayFlag;
	}
	// 放出之前是否进行精查
	private boolean checkBeforeOutFlag = true;
	public boolean getCheckBeforeOutFlag(){
		return checkBeforeOutFlag;
	}
	// 2018/04/09 釣銭機入金方式更新 BY ZY END
    //初期化
    private void init(){
    	try{
	    	//釣銭機配置する
	    	loadXml();
    	} catch (exception e) {
    		System.debug(loggingLevel.error, e);
    	}
    }
    //釣銭機配置する
    private void loadXml(){
    	// 将默认枚数放出指令变更为默认零钱放出
    	//meisuuSettingFlag = true;
    	meisuuSettingFlag = false;
    	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
    	autoSaveAndPrintFlag = true;
    	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
    	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
    	openDoorFlag = false;
    	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('ChangeMachineConfig', oShopCode);
		//店舗の区分
		if(shopDiff){
			Dom.XmlNode shopNode = targetNode.getChildElement('SHOPCODE',null);
			String spcd = '';
			if (shopNode != null) spcd = CommUtils.nullToBlank(shopNode.getText());
			//2017/03/30　無店舗エラー対応　by zy BEGIN
			//if (oShopCode != spcd ) return;
			if (CommUtils.nullToBlank(oShopCode) != CommUtils.nullToBlank(spcd) ) return;
			//2017/03/30　無店舗エラー対応　by zy END
		}
		Dom.XmlNode failDom = targetNode.getChildElement('FAILTIMEOUT',null);
		if (failDom != null) {
			ipMap.put('fail',CommUtils.nullToBlank(failDom.getText()));
		}
		Dom.XmlNode inputDom = targetNode.getChildElement('INPUTTIMEOUT',null);
		if (inputDom != null) {
			ipMap.put('timeout',CommUtils.nullToBlank(inputDom.getText()));
		}
		// 2018/04/09 釣銭機入金方式更新 BY ZY BEGIN
		Dom.XmlNode oldWayDom = targetNode.getChildElement('OLDWAY',null);
		if (oldWayDom != null) {
			oldWayFlag = boolean.valueOf(CommUtils.nullToBlank(oldWayDom.getText()));
		}
		Dom.XmlNode beforeCheckDom = targetNode.getChildElement('BEFORECHECK',null);
		if (beforeCheckDom != null) {
			checkBeforeOutFlag = boolean.valueOf(CommUtils.nullToBlank(beforeCheckDom.getText()));
		}
		// 2018/04/09 釣銭機入金方式更新 BY ZY END
		//一时封印 by zy BEGIN
		//功能开关
		boolean accSwitchFlag = true;
		/*
		Dom.XmlNode accSwitchDom = targetNode.getChildElement('ACCOUNTSWITCH',null);
		if (accSwitchDom != null) {
			accSwitchFlag = Boolean.valueOf(CommUtils.nullToBlank(accSwitchDom.getText()));
			
		}*/
		//一时封印 by zy END
		switchMap.put(PAGETYPE_ACCOUNT,accSwitchFlag);
		//功能开关
		//一时封印 by zy BEGIN
		boolean casSwitchFlag = true;
		/*
		Dom.XmlNode casSwitchDom = targetNode.getChildElement('CASHSWITCH',null);
		if (casSwitchDom != null) {
			casSwitchFlag = Boolean.valueOf(CommUtils.nullToBlank(casSwitchDom.getText()));
			switchMap.put(PAGETYPE_CASH,casSwitchFlag);
		}
		*/
		switchMap.put(PAGETYPE_CASH,casSwitchFlag);
		//一时封印 by zy END
		// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
		//Map<String,Map<String,Object>> printMap = new  Map<String,Map<String,Object>>();
		// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
		Map<String,String> ipToPrintMap = new Map<String,String>();
		Map<String,boolean> ipToRetMap = new Map<String,boolean>();
		for (Dom.XmlNode curNode : targetNode.getChildElements()){
			String nodeName = curNode.getName();
			if ( nodeName == 'PRINTCONFIG' ) {
				String linkUrl = '';
				// 原ip取得 by zy BEGIN
				String deviceUrl = '';
				// 原ip取得 by zy END
				String name = CommUtils.nullToBlank(curNode.getAttribute('NAME',null));
				Dom.XmlNode wsNode = curNode.getChildElement('WEBSOCKET',null);
				Dom.XmlNode prnNode = curNode.getChildElement('PRINT',null);
				Dom.XmlNode portNode = curNode.getChildElement('PRINTPORT',null);
				Dom.XmlNode posNode = curNode.getChildElement('POSNO',null);
				if (wsNode != null)  linkUrl += CommUtils.nullToBlank(wsNode.getText()) + '://';
				else linkUrl += 'wss://';
				// 原ip取得 by zy BEGIN
				if (prnNode != null) {
					linkUrl += CommUtils.nullToBlank(prnNode.getText()) + ':';
					deviceUrl = CommUtils.nullToBlank(prnNode.getText());
				} else linkUrl += 'localhost:';
				// 原ip取得 by zy END
				if (portNode != null) linkUrl += CommUtils.nullToBlank(portNode.getText()) + '/';
				else linkUrl += '443/';
				String posNo = '';
				if (posNode != null) posNo = CommUtils.nullToBlank(posNode.getText());
				// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
				String connectUrl = linkUrl + 'rt300/ws';
				// 原ip取得 by zy BEGIN
				printMap.put(name,new Map<String,Object>{'link' => linkUrl,'pos' => posNo,'url' => deviceUrl,'connect'=>connectUrl,'name' =>name});
				// 原ip取得 by zy END
				// 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
			} else if ( nodeName == 'DEVICECONFIG') {
				for ( Dom.XmlNode devNode : curNode.getChildElements()) {
					Dom.XmlNode locNode = devNode.getChildElement('LOCAL',null);
					Dom.XmlNode printerNode = devNode.getChildElement('PRINTER',null);
					Dom.XmlNode retNode = devNode.getChildElement('ALLRETURN',null);
					String name = CommUtils.nullToBlank(printerNode.getText());
					String local = CommUtils.nullToBlank(locNode.getText());
					boolean allReturnFlag = false;
					if (retNode != null) allReturnFlag = Boolean.valueOf(CommUtils.nullToBlank(retNode.getText()));
					ipToRetMap.put(local,allReturnFlag);
					ipToPrintMap.put(local,name);
				}
			} else if ( nodeName == 'PRICEMAPPING') {
				for ( Dom.XmlNode modeNode : curNode.getChildElements()) {
        			String node = modeNode.getName();
        			if ( node == 'CONVERT') {
        				Dom.XmlNode apiNode = modeNode.getChildElement('APINAME',null);
        				Dom.XmlNode chgNode = modeNode.getChildElement('CHANGE',null);
        				Dom.XmlNode accountNode = modeNode.getChildElement('ACCOUNT',null);
        				String apiName = '';
        				String change = '';
        				if (apiNode != null) {
        					apiName = CommUtils.nullToBlank(apiNode.getText());
        				}
        				if (chgNode != null) {
        					change = CommUtils.nullToBlank(chgNode.getText());
        				}
        				priceMap.put(apiName,change);
        			}
        		}
			}
		}
		Dom.XmlNode meisuuSettingNode = targetNode.getChildElement('MEISUUFLAG',null);
		if (meisuuSettingNode != null) {
			meisuuSettingFlag = boolean.valueOf(CommUtils.nullToBlank(meisuuSettingNode.getText()));
		}
		// 2017/08/15 入金完了後印刷自動処理機能追加　by zy BEGIN
    	Dom.XmlNode autoPrintFlagNode = targetNode.getChildElement('AUTOPRINTFLAG',null);
		if (autoPrintFlagNode != null) {
			autoSaveAndPrintFlag = boolean.valueOf(CommUtils.nullToBlank(autoPrintFlagNode.getText()));
		}
    	// 2017/08/15 入金完了後印刷自動処理機能追加　by zy END
    	// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　BEGIN
		Dom.XmlNode openDoorNode = targetNode.getChildElement('POSDOOROPEN',null);
		if (openDoorNode != null) {
			openDoorFlag = boolean.valueOf(CommUtils.nullToBlank(openDoorNode.getText()));
		}
		// 2017/08/18 入金自動印刷機能のドルーオプンー機能フラグ追加　by　zy　END
		for (String localIp : ipToPrintMap.keySet()){
			String name = ipToPrintMap.get(localIp);
			boolean allReturn = ipToRetMap.get(localIp);
			if (printMap.containsKey(name)){
				String url = (String)printMap.get(name).get('link');
				String posNo = (String)printMap.get(name).get('pos');
				String stopUrl = url + 'rt300/wsstop';
				String connectUrl = url + 'rt300/ws';
				// 原ip取得 by zy BEGIN
				String deviceUrl = (String)printMap.get(name).get('url');
				ipMap.put(localIp,new Map<String,Object>{'stopurl'=> stopUrl,'connect' => connectUrl,'pos' => posNo , 'name' => name ,'allReturn'=> allReturn ,'deviceUrl' => deviceUrl});
				// 原ip取得 by zy END
			}
		}
//system.debug(logginglevel.info,'ipMap:::' + ipMap);
    }
    // 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy BEGIN
    public Map<String,Map<String,Object>> getDeviceMap(){
    	return printMap;
    }
    private Map<String,Map<String,Object>> printMap;
    // 2018/05/22 連携監視/復旧機能(2wayバッチ状態チェック、バッチ復旧、釣銭機復旧) by zy END
}