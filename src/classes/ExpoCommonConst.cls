/**
*/
public class ExpoCommonConst {

	// 該当ユーザは既にログイン済み・されないチェツク用キー
	//public static final String AuthCookieId = 'SESSIONAUTHUSERID';
	public static final Integer AuthReleaseTime = 120;//SESSIONは２時間以内有効
	// 該当店舗ロゴ名作成・取得
	private static final String LogoName = 'LOGO';
	public static String getShopCodeLogoName(String shopCode){
		return LogoName + '_' + shopCode;
	}
}