/*
* レイアウトカスタマイズ機能
* 2019/06/31 新規
*/
global with sharing class DesignLayoutCtrl {
	// 店舗情報リスト
	public List<SelectOption> branchShopLst{get; private set;}
	// 店舗コード
    public String branchShopNm{get; set;}
    // 店舗基本情報
    public String layoutJSON{get;set;}
    // レイアウト名同じ鍵
	private static string ATTACHMENT_NAME = 'LAYOUT_TEMP';
	// レイアウト正式
	private static string ATTACHMENT_NAME_SAVE = 'LAYOUT_SAVE';
	// レイアウト有効
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
	public static String ATTACHMENT_NAME_USE = 'USED';
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	// 店舗デフォルト名
	private static String ATTACHMENT_NAME_SHOPDEF = '該当レイアウト';
	// ドキュメントファイル名
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
	public static String DOC_NAME = 'Template';
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	// テンプレートのデフォルト名
	private static String ATTACHMENT_DEF_NAME = 'テンプレート';
	// 添付Id
	public String attachmentId{get;set;}
	// 初期化
	public DesignLayoutCtrl() {
		// 画面指定店舗コード
		branchShopNm = Apexpages.currentPage().getParameters().get('spcd');
		// 未指定店舗コード、ユーザーコード設定
		if(CommUtils.isBlank(branchShopNm)) branchShopNm = UserUtil.CurrentUser.ShopCode__c;
		// 添付Id初期化
		attachmentId = '';
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		if (Apexpages.currentPage().getParameters().containsKey('layoutId')) 
			attachmentId = CommUtils.nullTOBlank(Apexpages.currentPage().getParameters().get('layoutId'));
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	}
	// 画面初期化
	public void init() {
		// 店舗リスト取得
		getShopList();
		// 該当レイアウト設定情報
		getLayoutInfo();
	}
	// 支店選択リスト変更の場合、関連の支店所属する部屋を取得、情報を表示する
    public void refreshBranchShopInfo() {getLayoutInfo();}
	// 店舗リスト取得
	private void getShopList() {
		// 該当ユーザー店舗取得
		branchShopLst = ShopInfoUtil.getBranchShopLst(UserUtil.CurrentUserInfo.shops);
		// 店舗未指定の場合
		if (CommUtils.isBlank(branchShopNm)) {
			// 顧客に設定する支店で初期値に設定する[2013/06/30]
			String locShopCode = UserUtil.CurrentUser.ShopCode__c;
	    	for (SelectOption s : branchShopLst) {
	    		if (s.getValue() == locShopCode) branchShopNm = locShopCode;
	    	}
		}
	}
	// 店舗の基本情報取得
	private void getLayoutInfo(){
		String width;String height;String color;LayoutInfo info = new LayoutInfo();
		// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy BEGIN	
		noLeadSelFlg = false;chkoutRoomFlg = false;mobileDblClickFlg = false;
		// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy END
		try{
			Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlDoc('RoomLayoutConfig', branchShopNm,new String[]{'<LOGOIMG>','</LOGOIMG>'});
			if (targetNode != null) {
				Dom.XmlNode shapeNode = targetNode.getChildElement('SHAPE',null);
				if (shapeNode != null) {
					// カラー設定
					Dom.XmlNode colorNode = shapeNode.getChildElement('COLOR',null);
					if (colorNode != null) color = CommUtils.nullToBlank(colorNode.getText());
					// 横幅設定
					Dom.XmlNode widthNode = shapeNode.getChildElement('WIDTH',null);
					if (widthNode != null) width = CommUtils.nullToBlank(widthNode.getText());
					// 高度設定
					Dom.XmlNode heightNode = shapeNode.getChildElement('HEIGHT',null);
					if (heightNode != null) height = CommUtils.nullToBlank(heightNode.getText());
				}
				// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy BEGIN
				Dom.XmlNode layoutNode = targetNode.getChildElement('LAYOUTSETING',null);
				if (layoutNode != null){
					String noleadSelAttr = layoutNode.getAttribute('NOLEADSEL',null);
					String blankSelAttr = layoutNode.getAttribute('CHECKOUTSEL',null);
					String roomChgDblClick = layoutNode.getAttribute('ROOMCHGDBLCLICK',null);
					if (!CommUtils.isBLank(noleadSelAttr)) {
						noLeadSelFlg = boolean.valueof(CommUtils.nullToBlank(noleadSelAttr));
					}
					if (!CommUtils.isBLank(blankSelAttr)) {
						chkoutRoomFlg = boolean.valueof(CommUtils.nullToBlank(blankSelAttr));
					}
					if (!CommUtils.isBlank(roomChgDblClick)) mobileDblClickFlg = boolean.valueOf(CommUtils.nullToBlank(roomChgDblClick));
				}
				// 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy END
			}
		} catch(Exception e){}
		info.width = CommUtils.isBlank(width) ? '78' : width;
		info.height = CommUtils.isBlank(height) ? '78' : height;
		info.color = CommUtils.isBlank(color) ? '#ececec' : color;
		layoutJSON = JSON.serialize(info);
	}
	// 店舗の有効レイアウト
	public static string getDefLayoutList(string spcd) {
    	return getLayoutByName(spcd,true);
	}
	// 店舗レイアウト取得
	private static String getLayoutByName(String spcd,boolean validateFlg){
    	String devlop = getDevlopeName(spcd);
		if (validateFlg != null) {
			// 有効のレイアウト取得
			if (validateFlg) devlop += ATTACHMENT_NAME_USE;
    	// 店舗コードあり
    	List<Document> atts = [select id,name,body from Document where  name = :devlop];
    	if (!atts.isEmpty()) {
    		// レイアウト内容設定
    		return atts[0].body.toString();
			}
		} else {
			Document doc =  getDevlopDocument(spcd);
			if (doc != null) return doc.body.toString();
    	}
		return '';
	}
	/*
	* 連携中心
	* dataType:方法名
	* req: 連携情報
	*/
	@remoteaction 
	global static object remoteCenter(String dataType ,String req){
		// 該当店舗指定レイアウト作成
		if (dataType == 'shopSave') return shopSave(req);
		// テンプレート作成
		else if (dataType == 'templateSave') return templateSave(req);
		// テンプレート取得
		else if (dataType == 'refreshAttachments') return refreshAttachments(req);
		// テンプレート削除
		else if (dataType == 'removeTemplate') return removeTemplate(req);
		// 指定テンプレート取得
		else if (dataType == 'getAttachment') return getAttachment(req);
		// 部屋リスト取得
		else if (dataType == 'getRoomLst') return getRoomLst(req);
		// 店舗レイアウト状態変更
		else if (dataType == 'layoutStatusChange') return layoutStatusChange(req);
		// 変更店舗情報設定
		else if (dataType == 'updateShopDocSetting') return updateShopDocSetting(req);
		return null;
	}
	// 該当店舗指定レイアウト作成
	private static object shopSave(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class) ;
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		if (!CommUtils.isBlank(request.attId)) {
			Document doc = getDevlopDocumentById(request.attId);
			if (doc != null) {
				doc.body = blob.valueof(request.shapes);
				update doc; 
			}
			return 'ok';
		}
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where name = :DOC_NAME];
		if (!fs.isEmpty()) {
			String folderId =  fs[0].id;
			Document doc = getDevlopDocument(request.shopCd);
			String useDevloperName = getDevlopeName(request.shopCd);
			if (doc == null) {
				// TimeStamp
				String timeStamp = System.now().format('yyyyMMddHHmmss');
				Document attchment = new Document(
					body = Blob.valueOf(request.shapes),
					FolderId = fs[0].id,
		        	ContentType = 'text/xml',
		        	type = 'xml',
		        	DeveloperName = useDevloperName + timeStamp,
		        	name = useDevloperName
				);
				insert attchment;
			} else {
				doc.body = blob.valueof(request.shapes);
				update doc; 
			}
		}
		return 'ok';
	}
	// テンプレート作成
	private static object templateSave(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
		// ファイル格納のフォルダを取得する
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		List<Folder> fs = [select id,name from Folder where name = :DOC_NAME];
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		if (!fs.isEmpty()) {
			Document attchment = new Document();
			if (CommUtils.isBlank(request.attId)) {
			// TimeStamp
			String timeStamp = System.now().format('yyyyMMddHHmmss');
				attchment = new Document(
				FolderId = fs[0].id,
	        	ContentType = 'text/xml',
	        	type = 'xml',
	        	DeveloperName = 'temp' + timeStamp
			);
			String docName =  CommUtils.isBlank(request.name) ? ATTACHMENT_DEF_NAME + timeStamp : CommUtils.nullTOBlank(request.name);
				attchment.name = getDocName(request.shopCd) + docName;
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
				Set<String> exitName = new Set<String>{attchment.name,(attchment.name + ATTACHMENT_NAME_USE)};
				List<document> exitNameDocs = [select id from document where name =:exitName];
				if (!exitNameDocs.isEmpty()) {
					return new Map<String,Boolean>{'exitflag' => true};
				}
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
			} else{
				attchment.id = request.attId;
				if (!CommUtils.isBlank(request.name)) attchment.name = getDocName(request.shopCd) + request.name;
			}
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
			// 確定フラグの場合
			if (request.upsertFlg != null && request.upsertFlg) {
				attchment.name = attchment.name.replace(ATTACHMENT_NAME_USE,'') + ATTACHMENT_NAME_USE;
			}
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
			attchment.body = Blob.valueOf(request.shapes);
			attchment.Description = CommUtils.nullToBlank(request.descr);
			upsert attchment;
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
			return new Document(id = attchment.id);
			// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
			// 確定フラグの場合
			if (request.upsertFlg != null && request.upsertFlg) {
				Document doc = getDevlopDocument(request.shopCd);
				if (doc != null) {
					update new Document(id = doc.id , body = attchment.body);
				} else {
					// TimeStamp
					String timeStamp = System.now().format('yyyyMMddHHmmss');
					String useDevloperName = getDevlopeName(request.shopCd);
					doc = new Document(
						body = attchment.body,
						FolderId = fs[0].id,
			        	ContentType = 'text/xml',
			        	type = 'xml',
			        	DeveloperName = useDevloperName + timeStamp,
			        	name = useDevloperName
					);
					insert doc;
				}
				return new Map<String,String> {'Id' => ''};
			}
			return new Document(id = attchment.id);
		}
		return null;
	}
	// テンプレート取得
	private static object refreshAttachments(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
		Map<String,Object> result = new Map<String,Object>();
		// 店舗コード
		String shopCd = request.shopCd;
		List<Map<String,Object>> dropDown = refreshAttach(shopCd);
		result.put('drop' , dropDown);
		// 該当ドキュメント内容刷新あり
		if (request.refresh) {
			AjaxRequest resultReq = getAttachmentById(request.attId,request.shopCd);
			result.put('doc' , resultReq);
		}
    	return result;
	}
	// テンプレート削除
	private static object removeTemplate(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
		// 指定添付削除
		delete [select id from Document where id = :request.attId];
    	return refreshAttach(request.shopCd);
	}
	// 指定テンプレート取得
	private static object getAttachment(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
    	return getAttachmentById(request.attId,request.shopCd);
	}
	private static AjaxRequest getAttachmentById(String attId,String shopCd){
		AjaxRequest result = new AjaxRequest();
    	result.shapes = '';
    	result.descr = '';
    	result.modify = '';
    	result.create = '';
		if (!CommUtils.isBlank(attId)) {
			List<Document> atts = [select id,name,body,Description,CreatedBy.name,CreatedDate,LastModifiedBy.name,LastModifiedDate from Document where id = :attId];
	    	if (!atts.isEmpty()) {
	    		result.shapes = atts[0].body.toString();
	    		result.descr = atts[0].Description;
	    		result.modify = atts[0].CreatedBy.name + ' ' + atts[0].CreatedDate.format();
	    		result.create = atts[0].LastModifiedBy.name + ' ' + atts[0].LastModifiedDate.format();
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
	    		result.name = atts[0].name.replace(getDocName(shopCd),'').replace(ATTACHMENT_NAME_USE,'');
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	    	}
	    } else {
	    	Document doc = getDevlopDocument(shopCd);
	    	if (doc != null) {
	    		result.shapes = doc.body.toString();
	    		result.descr = doc.Description;
	    		result.modify = doc.CreatedBy.name + ' ' + doc.CreatedDate.format();
	    		result.create = doc.LastModifiedBy.name + ' ' + doc.LastModifiedDate.format();
	    	}
	    }
    	return result;
	}
	// 部屋リスト取得
	private static object getRoomLst(String req) {
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
		// 初期化
		List<Map<string, Object>> result = new List<Map<string, Object>>();
		// 空値対応
		result.add(new Map<string, string>{'name'=>'　', 'value'=>''});
		// 該当店舗の部屋取得
		for(Room__c room : OrderServiceHelp.getRoomLst(request.shopCd)) {
			result.add(new Map<string, Object>{'name' => room.name, 'value' => room.id , 'idx' => result.size()});
		}
		return result;
	}
	// 店舗レイアウト状態変更
	private static object layoutStatusChange(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
		if (!CommUtils.isBlank(request.attId)) {
			Document doc = getDevlopDocumentById(request.attId);
			if (doc != null) {
				String docName = doc.name.replace(ATTACHMENT_NAME_USE,'');
				if (request.validate) docName = docName + ATTACHMENT_NAME_USE;
				Document newDoc = new Document(id = doc.id,name = docName);
				if (!CommUtils.isBlank(request.shapes)) newDoc.body = blob.valueof(request.shapes);
				update newDoc;
				return new Document(id = doc.id);
			}
		}
		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
		Document doc = getDevlopDocument(request.shopCd);
		if (doc != null) {
			String docName = doc.name.replace(ATTACHMENT_NAME_USE,'');
			if (request.validate) docName = docName + ATTACHMENT_NAME_USE;
			update new Document(id = doc.id,name = docName);
		}
		return null;
	}
	// 変更店舗情報設定
	private static object updateShopDocSetting(String req){
		AjaxRequest request = (AjaxRequest)JSON.deserialize(req, AjaxRequest.class);
		// 拡張予約項目を定義する
    	List<Document> sr = [select body, name from Document where DeveloperName = 'RoomLayoutConfig'];
    	String pShopCode = request.shopCd;
    	if (!sr.isEmpty()) {
    		Blob xmlBody = sr[0].Body;
    		String strXmlBody = xmlBody.toString();
    		Dom.XmlNode targetNode, firstNode = null;
    		Dom.Document doc = new Dom.Document();
    		doc.load(strXmlBody);
			Dom.XmlNode root = doc.getRootElement();
			for(Dom.XMLNode shop : root.getChildElements()) {
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
			// 目標店舗情報を取得する、店舗コード未設定する場合、一番目の店舗情報で設定する
			targetNode = targetNode == null ? firstNode : targetNode;
			if (targetNode != null) {
				Dom.XmlNode shapeNode = targetNode.getChildElement('SHAPE',null);
				if (shapeNode != null) {
					if (request.descr == 'Color') {
						// カラー設定
						Dom.XmlNode colorNode = shapeNode.getChildElement('COLOR',null);
						if (colorNode != null) {
							for(Dom.XmlNode child : colorNode.getChildren()) {
								if(child.getNodeType() == Dom.XmlNodeType.Text) {
									colorNode.removeChild(child);
									colorNode.addTextNode(request.value);
									break;
								}
							}
						}
					} else if (request.descr == 'Width') {
						// 横幅設定
						Dom.XmlNode widthNode = shapeNode.getChildElement('WIDTH',null);
						if (widthNode != null) {
							for(Dom.XmlNode child : widthNode.getChildren()) {
								if(child.getNodeType() == Dom.XmlNodeType.Text) {
									widthNode.removeChild(child);
									widthNode.addTextNode(request.value);
									break;
								}
							}
						}
					} else if (request.descr == 'Height') {
						// 高度設定
						Dom.XmlNode heightNode = shapeNode.getChildElement('HEIGHT',null);
						if (heightNode != null) {
							for(Dom.XmlNode child : heightNode.getChildren()) {
								if(child.getNodeType() == Dom.XmlNodeType.Text) {
									heightNode.removeChild(child);
									heightNode.addTextNode(request.value);
									break;
								}
							}
						}
					}
					sr[0].Body = blob.valueOf(doc.toXmlString());
					update sr[0];
				}
			}
		}
		return null;
	}
	// 指定店舗の添付リスト刷新
	private static List<Map<String,Object>> refreshAttach(String shopCd){
		List<Map<String,Object>> attachMents = new List<Map<String,Object>>();
		// 店舗のデフォルト名
		Document doc = getDevlopDocument(shopCd);
		String name = ATTACHMENT_NAME_SHOPDEF;
		// 有効チェック
		boolean validateFlg = doc != null && doc.name.indexof(ATTACHMENT_NAME_USE) >= 0;
		// 指定ドキュメントあり
		name = ATTACHMENT_NAME_SHOPDEF + '(' + (validateFlg ? '有効中' : '無効中') + ')';
		// 店舗用ドキュメント設定
		attachMents.add(new Map<String,Object>{'name' => name,'id' => '' , 'status' => validateFlg});
		// ファイル格納のフォルダを取得する
		List<Folder> fs = [select id from Folder where name = :DOC_NAME];
		if (!fs.isEmpty()){
			String parentId = fs[0].id;
			String quertSQL =  'select id,name from Document where name like \'' + getDocName(shopCd) + '%\' and FolderId = :parentId';
			// 表示順設定
			quertSQL += ' order by name';
			List<Document> atts = Database.query(quertSQL);
	    	for (Document att : atts) {
				// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
				Map<String,object> obj = new Map<String,Object>{'name'=> att.name.replace(getDocName(shopCd),'').replace(ATTACHMENT_NAME_USE,'(有効中)'),'id' => att.id,'status' => att.name.indexof(ATTACHMENT_NAME_USE) >= 0};
	    		attachMents.add(obj);
	    		// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	    	}
		}
		
    	return attachMents;
	}
	// 店舗指定レイアウト取得
	private static Document getDevlopDocument(String shopCd){
	    String devName = getDevlopeName(shopCd) + '%';
		List<Document> docs = [select id,name,body,Description,CreatedBy.name,CreatedDate,LastModifiedBy.name,LastModifiedDate from Document where name like :devName];
	    if (!docs.isEmpty()) return docs[0];
	    return null;
	}
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy BEGIN
	// 店舗指定レイアウト取得
	private static Document getDevlopDocumentById(String docId){
		List<Document> docs = [select id,name,body,Description,CreatedBy.name,CreatedDate,LastModifiedBy.name,LastModifiedDate from Document where id = :docId];
	    if (!docs.isEmpty()) return docs[0];
	    return null;
	}
	// 指定店舗レイアウト名取得
	public static String getDocName(String spcd){
		return ATTACHMENT_NAME + '_' + spcd + '_';
	}
	public static String getDevlopeName(String spcd){
		return ATTACHMENT_NAME_SAVE + '_' + spcd;
	}
	// 2020/01/30 レイアウトを複数作成できるようにし、「朝昼夕」と「レストラン毎」に画面を切り替えられるように by zy END
	public Class LayoutInfo{
		String width;
		String height;
		String color;
	}
	// 連携用情報
    public class AjaxRequest{
    	String shapes; // レイアウト情報
    	String shopCd; // 店舗コード
    	String attId;  // 添付Id
    	String name;   // 添付名
    	boolean validate; // 有効フラグ
    	String descr;
    	String modify;
    	String create;
    	boolean upsertFlg; // 確定フラグ
    	boolean refresh;   // 刷新フラグ
    	String value;
    }
    // 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy BEGIN
    public boolean noLeadSelFlg{get;set;}
    public boolean chkoutRoomFlg{get;set;}
	public boolean mobileDblClickFlg{get;set;}
    // 2019/12/30 予約の入っていないお部屋のページが開かないようになっているほうが、入力ミスが起きにくく、時間短縮になる、チェックアウト済の部屋はグレーになって、それ以上オーダーエントリーからは追加入力できなくする by zy END
}