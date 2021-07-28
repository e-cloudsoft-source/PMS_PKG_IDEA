/**
* オーダーエンドリー印刷処理を行う
* オーダーエントリー改善 レシート番号連続 
* オーダーエントリー改善レシート再出力機能
**/
public without sharing class OrderServiceHelp {
	// 打印机相关信息
	public PrintInfo curPrint;
	// 可以取消倒计时
	public Integer autoStemp;
	// 读取的xml中店铺编号
	public String oShopCode;
	// LOGO url
	public String LogoIcon;
	// 商品图片模式区分
	public Boolean noImgFlag;
	// 相同尺寸区分（客户有要求按图片自然大小显示）
	public boolean SameSizeFlag;
	// 样本模式参照日期
	public String demoDate;
	public String simpleDemoDate;
	// 所要读取xml的店铺编号
	private static String inShopCode;
	// 定義している商品コード
	private	Set<String> prodCodeSet;
	private List<Dom.XmlNode> buttonTabs ;
	// 打印机对应关系 ip => room => name => print
	// 设备对应的房间编号
	private Map<String,Set<Decimal>> deviceMap;
	// 房间对应打印机
	private map<String,String> roomToPrintMap;
	// 打印小票layout
	private map<String,String> ipToLayoutMap;
	// 打印机对应IP
	private Map<String,PrintInfo> printConifgMap;
	// ip 直接对应 打印机信息
	private Map<String,PrintInfo> ipToPntMap;
	//价格计算用
	private static CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
	//xml配置简易会计
	private Campain camp;
	//private String imgDocumentName ;
//2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
	//private String campType;
//2017/03/06 キャパンのデフォルト値設定する　by zy END
//2017/02/22 source整理 by zy BEGIN
	public enum LayoutType{SIMPLEACCOUNT,ACCOUNT,ORDER,DOOROPEN}
//2017/02/22 source整理 by zy END
//2017/04/17 layout 对应 by BEGIN
	private Map<String,String> ipToSpecialMap;
//2017/04/17 layout 对应 by END
//2017/04/28 device 改修 by zy BEGIN
	private Map<String,Device> ipToDeviceMap ;
//2017/04/28 device 改修 by zy END
//2017/07/03 レビュー更新する　by　zy　BEGIN
	private Map<String,PrintInfo> printNoMap;
//2017/07/03 レビュー更新する　by　zy　END
// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
	private List<PrintInfo> printLst;
// 2017/07/12 印刷リスト序列化改修 by zy END
// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
	private List<CustomInfo> customLst;
// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
// 2017/09/26 会計明細削除する　by　zy BEGIN
	private boolean deleteFlag;
// 2017/09/26 会計明細削除する　by　zy END
	//单例模式
	private static OrderServiceHelp instance = null;
	private static OrderServiceHelp getInstance() {
		if(instance == null) instance = new OrderServiceHelp();
		return instance;
	}
	//2017/04/20 多店舗機能対応　by　zy BEGIN
	public static void setInstance(String spcd) {
		// inShopCode == null  说明不是多店铺 只有空 和 01 等字符才说明有店铺
		inShopCode = spcd;
		if(instance == null) instance = new OrderServiceHelp();
		//return instance;
	}
	//2017/04/20 多店舗機能対応　by　zy END
	//初期化
	OrderServiceHelp(){
		ipToPntMap = new Map<String,PrintInfo>();
		ipToLayoutMap = new Map<String,String>();
		roomToPrintMap = new map<String,String>();
		printConifgMap = new Map<String,PrintInfo>();
//2017/04/28 device 改修 by zy BEGIN
	  	ipToDeviceMap = new Map<String,Device>();
//2017/04/28 device 改修 by zy END
//2017/07/03 レビュー更新する　by　zy　BEGIN
		printNoMap = new Map<String,PrintInfo>();
//2017/07/03 レビュー更新する　by　zy　END
		curPrint = new PrintInfo();
		//2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
		//camp = new Campain();
		camp = setDefaultCamp();
		//2017/03/06 キャパンのデフォルト値設定する　by zy END
		//imgDocumentName = '';
//2017/03/13 キャパンタイプ設定　by zy BEGIN
		//campType = '2';
//2017/03/13 キャパンタイプ設定　by zy END
//2017/04/17 layout 对应 by BEGIN
		ipToSpecialMap = new Map<String,String>();
//2017/04/17 layout 对应 by END
//2017/04/20 簡易オーダーのボタンカスタム設定　by　zy　BEGIN
// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
	  	printLst = new List<PrintInfo>();
// 2017/07/12 印刷リスト序列化改修 by zy END
		simpleWith = '170px';
		fontSize = '20px';
//2017/04/20 簡易オーダーのボタンカスタム設定　by　zy　END
		noImgFlag = false;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		transMergeFlg = false;
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
		cookProds = new Set<String>();
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
		leadSQLst = new List<String>();
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
		// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
		leadMap = new Map<String,LeadInfo>();
		isMultiRoomFlg = false;
		// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
		//读取配置信息
		printLoad();
	}
	//获取商品信息
	public static List<Dom.XmlNode> getButtonTabs(){
		return getInstance().buttonTabs;
	}
	//2017/04/19 ipcheck 対応 by BEGIN
	public static Set<String> getIpSet(){
		return getInstance().roomToPrintMap.keySet();
	}
	//2017/04/19 ipcheck 対応 by BEGIN
	//根据ip取得打印信息
	public static PrintInfo getPrintByIp(String ip){
		if (getInstance().ipToPntMap.containsKey(ip)) return getInstance().ipToPntMap.get(ip);
		String name = getInstance().roomToPrintMap.get(ip);
		PrintInfo pnt = getInstance().printConifgMap.get(name);
		getInstance().ipToPntMap.put(ip,pnt);
		return getInstance().ipToPntMap.get(ip);
	}
//2017/02/22 source整理 by zy BEGIN
	//根据ip取得打印信息
	public static PrintInfo getPrintByIp(String ip,String shopCode){
	//2017/04/17 layout 对应 by BEGIN
		return getPrintByIp(ip,shopCode,LayoutType.ORDER);
	}
	public static PrintInfo getPrintByIp(String ip,String shopCode,LayoutType layType){
	//2017/04/17 layout 对应 by END	
		//如果map中存在则直接返回
		if (getInstance().ipToPntMap.containsKey(ip)) return getInstance().ipToPntMap.get(ip);
		//2017/04/17 layout 对应 by BEGIN
		String name = getInstance().ipToSpecialMap.get(ip+layType);
		//2017/04/17 layout 对应 by END
		if (CommUtils.isBlank(ip)) name = ip;
		PrintInfo pnt = getInstance().printConifgMap.get(name);
		if (pnt != null) {
			//若不存在则进行数据初始化
			ShopInformation__c shop = null;
			try{
				List<ShopInformation__c> shops = [SELECT 
		                Id
		                , Name
		                , Phone__c
		                , Address__c
		                , ShopCode__c
		                , TierDefault__c
		                , PeopleDefault__c
		                , EnglishTaxLabel__c	// 内消費税英語表示文言
		            FROM
		                ShopInformation__c
		            where   ShopCode__c = :shopCode ];
		        if(!shops.isEmpty()) shop = shops[0];
	        	else shop = defaultShopMessage();
		    	if (!CommUtils.isBlank(shopCode)) {
		    		shop = ShopInfoUtil.getShop(shopCode);
		    	} else {
		    		shop = defaultShopMessage();
		    	}
	        } catch(Exception e) {
	        	shop = defaultShopMessage();
	        }
			PrintPara curPrintPara = new PrintPara();
			curPrintPara.telno = CommUtils.nullToBLank(shop.Phone__c);
			curPrintPara.address = CommUtils.nullToBLank(shop.Address__c);
			curPrintPara.company = CommUtils.nullToBLank(shop.Name);
			curPrintPara.empno = CommUtils.nullToBLank(UserUtil.CurrentUser.EmployeeCode__c);
			curPrintPara.postno = CommUtils.nullToBLank(shop.Post__c);
			pnt.par = curPrintPara;
			//2017/04/28 device 改修 by zy BEGIN
			Map<String ,Device> deviceMap = getInstance().ipToDeviceMap;
			if (deviceMap != null && deviceMap.containsKey(ip)) {
				Device d = deviceMap.get(ip);
				if (!CommUtils.isBlank(d.posNo)){
					pnt.posno = d.posNo;
				}
				if (!CommUtils.isBlank(d.printNo)){
					pnt.printNo = d.printNo;
				}
			}
			//2017/04/28 device 改修 by zy END
		}
		if (CommUtils.isBlank(ip)) {
			return pnt;
		} else 
			getInstance().ipToPntMap.put(ip,pnt);
		return getInstance().ipToPntMap.get(ip);
	}
//2017/02/22 source整理 by zy END
	//public static
	//获取允许退单时间
	public static Integer getAutoStamp(){
		return getInstance().autoStemp;
	}
	//获取ip对应房间
	public static Set<Decimal> getRoomSetByIp(String ip){
		return getInstance().deviceMap.get(ip);
	}
	//获取xml设定显示模式
	public static boolean isImgFlag(){
		return getInstance().noImgFlag;
	}
	//获取图片显示模式
	public static boolean getSameSizeFlag(){
		return getInstance().SameSizeFlag;
	}
	//获取样本指定日期
	public static String getDemoDate(){
		return getInstance().demoDate;
	}
	//获取简易会计样品日期
	public static String getSimpleDemoDate(){
		return getInstance().simpleDemoDate;
	}
	//通过ip获取layout区分
	public static String getDeviceLayout(String ip){
		return getInstance().ipToLayoutMap.get(ip);
	}
//2017/02/22 source整理 by zy BEGIN
	public static Campain getCamp(){
		return getInstance().camp;
	}
	// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
	public static List<CustomInfo> getCustomInfoLst(){
		return getInstance().customLst;
	}
	// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
	// 2017/09/26 会計明細削除する　by　zy BEGIN
	public static boolean getDeleteFlag(){
		return getInstance().deleteFlag;
	}
	// 2017/09/26 会計明細削除する　by　zy END
	//默认店铺信息取得
	private static ShopInformation__c defaultShopMessage(){
		List<Organization> orgDetailsLst = [SELECT Id, Name, PostalCode, State,City,Street,Phone,Fax  FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
		Organization orgDetails = null;
		if (orgDetailsLst.isEmpty()) orgDetails = new Organization();
		else orgDetails = orgDetailsLst[0];
		// 組織情報から設定する
		String PostNo = CommUtils.nullToBlank(orgDetails.PostalCode);
		String shopName = orgDetails.Name;
		String Address = CommUtils.nullToBlank(orgDetails.State) + CommUtils.nullToBlank(orgDetails.City) + CommUtils.nullToBlank(orgDetails.Street);
		String Phone = CommUtils.nullToBlank(orgDetails.Phone);
		//return new ShopInformation__c(Phone__c = Phone,Address__c = Address + PostNo,Name = shopName);
		return new ShopInformation__c(Phone__c = Phone,Address__c = Address,Name = shopName,Post__c=PostNo);
	}
	/*
	* 打印信息作成
	public static  String getPrintJson(PrintInfo info,List<Tran1__c> trans,Boolean doorOpenFlag){
		return getPrintJson(info,trans, doorOpenFlag, '1',new Map<Id,List<FoodDetail__c>>(),new AccountAcount__c(),null);
	}*/
	/*
	* 打印信息作成
	
	public static  String getPrintJson(PrintInfo info,List<Tran1__c> trans,String layoutStr,Boolean doorOpenFlag){
		return getPrintJson(info,trans, doorOpenFlag, layoutStr,new Map<Id,List<FoodDetail__c>>(),new AccountAcount__c(),null);
	}
	public static String getPrintJson(PrintInfo info,List<Tran1__c> trans,Boolean doorOpenFlag,String layoutStr, Map<Id,List<FoodDetail__c>> pdMap,Id accountId){
		return getPrintJson( info, trans, doorOpenFlag, layoutStr, pdMap,new AccountAcount__c(id = accountId),null);
	}*/
/*
	private static String LAOUT_1 = '1';
	private static String LAOUT_2 = '2';
	//简易会计
	private static String LAOUT_3 = '3';	
*/	//2017/04/17 layout 对应 by BEGIN
	public static String getPrintJsons(PrintInfo info,List<Tran1__c> trans,List<LayoutType> layoutLst,Map<Id,List<FoodDetail__c>> pdMap,AccountAcount__c acc,Map<String,Object> otherMap){
		String printJson = '';
		List<Object> results = new List<Object>();
		// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy BEGIN
		// レーシト印刷チェック
		boolean isReciptFlag = false;
		for (LayoutType ltype : layoutLst) {
			if (isReciptFlag) break;
			isReciptFlag = ltype == LayoutType.ACCOUNT || ltype == LayoutType.SIMPLEACCOUNT || ltype == LayoutType.ORDER;
		}
		// レーシト印刷の場合
		if (isReciptFlag) updateReciptNo(acc);
		// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy END
		for (LayoutType lt : layoutLst) {
			//2017/06/26　控えのフィルター追加　by　zy　BEGIN
			Object obj = getPrintObj(info,trans,lt,pdMap,acc,otherMap);
			//results.add(getPrintObj(info,trans,lt,pdMap,acc,otherMap));
			results.add(obj);
			if (lt == LayoutType.ACCOUNT && !CommUtils.isBlank(info.fieldHitotu)) {
				Map<String,Object> objMap = (Map<String,Object>)obj;
				Map<String,Object> objMapClone = objMap.clone();
				// Parameter Get And Replace To Save BEGIN
				String paramKey = 'parameter';
				if (objMapClone.containsKey(paramKey)) {
				    Map<String,Object> parameterMap = ((Map<String,Object>)objMapClone.get(paramKey)).clone();
				    parameterMap.put('hikae',CommUtils.nullToBlank(info.fieldHitotu));
				    objMapClone.put(paramKey,parameterMap);
				}
				//objMapClone.put('hikae',CommUtils.nullToBlank(info.fieldHitotu));
				// Parameter Get And Replace To Save END
				results.add(objMapClone);
			}
			//2017/06/26　控えのフィルター追加　by　zy　END
		}
		printJson = JSON.serialize(results);
		return printJson;
	}
	//2017/04/17 layout 对应 by END
	//打印信息作成
	public static String getPrintJson(PrintInfo info,List<Tran1__c> trans,Boolean doorOpenFlag,LayoutType layoutStr, Map<Id,List<FoodDetail__c>> pdMap,AccountAcount__c acc,Map<String,Object> otherMap){
//2017/02/22 source整理 by zy END
		String printJson = '';
		//2017/04/17 layout 对应 by BEGIN
		List<Object> results = new List<Object>();
		// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy BEGIN
		if (layoutStr == LayoutType.ACCOUNT || layoutStr == LayoutType.SIMPLEACCOUNT || layoutStr == LayoutType.ORDER) updateReciptNo(acc);
		// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy END
		results.add(getPrintObj(info,trans,layoutStr,pdMap,acc,otherMap));
		if (doorOpenFlag) {
			results.add(getPrintObj(info,new List<Tran1__c>(),LayoutType.DOOROPEN,pdMap,acc,otherMap));
		}
		printJson = JSON.serialize(results);
		return printJson;
	}
	/*
	* 印刷設備：info（new）
	* 会計明細：「Field5__c、Field23__c、Field21__c、Field20__c」
	* 印刷レイアウト；既存template「ORDER,ACCOUNT,SIMPLEACCOUNT」
	* 会席対応map ： 商品ID→会席リスト
	* 会計オブジェクト
	* 印刷レイアウト中フィールド直接指定：{'allergie'=> 'abc'}
	**/
	public static Object getPrintObj(PrintInfo info,List<Tran1__c> trans,LayoutType layoutStr, Map<Id,List<FoodDetail__c>> pdMap,AccountAcount__c acc,Map<String,Object> otherMap){
    //2017/04/17 layout 对应 by END
    	//打印信息
    	List<Map<String,Object>> rowDetail = new List<Map<String,Object>>();
    	//金额计算,找零，总计，合计
    	//2017/09/14 toomany datas process by zy BEGIN
    	TranResult t_result = new TranResult();
    	if (LayoutType.ORDER != layoutStr ) t_result = calDetailPrice(acc, trans);
    	//2017/09/14 toomany datas process by zy END
    	//2017/05/26 印刷の支払いレーアウト追加　by zy BEGIN
    	List<Map<String,String>> objLst = new List<Map<String,String>>();
    	//2017/05/26 印刷の支払いレーアウト追加　by zy END
    	for (Tran1__c tran : trans) {
    		//支払い明細は判定なし
    		//2017/05/26 印刷の支払いレーアウト追加　by zy BEGIN
    		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
    		if (tran.id == null && tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
    			//if (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
					objLst.add(new Map<String,String>{'name' => encode(CommUtils.nullToblank(tran.Field5__c)), 'price' => currency(CommUtils.nullToZero(tran.Field20__c))});
				//}
			// 2017/09/11 印刷リスト機能　by　zy　END
    			continue;
    		}
    		//2017/05/26 印刷の支払いレーアウト追加　by zy END
			Decimal qty = CommUtils.nullToZero(tran.Field21__c);
//2017/02/22 source整理 by zy BEGIN
			String itemName = info.itemMark + encode(CommUtils.nullToblank(tran.Field5__c));
//2017/02/22 source整理 by zy END
 			//明细对应
			Map<String,Object> detailMap = new Map<String,Object>();
//2017/02/22 source整理 by zy BEGIN
			String prodPrice = currency(CommUtils.nullToZero(tran.Field23__c));
			if (LayoutType.SIMPLEACCOUNT == layoutStr) {
				detailMap.put('price', prodPrice);
				//2017/03/02 簡易会計url bug fix by zy BEGIN
				//detailMap.put('name' ,  itemName);
				detailMap.put('name' ,  encode(CommUtils.nullToblank(tran.Field5__c)));
				//2017/03/02 簡易会計url bug fix by zy END
				detailMap.put('qty' , encode(tran.Field21__c) );
				rowDetail.add(detailMap);
			} else if (LayoutType.ACCOUNT == layoutStr) {
				detailMap.put('price', prodPrice);
				//2017/04/17 layout 对应 by BEGIN
				detailMap.put('name' ,  encode(CommUtils.nullToblank(tran.Field5__c)));
				//2017/04/17 layout 对应 by END
				detailMap.put('qty' , encode(tran.Field21__c) );
				rowDetail.add(detailMap);
			//オーダー
			} else if (LayoutType.ORDER == layoutStr) {
				detailMap.put('item',  itemName);
				detailMap.put('mark', '' );
				detailMap.put('item2', '' );
				detailMap.put('qlty', qty);
				detailMap.put('price', currency(CommUtils.nullToZero(tran.Field23__c)));//encode(CommUtils.nullToblank()) //CommBaseCtrl.getCurrencySybmol()
				rowDetail.add(detailMap);
				if (pdMap.containsKey(tran.Field7__c)){
					for (FoodDetail__c pd : pdMap.get(tran.Field7__c)){
						Map<String,Object> pDetailMap = new Map<String,Object>();
						pDetailMap.put('item' , '' );
						pDetailMap.put('mark' , info.itemMark);
						pDetailMap.put('item2', encode(CommUtils.nullToblank(pd.BreakName__c)) );
						pDetailMap.put('qlty' , '' );
						pDetailMap.put('price', '' );
						rowDetail.add(pDetailMap);
					}
				}
			}
			/*
			if (layoutStr == LAOUT_1 || layoutStr == LAOUT_3) {
				detailMap.put('price', currency(CommUtils.nullToZero(tran.Field23__c)));//encode(CommUtils.nullToZero(tran.Field23__c)encode(CommUtils.nullToblank()) )
				detailMap.put('name' ,  itemName);
				detailMap.put('qty' , encode(tran.Field21__c) );
				rowDetail.add(detailMap);
			} else if (layoutStr == LAOUT_2 ) {
				//{"item":"□商品ドリングA", "mark":"", "item2":"", "qlty":"3", "price":  "100,000"}
				detailMap.put('item',  itemName);
				detailMap.put('mark', '' );
				detailMap.put('item2', '' );
				detailMap.put('qlty', qty);
				detailMap.put('price', currency(CommUtils.nullToZero(tran.Field23__c)));//encode(CommUtils.nullToblank()) //CommBaseCtrl.getCurrencySybmol()
				rowDetail.add(detailMap);
				if (pdMap.containsKey(tran.Field7__c)){
					for (FoodDetail__c pd : pdMap.get(tran.Field7__c)){
						Map<String,Object> pDetailMap = new Map<String,Object>();
						pDetailMap.put('item' , '' );
						pDetailMap.put('mark' , info.itemMark);
						pDetailMap.put('item2', encode(CommUtils.nullToblank(pd.BreakName__c)) );
						pDetailMap.put('qlty' , '' );
						pDetailMap.put('price', '' );
						rowDetail.add(pDetailMap);
					}
				}
			}
//2017/02/22 source整理 by zy END*/
    	}
    	
    	//实收金额
    	//2017/02/22 預ｶﾘ金額処理　by　zy　BEGIN
    	String recevied = currency( CommUtils.nullToZero(t_result.tranPaymount));
    	//2017/02/22 預ｶﾘ金額処理　by　zy　END
    	//消費税
    	String tax = currency( CommUtils.nullToZero(t_result.tranTax));
    	//总计金额
    	String total = currency(CommUtils.nullToZero(t_result.tranTotal));
    	//总计金额
    	String subTotalStr = currency( CommUtils.nullToZero(t_result.tranTotal));
//system.debug(logginglevel.info,'t_result:::' + t_result);
    	Datetime dt = system.now();
    	String accountURL = CommUtils.nullToBlank('https://login.salesforce.com/' +  + acc.id);
    	//2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
    	OrderServiceHelp help = getInstance();
    	Campain camp = help.camp;
    	//Campain camp = getInstance().camp;
    	//if (CommUtils.isBlank(camp.photo)){
    	//if (help.campType == '2' || (help.campType == '3' && CommUtils.isBlank(camp.photo))){
//2017/03/13 キャパンタイプ設定　by zy END
    		//camp.photo = getImageBase64String();
    	//}
    	//String campQrUrl = CommUtils.nullToBlank(getInstance().camp.qrUrl);
    	String campQrUrl = CommUtils.nullToBlank(camp.qrUrl);
    	//2017/03/06 キャパンのデフォルト値設定する　by zy END
    	PrintPara para = info.par;
    	List<Object> results = new List<Object>();
    	Map<String, Object> m = new Map<String, Object>();
    	Map<String,Object> p = new Map<String,Object>();
        String change = currency(CommUtils.nullToZero(t_result.tranCharge));
        // 2017/08/22 special字処理　by zy BEGIN
        String dtFormatStr = dt.format('yyyy年MM月dd日$$(%%)$$HH:mm').replace('%%',CommUtils.getYobi(dt.date()));
        //String dtFormatStr = dt.format('yyyy年MM月dd日 (%%) HH:mm').replace('%%',CommUtils.getYobi(dt.date()));
         // 2017/08/22 special字処理　by zy END
//2017/02/22 source整理 by zy BEGIN
		// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy BEGIN
		String recpitNo = CommUtils.isBlank(acc.ReciptNo__c) ? acc.Field145__c : CommUtils.nullToBlank(acc.ReciptNo__c).right(4);
        // 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy END
        if (LayoutType.SIMPLEACCOUNT == layoutStr) {
			p.put('company' , encode(para.company));
	        p.put('address' , encode(para.address));
	        p.put('postno'	, encode(para.postno));// 郵便番号
	        p.put('telno'	, encode(para.telno) );
			// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy BEGIN
	        // p.put('receiptno', encode(acc.Field145__c));//レシートNO
			p.put('receiptno', encode(recpitNo));//レシートNO
			// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy END
	        p.put('empno'   , encode(para.empno));
	        //p.put('datetime', encode(dtFormatStr) );
	        p.put('rows'	, rowDetail);	
	        p.put('subTotal', subTotalStr );
	        p.put('total'   , total );
	        p.put('tax'     , tax );
	        p.put('recevied', recevied);
	        p.put('change'  , change);
	        //2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
	        //p.put('cmimg'   , getImageBase64String());
	        p.put('cmimg'   , camp.photo);
	        //2017/03/06 キャパンのデフォルト値設定する　by zy END
	        //2017/03/02 簡易会計url bug fix by zy BEGIN
	        //p.put('qrurl'   , CommUtils.nullToBlank(accountURL));
	    	p.put('qrurl'   , campQrUrl);
	    	//2017/03/02 簡易会計url bug fix by zy END
//2017/02/22 print 倒影处理 by zy BEGIN
			//2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
	    	//p.put('newsmsg'   ,getInstance().camp.getNewMessage(info.headStanFlag));//encode(  getInstance().camp.getNewMessage(info.headStanFlag))
	    	p.put('newsmsg'   , camp.getNewMessage(info.headStanFlag));
	    	//2017/03/06 キャパンのデフォルト値設定する　by zy END
//2017/02/22 print 倒影处理 by zy END
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
	    	p.put('printno'  , encode(info.printNo));
//2017/04/24 会計の新レーアウトのラベル追加　by zy END
//2017/05/26 印刷の支払いレーアウト追加　by zy BEGIN
			p.put('pays' , objLst);
//2017/05/26 印刷の支払いレーアウト追加　by zy END
	    	m.put('sequence', info.simpleLayout);
	    //会計
		} else if (LayoutType.ACCOUNT == layoutStr) {
			p.put('company' , encode(para.company));
	        p.put('address' , encode(para.address));
	        p.put('postno'	, encode(para.postno));// 郵便番号
	        p.put('telno'	, encode(para.telno) );
			// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy BEGIN
	        // p.put('receiptno', encode(acc.Field145__c));//レシートNO
			p.put('receiptno', encode(recpitNo));//レシートNO
			// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy END
	        p.put('empno'   , encode(para.empno));
	        //p.put('datetime', encode(dtFormatStr) );
	        p.put('rows'	, rowDetail);	
	        p.put('subTotal', subTotalStr );
	        p.put('total'   , total );
	        p.put('tax'     , tax );
	        p.put('recevied', recevied);
	        p.put('change'  , change);
	        //2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
	        //p.put('cmimg'   , getImageBase64String());
	        p.put('cmimg'   , camp.photo);
	        //2017/03/06 キャパンのデフォルト値設定する　by zy END
	    	p.put('qrurl'   , campQrUrl);
	    	//2017/04/17 layout 对应 by BEGIN
	    	p.put('newsmsg'   , camp.getNewMessage(info.headStanFlag));
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
	    	p.put('printno'  , encode(info.printNo));
//2017/04/24 会計の新レーアウトのラベル追加　by zy END
	    	//2017/04/17 layout 对应 by END
//2017/05/26 印刷の支払いレーアウト追加　by zy BEGIN
	    	p.put('pays' , objLst);
//2017/05/26 印刷の支払いレーアウト追加　by zy END
			p.put('hikae' , '');
	    	m.put('sequence', info.accountLayout);
		//オーダー
		} else if (LayoutType.ORDER == layoutStr) {
			p.put('orderplace' , '');
	        p.put('orderno' , '');
	        p.put('custname' , '');
	        p.put('allergie' , '　' );
	        //2017/04/28 empno layout追加　by　zy BEGIN
	        p.put('empno'   , encode(para.empno));
	        //2017/04/28 empno layout追加　by　zy END
	        p.put('rows'	, rowDetail);
	        p.put('time' , dt.format('HH:mm') );
	        p.put('orderurl'   , accountURL);
	        m.put('sequence', info.repiceLayout);
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
	    	p.put('printno'  , encode(info.printNo));
//2017/04/24 会計の新レーアウトのラベル追加　by zy END
		} else if (LayoutType.DOOROPEN == layoutStr) {
	        m.put('sequence', info.doorOpenLayout );
		}
    	/*
    	if (layoutStr == LAOUT_1 || layoutStr == LAOUT_3 ) {
	    	p.put('company' , encode(para.company));
	        p.put('address' , encode(para.address));
	        p.put('postno'	, encode(para.postno));// 郵便番号
	        p.put('telno'	, encode(para.telno) );
	        p.put('receiptno', encode(acc.Field145__c));//レシートNO
	        p.put('empno'   , encode(para.empno));
	        //p.put('datetime', encode(dtFormatStr) );
	        p.put('rows'	, rowDetail);	
	        p.put('subTotal', subTotalStr );
	        p.put('total'   , total );
	        p.put('tax'     , tax );
	        p.put('recevied', recevied);
	        p.put('change'  , change);
	        p.put('cmimg'   , getImageBase64String());
	        
	    	p.put('qrurl'   , CommUtils.nullToBlank(accountURL));
	    	if (layoutStr == LAOUT_3){
	    		p.put('newsmsg'   ,encode(  getInstance().camp.message));
	    	}
    	} else if (layoutStr == LAOUT_2) {
	        //p.put('sfdclogo' , '');
	        p.put('orderplace' , '');
	        p.put('orderno' , '');
	        p.put('custname' , '');
	        p.put('allergie' , '　' );
	        p.put('rows'	, rowDetail);
	        p.put('time' , dt.format('HH:mm') );
	        p.put('orderurl'   , CommUtils.nullToBlank(accountURL));
	        //p.put('cmimg'   , getImageBase64String());
    	}
    	*/
//2017/02/22 source整理 by zy END
    	if (otherMap != null) {
    		for ( String key : otherMap.keySet()){
    			if(m.containsKey(key)) m.put(key,otherMap.get(key));
    			if(p.containsKey(key)) p.put(key,otherMap.get(key));
    		}
    	}
    	p.put('posno'   , encode(info.posno));//レシートプリンターNO
    	// 2017/08/22 special字処理　by zy BEGIN
    	p.put('datetime', encode(dtFormatStr).replace('%24%24','%20'));
    	//p.put('datetime', encode(dtFormatStr) );
    	// 2017/08/22 special字処理　by zy END
    	m.put('headstand' , info.headStanFlag);
//2017/02/22 source整理 by zy BEGIN
    	//m.put('sequence', info.repiceLayout);
//2017/02/22 source整理 by zy END
	    m.put('parameter', p);
	    //2017/04/17 layout 对应 by BEGIN
        //results.add(m);
        //printJson = JSON.serialize(results);
    	return m;
    	//2017/04/17 layout 对应 by END
    }
    // 会計明細情報により、金額と消費税金額を計算を行う
    private static TranResult calDetailPrice(AccountAcount__c acc, List<Tran1__c> trans) {
    	// 指定の商品明細はプランするがどうかチェックする、プランの場合、プランの明細を取得して、該当プランの明細により、金額を自動計算を行う
    	TranResult res = new TranResult();
    	// プラン商品のIDリストを格納する
    	//Set<Id> planProdIdSet = new Set<Id>();
    	// 支払商品のIDリストを格納する
    	//Set<Id> payProdIdSet = new Set<Id>();
		// 単価定義区分はシステム現状の単価定義区分でそのまま使う
//		CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
		// 消費税レートを取得する
		Decimal taxRate = getTaxRate(acc);
		// 非課税商品金額合計値を格納する
		Decimal noTaxRateAmount = 0;
		// 支払金額合計値
		Decimal payAmount = 0;
    	for (Tran1__c tran : trans) {
    		// プラン商品を指定される場合
    		Decimal wktaxRate = CommUtils.nullToZero(tran.TaxRate__c);
			// 商品消費税計算を行う
    		priceInfo.process(CommUtils.nullToZero(tran.Field20__c) , CommUtils.nullToZero(tran.Field21__c), wktaxRate, CommUtils.nullToZero(tran.ServiceRate__c));
    		//if (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) planProdIdSet.add(tran.Field7__c);
    		// プラン商品は支払商品の場合「簡易会計は現金とクレジットカード、オーダーエントリは支払情報がないの前提条件で対応を行う」
    		if (tran.ActionType__c == CommConst.PROD_ACTION_TYPE_PY) {
    			payAmount += priceInfo.priceIncTax;
    		} else {
	    		// 合計金額を格納する
	    		res.tranTotal += priceInfo.priceIncTax;
	    		// 消費税金額は非課税の場合、
	    		if (wktaxRate == 0) {
	    			noTaxRateAmount += priceInfo.priceIncTax;
	    		}
    		}
    	}
    	// 合計金額から消費税を計算する
    	Decimal locAmoutIncTaxprice =  res.tranTotal - noTaxRateAmount;
    	res.tranTax = (taxRate > 0) ? (CommUtils.RoundProcess(locAmoutIncTaxprice / (1 + taxRate / 100) * (taxRate / 100), CommUtils.getPointLen())) : 0;
    	// お釣り金額を計算する
    	//2017/02/22 預ｶﾘ金額処理　by　zy　BEGIN
    	res.tranCharge = payAmount - res.tranTotal ;// res.tranTotal - payAmount
    	res.tranPaymount = payAmount;
    	//2017/02/22 預ｶﾘ金額処理　by　zy　END
    	return res;
    	/*
    	// プラン商品が存在する場合、プラン明細を取得して、プラン明細の非課税、課税を別して、消費税を計算
    	// 商品プランIDと関連のプラン明細
    	Map<Id, List<PlanDetail__c>> planDetailMap = new Map<Id, List<PlanDetail__c>>();
    	if (!planProdIdSet.isEmpty()) {
    		// プラン明細を取得する
           for (PlanDetail__c pd : [select Id, AccountMasterRef__c, AccountMasterRef__r.Name, AccountMasterRef__r.ActionType__c,
	        						AccountMasterRef__r.SCP_5__c, AccountMasterRef__r.TaxRateCal__c,
	        						AccountMasterRef__r.Field4__c,
	                                AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, JmstRef__c,
	                                ServiceRate__c, ProductNumber__c, PlanProdcut__c
	                                from PlanDetail__c where PlanProdcut__c in :planProdIdSet]) {
	            // 商品（プラン）非存在する場合
	            if (!planDetailMap.containsKey(pd.PlanProdcut__c)) {
	                List<PlanDetail__c> pdLst = new List<PlanDetail__c>();
	                pdLst.add(pd);
	                planDetailMap.put(pd.PlanProdcut__c, pdLst);
	            } else {
	                planDetailMap.get(pd.PlanProdcut__c).add(pd);
	            }
	        }
		}
		// 単価定義区分はシステム現状の単価定義区分でそのまま使う
		CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
		// 会計明細の合計金額、消費税、単価計算する、最後の合計消費税を計算する
		for (Tran1__c tran : trans) {
			// プランの場合、プラン明細から計算を行う
			if (planDetailMap.containsKey(tran.PlanProdcut__c)) {
				
			}
			// 支払商品の場合、合計金額からお釣り計算用、消費税など合計計算対象外
			
			// 普通の商品の場合、正常な消費税計算を行う
		}
		*/
    }
    //get Tax
    public static Decimal getTaxRate(AccountAcount__c acc){
    	// 会計日付にて、消費税計算を行う[会計日付から税率を取得する][連泊場合：初日の税率で]
    	// TODO:最後の会計日の消費税率で計算を行う
    	Decimal taxRate = acc.TaxRate__c;
    	// 会計に該当消費税が未設定する場合、会計に所属する会計明細から消費税率を取得する
    	if (CommUtils.nullToZero(taxRate) == 0) {
    		// 消費税率＞０　AND　BreakDown明細以外の会計明細を消費税率を取得する
    		List<Tran1__c> taxtranLst = [	select Id, TaxRate__c from Tran1__c 
    										where ParentTran1Ref__c = null And Field1__c = : acc.Id And TaxRate__c > 0 
    										limit 1];
    		if (!taxtranLst.isEmpty()) taxRate = taxtranLst[0].TaxRate__c;
    	}
    	return taxRate;
    }
    //获取图片编码
    
    private static String getImageBase64String(String curDocument) {
        String ret = '';
        //String curDocument = getInstance().imgDocumentName;
        if (!CommUtils.isBlank(curDocument)){
	        List<Document> imgs = [select body, name from Document where DeveloperName = :curDocument order by CreatedDate];
	        if (!imgs.isEmpty()){
	        	ret = EncodingUtil.base64Encode(imgs[0].body);
	        }
        }
        return ret;
    }
	/*
	* 配置信息读取
	*/
    private void printLoad(){
		autoStemp = 0;
		prodCodeSet = new Set<String>();
		deviceMap = new Map<String,Set<Decimal>>();
		// 表示するボタン情報を配列に格納する
		buttonTabs = new List<Dom.XmlNode>();
		
		// 処理ターゲットのNODEを取得する
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
		Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('OrderProductConfig', inShopCode,new String[]{'<LOGOIMG>','</LOGOIMG>','<ROOMFILTER>','</ROOMFILTER>'});
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
//2017/03/12 キャンペーンタイプ区分　by zy BEGIN			
		Dom.XmlNode campTypeNode = targetNode.getChildElement('CAMPTYPE',null);
		String campType = '2';
		if (campTypeNode != null){
			campType = campTypeNode.getText();
		}
		Campain xmlCamp = new Campain();
//2017/03/12 キャンペーンタイプ区分　by zy END
// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
		customLst = new List<CustomInfo>();
// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
// 2017/09/26 会計明細削除する　by　zy BEGIN
		deleteFlag = true;
// 2017/09/26 会計明細削除する　by　zy END
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
		deviceFilter = new deviceFilter();
		basePrintPara = getBaseParaInfo(inShopCode);
		// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw BEGIN
		menuZoomFlag = null;
		roomZoomFlag = null;
		// 移動デバイス有効な
		onlyMobileFlag = true;
		// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw END
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		layouDevlopMap = new Map<String,LacationInfo>();
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
		cookDoneFlag = false;
		// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
		selLeadRoomFlg = false;
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
		// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　BEGIN
		kitchenOrderOnlyFlg = true;
		// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　END
		// 2020/04/30 「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
		// 2020/04/30 6236 bug fix by zy BEGIN
		orderItemToMaseterFlg = false;
		// 2020/04/30 6236 bug fix by zy END
		// 2020/04/30 「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
		// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
		orderPriceInputFlg = false;
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
		// ボタン定義情報を取得する
		for(Dom.XMLNode xmlNode : targetNode.getChildElements()) {
			// タグ名
			String attributeName = xmlNode.getName();
			
			if(attributeName.equalsIgnoreCase('SHOPCODE')){
				oShopCode = CommUtils.nullToBlank(xmlNode.getText());
				continue;	// 店舗情報のタグ
			}
			// 個別ボタン設定情報を取得、設定する
			if(attributeName.equalsIgnoreCase('BUTTONTAB')){
				buttonTabs.add(xmlNode);
				continue;
			}else if(attributeName.equalsIgnoreCase('PRINTCONFIG')){
				PrintInfo p = new PrintInfo(xmlNode);
				if (CommUtils.isBlank(curPrint.prinUrl)) curPrint = p;
				if (!printConifgMap.containsKey(p.printName))
					printConifgMap.put(p.printName,p);
					//2017/07/03 レビュー更新する　by　zy　BEGIN
					printNoMap.put(p.printNo,p);
					//2017/07/03 レビュー更新する　by　zy　END
					// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
					printLst.add(p);
					// 2017/07/12 印刷リスト序列化改修 by zy END
			}else if(attributeName.equalsIgnoreCase('LOGOIMG')){
				LogoIcon = xmlNode.getText();
			}else if(attributeName.equalsIgnoreCase('CANCELTIMERANGE')){
				autoStemp = CommUtils.nullToIntZero(xmlNode.getText());
			}else if (attributeName.equalsIgnoreCase('DEVICECONFIG')) {
				for ( Dom.XMLNode node : xmlNode.getChildElements()){
					String printName = '';
					String localStr = '1';
					String roomNodeStr = '';
					String layoutStr = '';
					//2017/04/28 device 改修 by zy BEGIN
					Device dev = new Device();
					//2017/04/28 device 改修 by zy END
					Dom.XMLNode localNode = node.getChildElement('LOCAL',null); 
					Dom.XMLNode roomNode = node.getChildElement('ROOMSEQ',null);
					Dom.XMLNode printNode = node.getChildElement('PRINTER',null);
//2017/04/17 layout 对应 by BEGIN
					Dom.XMLNode accountNode = node.getChildElement('ACCOUNTPRINTER',null); 
					Dom.XMLNode simpleNode = node.getChildElement('SPACCOUNTPRINTER',null); 
//2017/04/17 layout 对应 by END
					Dom.XMLNode layoutNode = node.getChildElement('LAYOUT',null);
					//2017/04/28 device 改修 by zy BEGIN
					Dom.XMLNode posNode = node.getChildElement('POSNO',null); 
					Dom.XMLNode printNoNode = node.getChildElement('PRINTNO',null); 
					//2017/04/28 device 改修 by zy END
					// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
					Dom.XMLNode fieldNodes = node.getChildElement('FIELDS',null); 
					// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
					// 2018/06/12 SCANER機能新規 by zy BEGIN
					Dom.XMLNode scanerFieldNode = node.getChildElement('SCANNER',null);
					// 2018/06/12 SCANER機能新規 by zy END
					//ip地址
					if (localNode != null) localStr = CommUtils.nullToBlank(localNode.getText());
					//房间编号
					if (roomNode != null) roomNodeStr = CommUtils.nullToBlank(roomNode.getText());
					//打印机名
					if (printNode != null) printName = CommUtils.nullToBlank(printNode.getText());
					Set<Decimal> roomSet = new Set<Decimal>();
//system.debug(logginglevel.info,'roomNodeStr:::' + roomNodeStr);
					if (!CommUtils.isBlank(roomNodeStr)) {
						for (String roomSeq : roomNodeStr.split(',')) {
							if(!CommUtils.isBlank(roomSeq)) {
//system.debug(logginglevel.info,'roomNodeStr:::' + roomNodeStr);
								roomSet.add(CommUtils.nullToZero(roomSeq));
							}
						}
						
					}
					if (layoutNode != null) layoutStr =  CommUtils.nullToBlank(layoutNode.getText());
//system.debug(logginglevel.info,'roomNodeStr:::' + roomNodeStr);
					deviceMap.put(localStr,roomSet);
//system.debug(logginglevel.info,'localStr:::' + localStr + '--' + printName);
					//2017/04/17 layout 对应 by BEGIN
					if (accountNode != null) {
						ipToSpecialMap.put(localStr + LayoutType.ACCOUNT,CommUtils.nullToBlank(accountNode.getText()));
					} else ipToSpecialMap.put(localStr + LayoutType.ACCOUNT,printName);
					if (simpleNode != null) {
						ipToSpecialMap.put(localStr + LayoutType.SIMPLEACCOUNT,CommUtils.nullToBlank(simpleNode.getText()));
					} else ipToSpecialMap.put(localStr + LayoutType.SIMPLEACCOUNT,printName);
					ipToSpecialMap.put(localStr + LayoutType.ORDER, printName);
					//2017/04/28 device 改修 by zy BEGIN
					if (posNode != null) {
						dev.posNo = CommUtils.nullToBlank(posNode.getText());
					}
					if (printNoNode != null) {
						dev.printNo = CommUtils.nullToBlank(printNoNode.getText());
					}
					dev.localIp = localStr;
					// 2018/06/12 SCANER機能新規 by zy BEGIN
					if (scanerFieldNode != null) {
						dev.scanerFlag = boolean.valueOf(CommUtils.nullToBlank(scanerFieldNode.getText()));
						// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
						String autoConnectStr = CommUtils.nullToBlank(scanerFieldNode.getAttribute('AUTOCONNECT',null ));
						if (!CommUtils.isBlank(autoConnectStr)) dev.autoConnectFlg = boolean.valueOf(autoConnectStr);
						// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
					}
					// 2018/06/12 SCANER機能新規 by zy END
					ipToDeviceMap.put(localStr,dev);
					//2017/04/28 device 改修 by zy END
					//2017/04/17 layout 对应 by END
					roomToPrintMap.put(localStr,printName);
					ipToLayoutMap.put(localStr,layoutStr);
				}
			/*
			明细页面中上下背景
			} else if (attributeName.equalsIgnoreCase('DETAILTOPIMG')) {
				cusTopImgBack = CommUtils.nullToBlank(xmlNode.getText());
			} else if (attributeName.equalsIgnoreCase('DETAILBOTTOMIMG')) {
				cusBtmImgBack = CommUtils.nullToBlank(xmlNode.getText());
			*/
			} else if (attributeName.equalsIgnoreCase('WAITERMODE')) {
				noImgFlag = boolean.valueOf(xmlNode.getText());
			} else if (attributeName.equalsIgnoreCase('IMGSAMESIZE')) {
				SameSizeFlag = boolean.valueOf(xmlNode.getText());
			//2017/01/10 demo mode by zy BEGIN
			} else if (attributeName.equalsIgnoreCase('DEMODATE')) {
				demoDate = CommUtils.nullToBlank(xmlNode.getText());
				String simpleDemoDateStr = CommUtils.nullToBlank(xmlNode.getAttribute('SIMPLE',null));
				//如果设置过simple，则简易会计会被排除
				boolean simpleFlag = boolean.valueOf(simpleDemoDateStr);
				if (!simpleFlag) simpleDemoDate = demoDate;
			} else if (attributeName.equalsIgnoreCase('CAMPAIGN')) {
				Dom.XMLNode urlNode = xmlNode.getChildElement('URL',null); 
				Dom.XMLNode messageNode = xmlNode.getChildElement('MESSAGE',null);
				Dom.XMLNode imageNode = xmlNode.getChildElement('IMGNAME',null);
//2017/02/22 print 倒影处理 by zy BEGIN
				Dom.XMLNode messageLineNode = xmlNode.getChildElement('MESSAGELINE',null);
//2017/02/22 print 倒影处理 by zy END
				if (urlNode != null) xmlCamp.qrUrl = CommUtils.nullToBlank(urlNode.getText());
				//2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
				if (messageNode != null) {
					// 新＋product	
					xmlCamp.message = CommUtils.nullToblank(messageNode.getText());
				}
				//2017/03/06 キャパンのデフォルト値設定する　by zy END
				if (imageNode != null) xmlCamp.docName = CommUtils.nullToblank(imageNode.getText());
//2017/02/22 print 倒影处理 by zy BEGIN
				if (messageLineNode != null) xmlCamp.rowLen = CommUtils.nullToIntZero(CommUtils.nullToblank(messageLineNode.getText()));
//2017/02/22 print 倒影处理 by zy END
			//2017/04/20 簡易オーダーのボタンカスタム設定　by　zy　BEGIN
			} else if (attributeName.equalsIgnoreCase('LAYOUTSTYLE')) {
				Dom.XMLNode widNode = xmlNode.getChildElement('BTNWIDTH',null); 
				Dom.XMLNode fontNode = xmlNode.getChildElement('BTNFONTSIZE',null); 
				if (widNode != null) {
					if (!CommUtils.isBlank(widNode.getText()))
					simpleWith = widNode.getText();
				}
				if (fontNode != null) {
					if (!CommUtils.isBlank(fontNode.getText()))
					fontSize = fontNode.getText();
				}
			}
			//2017/04/20 簡易オーダーのボタンカスタム設定　by　zy　END
			//2017/01/10 demo mode by zy END
			// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
			 else if (attributeName.equalsIgnoreCase('INFO_CUSTOME_DEF')){
			 	for (Dom.XMLNode customNode : xmlNode.getChildElements()) {
			 		customLst.add(new CustomInfo(customNode));
			 	}
			 }
			 // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
			 // 2017/09/26 会計明細削除する　by　zy BEGIN
			else if (attributeName.equalsIgnoreCase('DELETEFLAG')) { 
				String deleteStr = CommUtils.nullToBlank(xmlNode.getText());
				if (!CommUtils.isBlank(deleteStr)) deleteFlag = boolean.valueOf(deleteStr);
			}
			// 2017/09/26 会計明細削除する　by　zy END
			// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
			else if (attributeName.equalsIgnoreCase('DEVICEFILTER')) {
				deviceFilter = new DeviceFilter(xmlNode);
			}
			// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
			// 2018/07/26 QRコード印刷対応 by zy BEGIN
			else if (attributeName.equalsIgnoreCase('QRCODEINFO')) {
				printOther = new PrintOtInfo(xmlNode);
			}
			// 2018/07/26 QRコード印刷対応 by zy END
			else if (attributeName.equalsIgnoreCase('FOODSCHEDULE')) {
				Dom.XmlNode foodTypeNode = xmlNode.getChildElement('FOODOPTYPE',null);
				if (foodTypeNode != null) {
					String prodStr = foodTypeNode.getText();
					if (!CommUtils.isBlank(prodStr)) cookProds = new Set<String>(CommUtils.nullToBlank(prodStr).deletewhitespace().split(','));
				}
				// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
				String orderStr = xmlNode.getAttribute('FINISHNOSHOW',null);
				if (!CommUtils.isBlank(orderStr))
					cookDoneFlag = boolean.valueOf(Commutils.nullToBLank(orderStr));
				// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
				// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　BEGIN
				String kitchenStr = xmlNode.getAttribute('KITCHENORDERONLY',null);
				if (!CommUtils.isBlank(kitchenStr))
					kitchenOrderOnlyFlg = boolean.valueOf(Commutils.nullToBLank(kitchenStr));
				// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　END
			}
			// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw BEGIN
			else if (attributeName.equalsIgnoreCase('ZOOM')) {
				String mobileFlag = xmlNode.getAttribute('ONLYMOBILE',null);
				// 移動デバイス有効な
				if (mobileFlag != null) onlyMobileFlag = boolean.valueOf(CommUtils.nullToBlank(mobileFlag));
				Dom.XmlNode menuZoomNode = xmlNode.getChildElement('MENUZOOM',null);
				if (menuZoomNode != null) {
					String sizeStr = CommUtils.nullToBlank(menuZoomNode.getText());
					if (sizeStr.isNumeric()) menuZoomFlag = sizeStr;
				}
				// 2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw BEGIN
				Dom.XmlNode roomZoomNode = xmlNode.getChildElement('ROOMZOOM',null);
				if(roomZoomNode != null) {
					roomZoomFlag = new Map<string, string>{'fontSize' => '', 'width' => '', 'height' => ''};
					String fontSize = CommUtils.nullToBlank(roomZoomNode.getText());
					if(fontSize.isNumeric()) roomZoomFlag.put('fontSize', fontSize);
					String width = CommUtils.nullToBlank(roomZoomNode.getAttribute('WIDTH', null));
					String height = CommUtils.nullToBlank(roomZoomNode.getAttribute('HEIGHT', null));
					if(width.isNumeric()) roomZoomFlag.put('width', width);
					if(height.isNumeric()) roomZoomFlag.put('height', height);
				}
				// 2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw END
			}
			// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw END
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
			else if (attributeName.equalsIgnoreCase('SAMEPRODMERGE')) {
				String transMergeStr = CommUtils.nullToBlank(xmlNode.getText());
				if (!CommUtils.isBlank(transMergeStr)) transMergeFlg = boolean.valueOf(transMergeStr);
			}
			// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
			// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
			else if (attributeName.equalsIgnoreCase('ROOMFILTER')) {
				String leadSQLWhere = CommUtils.nullToBlank(xmlNode.getText());
				if (!CommUtils.isBlank(leadSQLWhere)) leadSQLst.add('(' + leadSQLWhere + ')');
			}
			// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
			else if (attributeName.equalsIgnoreCase('LOCATIONS')){
				// 画面表示時間リスト設定
				for (Dom.XMLNode bussTmNode : xmlNode.getChildElements()) {
					// タグ名
					String nodeName = bussTmNode.getName();
					if ('LOCATION' == nodeName) {
						LacationInfo loc = new LacationInfo();
						for (Dom.XMLNode localNode : bussTmNode.getChildElements()){
							String localNodeName = localNode.getName();
							if (localNodeName == 'NAME') loc.name = CommUtils.nullToBlank(localNode.getText());
							else if (localNodeName == 'TIME') {
								// 表示料理ー＞時間ラベル
								Dom.XMLNode layoutNode = localNode.getChildElement('LAYOUT',null);
								// 表示料理ー＞開始時間
								Dom.XMLNode beginNode = localNode.getChildElement('BEGIN',null);
								// 表示料理ー＞終了時間
								Dom.XMLNode endNode = localNode.getChildElement('END',null);
								// 表示料理ー＞食べ時間
								Dom.XMLNode cookNode = localNode.getChildElement('COOKTIME',null);
					    		
								String layout = '';
								String beginTm = '';
								String endTm = '';
								String cookTm = '';
								if (layoutNode != null) layout = CommUtils.nullToBlank(layoutNode.getText());
								if (beginNode != null) beginTm = CommUtils.nullToBlank(beginNode.getText());
								if (endNode != null) endTm = CommUtils.nullToBlank(endNode.getText());
								if(cookNode != null) cookTm = CommUtils.nullToBlank(cookNode.getText());
								LacationInfo childInfo = new LacationInfo();
								childInfo.name = layout;
								childInfo.startTm = beginTm;
								childInfo.endTm = endTm;
								childInfo.cookTm = cookTm;
								// 料理開始時刻判定
								if (!CommUtils.isBlank(layout) && !CommUtils.isBlank(beginTm) && !CommUtils.isBlank(endTm)){
									// 料理開始時刻あり
									Date dt = system.today();
									Datetime begDt = CommUtils.convertDatetime(dt, beginTm);
									Datetime endDt = CommUtils.convertDatetime(dt, endTm);
									Datetime cookDt = system.now();
									if(cookDt >= begDt && cookDt <= endDt) {
										childInfo.isCurrent = true;
									}
								}
								loc.locations.add(childInfo);
							} else if ( localNodeName == 'ROOMTYPESEQ') {
								String roomTypeSeq = localNode.getText();
								loc.roomtypeStr = CommUtils.nullToBlank(roomTypeSeq);
							}
						}
						layouDevlopMap.put(loc.name,loc);
					}
				}
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
			// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
			} else if (attributeName.equalsIgnoreCase('CREATEINFO')) {
				isMultiRoomFlg = true;
				// 2020/04/30 「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
				String orderItemStr = xmlNode.getAttribute('ODERITEMTOMASTER',null);
				if (!CommUtils.isBlank(orderItemStr)) orderItemToMaseterFlg = boolean.valueOf(orderItemStr);
				// 2020/04/30 「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
				for (Dom.XMLNode infoNode : xmlNode.getChildElements()){
					String infoNodeName = infoNode.getName();
					if (infoNodeName == 'LEADINFO') {
						LeadInfo leadInfo = new LeadInfo(infoNode);
						// 初始化方法，默认房型设定方案
						if (leadMap.isEmpty()) leadMap.put('',leadInfo);
						leadMap.put(leadInfo.roomType,leadInfo);
					// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
					} else if (infoNodeName == 'MERGEINFO') {
						selLeadRoomFlg = true; // モード設定
						LeadInfo leadInfo = new LeadInfo(infoNode); // 情報作成
						// 初始化方法，默认房型设定方案
						leadMap.put('BLANK',leadInfo);
					}
					// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
				}
			}
			// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
			// 2020/02/15 初期画面を「テーブル選択画面」にする by zy BEGIN
			else if (attributeName.equalsIgnoreCase('ROOMPAGEAUTOSHOW')) {
				String pageShow = Commutils.nullToBlank(xmlNode.getText());
				if (!CommUtils.isBlank(pageShow))roomPageOpenFlg = boolean.valueOf(pageShow);
			}
			// 2020/02/15 初期画面を「テーブル選択画面」にする by zy END
			// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
			else if (attributeName.equalsIgnoreCase('ORDERCONFIG')) {
				Dom.XmlNode priceChangeNode = xmlNode.getChildElement('PRICECHANGE',null);
				if (priceChangeNode != null) {
					orderPriceInputFlg = boolean.valueOf(CommUtils.nullToBlank(priceChangeNode.getText()));
				}
			}
			// 2020/06/30 オーダエンドリーでの金額入力 by zy END
		}
		camp = chkCampType(camp,xmlCamp,campType);
    }
    private static Campain chkCampType(Campain camp,Campain xml , String cmapType){
    	Campain c = new Campain();
    	c.rowLen = xml.rowLen;
    	if (cmapType == '1') {
    		c.message = camp.message;
    		c.qrUrl = camp.qrUrl;
    		c.photo = camp.photo;
    	} else if (cmapType == '3') {
    		c.message = camp.message + xml.message;
    		c.qrUrl = camp.qrUrl;
    		c.photo = camp.photo;
    	} else {
    		c.message = xml.message;
    		c.qrUrl = xml.qrUrl;
    		c.photo = getImageBase64String(xml.docName);
    	}
    	return c;
    }
    //encode加密
    public static String encode(Object para) {
    	String paraStr = CommUtils.nullToBlank(para);
    	if (CommUtils.isBlank(paraStr)) return '';
        return EncodingUtil.urlEncode(paraStr, 'UTF-8');
    }
    public static String currency(Decimal i) {
    	List<String> args = new String[]{'0','number',CommBaseCtrl.getNumberFormat()};
		String s = String.format(i.format(), args);
    	return CommBaseCtrl.getCurrencySybmol() + s;
	}
    //m.put('headstand', false);
    /**
    * 打印信息作成
    */
    public class PrintPara{
		public String empno;
		String posno;
        String change;
        String recevied;
        String tax;
        String total;
        String subTotal;
        //String datetime;
        public String telno;
        public String address;
        public String company;
        public String postno;//郵便番号
        public PrintPara(){
        	
        }
	}
	
    /*
	* プリンターのクラス
	*/
	public class PrintInfo{
		//打印机链接地址
		public String prinUrl;
	 	//打印链接地址
	 	public String statusUrl;
	 	//打印layout区分
		public String repiceLayout;
//2017/02/22 source整理とlayout区分 by zy BEGIN
		public String doorOpenLayout;
		public String simpleLayout;
		public String accountLayout;
//2017/02/22 source整理とlayout区分 by zy END
		public String roomOrderLayout;
		//打印机名称
		public String printName;
		//打印机编号
		public String posNo;
		public PrintPara par;
		//顾客名
		public String customName;
		String itemMark;
		public boolean headStanFlag;
		//打印机链接方式
		String printWs;
//2017/02/22 source整理とlayout区分 by zy BEGIN
		//dooropen功能
		//String doorOpenSeq;
//2017/02/22 source整理とlayout区分 by zy BEGIN
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
		public String printNo;
//2017/04/24 会計の新レーアウトのラベル追加　by zy END
//2017/06/12 設備のメーセッジ機能　by　zy BEGIN
		public String deviceUrl;
//2017/06/12 設備のメーセッジ機能　by　zy END
//2017/06/26　控えのフィルター追加　by　zy　BEGIN
		public String fieldHitotu;
//2017/06/26　控えのフィルター追加　by　zy　END
// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
		public String barCodeLayout;
		public String barCodeField;
// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
		// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
		public String layoutType;
		// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
		public PrintInfo(){
			prinUrl = '';
			printName = '';
			statusUrl = '';
			repiceLayout = '';
			posNo = '';
			printWs = '';
			headStanFlag = false;
			par = new PrintPara();
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
			printNo = '';
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
// 2017/09/11 印刷リスト機能　by　zy　BEGIN
			itemMark = '';
// 2017/09/11 印刷リスト機能　by　zy　END
// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
			barCodeLayout = 'barcodeprint';
			barCodeField = '';
// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
			layoutType = '';
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
		}
		public PrintInfo(Dom.XMLNode xmlNode){
			prinUrl = 'localhost';
			statusUrl = 'localhost';
			headStanFlag = false;
			itemMark = '';
//2017/02/22 source整理とlayout区分 by zy BEGIN
			// 2017/05/30 デフォルトレーアウト変更　by　zy BEGIN
			accountLayout = 'retail_reciept1';
			//accountLayout = 'retail_reciept2';
			// 2017/05/30 デフォルトレーアウト変更　by　zy END
			simpleLayout = 'retail_reciept2';
			doorOpenLayout = 'kick_drawer'; 
			repiceLayout = 'table_reciept2';
			roomOrderLayout = 'ORDER';
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
			printNo = '';
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
//2017/06/26　控えのフィルター追加　by　zy　BEGIN
			fieldHitotu = '';
//2017/06/26　控えのフィルター追加　by　zy　END
// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
			barCodeLayout = 'barcodeprint';
			barCodeField = 'Field3__c';
// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
			layoutType = '';
			// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
			Dom.XMLNode printNode = xmlNode.getChildElement('PRINT',null); 
//2017/02/22 source整理とlayout区分 by zy END
			Dom.XMLNode layoutNode = xmlNode.getChildElement('LAYOUT',null);
			Dom.XMLNode statusNode = xmlNode.getChildElement('STATUS',null); 
			Dom.XMLNode ptPortNode = xmlNode.getChildElement('PRINTPORT',null); 
			Dom.XMLNode statusPortNode = xmlNode.getChildElement('STATUSPORT',null); 
			Dom.XMLNode posNode = xmlNode.getChildElement('POSNO',null); 
			Dom.XMLNode printWsNode = xmlNode.getChildElement('WEBSOCKET',null);
//2017/02/22 source整理とlayout区分 by zy BEGIN
			//Dom.XMLNode doorOpenSeqNode = xmlNode.getChildElement('DOOROPENSEQ',null);
			Dom.XMLNode headStandNode = xmlNode.getChildElement('HEADSTAND',null);
			Dom.XMLNode itemMarkNode = xmlNode.getChildElement('PREMARK',null);
//2017/02/22 source整理とlayout区分 by zy END
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
			Dom.XMLNode printNoNode = xmlNode.getChildElement('PRINTNO',null);
//2017/04/24 会計の新レーアウトのラベル追加　by zy END
//2017/06/26　控えのフィルター追加　by　zy　BEGIN
			Dom.XMLNode hitotuNode = xmlNode.getChildElement('HIKAE',null);
//2017/06/26　控えのフィルター追加　by　zy　END
			// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
			Dom.XMLNode barCodeFieldNode = xmlNode.getChildElement('BARCODEFIELD',null);
			// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
			if (xmlNode != null) {
				printName = CommUtils.nullToBlank(xmlNode.getAttribute('NAME',null));
			}
			//2017/06/12 設備のメーセッジ機能　by　zy BEGIN
			if (printNode != null && !CommUtils.isBlank(printNode.getText())) {
				prinUrl = printNode.getText();
				deviceUrl = prinUrl;
			}
			//2017/06/12 設備のメーセッジ機能　by　zy END
			if (ptPortNode != null && !CommUtils.isBlank(ptPortNode.getText())) prinUrl += ':' + ptPortNode.getText();
			else prinUrl += ':9999';
			if (statusNode != null && !CommUtils.isBlank(statusNode.getText())) statusUrl = statusNode.getText();
			if (statusPortNode != null && !CommUtils.isBlank(statusPortNode.getText())) statusUrl += ':' + statusPortNode.getText();
			else statusUrl += ':9999';
			//2017/02/22 source整理とlayout区分 by zy BEGIN
			//if (layoutNode != null && !CommUtils.isBlank(layoutNode.getText())) repiceLayout = layoutNode.getText();
			if (layoutNode != null) {
				
				Dom.XMLNode simpleAccountNode = layoutNode.getChildElement('SIMPLEACCOUNT',null);
				Dom.XMLNode doorOpenSeqNode = layoutNode.getChildElement('DOOROPENSEQ',null);
				Dom.XMLNode accountNode = layoutNode.getChildElement('ACCOUNT',null);
				Dom.XMLNode orderNode = layoutNode.getChildElement('ORDER',null);
				// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
				Dom.XMLNode barCodeNode = layoutNode.getChildElement('BARCODE',null);
				// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
				if (simpleAccountNode != null) simpleLayout = CommUtils.nullToBlank(simpleAccountNode.getText());
				if (doorOpenSeqNode != null ) doorOpenLayout = CommUtils.nullToBlank(doorOpenSeqNode.getText());
				if (accountNode != null)   accountLayout = CommUtils.nullToBlank(accountNode.getText());
				if (orderNode != null) repiceLayout = CommUtils.nullToBlank(orderNode.getText());
				// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
				if (barCodeNode != null) barCodeLayout = CommUtils.nullToBlank(barCodeNode.getText());
				// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
				// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
				Dom.XMLNode roomOrderNode = layoutNode.getChildElement('ROOMORDER',null);
				if (roomOrderNode != null) roomOrderLayout = CommUtils.nullToBlank(roomOrderNode.getText());
				// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
			}
			//2017/02/22 source整理とlayout区分 by zy END
			if (posNode != null) posNo = CommUtils.nullToBlank(posNode.getText());
			if (printWsNode != null && !CommUtils.isBlank(printWsNode.getText())) printWs = printWsNode.getText();
			else printWs = 'ws';
//2017/02/22 source整理とlayout区分 by zy BEGIN
			//doorOpenSeq = '';
			//if (doorOpenSeqNode != null ) doorOpenLayout = CommUtils.nullToBlank(doorOpenSeqNode.getText());
//2017/02/22 source整理とlayout区分 by zy END
			prinUrl = printWs + '://' + prinUrl + '/printer';
			statusUrl = printWs + '://' + statusUrl + '/status';
			if (headStandNode != null) headStanFlag = boolean.valueOf(CommUtils.nullToBlank(headStandNode.getText()));
			if (itemMarkNode != null) itemMark = CommUtils.nullToBlank(itemMarkNode.getText());
			par = new PrintPara();
//2017/04/24 会計の新レーアウトのラベル追加　by zy BEGIN
			if (printNoNode != null) {
				printNo = CommUtils.nullToBlank(printNoNode.getText());
			}
//2017/04/24 会計の新レーアウトのラベル追加　by zy END
			//2017/06/26　控えのフィルター追加　by　zy　BEGIN
			if (hitotuNode != null) {
				fieldHitotu = hitotuNode.getText();
			}
			//2017/06/26　控えのフィルター追加　by　zy　END
			// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
			if (barCodeFieldNode != null) barCodeField = CommUtils.nullToBlank(barCodeFieldNode.getText());
			// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
		}
	}
	//消费税等会计数据计算结果
	public class TranResult{
		public TranResult() {
			//2017/02/22 預ｶﾘ金額処理　by　zy　BEGIN
			tranTax = tranTotal = tranCharge = tranPaymount = 0;
			//2017/02/22 預ｶﾘ金額処理　by　zy　END
		}
		public Decimal tranTax;
		public Decimal tranTotal;
		public Decimal tranCharge;
		//2017/02/22 預ｶﾘ金額処理　by　zy　BEGIN
		public Decimal tranPaymount;
		//2017/02/22 預ｶﾘ金額処理　by　zy　END
	}
	//简易会计定义信息
	public class Campain{
		public String message;
		public String qrUrl;
		//2017/02/21 倒影处理用 by zy BEGIN
		public Integer rowLen;
		public String photo;
		public String docName;
		public Campain(){
			rowLen = 14;
			message = '';
			qrUrl = '';
			photo = '';
			docName = '';
		}
		//获取newmessage 倒影处理
		public String getNewMessage(boolean headFlag){
			//如果是倒影处理且换行数大于0
			if (headFlag && rowLen > 0 ) {
				String name = CommRepUtils.getPdfMaxShowStringNew(message,999,rowLen,'_$_','\n');
				List<String> contentLst = new List<String>();
				List<String> splitLst = new List<String>();
				String exportMessage = '';
				for (String mes : name.split('_\\$_')) {
					if(!CommUtils.isBlank(mes)) splitLst.add(mes);
				}
				for (Integer i = splitLst.size() ; i > 0 ; i--){
					String row = splitLst[i-1];
					if (!row.contains('\n')) row += '\n';
					exportMessage += row ;
				}
				return exportMessage;
			}
			return CommUtils.nullToBlank(message);
		}
		//2017/02/21 倒影处理用 by zy END
	}
	//2017/03/06 キャパンのデフォルト値設定する　by zy BEGIN
	/**
	*　キャパンの初期化
	**/
	private static Campain setDefaultCamp(){
		Campain camp = new Campain();
		try {
		// XMLに定義しているXMLのサイトURLを取得する
		BatchGetWebSiteInfo.ParseInfo websiteInf = BatchGetWebSiteInfo.getParseInfo();
		String msgDevelopNm = websiteInf.msgBlock.fileName;
		String imgDevelopNm = websiteInf.imgBlock.fileName;
		List<Document> docs = [select body, DeveloperName from Document where DeveloperName = :msgDevelopNm or DeveloperName = :imgDevelopNm order by CreatedDate];
		if (!docs.isEmpty()) {
			for (Document d : docs) {
				//メッセージ
				if (d.DeveloperName == msgDevelopNm) {
					camp.message = CommUtils.nullToBlank(d.body.toString());
				//LOGO
				} else if (d.DeveloperName == imgDevelopNm) {
					camp.photo = EncodingUtil.base64Encode(d.body);
				}
			}
		}
		camp.qrUrl = CommUtils.nullToBlank(websiteInf.sitePageUrl);
		} catch (Exception e) {}
		return camp;
	}
	//2017/03/06 キャパンのデフォルト値設定する　by zy END
	//2017/04/12 Security Fix　by　zy BEGIN
	public static List<Lead__c> queryLeadList(Id roomId,Date curDtDate) {
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		// 2020/02/28 SITE機能対応　by zy BEGIN
		return [select id,Rroom__c,EntryTime__c,Departure__c,field3__c,field4__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,CreatedDate,Field354__c,Rroom__r.name,RelContact__r.name,Name,StayNightCal__c,No__c,Rroom__r.ShopInfoRef__r.Shopcode__c,Field298__c from Lead__c 
		// 2020/02/28 SITE機能対応　by zy END
		// 2017/09/11 印刷リスト機能　by　zy　END
											where DAY_ONLY(convertTimezone(EntryTime__c)) <= : curDtDate  and DAY_ONLY(convertTimezone(Departure__c)) >= : curDtDate  and Rroom__c =:roomId and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG  
											order by EntryTime__c ];
	}
	//2017/04/12 Security Fix　by　zy END
	//2017/04/20 Security Fix　by　zy BEGIN
	private static final String ROOM_SORT_NAME_DIV = '1';
	private static final String ROOM_SORT_DIV = CommDefine__c.getOrgDefaults().RoomSortDiv__c == null ? ROOM_SORT_NAME_DIV : CommDefine__c.getOrgDefaults().RoomSortDiv__c;
	public static List<Room__c> getRoomLst(Set<Id> roomIds){
		List<Room__c> rooms = new List<Room__c>();
		if (!roomIds.isEmpty()) {
			if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
        		rooms = [select id,name,Floor__c,area__c,TypeRoomRef__c,TypeRoomRef__r.name,DisplayNo__c,Seq__c,TypeRoomRef__r.Seq__c,TypeRoomRef__r.RoomTypeCode__c from Room__c where id = :roomIds order by AREA__c asc, Floor__c asc, Seq__c asc];
//2017/05/26 無予約の部屋データ作成機能追加　by zy END 
        	} else {
//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
        		rooms = [select id,name,Floor__c,area__c,TypeRoomRef__c,TypeRoomRef__r.name,DisplayNo__c,Seq__c,TypeRoomRef__r.Seq__c,TypeRoomRef__r.RoomTypeCode__c from Room__c where id = :roomIds order by AREA__c asc, Floor__c asc, DisplayNo__c asc];
//2017/05/26 無予約の部屋データ作成機能追加　by zy END        	
        	}
		}
		return rooms;
	}
//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
	public static List<Room__c> getRoomLst(String spcd){
		String querySql = 'select id,name,Floor__c,area__c,TypeRoomRef__c,TypeRoomRef__r.name from Room__c ';
		//String shopInfoId = ShopInfoUtil.getShop(spcd).id;
		String sqlWhere = '';
		/*
		if (!CommUtils.isBlank(config.conditions)) {
			sqlWhere = 'where ' + config.conditions + ' and id != null';
		} else {
			sqlWhere = 'where ShopInfoRef__c = :shopInfoId and UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'';
		}*/
		//sqlWhere = 'where ShopInfoRef__r.ShopCode__c = :spcd and UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'';
		sqlWhere = 'where UseOfRoom__c = \'' + String.escapeSingleQuotes(CommConst.ROOM_UseOfType_Guest) + '\'';
		if (!CommUtils.isBlank(spcd)) {
			sqlWhere += ' and ShopInfoRef__r.ShopCode__c = :spcd ';
		}
		// 2019/02/15 部屋リスト表示並べ替え修正　by　zy　BEGIN
		// String sqlOrder = ' order by AREA__c asc, Floor__c asc, DisplayNo__c asc';
		String sqlOrder = ' order by AREA__c asc, Floor__c asc';
		if (ROOM_SORT_DIV == ROOM_SORT_NAME_DIV) {
			sqlOrder += ', Seq__c asc';
		} else {
			sqlOrder += ', DisplayNo__c asc';
		}
		// 2019/02/15 部屋リスト表示並べ替え修正　by　zy　END
//system.debug(logginglevel.info,'sql:::' + querySql + sqlWhere + sqlOrder);
		List<Room__c> rooms = Database.query(querySql + sqlWhere + sqlOrder);
//system.debug(logginglevel.info,'config:::' + config);
		return rooms;
	}
//2017/05/26 無予約の部屋データ作成機能追加　by zy END
	//2017/04/20 簡易オーダーのボタンカスタム設定　by　zy　BEGIN
	private String simpleWith;
	public static String getSimpleWidth(){
		return getInstance().simpleWith;
	}
	private String fontSize;
	public static String getFontSize(){
		return getInstance().fontSize;
	}
	//2017/04/20 簡易オーダーのボタンカスタム設定　by　zy　BEGIN
	//2017/04/20 Security Fix　by　zy END
	//2017/04/28 device 改修 by zy BEGIN
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
	public class Device{
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
		public String localIp;
		public String printNo;
		public String posNo;
		// 2018/06/12 SCANER機能新規 by zy BEGIN
		public boolean scanerFlag;
		// 2018/06/12 SCANER機能新規 by zy END
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
		public boolean autoConnectFlg;
		// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
		public Device(){
			localIp = '';
			printNo = null;
			posNo = null;
			// 2018/06/12 SCANER機能新規 by zy BEGIN
			scanerFlag = false;
			// 2018/06/12 SCANER機能新規 by zy END
			// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy BEGIN
			autoConnectFlg = false;
			// 2020/12/15 会計商品にJANコードを登録し、それをバーコードリーダーで読み取り、会計処理が行えるようにしたい by zy END
		}
	}
	//2017/04/28 device 改修 by zy END
	//2017/05/22 会計save by zy BEGIN 
// 2017/07/10 ログ出力機能を追加する BEGIN
	//public static BillInput_Ctrl upsertBillData(Date procDate,List<Tran1__c> oTranLst,String roomId,String oShopCode) {
	public static BillInput_Ctrl upsertBillData(Date procDate,List<Tran1__c> oTranLst,String roomId,String oShopCode,String localIp) {
// 2017/07/10 ログ出力機能を追加する BEGIN
		String todayRsvName = (DateTime.newInstance(procDate.year(), procDate.month(), procDate.day())).format('yyyyMMdd');
		List<RsvAccount__c> existRsvLst = [select id from RsvAccount__c where Name = :todayRsvName limit 1];
		// 非存在する場合、自動売上データを作成する
		// 会計新規登録を行う
		ApexPages.StandardController contrl = new ApexPages.StandardController(new AccountAcount__c());
		// 2017/07/10 ログ出力機能を追加する BEGIN
		Map<String,String> paramMap = Apexpages.currentPage().getParameters();
		paramMap.put('ip',localIp);
		// 2017/07/10 ログ出力機能を追加する END
		BillInput_Ctrl bill = new BillInput_Ctrl(contrl);
		/* 2014.10.17 売上データ作成タイミング改善 */
		if (existRsvLst.isEmpty()) {
			RsvAccount__c nw = new RsvAccount__c(name = todayRsvName) ;
			upsert nw name;
			existRsvLst.add(nw);
		}
		// 売上
		String rsvAcountId = existRsvLst[0].id;
		bill.setOrderFlg(oShopCode);
		// 初期化処理
		bill.initAction();
		// 会計基本情報を設定する
		AccountAcount__c accAount = bill.oAcountSobj;
//system.debug(logginglevel.info,'accAount:::' + accAount);
		// 人数:Default 1
		accAount.Field66__c = '1';
		accAount.frs__c = rsvAcountId;
		// 売上計上日設定[2014/04/16] ADD
		accAount.SalesDate__c = procDate;
		// 2014/08/25 現状の単価定義区分を設定する
		accAount.UnitPriceDefKb__c = String.valueOf(CommConst.APPOPTION_UTP_DEF_KB);
		//2017/05/29 部屋テーブルＮｏ．の追加する　by zy BEGIN
		if (!CommUtils.isBlank(roomId)) {
			accAount.Field150__c = roomId;
			List<Room__c> rooms = getRoomLst(new set<Id>{roomId});
			if (!rooms.isEmpty()) {
				// 部屋情報設定
				accAount.RoomDisplayNo__c = rooms[0].DisplayNo__c;
				accAount.RoomSeq__c = rooms[0].Seq__c;
				accAount.RoomName__c = rooms[0].Name;
				// 部屋タイプ情報設定
				accAount.TypeOfRoomSeq__c = rooms[0].TypeRoomRef__r.Seq__c;
				accAount.TypeOfRoomCode__c = rooms[0].TypeRoomRef__r.RoomTypeCode__c;
				accAount.TypeOfRoomName__c = rooms[0].TypeRoomRef__r.Name;
			}
		}
		//2017/05/29 部屋テーブルＮｏ．の追加する　by zy end
		// 支払総金額
		Decimal dTotalPrice = 0;
		for (Tran1__c tran : oTranLst) {
			dTotalPrice += CommUtils.nullToZero(tran.Field23__c);
		}
		List<BillInput_Ctrl.TranItem> tranLst = bill.oTranSobjLst;
		tranLst.clear();
		for (Integer i = 0; i < oTranLst.size(); i++) {
			oTranLst[i].RelAccount__c = rsvAcountId;
			// 処理リストへ追加する
			BillInput_Ctrl.TranItem tranItem = new BillInput_Ctrl.TranItem(oTranLst[i], 0);
			tranItem.productNm = oTranLst[i].Field5__c;
			tranLst.add(tranItem);	
		}
	
		//会計処理を登録する
		bill.upsertData();
		return bill;
	}
	//2017/05/22 会計save by zy END 
//2017/05/26 部屋設定　by zy BEGIN	
	public class RoomConfig{
		String blankRoomId;
		String conditions;
		String blankRoomName;
		public RoomConfig(Dom.XMLNode xmlNode ) {
			Dom.XMLNode bankNode = xmlNode.getChildElement('BLANKROOMID',null); 
			Dom.XMLNode conNode = xmlNode.getChildElement('CONDITION',null); 
			Dom.XMLNode nameNode = xmlNode.getChildElement('BLANKROOMNAME',null); 
			if (bankNode != null) blankRoomId = bankNode.getText();
			if (conNode != null)  conditions = conNode.getText();
			if (nameNode != null) blankRoomName = nameNode.getText();
		}
		public RoomConfig () {
			blankRoomId = '';
			conditions = '';
			blankRoomName = '';
		}
	}
//2017/05/26 部屋設定　by zy END
//2017/05/26 無予約の部屋データ作成機能追加　by zy BEGIN
	public static List<Lead__c> queryLeadList(String leadId) {
		// 2017/09/11 印刷リスト機能　by　zy　BEGIN
		// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
		return [select id,Rroom__c,EntryTime__c,Departure__c,field3__c,field4__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,CreatedDate,Field354__c,Rroom__r.name,RelContact__r.name,Rroom__r.ShopInfoRef__r.Shopcode__c,Name,StayNightCal__c,No__c,ParentLeadId__c from Lead__c 
		// 2020/04/30 現状の仕様ですと部屋付けをしてもあくまで「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
		// 2017/09/11 印刷リスト機能　by　zy　END
										where id = :leadId 
										order by EntryTime__c ];
	}
	public static List<Lead__c> queryLeadList(Date beginDt,Date endDt,String spcd) {
	// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN	
		return queryLeadList(beginDt,endDt,spcd,null);
	}
	public static List<Lead__c> queryLeadList(Date beginDt,Date endDt,String spcd,List<String> sqlWhere) {
		Integer status = CommConst.LEAD_ST_CANCEL_FLG;
		String leadSQL = 'select id,Rroom__c,EntryTime__c,Departure__c,field3__c,field4__c,LeadIndexSubId__c,LeadIndexRef__c,RoomGroupNo__c,CreatedDate,Field354__c,Rroom__r.name,RelContact__r.name,Name,Field298__c,Rroom__r.ShopInfoRef__r.Shopcode__c,StayNightCal__c from Lead__c '
												+ ' where DAY_ONLY(convertTimezone(EntryTime__c)) <= :beginDt and DAY_ONLY(convertTimezone(Departure__c)) >= :endDt and CancelBool__c != :status  '
												+ ' and Rroom__r.ShopInfoRef__r.ShopCode__c =:spcd';
		if (sqlWhere != null && !sqlWhere.isEmpty()) {
			String whereSQL = '';
			if (sqlWhere.size() > 1) whereSQL = '(' + String.join(sqlWhere,' or ') + ')';
			else whereSQL = '(' + sqlWhere[0] + ')';
			leadSQL += ' and ' + whereSQL;
		}
		leadSQL +=	' order by EntryTime__c ';
	// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
												//2017/06/13 checin数据不显示问题对应，时钟显示的数据改为checkin的数据by zy BEGIN
												//2017/04/21 过滤不是checkin的数据 by zy BEGIN
												//and Field298__c  != null
												//2017/04/21 过滤不是checkin的数据 by zy END
												//2017/06/13 checin数据不显示问题对应，时钟显示的数据改为checkin的数据by zy END
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
		//										];
		return database.query(leadSQL);
		// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
	}
	
	public final static String ORDER_STATUS_ACCOUNT_ING = '会計中';
	public final static String ORDER_STATUS_ACCOUNT_END = '会計済み';
	/**
	* 获取order信息
	**/
	// 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy BEGIN
	public static List<OrderEntryInfo__c> queryOrderEntrys(List<List<Id>> roomIds,Date queryDate){
		//　部屋ID取得する
		Set<Id> roomSet =new Set<Id>();
		for (List<Id> roomIdLst : roomIds){
			for (Id roomId : roomIdLst) {
				roomSet.add(roomId);
			}
		}
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
		Set<String> orderStatus = new Set<String>{ORDER_STATUS_ACCOUNT_ING,ORDER_STATUS_ACCOUNT_END};
		return [select id,OrderStatus__c,RoomRef__c,AccountRef__c,SearchDate__c,OrderTime__c,LeadRef__c 
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
					, LeadRef__r.RelContact__r.name,LeadRef__r.name,LeadRef__r.LeadIndexRef__c,CookDoneFlg__c
					// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
						from OrderEntryInfo__c where SearchDate__c = :queryDate and RoomRef__c = :roomSet 
						and OrderStatus__c in :orderStatus order by LastModifiedDate];
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
	}
	// 2017/09/27 コレクションサイズ 最大サイズを超えエラー修正　by　zy END
	// 会計済み保存
	public static void endOrderInfo(List<String> orderIds){
		List<OrderEntryInfo__c> orderInfos = new List<OrderEntryInfo__c>();
		for (String orderId : orderIds ) {
			orderInfos.add(new OrderEntryInfo__c(id = orderId, OrderStatus__c = ORDER_STATUS_ACCOUNT_END));
		}
		// 2018/03/07 Security Check BEGIN
		if (CommSecurityUtils.isCanUpdateable(OrderEntryInfo__c.getSObjectType())) {
		// 2018/03/07 Security Check END
			update orderInfos;
		// 2018/03/07 Security Check BEGIN
		}
		// 2018/03/07 Security Check END
	}
	private static Integer ORDER_INFO_MAXLENGTH = 1500;
	public static void insertOrderInfo(String roomId,String accId,Datetime queryDate,String leadId,String spcd){
		Date curDate = queryDate.date();
		// 2018/03/07 Security Check BEGIN
		List<String> chkFieldsLst = new List<String>{'OrderStatus__c','RoomRef__c','AccountRef__c','SearchDate__c','LeadRef__c'};//'Id'
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.OrderEntryInfo__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpsertable(chkFieldsLst, mm)) {
			return ;
		}
		// 2018/03/07 Security Check END
		String timeStr = queryDate.format('HH:mm');
		List<OrderEntryInfo__c> orderInfos = [select id,OrderStatus__c,RoomRef__c,AccountRef__c,SearchDate__c ,LeadRef__c
												from OrderEntryInfo__c where  SearchDate__c = :curDate 
																	and RoomRef__c = :roomId 
																	and OrderStatus__c = :ORDER_STATUS_ACCOUNT_ING];
		if (orderInfos.isEmpty()) {
			OrderEntryInfo__c orderInfo = new OrderEntryInfo__c(OrderStatus__c = ORDER_STATUS_ACCOUNT_ING, SearchDate__c = curDate, RoomRef__c = roomId,AccountRef__c = accId,OrderTime__c = timeStr);
			List<OrderEntryInfo__c> orders = [select id from OrderEntryInfo__c where RoomRef__r.ShopInfoRef__r.ShopCode__c =:spcd  order by LastModifiedDate limit :ORDER_INFO_MAXLENGTH];
			if (orders.size() >= ORDER_INFO_MAXLENGTH) {
				orderInfo.id = orders[0].id;
				if (!CommUtils.isBlank(leadId)) orderInfo.LeadRef__c = leadId;
				update orderInfo;
			} else {
				if (!CommUtils.isBlank(leadId)) orderInfo.LeadRef__c = leadId;
				insert orderInfo;
			}
		// 2017/06/14 同一房间不同预约，会计数据、订单时间显示异常bug修理 by zy BEGIN
		} else {
			OrderEntryInfo__c orderInfo = new OrderEntryInfo__c(OrderStatus__c = ORDER_STATUS_ACCOUNT_ING, SearchDate__c = curDate, RoomRef__c = roomId,
					AccountRef__c = accId,
					OrderTime__c = timeStr);
			if (!CommUtils.isBlank(leadId)) orderInfo.LeadRef__c=leadId;
			// 2017/10/15 オーダー時刻の予約別の保存　by　zy BEGIN
			id orderId = null;
			// 予約ID是否存在オーダー信息
			for (OrderEntryInfo__c info : orderInfos) {
				if ( !CommUtils.isBlank(leadId) && info.LeadRef__c == leadId) {
					orderId = info.id;
					break;
				}
			}
			if ( orderId == null && orderInfos[0].LeadRef__c == null) {
				orderId = orderInfos[0].id;
			}
			orderInfo.id = orderId;
			// 2017/10/15 オーダー時刻の予約別の保存　by　zy END
			upsert orderInfo;
		}
		// 2017/06/14 同一房间不同预约，会计数据、订单时间显示异常bug修理 by zy END
	}	
//2017/05/26 無予約の部屋データ作成機能追加　by zy END
//2017/05/26 商品の多い印刷設備対応　by zy BEGIN
	public static PrintInfo getPrintByPosName(String name){
		PrintInfo pnt = getInstance().printConifgMap.get(name);
		if (pnt != null) pnt.par = getInstance().basePrintPara;
		return pnt;
	}
	private static PrintPara getBaseParaInfo(String shopCode) {
		//若不存在则进行数据初始化
		ShopInformation__c shop = null;
		try{
			List<ShopInformation__c> shops = [SELECT 
	                Id
	                , Name
	                , Phone__c
	                , Address__c
	                , ShopCode__c
	                , TierDefault__c
	                , PeopleDefault__c
	                , EnglishTaxLabel__c	// 内消費税英語表示文言
	            FROM
	                ShopInformation__c
	            where   ShopCode__c = :shopCode ];
	        if(!shops.isEmpty()) shop = shops[0];
        	else shop = defaultShopMessage();
	    	if (!CommUtils.isBlank(shopCode)) {
	    		shop = ShopInfoUtil.getShop(shopCode);
	    	} else {
	    		shop = defaultShopMessage();
	    	}
        } catch(Exception e) {
        	shop = defaultShopMessage();
        }
		PrintPara curPrintPara = new PrintPara();
		curPrintPara.telno = CommUtils.nullToBLank(shop.Phone__c);
		curPrintPara.address = CommUtils.nullToBLank(shop.Address__c);
		curPrintPara.company = CommUtils.nullToBLank(shop.Name);
		curPrintPara.empno = CommUtils.nullToBLank(UserUtil.CurrentUser.EmployeeCode__c);
		curPrintPara.postno = CommUtils.nullToBLank(shop.Post__c);
		return curPrintPara;
	}
	public static Map<String,AccountAcount__c> getAcounts(List<Id> accountIds){
		Map<String,AccountAcount__c> accMap = new Map<String,AccountAcount__c>();
		for(AccountAcount__c acc : [SELECT id,Relreserve__c FROM AccountAcount__c  Where Relreserve__c in :accountIds ]){
			accMap.put(acc.Relreserve__c,acc);
		}
		return accMap;
	}
//2017/05/26 商品の多い印刷設備対応　by zy END
//2017/06/15 機能改修　by　zy　BEGIN
	public static void insertOrderInfos(List<OrderEntryInfo__c> orderInfos,String spcd){
		// 2018/03/07 Security Check BEGIN
		if (!CommSecurityUtils.isCanUpdateable(OrderEntryInfo__c.getSObjectType())){
			return ;
		}
		// 2018/03/07 Security Check END
		List<OrderEntryInfo__c> orders = [select id from OrderEntryInfo__c where RoomRef__r.ShopInfoRef__r.ShopCode__c =:spcd  order by LastModifiedDate limit :ORDER_INFO_MAXLENGTH];
		if (orders.size() >= ORDER_INFO_MAXLENGTH) {
			for (integer i = 0 ; i < orderInfos.size();i++) {
				orderInfos[i].id = orders[i].id;
			}
			update orderInfos;
		} else {
			insert orderInfos;
		}
	}
//2017/06/15 機能改修　by　zy　END
//2017/06/19 POS選択リストの初期化　by　zy　BEGIN
	/*
	更换pos获取列表方式，这种是通过posno进行区分，要更换为ip-》设备对应的方式
	public static List<PrintInfo> getPrintInfos(Set<String> excludePosnoSet){
		List<PrintInfo> pints = getInstance().printConifgMap.values();
		List<PrintInfo> printLst = new List<PrintInfo>();
		for (PrintInfo info : pints) {
			if (excludePosnoSet != null && excludePosnoSet.contains(info.printNo)) {
				continue;
			}
			printLst.add(info);
		}
		return printLst;
	}*/
	//2017/06/19 POS選択リストの初期化　by　zy　END
	//2017/07/03 レビュー更新する　by　zy　BEGIN
	// 2017/07/03 POS区分印刷設備
	public static PrintInfo getPrintInfoByPrintNo(String printNo) {
		return getInstance().printNoMap.get(printNo);
	}
	public static PrintInfo getPrintInfoByDeviceIp(String localIp){
		Map<String,PrintInfo> posMap = getInstance().printNoMap;
		PrintInfo curPnt = null;
		for (String posNo : posMap.keySet()) {
			PrintInfo p = posMap.get(posNo);
			if (p.deviceUrl == localIp) {
				curPnt = p;
				break;
			}
		}
		return curPnt;
	} 
	//2017/07/03 レビュー更新する　by　zy　END
	// 2017/07/10 192.168.10.XXX,192.168.10.YYY 除此两个ip以外没有其他配置则不打开pos功能 by zy BEGIN
	// 印刷の設備のリスト取得する
	// IP「192.168.10.XXX」、「192.168.10.YYY」以外の設備作成する
	// 印刷設備に「PRINTNO」必要
	public  static List<PrintInfo> getPrintInfoByIp(Set<String> excludePosnoSet){
		// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
		//获取对应map
		//Map<String,PrintInfo> pntMap = new Map<String,PrintInfo>();
		List<PrintInfo> pntLst = new List<PrintInfo>();
		// 2017/07/12 印刷リスト序列化改修 by zy END
		//初始化map
		//获取ip，device对应关系找出印刷設備
		Map<String,String> roomPntMap = getInstance().roomToPrintMap;
		Map<String,PrintInfo> printMap = getInstance().printConifgMap;
		// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
		Set<String> printNoSet = new Set<String>();
		// 2017/07/12 印刷リスト序列化改修 by zy END
		// 作成ip、印刷設備的对应关系
		for ( String curIp : roomPntMap.keySet()) {
			// 除外集合中含有当前ip，不进行处理
			if (excludePosnoSet != null && excludePosnoSet.contains(curIp)) continue;
			String deviceName = roomPntMap.get(curIp);
			//通过devicename找到印刷設備
			if (printMap.containsKey(deviceName)) {
				// 根据printname找到印刷設備
				PrintInfo p = printMap.get(deviceName);
				if (p != null && !CommUtils.isBlank(p.printNo)) {
					// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
					//pntMap.put(p.printNo,p);
					printNoSet.add(p.printNo);
					// 2017/07/12 印刷リスト序列化改修 by zy END
				}
			}
		}
		// 2017/07/12 印刷リスト序列化改修 by zy BEGIN
		// 根据顺序，筛选pos列表
		for (PrintInfo p : getInstance().printLst) {
			if (printNoSet.contains(p.printNo)) {
				pntLst.add(p);
			}
		}
		//return pntMap.values();
		return pntLst;
		// 2017/07/12 印刷リスト序列化改修 by zy END
	}
	// 2017/07/10 192.168.10.XXX,192.168.10.YYY 除此两个ip以外没有其他配置则不打开pos功能 by zy END
	// 2017/09/11 印刷リスト機能　by　zy　BEGIN
	// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy BEGIN
	//会席明細取得
	public static Map<Id,List<FoodDetail__c>> getKaisakiDetailMap(Set<Id> prodIds){
		return getKaisakiDetailMap(prodIds,new Set<Id>());
	}
	public static Map<Id,List<FoodDetail__c>> getKaisakiDetailMap(Set<Id> prodIds,Set<Id> ops){
		Map<Id,List<FoodDetail__c>> planDetailMap = new Map<Id,List<FoodDetail__c>> ();
		//2017/02/13 new layout by zy BEGIN
		// 2018/08/31 料理進捗機能追加 by zy BEGIN
		String accountQuery = 'select id , Name,Field5__c , TaxRateCal__c , ServiceRate__c , PaymentType__c , jmstRef__c, Field3__c, SpecialTax__c,ActionType__c, _foodQuery_ from AccountMaster__c where id =:prodIds';
		String foodQuery = '(Select BreakName__c, AccountMasterRef__c,AccountMasterSubRef__r.name,AccountMasterSubRef__c,AccountMasterSubRef__r.CookTime__c,DetailType__c  From ProdFoodDetailRef__r';
		if (ops != null && !ops.isEmpty()) foodQuery += ' where AccountMasterSubRef__r.Op__c in :ops ';
		foodQuery += ' order by OrderNo__c)';
		accountQuery = accountQuery.replace('_foodQuery_',foodQuery);
		// for ( AccountMaster__c acc : [select id , Name,Field5__c , TaxRateCal__c , ServiceRate__c , PaymentType__c , jmstRef__c, Field3__c, SpecialTax__c,ActionType__c, (Select BreakName__c, AccountMasterRef__c,AccountMasterSubRef__r.name,AccountMasterSubRef__c,AccountMasterSubRef__r.CookTime__c,DetailType__c From ProdFoodDetailRef__r order by OrderNo__c) from AccountMaster__c where id =:prodIds]){
		LIst<AccountMaster__c> accs = Database.query(accountQuery);
		for ( AccountMaster__c acc : accs){
		// 2020/02/28 同じ「料理リスト」タブ内で「テーブル」と「厨房」の切り替えを可能にする by zy END
		// 2018/08/31 料理進捗機能追加 by zy END
		//2017/02/13 new layout by zy END	
			//2017/02/13 new layout by zy BEGIN
			for (FoodDetail__c pd : acc.ProdFoodDetailRef__r){
				if (!planDetailMap.containsKey(pd.AccountMasterRef__c))  planDetailMap.put(pd.AccountMasterRef__c,new List<FoodDetail__c>());
				planDetailMap.get(pd.AccountMasterRef__c).add(pd);
			}
		}
		return planDetailMap;
	}
	// 一括印刷の場合、引き渡す必要情報
	public Class BulkPrintUIInfo {
	    public String leadid{get;set;}
	    public String accid{get;set;}
	    public String leadname{get;set;}
	    public String contactname{get;set;}
	    public String roomname{get;set;}
	    // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
	    //public Object printInfo{get; set;}
	    public Map<String,Object> printInfos{get; set;}
	    public Map<String,Object> posPrintInfo{get;set;}
	    // 2017/10/24 多印刷メッセージ放出機能追加 by zy END
	    public String leadstatus{get;set;}
	    public String leadstatuslabel{get;set;}
	}
	// 2017/09/11 印刷リスト機能　by　zy　END
	// 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy BEGIN
	public static Map<Id,Map<String,Object>> getAllCustomMap(List<Id> objectIds,String otherFields,boolean headStanFlag){
		if (objectIds == null || objectIds.isEmpty()) return null;
		List<String> otherFieldLst = new List<String>();
		List<String> defaultFieldLst = new List<String>();
		List<CustomInfo> infoLst = getCustomInfoLst();
		// ディフェンダー設定
		if (!CommUtils.isBlank(otherFields)) {
			for (String fieldStr : otherFields.toLowerCase().deleteWhitespace().split(',')) {
				String[] fieldValues = fieldStr.split(':');
				CustomInfo info = new CustomInfo();
				info.label = fieldValues[0];
				info.cusFields.add(fieldValues[1]);
				infoLst.add(info);
			}
		}
		// オブジェクト取得
		Schema.SObjectType sobjectType = objectIds[0].getSObjectType();
		Schema.DescribeSObjectResult dr = sobjectType.getDescribe();
		// カスタムラベルー設定
		List<CustomInfo> customLst = getCustomInfoLst(infoLst,sobjectType);
		// SQL文取得
		String querySql = getQuerySQL(customLst,dr.getName());
//system.debug(logginglevel.info,'querySQL:::' + querySQL);
		List<Sobject> sobjectLst = Database.query(querySQL);
//system.debug(logginglevel.info,'objectIds:::' + objectIds);
		return redirectSettingValue(sobjectLst,infoLst,headStanFlag);
	}
	// カスタム設定フィールド作成する
	private static List<CustomInfo> getCustomInfoLst(List<CustomInfo> customLst,Schema.SObjectType sobjectType){
		String refPrix = '__r.';
		String refNamePrix = '__r';
		String commPrix = '__c';
		Map<String, Schema.DescribeFieldResult> valuesMap = CommSqlUtils.getAllFieldLst(sobjectType,false,true);
		Sobject curSobj = sobjectType.newSObject();
		Map<String,Map<String, Schema.DescribeFieldResult>> sobjectMap = new Map<String,Map<String, Schema.DescribeFieldResult>>();
		for (CustomInfo info : customLst) {
			for (String customField : info.cusFields ) {
				customField = customField.toLowerCase();
				if (valuesMap.containsKey(customField)) {
					Schema.DescribeFieldResult dr = valuesMap.get(customField);
					info.addField(dr,customField);
				} else if (customField.contains(refPrix)) {
					String refName = customField.substringBefore('.');
					String curFieldName = refName.replace(refNamePrix,commPrix);
					String fieldName = customField.substringAfter(refPrix);
					if (valuesMap.containsKey(curFieldName)) {
						Schema.DescribeFieldResult dr = valuesMap.get(curFieldName);
						Schema.sObjectType refType = dr.getReferenceTo()[0];
						String typeName = refType.getDescribe().getLabel();
						if (!sobjectMap.containsKey(typeName)) sobjectMap.put(typeName,CommSqlUtils.getAllFieldLst(refType,false,true));
						Map<String, Schema.DescribeFieldResult> curValuesMap = sobjectMap.get(typeName);
						if (curValuesMap.containsKey(fieldName)) {
							Schema.DescribeFieldResult refDr = curValuesMap.get(fieldName);
							// ２０１７/10/12 アレルギー更新 by zy BEGIN
							info.addRefField(dr,refDr,customField);
							//String orgField = dr.getRelationshipName() + '.' + refDr.getName();
							//info.addRefField(dr,refName,orgField,refDr.getLocalName(),customField);
							// ２０１７/10/12 アレルギー更新 by zy END
						}
					}
				}
			}
		}
		return customLst;
	}
	// SQL文取得する
	private static String getQuerySQL(List<CustomInfo> customLst,String objName){
		// 初期化
		String querySQL = 'select id,';
		Set<String> fieldNameSet =new Set<String>();
		for (CustomInfo custom : customLst) {
			for ( PageCustomeFieldHelper.CusField cusfield : custom.cusLst) {
				if (cusfield.fieldName == 'id') continue;
				if (fieldNameSet.contains(cusfield.name)) continue;
				querySQL += cusfield.name + ',';
				fieldNameSet.add(cusfield.name);
			}
		}
		querySQL = querySQL.removeEnd(',');
		querySQL += ' from ' + objName + ' where id =:objectIds';
		return querySQL;
	}
	private static Map<Id,Map<String,Object>> redirectSettingValue(List<Sobject> sobjectLst,List<CustomInfo> customLst,boolean headStanFlag){
		Map<Id,Map<String,Object>> objectMapById = new Map<Id,Map<String,Object>>();
		for (sObject sobj : sobjectLst) {
			// 201７/10/12 アレルギー更新 by zy BEGIN
			Set<String> exitValueSet = new Set<String>();
			// 201７/10/12 アレルギー更新 by zy END
			Map<String,Object> objectMap = new Map<String,Object>();
			for (CustomInfo info : customLst) {
				List<String> allContents = new List<String>();
				for ( PageCustomeFieldHelper.CusField cus : info.cusLst) {
					List<String> filterValue = new List<String>();
					// 参照フィールド
					if (cus.isRefFlag) {
						Sobject refSobj = sobj.getSobject(cus.refName);
						if (refSobj != null) {
							String typeName = refSobj.getSObjectType().getDescribe().getLabel();
							Schema.DescribeFieldResult dr = cus.refDr;
							if ( dr != null ) {
								if (refSobj != null) filterValue = info.filter(cus,safeValue(refSobj.get(dr.getName()),dr.isHtmlFormatted()));
							}
						}
					} else filterValue = info.filter(cus,safeValue(sobj.get(cus.fieldName),cus.cusDr.isHtmlFormatted()));			
					// 不为空加个空格 并且不存在重复语句
					// 2017/10/12 アレルギー更新 by zy BEGIN
					allContents.addAll(filterValue);
				}
				String value = '';
				// 不为空加个空格 并且不存在重复语句
				if (!allContents.isEmpty()) {
					for (String filterValue : allContents) {
						if (!CommUtils.isBlank(filterValue)) {
							// 重复过滤
							if (!exitValueSet.contains(filterValue.trim())) exitValueSet.add(filterValue.trim());
							else continue;
							if (!CommUtils.isBlank(value)) value += ' ';
							value += filterValue;
						}
					}
				}
				objectMap.put(info.label,getNewMessage(value,headStanFlag,info.firstRowLen,info.otherRowLen));
			}
			objectMapById.put(sobj.id,objectMap);
			// 2017/10/12 アレルギー更新 by zy END
		}
		return objectMapById;
	}
	private static String safeValue(Object value,boolean isHtml){
		String result = CommUtils.nullToBlank(value);
		if (isHtml) {
//			result = result.unescapeHtml4().replaceAll('<br>','\n');
//			result = result.replaceAll('\\<.[^<>]*\\>','').trim();
            result = result.stripHtmlTags();
		}
    	return result;
    }
    // 2017/10/12 アレルギー更新 by zy BEGIN
    private static String getNewMessage(String message , boolean headFlag,Integer firstLen,Integer otherRowLen){
    	String result = message;
    	//如果是倒影处理且换行数大于0
		if ( firstLen > 0 && headFlag) {
			result = '';
			String firstContent = CommRepUtils.getPdfMaxShowStringNew(message,1,firstLen,'','',false);
			//List<String> firstLst = firstContent.split('_\\$_');
			//if (!firstLst.isEmpty()) firstContent = firstLst[0];
			String lastContent = message.subStringAfter(firstContent.trim());
			String name = CommRepUtils.getPdfMaxShowStringNew(lastContent,999,otherRowLen,'_$_','\n',false);
			//List<String> contentLst = new List<String>();
			List<String> splitLst = new List<String>();
			for (String mes : name.split('_\\$_')) {
				if(!CommUtils.isBlank(mes)) splitLst.add(mes);
			}
			for (Integer i = splitLst.size() ; i > 0 ; i--){
				String row = splitLst[i-1];
				if (!row.contains('\n')) row += '\n';
				result += row ;
			}
			result += firstContent;
		}
    	return result;
    }
    // 2017/10/12 アレルギー更新 by zy END
    public class CustomInfo{
    	String label;
    	// 2017/10/12 アレルギー更新 by zy BEGIN
    	// 截取长度
    	Integer firstRowLen;
    	integer otherRowLen;
    	// 2017/10/12 アレルギー更新 by zy END
    	List<String> cusFields;
    	Map<String,PageCustomeFieldHelper.NodeItem> cusFilterFields;
    	List<PageCustomeFieldHelper.CusField> cusLst;
    	public CustomInfo(){
    		label = '';
    		// 2017/10/12 アレルギー更新 by zy BEGIN
    		firstRowLen = 8;
    		otherRowLen = 13;
    		// 2017/10/12 アレルギー更新 by zy END
    		cusFields = new List<String>();
    		cusLst = new List<PageCustomeFieldHelper.CusField>();
    		cusFilterFields = new Map<String,PageCustomeFieldHelper.NodeItem>();
    	}
    	public CustomInfo(Dom.XmlNode customNode){
    		cusLst = new List<PageCustomeFieldHelper.CusField>();
    		label = CommUtils.nullToBlank(customNode.getName().toLowerCase());
    		// 2017/10/12 アレルギー更新 by zy BEGIN
    		firstRowLen = 8;
    		otherRowLen = 13;
    		// 2017/10/12 アレルギー更新 by zy END
    		String customContent = customNode.getText();
    		cusFields = new List<String>();
    		cusFilterFields = new Map<String,PageCustomeFieldHelper.NodeItem>();
 			cusFields = CommUtils.nullToBlank(customContent).toLowerCase().deleteWhitespace().split(',');
    		for (Dom.XmlNode filterNode : customNode.getChildElements()) {
    			String nodeName = filterNode.getName();
				if ('FILTER' == nodeName) {
					PageCustomeFieldHelper.NodeItem cus = new PageCustomeFieldHelper.NodeItem(filterNode);
					String[] setFields = cus.leadXmlTag.split(',');
					for (String curField : setFields) {
						curField = curField.toLowerCase().deleteWhitespace();
						cusFields.add(curField);
						cusFilterFields.put(label + '_' + curField,cus);
					}
				// 2017/10/12 アレルギー更新 by zy BEGIN
				} else if ('LINEMAXSIZE' == nodeName) {
					String messLineStr = filterNode.getText();
					if ( !CommUtils.isBlank(messLineStr)) {
						List<String> cutLine = messLineStr.split(',');
						if (!CommUtils.isBlank(cutLine[0])) firstRowLen = CommUtils.nullToIntZero(cutLine[0]);
						if (cutLine.size() >= 2 && !CommUtils.isBlank(cutLine[1])) otherRowLen = CommUtils.nullToIntZero(cutLine[1]);
					}
				}
				// 2017/10/12 アレルギー更新 by zy END
    		}
    	}
    	public void addField(Schema.DescribeFieldResult dr,String searchKey){
    		PageCustomeFieldHelper.CusField cus = new PageCustomeFieldHelper.CusField(dr);
    		cus.searchKey = searchKey;
    		cusLst.add(cus);
    	}
    	// ２０１７/10/12 アレルギー更新 by zy BEGIN
    	// 添加
    	public void addRefField(Schema.DescribeFieldResult dr,Schema.DescribeFieldResult refDr,String searchKey){
    		PageCustomeFieldHelper.CusField cus = new PageCustomeFieldHelper.CusField(dr);
			cus.isRefFlag = true;
			cus.refDr = refDr;
			cus.name = dr.getRelationshipName() + '.' + refDr.getName();
			cus.refName = dr.getRelationshipName();
			cus.searchKey = searchKey;
			cusLst.add(cus);
    	}
    	// ２０１７/10/12 アレルギー更新 by zy END
    	// 过滤
    	public List<String> filter(PageCustomeFieldHelper.CusField cus , String value){
    		String filterValue = value;
    		List<String> filterLst = new List<String>();
    		if (cusFilterFields != null && !cusFilterFields.isEmpty()) {
    			String searchKey = label + '_' + cus.searchKey;
    			PageCustomeFieldHelper.NodeItem item = cusFilterFields.get(searchKey);
    			if (item == null ) {
    				searchKey = label + '_' + cus.localName.toLowerCase();
    				item = cusFilterFields.get(searchKey);
    			}
    			if (item != null) filterLst = item.getFilterValue(value);
    		}
	    	return filterLst;
	    }
    }
    // 2017/09/18 印刷フィルター「アレルギー」カスタム設定機能by zy END
    // 2017/09/25　会計済みの項目　by zy BEGIN
    public static void updateAccountOver(String accId){
    	// 2018/03/07 Security Check BEGIN
    	List<String> chkFieldsLst = new List<String>{'Field53__c'};//'Id'
    	Map<String,Schema.SObjectField> mm = Schema.SObjectType.AccountAcount__c.fields.getMap();
    	if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
    	}
    	// 2018/03/07 Security Check END
    	if (!CommUtils.isBlank(accId)) {
	    	AccountAcount__c curAccount = new AccountAcount__c(id = accId);
			// 会計日時: TODO->原システム確認要
			curAccount.Field53__c = DateTime.valueOf(String.valueOf(System.now())).format('yyyyMMddHHmmss');
			update curAccount;
    	}
    }
    // 2017/09/25　会計済みの項目　by zy END
    // 2017/10/24 多印刷メッセージ放出機能追加 by zy BEGIN
    public class DeviceFilter{
		List<Filter> filterGP;
		List<Filter> filterOP;
		List<Filter> filterDP;
		List<Filter> filterLinkDP;
		List<String> sortLst;
		public DeviceFilter(){
			sortLst = new List<String>();
			filterGP = new List<Filter>();
			filterOP = new List<Filter>();
			filterDP = new List<Filter>();
			filterLinkDP = new List<Filter>();
		}
		public DeviceFilter(Dom.XmlNode xmlNode){
			filterGP = new List<Filter>();
			filterOP = new List<Filter>();
			filterDP = new List<Filter>();
			filterLinkDP = new List<Filter>();
			sortLst = new List<String>();
			for (Dom.XmlNode childNode : xmlNode.getChildElements()) {
				if (childNode == null) continue;
				String nodeName = childNode.getName();
				sortLst.add(nodeName);
				if ( nodeName == 'GP') {
					for ( Dom.XmlNode eachNode : childNode.getChildElements()){
						Filter f = new Filter(eachNode);
						filterGP.add(f);
					}
				} else if ( nodeName == 'OP' ) {
					for ( Dom.XmlNode eachNode : childNode.getChildElements()){
						Filter f = new Filter(eachNode);
						filterOP.add(f);
					}
				} else if ( nodeName == 'DP' ) {
					for ( Dom.XmlNode eachNode : childNode.getChildElements()){
						Filter f = new Filter(eachNode);
						filterDP.add(f);
					}
				} else if ( nodeName == 'LINKDP' ) {
					for ( Dom.XmlNode eachNode : childNode.getChildElements()){
						Filter f = new Filter(eachNode);
						filterLinkDP.add(f);
					}
				}
			}
		}
		public String filter(AccountMaster__c acc){
			for (String name : sortLst) {
				if ( name == 'OP') {
					for ( Filter f : filterOP) {
						if ( f.codes.contains(CommUtils.nullToBlank(acc.OP__r.OPcode1__c)) ) return f.posNo;
					}
				} else if ( name == 'GP') {
					for ( Filter f : filterGP) {
						if ( f.codes.contains(acc.GPChange__r.Field1__c) ) return f.posNo;
					}
				} else if  (  name == 'DP') {
					for ( Filter f : filterDP) {
						if ( f.codes.contains(acc.DPChange__r.Field1__c) ) return f.posNo;
					}
				} else if  (  name == 'LINKDP') {
					for ( Filter f : filterLinkDP) {
						if ( f.codes.contains(acc.Field4__r.Field1__c) ) return f.posNo;
					}
				}
			}
			return '' ;
		}
	}
	class Filter{
		String posNo;
		Set<String> codes;
		public Filter(Dom.XmlNode eachNode){
			codes = new Set<String> ();
			posNo = '';
			String nodeName = eachNode.getName();
			String eachText = eachNode.getText().trim();
//system.debug(logginglevel.info,'eachText:::' + eachText);
			codes = new Set<String> (CommUtils.nullToBlank(eachText).split(','));
//system.debug(logginglevel.info,'codes:::' + codes);
			String posNoStr = eachNode.getAttribute('POSNO', null);
			if (!CommUtils.isBlank(posNoStr)) posNo = posNoStr;
		}
	}
	public static DeviceFilter getDeviceFilter(){
		return getInstance().deviceFilter;
	}
	private DeviceFilter deviceFilter;
	// 2017/09/11 印刷リスト機能　by　zy　BEGIN
	public static void makePrintInfos(BulkPrintUIInfo uiInfo , OrderServiceHelp.PrintInfo printInfo , List<Tran1__c> tran1Lst,Map<String,String> prodPosMap,
									AccountAcount__c curAcc,Map<String,Object> resultMap,Map<Id,List<FoodDetail__c>> planDetailMap,
										OrderServiceHelp.LayoutType layType){
		uiInfo.printInfos = new Map<String,Object>();
		Map<String,List<Tran1__c>> posInfoMap = new Map<String,List<Tran1__c>>();
		for ( Tran1__c tran : tran1Lst) {
			if(prodPosMap.containsKey(tran.Field7__c)){
				String posName = prodPosMap.get(tran.Field7__c);
				if (CommUtils.isBlank(posName)) posName = printInfo.printName;
				if (!posInfoMap.containsKey(posName)) posInfoMap.put(posName,new List<Tran1__c>());
				posInfoMap.get(posName).add(tran);
			}
		}
		if (!posInfoMap.isEmpty()){
			for (String posName :posInfoMap.keySet()) {
				Object printMessage = OrderServiceHelp.getPrintObj(printInfo,posInfoMap.get(posName),layType, planDetailMap,curAcc,resultMap);
				//uiInfo.posPrintInfo.put(posName,printMessage);
				uiInfo.printInfos.put(posName,printMessage);
			}
		} else {
			Object printMessage = OrderServiceHelp.getPrintObj(printInfo,tran1Lst,layType, planDetailMap,curAcc,resultMap);
			uiInfo.printInfos.put('',printMessage);
		}
	}
	public static Map<String,PrintInfo> getPrintMap() {
		return getInstance().printConifgMap;
	}
	public static Map<String,Device> getDeviceMap(){
		return getInstance().ipToDeviceMap;
	}
	private PrintPara basePrintPara;
	// 2017/10/24 多印刷メッセージ放出機能追加 by zy END
	// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
	// 2018/07/26 QRコード印刷対応 by zy BEGIN
	public static String getPrintInfoByProdId(String prodId,String localIp,String printType) {
	//public static String getPrintInfoByProdId(String prodId,String localIp) {
	// 2018/07/26 QRコード印刷対応 by zy END	
		PrintInfo info = getPrintByIp(localIp);
		if (info == null) return null;
		PrintPara para = info.par;
		// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
		PrintOtInfo printOther = getOtherInfo();
		Map<String, Schema.DescribeFieldResult> accountMasterValuesMaps = CommSqlUtils.getAllFieldLst(AccountMaster__c.sObjectType,false,true);
		// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
		Map<String,Object> m = new Map<String,Object>();
		Map<String,Object> p = new Map<String,Object>();
		if (info != null) {
			// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
			List<String> refQuery = null;
			if (printOther != null)  {
				refQuery = printOther.refrenceFields;
			}
			String queryHd = CommSqlUtils.generateQueryString('AccountMaster__c',refQuery);
			queryHd += ' where id = :prodId';
			
			List<AccountMaster__c> masterLst = database.query(queryHd);
			//List<AccountMaster__c> masterLst = [select id,name,Field3__c,TaxRateCal__c,Field5__c,ServiceRate__c from AccountMaster__c where id = :prodId];
			// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
			if (!masterLst.isEmpty()) {
				AccountMaster__c acc = masterLst[0];
				CommUtils.ProductInfo prodInfo = new CommUtils.ProductInfo();
				decimal unitPrice = CommUtils.nullToZero(acc.Field5__c);
				priceInfo.process(unitPrice, 1 , acc.TaxRateCal__c, acc.ServiceRate__c);
				Datetime dt = system.now();
				String dtFormatStr = dt.format('yyyy年MM月dd日$$(%%)$$HH:mm').replace('%%',CommUtils.getYobi(dt.date()));
				// 商品コード
				p.put('barcode',CommUtils.nullToBlank(acc.get(info.barCodeField)));
				// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy BEGIN
				if (printType == 'qrcodeprint') {
					if (printOther != null) {
						String printInfo = getQRPrintInfo(printOther,acc,accountMasterValuesMaps);
						if (!CommUtils.isBlank(printInfo)) p.put('barcode',printInfo);
					}
				}
				// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
				// 13位长度超过13位补齐0
				p.put('fullcode',CommUtils.paddingLeftZero(CommUtils.nullToBlank(acc.Field3__c),13));
				p.put('datetime',encode(dtFormatStr).replace('%24%24','%20'));
				p.put('printno'  , encode(info.printNo));
				p.put('company' , encode(para.company));
		        p.put('address' , encode(para.address));
		        p.put('postno'	, encode(info.printName));// 郵便番号
		        p.put('telno'	, encode(para.telno) );
		        p.put('empno'   , encode(para.empno));
				//税抜き	        
		        p.put('price'   , currency(priceInfo.priceExcTax));
		        //税込
		        p.put('priceInc'   , currency(priceInfo.priceIncTax));
		        //商品名	
		        p.put('item'   , encode(CommLogUtils.removeOverLogString(acc.name,40,true)));
			}
			m.put('parameter',p);
			m.put('sequence', info.barCodeLayout);
		}
		return JSON.serialize(m);
	}
	// 2018/03/30 会計商品の印刷QRコードレイアウト対応 by zy END
// 2018/07/26 QRコード印刷対応 by zy BEGIN
private PrintOtInfo printOther;
public static PrintOtInfo getOtherInfo(){
	return getInstance().printOther;
}
public static String getQRPrintInfo(PrintOtInfo info,AccountMaster__c acc, Map<String, Schema.DescribeFieldResult> valuesMap){
	String result = '';
	if (acc != null) {
		Map<String,Object> objMap = parseQRCodeInfo(info.fieldLst,acc,valuesMap);
		if (!objMap.isEmpty()) {
			for (String fieldName : info.fieldLst) {
				String key = fieldName.toLowerCase();
				if (objMap.containsKey(key)) {
					result += key + '=' + CommUtils.nullToBlank(objMap.get(key)) + info.symbol;
				}
			}
		}
		result = result.removeEnd(info.symbol);
	}
	return result;
}
public static Map<String,Object> parseQRCodeInfo(List<String> fieldLst,AccountMaster__c acc,Map<String, Schema.DescribeFieldResult> valuesMap){
	Map<String,object> objMap = new Map<String,object>();
	for (String fieldName : fieldLst) {
		if (CommUtils.isBlank(fieldName)) continue;
		if (fieldName.contains('__r')) {
			Object value;
			List<String> fieldNames = fieldName.split('__r.');
			if (fieldNames.size() > 1) {
				String refFieldName = fieldNames[0] + '__c';
				String refName = fieldNames[1];
				Schema.DescribeFieldResult dr = valuesMap.get(refFieldName);
				if (dr.getType() == DisplayType.Reference) {
					Sobject refSobj = acc.getSobject(dr.getRelationshipName());
					if (refSobj != null)
						value = refSobj.get(refName);
				}
			}
			objMap.put(fieldName.toLowerCase(),value);
		} else objMap.put(fieldName.toLowerCase(),acc.get(fieldName));
	}
	return objMap;
}
public static String QR_PRINT_SYMBOL = '$$_$$';
// その他印刷メッセージ
class PrintOtInfo{
	public List<String> fieldLst;
	// 連接符
	public String symbol;
	public List<String> refrenceFields;
	public PrintOtInfo(Dom.xmlnode node){
		fieldLst = new List<String>();
		Dom.xmlnode fieldNode = node.getChildElement('FIELDS',null);
		if (fieldNode != null) {
			fieldLst = CommUtils.nullToBlank(fieldNode.getText()).deleteWhitespace().trim().toLowerCase().split(',');
			for (String fieldNm : fieldLst) {
				if (fieldNm.contains('__r')) {
					if (refrenceFields == null) refrenceFields = new List<String>();
					refrenceFields.add(fieldNm);
				}
			}
		}
		symbol = QR_PRINT_SYMBOL;
		Dom.xmlnode symbolNode = node.getChildElement('SYMBOL',null);
		if (symbolNode != null) {
			symbol = CommUtils.nullToBlank(symbolNode.getText());
		}
	}
}
// 2018/07/26 QRコード印刷対応 by zy END
private set<String> cookProds;
public static Set<String> getCookProds(){
	return getInstance().cookProds;
}
// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw BEGIN
private String menuZoomFlag;
// 2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw BEGIN
private Map<string, string> roomZoomFlag;
public static Map<string, string> getRoomZoomFlag(){
	return getInstance().roomZoomFlag;
}
// 2019/02/15 オーダーエントリー改善（文字サイズをカスタマイズとレイアウト自由カスタマイズ機能） by cxw END
public static String getMenuZoomFlag(){
	return getInstance().menuZoomFlag;
}
private Boolean onlyMobileFlag;
public static boolean getMobileFlag(){
	return getInstance().onlyMobileFlag;
}
// 2019/01/15 オーダーエントリー改善（メニューサイズ自動調整）by cxw END
	// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy BEGIN
	public final static String ORDER_STATUS_PRINT_INFO = '印刷情報';	
	// 新規印刷情報
	public static void insertPrintOrderinfo(List<OrderEntryInfo__c> infos){
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'trans__c','searchdate__c','roomref__c','printinfo__c','ordertime__c','ordertimestmp__c','orderstatus__c','accountref__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.OrderEntryInfo__c.fields.getMap();
		if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		insert infos;
	}
	// 指定注文取得
	public static List<OrderEntryInfo__c> queryEntrysByIds(Set<String> orderIds){
		// SQL文
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		String orderQery = 'select id,PrintInfo__c,Trans__c,RoomRef__r.name,accountRef__r.relreserve__r.relcontact__r.name,OrderTimeStmp__c from OrderEntryInfo__c where id = :orderIds';
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
		return database.query(orderQery);
	}
	// 印刷情報取得	
	public static List<OrderEntryInfo__c> queryPrintOrderinfo(String userId,Date queryDt,String orderType,String sortType,boolean isAcc){
		// SQL文
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
		String orderQery = 'select id,PrintInfo__c,Trans__c,RoomRef__r.name,accountRef__r.relreserve__r.relcontact__r.name,OrderTime__c,OrderTimeStmp__c from OrderEntryInfo__c where OrderStatus__c =:ORDER_STATUS_PRINT_INFO and OwnerId = :userId and SearchDate__c = :queryDt';
		// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
		String orderSort = ' order by CreatedDate';
		// 注文順
		if (orderType == '1') {
			orderSort = ' order by CreatedDate _sort_ ';
		// お客様順
		} else if (orderType == '2') {
			orderSort = ' order by accountRef__r.relreserve__r.relcontact__r.name _sort_,CreatedDate _sort_ ,RoomRef__r.name  nulls last';
		// 部屋順
		} else if (orderType == '3') {
			orderSort = ' order by RoomRef__r.name _sort_,CreatedDate,accountRef__r.relreserve__r.relcontact__r.name nulls last';
		}
		// 降順と昇順変更
		String acc = '';
		// NULL対応
		if (sortType == 'desc') sortType += ' nulls last ';
		if (isAcc) acc = 'AccountRef__c ' + sortType + ', ';
		orderSort = orderSort.replaceAll('_sort_',sortType)
							.replaceAll('_account_',acc);
		List<OrderEntryInfo__c> infos = database.query(orderQery + orderSort);
		return infos;
	}
// 2019/03/28 オーダーエントリー改善レシート再出力機能 by zy END
	// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy BEGIN
	// 2019/10/02 エラー修正 by zy BEGIN
	public static void updateReciptNo(AccountAcount__c curAcc){
		updateReciptNo(curAcc,0);
	}
	// 2019/10/02 エラー修正 by zy END
	// 印刷レーシト番号更新
	public static void updateReciptNo(AccountAcount__c curAcc,Integer errorInt){
		// レーシト番号存在
		if (CommUtils.isBlank(curAcc.id)) return;
		// 2019/09/15 Security Check BY zyz BEGIN
		List<String> chkFieldsLst = new List<String>{'reciptno__c'};
		Map<String,Schema.SObjectField> mm = Schema.SObjectType.AccountAcount__c.fields.getMap();
		if (!CommSecurityUtils.isCanUpdateable(chkFieldsLst, mm)) {
			return ;
		}
		// 2019/09/15 Security Check BY zyz END
		// 指定会計取得
		List<AccountAcount__c> exitAccs = [select id ,ReciptNo__c,ShopCode__c,SalesDate__c from AccountAcount__c where id = :curAcc.id];
		if (exitAccs.isEmpty()) return;
		AccountAcount__c acc = exitAccs[0];
		if (!CommUtils.isBlank(acc.ReciptNo__c)){
			curAcc.ReciptNo__c = acc.ReciptNo__c;
			return;
		}
		// 開始計数値
		Decimal lastNum = 0;
		// 2019/10/02 エラー修正 by zy BEGIN
		String dateHead = Datetime.newInstance(acc.SalesDate__c.year(),acc.SalesDate__c.month(),acc.SalesDate__c.day()).format('yyyyMMdd%');
		// 該当日、該当店舗下最大レーシト番号取得
		// List<AccountAcount__c> accs = [select id,ReciptNo__c from AccountAcount__c where ShopCode__c = :acc.ShopCode__c and SalesDate__c = :acc.SalesDate__c and ReciptNo__c != null and ReciptNo__c like :dateHead order by ReciptNo__c desc limit 1];
		// 不进行salesdate判断，既存数据中存在日期与reciptno不相符的数据，后续在trigger中进行解锁
		List<AccountAcount__c> accs = [select id,ReciptNo__c from AccountAcount__c where ShopCode__c = :acc.ShopCode__c  and ReciptNo__c != null and ReciptNo__c like :dateHead order by ReciptNo__c desc limit 1];
		// 2019/10/02 エラー修正 by zy END
		// 会計あり
		if (!accs.isEmpty()) {
			// 2019/10/02 エラー修正 by zy BEGIN
			List<AccountAcount__c> accLst = [select id,ReciptNo__c from AccountAcount__c where id = :accs[0].id for update];
			// 2019/10/02 エラー修正 by zy END
			// レーシト番号
			String lastReciptNo = accs[0].ReciptNo__c;
			lastNum = CommUtils.nulltoZero(lastReciptNo.right(4));
		}
		// レーシト番号作成
		acc.ReciptNo__c = getReciptKey(acc,lastNum);
		try{
			// レーシト更新
			update acc;
			curAcc.ReciptNo__c = acc.ReciptNo__c;
		// 同じ番号制御
		}catch(Exception e){
			// 2019/10/02 エラー修正 by zy BEGIN
			if (errorInt < 2) {
				errorInt++;
				updateReciptNo(acc,errorInt);
			}
			// 2019/10/02 エラー修正 by zy END
		}
	}
	// レーシト番号作成
	public static string getReciptKey(AccountAcount__c acc,Decimal curNumber){
		// 当日
		String dtFormat = Datetime.newInstance(acc.SalesDate__c.year(),acc.SalesDate__c.month(),acc.SalesDate__c.day()).format('yyyyMMdd');
		// 店舗コード
		String spcd = CommUtils.isBlank(acc.ShopCode__c) ? '00' : acc.ShopCode__c;
		// 2019/10/02 エラー修正 by zy BEGIN
		return dtFormat + spcd + CommUtils.paddingLeftZero(CommUtils.nullToBlank(curNumber + 1).right(4) , 4);
		// 2019/10/02 エラー修正 by zy END
	}
	// 2019/03/28 オーダーエントリー改善 レシート番号連続 by zy END
	// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy BEGIN
	// 同じ会計商品数量マージフラグ
	private boolean transMergeFlg;
	public static boolean getTransMergeFlg(){
		return getInstance().transMergeFlg;
	}
	// 2019/05/31 オーダーエントリーでの一枠でまとまるようにして頂けないでしょうか。by zy END
	// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy BEGIN
	public static List<PrintInfo> getPrintLst(){
		return getInstance().printLst;
	}
	// 2019/07/31 オーダーエンドリーのIPAD印刷連携機能 by zy END
	// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy BEGIN
	private List<String> leadSQLst;
	public static List<String> getLeadSqlWhere(){
		return getInstance().leadSQLst;
	}
	// 2019/10/30 オーダーエントリー画面で、「部屋」から予約一覧を呼び出す際、当日にご予約がないお部屋は前日のご予約が表示されたままになってしまいます。 by zy END
	// 2020/03/30 初期画面を「テーブル選択画面」にする by zy BEGIN
	private boolean roomPageOpenFlg = true;
	public static boolean getRoomPageOpenFlg(){
		return getInstance().roomPageOpenFlg;
	}
	// 2020/03/30 初期画面を「テーブル選択画面」にする by zy END
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
	public class LacationInfo{
		public String name;
		public List<LacationInfo> locations;
		public boolean isCurrent;
		public String layoutId;
		// 2020/02/15 同店舗内でもレストラン毎の表示を可能にする by zy BEGIN
		public String startTm;
		public String endTm;
		public String roomtypeStr;
		public String cookTm;
		// 2020/02/15 同店舗内でもレストラン毎の表示を可能にする by zy END
		public LacationInfo(){
			locations = new List<LacationInfo>();
			isCurrent = false;
		}
	}
	// 場所指定集合
	private static Map<String,LacationInfo> layouDevlopMap;
	// デフォルトレイアウトId  
	private String firstLayoutId;
	public static String getFirstLayoutId(){
		return getInstance().firstLayoutId;
	}
	// 指定場所レイアウト取得
	public static List<SelectOption> getLayoutOpts(String spcd,boolean cookUseFlg){
		List<SelectOption> layoutOpts = new List<SelectOption>();
		List<Folder> fs = [select id from Folder where name = :DesignLayoutCtrl.DOC_NAME];
		String defaultLayoutId = '';
		String curLayoutId = '';
		// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy BEGIN
		String curType = '';
		// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy END
		if (!fs.isEmpty()){
			String parentId = fs[0].id;
			if (!layouDevlopMap.isEmpty()) {
				String selectKey = '%' + spcd + '%' + DesignLayoutCtrl.ATTACHMENT_NAME_USE;
				List<Document> atts = [select id,name,body from Document where  name like :selectKey and FolderId = :parentId order by DeveloperName];
				for (LacationInfo info : layouDevlopMap.values()) {
					List<Map<String,Object>> layoutNames = new List<Map<String,Object>>();
					for (Document doc : atts) {
						String layoutName = doc.name.replace(DesignLayoutCtrl.getDocName(spcd),'').replace(DesignLayoutCtrl.getDevlopeName(spcd),'').replace(DesignLayoutCtrl.ATTACHMENT_NAME_USE,'');
						for (LacationInfo child : info.locations) {
							if (layoutName == child.name){
								Map<String,object> layout = new Map<String,object>{'id' => doc.id,'name' =>layoutName};
								if (child.isCurrent) {
									layout.put('select',true);
									// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy BEGIN
									if (CommUtils.isBlank(curLayoutId)) {
										curLayoutId = doc.id;
										curType = child.startTm + '~' + child.endTm;
									}
									// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy END
								}
								if (CommUtils.isBlank(defaultLayoutId)) defaultLayoutId = doc.id;
								// 時間設定
								layout.put('time',child.startTm + '~' + child.endTm + '~' + child.cookTm);
								// 料理リスト用の函数
								if (cookUseFlg) {
									layout.put('roomtype',CommUtils.nullToBlank(info.roomtypeStr));
								}
								layoutNames.add(layout);
							}
						}
					}
					if (!layoutNames.isEmpty())
						layoutOpts.add(new SelectOption(JSON.serialize(layoutNames),info.name));
				}
				// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy BEGIN
				if (Commutils.isBlank(curLayoutId)) {
					curLayoutId = defaultLayoutId;
				}
				if (!CommUtils.isBlank(curType)) getInstance().defLayoutCurtype = curType;
				// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy END
				getInstance().firstLayoutId = curLayoutId;
			}
		}
		return layoutOpts;
	}
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
	private Map<String,LeadInfo> leadMap; // 作成部屋タイプ集合
	public static Map<String,LeadInfo> getLeadMap(){
		return getInstance().leadMap;
	}
	private boolean isMultiRoomFlg;
	public static boolean getMultiRoomFlg(){
		return getInstance().isMultiRoomFlg;
	}
	// 予約設定内容
	public class LeadInfo{
		public Map<String,String> fieldValueMap;
		public String roomType;
		public Integer night;
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
		public Set<String> cloneSet;
		// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
		public LeadInfo(Dom.XMLNode leadNode){
			night = 0;
			roomType = '';
			fieldValueMap = new Map<String,String>();
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
			cloneSet = new Set<String>();
			// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
			String nights = CommUtils.nullToBlank(leadNode.getAttribute('NIGHTS',null));
			String typeStr = CommUtils.nullToBlank(leadNode.getAttribute('ROOMTYPE',null));
			if (!CommUtils.isBlank(nights)) night = CommUtils.nullToIntZero(nights);
			if (night > 1) night = 1;
			if (!CommUtils.isBlank(typeStr)) roomType = typeStr;
			for(Dom.XMLNode assignNode : leadNode.getChildElements()) {
				// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
				String nodeName = assignNode.getName();
				if (nodeName == 'CLONE') {
					String fieldName = assignNode.getText();
					if (!CommUtils.isBlank(fieldName)) cloneSet.addAll(CommUtils.nullToBlank(fieldName).deletewhitespace().trim().toLowerCase().split(','));
					continue;
				}
				// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
				String fieldName = assignNode.getAttribute('FIELD',null);
				String defValue = assignNode.getText();
				fieldValueMap.put(CommUtils.nullToBlank(fieldName),CommUtils.nullToBlank(defValue));
			}
		}
	}
	// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
	// 2020/02/15 会計の簡易レイアウトを変更 by zy BEGIN
	// 該当会計の料理順番取得
	public static Integer getOrderEntryCnt(String roomId,String roomLeadId){
		// 料理順番初期化
		integer index = 0;
		// 指定部屋と予約の注文情報取得
		for (OrderEntryInfo__c order : [select id,trans__c,cookInfo__c from OrderEntryInfo__c where OrderStatus__c = :ORDER_STATUS_PRINT_INFO and RoomRef__c = :roomId and LeadRef__c = :roomLeadId]){
			// 注文情報未設定対応
			if (CommUtils.isBlank(order.cookinfo__c)) continue;
			// 注文情報取得
			List<String> transCnt = order.trans__c.split(',');
			// 注文の料理情報取得
			List<String> cookInfo = order.cookinfo__c.split(',');
			// 注文情報作成
			for (integer i = 0 ; i < transCnt.size(); i++) {
				string[] tranArr = transCnt[i].split(':');
				// 削除チェック
				if (tranArr.size() < 3) {
					String cook = cookInfo[i];
					String[] cooInfos = cook.split(':');
					Integer currentInt = CommUtils.nullToIntZero(Commutils.nullToBlank(cooInfos[2]));
					if (currentInt > index) index = currentInt;
				}
			}
		}
		return index;
	}
	// 2020/02/15 会計の簡易レイアウトを変更 by zy END
	// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy BEGIN
	public static boolean getCookDoneFlg(){
		return getInstance().cookDoneFlag;
	}
	private boolean cookDoneFlag;
	private static Set<String> getOrderCookDoneInfos(Set<String> roomIdSet){
		Set<String> leadSet = new Set<String>();
       	for (OrderEntryInfo__c order : [select id , leadRef__c from OrderEntryInfo__c where roomRef__c in :roomIdSet and CookDoneFlg__c = true]) {
			leadSet.add(order.leadRef__c);
		}
		return leadSet;
    }
	// 2020/04/15 全ての注文が提供済み場合、料理リストに該当部屋を非表示になる by zy END
	// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy BEGIN
	public static boolean getSelLeadRoomFlg(){
		return getInstance().selLeadRoomFlg;
	}
	private boolean selLeadRoomFlg;
	// 2020/04/15 空のテーブルを選んだ場合のみ、「部屋付け」が確定ボタンの上に表 by zy END
	// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　BEGIN
	private boolean kitchenOrderOnlyFlg;
	public static boolean getKitchenOrderOnlyFlg(){
		return getInstance().kitchenOrderOnlyFlg;
	}
	// 2020/04/30 料理リストの厨房レイアウトですが、こちらにまだ注文をかけていない料理も表示されてしまっているようです　by　zy　END
	// 2020/04/30 「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy BEGIN
	private boolean orderItemToMaseterFlg;
	public static boolean getOrderItemToMaseterFlg(){
		return getInstance().orderItemToMaseterFlg;
	}
	// 2020/04/30 「選択したテーブルの会計」に注文した商品が入力される形となりますが、実際に行いたかったのは「部屋付け先の客室の会計」に注文した商品が入力されるという挙動です。 by zy END
	// 2020/06/30 オーダエンドリーでの金額入力 by zy BEGIN
	private boolean orderPriceInputFlg;
	public static boolean getOrderPriceInputFlg(){
		return getInstance().orderPriceInputFlg;
	}
	// 2020/06/30 オーダエンドリーでの金額入力 by zy END
	// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy BEGIN
	private String defLayoutCurtype;
	public static String getDefLayoutCurtype(){
		return getInstance().defLayoutCurtype;
	}
	// 2020/08/15 オーダーエントリーの部屋レイアウトですが、画面を開いたタイミングでは、各予約の到着時刻・出発時刻に関わらず全ての予約が表示されてしまうようです。 by zy END
	// 2020/02/28 SITE機能対応　by zy BEGIN
	public static List<Room__c> getRoomsBySeq(boolean isDomainFlag,String oShopCode , Set<decimal> roomSet){
		List<Room__c> roomLst = new List<Room__c>();
		if (isDomainFlag) {
			roomLst = [select id,name from Room__c where seq__c = :roomSet and ShopInfoRef__r.ShopCode__c = :oShopCode];
		} else {
			roomLst = [select id,name from Room__c where seq__c = :roomSet];
		}
		return roomLst;
	}
	public static List<AccountMaster__c> getAccountMasterByProdSet(String queryStr,Set<String> prodCodeSet){
		// 検索結果格納
		return  Database.query(queryStr);
	}
	public static List<AccountAcount__c> getAccountsByLeadId(String leadId) {
		return [select id,frs__c,TaxRate__c,name,Field53__c from AccountAcount__c where Relreserve__c = :leadId];
	}
	public static List<AccountMaster__c> getAccountMasterByAccSets(Set<String> prodSet){
		return [select id , Name,Field5__c , TaxRateCal__c , ProductEnName__c , ServiceRate__c , PaymentType__c , jmstRef__c, Field3__c, SpecialTax__c,ActionType__c, (Select BreakName__c, AccountMasterRef__c From ProdFoodDetailRef__r order by OrderNo__c) from AccountMaster__c where id =:prodSet];
	}
	public static List<Tran1__c> getTransByAccoutId(String accId){
		return [select POSNo__c,Field9__c,Field21__c,Field23__c,Field7__c,Field50__c,UseDate__c,DeviceNo__c,InvoiceNoShowFlg__c,CreatedDate,OrderTime__c,IsDeleted,Field20__c from Tran1__c where Field1__c = :accId and Field9__c != null order by CreatedDate all rows];
	}
	public static List<OrderEntryInfo__c> getOrderEntrysByAccId(String accId){
		return [select AccountRef__c, Id, LeadRef__c, Name, OrderStatus__c, OrderTime__c, PrintInfo__c, RoomRef__c, Trans__c,OrderTimeStmp__c from OrderEntryInfo__c where AccountRef__c =:accId and OrderStatus__c='印刷情報' order by OrderTime__c asc];
	}
	public static void upsertTrans(List<tran1__c> tranLst){
		upsert tranLst;
	}
	public static List<Tran1__c> getTransByAccountMasterAndAccId(String accountId,Set<String> accMasterIds){
		return [select id,Field1__c,Field21__c,Field23__c,Field7__c,Field7__r.Field5__c,Field7__r.TaxRateCal__c,Field7__r.ServiceRate__c,OrderTimeStmp__c,OrderTime__c,Field20__c from Tran1__c where Field1__c = :accountId and Field7__c = :accMasterIds and InvoiceNoShowFlg__c = false 
		// 2020/06/30 オーダエンドリーでの金額入力 by zy END
									and ParentTran1Ref__c = null
									order by orderTime__c asc];
	} 
	public static void insertCooperationResultInfo(List<CooperationResult__c> info){
		insert info;
	}
	// 2020/02/28 SITE機能対応　by zy END
}