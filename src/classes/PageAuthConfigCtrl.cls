public with sharing class PageAuthConfigCtrl {
    public UserUtil.UserShopInfo userInf;
    public String branchShopNm{get;set;}
    public String profileIds{get;set;}
    public List<SelectOption> branchShopLst{get; private set;}
    public List<SelectOption> roleLst{get; private set;}
    public List<SelectOption> profileLst{get; private set;}
    public String errorMessage{get;set;}
    public boolean isShowPageDetail{get;set;}
    public PageAuthConfigCtrl() {
        branchShopNm = null;
        userInf = UserUtil.CurrentUserInfo;
        //アクセス権限がないため要求を実行できません。データの所有者または、システム管理者にお問い合わせください。
	    errorMessage = Label.MSG_035_0132;
        isShowPageDetail = false;
    }
    public void init(){
        initDoc();
        initCookie();
        setInitBranShopLst();
        setInitProfileLst();
    }
    public void initDoc(){
        try{
            // XML読み込み
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('PageAuthConfigXml',null);
			if (targetNode != null) {
                Dom.XmlNode accessNode = targetNode.getChildElement('ACCESSUSER', null);
                if (accessNode != null) {
                    for (Dom.XmlNode userNode : accessNode.getChildElements()) {
                        String domName = userNode.getName();
                        if ('USERNAME' == domName){
                            if(CommUtils.nullToBlank(userNode.getText()) == UserInfo.getUserName()){
                                isShowPageDetail = true;
                                break;
                            }
                        }
                    }
                } 
                
            }
        } catch(Exception e){

        }
    }
    private void initCookie(){
        String initJson = getCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.SETINFO.name());
        if (!CommUtils.isBlank(initJson)) {
            CookieInfo info = (CookieInfo) JSON.deserialize(initJson,CookieInfo.class);
            if (info.shopcds != null && !info.shopcds.isEmpty()) 
                branchShopNm = String.join(info.shopcds,',');
            if (info.profiles != null && !info.profiles.isEmpty()) 
                profileIds = String.join(info.profiles,',');
        }
    }
    private void setInitBranShopLst() {
        branchShopLst = ShopInfoUtil.getBranchShopLst(userInf.shops);
        List<String> exitCodeLst = new List<String>();
        Set<String> codeSet = new Set<String>();
        if (ApexPages.currentPage().getParameters().containsKey('spcd')) {
            branchShopNm = ApexPages.currentPage().getParameters().get('spcd');
        }else{
            if (branchShopNm != null) {
                codeSet = new Set<String>(branchShopNm.split(','));
            }
            if (!branchShopLst.isEmpty()) {
                // 顧客に設定する支店で初期値に設定する[2013/06/30]
                String locShopCode = UserUtil.CurrentUser.ShopCode__c;
                // 指定デフォルトコード
                for (SelectOption s : branchShopLst) {
                    if (branchShopNm != null) {
                        String spcd = s.getValue();
                        if (codeSet.contains(spcd)) exitCodeLst.add(spcd);
                    } else if (!codeSet.contains('') && s.getValue() == locShopCode) branchShopNm = locShopCode;
                }
                if(!exitCodeLst.isEmpty()) branchShopNm = String.join(exitCodeLst,',');
            }
        }
    }
    private void setInitProfileLst(){
        profileLst = new List<SelectOption>();
        for (Profile p : [select Id, Name, UserType from Profile]) {
            profileLst.add(new SelectOption(p.id,p.name));
        }
    }
    private void setInitRoleLst(){
        roleLst = new List<SelectOption>();
        for (UserRole role : [select Id, Name from UserRole]) {
            roleLst.add(new SelectOption(role.id,role.name));
        }
    }
    @remoteAction
    public static object remoteCenter(String type,String data){
        if (type == 'getUsers') return getUsers(data);
        else if (type == 'saveUsers') return saveUsers(data);
        return null;
    }
    private static object getUsers(String data){
        Request req = (Request)JSON.deserializeStrict(data,Request.class);
        List<Response> res = new List<Response>();
        Set<String> profileSt = new Set<String>(CommUtils.nullToBlank(req.profileStr).split(','));
        Set<String> shopSt = new Set<String>(CommUtils.nullToBlank(req.shops).split(','));
        CookieInfo info = new CookieInfo();
        info.shopcds = new List<String>(shopSt);
        info.profiles = new List<String>(profileSt);
        profileSt.remove('');
        shopSt.remove('');
        String userQuery = 'select id,lastName,firstName , ReadOnlyLst__c,profileId,profile.name,UserRoleId,UserRole.name from User ';
        String whereSQL = '';
        List<String> whereLst = new List<String>();
        if (!shopSt.isEmpty()) {
            whereLst.add(' ( DefaultShopCode__c = :shopSt or ShopCode__c = :shopSt ) ');
        } 
        if (!profileSt.isEmpty()) {
            whereLst.add(' profileId = :profileSt');
        }
        saveCookieInfo(UserConfigCompCtrl.KREP_SUBTYPE.SETINFO.name(),JSON.serialize(info));
        if (!whereLst.isEmpty()) whereSQL = ' where ' + String.join(whereLst,' and ');
        String countSQL = 'select count(id) total from User';
        AggregateResult[] groupedResults = Database.query(countSQL + whereSQL);
        integer countInt = 0;
        for (AggregateResult avgRs : groupedResults) {
            countInt = (integer)(avgRs.get('total'));
        }
        String orderSQL = ' order by profileId,UserRoleId';
        Integer limitInt = 2000;
        if (countInt > limitInt) {
            Response response = new Response();
            response.warn = Label.MSG_040_0113.replace('XXXXXX',String.valueOf(limitInt));
            orderSQL += ' limit ' + limitInt;
            res.add(response);
        }
        for (User u : Database.query(userQuery + whereSQL + orderSQL)) {
            Response response = new Response();
            String firstName = CommUtils.isBlank(u.firstName) ? '' : ' ' + CommUtils.nullToBlank(u.firstName);
            response.name = CommUtils.nullToBlank(u.lastName) + firstName;
            response.dataid = u.id;
            response.profileId = u.profileId;
            response.profileNm = CommUtils.nullTOBlank(u.profile.name);
            response.roleNm = CommUtils.nullTOBlank(u.UserRole.name);
            String readOnlyMsg = CommUtils.nullToBlank(u.ReadOnlyLst__c);
            response.hadRoomFlg = !readOnlyMsg.contains(Commconst.READ_ONLY_MODE_ROOMINDICATOR);
            response.hadTimeTable = !readOnlyMsg.contains(Commconst.READ_ONLY_MODE_ROOMSCHEDULE);
            response.hadTaskFlg = !readOnlyMsg.contains(Commconst.READ_ONLY_MODE_TASK);
            res.add(response);
        }
        return res;
    }
    private static object saveUsers(String data){
        List<Response> res = (List<Response>)JSON.deserializeStrict(data,List<Response>.class);
        List<User> users = new List<User>();
        for (Response r : res) {
            users.add(new User(id = r.dataid,ReadOnlyLst__c = getReadStr(r.hadRoomFlg,r.hadTimeTable,r.hadTaskFlg)));
        }
        if (!users.isEmpty()) update users;
        return null;
    }
    private static String getReadStr(boolean isRoom,boolean isTime,boolean isTask){
        List<String> statusLst = new List<String>();
        if (!isRoom) statusLst.add(Commconst.READ_ONLY_MODE_ROOMINDICATOR);
        if (!isTime) statusLst.add(Commconst.READ_ONLY_MODE_ROOMSCHEDULE);
        if (!isTask) statusLst.add(Commconst.READ_ONLY_MODE_TASK);
        return String.join(statusLst,',');
    }
    // 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
    public static String getCookieInfo(String subType){
    // 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
        map<String,String> userBookMap = UserConfigCompCtrl.getCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.READONLY,
                                            UserUtil.CurrentUser.id,'');
        // 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy BEGIN
        String cookieInfo = CommUtils.nullToBlank(userBookMap.get(subType));
        // 2019/07/31 ルームインジケータの店舗の初期値をallにしたいとの要望です by zy END
        return cookieInfo;
    }
    public static void saveCookieInfo(String subType,String settingInfo){
        // Cookieからレイアウトモードを取得する
        UserConfigCompCtrl.saveCommConfig(UserConfigCompCtrl.FUNCTION_TYPE.READONLY,
                subType,settingInfo,UserUtil.CurrentUser.id,'');
    }
    public class Request{
        List<String> profiles;
        List<String> roleIds;
        String shops;
        String profileStr;
    }
    public class Response{
        String name;
        String dataid;
        String groupId;
        String profileId;
        String profileNm;
        String roleNm;
        String error;
        String warn;
        boolean hadRoomFlg;
        boolean hadTimeTable;
        boolean hadTaskFlg;
        public Response(){
            hadRoomFlg = true;
            hadTaskFlg = true;
            hadTimeTable = true;
        }
    }
    class CookieInfo{
        List<String> shopcds;
        List<String> profiles;
        List<String> groups; 
    }
    // 2019/10/15 iPadは陣屋コネクトとして推奨しているモバイル端末であり、iPadでは一切ドラッグ＆ドロップができなくなるのも困りますので、編集モードと閲覧モードの切り替えができる様にお願いします by zy BEGIN
    public static boolean getMobileReadonlyFlg(String pShopCode){
        Boolean mobilereandOnly = false;
        try{
            String docName = 'PageAuthConfigXml';
            // 拡張予約項目を定義する
            List<Document> sr = [select body, name from Document where DeveloperName = :docName];
            Blob xmlBody = sr[0].Body;
            String strXmlBody = xmlBody.toString();
            Dom.XmlNode targetNode, firstNode = null;
            Dom.Document doc = new Dom.Document();
            doc.load(strXmlBody);
            Dom.XmlNode root = doc.getRootElement();
            for(Dom.XMLNode shop : root.getChildElements()) {
                String nodeName = shop.getName();
                if (nodeName == 'SHOP') {
                    // 各店舗情報はＸＭＬから取得する
                    Dom.XmlNode shopcode =  shop.getChildElement('SHOPCODE', null);
                    //2017/04/27 commit by zy BEGIN
                    if (shopcode == null) continue;
                    //2017/04/27 commit by zy END
                    // 店舗コードを取得する
                    String strShopCode = CommUtils.nullToBlank(shopcode.getText());
                    if (firstNode == null) firstNode = shop;
                    // ログインユーザの店舗コードと一致する場合
                    if (strShopCode == pShopCode) {
                        targetNode = shop;
                        break;
                    }
                }
            }
            // 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
            targetNode = targetNode == null ? firstNode : targetNode;
            if (targetNode == null) throw New CommException('Config Xml(' + docName +') File Parse Faied!!!');
			if (targetNode != null) {
                Dom.XmlNode accessNode = targetNode.getChildElement('APPLICATION', null);
                if (accessNode != null) {
                    Dom.XmlNode roomIndcatorNode = accessNode.getChildElement('ROOMINDICATOR', null);
                    if (roomIndcatorNode != null) {
                        Dom.XmlNode MOBILE_READONLY = roomIndcatorNode.getChildElement('MOBILE_READONLY', null);
                        if (MOBILE_READONLY != null) mobilereandOnly = boolean.valueof(CommUtils.nullToBlank(MOBILE_READONLY.getText()));
                    }
                } 
            }
        } catch(Exception e){
            System.debug(LoggingLevel.info, 'e:::' + e);
        }
        return mobilereandOnly;
    }
    // 2019/10/15 iPadは陣屋コネクトとして推奨しているモバイル端末であり、iPadでは一切ドラッグ＆ドロップができなくなるのも困りますので、編集モードと閲覧モードの切り替えができる様にお願いします by zy END
}