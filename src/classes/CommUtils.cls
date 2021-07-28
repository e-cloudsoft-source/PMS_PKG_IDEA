public with sharing class CommUtils {
	// Regex: 1.23, -1.23 OK
	private static final Pattern isnumbersPattern = Pattern.Compile('^[-]?[0-9]+[.]?[0-9]*$');
	// Regex: Half Kana
	private static final Pattern isHalfKanaPattern = Pattern.Compile('^[ｧ-ﾝﾞﾟ]+$');
	// Regex: 半角小英文字
	private static final Pattern isAscLowerCasePattern = Pattern.Compile('^[a-z]+$');
	// Regex: 日本住所分割定義
	private static final Pattern addressPattern = Pattern.Compile('(...??[都道府県])((?:旭川|伊達|石狩|盛岡|奥州|田村|南相馬|那須塩原|東村山|武蔵村山|羽村|十日町|上越|富山|野々市|大町|蒲郡|四日市|姫路|大和郡山|廿日市|下松|岩国|田川|大村)市|.+?郡(?:玉村|大町|.+?)[町村]|.+?市.+?区|.+?[市区町村])(.+)');
	// Regex: 英日期
	private static final String engDateFormat = '([a-zA-Z]+) [\\d]{2} [\\d]{4}';
	private static final Pattern engDatePattern = Pattern.Compile(engDateFormat);
	// Regex: 英時間
	private static final String engTimeFormat = '[\\d]{2}:[\\d]{2}';
	private static final Pattern engTimePattern = Pattern.Compile(engTimeFormat);
	private static map<String,String> monthMap = new Map<String,String>{'January'=>'01',
																		'February'=>'02',
																		'March'=>'03',
																		'April'=>'04',
																		'May'=>'05',
																		'June'=>'06',
																		'August'=>'08',
																		'September'=>'09',
																		'October'=>'10',
																		'November'=>'11',
																		'December'=>'12',
																		'July'=>'07'};
	
	public static Boolean isBlank(String s) {
		return (s == null || s.length() == 0);
	}

	public static String escStr(String s) {
		if (isBlank(s)) return '';
		// 2019/03/11 SFの全角「＼」問題回避 WSQ BEGIN
		s = String.escapeSingleQuotes(s);
		s = s.Replace('＼', '＼＼');
		// 2019/03/11 SFの全角「＼」問題回避 WSQ END
		return s;
	}
	/*
     * 文字列のバイト数を返す。
     * 
     */
    public static Integer getBytes(String strings) {
        return Blob.valueOf(strings).size();
    }
	/**
	* null -> ''変換関数
	**/
	public static String nullToBlank(String s) {
		return (s == null ? '' : s.trim());
	}
	public static String nullToBlank(Object s) {
		return (s == null ? '' : String.valueOf(s).trim());
	}
	public static Decimal nullToZero(Object s) {
		return (s == null ? 0 : Decimal.valueOf(String.valueOf(s).replaceAll('　','').trim()));
	}
	public static Decimal nullToZero(Decimal s) {
		return (s == null ? 0 : s);
	}
	public static Decimal nullToZero(String s) {
		return (isBlank(s) ? 0 : Decimal.valueOf(s.replaceAll(',', '').replaceAll('　','').trim()));
	}
	public static Integer nullToZero(Integer s) {
		return (s == null ? 0 : s);
	}
	public static Integer nullToIntZero (Object s) {
		return (isBlank(nullToBlank(s)) ? 0 : Integer.valueOf(nullToBlank(s).replaceAll('　','').trim()));
	}
	public static Decimal strToNullOrNumber(Object s) {
		return (isBlank(nullToBlank(s)) ? null : nullToZero(s));
	} 
    public static Time stringToTime(String s) {
    	//if (s==null || s.length() != 5) return null;
        //Integer HH = Integer.valueOf(s.subString(0,2));
        //Integer MM = Integer.valueOf(s.subString(3,5));
        if (s==null) return null;
        String[] times = splitTimes(s);
        try {
        return Time.newInstance(Integer.valueOf(times[0]), Integer.valueOf(times[1]), 0, 0);
        } catch (Exception e) {return null;}
    }
    public static Time stringToTimeOrNull(String s) {
    	if (CommUtils.isBLank(s)) return null;
    	return stringToTime(s);
    }
	/**
	* String -> Date
	**/
	public static Date stringToDate(String s) {
		/*try {
			if (s.contains('-')) return Date.valueOf(s);
			if (s.length() == 8) return Date.newInstance(Integer.valueOf(s.substring(0,4)),
														Integer.valueOf(s.substring(4,6)),
														Integer.valueOf(s.substring(6,8)));
			else return Date.parse(s);
		} catch (Exception e) { return null; }*/
		Date dt = null;
		if (isBlank(s)) return dt;
		try {
			if (s.contains('-')) dt = Date.valueOf(s);
		} catch (System.TypeException e) {}
		if (dt != null) return dt;
		try {
			if (s.length() == 8) dt = Date.newInstance(Integer.valueOf(s.substring(0,4)),
														Integer.valueOf(s.substring(4,6)),
														Integer.valueOf(s.substring(6,8)));
		} catch (System.TypeException e) {}
		if (dt != null) return dt;
		try {
			dt = Date.parse(s);
		} catch (System.TypeException e) {}
		return dt;
	}
	/*
	* Date -> YYYYMMDD
	*/
	public static string dateToYYYYMMDD(Date dt) {
		if (dt == null) return '';
		return (Datetime.newInstance(dt.year(),dt.month(),dt.day())).format('yyyyMMdd');
	}
	/**
	* Object -> Date
	**/
	public static Date objectToDate(Object o) {
		try {
			if(o != null){
				String s = String.valueOf(o);
				if (s.contains('-')) return Date.valueOf(s);
				if (s.length() == 8) return Date.newInstance(Integer.valueOf(s.substring(0,4)),
															Integer.valueOf(s.substring(4,6)),
															Integer.valueOf(s.substring(6,8)));
				else return Date.parse(s);
			}
			return null;
			
		} catch (Exception e) { return null; }
	}
	/**
	* Object -> Time
	**/
	public static Time objectToTime(Object o) {
		if(o == null) return null;
		String s = string.valueOf(o);
        String[] times = splitTimes(s);
        return Time.newInstance(Integer.valueOf(times[0]), Integer.valueOf(times[1]), 0, 0);
    }
	public static Date stringGmtToLocalDate(String s) {
		if(isBlank(s)){
			return null;
		}
		String str = s.replace('T',' ').replace('Z', '');
		DateTime dt = DateTime.valueOfGMT(str);
		return dt.date();
	}
    public static String getRandom(Integer bitLen) {
        Decimal lenNum = Math.random() * Math.pow(10,bitLen);
        return String.valueOf(lenNum.longValue());
    }
	/**
	 * パッディング：左ゼロ埋め
	 * @param n 数値
	 * @param len 桁数（数値の桁を含める）
	 * @return
	 */
	public static String paddingLeftZero(Decimal n, Integer len) {
	    Integer nlen = (Math.floor(Math.log10(Double.valueOf(n))).intValue() + 1);
	    if (n == 0) nlen = 1;
	    if(nlen >= len) return n.format();
	    String s = '';
	    for(Integer i=0, l=len-nlen; i<l; i++) {
	        s += '0';
	    }
	    return s + n;
	}
	public static String paddingLeftZero(String s, Integer len) {
		s = CommUtils.nullToblank(s);
		Integer slen = s.length();
	    if (slen == 0) slen = 1;
	    if(slen >= len) return s;
	    String rs = '';
	    for(Integer i=0, l=len-slen; i<l; i++) {
	        rs += '0';
	    }
	    return rs + s;
	}
	/**
	* 文字列で小数点以下の0を削除
	* @param s 文字列
	*/
	public static String deleteRightZero(String s) {
		if (isNumber(s) && s.contains('.')) {
			string ns = s.replaceAll('0+$', '');
			return ns.removeEnd('.');
		} else {
			return s;
		}
	}
	public static String deleteRightZero(String s, Integer pointLen) {
		if (pointLen > 0) return s;
		return deleteRightZero(s);
	}
	public static Boolean isNumber(String s) {
		Matcher numberMatch = isnumbersPattern.matcher(s);
		return numberMatch.Matches();
	}
	public static Boolean isHalfKana(String s) {
		Matcher mathch = isHalfKanaPattern.matcher(s);
		return mathch.Matches();
	}
	// 小文字半角英文字
	public static Boolean isAscLowercase(String s) {
		Matcher mathch = isAscLowerCasePattern.matcher(s);
		return mathch.Matches();
	}
	// 数字以外外す
	public static String convTelphoneNumber(String s) {
		if (String.isEmpty(s)) return '';
		return s.replaceAll('\\D','');
	}
	public static Date stringEnToDate(String dateString){
		Matcher mathch = engDatePattern.matcher(dateString);
		if (mathch.Matches()){ 
			for (String key : monthMap.keySet()) {
				if(dateString.contains(key)){
					dateString = dateString.replace(key,monthMap.get(key));
					String[] dateStrLst = dateString.split(' '); 
					Integer year = nullToIntZero(dateStrLst[2]);
					Integer month = nullToIntZero(dateStrLst[0]);
					Integer day = nullToIntZero(dateStrLst[1]);
					return Date.newInstance(year,month,day);
				}
			}
		}
		return null;
	}
	public static DateTime stringEnToDateTime(String dateString){
		String dateFormatString = dateString;
		for (String splitStr : dateString.split(engDateFormat)){
			dateFormatString = dateFormatString.replace(splitStr,'');
		}
		String timeFormatString = dateString;
		for (String splitStr : dateString.split(engTimeFormat)){
			timeFormatString = timeFormatString.replace(splitStr,'');
		}
		Date d = stringEnToDate(dateFormatString);
		Time t = stringToTime(timeFormatString);
		
		if (d != null && t != null) return DateTime.newInstance(d,t);
		return null;
	}
	// 有効な日付情報をチェックする
	public static boolean isBirthDay(Integer dtYear, Integer dtMonth, Integer dtDay) {
		if (dtYear < 1700) return false;
		if (dtMonth < 1 || dtMonth > 12) return false;
	    else if (dtDay < 1 || dtDay> 31) return false;
	    else if ((dtMonth==4 || dtMonth==6 || dtMonth==9 || dtMonth==11) && dtDay ==31) return false;
	    else if (dtMonth == 2) {
	        boolean isleap = (Math.mod(dtYear,4) == 0 && (Math.mod(dtYear,100) != 0 || Math.mod(dtYear,400) == 0));
	        if (dtDay> 29 || (dtDay ==29 && !isleap)) return false;
	    }
	    return true;
	}
    // 電話番号切り分け共通Mehtod
    public static String[] splitPhone(String p) {
    	String[] phoneNums = new String[]{'','',''};
    	if (String.isEmpty(p)) return phoneNums;
    	String[] splitNums = p.split('-');
        if (splitNums.size() >= 3) {
        	for (Integer i = 0; i < 3; i++) phoneNums[i] = splitNums[i];
        } else {
        	for (Integer i = 0; i < splitNums.size(); i++) phoneNums[i] = splitNums[i];
        }
    	return phoneNums;
    }
    // 郵便番号切り分け共通
    public static String[] splitPost(String p) {
        String[] postNums = new String[]{'',''};
        if (String.isEmpty(p)) return postNums;
        if (p.length() != 7 && p.length() != 8) return postNums;
        String[] splitNums = p.split('-');
        // - 含めない場合
        if (splitNums.size() == 1) {
            postNums[0] = p.subString(0,3);
            postNums[1] = p.subString(3);
        } else if (splitNums.size() == 2) {
            for (Integer i = 0; i < splitNums.size(); i++) postNums[i] = splitNums[i];
        }
        return postNums;
    }
    // 氏名切り分け共通
    public static String[] splitName(String p) {
        String[] names = new String[]{'',''};
        if (String.isEmpty(p)) return names;
        // 全角スペースから半角スペースへ変換を行う
        p = p.replaceAll('　',' ');
        // 両方の半角スペースを外す【2015/01/22 不具合修正:入力文字列の全方に半角スペースを入れると、分割処理は不正野不具合対応】
        p = p.trim();
        // 2個以上の半角スペースから１個半角スペースに変換を行う
        p = p.replaceAll('[ ]{2,}+',' ');
        String[] splits = p.split(' ');
        if (splits.size() == 1) {
        	names[0] = splits[0];
        } else if (splits.size() >= 2) {
        	// 2017/03/30 氏名は A B Cような複数スペースが存在する場合、２番目スペース以後の文言をなくなる不具合改修 BEGIN
        	for(Integer i = 0; i < splits.size(); i++) {
        		if (i > 1) {
        			names[1] += ' ' + splits[i].trim();
        		} else {
        			names[i] = splits[i].trim();
        		}
        	}
        	// 2017/03/30 氏名は A B Cような複数スペースが存在する場合、２番目スペース以後の文言をなくなる不具合改修 END
        }
        return names;
    }
    // 日本住所分割対応[東京都 台東区 池之端2－1－39]
    public static List<String> parseJapanAddress(String address) {
    	List<String> addressLst = new list<String>();
    	Matcher m=addressPattern.matcher(address);  
    	if(m.find()){
    		addressLst.add(CommUtils.nullToBlank(m.group(1)));
    		addressLst.add(CommUtils.nullToBlank(m.group(2)));
    		addressLst.add(CommUtils.nullToBlank(m.group(3)));
    	} else {
    		addressLst.add(CommUtils.nullToBlank(address));
    	}
    	return addressLst;
    }
    // スペースで単語分ける処理
    public static String[] splitSpace(String p) {
        if (String.isEmpty(p)) return new String[]{''};
        // 全角スペースから半角スペースへ変換を行う
        p = p.replaceAll('　',' ');
        // 2個以上の半角スペースから１個半角スペースに変換を行う
        p = p.replaceAll('[ ]{2,}+',' ');
        return p.split(' ');
    }
    // 時刻切り分け共通
    public static String[] splitTimes(String p) {
        String[] times = new String[]{'0','0'};
        if (String.isEmpty(p)) return times;
        String[] splits = p.split(':');
        if (splits.size() == 1) {
        	times[0] = splits[0];
        } else if (splits.size() >= 2) {
        	for(Integer i = 0; i < times.size(); i++) times[i] = splits[i].trim();
        }
        return times;
    }
    /*
    // 週間の曜日リストを返却する
    public static List<String> getYobiLst() {
        return new List<String>{
	        Label.CONST_012_0503,
	        Label.CONST_012_0504,
	        Label.CONST_012_0505,
	        Label.CONST_012_0506,
	        Label.CONST_012_0507,
	        Label.CONST_012_0508,
	        Label.CONST_012_0509};
    }*/
  	// 曜日の取得処理
  	public static String getYobi(Date vdDate){
  		if (vdDate == null) return null;
		Datetime tDate = datetime.newInstance(vdDate.year(), vdDate.month(), vdDate.day());
		String week = tDate.format('E');
		if(week == 'Sun'){
			//日
			return Label.CONST_012_0503;
		}else if(week =='Mon'){
			//月
			return Label.CONST_012_0504;
		}else if(week =='Tue'){
			//火
			return Label.CONST_012_0505;
		}else if(week =='Wed'){
			//水
			return Label.CONST_012_0506;
		}else if(week =='Thu'){
			//木
			return Label.CONST_012_0507;
		}else if(week =='Fri'){
			//金
			return Label.CONST_012_0508;
		}else if(week =='Sat'){
			//土
			return Label.CONST_012_0509;
		}
		return null;
	}
	// Day number of week (1 = Monday, ..., 7 = Sunday)
	public static Integer getDayNumOfWeek(Date vdDate) {
		Datetime tDate = datetime.newInstance(vdDate.year(), vdDate.month(), vdDate.day());
		return Integer.valueOf(tDate.format('u'));
	}
	// 指定日所属する月の１日から一か月分の日付リストを取得する
	public static List<Date> getDaysOfMonth(Date dt) {
		Date st = Date.newInstance(dt.year(), dt.month(), 1);
		Date ed = st.addmonths(1);
		List<Date> rsLst = new List<Date>();
		while (st < ed) {
			rsLst.add(st);
			st = st.adddays(1);
		}
		return rsLst;
	}
	public static List<Date> getDaysList(Date dt, Integer days) {
		Date st = dt;
		Date ed = st.addDays(days);
		List<Date> rsLst = new List<Date>();
		while (st <= ed) {
			rsLst.add(st);
			st = st.adddays(1);
		}
		return rsLst;
	}
	/**
	* Labelの入り変え対応　
	*/
	public static String LabelReplace(String lab, String val) {
	    return lab.replace('XXXXXX',val);
	}
	/**
	* FIELD_CUSTOM_VALIDATION_EXCEPTIONエラーメッセージ内容を取得する
	**/
	public static String getFieldValidationMessage(String message) {
		String key = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
		if (message.contains(key)) {
			Integer idx = message.indexOf(key) + key.length() + 1;
			String msgStr = message.substring(idx);
			return msgStr.removeEnd(': []');
		} else {
			return message;
		}
	}
	public static Boolean isFieldValidationMessage(String message) {
		String key = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
		return message.contains(key);
	}
	
	public static String getHostNameUrl () {
		return URL.getSalesforceBaseUrl().toExternalForm();
	}
	// UUID取得
	public static String getGUID() {
		return EncodingUtil.convertToHex(
		// 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz BEGIN
        Crypto.generateDigest('MD5', Blob.valueOf(DateTime.now().getTime().format()+getRandom(10)))
        // 2017/06/26 お客様がチェックアウトしたタイミングで音声通知機能 zyz END
		);
	}
    // 2017/12/11 指定SOBJECTの項目情報を取得する BEGIN
    public static String getFielValue(Sobject s, String api) {
        if (s == null || CommUtils.isBlank(api)) return null;
        api = CommUtils.nullToBlank(api).toLowerCase();
        if(!api.contains('__r.')){
            return CommUtils.nullToBlank(s.get(api));
        }else{
            String[] childApis = api.split('\\.');
            if(childApis.size() == 2){
                Sobject refObj = s.getSobject(childApis[0]);
                if(refObj == null) return null;
                return CommUtils.nullToBlank(refObj.get(childApis[1]));
            }
        }
        return null;
    }
    // 2017/12/11 指定SOBJECTの項目情報を取得する END
	// 2017/12/14 有効のSOSLキーチェック BEGIN
	public static Boolean isValidateSoslKey(String s) {
	    s = CommUtils.nullToBlank(s);
	    if (CommUtils.isBlank(s)) return false;
	    
        String ws = s.replaceAll('\\*','').replaceAll('\\?','').replaceAll('\\(','').replaceAll('\\)','').replaceAll('"','');
        Integer chkMinLen = containsDoubleByteCharacters(ws) ? 1 : 2;
        if(ws.length() < chkMinLen ) return false;
        return true;
	}
    /**
    * 全角文字列チェック
    * @param : input:チェック対象文字
    * @return : True/False
    * @created : 2017/12/07  TMTS)zhouyu
    */
    private static Boolean containsDoubleByteCharacters(String s) {
        Matcher m = Pattern.compile('[\\u0000-\\u007F]*').matcher(s);
        return !m.matches();
    }
	// 2017/12/14 有効のSOSLキーチェック BEGIN
	/**
	* 小数端末処理方式
	* 0:切り捨て 
	* 1:四捨五入 
	* 2:切り上げ 
	**/
	public static System.RoundingMode pointRoundMode() {
		Decimal roundType = CommDefine__c.getOrgDefaults().RoundType__c;
		//return(roundType == 0 ? RoundingMode.FLOOR : (roundType == 1 ? RoundingMode.HALF_UP : RoundingMode.CEILING));
		//return (CommDefine__c.RoundType__c == 0 ? RoundingMode.FLOOR : RoundingMode.HALF_UP );
		return pointRoundMode(roundType);
	}
	public static System.RoundingMode pointRoundMode(Decimal roundType) {
		return(roundType == 0 ? RoundingMode.FLOOR : (roundType == 1 ? RoundingMode.HALF_UP : RoundingMode.CEILING));
	}
	public static System.RoundingMode pointRoundMode(String roundType) {
		return (roundType == '切り捨て' ? RoundingMode.FLOOR : (roundType == '四捨五入' ? RoundingMode.HALF_UP : RoundingMode.CEILING));
	}
	// Profile単位で定義を行う
	public static String getPosNoByComdefine() {
		return(CommDefine__c.getInstance(UserInfo.getProfileId()).POSNo__c);
	}
	/**
	* 小数端末処理を行う
	**/
	public static Decimal RoundProcess(Decimal d, Integer pointSize) {
		return (d == null ? 0 : d.divide(1, pointSize, pointRoundMode()));
	}
    public static Decimal RoundProcess(Decimal d, Integer pointSize, RoundingMode mode) {
        return (d == null ? 0 : d.divide(1, pointSize, mode));
    }
    /**
    * 端数処理モードにより、端数処理区分を戻る
    **/
    public static Integer getRoundTypeKbnByRoundMode(RoundingMode modeType) {
    	return (modeType == RoundingMode.FLOOR ? 0 : (modeType == RoundingMode.CEILING ? 2 : 1));
    }
	/**
	* 金額（税金抜く）処理を行う
	**/
	public static Decimal CalExcTaxPrice (Decimal d, Decimal taxRate, Integer pointSize) {
		return ( d == null || taxRate == null ? 0 : RoundProcess(d / (1+nullToZero(taxRate)/100), pointSize ));
	}
	public static Decimal CalExcTaxPrice (Decimal d, Decimal taxRate, Integer pointSize, RoundingMode mode) {
		return ( d == null || taxRate == null ? 0 : RoundProcess(d / (1+nullToZero(taxRate)/100), pointSize, mode ));
	}
	/**
	* 金額（税金込み）処理を行う
	**/
	public static Decimal CalIncTaxPrice (Decimal d, Decimal taxRate, Integer pointSize) {
		return ( d == null || taxRate == null ? 0 : RoundProcess(d * (1+taxRate/100), pointSize ));
	}
	public static Decimal CalIncTaxPrice (Decimal d, Decimal taxRate, Integer pointSize, RoundingMode mode) {
		return ( d == null || taxRate == null ? 0 : RoundProcess(d * (1+taxRate/100), pointSize, mode ));
	}
	/**
	* 金額（税金含め）から消費税取得処理を行う
	**/
	/*
	public static Decimal CalTaxByPriceIncTax(Decimal d, Decimal taxRate, Integer pointSize) {
		// 税金1円未満は切り捨てとなります。
		if (taxRate == null) taxRate =
		Decimal priceExcTax = CalPriceOfExcTax(d, taxRate, pointSize, RoundingMode.CEILING);
		return (d - priceExcTax);
	}*/
	// 営業日付
	public static String getBusinessDay() {
		return (DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0))).format('yyyyMMdd');
	}
	// 消費税を取得する
	public static Decimal getTaxRate(Date validate) {
		// 2019/03/15 检索不到消费税数据bug对应 BY BEGIN
		//return [select TaxRate__c from JMST__c where TaxRate__c > 0 And BeginDate__c <= :validate And EndDate__c >= :validate order by createdDate asc limit 1].TaxRate__c;
		Decimal TaxRate = 0;
		list<JMST__c> jmlst = [select TaxRate__c from JMST__c where TaxRate__c > 0 And BeginDate__c <= :validate And EndDate__c >= :validate order by createdDate asc limit 1];
		if (!jmlst.isEmpty()) {
			TaxRate = jmlst[0].TaxRate__c;
		}
		return TaxRate;
		// 2019/03/15 检索不到消费税数据bug对应 BY END
	}
	public static Map<Date, Decimal> getTaxRateMap(Set<Date> validateSet) {
		Map<Date, Decimal> rateMap = new Map<Date, Decimal>();
		for (JMST__c rateMst: [select TaxRate__c,BeginDate__c,EndDate__c from JMST__c where TaxRate__c > 0 order by createdDate asc]) {
			for (Date dt: validateSet) {
				if (rateMst.BeginDate__c <= dt && rateMst.EndDate__c >= dt) {
					IF (!rateMap.containsKey(dt)) rateMap.put(dt, rateMst.TaxRate__c);
					validateSet.remove(dt);
				}
			}
		}
		for (Date dt: validateSet) {
			rateMap.put(dt, 0);
		}
		return rateMap;
	}
	/**
	* Where Key Like '%key%'
	**/
	public static String getLikeWhereBySetKey(Set<String> keySet, String fieldKey) {
		if (keySet == null || keySet.isEmpty()) return '';
		String likeWhereSql = '(';
		for (String key : keySet) {
			String likeKey = '\'%' + String.escapeSingleQuotes(key) + '%\'';
			likeWhereSql += fieldKey + ' like ' + likeKey + ' OR '; 
		}
		likeWhereSql = likeWhereSql.substringBeforeLast('OR');
		likeWhereSql += ')';
		return likeWhereSql;
	}

    /**
    * 指定する項目のMeta Describe情報取得
    Set<String> fields = new Set<String>{'name','annualrevenue','BADFIELD'};
	Map<String, Schema.DescribeFieldResult> finalMap = 
	  Utils.getFieldMetaData(Account.getSObjectType().getDescribe(), fields);
	 
	// only print out the 'good' fields
	for (String field : new Set<String>{'name','annualrevenue'}) {
	  System.debug(finalMap.get(field).getName()); // field name
	  System.debug(finalMap.get(field).getType()); // field type
	  System.debug(finalMap.get(field).getLength()); // field length
	}
    **/
	public static Map<String, Schema.DescribeFieldResult> getFieldMetaData(
	  Schema.DescribeSObjectResult dsor, Set<String> fields) {
	 
	  // the map to be returned with the final data
	  Map<String,Schema.DescribeFieldResult> finalMap = 
	    new Map<String, Schema.DescribeFieldResult>();
	  //
	  if (fields == null || fields.isEmpty()) return finalMap;
	  // map of all fields in the object
	  Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();
	 
	  // iterate over the requested fields and get the describe info for each one. 
	  // add it to a map with field name as key
	  for(String field : fields){
	    // skip fields that are not part of the object
	    if (objectFields.containsKey(field)) {
	      Schema.DescribeFieldResult dr = objectFields.get(field).getDescribe();
	      // add the results to the map to be returned
	      finalMap.put(field, dr); 
	    }
	  }
	  return finalMap;
	}
	/**
	 * CSV文字列からオブジェクトを作成するユーティリティクラス
	 * 使用例:
	 * ObjectBuilder builder = new ObjectBuilder(Account.getSObjectType());
	 * builder.setFieldNames('Name,Phone,Fax');
	 * Account acc = (Account)builder.create('Appirio,xxx-xxxx-xxxx,zzz-zzzz-zzzz');
	 */
	public virtual class ObjectBuilder {
	    /** sObjectType */
	    protected Schema.sObjectType sType;
	    /** インスタンスを作成する */
	    public virtual SObject newInstance() {
	        return sType.newSObject();
	    }
	    /**
	     * コンストラクタ
	     * @param sType 対象オブジェクトのsObjectType
	     */
	    public ObjectBuilder(Schema.sObjectType sType) {
	        this.sType = sType;
	        buildFieldTypeMap();
	    }

	    /** フィールド名と並び順を記録 */
	    protected List<String> fields = new List<String>();
	    /** フィールド名と型情報(Schema.DisplayType)のマッピング */
	    public Map<String, Schema.DisplayType> fieldTypeMap = new Map<String, Schema.DisplayType>();

	    /**
	     * CSVのヘッダを設定
	     *//*
	    public void setFieldNames(String headerCSV) {
	        if(headerCSV==null || headerCSV=='')
	            return;
	        List<String> headers = headerCSV.split(',');
	        for(String h : headers) {
	            fields.add(h.trim());
	        }
	    }*/
	    public Schema.DisplayType getDisplayType (String fieldNm) {
	    	return fieldTypeMap.get(fieldNm.toLowerCase());
	    }

	    /**
	     * CSV文字列からオブジェクトを作成し、データベースに保存して返す.
	     * テストクラス用途なので、upsertを行っています。また、エラー発生時はそのまま例外を送出します。
	     * （この部分は、用途に応じて改善の余地があります）
	     * @param csv
	     * @returns 保存後のオブジェクト
	     */
	     /*
	    public SObject create(String csv) {
	        if(csv==null)
	            return null;
	        SObject sobj = toObject(csv);
	        upsert sobj;
	        return sobj;
	    }*/

	    /**
	     * CSV文字列からオブジェクトを作成し、データベースに保存して返す.
	     * テストクラス用途なので、upsertを行っています。また、エラー発生時はそのまま例外を送出します。
	     * （この部分は、用途に応じて改善の余地があります）
	     * @param csvlist
	     * @returns 保存後のオブジェクト
	     *//*
	    public List<SObject> create(String[] csvlist) {
	        //具体的なオブジェクト名でリストを作成できないため、バッチアップデートできない。
	        //できそうな気もするが..
	        List<SObject> sobjs = new List<SObject>();
	        if(csvlist==null || csvlist.size()==0)
	            return sobjs;
	        for(String csv: csvlist) {
	            SObject sobj = toObject(csv);
	            if(sobj!=null) {
	                sobjs.add(sobj);
	                upsert sobj;
	            }
	        }
	        return sobjs;
	    }*/

	    /**
	     * フィールド名と型情報のマッピングを作る
	     */
	    protected virtual void buildFieldTypeMap() {
	        if(this.sType==null)
	            return;
	        Map<String, Schema.SObjectField> fmap = sType.getDescribe().fields.getMap();
	        for(Schema.Sobjectfield f : fmap.values()) {
	            Schema.DescribeFieldResult fd = f.getDescribe();
	            fieldTypeMap.put(fd.getName().toLowerCase(), fd.getType());
	        }
	    }

	    /**
	     * オブジェクトのインスタンスを作成し、CSVの値をセットして返す.
	     * @param values CSVの値
	     * @returns オブジェクトのインスタンス
	     *//*
	    protected SObject toObject(String csv) {
	        if(csv==null)
	            return null;
	        return toObject(csv.split(','));
	    }
	    */
	    /**
	     * オブジェクトのインスタンスを作成し、CSVの値をセットして返す.
	     * @param values CSVの値
	     * @returns オブジェクトのインスタンス
	     *//*
	    protected virtual SObject toObject(List<String> values) {
	        if(values==null || values.size()==0)
	            return null;

	        SObject sobj = newInstance();
	        if(sobj==null)
	            return null;

	        Integer i=0;
	        for(String f : fields) {
	            if(i >= values.size())
	                break;
	            sobj.put(f, conv(values.get(i), fieldTypeMap.get(f)));
	            i++;
	        }
	        return sobj;
	    }*/
	    /**
	     * 型情報に合わせて、文字列データを変換して返す.
	     * @param value データ
	     * @param fieldType 型情報
	     * @returns 変換後のデータ
	     *//*
	    public virtual Object conv(Object value, Schema.DisplayType fieldType) {
	        if(value==null)
	            return null;

	        if(fieldType == Schema.DisplayType.Integer ||
	            fieldType == Schema.DisplayType.Double ||
	            fieldType == Schema.DisplayType.Percent ||
	            fieldType == Schema.DisplayType.Currency ) {
	            // Decimal

//	            return value.trim()!='' ? Decimal.valueOf(value) : null;
				return value !=null ? Double.valueOf(value) : null;
	        }
	        else if(fieldType == Schema.DisplayType.Date) {
	            //Date
	            return value !=null ? Date.valueOf(value) : null;
	        }
	        else if(fieldType == Schema.DisplayType.DateTime) {
	            //DateTime
	            return value !=null ? DateTime.valueOf(value) : null;
	        }
	        else if(fieldType == Schema.DisplayType.Boolean) {
	            //Boolean
	            return value !=null ? Boolean.valueOf(value) : null;
	        }
	        //String
	        return value;
	    }*/
	}
	
    /**
     * 型情報に合わせて、文字列データを変換して返す.
     * @param value データ
     * @param fieldType 型情報
     * @returns 変換後のデータ
     */
    public static Object ConvByFielType(Object value, Schema.DisplayType fieldType) {
    // 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
		return ConvByFielType(value,fieldType,false);
	}
	public static Object ConvByFielType(Object value, Schema.DisplayType fieldType,boolean isNewVersionFlg) {
	// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
        if(value==null) return null;
        
        if(fieldType == Schema.DisplayType.Integer ||
            fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Percent ||
            fieldType == Schema.DisplayType.Currency ) {
            // Decimal
            return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? Decimal.valueof(String.valueOf(value)) : null;
        }
        else if(fieldType == Schema.DisplayType.Date) {
            // Date
			// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
			if (isNewVersionFlg) return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? stringToDate(String.valueOf(value)) : null;
            return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? Date.valueOf(String.valueOf(value)) : null;
			// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
        }
        else if(fieldType == Schema.DisplayType.DateTime) {
            // DateTime
			// 2020/02/15 予約が入っていないテーブルも選択可能に by zy BEGIN 
			if (isNewVersionFlg) return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? Datetime.parse(String.valueOf(value)) : null;
            return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? DateTime.valueOf(String.valueOf(value)) : null;
			// 2020/02/15 予約が入っていないテーブルも選択可能に by zy END 
        }
        else if(fieldType == Schema.DisplayType.Boolean) {
            // Boolean
            return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? Boolean.valueOf(String.valueOf(value)) : null;
        }
        // 2018/04/02 TIMEタイプを追加する
        else if(fieldType == Schema.DisplayType.Time) {
            // TIME
            return (!CommUtils.isBlank(CommUtils.nullToBlank(value))) ? CommUtils.stringtotime(String.valueOf(value)) : null;
        }
        //String
        return value;
    }
	// 組織の通貨定義情報により、小数点桁数情報を取得する
	public static Integer getPointLen() {
		// 通貨は日本円の場合、小数点０桁で計算する、日本円以外の場合、小数点２桁まで計算する
		String locCurrency = UserInfo.getDefaultCurrency();
		return getPointLen(locCurrency);
	}
	public static Integer getPointLen(String locCurrency) {
		return (!CommUtils.isBlank(locCurrency) && locCurrency != 'JPY' ) ? 2 : 0; 
	}
	// 指定する通貨により、消費税桁数情報を取得する
	public static Integer getTaxPointLen() {
		// 通貨は日本円の場合、小数点０桁で計算する、日本円以外の場合、小数点２桁まで計算する
		String locCurrency = UserInfo.getDefaultCurrency();
		return getTaxPointLen(locCurrency);
	}
	public static Integer getTaxPointLen(String locCurrency) {
		return (!CommUtils.isBlank(locCurrency) && locCurrency != 'JPY' ) ? 4 : 0; 
	}
	// 指定する通貨のMARKを取得する
	public static String getCurrencyMark(String pCurrency) {
		return (CommUtils.isBlank(pCurrency) || pCurrency == 'JPY')  ? '¥' : '';
	}
	// 指定する通貨の単位を取得する
	public static String getCurrencyUnit(String pCurrency) {
		return (CommUtils.isBlank(pCurrency) || pCurrency == 'JPY')  ? '円' : pCurrency;
	}
	// 指定する通貨は外貨(JPY)以外がどうかチェックする
	public static Boolean isForeignCurrency(String pCurrency) {
		return (!CommUtils.isBlank(pCurrency) && pCurrency != 'JPY');
	}
	// 指定の小数桁数により、NumberのFormat数式を作成する
	public static String getNumberFormat(integer pointlen) {
		return pointlen > 0 ? ('##,##0.' + '0'.repeat(pointlen) ) : '##,###';
	}
	public static String getNumberFormat() {
		return getNumberFormat(getPointLen());
	}
	// 消費税指定の小数書式化文字列
	public static String getTaxNumberFormat(integer pointlen) {
		return pointlen > 0 ? ('#0.' + '0'.repeat(pointlen)+ '%') : '#0%';
	}
	public static String getTaxNumberFormat() {
		return getTaxNumberFormat(getTaxPointLen());
	}
	// 2017/12/15 数値から通貨(##,###)出力する
	public static String numberFormat(decimal a) {
		List<String> args = new String[]{'0','number',getNumberFormat()};
		return String.format(CommUtils.nullToZero(a).format(), args);
	}
	// 税区分により、金額変換処理対応
	// usePrice : 元の商品の利用金額
	// taxRate  : 消費税率
	// serviceRate : サビース料
	// orgTaxKbn: 変換元の税区分
	// newTaxKbn: 変換後の税区分
	public static Decimal convertPriceByTaxKbn(Decimal usePrice, Decimal taxRate, Decimal serviceRate, Integer orgTaxKbn, Integer newTaxKbn) {
		// 変換なしの場合、そのまま返却する
		if (orgTaxKbn == newTaxKbn) return usePrice;
		serviceRate = nullToZero(serviceRate) / 100;
		taxRate = nullToZero(taxRate) / 100;
		// 小数点桁数設定
		Integer pointLen = getPointLen();
		Integer noTaxKbnPointLen = pointLen;
		if (serviceRate > 0) noTaxKbnPointLen++;
		if (taxRate > 0) noTaxKbnPointLen++;
		
		Decimal sfLocPrice = usePrice;
		// 単数区分の設定
		/*
		System.RoundingMode orgRoundMode = pointRoundMode();
		System.RoundingMode newRoundMode = RoundingMode.HALF_UP;
		if (orgRoundMode == RoundingMode.FLOOR) {
			newRoundMode = RoundingMode.CEILING;
		} else if (orgRoundMode == RoundingMode.CEILING) {
			newRoundMode = RoundingMode.FLOOR;
		}
		*/
		Decimal noTaxPrice = 0;
		// 税区分１に変換:サ抜き、税込
		if (orgTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP1) { 
			// 税区分２に変換:サ込、税込
			if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
				sfLocPrice = convertPriceToIncTax(usePrice, null, serviceRate, pointLen);
			}
			// 税区分３に変換:サ抜き、税抜き
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP3) {
				sfLocPrice = convertPriceToNoTax(usePrice, taxRate, null, noTaxKbnPointLen);
			}
			// 税区分４に変換:サ込、税抜き
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP4) {
				decimal incTaxPrice = convertPriceToIncTax(usePrice, null, serviceRate, pointLen);
				sfLocPrice = convertPriceToNoTax(incTaxPrice, taxRate, null, noTaxKbnPointLen);
			}
		} 
		// 税区分２に変換:サ込、税込
		else if (orgTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
			// 税区分１に変換:サ抜き、税込
			if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP1) {
				sfLocPrice = convertPriceToNoTax(usePrice, null, serviceRate, noTaxKbnPointLen);
			} 
			// 税区分３に変換:サ抜き、税抜き
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP3) {
				sfLocPrice = convertPriceToNoTax(usePrice, taxRate, serviceRate, noTaxKbnPointLen);
			}
			// 税区分４に変換:サ込、税抜き
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP4) {
				sfLocPrice = convertPriceToNoTax(usePrice, taxRate, null, noTaxKbnPointLen);
			}
		} 
		// 税区分３に変換:サ抜き、税抜き
		else if (orgTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP3) {
			// 税区分１に変換:サ抜き、税込
			if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP1) {
				sfLocPrice = convertPriceToIncTax(usePrice, taxRate, null, noTaxKbnPointLen);
			} 
			// 税区分２に変換:サ込、税込
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
				sfLocPrice = convertPriceToIncTax(usePrice, taxRate, serviceRate, pointLen);
			}
			// 税区分４に変換:サ込、税抜き
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP4) {
				sfLocPrice = convertPriceToIncTax(usePrice, null, serviceRate, noTaxKbnPointLen);
			}
		} 
		// 税区分４に変換:サ込、税抜き
		else if (orgTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP4) {
			// 税区分１に変換:サ抜き、税込
			if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP1) {
				// 税込みから税抜きに変更
				//Decimal noTaxSerPrice = convertPriceToNoTax(usePrice, null, serviceRate);
				//return convertPriceToIncTax(noTaxSerPrice, taxRate, null);
				Decimal incTaxPrice = convertPriceToIncTax(usePrice, taxRate, null, pointLen);
				// 
				sfLocPrice = convertPriceToNoTax(incTaxPrice, null, serviceRate, noTaxKbnPointLen);
			} 
			// 税区分２に変換:サ込、税込
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
				sfLocPrice = convertPriceToIncTax(usePrice, taxRate, null, pointLen);
			}
			// 税区分３に変換:サ抜き、税抜き
			else if (newTaxKbn == CommConst.APPOPTION_UTP_DEF_KB_OP3) {
				sfLocPrice = convertPriceToNoTax(usePrice, null, serviceRate, noTaxKbnPointLen);
			}
		}
		//return usePrice;
		// 
		/*
		Decimal sfPrice = RoundProcess(sfLocPrice,pointLen);
		// 税込金額一致の確認
		ProductInfo orgProd = new ProductInfo(orgTaxKbn);
		orgProd.process(usePrice, 1, taxRate, serviceRate);
		ProductInfo locProd = new ProductInfo();
		locProd.process(sfPrice, 1, taxRate, serviceRate);
		if (orgProd.unitPriceTax == locProd.unitPriceTax) return sfPrice;
		else return sfLocPrice;*/
		return sfLocPrice;
	}
	public static Decimal checkIfHadScale(Decimal orgPrice,Decimal taxRate,Decimal serviceRate,Integer kbn){
		// システム小数点の長さ
        Integer pointLen = CommUtils.getPointLen(); 
        // 変換値の小数点桁数
        Integer pricePointLen = orgPrice.stripTrailingZeros().scale();
        // システム予想の小数桁数により、長小数点をもっている場合
        if(pricePointLen > pointLen){
        	// 指定区分でサ込、税込金額を取得する
        	CommUtils.ProductInfo pro =  new CommUtils.ProductInfo(kbn);
        	pro.process(orgPrice,1,taxRate,serviceRate);
        	Decimal orgIncTaxServicePrice = pro.unitPriceTax;
        	
 			// 指定小数まで切上げで変換する
        	Decimal roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.CEILING);
        	pro.process(roundPrice,1,taxRate,serviceRate);
        	if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;
        	
        	// 指定小数まで切り捨てで変換する
        	roundPrice = CommUtils.RoundProcess(orgPrice, pointLen, RoundingMode.FLOOR);
        	pro.process(roundPrice,1,taxRate,serviceRate);
        	if (pro.unitPriceTax == orgIncTaxServicePrice) return roundPrice;
        }
        return orgPrice;
	}
	// 税抜き金額から税込金額に変更対応
	public static Decimal convertPriceToIncTax(Decimal usePrice, Decimal taxRate, Decimal serviceRate, Integer pointLen) {
		// 税抜き→税込みに変換を行う
		// 小数点桁数設定
		//Integer pointLen = getPointLen();
		serviceRate = nullToZero(serviceRate);
		taxRate = nullToZero(taxRate);
		// サビース料、税両方共に計算する場合、
		/*
		// 消費税込
		Decimal noTaxPrice = (taxRate == 0)
								? usePrice
								: RoundProcess(usePrice * (1+taxRate) , pointLen+1);
		// サビース込
		Decimal noServicePrice = (serviceRate == 0)
								? noTaxPrice
								: RoundProcess(noTaxPrice * (1+serviceRate) , pointLen+1);
								
		*/
//System.debug(loggingLevel.INFO, (1+taxRate));
//System.debug(loggingLevel.INFO, (1+serviceRate));
//System.debug(loggingLevel.INFO, (usePrice));
		return RoundProcess(usePrice * (1+taxRate) * (1+serviceRate) , pointLen);
	}
	public static Decimal convertPriceToNoTax(Decimal usePrice, Decimal taxRate, Decimal serviceRate, Integer noTaxKbnPointLen) {
		// 税込み→在抜きに変換を行う
		
		//Integer pointLen = getPointLen();
		// サビース料がない場合
		serviceRate = nullToZero(serviceRate);
		taxRate = nullToZero(taxRate);
		/*
		// 消費税抜き
		Decimal noTaxPrice = (taxRate == 0)
								? usePrice
								: RoundProcess(usePrice / (1+taxRate) , pointLen+1);
		// サビース料抜きの場合
		Decimal noServicePrice = (serviceRate == 0)
								? noTaxPrice
								: RoundProcess(noTaxPrice / (1+serviceRate) , pointLen+1);
								*/
		// 小数点桁数設定
		//if (taxRate > 0 ) pointLen++;
		//if (serviceRate > 0) pointLen++;
//System.debug(loggingLevel.INFO, '::::::::::::::::::');
//System.debug(loggingLevel.INFO, 'serviceRate:::' + serviceRate);
//System.debug(loggingLevel.INFO, 'taxRate:::' + taxRate);	
//System.debug(loggingLevel.INFO, 'noTaxKbnPointLen:::' + noTaxKbnPointLen);	
		return RoundProcess(usePrice / (1+taxRate) / (1+serviceRate) , noTaxKbnPointLen);
	}
    // 商品関連の金額計算結果を維持する
    public class ProductInfo {

        public decimal unitPriceIncTax{get; private set;}          // 本体単価（税込）
        public decimal unitPriceExcTax{get; private set;}          // 本体単価（税抜）
        public decimal unitPriceIncService{get; private set;}      // 単価サービス料（税込）
        public decimal unitPriceExcService{get; private set;}      // 単価サービス料（税抜）
        public decimal unitPriceTax{get; private set;}             // 単価（税込、サービス料込）
        public decimal unitPriceIncServiceExcTax{get; private set;}// 単価（サービス料込、税抜き）

    	public decimal priceIncTax{get; private set;}              // 合計金額（税込:サービス込）
    	public decimal priceIncTaxNoService{get; private set;}     // 合計金額（税込：サービスなし）
    	public decimal priceExcTax{get; private set;}              // 合計金額(税抜)[サービス込] <-2013.07.23 （サービス込）意味追加
    	public decimal priceService{get; private set;}             //　合計サービス料（税込）
    	public decimal priceServiceExcTax{get; private set;}       //　合計サービス料(税抜)
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	//public decimal priceTax{get; private set;}               // 金額（消費税）
    	public decimal priceTax{get; private set;}
    	// 2019/07/30 軽減税率機能対応 WGCH END
    	// 2014/07/02 小数点BTYE数COUNTする
    	private Integer pointLen = 0;
		// 2014/07/08 単価定義区分指定
		private Integer initPriceKbn = null;
    	public ProductInfo() {
    		initPriceKbn = null;
			pointLen = getPointLen();
    	}
		public ProductInfo (Integer kbn) {
			initPriceKbn = kbn;
			pointLen = getPointLen();
		}
		public ProductInfo (Integer kbn, Integer pPointLen) {
			initPriceKbn = kbn;
			pointLen = pPointLen;
		}
		public void init(){
			pointLen = getPointLen();
		}
    	// ***********************************
    	// unitPrice:      商品金額（単価）
    	// amount:         数量
    	// taxRate:        消費税
    	// serviceRate:    サービス料
    	// ***********************************
    	public void process(Decimal unitPrice, Decimal amount, Decimal taxRate, Decimal serviceRate) {
    		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    		unitPrice = nullToZero(unitPrice);
    		amount = nullToZero(amount);
    		// 2019/07/30 軽減税率機能対応 WGCH END
    		// 商品単価区分
    		//Integer kbn = CommDefine__c.getInstance().UnitPriceDefKb__c == null ? 1 : CommDefine__c.getInstance().UnitPriceDefKb__c.intValue();
    		Integer kbn = ((initPriceKbn != null && initPriceKbn > 0) ? initPriceKbn : CommConst.APPOPTION_UTP_DEF_KB);
	 		// 2016/02/15 マイナス数値計算の対応 BEGIN
			Boolean accountMinusCalFlg = CommDefine__c.getOrgDefaults().AccountNoTaxCalFlg__c;
			Boolean unitPriceIsMinus = unitPrice < 0 ? true : false;
			if (unitPriceIsMinus && accountMinusCalFlg) unitPrice = Math.abs(unitPrice);
			Boolean accountNoTaxCalFlg = accountMinusCalFlg;
			// 2016/02/15 マイナス数値計算の対応 END
			// 2016/04/07 消費税金額を計算ロジックを追加 BEGIN
			Decimal calServiceRate = (nullToZero(serviceRate) / 100);
			Decimal calTaxRate = (nullToZero(taxRate) / 100);
			// 2016/04/07 消費税金額を計算ロジックを追加 END
    		// 商品単価の意味は 1:税込、サービス料抜き
    		if(kbn == CommConst.APPOPTION_UTP_DEF_KB_OP1) {
		        // *****************[仕様説明]**************
		        //　単価：500円　数量：3
		        // 単価（税込）:500
                // 単価（税抜）：500 / 1.05 =  477 (切上げ)
                // 単価サービス料（税込）：500 * 0.1 = 50
                // 単価サービス料（税抜）：477 * 0.1 = 47.7 ->47(切り捨て)
                // 単価金額（税込:サービス込）：500 + 50 = 550
		        // 合計サービス料（税込）：50 * 3 = 150
		        // 合計サービス料（税抜）：47 * 3 = 141
		        // 合計金額(税抜)：477 * 3 = 1431
		        // 合計金額（税込：サービスなし）:500 * 3 = 1500
		        // ****************************************
		        // 合計金額（税込:サービス込）:550 * 3 = 1650
		        // ****************************************
		        // 本体単価（税込）
                unitPriceIncTax = unitPrice;
                // 本体単価（税抜き）※※※※（１円未満切り上げ）※※※※
			    // 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
                unitPriceExcTax = CalExcTaxPrice(unitPriceIncTax, nullToZero(taxRate), pointLen, RoundingMode.CEILING);
			    } else {
		    	unitPriceExcTax = CalExcTaxPrice(unitPriceIncTax, nullToZero(taxRate), pointLen);
			    }
                // 単価サービス料（税込）
                unitPriceIncService = RoundProcess(unitPriceIncTax * (nullToZero(serviceRate) / 100), pointLen);
                // 単価サービス料（税抜）
                unitPriceExcService = RoundProcess(unitPriceExcTax * (nullToZero(serviceRate) / 100), pointLen);
                // 単価（税込、サービス料込）
                //unitPriceTax = unitPriceIncTax + unitPriceIncService;
                unitPriceTax = RoundProcess(unitPriceIncTax * ( 1 + nullToZero(serviceRate) / 100), pointLen);
                // 単価（税抜き、サービス料込）
				// 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
				unitPriceIncServiceExcTax = RoundProcess(unitPriceIncTax * (1 + nullToZero(serviceRate)  / 100) / (1 + (nullToZero(taxRate) / 100)), pointLen, RoundingMode.CEILING);
			    } else {
				unitPriceIncServiceExcTax = RoundProcess(unitPriceIncTax * (1 + nullToZero(serviceRate)  / 100) / (1 + (nullToZero(taxRate) / 100)), pointLen);			    	
			    }
                // 合計金額(税抜)[Object数式計算式と一致する]
                // 2013/07/23 EDIT
                //priceExcTax = unitPriceExcTax * amount;
                priceExcTax = unitPriceIncServiceExcTax * amount;
                // 合計サービス料金（税込）
                //priceService = RoundProcess(unitPriceIncTax * amount * (nullToZero(serviceRate) / 100), pointLen);
                priceService = RoundProcess(unitPriceIncService * amount, pointLen);
                // 合計サービス料金（税抜）
                priceServiceExcTax = unitPriceExcService * amount;
                // 合計金額(税抜)
                //priceExcTax = unitPriceExcTax * amount;
                // 合計金額（税込：サービスなし）
                priceIncTaxNoService = unitPriceIncTax * amount;
                // 合計金額（税込:サービス込）
                priceIncTax = unitPriceTax * amount;
                /*
                if (calTpKb == CommConst.APPOPTION_UTP_DEF_KB_TY2) {
	                priceIncTax = RoundProcess(unitPriceTax * amount, 0);
		        } else {
                    priceIncTax = RoundProcess(unitPriceExcTax * (1 + nullToZero(serviceRate) / 100) * amount * (1 + nullToZero(taxRate) / 100), 0);
		        }*/
                // 合計金額（税込）
	           /*
    			// 金額（税込）[サービス料も含めない]
    			priceIncTaxNoService = d;
	            // 合計金額(税抜)※※※※（１円未満切り上げ）※※※※
	            priceExcTax = CalExcTaxPrice(d, nullToZero(taxRate), 0, RoundingMode.CEILING);
	            // サービス料金（税込）
	            priceService = RoundProcess(d * (nullToZero(serviceRate) / 100), 0);
	            // サービス料金（税抜）
	            priceServiceExcTax = RoundProcess(priceExcTax * (nullToZero(serviceRate) / 100), 0);
	            // 税込合計金額再計算を行う（商品合計金額＋サービス料金（税込）+特別税）
	            priceIncTax = d + priceService;
	            // 消費税[本体消費税＋サビース消費税]
	            priceTax = priceIncTax - priceExcTax - priceServiceExcTax; // RoundProcess(d * (nullToZero(taxRate) / 100), 0);*/
    		}
    		// 商品単価の意味は 2:税込、サービス料込
    		else if (kbn == CommConst.APPOPTION_UTP_DEF_KB_OP2) {
                // *****************[仕様説明]**************
                //　単価：550円　数量：3
                // 単価（税抜）：550 / 1.1 / 1.05 =  477 (切上げ)
                // 単価（税込）：477 * 1.05 = 500.86 = 500(切り捨て)
                // 単価サービス料（税込）：550 - 500 = 50
                // 単価サービス料（税抜）：477 * 0.1 = 47.7 -> 47(切り捨て)
                // 単価金額（税込:サービス込）：550
                // 合計サービス料（税込）：50 * 3 = 150
                // 合計サービス料（税抜）：47 * 3 = 141
                // 合計金額(税抜)：477 * 3 = 1431
                // 合計金額（税込：サービスなし）:単価金額（税込:サービス込） * 3 = 1500
                // ****************************************
                // 合計金額（税込:サービス込）:550 * 3 = 1650
                // ****************************************
                // 本体単価（税抜き）※※※※（１円未満切り上げ）※※※※
				// 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
                unitPriceExcTax = RoundProcess(unitPrice / ((1 + (nullToZero(taxRate) / 100)) * (1 + (nullToZero(serviceRate) / 100))), pointLen, RoundingMode.CEILING);
			    } else {
                unitPriceExcTax = RoundProcess(unitPrice / ((1 + (nullToZero(taxRate) / 100)) * (1 + (nullToZero(serviceRate) / 100))), pointLen);
			    }
			    // 2016/03/01 税抜金額の端数処理は共通定義により計算する END
                // 本体単価（税込）
                unitPriceIncTax = CalIncTaxPrice(unitPriceExcTax, nullToZero(taxRate), pointLen);
                // 単価サービス料（税込）
                //unitPriceIncService = unitPrice - unitPriceIncTax;
                unitPriceIncService = RoundProcess(unitPriceExcTax * calServiceRate * (1+calTaxRate), pointLen);
                // 単価サービス料（税抜）
                unitPriceExcService = RoundProcess(unitPriceExcTax * (nullToZero(serviceRate) / 100), pointLen);
                // 単価金額（税込:サービス込）
                unitPriceTax = unitPrice;
                // 単価（税抜き、サービス料込）
				// 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
                unitPriceIncServiceExcTax = RoundProcess(unitPrice / (1 + (nullToZero(taxRate) / 100)), pointLen, RoundingMode.CEILING);
			    } else {
			    unitPriceIncServiceExcTax = RoundProcess(unitPrice / (1 + (nullToZero(taxRate) / 100)), pointLen);
			    }
			    // 2016/03/01 税抜金額の端数処理は共通定義により計算する END
                // 合計金額(税抜)[Object数式計算式と一致する]
                // EDIT 2013/07/23
                //priceExcTax = unitPriceExcTax * amount;
//2014/09/03 数量が小数点あり機能対応
//                priceExcTax = unitPriceIncServiceExcTax * amount;
				priceExcTax = RoundProcess(unitPriceIncServiceExcTax * amount, pointLen);
                // 合計サービス料金（税込）
                //priceService = RoundProcess(unitPriceIncTax * amount * (nullToZero(serviceRate) / 100), pointLen);
                priceService = RoundProcess(unitPriceIncService * amount, pointLen);
                // 合計サービス料金（税抜）
//                priceServiceExcTax = unitPriceExcService * amount;
				priceServiceExcTax = RoundProcess(unitPriceExcService * amount, pointLen);
                // 合計金額(税抜)
                //priceExcTax = unitPriceExcTax * amount;
                // 合計金額（税込：サービスなし）
//                priceIncTaxNoService = unitPriceIncTax * amount;
				priceIncTaxNoService = RoundProcess(unitPriceIncTax * amount, pointLen);
                // 合計金額（税込:サービス込）
//                priceIncTax = unitPriceTax * amount;
				priceIncTax = RoundProcess(unitPriceTax * amount, pointLen);
                /*
                // 合計金額(税込)
                priceIncTax = d;
                // 合計金額(税抜)※※※※（１円未満切り上げ）※※※※
                priceExcTax = RoundProcess(priceIncTax / ((1 + (nullToZero(taxRate) / 100)) * (1 + (nullToZero(serviceRate) / 100))), 0, RoundingMode.CEILING);
                 // サービス料金（税込）[商品金額 / (サービス料+消費税) * サービス料率]
                priceService = RoundProcess(priceExcTax * (nullToZero(serviceRate) / 100) * (1 + (nullToZero(taxRate) / 100)), 0);
	            // サービス料金（税抜）
	            priceServiceExcTax = RoundProcess(priceExcTax * (nullToZero(serviceRate) / 100), 0);
                // 消費税[本体消費税＋サビース消費税]
                priceTax = priceIncTax - priceServiceExcTax - priceExcTax;
                // 金額（税込）[サービス料も含めない]
                priceIncTaxNoService = priceIncTax - priceService;
                */
    		}
    		// 商品単価の意味は 3:税抜、サービス料抜き
    		else if (kbn == CommConst.APPOPTION_UTP_DEF_KB_OP3) {
                // *****************[仕様説明]**************
                //　単価：477円　数量：3
                // 単価（税抜）：477
                // 単価（税込）：477 * 1.05 = 500.85 = 500(切り捨て)
                // 単価サービス料（税込）：477 * 0.1 * 1.05 = 50.085 = 50(切り捨て)
                // 単価サービス料（税抜）：477 * 0.1 = 47.7 = 47 (切り捨て)
                // 単価金額（税込:サービス込）：477 * 1.1 * 1.05 = 550.935 = 550(切り捨て)
                // 合計サービス料（税込）：50 * 3 = 150
                // 合計サービス料（税抜）：47 * 3 = 141
                // 合計金額(税抜)：477 * 3 = 1431
                // 合計金額（税込：サービスなし）:単価金額（税込:サービス込） * 3 = 1500
                // ****************************************
                // 合計金額（税込:サービス込）:550 * 3 = 1650
                // ****************************************
                // 本体単価（税抜き）※※※※（１円未満切り上げ）※※※※
                unitPriceExcTax = unitPrice;
                // 本体単価（税込）
                unitPriceIncTax = CalIncTaxPrice(unitPriceExcTax, nullToZero(taxRate), pointLen);
                // 単価サービス料（税込）
                unitPriceIncService = RoundProcess(unitPriceExcTax * (nullToZero(serviceRate) / 100) * (1 + nullToZero(taxRate) / 100), pointLen);
                // 単価サービス料（税抜）
                unitPriceExcService = RoundProcess(unitPriceExcTax * (nullToZero(serviceRate) / 100), pointLen);
                // 単価金額（税込:サービス込）
                unitPriceTax = RoundProcess(unitPriceExcTax * (1 + nullToZero(serviceRate) / 100) * (1 + nullToZero(taxRate) / 100), pointLen);
                // 単価（税抜き、サービス料込）
				// 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
                unitPriceIncServiceExcTax = RoundProcess(unitPriceExcTax * (1 + (nullToZero(serviceRate) / 100)), pointLen, RoundingMode.CEILING);
			    } else {
			    unitPriceIncServiceExcTax = RoundProcess(unitPriceExcTax * (1 + (nullToZero(serviceRate) / 100)), pointLen);
			    }
			    // 2016/03/01 税抜金額の端数処理は共通定義により計算する END
//2014/09/03 数量が小数点あり機能対応
                // 合計サービス料金（税込）
//                priceService = unitPriceIncService * amount;
				priceService = RoundProcess(unitPriceIncService * amount, pointLen);
                // 合計サービス料金（税抜）
//                priceServiceExcTax = unitPriceExcService * amount;
				priceServiceExcTax = RoundProcess(unitPriceExcService * amount, pointLen);
                // 合計金額(税抜)
                // EDIT 2013/07/23 
                //priceExcTax = unitPriceExcTax * amount;
//                priceExcTax = unitPriceIncServiceExcTax * amount;
				priceExcTax = RoundProcess(unitPriceIncServiceExcTax * amount, pointLen);
                // 合計金額（税込：サービスなし）
//                priceIncTaxNoService = unitPriceIncTax * amount;
				priceIncTaxNoService = RoundProcess(unitPriceIncTax * amount, pointLen);
                // 合計金額（税込:サービス込）
//                priceIncTax = unitPriceTax * amount;
				priceIncTax = RoundProcess(unitPriceTax * amount, pointLen);
    			/*
                // 合計金額(税抜)
                priceExcTax = d;
                // 金額（税込）[サービス料も含めない]
                priceIncTaxNoService = CalIncTaxPrice(priceExcTax, nullToZero(taxRate), 0);
                 // サービス料金（税込）[商品金額 / (サービス料+消費税) * サービス料率]
                priceService = RoundProcess(priceExcTax * (nullToZero(serviceRate) / 100) * (1 + (nullToZero(taxRate) / 100)), 0);
                // サービス料[合計金額(税抜) * サービス料率]= サービス料金（税込）
                priceServiceExcTax = RoundProcess(priceExcTax * (nullToZero(serviceRate) / 100), 0);
                // 消費税[本体消費税＋サビース消費税]
                //priceTax = RoundProcess(priceExcTax * (nullToZero(taxRate) / 100), 0);
                // 合計金額（税込） = [合計金額(税抜) * (1+消費税) * (1+サービス率)]
                priceIncTax = RoundProcess(priceExcTax * (1 + nullToZero(taxRate) / 100) *  (1 + nullToZero(serviceRate)/100), 0);
                // 消費税[本体消費税＋サビース消費税]
                priceTax = priceIncTax - priceServiceExcTax - priceExcTax;*/
    		}
    		// 商品単価の意味は 4:税抜、サービス料込
    		else if(kbn == CommConst.APPOPTION_UTP_DEF_KB_OP4){
    			 // *****************[仕様説明]**************
                //　単価：500 円　数量：3
                // 単価（税抜）：500 / 1.1 = 454.54 = 455(切り捨て)
                // 単価（税込）：455 * 1.05 = 477.75 = 478(切り捨て)
                // 単価サービス料（税込）：(500 - 455) * 1.05 = 47.25 = 47(切り捨て)
                // 単価サービス料（税抜）：500 - 455 = 45
                // 単価金額（税込:サービス込）：500 * 1.05 = 525
                // 合計サービス料（税込）：47 * 3 = 141
                // 合計サービス料（税抜）：45 * 3 = 135
                // 合計金額(税抜)：455 * 3 = 1365
                // 合計金額（税込：サービスなし）:単価金額（税込:サービスなし） * 3 = 1434
                // ****************************************
                // 合計金額（税込:サービス込）:525 * 3 = 1575
                // ****************************************
                // 本体単価（税抜き）※※※※（１円未満切り上げ）※※※※
				// 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
			    unitPriceExcTax = RoundProcess(unitPrice / (1 + nullToZero(serviceRate) / 100),pointLen, RoundingMode.CEILING);
			    } else {
                unitPriceExcTax = RoundProcess(unitPrice / (1 + nullToZero(serviceRate) / 100),pointLen);
			    }
			    // 2016/03/01 税抜金額の端数処理は共通定義により計算する END
                // 本体単価（税込）
                unitPriceIncTax = CalIncTaxPrice(unitPriceExcTax, nullToZero(taxRate), pointLen);
                // 単価サービス料（税抜）
                //unitPriceExcService = unitPrice - unitPriceExcTax;
                unitPriceExcService = RoundProcess(unitPriceExcTax * calServiceRate, pointLen);
                // 単価サービス料（税込）
                //unitPriceIncService = RoundProcess(unitPriceExcService * (1 + nullToZero(taxRate) / 100), pointLen);
                unitPriceIncService = RoundProcess(unitPriceExcTax * calServiceRate * (1+calTaxRate), pointLen);
                // 単価金額（税込:サービス込）
                unitPriceTax = RoundProcess(unitPrice * (1 + nullToZero(taxRate) / 100) , pointLen);
                // 単価（税抜き、サービス料込）
				// 2016/03/01 税抜金額の端数処理は共通定義により計算する BEGIN
			    if (!accountNoTaxCalFlg) {
			    unitPriceIncServiceExcTax = RoundProcess(unitPrice, pointLen, RoundingMode.CEILING);	
			    } else {
                unitPriceIncServiceExcTax = RoundProcess(unitPrice, pointLen);
			    }
			    // 2016/03/01 税抜金額の端数処理は共通定義により計算する END
//2014/09/03 数量が小数点あり機能対応
                // 合計サービス料金（税込）
//                priceService = unitPriceIncService * amount;
				priceService = RoundProcess(unitPriceIncService * amount, pointLen);
                // 合計サービス料金（税抜）
//                priceServiceExcTax = unitPriceExcService * amount;
				priceServiceExcTax = RoundProcess(unitPriceExcService * amount, pointLen);
                // 合計金額(税抜)
                // EDIT 2013/07/23 
                //priceExcTax = unitPriceExcTax * amount;
//                priceExcTax = unitPriceIncServiceExcTax * amount;
				priceExcTax = RoundProcess(unitPriceIncServiceExcTax * amount, pointLen);
                // 合計金額（税込：サービスなし）
//                priceIncTaxNoService = unitPriceIncTax * amount;
				priceIncTaxNoService = RoundProcess(unitPriceIncTax * amount, pointLen);
                // 合計金額（税込:サービス込）
//                priceIncTax = unitPriceTax * amount;
				priceIncTax = RoundProcess(unitPriceTax * amount, pointLen);
    			
    		}
    		// 2016/02/15 マイナス数値計算の対応 BEGIN
    		if (unitPriceIsMinus && accountMinusCalFlg) {
				unitPriceIncTax = -unitPriceIncTax;				// 本体単価（税込）
				unitPriceExcTax = -unitPriceExcTax;				// 本体単価（税抜）
				unitPriceIncService = -unitPriceIncService;		// 単価サービス料（税込）
				unitPriceExcService = -unitPriceExcService;		// 単価サービス料（税抜）
				unitPriceTax = -unitPriceTax;					// 単価（税込、サービス料込）
				unitPriceIncServiceExcTax = -unitPriceIncServiceExcTax;		// 単価（サービス料込、税抜き）
				priceIncTax = -priceIncTax;						// 合計金額（税込:サービス込）
				priceIncTaxNoService = -priceIncTaxNoService;	// 合計金額（税込：サービスなし）
				priceExcTax = -priceExcTax;						// 合計金額(税抜)[サービス込] <-2013.07.23 （サービス込）意味追加
				priceService = -priceService;					// 合計サービス料（税込）
				priceServiceExcTax = -priceServiceExcTax;		// 合計サービス料(税抜)
    		}
    		// 2016/02/15 マイナス数値計算の対応 END
    		// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    		priceTax = RoundProcess(unitPriceIncServiceExcTax * (nullToZero(taxRate) / 100), 0);
    		// 2019/07/30 軽減税率機能対応 WGCH END
    	}
    	// 特別税計算を行う
    	public Decimal specialTaxCal(Decimal roomPrice) {
			if (roomPrice >= CommConst.ROOM_TAX_MONEY_LEV1 && roomPrice < CommConst.ROOM_TAX_MONEY_LEV2) {
				return 100;
			} else if (roomPrice >= CommConst.ROOM_TAX_MONEY_LEV2) {
				return 200;
			} else {
				return 0;
			}
    	}
    	// 2019/07/30 軽減税率機能対応 WGCH BEGIN
    	public ProductInfo getNewPriceInfo(ProductInfo priceInfo, Decimal wkHotelTax, Decimal qty){
			priceInfo.unitPriceIncTax += wkHotelTax;          // 本体単価（税込）
			priceInfo.unitPriceExcTax += wkHotelTax;          // 本体単価（税抜）
			// priceInfo.unitPriceIncService;                 // 単価サービス料（税込）=> 原值
			// priceInfo.unitPriceExcService;                 // 単価サービス料（税抜）=> 原值
			priceInfo.unitPriceTax += wkHotelTax;             // 単価（税込、サービス料込）
			priceInfo.unitPriceIncServiceExcTax += wkHotelTax;// 単価（サービス料込、税抜き）
	
			priceInfo.priceIncTax += wkHotelTax * qty;          // 合計金額（税込:サービス込）
			priceInfo.priceIncTaxNoService += wkHotelTax * qty; // 合計金額（税込：サービスなし）
			priceInfo.priceExcTax += wkHotelTax * qty;          // 合計金額(税抜)[サービス込] <-2013.07.23 （サービス込）意味追加
			// priceInfo.priceService;                          //　合計サービス料（税込）=> 原值
			// priceInfo.priceServiceExcTax;                    //　合計サービス料(税抜) => 原值
			return priceInfo;
    	}
    	public void getAddPriceInfo(ProductInfo priceInfo){
			unitPriceIncTax = CommUtils.nullToZero(unitPriceIncTax) + priceInfo.unitPriceIncTax; // 本体単価（税込）
			unitPriceExcTax = CommUtils.nullToZero(unitPriceExcTax) + priceInfo.unitPriceExcTax; // 本体単価（税抜）
			unitPriceIncService = CommUtils.nullToZero(unitPriceIncService) + priceInfo.unitPriceIncService; // 単価サービス料（税込）=> 原值
			unitPriceExcService = CommUtils.nullToZero(unitPriceExcService) + priceInfo.unitPriceExcService; // 単価サービス料（税抜）=> 原值
			unitPriceTax = CommUtils.nullToZero(unitPriceTax) + priceInfo.unitPriceTax; // 単価（税込、サービス料込）
			unitPriceIncServiceExcTax = CommUtils.nullToZero(unitPriceIncServiceExcTax) + priceInfo.unitPriceIncServiceExcTax; // 単価（サービス料込、税抜き）
	
			priceIncTax = CommUtils.nullToZero(priceIncTax) + priceInfo.priceIncTax; // 合計金額（税込:サービス込）
			priceIncTaxNoService = CommUtils.nullToZero(priceIncTaxNoService) + priceInfo.priceIncTaxNoService; // 合計金額（税込：サービスなし）
			priceExcTax = CommUtils.nullToZero(priceExcTax) + priceInfo.priceExcTax; // 合計金額(税抜)[サービス込] <-2013.07.23 （サービス込）意味追加
			priceService = CommUtils.nullToZero(priceService) + priceInfo.priceService; //　合計サービス料（税込）=> 原值
			priceServiceExcTax = CommUtils.nullToZero(priceServiceExcTax) + priceInfo.priceServiceExcTax; //　合計サービス料(税抜) => 原值
			priceTax = CommUtils.nullToZero(priceTax) + priceInfo.priceTax; // 消费税
			//return priceInfo;
    	}
    	// 2019/07/30 軽減税率機能対応 WGCH  END
    }
    // 边界值
    private static String nextTime = '24:00';
    // 2018/04/18 時刻チェック不正対応 BY ZY BEGIN
    private static integer nextTimeInt = 24;
    // 2018/04/18 時刻チェック不正対応 BY ZY END
    // 24小时以后的日期处理
	public static Datetime convertDatetime(Date curDt,String curTime) {
		// 补位判断
		curTime = paddingLeftZero(curTime, 5);
		// 2018/04/18 時刻チェック不正対応 BY ZY BEGIN
		String[] times = splitTimes(curTime);
		// 是否需要加一天
		boolean skipFlag = nextTimeInt <= CommUtils.nullToIntZero(times[0]);
		 // 2018/04/18 時刻チェック不正対応 BY ZY END
		// 根据时间作成日期
		DateTime curDatetime = DateTime.newInstance(curDt,CommUtils.stringtotime(curTime));
		// 加一天
		if (skipFlag) curDatetime = curDatetime.addDays(1);
		return curDatetime;
	}
	// 2018/11/06 24時以後書式バグ対応 by zy BEGIN
	// 時間Format
	public static String convertHourKm(Datetime curtime,Date baseDt){
		// チェック日付
		if (baseDt != null && curtime.date() > baseDt) {
			Integer nextHour = nextTimeInt + curtime.hour();
			Integer minute = curtime.minute();
			String hourStr = CommUtils.paddingLeftZero(nextHour,2);
			String minuteStr = CommUtils.paddingLeftZero(minute,2);
			return hourStr + ':' + minuteStr;
		}
		return curtime.format('kk:mm');
	}
	// 2018/11/06 24時以後書式バグ対応 by zy END
	// 2018/12/30 プロジェックト新規プロジェックト明細改善対応　by zy BEGIN
	public static Datetime eventSafeEndDateTm(Datetime startDt,Datetime endDt){
		Integer maxMiuteLen = 14 * 24 * 60 * 1000;
		long startLong = startDt.getTime();
		long timeDiff = endDt.getTime() - startLong;
		if (timeDiff > maxMiuteLen) {
			decimal endTm = startLong + 14 * 23.9 * 60 * 1000;
			return Datetime.newInstance(endTm.longvalue());
		}
		return endDt;
	}
	// 2018/12/30 プロジェックト新規プロジェックト明細改善対応　by zy END
	// 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy BEGIN
	public static String convertHourKm(Datetime curtime,Datetime basetime){
		// チェック日付
		if (basetime != null) {
			if (curtime.isSameDay(basetime)) return curtime.format('HH:mm');
			else if (curtime.date() > basetime.date()) {
				Integer nextHour = nextTimeInt + curtime.hour();
				Integer minute = curtime.minute();
				String hourStr = CommUtils.paddingLeftZero(nextHour,2);
				String minuteStr = CommUtils.paddingLeftZero(minute,2);
				return hourStr + ':' + minuteStr;
			}
		}
		return curtime.format('kk:mm');
	}
	// 2019/04/30 一つの会席料理を90分を基準にするモードを追加する by zy END
	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz BEGIN
	private static final String HTML_FONT_PX = 'px';
	private static final String HTML_FONT_PT = 'pt';
	private static final String HTML_FONT_EM = 'em';
	private static final String HYML_STYLE_FONT = 'font-size';
	public static Decimal getCustomContentFontSizePdfLine(String content,String styleStr,Decimal lineWhite){
		return getCustomContentFontSizePdfLine(styleStr,null,null,lineWhite,content);
	}
	public static Decimal getCustomContentFontSizePdfLine(Decimal orgInt,Decimal fontSize){
		return getCustomContentFontSizePdfLine(null,orgInt,fontSize,null,null);
	}
	// 字体カスタム設定の場合、サイズ更新指定行数
	public static Decimal getCustomContentFontSizePdfLine(String styleStr,Decimal orgInt,Decimal fontSize,Decimal lineWhite,String content){
		if (orgInt == null) orgInt = 0;
		// 固定比例：1 em = 12 pt = 16 px = 100%
        if (fontSize == null) fontSize = 1;
        if (!CommUtils.isBlank(content)) orgInt = content.split('<br/>').size();
		// 字体設定あり
		if (!CommUtils.isBlank(styleStr)) {
			// 字体設定サイズ取得
            String req = HYML_STYLE_FONT + ':(.*?);';
            Pattern quotePattern = Pattern.compile(req);
            Matcher m = quotePattern.matcher(styleStr);
            String fontSizeTxt = '';
            // 字体最後サイズ
            while(m.find()) fontSizeTxt = m.group(0).tolowerCase();
            // ZOOMレベル計算
            if (!CommUtils.isBlank(fontSizeTxt)) {
                if (fontSizeTxt.contains(HTML_FONT_PX)) {
                    String fontSizeStr = fontSizeTxt.subStringBetween(HYML_STYLE_FONT + ':',HTML_FONT_PX + ';').deleteWhiteSpace();
                    fontSize = CommUtils.nullToZero(fontSizeStr) / 16;
                }
                else if (fontSizeTxt.contains(HTML_FONT_PT)) {
                    String fontSizeStr = fontSizeTxt.subStringBetween(HYML_STYLE_FONT + ':',HTML_FONT_PT + ';').deleteWhiteSpace();
                    fontSize = CommUtils.nullToZero(fontSizeStr) / 12;
                }
                else if (fontSizeTxt.contains(HTML_FONT_EM)) {
                    String fontSizeStr = fontSizeTxt.subStringBetween(HYML_STYLE_FONT + ':',HTML_FONT_EM + ';').deleteWhiteSpace();
                    fontSize = CommUtils.nullToZero(fontSizeStr) / 1;
                }
	        }
		}
		if (lineWhite == null) lineWhite = 0;
		// lineWhite * (orgInt - 1) 行间距为两行之间空隙
        // 該当折行*該当字体ZOOMレベル　小数点后省略
		orgInt = orgInt * fontSize + lineWhite * (orgInt - 1);
        return orgInt;
	}
	// 2019/07/15 請求書の請求先名称の上部に請求先の住所を印字 BY zyz END
}