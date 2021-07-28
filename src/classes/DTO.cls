global with sharing class DTO {

	global class ContactInfo {
		public ContactInfo(Contact c){
			KanaName = CommUtils.nullToBlank(c.KanaName1__c);
			KatakanaName = CommUtils.nullToBlank(c.Katakana__c);
			phone = CommUtils.nullToBlank(c.Phone);
		}
		public String KanaName{get;set;}	// カタカナ
		public String KatakanaName{get;set;} //ひらがな、
		public String phone{get;set;}		// Phone
	} 
}