public with sharing class ExpoAreaMstSettingCtrl {
	public static final String CUST_SYMBOL{get{ return '_';} set;}
	public static final String CUST_ERROR_MSG{get{ return '指定している会計商品情報は削除されました';} set;}
	public Boolean isNoExpoFlg{get; set;}
	public String accMstId{get; set;}
	public PageInfo pageItem{get; set;} // 页面变量
	/*************************
    * 初期化処理
    **************************/
    public ExpoAreaMstSettingCtrl(ApexPages.StandardController controller){
    	accMstId = controller.getId();
    }
	public void init(){
		pageItem = new PageInfo();
		Map<String, String> paramMap = Apexpages.currentPage().getParameters();
		isNoExpoFlg = paramMap.containsKey('expo');
		List<AccountMaster__c> extAccs = [select Id, ExpoAreaMstLab__c, ExpoAreaMstCode__c from AccountMaster__c where id =: accMstId];
		if (!isNoExpoFlg && extAccs.isEmpty()) throw New CommException(CUST_ERROR_MSG);
		Set<String> areaCdSet = new Set<String>();
		Set<String> selectStateCdSet = new Set<String>();
		Set<String> selectCityCdSet = new Set<String>();
		Map<String, String> cityCdToStateCdMap = getExpoAreaMstCodeAllMap(false);
		for(AccountMaster__c accMst : extAccs){
			if(!CommUtils.isBlank(accMst.ExpoAreaMstCode__c)){
				for(String areaMstCode : CommUtils.nullToBlank(accMst.ExpoAreaMstCode__c).split(';')){
					String[] areaCdSplit = CommUtils.nullToBlank(areaMstCode).split('_');
					if(areaCdSplit.isEmpty()) continue;
					if(areaCdSplit.size() == 2){
						areaCdSet.add(areaCdSplit[0]);
						selectStateCdSet.add(areaCdSplit[1]);
					} else if(areaCdSplit.size() == 3) {
						areaCdSet.add(areaCdSplit[0]);
						String cityCode = areaCdSplit[2];
						// すべて-コード转换
						if(cityCdToStateCdMap.containsKey(cityCode)){
							selectStateCdSet.add(cityCdToStateCdMap.get(cityCode));
						} else selectCityCdSet.add(cityCode);
					}
				}
			}
		}
		if(!areaCdSet.isEmpty()){
			String queryStr = ' Select Id, Name, AreaLst__c,tolabel(AreaLst__c) areaLab, StateLst__c, tolabel(StateLst__c) stateLab, CityAll__c, CityCode__c, City__c From ExpoAreaMst__c ';
			queryStr += ' Where AreaLst__c in: areaCdSet ';
			queryStr += ' Order by AreaLst__c, StateLst__c, CityAll__c, CityCode__c ';
			List<ExpoAreaMst__c> expoAreaMstLst = Database.query(queryStr);
			for(ExpoAreaMst__c sobj : expoAreaMstLst){
				String areaCd = CommUtils.nullToBlank(sobj.AreaLst__c);
				String stateCd = CommUtils.nullToBlank(sobj.StateLst__c);
				String cityAll = CommUtils.nullToBlank(sobj.CityAll__c);
				String cityCd = CommUtils.nullToBlank(sobj.CityCode__c);
				// 设置默认选中值
				if(CommUtils.isBlank(pageItem.selectAreaCd)) pageItem.selectAreaCd = areaCd;
				// 地域
				if(pageItem.selectStateCdMap.isEmpty()){
					pageItem.selectStateCdMap.put(areaCd, stateCd);
				}
				if(selectStateCdSet.contains(stateCd) || selectCityCdSet.contains(cityCd)){
					String selectCityCdKey = getSelectCityCdKey(areaCd, stateCd);
					if(!pageItem.selectCityCdMap.containsKey(selectCityCdKey)) pageItem.selectCityCdMap.put(selectCityCdKey, new Set<String>());
					pageItem.selectCityCdMap.get(selectCityCdKey).add(cityCd) ;
				}
			}
		}
		pageItem.selectStateCdJson = JSON.serialize(pageItem.selectStateCdMap);
		pageItem.selectCityCdJson = JSON.serialize(pageItem.selectCityCdMap);
		setDataInfo(pageItem, true);
	}
	public void queryExpoAreaMstData(){
		try {
			pageItem.selectStateCdMap = (Map<String, String>)JSON.deserializeStrict(pageItem.selectStateCdJson, Map<String, String>.class);
			pageItem.selectCityCdMap = (Map<String, Set<String>>)JSON.deserializeStrict(pageItem.selectCityCdJson, Map<String, Set<String>>.class);
		} catch (Exception e) {}
		// 地域数据处理
		setDataInfo(pageItem, false);
	}
	// 地域数据处理
	public static void setDataInfo(PageInfo wkPageItem, Boolean isAllModeFlg){
		String queryStr = ' Select Id, Name, AreaLst__c,tolabel(AreaLst__c) areaLab, StateLst__c, tolabel(StateLst__c) stateLab, CityAll__c, CityCode__c, City__c From ExpoAreaMst__c Where City__c != null ';
		String selectAreaCd = wkPageItem.selectAreaCd;
		if(!isAllModeFlg && !CommUtils.isBlank(selectAreaCd)) queryStr += ' And AreaLst__c =: selectAreaCd ';
		queryStr += ' Order by AreaLst__c, StateLst__c, CityAll__c, CityCode__c ';
		List<ExpoAreaMst__c> expoAreaMstLst = Database.query(queryStr);
		for(ExpoAreaMst__c sobj : expoAreaMstLst){
			String areaCd = CommUtils.nullToBlank(sobj.AreaLst__c);
			String stateCd = CommUtils.nullToBlank(sobj.StateLst__c);
			String cityAll = CommUtils.nullToBlank(sobj.CityAll__c);
			String cityCd = CommUtils.nullToBlank(sobj.CityCode__c);
			String city = CommUtils.nullToBlank(sobj.City__c);
			if(CommUtils.isBlank(cityCd) || CommUtils.isBlank(city)) continue;
			// 设置默认选中值-関東
			if(CommUtils.isBlank(wkPageItem.selectAreaCd)) wkPageItem.selectAreaCd = 'C';
			// 地域
			if(!wkPageItem.areaInfoMap.containsKey(areaCd)){
				wkPageItem.areaCdLst.add(areaCd);
				wkPageItem.areaInfoMap.put(areaCd, new AreaInfo(sobj));
				wkPageItem.selectStateCdMap.put(areaCd, CommUtils.nullToBlank(sobj.StateLst__c));
			}
			AreaInfo areaItem = wkPageItem.areaInfoMap.get(areaCd);
			// 选中设定
			areaItem.checkFlg = wkPageItem.selectAreaCd == areaItem.areaCd;
			// 都道府県
			if(!areaItem.stateCdLst.contains(stateCd)){
				areaItem.stateCdLst.add(stateCd);
				areaItem.stateInfoMap.put(stateCd, new StateInfo(sobj));
			}
			StateInfo stateItem = areaItem.stateInfoMap.get(stateCd);
			// 选中设定
			if(wkPageItem.selectStateCdMap.containsKey(areaItem.areaCd)){
				String selectStateCd = wkPageItem.selectStateCdMap.get(areaItem.areaCd);
				if(selectStateCd == stateItem.stateCd) stateItem.checkFlg = true;
				else stateItem.checkFlg = false;
			}
			// 市区郡
			if(!CommUtils.isBlank(cityAll)){
				if(!stateItem.cityAllLst.contains(cityAll)){
					stateItem.cityAllLst.add(cityAll);
					stateItem.cityCdAllMap.put(cityAll, new List<String>());
				}
				List<String> cityAllLst = stateItem.cityCdAllMap.get(cityAll);
				if(!cityAllLst.contains(cityCd)) cityAllLst.add(cityCd);
			} else {
				if(!stateItem.cityCdLst.contains(cityCd)){
					stateItem.cityCdLst.add(cityCd);
				}
			}
			// 2019/04/30 修正 WGCH BGEGIN
			stateItem.cityCdAllLst.add(cityCd);
			// 2019/04/30 修正 WGCH END
			if(!stateItem.cityInfoMap.containsKey(cityCd)) stateItem.cityInfoMap.put(cityCd, new CityInfo(sobj));
			CityInfo cityItem = stateItem.cityInfoMap.get(cityCd);
			String selectCityCdKey = getSelectCityCdKey(areaItem.areaCd, stateItem.stateCd);
			if(wkPageItem.selectCityCdMap.containsKey(selectCityCdKey)){
				Set<String> selectCityCdSet = wkPageItem.selectCityCdMap.get(selectCityCdKey);
				if(selectCityCdSet.contains(cityItem.cityCd)) cityItem.checkFlg = true;
				else cityItem.checkFlg = false;
			}
		}
		// 选中数据转成json
		wkPageItem.selectStateCdJson = JSON.serialize(wkPageItem.selectStateCdMap);
		wkPageItem.selectCityCdJson = JSON.serialize(wkPageItem.selectCityCdMap);
	}
	// 页面数据集
	public class PageInfo{
		public PageInfo(){
			areaCdLst = new List<String>(); // 地域-存在的-コード-LIST
			areaInfoMap = new Map<String, AreaInfo>(); // 市区郡-存在的-MAP
			selectStateCdMap = new Map<String, String>(); // 都道府県-选中-MAP
			selectCityCdMap = new Map<String, Set<String>>(); // 市区郡-选中-MAP
			selectStateCdJson = JSON.serialize(selectStateCdMap); // 都道府県-选中-JSON
			selectCityCdJson = JSON.serialize(selectCityCdMap);  // 市区郡-选中-JSON
		}
		public String selectAreaCd{get; set;} // 地域-选中-コード
		public String selectStateCdJson{get; set;} // 都道府県-选中-JSON
		public String selectCityCdJson{get; set;} // 市区郡-选中-JSON
		public List<String> areaCdLst{get; set;} // 存在的地域-コード
		public Map<String, AreaInfo> areaInfoMap{get; set;} // 存在的市区郡
		public Map<String, String> selectStateCdMap; // 都道府県-选中-MAP
		public Map<String, Set<String>> selectCityCdMap; // 市区郡-选中-MAP
	}
	public class AreaInfo{
		public AreaInfo(ExpoAreaMst__c s){
			areaCd = CommUtils.nullToBlank(s.AreaLst__c);
			areaLab = CommUtils.nullToBlank(s.get('areaLab'));
			checkFlg = false;
			stateCdLst = new List<String>();
			stateInfoMap = new Map<String, StateInfo>();
		}
		public String areaCd{get; set;}
		public String areaLab{get; set;}
		public Boolean checkFlg{get; set;}
		public List<String> stateCdLst{get; set;}
		public Map<String, StateInfo> stateInfoMap{get; set;}
	}
	public class StateInfo{
		public StateInfo(ExpoAreaMst__c s){
			areaCd = CommUtils.nullToBlank(s.AreaLst__c);
			stateCd = CommUtils.nullToBlank(s.StateLst__c);
			stateLab = CommUtils.nullToBlank(s.get('stateLab'));
			checkFlg = false;
			cityCdLst = new List<String>();
			cityAllLst = new List<String>();
			// 2019/04/30 修正 WGCH BGEGIN
			cityCdAllLst = new List<String>();
			// 2019/04/30 修正 WGCH END
			cityCdAllMap = new Map<String, List<String>>();
			cityInfoMap = new Map<String, CityInfo>();
		}
		public String areaCd{get; set;}
		public String stateCd{get; set;}
		public String stateLab{get; set;}
		public Boolean checkFlg{get; set;}
		public List<String> cityCdLst{get; set;}
		public List<String> cityAllLst{get; set;}
		// 2019/04/30 修正 WGCH BGEGIN
		public List<String> cityCdAllLst{get; set;}
		// 2019/04/30 修正 WGCH END
		public Map<String, List<String>> cityCdAllMap{get; set;}
		public Map<String, CityInfo> cityInfoMap{get; set;}
	}
	public class CityInfo{
		public CityInfo(ExpoAreaMst__c s){
			cityId = CommUtils.nullToBlank(s.Id);
			areaCd = CommUtils.nullToBlank(s.AreaLst__c);
			stateCd = CommUtils.nullToBlank(s.StateLst__c);
			cityCd = CommUtils.nullToBlank(s.CityCode__c);
			cityLab = CommUtils.nullToBlank(s.City__c);
			checkFlg = false;
		}
		public String cityId{get; set;}
		public String areaCd{get; set;}
		public String stateCd{get; set;}
		public String cityCd{get; set;}
		public String cityLab{get; set;}
		public Boolean checkFlg{get; set;}
		public List<CityInfo> cityInfoLst{get; set;}
		public List<AreaInfo> areaInfoLst{get; set;}
	}
	public class RemoteActionInfo{
		public RemoteActionInfo(){
			accMstId = errorMessage = expoAreaMstLab = expoAreaMstCode = '';
			isNoExpoFlg = false;
			selectCityCdMap = new Map<String, Set<String>>();
		}
		
		public String accMstId;
		public String errorMessage;
		public String expoAreaMstLab;
		public String expoAreaMstCode;
		public Boolean isNoExpoFlg;
		public Map<String, Set<String>> selectCityCdMap;
	}
	@remoteAction
	public static RemoteActionInfo updateAreaToAccMst(String wkSelectCityCdJson, String accMstId, String isNoExpoFlg) {
		RemoteActionInfo rActItem = new RemoteActionInfo();
		try {
			rActItem.isNoExpoFlg = Boolean.valueOf(isNoExpoFlg);
			rActItem.accMstId = accMstId;
			rActItem.selectCityCdMap = (Map<String, Set<String>>)JSON.deserializeStrict(wkSelectCityCdJson, Map<String, Set<String>>.class);
		} catch (Exception e) {}
		PageInfo pageItem = new PageInfo();
		// 地域数据处理
		setDataInfo(pageItem, true);
		List<String> expoAreaMstLabLst = new List<String>();
		List<String> expoAreaMstCodeLst = new List<String>();
		Map<String, String> stateCdToCityCdMap = getExpoAreaMstCodeAllMap(true);
		// selectCityCdMap
		for(String areaCd : pageItem.areaInfoMap.keySet()){
			AreaInfo areaItem = pageItem.areaInfoMap.get(areaCd);
			for(String stateCd : areaItem.stateInfoMap.keySet()){
				StateInfo stateItem = areaItem.stateInfoMap.get(stateCd);
				String selectCityCdKey = getSelectCityCdKey(areaItem.areaCd, stateItem.stateCd);
				if(rActItem.selectCityCdMap.containsKey(selectCityCdKey)){
					String expoAreaMstLab = stateItem.stateLab;
					// 2019/04/30 修正 WGCH BGEGIN
					String expoAreaMstCode = selectCityCdKey;
					// 2019/04/30 修正 WGCH END
					Set<String> selectCityCdSet = rActItem.selectCityCdMap.get(selectCityCdKey);
					if(selectCityCdSet.size() >= stateItem.cityInfoMap.size()){
						if(expoAreaMstCodeLst.contains(expoAreaMstCode)) continue;
						expoAreaMstLabLst.add(expoAreaMstLab);
						expoAreaMstCodeLst.add(expoAreaMstCode);
					} else {
						// 2019/04/30 修正 WGCH BGEGIN
						for(String cityCd : stateItem.cityCdAllLst){
						// 2019/04/30 修正 WGCH END
							if(!selectCityCdSet.contains(cityCd)) continue;
							CityInfo cityItem = stateItem.cityInfoMap.get(cityCd);
							String wkExpoAreaMstLab = cityItem.cityLab + '(' + expoAreaMstLab + ')';
							String wkExpoAreaMstCode = expoAreaMstCode + CUST_SYMBOL + cityItem.cityCd;
							expoAreaMstLabLst.add(wkExpoAreaMstLab);
							expoAreaMstCodeLst.add(wkExpoAreaMstCode);
						}
					}
				}
			}
		}
		List<String> newExpoAreaMstCodeLst = new List<String>();
		for(String cd : expoAreaMstCodeLst){
			if(stateCdToCityCdMap.containsKey(cd)) cd = stateCdToCityCdMap.get(cd);
			newExpoAreaMstCodeLst.add(cd);
		}
		rActItem.expoAreaMstLab = String.join(expoAreaMstLabLst, ';');
		rActItem.expoAreaMstCode = String.join(newExpoAreaMstCodeLst, ';');
		if(expoAreaMstCodeLst.size() > 50){
			rActItem.errorMessage = '最大５０件まで選択してください。';
			return rActItem;
		}
		if(!rActItem.isNoExpoFlg){
			// 指定の会計商品に指定住所IDを設定する
			List<AccountMaster__c> extAccs = [select Id, ExpoAreaMstLab__c, ExpoAreaMstCode__c from AccountMaster__c where id =: rActItem.accMstId];
			if (extAccs.isEmpty()){
				rActItem.errorMessage = CUST_ERROR_MSG;
				return rActItem;
			}
			for (AccountMaster__c acc : extAccs) {
				acc.ExpoAreaMstLab__c = rActItem.expoAreaMstLab;
				acc.ExpoAreaMstCode__c = rActItem.expoAreaMstCode;
			}
			update extAccs;
		}
		return rActItem;
	}
	// 获取市区郡-KEY
	public static String getSelectCityCdKey(String areaCd, String stateCd){
		return CommUtils.nullToBlank(areaCd) + CUST_SYMBOL + CommUtils.nullToBlank(stateCd);
	}
	// すべて-コード
	public static Map<String, String> getExpoAreaMstCodeAllMap(Boolean isStateCdToCityCdFlg){
		Map<String, String> stateCdToCityCdMap = new Map<String, String>();
		Map<String, String> cityCdToStateCdMap = new Map<String, String>();
		for(ExpoAreaMst__c sobj : [Select Id, AreaLst__c, StateLst__c, City__c, CityCode__c From ExpoAreaMst__c Where City__c = null]){
			String selectAll = getSelectCityCdKey(sobj.AreaLst__c, sobj.StateLst__c);
			stateCdToCityCdMap.put(selectAll, (selectAll + CUST_SYMBOL + CommUtils.nullToBlank(sobj.CityCode__c)));
			cityCdToStateCdMap.put(CommUtils.nullToBlank(sobj.CityCode__c), CommUtils.nullToBlank(sobj.StateLst__c));
		}
		return isStateCdToCityCdFlg ? stateCdToCityCdMap : cityCdToStateCdMap;
	}
}