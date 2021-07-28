public with sharing class FreeeSyncCsvPostBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts{
	public final String disName = CommConst.DISNAME;   // 事業所名
	public final String callBack = CommConst.CALLBACK; // 回调函数
	// FreeeAPI
	public static final String account_items = 'account_items'; // 勘定科目
	public static final String companies = 'companies'; // 事業所
	public static final String items = 'items'; // 品目
	public static final String manual_journals = 'manual_journals'; // 振替伝票
	public static final String sections = 'sections'; // 部門
	public static final String taxes = 'taxes';
	// FreeeAPI => Label
	public static final Map<String, String> apiLabelMap = new Map<String, String>{
		account_items => '勘定科目',
		companies => '事業所',
		items => '品目',
		manual_journals => '振替伝票',
		sections => '部門',
		taxes => '税区分'
	};
	public ProDocumentInfo pro;
	public List<ProShopInfo> proShopInfoLst;
	public Map<String, List<ProDocumentInfo>> proDocInfoMap;
	
	public FreeeSyncCsvPostBatch(List<ProShopInfo> proShopInfoLst, Map<String, List<ProDocumentInfo>> proDocInfoMap){
		this.proShopInfoLst = proShopInfoLst;
		this.proDocInfoMap = proDocInfoMap;
	}
	// ***********************************
	// バッチ処理開始
	// ***********************************
	public Iterable<String> start(Database.BatchableContext info){
		List<String> blankLst = new List<String>();
		if(proShopInfoLst.isEmpty()) return blankLst;
		// 有效店铺信息处理
		for(ProShopInfo proShop : proShopInfoLst){
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'proShop:='+proShop);
			if(!proShop.isStartFlg) continue;
			if(!proDocInfoMap.containsKey(proShop.shopCode)) continue;
			List<ProDocumentInfo> proDocInfoLst = proDocInfoMap.get(proShop.shopCode);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'proDocInfoLst:='+proDocInfoLst);
			if(proDocInfoLst.isEmpty()) continue;
			// 防止地址共存
			pro = proDocInfoLst[0].clone();
			break;
		}
		if(pro == null) return blankLst;
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'PRO:='+PRO);
		List<Document> docLst = [Select Body From Document Where Id =: pro.docmentId];
		if(docLst.isEmpty()) return blankLst;
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'DOCLST[0].BODY:='+DOCLST[0].BODY.TOSTRING());
		// 数据行分割
		List<String> lineLst = CommUtils.nullToBlank(docLst[0].Body.toString()).split('\n');
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'LINELST:='+LINELST);
		// データが存在する場所
		if(lineLst.size() > 1){
			CommCsvUtils.CSVParser csvItem =  new CommCsvUtils.CSVParser();
			for(Integer i = 1; i < lineLst.size(); i++){
				String ln = lineLst[i];
				// // SYSTEM.DEBUG(logginglevel.info,'ln:='+ln);
				List<String> lnLst = csvItem.parseLine(CommUtils.nullToBlank(ln));
				if(lnLst.size() < 16) continue;
				FreeeLineInfo item = new FreeeLineInfo();
				item.startDay = CommUtils.nullToBlank(lnLst[1]); // 日付[1] yyyyMMdd
				item.startNo = CommUtils.nullToBlank(lnLst[2]);  // 伝票No.[2]
				// 借方
				item.debitSubName = CommUtils.nullToBlank(lnLst[3]);	 // 借方勘定科目[3]
				item.debitHojyoKamoku = CommUtils.nullToBlank(lnLst[4]); // 借方補助科目[4]
				item.debitDepartment = CommUtils.nullToBlank(lnLst[5]);  // 借方部門[5]
				item.debitTaxKbn = CommUtils.nullToBlank(lnLst[6]);		 // 借方税区分[6]
				item.debitAmount = CommUtils.nullToZero(lnLst[7]).intValue();	 // 借方金額[7]
				item.debitTaxAmount = CommUtils.nullToZero(lnLst[8]).intValue(); // 借方税額[8]
				// 貸方
				item.creditSubName = CommUtils.nullToBlank(lnLst[9]);	   // 貸方勘定科目[9]
				item.creditHojyoKamoku = CommUtils.nullToBlank(lnLst[10]); // 貸方補助科目[10]
				item.creditDepartment = CommUtils.nullToBlank(lnLst[11]);  // 貸方部門[11]
				item.creditTaxKbn = CommUtils.nullToBlank(lnLst[12]);	   // 貸方税区分[12]
				item.creditAmount = CommUtils.nullToZero(lnLst[13]).intValue();	   // 貸方金額[13]
				item.creditTaxAmount = CommUtils.nullToZero(lnLst[14]).intValue(); // 貸方税額[14]
				item.description = CommUtils.nullToBlank(lnLst[15]); // 摘要[15]
				// 数据分组处理「KEY: 伝票No, VAL: Ln」
				if(!pro.freeePageInfoMap.containsKey(item.startNo)){
					pro.startNoProLst.add(item.startNo);
					pro.freeePageInfoMap.put(item.startNo, new FreeePageInfo());
				}
				FreeePageInfo onePage = pro.freeePageInfoMap.get(item.startNo);
				// 日付 yyyyMMdd
				onePage.startDay = item.startDay;
				// 伝票No.
				onePage.startNo = item.startNo;
				onePage.lineInfoLst.add(item);
				// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'ITEM:='+ITEM);
			}
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'PRO.FREEEPAGEINFOMAP:='+PRO.FREEEPAGEINFOMAP);
		}
		// 事業所ID
		pro.companyId = getCompanyId();
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'pro.companyId:='+pro.companyId);
		// 删除已存在的数据
		for(String startNo : pro.startNoProLst){
			FreeePageInfo onePage = pro.freeePageInfoMap.get(startNo);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'pro.shopCode:='+pro.shopCode);
			// 为了实时更新数据源「店铺CODE确认」
			String sectionsId = checkSections(pro.shopCode, false);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'sectionsId:='+sectionsId);
			if(!CommUtils.isBlank(sectionsId)){
				// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'onePage.startDateFmt:='+onePage.startDateFmt);
				// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'onePage.startDateFmt:='+onePage.startDateFmt);
				String whereStr = '&start_issue_date=' + onePage.startDateFmt + '&end_issue_date=' + onePage.startDateFmt + '&section_id=' + sectionsId;
				//Object manualJournalsObj = checkManualJournals(whereStr);
				Map<String, Object> manualJournalsMap = getManualJournals(whereStr);
				// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'manualJournalsMap:='+manualJournalsMap);
				for(String manualJournalsId : manualJournalsMap.keySet()){
					if(!deleteManualJournals(manualJournalsId)){
						onePage.mailMsg.bodyMsg += '削除失敗(https://secure.freee.co.jp/manual_journals/' + manualJournalsId + ')\n';
						// ToDolog记录邮件不记录
						// bItem.log.delErrMsg = '会計科目: 貸方部門/借方部門、設置一貫性のない';
						// '削除失敗(https://secure.freee.co.jp/manual_journals/' + sectionsId + ')';
						continue;
					}
				}
			}
		}
		// 有效的伝票No
		return pro.startNoProLst;
	}
	// ***********************************
	// バッチロジック処理開始
	// ***********************************
	public void execute(Database.BatchableContext BC, List<String> startNoProLst){
		try{
			// 只会一次循环
			for(String startNo : startNoProLst){
				FreeePageInfo onePage = pro.freeePageInfoMap.get(startNo);
				// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'onePage:='+onePage);
				String detailsJson = getDetailsJson(onePage);
				// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'detailsJson:='+detailsJson);
				if(CommUtils.isBlank(detailsJson)){
					// onePage.mailMsg.bodyMsg = '無効なデータ設定\n';
					continue;
				}
				// 振替伝票
				Object manualJournalsObj = postManualJournals(detailsJson);
				if(manualJournalsObj != null){
					Map<String, Object> manualJournalsData = (Map<String, Object>)manualJournalsObj;
					onePage.postNgFlg = false;
					// onePage.mailMsg.bodyMsg = '振替伝票: POST成功(https://secure.freee.co.jp/manual_journals/'+ manualJournalsData.get('id') + ')';
					pro.okInt++;
				} else {
					// onePage.mailMsg.bodyMsg += '(https://login.salesforce.com/'+ pro.docmentId +')\n';
				}
			}
		} catch(Exception e){
			// onePage.mailMsg.bodyMsg = '無効なデータ設定\n';
		}
	}
	
	// ***********************************
	// バッチ終了処理開始
	// ***********************************
	public void finish(Database.BatchableContext BC){
		Map<String, List<ProDocumentInfo>> nextProDocInfoMap = new Map<String, List<ProDocumentInfo>>();
		// 有效店铺信息处理
		for(ProShopInfo proShop : proShopInfoLst){
			if(!proShop.isStartFlg) continue;
			if(!proDocInfoMap.containsKey(proShop.shopCode)) continue;
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'proShop.shopCode:='+proShop.shopCode+'(' + proShop.shopName +')');
			List<ProDocumentInfo> proDocInfoLst = proDocInfoMap.get(proShop.shopCode);
			// 相同店铺数据集计处理
			if(proShop.shopCode == pro.shopCode){
				proShop.okInt += pro.okInt;
				proShop.ngInt += pro.ngInt;
				proShop.proDocEndLst.add(pro.clone());
				if(!proDocInfoLst.isEmpty()) proDocInfoLst.remove(0);
			}
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'PRO-END:='+PRO);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'proShop:='+proShop);
			// 已无下次处理的数据跳出
			if(proDocInfoLst.isEmpty()){
				proShop.isStartFlg = false;
				sendMail(proShop.clone());
				continue;
			}
			// 下次信息有效处理
			nextProDocInfoMap.put(proShop.shopCode, proDocInfoLst.clone());
		}
		if(nextProDocInfoMap.isEmpty()) return;
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'proShopInfoLst:='+proShopInfoLst);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, 'nextProDocInfoMap:='+nextProDocInfoMap);
		FreeeSyncCsvPostBatch batch = new FreeeSyncCsvPostBatch(proShopInfoLst.clone(), nextProDocInfoMap);
		DataBase.executeBatch(batch,1);
	}
	/*
	* 指定した事業所の振替伝票の削除
	*/
	public Boolean deleteManualJournals(String deleteId){
		return deleteData(manual_journals, deleteId);
	}
	/*
	* 指定した事業所の振替伝票一覧を取得する
	* Map => Key: name, Val: 振替伝票
	*/
	public Map<String, Object> getManualJournals(){
		return getManualJournals('');
	}
	public Map<String, Object> getManualJournals(String whereStr){
		// 振替伝票MAP => Key: name, Val: 振替伝票
		Map<String, Object> manualJournalsMap = new Map<String, Object>();
		try{
			String path = manual_journals + '?company_id=' + pro.companyId + whereStr;
			for(Object s : getDataView(manual_journals, path)){
				Map<String, Object> obj = (Map<String, Object>)s;
				manualJournalsMap.put(CommUtils.nullToBlank(obj.get('id')), s);
			}
		} catch(Exception e){}
		return manualJournalsMap;
	}
	/*
	* 指定した事業所の振替伝票を作成する
	*/
	public Object postManualJournals(String detailsJson){
		// 事業所の数据Json
		String dataJson = getManualJournalsJson(detailsJson);
		return postData(manual_journals, dataJson);
	}
	/*
	* 振替伝票JSONの作成
	*/
	public String getManualJournalsJson(String detailsJson){
		// 振替伝票の作成
		String json = '{';
		json += '  "company_id": ' + pro.companyId + ',';
		json += '  "issue_date": "' + pro.startDateFmt + '",'; // 発生日 yyyy-MM-dd
		json += '  "adjustment": false,'; // 決算整理仕訳フラグ（true: 決算整理仕訳, false: 日常仕訳）
		json += '  "txn_number": null,'; // 仕訳番号
		json += '  "details": ['; // 振替伝票の貸借行
		json += detailsJson;
		json += '  ]';
		json += '}';
		return json;
	}
	/*
	* 貸借行JSONの作成
	*/
	public String getDetailsJson(FreeePageInfo onePage){
		String detailsJson = '';
		try{
			// Map => Key: name_ja, Val: 税区分コード
			Map<String, Object> taxesMap = getTaxes();
			for(FreeeLineInfo ln : onePage.lineInfoLst){
				
				Integer debitTaxKbn = checkTaxes(taxesMap, ln.debitTaxKbn);
				// if(debitTaxKbn == null) onePage.mailMsg.bodyMsg = '借方税区分: 設定が正しくありません。\n';
				String debitData = ''; // 借方: debit
				// 借方金額 > 0 && 借方勘定科目 != ''
				if(ln.debitAmount > 0  && !CommUtils.isBlank(ln.debitSubName) && debitTaxKbn != null){
					debitData += '	{';
					debitData += '	  "entry_side": "debit",'; // 貸借区分[貸借（貸方: credit, 借方: debit）] *必须
					debitData += '	  "tax_code": ' + checkTaxes(taxesMap, ln.debitTaxKbn) + ','; // 税区分コード *必须 => 借方税区分
					debitData += '	  "account_item_id": ' + checkAccountItems(ln.debitSubName) + ','; // 勘定科目ID 需要提前新规 *必须 => 借方勘定科目
					debitData += '	  "amount": ' + ln.debitAmount + ','; // 金額 取引金額（税込で指定してください）*必须 => 借方金額
					debitData += '	  "vat": ' + ln.debitTaxAmount + ','; // 消費税額（指定しない場合は自動で計算されます）
					if(!CommUtils.isBlank(ln.debitHojyoKamoku)){
						String debitHojyoKamoku = checkItems(ln.debitHojyoKamoku);
						if(!CommUtils.isBlank(debitHojyoKamoku)) debitData += '	  "item_id": ' + debitHojyoKamoku + ','; // 品目ID 需要提前新规 => 借方補助科目
					}
					if(!CommUtils.isBlank(ln.debitDepartment)){
						String debitDepartment = checkSections(ln.debitDepartment);
						if(!CommUtils.isBlank(debitDepartment)) debitData += '	  "section_id": ' + debitDepartment + ','; // 部門ID 需要提前新规 => 借方部門
					}
					debitData += '	  "tag_ids": ['; // メモタグID
					debitData += '		';
					debitData += '	  ],';
					debitData += '	  "description": "' + ln.description + '"';
					debitData += '	}';
				}
				String creditData = ''; // 貸方: credit
				Integer creditTaxKbn = checkTaxes(taxesMap, ln.creditTaxKbn);
				// if(creditTaxKbn == null) onePage.mailMsg.bodyMsg = '貸方税区分: 設定が正しくありません。\n';
				// 貸方金額 > 0 && 貸方勘定科目 != ''
				if(ln.creditAmount > 0 && !CommUtils.isBlank(ln.creditSubName) && creditTaxKbn != null){
					creditData += '	{';
					creditData += '	  "entry_side": "credit",'; // 貸借区分[貸借（貸方: credit, 借方: debit）] *必须
					// TODO
					creditData += '	  "tax_code": ' + checkTaxes(taxesMap, ln.creditTaxKbn) + ','; // 税区分コード *必须 => 貸方税区分
					creditData += '	  "account_item_id": ' + checkAccountItems(ln.creditSubName) + ','; // 勘定科目ID 需要提前新规 *必须 => 貸方勘定科目 *必须 
					creditData += '	  "amount": ' + ln.creditAmount + ','; // 金額 取引金額（税込で指定してください）
					creditData += '	  "vat": ' + ln.creditTaxAmount + ','; // 消費税額（指定しない場合は自動で計算されます）
					if(!CommUtils.isBlank(ln.creditHojyoKamoku)){
						String creditHojyoKamoku = checkItems(ln.creditHojyoKamoku);
						if(!CommUtils.isBlank(creditHojyoKamoku)) creditData += '	  "item_id": ' + creditHojyoKamoku + ','; // 品目ID 需要提前新规 => 貸方補助科目
					}
					if(!CommUtils.isBlank(ln.creditDepartment)){
						String creditDepartment = checkSections(ln.creditDepartment);
						if(!CommUtils.isBlank(creditDepartment)) creditData += '	  "section_id": ' + creditDepartment + ','; // 部門ID 需要提前新规 => 貸方部門
					}
					creditData += '	  "tag_ids": ['; // メモタグID
					creditData += '		';
					creditData += '	  ],';
					creditData += '	  "description": "' + ln.description + '"';
					creditData += '	}';
				}
				if(!CommUtils.isBlank(debitData)) detailsJson += debitData + ',';
				if(!CommUtils.isBlank(creditData)) detailsJson += creditData + ',';
			}
		} catch(Exception e){}
		return detailsJson.removeEnd(',');
	}
	/*
	* 勘定科目存在场合check
	*/
	public String checkAccountItems(String name){
		try{
			name = unEscReplace(name);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'name:='+name);
			Object obj;
			// 为了实时更新数据源
			Map<String, Object> accountItemsMap = getAccountItems();
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'accountItemsMap:='+accountItemsMap);
			// 存在の場所
			if(accountItemsMap.containsKey(name)) obj = accountItemsMap.get(name);
			Map<String, Object> objMap = (Map<String, Object>)obj;
			return CommUtils.nullToBlank(objMap.get('id'));
		} catch(Exception e){
			return '';
		}
	}
	/*
	* 指定した事業所の勘定科目一覧を取得する
	* Map => Key: name, Val: 勘定科目「默认」
	*/
	public Map<String, Object> getAccountItems(){
		return getAccountItems('name');
	}
	public Map<String, Object> getAccountItems(String key){
		String path = account_items + '?company_id=' + pro.companyId;
		// 勘定科目MAP => Key: name, Val: 勘定科目
		Map<String, Object> accountItemsMap = new Map<String, Object>();
		for(Object s : getDataView(account_items, path)){
			Map<String, Object> obj = (Map<String, Object>)s;
			accountItemsMap.put(CommUtils.nullToBlank(obj.get(key)), s);
		}
		return accountItemsMap;
	}
	/*
	* 指定した事業所の勘定科目を作成する
	*
	public Object postAccountItems(String name){
		String dataJson = getAccountItemsJson(name);
		return postData(account_items, dataJson);
	}
	*/
	/*
	* 勘定科目JSONの作成
	*
	public String getAccountItemsJson(String name){
		String json = '';
		json += '{';
		json += '  "company_id": ' + pro.companyId + ','; // 事業所ID *必须
		json += '  "account_item": {';
		json += '	"name": "' + (name.length() >= 30 ? name.substring(0, 30) : name) + '",'; // 勘定科目名 (30文字以内) *必须
		// json += '	"shortcut": "NEWACCOUNTITEM",'; // ショートカット1 (20文字以内)
		// json += '	"shortcut_num": "999",'; // ショートカット2(勘定科目コード)(20文字以内)
		// TODO
		json += '	"tax_name": "課税売上",'; // 税区分 *必须
		json += '	"group_name": "その他預金",'; // 決算書表示名 *必须
		json += '	"account_category": "現金・預金",'; // 勘定科目カテゴリー *必须
		json += '	"corresponding_income_name": "売掛金",'; // 収入取引相手勘定科目 *必须
		json += '	"corresponding_expense_name": "買掛金"'; // 支出取引相手勘定科目 *必须
		**
		json += '	"accumulated_dep_account_item_name": "減価償却累計額勘定科目",'; // 減価償却累計額勘定科目
		json += '	"searchable": 2,'; // 検索可能:2, 検索不可：3
		json += '	"items": ['; // 品目
		json += '	  {';
		json += '		"id": 1';
		json += '	  },';
		json += '	  {';
		json += '		"id": 3';
		json += '	  }';
		json += '	],';
		json += '	"partners": ['; // 取引先
		json += '	  {';
		json += '		"id": 21';
		json += '	  },';
		json += '	  {';
		json += '		"id": 43';
		json += '	  }';
		json += '	]';
		**
		json += '  }';
		json += '}';
		return json;
	}
	*/
	/*
	* 品目存在场合check
	*/
	public String checkItems(String name){
		try{
			Object obj;
			name = unEscReplace(name);
			// 为了实时更新数据源
			Map<String, Object> itemsMap = getItems();
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, items + '=>name:='+name);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, items + '=>itemsMap:='+itemsMap);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO, items + '=>itemsMap.containsKey(name):='+itemsMap.containsKey(name));
			if(itemsMap.containsKey(name)) obj = itemsMap.get(name);
			else obj = postItems(name);
			Map<String, Object> objMap = (Map<String, Object>)obj;
			return CommUtils.nullToBlank(objMap.get('id'));
		} catch(Exception e){
			return '';
		}
	}
	/*
	* 指定した事業所の品目一覧を取得する
	* Map => Key: name, Val: 品目 「默认」
	*/
	public Map<String, Object> getItems(){
		return getItems('name');
	}
	public Map<String, Object> getItems(String key){
		// 品目MAP => Key: name, Val: 品目
		Map<String, Object> itemsMap = new Map<String, Object>();
		try{
			String path = items + '?company_id=' + pro.companyId;
			for(Object s : getDataView(items, path)){
				Map<String, Object> obj = (Map<String, Object>)s;
				itemsMap.put(CommUtils.nullToBlank(obj.get(key)), s);
			}
		} catch(Exception e){}
		return itemsMap;
	}
	/*
	* 指定した事業所の品目を作成する
	*/
	public Object postItems(String name){
		String dataJson = getItemsJson(name);
		return postData(items, dataJson);
	}
	/*
	* 品目JSONの作成
	*/
	public String getItemsJson(String name){
		return getItemsJson(name, '', '');
	}
	public String getItemsJson(String name, String shortcut1, String shortcut2){
		String json = '';
		json += '{';
		json += '  "company_id": ' + pro.companyId + ','; // 事業所ID *必须
		json += '  "name": "' + (name.length() >= 30 ? name.substring(0, 30) : name) + '",'; // 品目名 (30文字以内) *必须
		json += '  "shortcut1": "' + shortcut1 + '",'; // ショートカット１ (20文字以内)
		json += '  "shortcut2": "' + shortcut2 + '"';  // ショートカット２ (20文字以内)
		json += '}';
		return json;
	}
	/*
	* 部門存在场合check
	*/
	public String checkSections(String name){
		return checkSections(name, true);
	}
	public String checkSections(String name, Boolean isPost){
		try{
			Object obj;
			name = unEscReplace(name);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'name:='+name);
			// 为了实时更新数据源
			Map<String, Object> sectionsMap = getSections();
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'sectionsMap:='+sectionsMap);
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'sectionsMap.containsKey(name):='+sectionsMap.containsKey(name));
			if(sectionsMap.containsKey(name))obj = sectionsMap.get(name);
			else if(isPost) obj = postSections(name);
			if(!isPost && obj == null) return '';
			Map<String, Object> objMap = (Map<String, Object>)obj;
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'objMap:='+objMap);
			return CommUtils.nullToBlank(objMap.get('id'));
		} catch(Exception e){
			return '';
		}
	}
	/*
	* 指定した事業所の部門一覧を取得する
	* Map => Key: name, Val: 部門
	*/
	public Map<String, Object> getSections(){
		String path = sections + '?company_id=' + pro.companyId;
		// 部門MAP => Key: name, Val: 部門
		Map<String, Object> sectionsMap = new Map<String, Object>();
		for(Object s : getDataView(sections, path)){
			Map<String, Object> obj = (Map<String, Object>)s;
			sectionsMap.put(CommUtils.nullToBlank(obj.get('name')), s);
		}
		return sectionsMap;
	}
	/*
	* 指定した事業所の部門を作成する
	*/
	public Object postSections(String name){
		String dataJson = getItemsJson(name);
		return postData(sections, dataJson);
	}
	/*
	* 部門JSONの作成
	*/
	public String getSectionsJson(String name){
		return getSectionsJson(name, '', '', '');
	}
	public String getSectionsJson(String name, String shortcut1, String shortcut2, String parentId){
		String json = '';
		json += '{';
		json += '  "company_id": ' + pro.companyId + ','; // 事業所ID *必须
		json += '  "name": "' + (name.length() >= 30 ? name.substring(0, 30) : name) + '",'; // 部門名 (30文字以内) *必须
		json += '  "shortcut1": "' + shortcut1 + '",'; // ショートカット１ (20文字以内)
		json += '  "shortcut2": "' + shortcut2 + '"'; // ショートカット２ (20文字以内)
		json += '  "parent_id": "' + parentId + '"'; // 親部門ID (ビジネスプラン以上)
		json += '}';
		return json;
	}
	/*
	* 税区分コードcheck
	*/
	public Integer checkTaxes(Map<String, Object> taxesMap, String name){
		Integer taxCode = null;
		name = unEscReplace(name);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'taxesMap:='+taxesMap);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'name:='+name);
		if(taxesMap.containsKey(name)){
			Object obj = taxesMap.get(name);
			Map<String, Object> objMap = (Map<String, Object>)obj;
			taxCode = CommUtils.nullToIntZero(objMap.get('code'));
		}
		return taxCode;
	}
	/**
	* 税区分コード一覧を取得する
	* Map => Key: name_ja, Val: 税区分コード 「默认」
	*/
	public Map<String, Object> getTaxes(){
		return getTaxes('name_ja');
	}
	public Map<String, Object> getTaxes(String key){
		// 税区分コードMAP => Key: name_ja, Val: 税区分コード
		Map<String, Object> taxesMap = new Map<String, Object>();
		try{
			String path = taxes + '/' + companies + '/' + pro.companyId;
			for(Object s : getDataView(taxes, path)){
				Map<String, Object> obj = (Map<String, Object>)s;
				taxesMap.put(CommUtils.nullToBlank(obj.get(key)), s);
			}
		} catch(Exception e){}
		return taxesMap;
	}
	/*
	* 事業所のId
	*/
	public Integer getCompanyId(){
		try{
			Map<String, Object> companiesMap = getCompanies();
			if(companiesMap.containsKey(disName)){
				Map<String, Object> obj = (Map<String, Object>)companiesMap.get(disName);
				return (Integer)obj.get('id');
			}
		} catch(Exception e){}
		return null;
	}
	/*
	* ユーザが所属する事業所の一覧を取得する
	* Map => Key: display_name, Val: 事業所
	*/
	public Map<String, Object> getCompanies(){
		// 税区分コードMAP => Key: display_name, Val: 事業所
		Map<String, Object> companiesMap = new Map<String, Object>();
		try{
			String path = companies;
			for(Object s : getDataView(companies, path)){
				Map<String, Object> obj = (Map<String, Object>)s;
				companiesMap.put(CommUtils.nullToBlank(obj.get('display_name')), s);
			}
		} catch(Exception e){}
		return companiesMap;
	}
	/*
	* DATA一覧を取得する
	*/
	public List<Object> getDataView(String api, String path){
		List<Object> lstBody = new List<Object>();
		try{
			// 一覧を取得する
			Http http = new Http();
			path = 'callout:' + callBack +'/' + path;
			HttpRequest req = new HttpRequest();
			req.setEndpoint(path);
			req.setMethod('GET');
			// req.setTimeout(COMMONCALL_TIME_OUT_VALUE);
			HttpResponse res = http.send(req);
			Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			// 設定する
			if(res.getStatusCode() == 200){
				// DATA一覧Lst
				lstBody = (List<Object>)resMap.get(api);
			}
			// エラーで返ってきたら例外をスローする
			else{
				for(String typ : resMap.keySet()){
					if(typ == 'errors'){
						String messages = apiLabelMap.get(api) + ': ';
						for(Object msg : (List<Object>)resMap.get(typ)){
							Map<String, Object> msgMap = (Map<String, Object>)msg;
							messages += CommUtils.nullToBlank(msgMap.get('messages')).replace('(', '').replace(')', ' ');
						}
						// onePage.mailMsg.bodyMsg += messages;
						// onePage.mailMsg.bodyMsg += '(https://login.salesforce.com/'+ pro.docmentId +')\n';
					}
				}
			}
		} catch(Exception e){
			// onePage.mailMsg.bodyMsg += apiLabelMap.get(api) + ': 接続異常 \n';
		}
		return lstBody;
	}
	/*
	* 指定した事業所のDATAを作成する
	*/
	public Object postData(String api, String dataJson){
		try{
			Http http = new Http();
			String path = 'callout:' + callBack +'/' + api;
			HttpRequest req = new HttpRequest();
			req.setEndpoint(path);
			req.setMethod('POST');
			req.setBody(dataJson);
			// req.setTimeout(COMMONCALL_TIME_OUT_VALUE);
			req.setHeader('Content-Type', 'application/json');
			HttpResponse res = http.send(req);
			// SYSTEM.DEBUG(logginglevel.info,'path:='+path);
			// SYSTEM.DEBUG(logginglevel.info,'dataJson:='+dataJson);
			// SYSTEM.DEBUG(logginglevel.info,'res.getBody():='+res.getBody());
			Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			if(res.getStatusCode() == 201) {
				return resMap.values()[0];
			} else {
				for(String typ : resMap.keySet()){
					if(typ == 'errors'){
						String messages = apiLabelMap.get(api) + ': ';
						for(Object msg : (List<Object>)resMap.get(typ)){
							Map<String, Object> msgMap = (Map<String, Object>)msg;
							messages += CommUtils.nullToBlank(msgMap.get('messages')).replace('(', '').replace(')', ' ');
						}
						// onePage.mailMsg.bodyMsg += messages;
						// onePage.mailMsg.bodyMsg += '(https://login.salesforce.com/'+ pro.docmentId +')\n';
					}
				}
			}
		} catch(Exception e){
			// onePage.mailMsg.bodyMsg += apiLabelMap.get(api) + ': 接続異常 \n';
		}
		return null;
	}
	/*
	* 指定した事業所のDATAを削除する
	*/
	public Boolean deleteData(String api, String deleteId){
		try{
			// 一覧を取得する
			Http http = new Http();
			String path = 'callout:' + callBack +'/' + api + '/' + deleteId + '?company_id=' + pro.companyId;
			HttpRequest req = new HttpRequest();
			req.setEndpoint(path);
			req.setMethod('DELETE');
			// req.setTimeout(COMMONCALL_TIME_OUT_VALUE);
			HttpResponse res = http.send(req);
			String resBody = res.getBody();
			if(CommUtils.isBlank(resBody)) return true;
		} catch(Exception e){
			// ToDolog
			// bItem.log.bodyMsg += apiLabelMap.get(api) + ': 接続異常 \n';
		}
		return false;
	}
	// 处理店铺信息
	public class ProShopInfo{
		public ProShopInfo(){
			okInt = ngInt = 0;
			isStartFlg = true;
			proDocEndLst = new List<ProDocumentInfo>();
		}
		public String shopCode; // 店铺Code
		public String shopName; // 店铺Name
		public Boolean isStartFlg; // 有下次处理Flg
		public String startDate; // 日付 yyyyMMdd
		public String endDate; // 结束日付 yyyyMMdd
		public Integer okInt; // 成功件数
		public Integer ngInt; // 失败件数
		public List<ProDocumentInfo> proDocEndLst;
	}
	public class ProDocumentInfo{
		public ProDocumentInfo(){
			startDate = shopCode = shopName = docmentId = '';
			
			okInt = ngInt = 0;
			mailMsg = new EmailMessage();
			startNoProLst = new List<String>();
			// startNoErrLst = new List<String>();
			
			csvAccIdMap = new Map<String, String>();
			freeePageInfoMap = new Map<String, FreeePageInfo>();
		}
		public String startDate; // 日付 yyyyMMdd
		public String startDateFmt{ get{
			return  ( startDate.subString(0,4) + '-' +
					  startDate.subString(4,6) + '-' +
					  startDate.subString(6,8));
		}} // 発生日
		public String shopCode;  // 店铺Code
		public String shopName;  // 店铺Name
		public String docmentId; // 当前数据文件Id
		
		public Integer okInt; // 成功件数
		public Integer ngInt{get{ return (freeePageInfoMap.keySet().size() - okInt);}  set;} // 失败件数
		public Integer companyId; // 事業所ID
		public EmailMessage mailMsg;	   // 邮件模版信息
		public List<String> startNoProLst; // 伝票No.处理集合
		// public List<String> startNoErrLst; // 伝票No.异常集合
		public Map<String, String> csvAccIdMap;
		public Map<String, FreeePageInfo> freeePageInfoMap; // 行数据Map
	}
	// POSTPage数据信息
	public class FreeePageInfo{
		public FreeePageInfo(){
			postNgFlg = true;
			mailMsg = new EmailMessage();
			lineInfoLst = new List<FreeeLineInfo>();
		}
		public String startDay; // 日付[1]
		public String startNo;  // 伝票No.[2]
		public String shopCode; // 店铺Code
		public String key{ get{ return (startDay + '_' + shopCode + '_' + startNo);}} // 日付_店铺Code_云票No
		public String shopName; // 店铺Name
		public String startDateFmt{ get{
			return  ( startDay.subString(0,4) + '-' +
					  startDay.subString(4,6) + '-' +
					  startDay.subString(6,8));
		}} // 発生日
		public Boolean postNgFlg; // 店铺Name
		public EmailMessage mailMsg; // 邮件信息
		public List<FreeeLineInfo> lineInfoLst;
	}
	// PostJson
	public static String escReplace(String str){
		return CommUtils.nullToBlank(str).replace('"','\\"');
	}
	public static String unEscReplace(String str){
		return CommUtils.nullToBlank(str).replace('\\"','"');
	}
	// 行数据
	public class FreeeLineInfo{
		public FreeeLineInfo(){}
		public String startDay; // 日付[1]
		public String startNo;  // 伝票No.[2]
		// 借方
		public String debitSubName{get{ return escReplace(debitSubName);} set;}			// 借方勘定科目[3]
		public String debitHojyoKamoku{get{ return escReplace(debitHojyoKamoku);} set;} // 借方補助科目[4]
		public String debitDepartment{get{ return escReplace(debitDepartment);} set;}   // 借方部門[5]
		public String debitTaxKbn;		// 借方税区分[6]
		public Integer debitAmount;		// 借方金額[7]
		public Integer debitTaxAmount;  // 借方税額[8]
		// 貸方
		public String creditSubName{get{ return escReplace(creditSubName);} set;}		 // 貸方勘定科目[9]
		public String creditHojyoKamoku{get{ return escReplace(creditHojyoKamoku);} set;} // 貸方補助科目[10]
		public String creditDepartment{get{ return escReplace(creditDepartment);} set;}   // 貸方部門[11]
		public String creditTaxKbn;	 // 貸方税区分[12]
		public Integer creditAmount;	// 貸方金額[13]
		public Integer creditTaxAmount; // 貸方税額[14]
		public String description{get{ return escReplace(description);} set;} // 摘要[15]
	}
	// 邮件模版信息
	public class EmailMessage{
		public EmailMessage(){
			// startDay = startNo = proDayMsg = comErrMsg = infErrMsg = chkErrMsg = 
			bodyMsg = '';
		}
		/*
		// 日付yyyyMMdd
		public String startDay;
		// 伝票No.
		public String startNo;
		// 处理日
		public String proDayMsg;
		// 共通设定异常Msg
		public String comErrMsg;
		// 处理数据异常Msg
		public String infErrMsg;
		// 部门设定异常Msg
		public String chkErrMsg;
		*/
		// Post处理Msg
		public String bodyMsg;
	}
	// 処理結果の送信処理
	public void sendMail(ProShopInfo proShop) {
		// SYSTEM.DEBUG(logginglevel.info,'proShop:='+ proShop);
		// SYSTEM.DEBUG(logginglevel.info,'proShop.proDocEndLst:='+ proShop.proDocEndLst);
		String mailAdds = CommDefine__c.getOrgDefaults().ScheduleResultMailAddress__c;
		if(CommUtils.isBlank(mailAdds)) return;
		String mailBodyStr = 'FREEE連携のCSV出力が以下の通リ終了しましたのでお知らせいたします。';
		// 共通设定异常场合
		if(CommUtils.isBlank(disName) || CommUtils.isBlank(callBack)) mailBodyStr += '\n\nFreee連携設定: 事業所名(屋号) または 認証プロバイダをURL接尾辞設定が正しくありません。';
		// 共通设定正常场合
		else{
			// mailBodyStr += '\n店舗: ' + pro.shopName;
			mailBodyStr += '\n売上計上日: ' + proShop.startDate + ' ～ ' + proShop.endDate;
			if(!CommUtils.isBlank(proShop.shopName)) mailBodyStr += '\n店舗: ' + proShop.shopName;
			mailBodyStr += '\n事業所名(屋号): ' + disName;
			mailBodyStr += '\n処理成功件数:' + proShop.okInt + '件';
			mailBodyStr += '\n処理失敗件数:' + proShop.ngInt + '件';
			
			for(ProDocumentInfo gPro : proShop.proDocEndLst){
				// 2020/01/15 BUGFIX WGCH BEGIN
				// mailBodyStr += '\n\n売上計上日: ' + gPro.startDate + ' 仕訳明細ファイル (https://login.salesforce.com/apex/'+ CommConst.APPOTION_NAMESPACE +'PcaSyncCsvDownload?rid=' + pro.docmentId + ')';
				mailBodyStr += '\n\n売上計上日: ' + gPro.startDate + ' 仕訳明細ファイル (https://login.salesforce.com/apex/'+ CommConst.APPOTION_NAMESPACE +'PcaSyncCsvDownload?rid=' + gPro.docmentId + ')';
				// 2020/01/15 BUGFIX WGCH END
				mailBodyStr += '\n処理成功件数:' + gPro.okInt + '件';
				mailBodyStr += '\n処理失敗件数:' + gPro.ngInt + '件';
				
				for(String startNo : gPro.startNoProLst){
					FreeePageInfo onePage = gPro.freeePageInfoMap.get(startNo);
					if(onePage.postNgFlg){
						mailBodyStr += '\n\n' + onePage.startDay + '  ' + Label.CONST_046_0031 +'【'+onePage.startNo+'】';
						mailBodyStr += '\n不正なリクエストです。 (設定不正例: 会計科目名がFREEEに非存在、借方税区分、貸方税区分がFREEEに非存在、貸借金額が不一致)';
					}
				}
			}
		}
		mailBodyStr += '\n\nJinyaConnect Enterprise system R&D team.';
		List<String> chatterGroupNamesLst = CommConst.GetChatterGroupNameByCode(CommConst.Pcas_ChatterGroupNameType);
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'chatterGroupNamesLst:='+chatterGroupNamesLst);
		List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
		// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'chatterGroups:='+chatterGroups);
		if (!chatterGroups.isEmpty()){
			List<FeedItem> feedItems = new List<FeedItem>();
			for (CollaborationGroup cGroup : chatterGroups) {
				FeedItem post = new FeedItem();
				post.Type = 'TextPost';
				post.Body = mailBodyStr;
				post.ParentId = cGroup.Id;
				feedItems.add(post);
			}
			// SYSTEM.DEBUG(LOGGINGLEVEL.INFO,'feedItems:='+feedItems);
			if (!feedItems.isEmpty()) insert feedItems;
		}
		// SYSTEM.DEBUG(logginglevel.info,'mailBodyStr:='+mailBodyStr);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = mailAdds.split(',');
		mail.setToAddresses(toAddresses);
		//Freee連携のバッチ処理結果の通知
		mail.setSubject('['+UserInfo.getOrganizationName()+'] '+ Label.MSG_046_0016);
		mail.setPlainTextBody(mailBodyStr);
		// テストクラスの場合、実施しない
		if(!Test.isRunningTest()) {
			try {
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			} catch(Exception e){}
		}
	}
}