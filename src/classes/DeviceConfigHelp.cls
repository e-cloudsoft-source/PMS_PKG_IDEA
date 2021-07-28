public with sharing class DeviceConfigHelp {
	//单例模式
	private static DeviceConfigHelp instance = null;
	//2017/07/01 レビュー更新する　by　zy　BEGIN
	public static void getInstance(String spcd) {
		oshopCode = CommUtils.nullToBlank(spcd);
		if(instance == null) instance = new DeviceConfigHelp();
	}
	//2017/07/01 レビュー更新する　by　zy　END
	//初期化
	DeviceConfigHelp(){
		//读取配置信息
		loadingConfigXml();
	}
	private void loadingConfigXml(){
		// 変数初期化
		deviceMap = new Map<String,DeviceInfo>();
		// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('DeviceConfigXml',oshopCode,new String[]{});
		deviceInfo = new DeviceInfo(targetNode);
		// 节点処理
		/*
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
			String nodeName = xmlNode.getName();
			if (nodeName != "SHOPCODE") {
				
			}
		}*/
		//deviceInfo = new DeviceInfo(targetNode);
		deviceMap.put(oshopCode,deviceInfo);
	}
	public static Map<String,DeviceInfo> getDeviceMap(){
		if (instance == null) getInstance(oshopCode);
		return instance.deviceMap;
	}
	private static String oshopCode;
	public static DeviceInfo getDevice(String inShopCode){
		if (instance == null) getInstance(inShopCode);
		return instance.deviceInfo;
	}
	//根据店铺コード查询显示posリスト
	public static List<SelectOption> getPosLst(String shopCode,DeviceType dtype){
		if (instance == null) getInstance(shopCode);
		List<SelectOption> posLst = new List<SelectOption>();
		DeviceInfo device = instance.deviceInfo;
		if (device != null) {
			// 2017/07/10 192.168.10.XXX,192.168.10.YYY 除此两个ip以外没有其他配置则不打开pos功能 by zy BEGIN
			//Set<String> excludePosnoSet = new Set<String>();
			Set<String> excludePosnoSet = new Set<String>{'192.168.10.XXX','192.168.10.YYY'};
			// 2017/07/10 192.168.10.XXX,192.168.10.YYY 除此两个ip以外没有其他配置则不打开pos功能 by zy END
			FuncLst curFunc = device.getFuncLstByCurPos('',dtype);
			//device.exculdeMap.get(dtype);
			if (curFunc.orderPrintFlag) {
				//店舗別のオーダー初期化する
				OrderServiceHelp.setInstance(shopCode);
				// 2017/07/10 192.168.10.XXX,192.168.10.YYY 除此两个ip以外没有其他配置则不打开pos功能 by zy BEGIN
				//List<OrderServiceHelp.PrintInfo> prints  = OrderServiceHelp.getPrintInfos(excludePosnoSet);
				List<OrderServiceHelp.PrintInfo> prints  = OrderServiceHelp.getPrintInfoByIp(excludePosnoSet);
				// 2017/07/10 192.168.10.XXX,192.168.10.YYY 除此两个ip以外没有其他配置则不打开pos功能 by zy END
				for (OrderServiceHelp.PrintInfo p : prints) {
					//TODO device区分 如果没在device ip 没有配置的设备不显示出来
					posLst.add(new SelectOption(p.printNo,p.printNo));
				}
			}
		}
		return posLst;
	}
	private DeviceInfo deviceInfo;
    //設備map
    private Map<String,DeviceInfo> deviceMap;
    public enum DeviceType{SIMPLEACCOUNT,ACCOUNT,ORDER,CASH}
    // 設備メーセッジ
    public class DeviceInfo{
    	// 新会計の画面コンフィグ
    	public FuncLst accountFunc;
    	// 簡易会計の画面コンフィグ
    	public FuncLst simpleAccountFunc;
    	// 現金合わせの画面コンフィグ
    	public FuncLst cashFunc;
    	public Map<String,FuncLst> accFuncMap;
    	public Map<String,FuncLst> cashFuncMap;
    	public Map<String,FuncLst> simpleFuncMap;
    	public Map<DeviceType,Set<String>> exculdeMap;
    	// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　BEGIN
    	// POSリストの「all」場合、保存可能フラグ
    	public boolean isAllPosCanSaveFlag;
    	// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　END
    	public DeviceInfo () {
    		// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    		cashFunc = new FuncLst(true);
    		accountFunc = new FuncLst(true);
    		simpleAccountFunc = new FuncLst(true);
    		// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    		// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　BEGIN
    		isAllPosCanSaveFlag = true;
    		// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　END
    	}
    	public FuncLst getFuncLstByCurPos(String curPos,DeviceType deviceType) {
    		//現金合わせ
    		if (DeviceConfigHelp.DeviceType.CASH == deviceType) {
    			String searchKey = curPos + '_' + deviceType;
    			if(!cashFuncMap.isEmpty()){
    				if (cashFuncMap.containsKey(searchKey)) {
    					return cashFuncMap.get(searchKey);
    				}
    			}/**/
    			return cashFunc;
    		} else if ( deviceType == DeviceConfigHelp.DeviceType.ACCOUNT ) {
    			String searchKey = curPos + '_' + deviceType;
    			if(!accFuncMap.isEmpty()){
    				if (accFuncMap.containsKey(searchKey)) {
    					return accFuncMap.get(searchKey);
    				}
    			}/**/
    			return accountFunc;
    		} else if ( deviceType == DeviceConfigHelp.DeviceType.SIMPLEACCOUNT ) {
    			String searchKey = curPos + '_' + deviceType;
    			if(!simpleFuncMap.isEmpty()){
    				if (simpleFuncMap.containsKey(searchKey)) {
    					return simpleFuncMap.get(searchKey);
    				}
    			}
    			return simpleAccountFunc;
    		}
    		return null;
    	}
    	public DeviceInfo (Dom.XMLNode xmlNode) {
    		// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    		// 功能开关是否打开，默认为打开
    		boolean defaultFlag = true;
    		// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　BEGIN
    		isAllPosCanSaveFlag = true;
    		// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　END
    		//
    		DOM.xmlNode defaultNode = xmlNode.getChildElement('CONFIGISVALIDATE',null);
    		if ( defaultNode != null) {
    			// 2017/07/12 控制改修 by zy BEGIN
    			Boolean configValidateFlag = Boolean.valueOf(CommUtils.nullToBlank(defaultNode.getText()));
    			defaultFlag = !configValidateFlag;
    			// 2017/07/12 控制改修 by zy END
    		}
    		cashFunc = new FuncLst(defaultFlag);
    		accountFunc = new FuncLst(defaultFlag);
    		simpleAccountFunc = new FuncLst(defaultFlag);
    		// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    		accFuncMap = new Map<String,FuncLst>();
    		cashFuncMap = new Map<String,FuncLst>();
    		simpleFuncMap = new Map<String,FuncLst>();
    		exculdeMap = new Map<DeviceType,Set<String>>();
    		for(Dom.XMLNode configNode : xmlNode.getChildElements()) {
    			String nodeName = configNode.getName();
    			if (nodeName == 'ACCOUNT') {
    				//accountFunc = new FuncLst(configNode);
    				//TODO 会计进行pos区分 会计默认值不打开问题
    				for ( Dom.XMLNode eachNode : configNode.getChildElements()) {
    					String eachName = eachNode.getName();
    					if ( eachName == 'CONFIG') {
    						String posNo = CommUtils.nullToblank(eachNode.getAttribute('PRINTNO',null));
    						if (!CommUtils.isBlank(posNo)) {
    							// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    							FuncLst func = new FuncLst(defaultFlag,eachNode);
    							// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    							accFuncMap.put(posNo + '_' + DeviceType.ACCOUNT,func);
    							if (!func.orderPrintFlag) {
    								if (!exculdeMap.containsKey(DeviceType.ACCOUNT)) exculdeMap.put(DeviceType.ACCOUNT,new Set<String>());
    								exculdeMap.get(DeviceType.ACCOUNT).add(posNo);
    							}
    						// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    						} else 
    							accountFunc = new FuncLst(defaultFlag,eachNode);
    						// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    					}
    				}
    			} else if (nodeName == 'CASH') {
    				for ( Dom.XMLNode eachNode : configNode.getChildElements()) {
    					String eachName = eachNode.getName();
    					if ( eachName == 'CONFIG') {
    						String posNo = CommUtils.nullToblank(eachNode.getAttribute('PRINTNO',null));
    						if (!CommUtils.isBlank(posNo)) {
    							// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    							FuncLst func = new FuncLst(defaultFlag,eachNode);
    							// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    							cashFuncMap.put(posNo + '_' + DeviceType.CASH,func);
    							if (!func.orderPrintFlag) {
    								if (!exculdeMap.containsKey(DeviceType.CASH)) exculdeMap.put(DeviceType.CASH,new Set<String>());
    								exculdeMap.get(DeviceType.CASH).add(posNo);
    							}
    						// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    						} else 
    							cashFunc = new FuncLst(defaultFlag,eachNode);
    						// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    					}
    				}
    				
    			} else if (nodeName == 'SIMPLEACCOUNT') {
    				for ( Dom.XMLNode eachNode : configNode.getChildElements()) {
    					String eachName = eachNode.getName();
    					if ( eachName == 'CONFIG') {
    						String posNo = CommUtils.nullToblank(eachNode.getAttribute('PRINTNO',null));
    						if (!CommUtils.isBlank(posNo)) {
    							// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    							FuncLst func = new FuncLst(defaultFlag,eachNode);
    							// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    							simpleFuncMap.put(posNo + '_' + DeviceType.SIMPLEACCOUNT,func);
    							//if (!func.orderPrintFlag) {
    								//if (!exculdeMap.containsKey(DeviceType.CASH)) exculdeMap.put(DeviceType.CASH,new Set<String>());
    								//exculdeMap.get(DeviceType.CASH).add(posNo);
    							//}
    						// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    						} else 
    							simpleAccountFunc = new FuncLst(defaultFlag,eachNode);
    						// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    					}
    				}
    			// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　BEGIN
    			// pos保存フラク判定
    			} else if ( nodeName == 'ISALLCANSAVE') {
    				String configStr = CommUtils.nullToBlank(configNode.getText());
    				// 2017/07/12 控制改修 by zy BEGIN
    				// 默认是打开，只有true的时候对数据进行控制，根据xml配置的来
    				boolean canSaveFlag = boolean.valueOf(configStr);
    				isAllPosCanSaveFlag = !canSaveFlag;
    				// 2017/07/12 控制改修 by zy END
    			}
    			// 2017/07/11 POSリストの「all」場合、保存可能 追加　by　zy　END
    		}
    	}
    }
    // 機能リスト
    public class FuncLst{
    	//釣銭機開くフラグ
    	public boolean changePrintFlag;
    	// オーダーエンドリ開くフラグ
    	public boolean orderPrintFlag;
    	// オーダーエンドリのドルーオプンーフラグ
    	public boolean orderAutoDoorOpenFlag;
    	// 現金合わせの機械有高変更可能フラグ
    	public boolean isEditKikaiFlag;
    	// 現金合わせの機械有高変更不可时刻入力chk
    	public boolean isSaveFlag;
    	// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    	public FuncLst (boolean flag) {
    		//初期化
    		changePrintFlag = flag;
    		orderPrintFlag = flag;
    		orderAutoDoorOpenFlag = true;
    		isEditKikaiFlag = false;
    		isSaveFlag = flag;
    	// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    	}
    	// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy BEGIN
    	public FuncLst (boolean flag,Dom.XMLNode xmlNode) {
    		//初期化
    		changePrintFlag = flag;
    		orderPrintFlag = flag;
    		//对应简易会计默认弹开
    		orderAutoDoorOpenFlag = true;
    		isEditKikaiFlag = false;
    		// 保存开关始终打开
    		isSaveFlag = true;
    	// 2017/07/10 把默认开关都打开设置为true(除了editflag)，在xml里设置不公开的开关 by zy END
    		// DOM対応
    		Dom.XMLNode kikaiDom = xmlNode.getChildElement('EDITABLE',null);
    		if (!flag) {
    			Dom.XMLNode changeDom = xmlNode.getChildElement('CHARGE',null);
    			Dom.XMLNode posPrintDom = xmlNode.getChildElement('POSPRINT',null);
	    		if (changeDom != null) {
	    			String changePrintStr = changeDom.getText();
	    			changePrintFlag = boolean.valueOf(CommUtils.nullToBlank(changePrintStr));
	    		}
	    		if (posPrintDom != null) {
	    			String posPrintStr = posPrintDom.getText();
	    			orderPrintFlag = boolean.valueOf(CommUtils.nullToBlank(posPrintStr));
	    			String posDomStr = posPrintDom.getAttribute('autoDoorOpen',null);
	    			//不为空情况下进行查找
	    			if (!CommUtils.isBlank(posDomStr)) orderAutoDoorOpenFlag = boolean.valueOf(CommUtils.nullToBlank(posDomStr));
	    		}
    		}
    		if (kikaiDom != null) {
    			String kikaiStr = kikaiDom.getText();
    			isEditKikaiFlag = boolean.valueOf(CommUtils.nullToBlank(kikaiStr));
    			String saveStr = kikaiDom.getAttribute('saveflag',null);
    			// 更改为需要手动关闭，默认开关打开
    			if (!CommUtils.isBlank(saveStr)) {
    				isSaveFlag = boolean.valueOf(CommUtils.nullToBlank(saveStr));
    			}
    		}
    	}
    }
}