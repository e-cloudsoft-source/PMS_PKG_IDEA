public with sharing class CommRepUtils {
	// LOGO_01_BILL:請求書/ LOGO_02_ACCOUNT:会計書/ LOGO_03_LEAD:見積書 /LOGO_00_SYSDEF 組織Default値
	public enum REP_TYPE{LOGO_00_SYSDEF, LOGO_01_BILL, LOGO_02_ACCOUNT, LOGO_03_LEAD}
	
	public static ReportLogo__c getReplogoInfoByTypeId (REP_TYPE rType) {
		// 2019/05/15 領収書の収入印紙部分に添付の画像機能対応 BY zyz BEGIN
		List<ReportLogo__c> rs =[select name, ReportLogo__c,StampImage__c,StampDutyImage__c,ShopInfoRef__c,ShopInfoRef__r.Name from ReportLogo__c where (name = :rType.name() Or name = :REP_TYPE.LOGO_00_SYSDEF.name()) Order By Name desc limit 1];
		// 2019/05/15 領収書の収入印紙部分に添付の画像機能対応 BY zyz END
		//レポート関連設定情報を見つかりません。
		if (rs.isEmpty()) throw new CommException(Label.MSG_012_0417);
		return rs[0];
	}
	/**
	* 支店コードにて、該当支店に所属するレポート情報を取得する
	**/
	public static ReportLogo__c getReportTitleInfo() {
		User curUser = UserUtil.CurrentUser;
		return getReportTitleInfo(curUser.ShopCode__c);
	}
	public static ReportLogo__c getReportTitleInfo(String pShopCode) {
		// 支店コードが未設定する場合、元の組織情報とカスタム設定から、情報を取得する
		if (CommUtils.isBlank(pShopCode)) {
			ReportLogo__c newRepInfo = getReplogoInfoByTypeId(REP_TYPE.LOGO_00_SYSDEF);
			// 総合情報からレポート情報Merageする
			return newRepInfo;
		} else {
			// 支店コードにて、支店関連レポート情報を取得する
			List<ReportLogo__c> rs = [SELECT   ShopInfoRef__r.WebSite__c,
										       ShopInfoRef__r.Post__c,
										       ShopInfoRef__r.Phone__c,
										       ShopInfoRef__r.Fax__c,
										       ShopInfoRef__r.Email__c,
										       ShopInfoRef__r.Address__c,
										       ShopInfoRef__r.Name,
										       ShopInfoRef__r.ShopCode__c,
										       ShopInfoRef__c,
										       StampImage__c,
										       // 2019/05/15 領収書の収入印紙部分に添付の画像機能対応 BY zyz BEGIN
										       StampDutyImage__c,
										       // 2019/05/15 領収書の収入印紙部分に添付の画像機能対応 BY zyz END
										       ReportLogo__c
										FROM ReportLogo__c r
										where ShopInfoRef__r.ShopCode__c = :pShopCode
										Order By Name desc limit 1];
			// 支店コードにて、関連支店レポート情報設定内容を取得する
			//if (rs.isEmpty()) throw new CommException('レポート関連設定情報を見つかりません。支店：['+ curUser.BranchShop__c +']');
			if (rs.isEmpty()) throw new CommException('Shop Code Not Found. [' + pShopCode + ']');
			
			return rs[0];
		}
	}
	// 2017/09/25 店舗ロゴ情報を取得する
    public static map<string,ReportLogo__c> getReportTitleInfo(set<String> pShopCodeSet) {
        // 支店コードが未設定する場合、元の組織情報とカスタム設定から、情報を取得する
        if (pShopCodeSet == null || pShopCodeSet.isEmpty()) {
            ReportLogo__c newRepInfo = getReplogoInfoByTypeId(REP_TYPE.LOGO_00_SYSDEF);
            // 総合情報からレポート情報Merageする
            return new map<String,ReportLogo__c>{''=>newRepInfo};
        } else {
            // 支店コードにて、支店関連レポート情報を取得する
            List<ReportLogo__c> rs = [SELECT   ShopInfoRef__r.WebSite__c,
                                               ShopInfoRef__r.Post__c,
                                               ShopInfoRef__r.Phone__c,
                                               ShopInfoRef__r.Fax__c,
                                               ShopInfoRef__r.Email__c,
                                               ShopInfoRef__r.Address__c,
                                               ShopInfoRef__r.Name,
                                               ShopInfoRef__r.ShopCode__c,
                                               ShopInfoRef__c,
                                               StampImage__c,
										       // 2019/05/15 領収書の収入印紙部分に添付の画像機能対応 BY zyz BEGIN
										       StampDutyImage__c,
										       // 2019/05/15 領収書の収入印紙部分に添付の画像機能対応 BY zyz END
                                               ReportLogo__c
                                        FROM ReportLogo__c r
                                        where ShopInfoRef__r.ShopCode__c = :pShopCodeSet
                                        Order By Name];
            // 支店コードにて、関連支店レポート情報設定内容を取得する
            //if (rs.isEmpty()) throw new CommException('レポート関連設定情報を見つかりません。支店：['+ curUser.BranchShop__c +']');
            if (rs.isEmpty()) throw new CommException('Shop Code Not Found. [' + pShopCodeSet + ']');
            map<string, ReportLogo__c> rsmap = new map<string, ReportLogo__c>();
            for (ReportLogo__c rep : rs) {
                rsmap.put(rep.ShopInfoRef__r.ShopCode__c, rep);
            }
            return rsmap;
        }
    }
	
	public static String getPdfMaxShowString(String s , Integer maxByte) {
		if (String.isEmpty(s)) return s;
		String returnStr = '';
		Decimal sum = 0;
		for(Integer i = 0 ; i < s.length(); i++){
			//一文字取得
			String one = s.substring(i, (i+1) ) ;
			//一文字バイト数計算
			Integer oneSize = CommUtils.getBytes(one);
			// 漢字など全角項目は２桁で計算（SFの中に、UNCODEは全部３桁として計算する
			sum += oneSize > 2 ? (CommUtils.isHalfKana(one) ? 1 : 1.7) : 1;
			//MAXを超えた場合
			if(sum > maxByte){
				return returnStr;
			}
			returnStr += one;
		}
		return s;
	}
	// 指定の施設のコメント最大表示できる文字数を格納する
	private static final map<String, Integer> commentMaxSizeMap =  
		new Map<String,Integer>{
			'1' =>17,
			'3' =>13,
			'4' =>17,
			'13'=>27,
			'14'=>36,
			'23'=>27,
			'24'=>36,
			'33'=>27,
			// 2017/11/15 会計画面コメント最大表示数対応ミス修正　by　wgch　BEGIN
			'34'=>36,
			'35'=>27,
			'36'=>36};
			// 2017/11/15 会計画面コメント最大表示数対応ミス修正　wgch　END
	private static final map<String, Integer> commentMaxLineMap =
		new Map<String,Integer>{
			'1'=>5,
			'3'=>5,
			'4'=>5,
			'13'=>2,
			'14'=>2,
			'23'=>2,
			'24'=>2,
			'33'=>2,
			// 2017/11/15 会計画面コメント最大表示数対応ミス修正　by　wgch　BEGIN
			'34'=>2,
			'35'=>2,
			'36'=>2 };
			// 2017/11/15 会計画面コメント最大表示数対応ミス修正　by　wgch　END
	private static final map<String, Decimal> commentLowSizeMap =  
		new Map<String,Decimal>{
			'a'=>0.55,
			'b'=>0.55,
			'c'=>0.50,
			'd'=>0.55,
			'e'=>0.55,
			'f'=>0.28,
			'g'=>0.55,
			'h'=>0.55,
			'i'=>0.22,
			'j'=>0.22,
			'k'=>0.50,
			'l'=>0.22,
			'm'=>0.85,
			'n'=>0.55,
			'o'=>0.55,
			'p'=>0.55,
			'q'=>0.55,
			'r'=>0.33,
			's'=>0.50,
			't'=>0.28,
			'w'=>0.73,
			'v'=>0.50,
			'u'=>0.55,
			'x'=>0.50,
			'y'=>0.50,
			'z'=>0.50};
	private static final map<String, Decimal> commentCapSizeMap =  
		new Map<String,Decimal>{
			'A'=>0.67,
			'B'=>0.67,
			'C'=>0.71,
			'D'=>0.71,
			'E'=>0.67,
			'F'=>0.61,
			'G'=>0.77,
			'H'=>0.71,
			'I'=>0.28,
			'J'=>0.50,
			'K'=>0.67,
			'L'=>0.56,
			'M'=>0.83,
			'N'=>0.71,
			'O'=>0.77,
			'P'=>0.67,
			'Q'=>0.77,
			'R'=>0.71,
			'S'=>0.67,
			'T'=>0.61,
			'W'=>0.96,
			'V'=>0.67,
			'U'=>0.71,
			'X'=>0.67,
			'Y'=>0.67,
			'Z'=>0.61};
	public static Integer getPdfMaxShowStringNum(String fc) {
		if (!commentMaxSizeMap.containsKey(fc)) return 0;
		return commentMaxSizeMap.get(fc) * commentMaxLineMap.get(fc);
	}
	private static final Pattern isnumbersPattern = Pattern.Compile('^[0-9]+$');
	public static Boolean isNumber(String s) {
		Matcher numberMatch = isnumbersPattern.matcher(s);
		return numberMatch.Matches();
	}
	public static String getPdfMaxShowStringNew(String s , String fc) {
		if (String.isEmpty(s)) return '';
		if (!commentMaxSizeMap.containsKey(fc)) return s;
		String sw = s.replace(' ', '');

		Integer cyIndex = commentMaxLineMap.get(fc);
		Integer rowNum = commentMaxSizeMap.get(fc);
		return getPdfMaxShowStringNew(sw, cyIndex, rowNum);
	}
	// 指定の文字列の最大N行、最大M文字（oneLineMaxSize）/行目は空白スペースでわけって文字列を返却する
	public static String getPdfMaxShowStringNew(String sw , Integer maxRows, Integer oneLineMaxSize) {
		return getPdfMaxShowStringNew(sw, maxRows, oneLineMaxSize, null,null);
	}
	//2017/02/21 倒影处理用 by zy BEGIN
	// 指定の文字列の最大N行、最大M文字（oneLineMaxSize）/行目は指定キーでわけって文字列を返却する
	public static String getPdfMaxShowStringNew(String sw , Integer maxRows, Integer oneLineMaxSize, String splitChar) {
		return getPdfMaxShowStringNew(sw, maxRows, oneLineMaxSize, splitChar,null);
	}
	// 指定の文字列の最大N行、最大M文字（oneLineMaxSize）/行目は指定キーでわけって文字列を返却する
	public static String getPdfMaxShowStringNew(String sw , Integer maxRows, Integer oneLineMaxSize, String splitChar,String splitRow) {
	    return getPdfMaxShowStringNew(sw, maxRows, oneLineMaxSize, splitChar,splitRow, true);
	}
	public static String getPdfMaxShowStringNew(String sw , Integer maxRows, Integer oneLineMaxSize, String splitChar,String splitRow, Boolean removeBlank) {
	//2017/02/21 倒影处理用 by zy END
		if (String.isEmpty(sw)) return '';
		// 2017/02/06 splitChar機能対応 BEGIN
		if (String.isEmpty(splitChar)) splitChar = ' ';
		// 2017/02/06 splitChar機能対応 END
		String returnStr = '';
		Integer ds = 0;
		if (sw.length() <= oneLineMaxSize) return sw;

		if (removeBlank) sw = sw.replace(' ', '');
		Integer maxBt = oneLineMaxSize * maxRows;
		for (Integer i = 0; i < maxRows; i++ ) {
			// 2015/01/13 BUG FIX BEGIN
			// if( (ds + 1) == sw.length()) return returnStr;
			// 2015/01/13 BUG FIX END
			Decimal sum = 0;
			for(Integer p = ds ; p < sw.length(); p++){
				String one = sw.substring(p, (p+1) ) ;
				Integer oneSize = CommUtils.getBytes(one);
				sum += oneSize > 2 ? (CommUtils.isHalfKana(one) ? 0.5 : 1) : (isNumber(one) ? 0.56 : (CommUtils.isAscLowercase(one) ? commentLowSizeMap.get(one) : (commentCapSizeMap.containsKey(one) ? commentCapSizeMap.get(one) : 0.5)));
				//2017/02/21 倒影处理用 by zy BEGIN
				if (!CommUtils.isBlank(splitRow)){
					if(one.contains(splitRow)){
						ds = p + 1;
						returnStr += one + splitChar;
						break;
					}
				}
				//2017/02/21 倒影处理用 by zy END
				if(sum > oneLineMaxSize){
					// 2017/02/06 splitChar機能対応 BEGIN
					//returnStr += ' ';
					returnStr += splitChar;
					// 2017/02/06 splitChar機能対応 END
					break;
				}
				ds = p + 1;
				returnStr += one;
				if(sum > maxBt) return returnStr;
			}
		}
		return returnStr;
	}
    // 2017/12/12 返却パラメータを追加する「返却文字列と行数を追加する」BEGIN
    public static String[] getPdfMaxShowStringNews(String sw , Integer maxRows, Integer oneLineMaxSize, Boolean removeBlank) {
        list<String> retArr = new List<String>();
        Integer cntMaxRow = 0;
        if (String.isEmpty(sw)) return retArr;
        String returnStr = '';
        Integer ds = 0;
        // 文字列は最大行文字数を超える場合、該当文字列をそのまま返却する
        if (sw.length() <= oneLineMaxSize) {
            retArr.add(sw);
            return retArr;
        }
        // 空白をクリアする
        if (removeBlank) sw = sw.replace(' ', '');
        // 最大文字数計算する
        Integer maxBt = oneLineMaxSize * maxRows;
        for (Integer i = 0; i < maxRows; i++ ) {
            // 行毎の文字数を格納する
            Decimal sum = 0;
            for(Integer p = ds ; p < sw.length(); p++){
                String one = sw.substring(p, (p+1) ) ;
                Integer oneSize = CommUtils.getBytes(one);
                sum += oneSize > 2 ? (CommUtils.isHalfKana(one) ? 0.5 : 1) : (isNumber(one) ? 0.56 : (CommUtils.isAscLowercase(one) ? commentLowSizeMap.get(one) : (commentCapSizeMap.containsKey(one) ? commentCapSizeMap.get(one) : 0.5)));
                if(sum > oneLineMaxSize){
                    // 改行処理済内容を格納する
                    retArr.add(returnStr);
                    returnStr = '';
                    break;
                }
                ds = p + 1;
                returnStr += one;
                //if(sum > maxBt) return returnStr;
                if(sum > maxBt) {
                    retArr.add(returnStr);
                    returnStr = '';
                    return retArr;
                }
            }
        }
        if (!CommUtils.isBlank(returnStr)) retArr.add(returnStr);
        return retArr;
    }
    // 2017/12/12 返却パラメータを追加する「返却文字列と行数を追加する」END
	// LOGOの画像はBase64に自動変換処理を行う
	public static String convertLogoToBase64(String logoUrl, Id repId) {
		String reporLogotURL = CommUtils.nullToBlank(logoUrl).substringBetween( ' src="', '"' );
        //String decodedURL = 'https://c.cs31.content.force.com/servlet/rtaImage?eid=a0Tp0000000a2B3&feoid=00Np0000000hzrc&refid=0EMp0000000LfEe'.unescapeHtml4();
        // 转换成base64，显示图片
        String imageStr ='';
        if (!CommUtils.isBlank(reporLogotURL)) {
	        String decodedURL = reporLogotURL.unescapeHtml4();
	        PageReference page = new PageReference( decodedURL );
	        Blob b = page.getContent();
	        imageStr = EncodingUtil.base64Encode(b);
        }
        return imageStr;
	}
	// 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw BEGIN
	// 按指定行数和列数分割字符串, 返回字符数组, 超出部分忽略
    public static List<String> handleNewLines(String s, Integer row, Integer col){
		List<String> result = new List<String>();
		List<String> lstSplits = s.trim().split('\n');
		for(Integer i = 0, j = Math.min(row, lstSplits.size()); i < j; i++) {
			String curStr = lstSplits[i];
			if(curStr.length() <= col) {
				result.add(curStr);
				if(result.size() == row) break;
				continue;
			}
			result.add(curStr.substring(0, col));
			if(result.size() == row) break;
			result.add(curStr.substring(col));
			if(result.size() == row) break;
		}
		return result;
	}
    // 2019/1/15 請求書に掲載する振込先口座情報を、同一店舗内で切り替えする BY cxw END
    // 2019/02/28 指定の文字は最大X全角文字数計算機能 WSQ BEGIN
    public static decimal zankaSizeByStr(String sw, Integer breakSize) {
    	sw = CommUtils.nullToBlank(sw);
    	decimal sum = 0;
    	if (breakSize == null) breakSize = 0;
        for(Integer p = 0 ; p < sw.length(); p++){
            String one = sw.substring(p, (p+1) ) ;
            Integer oneSize = CommUtils.getBytes(one);
            sum += oneSize > 2 ? (CommUtils.isHalfKana(one) ? 0.5 : 1) : (isNumber(one) ? 0.56 : (CommUtils.isAscLowercase(one) ? commentLowSizeMap.get(one) : (commentCapSizeMap.containsKey(one) ? commentCapSizeMap.get(one) : 0.5)));
            if(sum > breakSize){
                break;
            }
        }
        return sum;
    }
    // 2019/02/28 指定の文字は最大X全角文字数計算機能 WSQ END
}