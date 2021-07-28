public with sharing class CustomBathTaxAutoSetCtrl {
    // プランの入湯税に自動入力フラグ
	public String bTaxSetMode{get{ return CommConst.PLAN_BATHTAXAUTOSET_MODE;} set;}
	// プランの入湯税に自動入力設定有効FLG
	public Boolean isBTaxSetFlg{get{ return CommConst.PLAN_BATHTAXAUTOSET_MODE != CommConst.PLAN_BATHTAXAUTOSET_1;} set;}
	public CustomBathTaxAutoSetCtrl(){}
}