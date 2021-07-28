public abstract with sharing class CommBaseCtrl {

	//初期化設定
	private static final String g_numberFormat = CommUtils.getNumberFormat();
	private static final String g_pointLen = String.valueOf(CommUtils.getPointLen());
	private static final String g_taxNumberFormat = CommUtils.getTaxNumberFormat();
	private static final String g_taxPointLen = String.valueOf(CommUtils.getTaxPointLen());
	private static final String g_currencySymbol = CommLocalUtils.getCurrencySymbol(UserInfo.getDefaultCurrency());
	private static final String g_local = UserInfo.getLocale();
	public static String getNumberFormat() { return g_numberFormat;}
	public static String getPointLen() { return g_pointLen; }
	public static String getTaxNumberFormat() { return g_taxNumberFormat;}
	public static String getTaxPointLen() { return g_taxPointLen;}
	public static String getCurrencySybmol() { return g_currencySymbol;}
	public static String getCurrency() {
		String locCurrency = UserInfo.getDefaultCurrency();
		if (locCurrency == null) locCurrency = 'JPY';
		return locCurrency;
	}
	public static boolean getLocalIsJapanese(){ return (CommUtils.isBlank(UserInfo.getLanguage()) || UserInfo.getLanguage() == 'ja'); }
	// 単価定義区分
	public static Integer getUnitPriceDefKbn(){ return ( CommDefine__c.getOrgDefaults().UnitPriceDefKb__c == null ? 2 : CommDefine__c.getOrgDefaults().UnitPriceDefKb__c.intValue()); }
	// 端数処理区分
	public static Integer getRoundType(){ return ( CommDefine__c.getOrgDefaults().RoundType__c == null ? 1 : CommDefine__c.getOrgDefaults().RoundType__c.intValue()); }
	// NS
	public static String getNs(){return CommConst.APPOTION_NAMESPACE;}
	// 日付書式
	public static String getDateFormat() {
		//if (getLocalIsJapanese()) return 'yyyy/MM/dd';
		//if (g_local == 'ja' || g_local == 'ja_JP') return 'yyyy/MM/dd';
		//else return 'MM/dd/yyyy';
		//else return 'M/d/yyyy';
		String locDateTmStr = CommUtils.nullToBlank(CommLocalUtils.getLocaleToDateTimeFmtMap().get(g_local));
		if (CommUtils.isBlank(locDateTmStr)) return 'M/d/yyyy'; 
		if (locDateTmStr.indexOf(',') > 0) {
			return locDateTmStr.substringBefore(',');
		} else {
			return locDateTmStr.substringBefore(' ');
		}
	}
	public static String getDateTimeFormat() {
		//String timeFormat = (getLocalIsJapanese()) ? ' HH:mm' : ' HH:mm';
		//return getDateFormat() + timeFormat;
		String locDateTimeStr = CommUtils.nullToBlank(CommLocalUtils.getLocaleToDateTimeFmtMap().get(g_local));
		if (CommUtils.isBlank(locDateTimeStr)) return getDateFormat() + ' HH:mm'; 
		else return locDateTimeStr;
	}
	public static String getTimeFormat() {


		
		String locTmStr = CommUtils.nullToBlank(CommLocalUtils.getLocaleToDateTimeFmtMap().get(g_local));
		if (CommUtils.isBlank(locTmStr)) return ' HH:mm'; 
		if (locTmStr.indexOf(',') > 0) {

			return locTmStr.substring(locTmStr.indexOf(','),locTmStr.length());
		} else {
			return locTmStr.substring(locTmStr.indexOf(' '),locTmStr.length());
		}
	}
	// 2017/04/17 Source Security Fix BEGIN
	public String getAccountNoTaxCalFlgStr() {
		return (CommDefine__c.getOrgDefaults().AccountNoTaxCalFlg__c != true ? 'false' : 'true');
	}
	// 2017/04/17 Source Security Fix END
}