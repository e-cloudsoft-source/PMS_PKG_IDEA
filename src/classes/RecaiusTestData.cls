/**
 * テストデータ作成クラス
 * 
 * 本番組織リリース時に必要なテストクラス
 * 
 * Copyright (c) 2018 TOSHIBA CORPORATION,  All Rights Reserved.
 */ 
@isTest(SeeALLData = true)
public class RecaiusTestData {
    public static String createUser1(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        //test用ユーザ作成
        User user1 = new User();
        String testusername = 'jinyarecaiustestuser2017@jinya-toshibatest.com';
        user1.UserName = testusername;
        user1.LastName = 'recaiustestuser1';
        user1.FirstName = 'jinyatestuser1';        
        user1.Email = testusername;
        user1.EmailPreferencesAutoBcc = true;
        user1.EmailPreferencesAutoBccStayInTouch = false;
        user1.EmailPreferencesStayInTouchReminder = true;
        user1.Alias = 'てすとです';
        user1.CommunityNickname = 'てすとです';
        user1.IsActive = true;
        user1.TimeZoneSidKey = 'Asia/Tokyo';
        user1.LocaleSidKey = 'ja_JP';
        user1.ReceivesInfoEmails = false;
        user1.EmailEncodingKey = 'ISO-2022-JP';
        //本番環境要確認
        Profile[] profiles;
   		profiles =  [select Id From Profile where Name = '標準ユーザ' limit 1];
         if (profiles.isEmpty()){
             profiles =  [select Id From Profile where Name = 'Standard User' limit 1];
    	}
        user1.ProfileId = profiles[0].Id;        
        user1.LanguageLocaleKey = 'ja';        
        insert user1;
        return user1.Id;
    }

    public static String createUser2(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        //test用ユーザ作成 firstname
        User user2 = new User();
        String testusername2 = 'jinyarecaiustestuser22017@jinya-toshibatest.com';
        user2.UserName = testusername2;
        user2.LastName = 'recaiustestuser2';        
        user2.Email = testusername2;
        user2.EmailPreferencesAutoBcc = true;
        user2.EmailPreferencesAutoBccStayInTouch = false;
        user2.EmailPreferencesStayInTouchReminder = true;
        user2.Alias = 'てすとです';
        user2.CommunityNickname = 'てすと2です';
        user2.IsActive = true;
        user2.TimeZoneSidKey = 'Asia/Tokyo';
        user2.LocaleSidKey = 'ja_JP';
        user2.ReceivesInfoEmails = false;
        user2.EmailEncodingKey = 'ISO-2022-JP';
        //本番環境要確認
        Profile[] profiles;
   		profiles =  [select Id From Profile where Name = '標準ユーザ' limit 1];
         if (profiles.isEmpty()){
             profiles =  [select Id From Profile where Name = 'Standard User' limit 1];
    	}
        user2.ProfileId = profiles[0].Id;        
        user2.LanguageLocaleKey = 'ja';        
        insert user2;
        return user2.Id;
    }

    public static String createUser3(){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        //test用ユーザ作成 firstname
        User user3 = new User();
        String testusername3 = 'jinyarecaiustestuser32017@jinya-toshibatest.com';
        user3.UserName = testusername3;
        user3.LastName = 'recaiustestuser3';
        user3.FirstName = 'jinyatestuser3';        
        user3.Email = testusername3;
        user3.EmailPreferencesAutoBcc = true;
        user3.EmailPreferencesAutoBccStayInTouch = false;
        user3.EmailPreferencesStayInTouchReminder = true;
        user3.Alias = 'てすとです';
        user3.CommunityNickname = 'てすと3です';
        user3.IsActive = true;
        user3.TimeZoneSidKey = 'Asia/Tokyo';
        user3.LocaleSidKey = 'ja_JP';
        user3.ReceivesInfoEmails = false;
        user3.EmailEncodingKey = 'ISO-2022-JP';
        //本番環境要確認
        Profile[] profiles;
   		profiles =  [select Id From Profile where Name = '標準ユーザ' limit 1];
         if (profiles.isEmpty()){
             profiles =  [select Id From Profile where Name = 'Standard User' limit 1];
    	}
        user3.ProfileId = profiles[0].Id;       
        user3.LanguageLocaleKey = 'ja';        
        insert user3;
        return user3.Id;
    }

    public static List<RecaiusUserInfo__c> createRecaiusUserInfo(String groupname, String groupId){
        // 2018/03/26 Package Merge Edit Begin
        CommDefine__c comdef = TestCommon.createCommDefine();
        comdef.RecaiusFlg__c = true;
        update comdef;
        // 2018/03/26 Package Merge Edit End
        List<RecaiusUserInfo__c> Ruser = new List<RecaiusUserInfo__c>();
        Ruser.add(new RecaiusUserInfo__c());
        Ruser[0].Password__c = 'pass';
        Ruser[0].contactId__c = 'FVtest';
        Ruser[0].userId__c = 'testuser';
        Ruser[0].RecaiusGroup__c = 'testgroup';
        Ruser[0].RecaiusGroup_Id__c = 123;
        Ruser[0].ChatterGroup__c = groupname;
        Ruser[0].ChatterGroup_Id__c = groupId; 
        insert Ruser;
        return Ruser;
    }

}