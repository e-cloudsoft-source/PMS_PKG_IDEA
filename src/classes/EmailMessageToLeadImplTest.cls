/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class EmailMessageToLeadImplTest {
	//private static final String mailServiceAddress = 'mailtolead@z-2nmjasfkx1m6r5pchld7j6tuv.p-hipeaa.cs31.apex.sandbox.salesforce.com';
	private static final String mailServiceAddress = 'bookingemail@0-12sqgik8q15k082q6bbk2iju37he3qbf8fk3q4qgxm4alhmw6l.d-dbjcea2.na14.apex.salesforce.com';
    static testMethod void myUnitTest1() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
        createPlanHadHoomZero('80');  
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○プラン名　(80)                                 \n'+
		'●オプション　：なし                                 \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'小学生								\n'+
		'　　(29,000円)×1名　=　29,000円								\n'+
		'小児（食事布団なし）								\n'+
		'　　(50円)×1名　=　50円							\n'+
		'小児（食事のみ）								\n'+
		'　　(30円)×1名　=　30円								\n'+
		'小児（布団のみ）								\n'+
		'　　(10円)×1名　=　10円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'合計宿泊料金入湯税:　500円								\n'+
		'合計宿泊料金サービス料:　300円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		//impl.
    }
    static testMethod void myUnitTest1_1() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc1();
        createPlanHadHoomZero('80');
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：                                                 							\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○プラン名　(80)                                 \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'【合計金額】　57,024円								\n'+
		'入湯税=150円								\n'+
		'サービス料=100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'合計宿泊料金入湯税:　500円								\n'+
		'合計宿泊料金サービス料:　300円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		//impl.
    }
    static testMethod void myUnitTest1_2() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'小学生								\n'+
		'　　(29,000円)×1名　=　29,000円								\n'+
		'小児（食事布団なし）								\n'+
		'　　(50円)×1名　=　50円							\n'+
		'小児（食事のみ）								\n'+
		'　　(30円)×1名　=　30円								\n'+
		'小児（布団のみ）								\n'+
		'　　(10円)×1名　=　10円								\n'+
		'入湯税=150円								\n'+
		'サービス料=100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'合計宿泊料金入湯税:　500円								\n'+
		'合計宿泊料金サービス料:　300円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		//impl.
    }
    static testMethod void myUnitTest1_3() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc1();
        createPlanHadHoomZero('80');
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'88							                            \n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○プラン名　(80)                                 \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'小学生								\n'+
		'　　(29,000円)×1名　=　29,000円								\n'+
		'小児（食事布団なし）								\n'+
		'　　(50円)×1名　=　50円							\n'+
		'小児（食事のみ）								\n'+
		'　　(30円)×1名　=　30円								\n'+
		'小児（布団のみ）								\n'+
		'　　(10円)×1名　=　10円								\n'+
		'【合計金額】　57,024円								\n'+
		'入湯税=150円								\n'+
		'サービス料=100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'合計宿泊料金入湯税:　500円								\n'+
		'合計宿泊料金サービス料:　300円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		//impl.
    }
    
    static testMethod void myUnitTest2() {
        // TO DO: implement unit test
        insertConfigDoc();
        insertDoc();
        createProductMst(1);
        insertCsvSetupConfig();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'=====<変更>=========＜予約変更メール＞=========<変更>=====								\n'+
		'受付時間：2015年6月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月2日(月)　12時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：WA								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン      \n'+
		'○誕生日　　　　　：1996年5月1日								\n'+
		'携帯電話番号[Mobile Phone Number]：357687967								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		
		
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		impl.handleInboundEmail(email,env);
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'####################＜キャンセルメール＞####################			\n'+
		'受付時間：2015年6月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月2日(月)　12時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：WA								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン      \n'+
		'○誕生日　　　　　：1996年5月1日								\n'+
		'携帯電話番号[Mobile Phone Number]：357687967								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		impl.handleInboundEmail(email,env);
    } 
    static testMethod void myUnitTest2_1() {
        // TO DO: implement unit test
        insertConfigDoc();
        insertDoc1();
        createProductMst(1);
        insertCsvSetupConfig();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'■■■■■■■■■■■ 66 ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'=====<変更>=========＜予約変更メール＞=========<変更>=====								\n'+
		'受付時間：2015年6月10日　17:43:51								\n'+
		'予約Ｎｏ：    								                    \n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月2日(月)　12時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：WA								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン      \n'+
		'○プラン名　(p0002)                                 \n'+
		'○誕生日　　　　　：1996年5月1日								\n'+
		'携帯電話番号[Mobile Phone Number]：357687967								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		
		
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		impl.handleInboundEmail(email,env);
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'####################＜キャンセルメール＞####################			\n'+
		'受付時間：2015年6月10日　17:43:51								\n'+
		'予約Ｎｏ：  41234325                                                 							\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月2日(月)　12時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：WA								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン112      \n'+
		'○誕生日　　　　　：1996年5月1日								\n'+
		'携帯電話番号[Mobile Phone Number]：357687967								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		impl.handleInboundEmail(email,env);
    }   
    static testMethod void myUnitTest3() {
        // TO DO: implement unit test
        insertConfigDoc();
        insertDoc();
        createProductMst(1);
        insertCsvSetupConfig();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'=====<変更>=========＜予約変更メール＞=========<変更>=====								\n'+
		'受付時間：2015年6月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月2日(月)　12時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：WA								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン      \n'+
		'○誕生日　　　　　：1996年5月1日								\n'+
		'携帯電話番号[Mobile Phone Number]：357687967								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl1 = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);

    	Test.startTest();
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl2 = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		Test.stopTest();
		//impl.
    }
    static testMethod void myUnitTest3_1() {
        // TO DO: implement unit test
        insertConfigDoc1();
        insertDoc2();
        createContact();
        createProductMst(1);
        createLead();
        insertCsvSetupConfig();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571333(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'=====<変更>=========＜予約変更メール＞=========<変更>=====								\n'+
		'受付時間：2015年6月10日　17:43:51								\n'+
		'予約Ｎｏ：(通し番号:3657412)								\n'+						
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月2日(月)　12時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：WA								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン      \n'+
		'○誕生日　　　　　：1996年5月1日								\n'+
		'携帯電話番号[Mobile Phone Number]：357687967								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl1 = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);

    	Test.startTest();
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl2 = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		Test.stopTest();
		//impl.
    }
    static testMethod void myUnitTest4() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'####################＜キャンセルメール＞####################			\n'+
		'お客様が下記の予約内容をキャンセルされましたのでご確認ください。		\n'+
		
		'キャンセル日時：2016年2月3日　17:46:13								\n'+
		'=====<変更>=========＜予約変更メール＞=========<変更>=====								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン	\n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		impl.handleInboundEmail(email,env);
		//impl.
    }
    static testMethod void myUnitTest4_1() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'====================＜新規予約メール＞====================								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300								\n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)								\n'+
		'○部屋数　　　　　：1部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン   \n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'入湯税 =　150円								\n'+
		'サービス料 = 　100円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　52,800円								\n'+
		'【消費税】4,224円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　57,024円								\n'+
		'-----------------------------------------------------------								\n';
		impl.handleInboundEmail(email,env);
		//impl.
    }
    static testMethod void myUnitTest5() {
        // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
        delete [select id from CommDefine__c];
        CommDefine__c newDef = new CommDefine__c(
	    	RoomTypeReport__c = '$0001 客室タイプ別予約表',
	    	Posreg__c = '0',
	    	UnitPriceDefKb__c = 2,
	    	ScheduleResultMailAddress__c = '1@a.com,2@b.com,3@c.com,4@d.com,5@e.com,6@f.com',
			RoomIndicatorInfoMaxLength__c = 4,
			RoomSortDiv__c = '1',
			BookingMansDef__c = 1,
			BookingFemailsDef__c = 0,
			BookingChildrenDef__c = 0,
			ShopPlanSetupFlg__c = true
		);	
        insert newDef;
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = emailIkkyu;
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		email.plainTextBody = emailPointIkyuu;
		impl.handleInboundEmail(email,env);
		//impl.
    }
    static testMethod void myUnitTest6(){
    	createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
    	EmailMessageToLeadHelp.AgtInfo currAgt = null;
    	String emailBody = '予約プロ';
    	list<EmailMessageToLeadHelp.AgtInfo> agtLst = EmailMessageToLeadHelp.getCommConfig().agtLst;
    	//AGT コードを取得
		for (EmailMessageToLeadHelp.AgtInfo agtInf : agtLst) {
			
			if (emailBody.containsIgnoreCase(agtInf.agtNm)) {
				currAgt = agtInf; 
				break;
			}
		}
		system.debug(logginglevel.info,'currAgt:::' + currAgt);
		// 機能対応対象外 // TODO
		if (currAgt != null) {
		
	    	// 取込異常の場合、メール送信して、報告する	
	        EmailMessageToLeadProcess e = new EmailMessageToLeadProcess(currAgt);
	        EmailMessageToLeadSync leadInfoToSfCtrl = new EmailMessageToLeadSync(e);
			EmailMessageToLeadParser parseXmlCtrl = new EmailMessageToLeadParser();	
	    	EmailMessageToLeadSync.BI_EMAIL_SyncInfo bookingInfo = parseXmlCtrl.parse(importXml,'02');				
			EmailMessageToLeadSync.BI_EMAIL_SyncResult syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
			String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>106535992-1</DataID>        <SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル (旧アルモニービアン）</AccommodationName>        <AccommodationCode>Y81153</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation>        <SalesOfficeCompanyName>じゃらんnet</SalesOfficeCompanyName>        <SalesOfficeName>じゃらんnet宿予約サービス</SalesOfficeName>        <SalesOfficeCode>66</SalesOfficeCode>        <SalesOfficeEmail>support@jalan.net</SalesOfficeEmail>        <SalesOfficePhoneNumber>0570-005972</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>0HVAXER7</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>15:27:26</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000013</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ｹﾞﾝ ｼﾘｭｳ _!</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>玄 志龍 _!</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-24</CheckInDate>        <CheckInTime>20:00:00</CheckInTime>        <CheckOutDate>2013-08-25</CheckOutDate>        <CheckOutTime>11:00:00</CheckOutTime>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <PackagePlanName>◇基本プラン◇【朝食付】</PackagePlanName>        <PackagePlanCode>00646064</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>ポイント利用(現:200pt)朝食付質問1：・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください(回答1：駐車場ご利用：1台Tel：09035983092)</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>9800</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>30</RoomTypeCode>                <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-24</RoomDate>                <PerPaxRate>9800</PerPaxRate>            <PerChildA70Rate>9800</PerChildA70Rate>            <PerChildA50Rate>9800</PerChildA50Rate>            <PerChildA30Rate>9800</PerChildA30Rate>            <PerChildDRate>9800</PerChildDRate>        </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 じゃらんnet                                   SNT-NET 08-16 15:27 (66) 予約番号： 0HVAXER7  NO.00000013 松本丸の内ホテル (旧アルモニービアン）様(Y81153)宿泊者情報：  玄 志龍 _!  TEL:09035983092  ｹﾞﾝ ｼﾘｭｳ _!  住所:(〒3330811)埼玉県川口市戸塚６－７－６　エスペランサ１０３  性別:        年代:35-39才予約者情報：  玄 志龍  ｹﾞﾝ ｼﾘｭｳ  Mail:ziontrek@gmail.comプラン名：◇基本プラン◇【朝食付】(00646064)2013年08月24日から    1泊  朝食付  サ込税込入込方法：                   チェックイン時間：20:00  チェックアウト時間：11:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月24日  0133893  (スタンダードダブル18㎡（禁煙）)          大人（男）     1名     @9,800                                   宿泊料金計                ：     \\9,800                       合計料金                              ：     \\9,800                       割引額(現ポイント)                    ：      \\200                     【宿泊者への請求額】                    ：     \\9,600           ---------------------------------------------------------------------ご確認事項：ポイント利用(現:200pt)朝食付質問1：・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください(回答1：駐車場ご利用：1台Tel：09035983092)取扱個所：じゃらんnet宿予約サービス(66)  TEL 0570-005972Mail support@jalan.net※「ＰＣサイト」より予約がはいりました。ご確認をお願いいたします。キャンセル□／NO SHOW□／変更□キャンセル・NO SHOW・変更が発生した場合、お手数ですが上記にチェックの上、このままFAXにてご返信ください。変更の場合は上記項目のうち変更になったもの（部屋数・人数等）を訂正の上お送り下さい。TEL 0570-005972(03-3980-2018)/FAX  0570-005973(03-3980-2032)---</TelegramData>                <PhoneNumber>09035983092</PhoneNumber>                <PostalCode>3330811</PostalCode>                <Address>埼玉県川口市戸塚６－７－６　エスペランサ１０３</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <RepresentativeGeneration>35-39才</RepresentativeGeneration>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>30</RoomTypeCode>                    <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomTypeAgent>66</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>6</NetRmTypeGroupCode>                    <PlanGroupCode>31</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-24</RoomDate>                    <PerPaxRate>9800</PerPaxRate>                    <PerMaleRate>9800</PerMaleRate>                    <PerChildA70Rate>9800</PerChildA70Rate>            <PerChildA50Rate>9800</PerChildA50Rate>            <PerChildA30Rate>9800</PerChildA30Rate>            <PerChildDRate>9800</PerChildDRate>                <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>玄 志龍</UserName>                <UserKana>ｹﾞﾝ ｼﾘｭｳ</UserKana>                <UserMailAddr>ziontrek@gmail.com</UserMailAddr>            </Member>            <OtherInfo>                <GuestRequest>ポイント利用(現:200pt)朝食付</GuestRequest>                <QuestionAndAnswerList>                    <QuestionToGuest>・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください</QuestionToGuest>                    <AnswerToHotel>駐車場ご利用：1台Tel：09035983092</AnswerToHotel>                </QuestionAndAnswerList>            </OtherInfo>            <BasicRate>                <TotalAccomodationServiceCharge>0</TotalAccomodationServiceCharge>                <PointsDiscountList>                    <PointsDiv>2</PointsDiv>                    <PointsDiscountName>現ポイント</PointsDiscountName>                    <PointsDiscount>200</PointsDiscount>                </PointsDiscountList>            </BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <PointDiv>エージェント原資</PointDiv>                <PointName>現ポイント</PointName>                <Points>200</Points>                <TotalAccommodationDecleasePoints>9600</TotalAccommodationDecleasePoints>                <TotalAccommodationConsumptionTax>0</TotalAccommodationConsumptionTax>                <AmountClaimed>9600</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
        	//1-1
        	bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');
        	syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
        	Test.startTest();
        	//1-2
        	infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID>106557046-1</DataID>        <SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル</AccommodationName>        <AccommodationCode>00001782</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation>        <SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>        <SalesOfficeName>株式会社一休</SalesOfficeName>        <SalesOfficeCode>001</SalesOfficeCode>        <SalesOfficePhoneNumber>03-6685-0065</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>IK0144977541</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>20:55:14</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000003</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾉﾑﾗ ｶｽﾞﾕｷ</GuestOrGroupNameSingleByte>        <GuestOrGroupNameDoubleByte>のむら かずゆき</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>野村 豊幸</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-18</CheckInDate>        <CheckInTime>15:00:00</CheckInTime>        <CheckOutDate>2013-08-19</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <TotalPaxFemaleCount>0</TotalPaxFemaleCount>        <TotalChildA70Count>0</TotalChildA70Count>        <TotalChildB50Count>0</TotalChildB50Count>        <TotalChildC30Count>0</TotalChildC30Count>        <TotalChildDNoneCount>0</TotalChildDNoneCount>        <PackagePlanName>ビジネス応援「ゆったりデラックス」素泊まり</PackagePlanName>        <PackagePlanCode>bien14</PackagePlanCode>        <MealCondition>WithoutMeal</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>支払い方法：現払い食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <Payment>Cash</Payment>        <TotalAccommodationCharge>8000</TotalAccommodationCharge>        <TotalAccommodationHotSpringTax>0</TotalAccommodationHotSpringTax>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>20</RoomTypeCode>                <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                <RoomChildA70Count>0</RoomChildA70Count>                <RoomChildB50Count>0</RoomChildB50Count>                <RoomChildC30Count>0</RoomChildC30Count>                <RoomChildDNoneCount>0</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-18</RoomDate>                <PerPaxRate>8000</PerPaxRate>                <PerChildA70Rate>8000</PerChildA70Rate>                <PerChildB50Rate>1</PerChildB50Rate>                <PerChildC30Rate>8000</PerChildC30Rate>                <PerChildDRate>8000</PerChildDRate>                <TotalPerRoomRate>8000</TotalPerRoomRate>                <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 一休.com                                      SNT-NET 08-16 20:56 (80) 予約番号： IK0144977541  NO.00000003 松本丸の内ホテル様(00001782)宿泊者情報：  野村 豊幸  TEL:0423241785  ﾉﾑﾗ ｶｽﾞﾕｷ  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男        年代:40代        年齢:予約者情報：  野村 豊幸  のむら かずゆき  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男                     生年月日:  会員種別:会員               メルマガ希望:プラン名：ビジネス応援「ゆったりデラックス」素泊まり(bien14)2013年08月18日から    1泊  ＲＣ  サ込税込入込方法：                   チェックイン時間：15:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月18日  dsn  (デラックスシングル（禁煙）(シングル))  @8,000          大人（男）     1名                                   宿泊料金計                ：     \\8,000                       合計料金                              ：     \\8,000                     【宿泊者への請求額】                    ：     \\8,000           ---------------------------------------------------------------------支払い方法  ：現払いご確認事項：食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B取扱個所：株式会社一休(001)  TEL 03-6685-0065  FAX 03-6234-8921会員番号：01006096---</TelegramData>                <PhoneNumber>0423241785</PhoneNumber>                <PostalCode>185-0023</PostalCode>                <Address>東京都 国分寺市 西元町　2-11-7</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <BranchFaxNumber>03-6234-8921</BranchFaxNumber>                <Version>2.0</Version>                <RepresentativePhoneType>2</RepresentativePhoneType>                <RepresentativeGeneration>40代</RepresentativeGeneration>                <RepresentativeGendar>0</RepresentativeGendar>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>1</UseDiv>            </Allotment>  <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>特選会席料理</Name>                <OptionCount>4</OptionCount>                <OptionRate>12000</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（陣屋どらやき　6個入）</Name>                <OptionCount>1</OptionCount>                <OptionRate>960</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 10枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>1575</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 20枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>3150</OptionRate>            </Option>          <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>20</RoomTypeCode>                    <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                    <RoomChildA70Count>0</RoomChildA70Count>                    <RoomChildB50Count>0</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomTypeAgent>80</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>4</NetRmTypeGroupCode>                    <PlanGroupCode>18</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-18</RoomDate>                    <PerPaxRate>8000</PerPaxRate>                    <PerChildA70Rate>8000</PerChildA70Rate>                    <PerChildB50Rate>8000</PerChildB50Rate>                    <PerChildC30Rate>8000</PerChildC30Rate>                    <PerChildDRate>8000</PerChildDRate>                    <TotalPerRoomRate>8000</TotalPerRoomRate>                    <PerMaleRate>8000</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>0</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                     <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>野村 豊幸</UserName>                <UserKana>のむら かずゆき</UserKana>                <UserZip>185-0023</UserZip>                <UserAddr>東京都 国分寺市 西元町　2-11-7</UserAddr>                <UserID>01006096</UserID>                <UserType>会員</UserType>                <UserGendar>0</UserGendar>            </Member>            <OtherInfo>                <GuestRequest>食事なし禁煙ルームをお願いします</GuestRequest>                <AdditionalInformation>質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</AdditionalInformation>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <TotalAccommodationDecleasePoints>8000</TotalAccommodationDecleasePoints>                <AmountClaimed>8000</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
        	bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');
        	syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
        	//1-3
        	infoTravelXML = '<?xmlversion="1.0"encoding="UTF-8"standalone="yes"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>101731864-1</DataID><SystemDate>2013-07-09</SystemDate></TransactionType><AccommodationInformation><AccommodationName>元湯陣屋</AccommodationName><AccommodationCode>14000010</AccommodationCode></AccommodationInformation><SalesOfficeInformation><SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName><SalesOfficeName>予約プロ</SalesOfficeName><SalesOfficeCode>88</SalesOfficeCode><SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate><TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime><TravelAgencyReportNumber>00000051</TravelAgencyReportNumber><GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ_</GuestOrGroupNameSingleByte><GuestOrGroupNameKanjiName>テスト予約No.2013/07/09_</GuestOrGroupNameKanjiName><CheckInDate>2013-07-22</CheckInDate><CheckInTime>15:30:00</CheckInTime><CheckOutDate>2013-07-25</CheckOutDate><Nights>3</Nights><TotalRoomCount>2</TotalRoomCount><GrandTotalPaxCount>14</GrandTotalPaxCount><TotalPaxMaleCount>2</TotalPaxMaleCount><TotalPaxFemaleCount>2</TotalPaxFemaleCount><TotalChildA70Count>2</TotalChildA70Count><TotalChildB50Count>4</TotalChildB50Count><TotalChildC30Count>2</TotalChildC30Count><TotalChildDNoneCount>2</TotalChildDNoneCount><PackagePlanName>【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！</PackagePlanName><PackagePlanCode>3333</PackagePlanCode><MealCondition>1nightBreakfast</MealCondition><SpecificMealCondition>NoneSpecified</SpecificMealCondition><OtherServiceInformation>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</OtherServiceInformation></BasicInformation><BasicRateInformation><RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate><TaxServiceFee>IncludingServiceAndTax</TaxServiceFee><TotalAccommodationCharge>429135</TotalAccommodationCharge></BasicRateInformation><RoomAndGuestInformation><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList></RoomAndGuestInformation><RisaplsInformation><RisaplsCommonInformation><Basic><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><TelegramDiv></TelegramDiv><RisaplsDataID></RisaplsDataID><RisaplsTelegramNumber></RisaplsTelegramNumber>';
	        infoTravelXML += '<TelegramData>予約通知予約プロSNT-NET07-0923:49(88)予約番号：A001781590NO.00000051元湯陣屋様(14000010)宿泊者情報：テスト予約No.2013/07/09_TEL:01-2345-6789ﾃｽﾄﾖﾔｸ_Mail:hiroyuki_morimoto@jinya-inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北プラン名：【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！(185)2013年07月22日から3泊朝食付サ込税込入込方法：チェックイン時間：15:30人員総数：14人内訳：(男)2名+(女)2名+(Ａ)2名+(Ｂ)4名+(Ｃ)2名+(Ｄ)2名客室総数：2室07月22日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月23日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月24日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）宿泊料金計：\\366,000オプション：07月22日特選会席料理4個@12,000お土産（陣屋どらやき　6個入）1個@960お土産（やまと豚の桜味噌漬け13個@1,575お土産（やまと豚の桜味噌漬け23個@3,150 オプション料金計：\\63,135合計料金：\\429,135【宿泊者への請求額】：\\429,135---------------------------------------------------------------------ご確認事項：○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため取扱個所：予約プロ(88)TEL052-262-8041FAX052-262-8042---</TelegramData><PhoneNumber>01-2345-6789</PhoneNumber><Email>hiroyuki_morimoto@jinya-inn.com</Email>';
	        infoTravelXML += '<PostalCode>257-0001</PostalCode><Address>神奈川県秦野市鶴巻北</Address><TotalPaxManCount>4</TotalPaxManCount><BranchFaxNumber>052-262-8042</BranchFaxNumber><Version>2.0</Version><AccommodationId>X36969</AccommodationId></Basic><Allotment><AssignDiv>1</AssignDiv><GenderDiv>1</GenderDiv><HandleDiv>1</HandleDiv><RsvUserDiv>0</RsvUserDiv><UseDiv>0</UseDiv></Allotment><Option><OptionDate>2013-07-22</OptionDate><OptionCode>33</OptionCode><Name>特選会席料理</Name><OptionCount>4</OptionCount><OptionRate>12000</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（陣屋どらやき　6個入）</Name><OptionCount>1</OptionCount><OptionRate>960</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け10枚入）</Name><OptionCount>3</OptionCount><OptionRate>1575</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け20枚入）</Name><OptionCount>3</OptionCount><OptionRate>3150</OptionRate></Option><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>';
	        infoTravelXML += '<RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><OtherInfo><GuestRequest>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</GuestRequest></OtherInfo></RisaplsCommonInformation><AgentNativeInformation><Extend><AmountClaimed>429135</AmountClaimed></Extend><Extendmytrip><SettlementDiv>4</SettlementDiv></Extendmytrip></AgentNativeInformation></RisaplsInformation></AllotmentBookingReport>';

        	bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');
        	syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
        	Test.stopTest();
		}
    }
    static testMethod void myUnitTest6_1(){
    	createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
    	EmailMessageToLeadHelp.AgtInfo currAgt = null;
    	String emailBody = '予約プロ';
    	list<EmailMessageToLeadHelp.AgtInfo> agtLst = EmailMessageToLeadHelp.getCommConfig().agtLst;
    	//AGT コードを取得
		for (EmailMessageToLeadHelp.AgtInfo agtInf : agtLst) {
			
			if (emailBody.containsIgnoreCase(agtInf.agtNm)) {
				currAgt = agtInf; 
				break;
			}
		}
		system.debug(logginglevel.info,'currAgt:::' + currAgt);
		// 機能対応対象外 // TODO
		if (currAgt != null) {
		
	    	// 取込異常の場合、メール送信して、報告する	
	        EmailMessageToLeadProcess e = new EmailMessageToLeadProcess(currAgt);
	        EmailMessageToLeadSync leadInfoToSfCtrl = new EmailMessageToLeadSync(e);
			EmailMessageToLeadParser parseXmlCtrl = new EmailMessageToLeadParser();	
	    	EmailMessageToLeadSync.BI_EMAIL_SyncInfo bookingInfo = parseXmlCtrl.parse(importXml,'02');				
			EmailMessageToLeadSync.BI_EMAIL_SyncResult syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
			String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID></DataID>        <SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル (旧アルモニービアン）</AccommodationName>        <AccommodationCode>Y81153</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation>        <SalesOfficeCompanyName>じゃらんnet</SalesOfficeCompanyName>        <SalesOfficeName>株式会社一休</SalesOfficeName>        <SalesOfficeCode>80</SalesOfficeCode>        <SalesOfficeEmail>support@jalan.net</SalesOfficeEmail>        <SalesOfficePhoneNumber>0570-005972</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>0HVAXER7</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>15:27:26</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000013</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ｹﾞﾝ ｼﾘｭｳ _!</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>玄 志龍 _!</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-24</CheckInDate>        <CheckInTime>20:00:00</CheckInTime>        <CheckOutDate>2013-08-25</CheckOutDate>        <CheckOutTime>11:00:00</CheckOutTime>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <PackagePlanName></PackagePlanName>        <PackagePlanCode></PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>ポイント利用(現:200pt)朝食付質問1：・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください(回答1：駐車場ご利用：1台Tel：09035983092)</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>9800</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>30</RoomTypeCode>                <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-24</RoomDate>                <PerPaxRate>9800</PerPaxRate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 じゃらんnet                                   SNT-NET 08-16 15:27 (66) 予約番号： 0HVAXER7  NO.00000013 松本丸の内ホテル (旧アルモニービアン）様(Y81153)宿泊者情報：  玄 志龍 _!  TEL:09035983092  ｹﾞﾝ ｼﾘｭｳ _!  住所:(〒3330811)埼玉県川口市戸塚６－７－６　エスペランサ１０３  性別:        年代:35-39才予約者情報：  玄 志龍  ｹﾞﾝ ｼﾘｭｳ  Mail:ziontrek@gmail.comプラン名：◇基本プラン◇【朝食付】(00646064)2013年08月24日から    1泊  朝食付  サ込税込入込方法：                   チェックイン時間：20:00  チェックアウト時間：11:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月24日  0133893  (スタンダードダブル18㎡（禁煙）)          大人（男）     1名     @9,800                                   宿泊料金計                ：     \\9,800                       合計料金                              ：     \\9,800                       割引額(現ポイント)                    ：      \\200                     【宿泊者への請求額】                    ：     \\9,600           ---------------------------------------------------------------------ご確認事項：ポイント利用(現:200pt)朝食付質問1：・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください(回答1：駐車場ご利用：1台Tel：09035983092)取扱個所：じゃらんnet宿予約サービス(66)  TEL 0570-005972Mail support@jalan.net※「ＰＣサイト」より予約がはいりました。ご確認をお願いいたします。キャンセル□／NO SHOW□／変更□キャンセル・NO SHOW・変更が発生した場合、お手数ですが上記にチェックの上、このままFAXにてご返信ください。変更の場合は上記項目のうち変更になったもの（部屋数・人数等）を訂正の上お送り下さい。TEL 0570-005972(03-3980-2018)/FAX  0570-005973(03-3980-2032)---</TelegramData>                <PhoneNumber>09035983092</PhoneNumber>                <PostalCode>3330811</PostalCode>                <Address>埼玉県川口市戸塚６－７－６　エスペランサ１０３</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <Version>2.0</Version>                <RepresentativeGeneration>35-39才</RepresentativeGeneration>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>30</RoomTypeCode>                    <RoomTypeName>スタンダードダブル18㎡（禁煙）</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomTypeAgent>66</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>6</NetRmTypeGroupCode>                    <PlanGroupCode>31</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-24</RoomDate>                    <PerPaxRate>9800</PerPaxRate>                    <PerMaleRate>9800</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>玄 志龍</UserName>                <UserKana>ｹﾞﾝ ｼﾘｭｳ</UserKana>                <UserMailAddr>ziontrek@gmail.com</UserMailAddr>            </Member>            <OtherInfo>                <GuestRequest>ポイント利用(現:200pt)朝食付</GuestRequest>                <QuestionAndAnswerList>                    <QuestionToGuest>・駐車場ご利用のお客様はこちらに必要台数をご記入ください・専用駐車場が満車の場合、近隣の提携駐車場へのご案内となる場合があります・チェックイン時間がご予定より大幅に遅れられる場合は、ご連絡ください・当日お客様と連絡が取れる電話番号（携帯番号など）をお教えください</QuestionToGuest>                    <AnswerToHotel>駐車場ご利用：1台Tel：09035983092</AnswerToHotel>                </QuestionAndAnswerList>            </OtherInfo>            <BasicRate>                <TotalAccomodationServiceCharge>0</TotalAccomodationServiceCharge>                <PointsDiscountList>                    <PointsDiv>2</PointsDiv>                    <PointsDiscountName>現ポイント</PointsDiscountName>                    <PointsDiscount>200</PointsDiscount>                </PointsDiscountList>            </BasicRate>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <PointDiv>エージェント原資</PointDiv>                <PointName>現ポイント</PointName>                <Points>200</Points>                <TotalAccommodationDecleasePoints>9600</TotalAccommodationDecleasePoints>                <TotalAccommodationConsumptionTax>0</TotalAccommodationConsumptionTax>                <AmountClaimed>9600</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
        	//1-1
        	bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');
        	syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
        	Test.startTest();
        	//1-2
        	infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>NewBookReport</DataClassification>        <DataID></DataID>        <SystemDate>2013-08-23</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>松本丸の内ホテル</AccommodationName>        <AccommodationCode>00001782</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation>        <SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>        <SalesOfficeName>株式会社一休</SalesOfficeName>        <SalesOfficeCode>80</SalesOfficeCode>        <SalesOfficePhoneNumber>03-6685-0065</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>IK0144977541</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-08-16</TravelAgencyBookingDate>        <TravelAgencyBookingTime>20:55:14</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000003</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾉﾑﾗ ｶｽﾞﾕｷ</GuestOrGroupNameSingleByte>        <GuestOrGroupNameDoubleByte>のむら かずゆき</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>野村 豊幸</GuestOrGroupNameKanjiName>        <CheckInDate>2013-08-18</CheckInDate>        <CheckInTime>15:00:00</CheckInTime>        <CheckOutDate>2013-08-19</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>1</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <TotalPaxFemaleCount>0</TotalPaxFemaleCount>        <TotalChildA70Count>0</TotalChildA70Count>        <TotalChildB50Count>0</TotalChildB50Count>        <TotalChildC30Count>0</TotalChildC30Count>        <TotalChildDNoneCount>0</TotalChildDNoneCount>        <PackagePlanName></PackagePlanName>        <PackagePlanCode></PackagePlanCode>        <MealCondition>WithoutMeal</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>支払い方法：現払い食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <Payment>Cash</Payment>        <TotalAccommodationCharge>8000</TotalAccommodationCharge>        <TotalAccommodationHotSpringTax>0</TotalAccommodationHotSpringTax>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>20</RoomTypeCode>                <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                <PerRoomPaxCount>1</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                <RoomChildA70Count>0</RoomChildA70Count>                <RoomChildB50Count>0</RoomChildB50Count>                <RoomChildC30Count>0</RoomChildC30Count>                <RoomChildDNoneCount>0</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-08-18</RoomDate>                <PerPaxRate>8000</PerPaxRate>                <PerChildA70Rate>0</PerChildA70Rate>                <PerChildB50Rate>0</PerChildB50Rate>                <PerChildC30Rate>0</PerChildC30Rate>                <PerChildDRate>0</PerChildDRate>                <TotalPerRoomRate>8000</TotalPerRoomRate>                <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>予約通知 一休.com                                      SNT-NET 08-16 20:56 (80) 予約番号： IK0144977541  NO.00000003 松本丸の内ホテル様(00001782)宿泊者情報：  野村 豊幸  TEL:0423241785  ﾉﾑﾗ ｶｽﾞﾕｷ  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男        年代:40代        年齢:予約者情報：  野村 豊幸  のむら かずゆき  住所:(〒185-0023)東京都 国分寺市 西元町　2-11-7  性別:男                     生年月日:  会員種別:会員               メルマガ希望:プラン名：ビジネス応援「ゆったりデラックス」素泊まり(bien14)2013年08月18日から    1泊  ＲＣ  サ込税込入込方法：                   チェックイン時間：15:00人員総数：   1人  内訳：(男)1名客室総数：   1室08月18日  dsn  (デラックスシングル（禁煙）(シングル))  @8,000          大人（男）     1名                                   宿泊料金計                ：     \\8,000                       合計料金                              ：     \\8,000                     【宿泊者への請求額】                    ：     \\8,000           ---------------------------------------------------------------------支払い方法  ：現払いご確認事項：食事なし禁煙ルームをお願いします質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B取扱個所：株式会社一休(001)  TEL 03-6685-0065  FAX 03-6234-8921会員番号：01006096---</TelegramData>                <PhoneNumber>0423241785</PhoneNumber>                <PostalCode>185-0023</PostalCode>                <Address>東京都 国分寺市 西元町　2-11-7</Address>                <TotalPaxManCount>1</TotalPaxManCount>                <BranchFaxNumber>03-6234-8921</BranchFaxNumber>                <Version>2.0</Version>                <RepresentativePhoneType>2</RepresentativePhoneType>                <RepresentativeGeneration>40代</RepresentativeGeneration>                <RepresentativeGendar>0</RepresentativeGendar>                <AccommodationId>G66249</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>0</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>1</RsvUserDiv>                <UseDiv>1</UseDiv>            </Allotment>  <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>特選会席料理</Name>                <OptionCount>4</OptionCount>                <OptionRate>12000</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（陣屋どらやき　6個入）</Name>                <OptionCount>1</OptionCount>                <OptionRate>960</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 10枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>1575</OptionRate>            </Option>            <Option>                <OptionDate>2013-07-22</OptionDate>                <Name>お土産（やまと豚の桜味噌漬け 20枚入）</Name>                <OptionCount>3</OptionCount>                <OptionRate>3150</OptionRate>            </Option>          <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>20</RoomTypeCode>                    <RoomTypeName>デラックスシングル（禁煙）(シングル)</RoomTypeName>                    <PerRoomPaxCount>1</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>0</RoomPaxFemaleCount>                    <RoomChildA70Count>0</RoomChildA70Count>                    <RoomChildB50Count>0</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomTypeAgent>80</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>4</NetRmTypeGroupCode>                    <PlanGroupCode>18</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-08-18</RoomDate>                    <PerPaxRate>8000</PerPaxRate>                    <PerChildA70Rate>0</PerChildA70Rate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <PerChildC30Rate>0</PerChildC30Rate>                    <PerChildDRate>0</PerChildDRate>                    <TotalPerRoomRate>8000</TotalPerRoomRate>                    <PerMaleRate>8000</PerMaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>0</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>0</RoomRateChildA70Count>                    <RoomRateChildB50Count>0</RoomRateChildB50Count>                    <RoomRateChildC30Count>0</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>0</RoomRateChildDNoneCount>                     <TotalRoomHotSpringTax>100</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>500</TotalPerRoomServiceFee>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <Member>                <UserName>野村 豊幸</UserName>                <UserKana>のむら かずゆき</UserKana>                <UserZip>185-0023</UserZip>                <UserAddr>東京都 国分寺市 西元町　2-11-7</UserAddr>                <UserID>01006096</UserID>                <UserType>会員</UserType>                <UserGendar>1</UserGendar>            </Member>            <OtherInfo>                <GuestRequest>食事なし禁煙ルームをお願いします</GuestRequest>                <AdditionalInformation>質問1:駐車場ご利用の場合はAとお車の台数を、ご利用のない場合はBとご記入ください。回答1:B</AdditionalInformation>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <TotalAccommodationDecleasePoints>8000</TotalAccommodationDecleasePoints>                <AmountClaimed>8000</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>0</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
        	bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');
        	syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
        	//1-3
        	infoTravelXML = '<?xmlversion="1.0"encoding="UTF-8"standalone="yes"?><AllotmentBookingReport><TransactionType><DataFrom>FromTravelAgency</DataFrom><DataClassification>NewBookReport</DataClassification><DataID>101731864-1</DataID><SystemDate>2013-07-09</SystemDate></TransactionType><AccommodationInformation><AccommodationName>元湯陣屋</AccommodationName><AccommodationCode>14000010</AccommodationCode></AccommodationInformation><SalesOfficeInformation><SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName><SalesOfficeName>予約プロ</SalesOfficeName><SalesOfficeCode>88</SalesOfficeCode><SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber></SalesOfficeInformation><BasicInformation><TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber><TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate><TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime><TravelAgencyReportNumber>00000051</TravelAgencyReportNumber><GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ_</GuestOrGroupNameSingleByte><GuestOrGroupNameKanjiName>テスト予約No.2013/07/09_</GuestOrGroupNameKanjiName><CheckInDate>2013-07-22</CheckInDate><CheckInTime>15:30:00</CheckInTime><CheckOutDate>2013-07-25</CheckOutDate><Nights>3</Nights><TotalRoomCount>2</TotalRoomCount><GrandTotalPaxCount>14</GrandTotalPaxCount><TotalPaxMaleCount>2</TotalPaxMaleCount><TotalPaxFemaleCount>2</TotalPaxFemaleCount><TotalChildA70Count>2</TotalChildA70Count><TotalChildB50Count>4</TotalChildB50Count><TotalChildC30Count>2</TotalChildC30Count><TotalChildDNoneCount>2</TotalChildDNoneCount><PackagePlanName></PackagePlanName><PackagePlanCode></PackagePlanCode><MealCondition>1nightBreakfast</MealCondition><SpecificMealCondition>NoneSpecified</SpecificMealCondition><OtherServiceInformation>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</OtherServiceInformation></BasicInformation><BasicRateInformation><RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate><TaxServiceFee>IncludingServiceAndTax</TaxServiceFee><TotalAccommodationCharge>429135</TotalAccommodationCharge></BasicRateInformation><RoomAndGuestInformation><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>2</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList><RoomAndGuestList><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>1</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate></RoomRateInformation></RoomAndGuestList></RoomAndGuestInformation><RisaplsInformation><RisaplsCommonInformation><Basic><SalesOfficeCompanyCode>88</SalesOfficeCompanyCode><TelegramDiv></TelegramDiv><RisaplsDataID></RisaplsDataID><RisaplsTelegramNumber></RisaplsTelegramNumber>';
	        infoTravelXML += '<TelegramData>予約通知予約プロSNT-NET07-0923:49(88)予約番号：      宿泊者情報：テスト予約No.2013/07/09_TEL:01-2345-6789ﾃｽﾄﾖﾔｸ_Mail:hiroyuki_morimoto@jinya-inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北inn.com住所:(〒257-0001)神奈川県秦野市鶴巻北プラン名：【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！(185)2013年07月22日から3泊朝食付サ込税込入込方法：チェックイン時間：15:30人員総数：14人内訳：(男)2名+(女)2名+(Ａ)2名+(Ｂ)4名+(Ｃ)2名+(Ｄ)2名客室総数：2室07月22日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月23日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）07月24日24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）24(純和風客室(バスルーム無し))大人（男）1名@12,000大人（女）1名@12,000子供Ａ1名@12,000小学生子供Ｂ1名@12,000小児（食事布団あり）子供Ｂ1名@0小児（食事布団なし）子供Ｃ1名@3,000小児（食事のみ）子供Ｄ1名@10,000小児（布団のみ）宿泊料金計：\\366,000オプション：07月22日特選会席料理4個@12,000お土産（陣屋どらやき　6個入）1個@960お土産（やまと豚の桜味噌漬け13個@1,575お土産（やまと豚の桜味噌漬け23個@3,150 オプション料金計：\\63,135合計料金：\\429,135【宿泊者への請求額】：\\429,135---------------------------------------------------------------------ご確認事項：○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため取扱個所：予約プロ(88)TEL052-262-8041FAX052-262-8042---</TelegramData><PhoneNumber>01-2345-6789</PhoneNumber><Email>hiroyuki_morimoto@jinya-inn.com</Email>';
	        infoTravelXML += '<PostalCode>257-0001</PostalCode><Address>神奈川県秦野市鶴巻北</Address><TotalPaxManCount>4</TotalPaxManCount><BranchFaxNumber>052-262-8042</BranchFaxNumber><Version>2.0</Version><AccommodationId>X36969</AccommodationId></Basic><Allotment><AssignDiv>1</AssignDiv><GenderDiv>1</GenderDiv><HandleDiv>1</HandleDiv><RsvUserDiv>0</RsvUserDiv><UseDiv>0</UseDiv></Allotment><Option><OptionDate>2013-07-22</OptionDate><OptionCode>33</OptionCode><Name>特選会席料理</Name><OptionCount>4</OptionCount><OptionRate>12000</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（陣屋どらやき　6個入）</Name><OptionCount>1</OptionCount><OptionRate>960</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け10枚入）</Name><OptionCount>3</OptionCount><OptionRate>1575</OptionRate></Option><Option><OptionDate>2013-07-22</OptionDate><Name>お土産（やまと豚の桜味噌漬け20枚入）</Name><OptionCount>3</OptionCount><OptionRate>3150</OptionRate></Option><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>';
	        infoTravelXML += '<RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-22</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-23</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><RoomAndRoomRateInformation><RoomInformation><RoomTypeCode>1</RoomTypeCode><RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName><PerRoomPaxCount>7</PerRoomPaxCount><RoomPaxMaleCount>1</RoomPaxMaleCount><RoomPaxFemaleCount>1</RoomPaxFemaleCount><RoomChildA70Count>1</RoomChildA70Count><RoomChildB50Count>2</RoomChildB50Count><RoomChildC30Count>1</RoomChildC30Count><RoomChildDNoneCount>1</RoomChildDNoneCount><RoomChildA70Request>小学生</RoomChildA70Request><RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request><RoomChildC30Request>小児（食事のみ）</RoomChildC30Request><RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest><RoomTypeAgent>88</RoomTypeAgent><RoomFrame>--</RoomFrame><NetRmTypeGroupCode>49</NetRmTypeGroupCode><PlanGroupCode>---</PlanGroupCode></RoomInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerPaxRate>12000</PerPaxRate><PerChildA70Rate>12000</PerChildA70Rate><PerChildB50Rate>12000</PerChildB50Rate><PerChildC30Rate>3000</PerChildC30Rate><PerChildDRate>10000</PerChildDRate><TotalRoomHotSpringTax>0</TotalRoomHotSpringTax><TotalPerRoomServiceFee>0</TotalPerRoomServiceFee><PerMaleRate>12000</PerMaleRate><PerFemaleRate>12000</PerFemaleRate><RoomRatePaxMaleCount>1</RoomRatePaxMaleCount><RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount><RoomRateChildA70Count>1</RoomRateChildA70Count><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildC30Count>1</RoomRateChildC30Count><RoomRateChildDNoneCount>1</RoomRateChildDNoneCount><RoomRateChildA70Request>小学生</RoomRateChildA70Request><RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request><RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request><RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest></RoomRateInformation><RoomRateInformation><RoomDate>2013-07-24</RoomDate><PerChildB50Rate>0</PerChildB50Rate><RoomRateChildB50Count>1</RoomRateChildB50Count><RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request></RoomRateInformation></RoomAndRoomRateInformation><OtherInfo><GuestRequest>○携帯電話番号[MobilePhoneNumber]：00-2345-6789○ご要望・ご質問：NroomsNnightsのテストのため</GuestRequest></OtherInfo></RisaplsCommonInformation><AgentNativeInformation><Extend><AmountClaimed>429135</AmountClaimed></Extend><Extendmytrip><SettlementDiv>4</SettlementDiv></Extendmytrip></AgentNativeInformation></RisaplsInformation></AllotmentBookingReport>';

        	bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');
        	syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
        	Test.stopTest();
		}
    }
    static testMethod void myUnitTest7(){
    	 // TO DO: implement unit test
        createProductMst(1);
        insertCsvSetupConfig();
        insertOtherConfigDoc();
        createContact();
        insertDoc();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = '【新規.A00264245】2010/11/04(Thu)[2名1部屋：1泊]Edgar Lewis';
// Create the plainTextBody and fromAddres for the test
    	email.plainTextBody = '■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■' + '\n' +
		'■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■								\n'+
		'※このメールをそのまま返信されても、ご予約者様には届きません。								\n'+
		'　このメールをご予約者様に返信される場合は、下記メールに記載されております、								\n'+
		'　【メールアドレス】を宛先欄に入力した上で、ご送信ください。								\n'+
		'								\n'+
		'####################＜キャンセルメール＞####################			\n'+
		'お客様が下記の予約内容をキャンセルされましたのでご確認ください。		\n'+
		
		'キャンセル日時：2016年2月3日　17:46:13								\n'+
		'=====<変更>=========＜予約変更メール＞=========<変更>=====								\n'+
		'受付時間：2015年12月10日　17:43:51								\n'+
		'予約Ｎｏ：A005429571(通し番号:3657)								\n'+
		'【宿泊代表者氏名】テスト　井桁かおる 様　(てすと　いげたかおる)								\n'+
		'【電話番号】0463771300 \n'+
		'【メールアドレス】info@jinya-inn.com								\n'+
		'【住所】〒257-0001 神奈川県秦野市鶴巻北2-8-24								\n'+
		'								\n'+
		'○ご利用日時　　　：2016年2月1日(月)　11時30分								\n'+
		'○部屋数　　　　　：2部屋								\n'+
		'○部屋タイプ　　　：貴賓会席(レストラン)								\n'+
		'○プラン名　　　　：日帰り温泉入浴とレストランでのお食事プラン	\n'+
		'○誕生日　　　　　：未回答								\n'+
		'携帯電話番号[Mobile Phone Number]：								\n'+
		'レストラン利用のご案内：								\n'+
		'　※予約フォームはシステムの関係上部屋数の選択となっておりますが、								\n'+
		'　正しくはレストランの席をご用意するものです。								\n'+
		'　個室でのご用意ではありません。								\n'+
		'-----------------------------------------------------------								\n'+
		'<料金明細>								\n'+
		'-----------------------------------------------------------								\n'+
		'■1部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'■2部屋目：								\n'+
		'【大人】2名　　(男性:1名　女性:1名)								\n'+
		'　　(26,400円)×2名　=　52,800円								\n'+
		'----------------------------------------								\n'+
		'【小計金額】　105,600円								\n'+
		'【消費税】8,448円								\n'+
		'----------------------------------------								\n'+
		'【合計金額】　97,152円								\n'+
		'-----------------------------------------------------------								\n';
		env.toAddress = mailServiceAddress;
		email.fromAddress ='testmail00001@gmail.com';
		EmailMessageToLeadImpl impl = new EmailMessageToLeadImpl();
		impl.handleInboundEmail(email,env);
		
    }
    static testMethod void myUnitTest8(){
    	createProductMst(1);
        insertCsvSetupConfig();
        insertConfigDoc();
        insertDoc();
    	EmailMessageToLeadHelp.AgtInfo currAgt = null;
    	String emailBody = '予約プロ';
    	list<EmailMessageToLeadHelp.AgtInfo> agtLst = EmailMessageToLeadHelp.getCommConfig().agtLst;
    	//AGT コードを取得
		for (EmailMessageToLeadHelp.AgtInfo agtInf : agtLst) {
			
			if (emailBody.containsIgnoreCase(agtInf.agtNm)) {
				currAgt = agtInf; 
				break;
			}
		}
		system.debug(logginglevel.info,'currAgt:::' + currAgt);
		// 機能対応対象外 // TODO
		if (currAgt != null) {
			String infoTravelXML = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>ModificationReport</DataClassification>        <DataID>101731864-2</DataID>        <SystemDate>2013-07-09</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>元湯陣屋</AccommodationName>        <AccommodationCode>14000010</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation>        <SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>        <SalesOfficeName>予約プロ</SalesOfficeName>        <SalesOfficeCode>88</SalesOfficeCode>        <SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>A001781590</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2013-07-09</TravelAgencyBookingDate>        <TravelAgencyBookingTime>23:47:14</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00000051</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ﾃｽﾄﾖﾔｸ _</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>テスト予約No. 2013/07/09 _</GuestOrGroupNameKanjiName>        <CheckInDate>2013-07-22</CheckInDate>        <CheckInTime>15:30:00</CheckInTime>        <CheckOutDate>2013-07-23</CheckOutDate>        <Nights>1</Nights>        <TotalRoomCount>2</TotalRoomCount>        <GrandTotalPaxCount>14</GrandTotalPaxCount>        <TotalPaxMaleCount>2</TotalPaxMaleCount>        <TotalPaxFemaleCount>2</TotalPaxFemaleCount>        <TotalChildA70Count>2</TotalChildA70Count>        <TotalChildB50Count>4</TotalChildB50Count>        <TotalChildC30Count>2</TotalChildC30Count>        <TotalChildDNoneCount>2</TotalChildDNoneCount>        <PackagePlanName>【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！</PackagePlanName>        <PackagePlanCode>186</PackagePlanCode>        <MealCondition>1nightBreakfast</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <OtherServiceInformation>○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>WithoutSerivceAndTax</TaxServiceFee>        <TotalAccommodationCharge>429135</TotalAccommodationCharge>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>7</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>2</RoomChildB50Count>                <RoomChildC30Count>1</RoomChildC30Count>                <RoomChildDNoneCount>1</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>1</RoomTypeCode>                <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                <PerRoomPaxCount>2</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerPaxRate>12000</PerPaxRate>                <PerChildA70Rate>12000</PerChildA70Rate>                <PerChildB50Rate>12000</PerChildB50Rate>                <PerChildC30Rate>3000</PerChildC30Rate>                <PerChildDRate>10000</PerChildDRate>                <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>            <RoomRateInformation>                <RoomDate>2013-07-22</RoomDate>                <PerChildB50Rate>0</PerChildB50Rate>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>88</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber> ';
    		infoTravelXML +=  '<TelegramData>予約通知 予約プロ                                      SNT-NET 07-09 23:49 (88) 予約番号： A001781590  NO.00000051 元湯陣屋様(14000010)宿泊者情報：  テスト予約No. 2013/07/09 _  TEL:01-2345-6789  ﾃｽﾄﾖﾔｸ _  Mail:hiroyuki_morimoto@jinya-inn.com  住所:(〒257-0001)神奈川県秦野市鶴巻北プラン名：【１泊朝食付】朝膳朝食付きプラン　チェックイン24:00までOK！(185)2013年07月22日から    3泊  朝食付  サ込税込入込方法：                   チェックイン時間：15:30人員総数：  14人  内訳：(男)2名+(女)2名+(Ａ)2名+(Ｂ)4名+(Ｃ)2名+(Ｄ)2名客室総数：   2室07月22日  24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）          24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）07月23日  24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）          24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）07月24日  24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）          24  (純和風客室(バスルーム無し))          大人（男）     1名    @12,000          大人（女）     1名    @12,000          子供Ａ         1名    @12,000  小学生          子供Ｂ         1名    @12,000  小児（食事布団あり）          子供Ｂ         1名         @0  小児（食事布団なし）          子供Ｃ         1名     @3,000  小児（食事のみ）          子供Ｄ         1名    @10,000  小児（布団のみ）                                   宿泊料金計                ：   \\366,000オプション：07月22日  特選会席料理                     4 個      @12,000             お土産（陣屋どらやき　6個入）    1 個         @960             お土産（やまと豚の桜味噌漬け 1   3 個       @1,575             お土産（やまと豚の桜味噌漬け 2   3 個       @3,150                                      オプション料金計          ：    \\63,135                       合計料金                              ：   \\429,135                     【宿泊者への請求額】                    ：   \\429,135           ---------------------------------------------------------------------ご確認事項：○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため取扱個所：予約プロ(88)  TEL 052-262-8041  FAX 052-262-8042---</TelegramData>                <PhoneNumber>01-2345-6789</PhoneNumber>                <Email>hiroyuki_morimoto@jinya-inn.com</Email>                <PostalCode>257-0001</PostalCode>                <Address>神奈川県秦野市鶴巻北</Address>                <TotalPaxManCount>4</TotalPaxManCount>                <BranchFaxNumber>052-262-8042</BranchFaxNumber>                <Version>2.0</Version>                <AccommodationId>X36969</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>1</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>0</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>1</RoomTypeCode>                    <RoomTypeName>純和風客室(バスルーム無し)</RoomTypeName>                    <PerRoomPaxCount>7</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>2</RoomChildB50Count>                    <RoomChildC30Count>1</RoomChildC30Count>                    <RoomChildDNoneCount>1</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）小児（食事布団なし）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>49</NetRmTypeGroupCode>                    <PlanGroupCode>---</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerPaxRate>12000</PerPaxRate>                    <PerChildA70Rate>12000</PerChildA70Rate>                    <PerChildB50Rate>12000</PerChildB50Rate>                    <PerChildC30Rate>3000</PerChildC30Rate>                    <PerChildDRate>10000</PerChildDRate>                    <TotalRoomHotSpringTax>0</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>12000</PerMaleRate>                    <PerFemaleRate>12000</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>1</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>1</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>                <RoomRateInformation>                    <RoomDate>2013-07-22</RoomDate>                    <PerChildB50Rate>0</PerChildB50Rate>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildB50Request>小児（食事布団なし）</RoomRateChildB50Request>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <OtherInfo>                <GuestRequest>○携帯電話番号[Mobile Phone Number]：00-2345-6789○ご要望・ご質問：N rooms N nightsのテストのため</GuestRequest>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <AmountClaimed>429135</AmountClaimed>            </Extend>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
		
	    	// 取込異常の場合、メール送信して、報告する	
	        EmailMessageToLeadProcess e = new EmailMessageToLeadProcess(currAgt);
	        EmailMessageToLeadSync leadInfoToSfCtrl = new EmailMessageToLeadSync(e);
			EmailMessageToLeadParser parseXmlCtrl = new EmailMessageToLeadParser();	
	    	EmailMessageToLeadSync.BI_EMAIL_SyncInfo bookingInfo = parseXmlCtrl.parse(infoTravelXML,'02');				
			EmailMessageToLeadSync.BI_EMAIL_SyncResult syncResult = leadInfoToSfCtrl.upsertEmail2LeadInfo(bookingInfo,'02');
		}
    }
    
        	
     private static void insertConfigDoc() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailImportServiceConfig';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
    	String mapString = '<?xml version="1.0" encoding="UTF-8"?><root>	<COMMON>	<LEADINTERVAL>60</LEADINTERVAL>		<LEADDELETEVAL>-14</LEADDELETEVAL>        <AGTS>			<AGT NMKEY="一休.com" template="EmailTemplateForIkyuu">80</AGT>			<AGT NMKEY="予約プロ" template="EmailTemplateForYoyakuPro">88</AGT>			<AGT NMKEY="ｅ宿" template="EmailTemplateForEsyoku">55</AGT>        </AGTS>        <MAIL_ADDRESS_MATCH>        	<RULE MAILADDRESS="'+mailServiceAddress+'">02</RULE>        </MAIL_ADDRESS_MATCH>	</COMMON>	<SHOP>			<SHOPCODE>02</SHOPCODE>		<APPCONFIG>				<UCACTISSYNC>TRUE</UCACTISSYNC>				<ROOMAUTOASSIGN>TRUE</ROOMAUTOASSIGN>				<ROOMSORT>DESC</ROOMSORT> <DEFAULTVALUES>  <APIFIELDNAME></APIFIELDNAME>     <APIFIELDVALUE></APIFIELDVALUE>    </DEFAULTVALUES>		</APPCONFIG>		<ACCOUNTCONFIG>				<NYUUTOUACCOUNT>M99000</NYUUTOUACCOUNT>				<SERVICEACCOUNT>M99001</SERVICEACCOUNT>		</ACCOUNTCONFIG> <PLANCODE_CONVERT>			<AGT NAME="XXXXXXX">				<CONVERT>					<AGTPACKAGECODE>A268Q,234,235</AGTPACKAGECODE>					<SFPLANNO>YYYYYYYY</SFPLANNO>				</CONVERT>			</AGT>		</PLANCODE_CONVERT><CONTACT_INFO_PARSE>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>携帯電話;Mobile Phone Number</KEYWORD><FORMAT>((090|080|070)[-| ]?\\d{4}[-| ]?\\d{4})</FORMAT><TOFIELD>Contact.Phone</TOFIELD>					<EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>誕生日;Birthday</KEYWORD><FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日;([0-9]{4})-([0-9]{1,2})-([0-9]{1,2});([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})</FORMAT><TOFIELD>Contact.Birthday</TOFIELD>				<EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO>		</CONTACT_INFO_PARSE>		<!-- 事前決済区分とAGTコードにより、指定の会計商品を取り込み -->		<PAYMENT_CONVERTS>			<!-- 引額(ポイント・補助金)金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する -->			<POINT_CONVERT PAYKBN="3">	<!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</POINT_CONVERT>			<POINT_CONVERT PAYKBN="2">	<!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</POINT_CONVERT>			<!-- 事前決済金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する -->			<PAYMENT_CONVERT PAYKBN="2">		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</PAYMENT_CONVERT>	     </PAYMENT_CONVERTS>		<!-- 事前支払方法キーワード定義 -->		<PRE_PAYMENT_DEF>	   		<!-- XMLに類語変換機能タグ XML_VAL:XMLから出力の支払方法、-->			<CREDIT>一括精算,パッケージ予約</CREDIT><!-- 支払方法タグに該当キーワードを含めすると、お客様請求金額は売掛明細として、見積明細に反映する -->			<CRAD>事前カード決済</CRAD>		</PRE_PAYMENT_DEF>	</SHOP></root>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;	
	}
	private static void insertConfigDoc1() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailImportServiceConfig';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
    	String mapString = '<?xml version="1.0" encoding="UTF-8"?><root>	<COMMON>	<LEADINTERVAL>60</LEADINTERVAL>		<LEADDELETEVAL>-14</LEADDELETEVAL>        <AGTS>			<AGT NMKEY="一休.com" template="EmailTemplateForIkyuu">80</AGT>			<AGT NMKEY="予約プロ" template="EmailTemplateForYoyakuPro"></AGT>			<AGT NMKEY="ｅ宿" template="EmailTemplateForEsyoku">55</AGT>        </AGTS>        <MAIL_ADDRESS_MATCH>        	<RULE MAILADDRESS="'+mailServiceAddress+'">02</RULE>        </MAIL_ADDRESS_MATCH>	</COMMON>	<SHOP>			<SHOPCODE>02</SHOPCODE>		<APPCONFIG>				<UCACTISSYNC>TRUE</UCACTISSYNC>				<ROOMAUTOASSIGN>TRUE</ROOMAUTOASSIGN>				<ROOMSORT>DESC</ROOMSORT> <DEFAULTVALUES>  <APIFIELDNAME></APIFIELDNAME>     <APIFIELDVALUE></APIFIELDVALUE>    </DEFAULTVALUES>		</APPCONFIG>		<ACCOUNTCONFIG>				<NYUUTOUACCOUNT>M99000</NYUUTOUACCOUNT>				<SERVICEACCOUNT>M99001</SERVICEACCOUNT>		</ACCOUNTCONFIG> <PLANCODE_CONVERT>			<AGT NAME="XXXXXXX">				<CONVERT>					<AGTPACKAGECODE>A268Q,234,235</AGTPACKAGECODE>					<SFPLANNO>YYYYYYYY</SFPLANNO>				</CONVERT>			</AGT>		</PLANCODE_CONVERT><CONTACT_INFO_PARSE>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>携帯電話;Mobile Phone Number</KEYWORD><FORMAT>((090|080|070)[-| ]?\\d{4}[-| ]?\\d{4})</FORMAT><TOFIELD>Contact.Phone</TOFIELD>					<EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>誕生日;Birthday</KEYWORD><FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日;([0-9]{4})-([0-9]{1,2})-([0-9]{1,2});([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})</FORMAT><TOFIELD>Contact.Birthday</TOFIELD>				<EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO>		</CONTACT_INFO_PARSE>		<!-- 事前決済区分とAGTコードにより、指定の会計商品を取り込み -->		<PAYMENT_CONVERTS>			<!-- 引額(ポイント・補助金)金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する -->			<POINT_CONVERT PAYKBN="3">	<!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</POINT_CONVERT>			<POINT_CONVERT PAYKBN="2">	<!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</POINT_CONVERT>			<!-- 事前決済金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する -->			<PAYMENT_CONVERT PAYKBN="2">		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</PAYMENT_CONVERT>	     </PAYMENT_CONVERTS>		<!-- 事前支払方法キーワード定義 -->		<PRE_PAYMENT_DEF>	   		<!-- XMLに類語変換機能タグ XML_VAL:XMLから出力の支払方法、-->			<CREDIT>一括精算,パッケージ予約</CREDIT><!-- 支払方法タグに該当キーワードを含めすると、お客様請求金額は売掛明細として、見積明細に反映する -->			<CRAD>事前カード決済</CRAD>		</PRE_PAYMENT_DEF>	</SHOP></root>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;	
	}
	 private static void insertOtherConfigDoc() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailImportServiceConfig';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
    	String mapString = '<?xml version="1.0" encoding="UTF-8"?><root>	<COMMON>	<LEADINTERVAL>60</LEADINTERVAL>		<LEADDELETEVAL>-14</LEADDELETEVAL>        <AGTS>			<AGT NMKEY="一休.com" template="EmailTemplateForIkyuu">80</AGT>			<AGT NMKEY="予約プロ" template="EmailTemplateForYoyakuPro">88</AGT>			<AGT NMKEY="ｅ宿" template="EmailTemplateForEsyoku">55</AGT>        </AGTS>        <MAIL_ADDRESS_MATCH>        	<RULE MAILADDRESS="'+mailServiceAddress+'">02</RULE>        </MAIL_ADDRESS_MATCH>	</COMMON>	<SHOP>			<SHOPCODE>02</SHOPCODE>		<APPCONFIG>				<UCACTISSYNC>FALSE</UCACTISSYNC>				<ROOMAUTOASSIGN>TRUE</ROOMAUTOASSIGN>				<ROOMSORT>DESC</ROOMSORT> <DEFAULTVALUES>  <APIFIELDNAME></APIFIELDNAME>     <APIFIELDVALUE></APIFIELDVALUE>    </DEFAULTVALUES>		</APPCONFIG>		<ACCOUNTCONFIG>				<NYUUTOUACCOUNT>M99000</NYUUTOUACCOUNT>				<SERVICEACCOUNT>M99001</SERVICEACCOUNT>		</ACCOUNTCONFIG> <PLANCODE_CONVERT>			<AGT NAME="XXXXXXX">				<CONVERT>					<AGTPACKAGECODE>A268Q,234,235</AGTPACKAGECODE>					<SFPLANNO>YYYYYYYY</SFPLANNO>				</CONVERT>			</AGT>		</PLANCODE_CONVERT><CONTACT_INFO_PARSE>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>携帯電話;Mobile Phone Number</KEYWORD><FORMAT>((090|080|070)[-| ]?\\d{4}[-| ]?\\d{4})</FORMAT><TOFIELD>Contact.Phone</TOFIELD>					<EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO>			<PARSE_LOGIC_INFO AGTCODE="">				<KEYWORD>誕生日;Birthday</KEYWORD><FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日;([0-9]{4})-([0-9]{1,2})-([0-9]{1,2});([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})</FORMAT><TOFIELD>Contact.Birthday</TOFIELD>				<EXCLUDEVAL></EXCLUDEVAL></PARSE_LOGIC_INFO>		</CONTACT_INFO_PARSE>		<!-- 事前決済区分とAGTコードにより、指定の会計商品を取り込み -->		<PAYMENT_CONVERTS>			<!-- 引額(ポイント・補助金)金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する -->			<POINT_CONVERT PAYKBN="3">	<!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</POINT_CONVERT>			<POINT_CONVERT PAYKBN="2">	<!-- KBN:「0」：指定なし、「1」：法人利用、「2」：カード決済、「3」：現地払い、「4」：ツアー会社、「5」：一部精算、「6」：エージェント精算 -->		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</POINT_CONVERT>			<!-- 事前決済金額に対して、事前決済区分とAGTコードにより、取り込みしたい会計商品コード情報を定義する -->			<PAYMENT_CONVERT PAYKBN="2">		          <CONVERT AGTCODE="80">M90201</CONVERT><!--一休ポイント-->			</PAYMENT_CONVERT>	     </PAYMENT_CONVERTS>		<!-- 事前支払方法キーワード定義 -->		<PRE_PAYMENT_DEF>	   		<!-- XMLに類語変換機能タグ XML_VAL:XMLから出力の支払方法、-->			<CREDIT>一括精算,パッケージ予約</CREDIT><!-- 支払方法タグに該当キーワードを含めすると、お客様請求金額は売掛明細として、見積明細に反映する -->			<CRAD>事前カード決済</CRAD>		</PRE_PAYMENT_DEF>	</SHOP></root>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;	
	}
    private static void insertDoc() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailTemplateForYoyakuPro';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
    	String mapString = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>	<TransactionType START_TAG="■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■" END_TAG="【宿泊代表者氏名】">		<DataFrom>FromMailImport</DataFrom>		<DataClassification>			<EMAIL_DETAIL>				<EMIAL_TAG_FORMAT>キャンセルメール</EMIAL_TAG_FORMAT>				<CONVERT_VAL>CancellationReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>            	<EMIAL_TAG_FORMAT>新規予約メール</EMIAL_TAG_FORMAT>            	<CONVERT_VAL>NewBookReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>	            <EMIAL_TAG_FORMAT>予約変更メール</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>ModificationReport</CONVERT_VAL>			</EMAIL_DETAIL>		</DataClassification>        <DataID>            <EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>            <EMAIL_END>(</EMAIL_END>        </DataID>	</TransactionType>	<AccommodationInformation>		<AccommodationName>元湯陣屋</AccommodationName>		<AccommodationCode>02</AccommodationCode>	</AccommodationInformation>	<SalesOfficeInformation>		<SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>		<SalesOfficeCompanyCode>88</SalesOfficeCompanyCode>	</SalesOfficeInformation>	<BasicInformation START_TAG="メール＞=========" END_TAG="料金明細">>		<TravelAgencyBookingNumber>			<EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>            <EMAIL_END>(</EMAIL_END>		</TravelAgencyBookingNumber>		<TravelAgencyBookingDate>			<EMAIL_TAG>受付時間：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>            <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		</TravelAgencyBookingDate>        <TravelAgencyBookingTime>            <EMAIL_TAG>受付時間：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>            <EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>        </TravelAgencyBookingTime>		<GuestOrGroupNameDoubleByte>            <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>		</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>        	<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>            <EMAIL_END>様</EMAIL_END>       	</GuestOrGroupNameKanjiName>       	<CheckInDate>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>				<EMAIL_END>)</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>				<EMAIL_END>)</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       	</CheckInDate>        <CheckInTime>        	<EMAIL_DETAIL>       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>				<EMAIL_BEG>)</EMAIL_BEG>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>				<EMAIL_BEG>)</EMAIL_BEG>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>        </CheckInTime>        <Nights>        	<EMAIL_TAG>○泊数</EMAIL_TAG>            <EMAIL_END>泊</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>        </Nights>        <TotalRoomCount>        	<EMAIL_TAG>○部屋数</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>部屋</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>        </TotalRoomCount>        <PackagePlanCode>        	<EMAIL_TAG>○プラン名</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>        </PackagePlanCode>        <PackagePlanName>       		<EMAIL_DETAIL>	        	<EMAIL_TAG>○プラン名</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>\n</EMAIL_END>       		</EMAIL_DETAIL>        </PackagePlanName>		<RoomTypeCode>            <EMAIL_TAG>○部屋タイプ</EMAIL_TAG>            <EMAIL_BEG>(</EMAIL_BEG>            <EMAIL_END>)</EMAIL_END>		</RoomTypeCode>		<RoomTypeName>			<EMAIL_DETAIL>				<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>(</EMAIL_END>            </EMAIL_DETAIL>            <EMAIL_DETAIL>	        	<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>)</EMAIL_END>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>	        	<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>○プラン名</EMAIL_END>       		</EMAIL_DETAIL>		</RoomTypeName>		<OtherServiceInformation>			<EMAIL_DETAIL>			<EMAIL_TAG>○プラン名</EMAIL_TAG>            <EMAIL_BEG>\n</EMAIL_BEG>            <EMAIL_END>---------</EMAIL_END>            </EMAIL_DETAIL>            <EMAIL_DETAIL>				<EMAIL_TAG>○ご要望・ご質問</EMAIL_TAG>        		<EMAIL_BEG>：</EMAIL_BEG>            	<EMAIL_END>\n</EMAIL_END>			</EMAIL_DETAIL>		</OtherServiceInformation>			</BasicInformation>	<BasicRateInformation>		<RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>		<!-- IncludingServiceWithOutTax/IncludingServiceAndTax/WithoutSerivceAndTax -->		<TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>		<!-- 		<Payment></Payment>		-->		<TotalAccommodationCharge>        	<EMAIL_TAG>【合計金額】</EMAIL_TAG>			<EMAIL_END>円</EMAIL_END>           	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		</TotalAccommodationCharge>	</BasicRateInformation>	<RoomAndGuestInformation orderType="1"  START_TAG="料金明細" SPLIT_TAG="泊目,部屋目：">				<RoomInformation >			<!-- 			<RoomTypeCode></RoomTypeCode>			<RoomTypeName>				<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>				<EMAIL_BEG>：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>			</RoomTypeName>			-->			<PerRoomPaxCount>				<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>			</PerRoomPaxCount>            <RoomPaxMaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>男性</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomPaxMaleCount>            <RoomPaxFemaleCount>	            	<EMAIL_TAG>大人</EMAIL_TAG>					<EMAIL_BEG>女性</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomPaxFemaleCount>            <RoomChildA70Count>            	<EMAIL_TAG>小学生</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildA70Count>             <RoomChildB50Count>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>            </RoomChildB50Count>            <RoomChildC30Count>            	<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildC30Count>            <RoomChildDNoneCount>            	<EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildDNoneCount>            <!--             <RoomChildDNoneCount>0</RoomChildDNoneCount> -->		</RoomInformation>		<RoomRateInformation >			<PerPaxRate>				<EMAIL_DETAIL>					<EMAIL_TAG>大人</EMAIL_TAG>	            	<EMAIL_BEG>名)</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>            	<EMAIL_DETAIL>					<EMAIL_TAG>大人</EMAIL_TAG>	            	<EMAIL_BEG>名)</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>			</PerPaxRate>			<PerChildA70Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小学生</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>            	<EMAIL_DETAIL>					<EMAIL_TAG>小学生</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>			</PerChildA70Rate>			<PerChildB50Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>			</PerChildB50Rate>			<PerChildC30Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>							</PerChildC30Rate>			<PerChildDRate></PerChildDRate>			<TotalPerRoomRate></TotalPerRoomRate>			<TotalRoomHotSpringTax>			<EMAIL_DETAIL>			<EMAIL_TAG>入湯税</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalRoomHotSpringTax>			<TotalPerRoomServiceFee>			<EMAIL_DETAIL>			<EMAIL_TAG>サービス料</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalPerRoomServiceFee>			 -->		</RoomRateInformation>		<GuestInformation>			<GuestInformationList>				<GuestNameSingleByte>					<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		        	<EMAIL_BEG>(</EMAIL_BEG>		        	<EMAIL_END>)</EMAIL_END>				</GuestNameSingleByte>				<GuestKanjiName>					<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>            		<EMAIL_END>様</EMAIL_END>				</GuestKanjiName>				<GuestDateOfBirth>					<EMAIL_TAG>○誕生日</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>				</GuestDateOfBirth>			</GuestInformationList>		</GuestInformation>	</RoomAndGuestInformation>	<RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>88</SalesOfficeCompanyCode>                <PhoneNumber>                	<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                    <EMAIL_BEG>【電話番号】</EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([-0-9]+)</EMIAL_TAG_FORMAT>                </PhoneNumber>                <Email>               		<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                	<EMAIL_BEG>【メールアドレス】</EMAIL_BEG>                	<EMAIL_END>\n</EMAIL_END>                </Email>                <PostalCode>                	<EMAIL_TAG>【住所】</EMAIL_TAG>                	<EMAIL_BEG>〒</EMAIL_BEG>                	<EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>                </PostalCode>                <Address>                    <EMAIL_TAG>【住所】</EMAIL_TAG>                    <EMAIL_BEG> </EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([\u4e00-\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>                </Address>            </Basic>        </RisaplsCommonInformation>        <AgentNativeInformation>        	<Extend>        		<!--         		<PointName>        		        		</PointName>        		<Points>        		        		</Points> -->        		        	</Extend>        	<Extendmytrip>        		<!-- <SettlementDiv></SettlementDiv> -->        	</Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation>    <CUSTOMER_SETTING>		<OBJECT>			<NAME>Lead__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Field375__c">					<EMAIL_DETAIL>		       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>						<EMAIL_END>)</EMAIL_END>			            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>						<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       		</EMAIL_DETAIL>		       		<EMAIL_DETAIL>		       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>						<EMAIL_END>)</EMAIL_END>			            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>						<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       		</EMAIL_DETAIL>		       	</EMAIL_FIELD>		       	<EMAIL_FIELD apiname="Field305__c">			       	<EMIAL_TAG_FORMAT>○ご利用日時</EMIAL_TAG_FORMAT>			       	<CONVERT_VAL>TRUE</CONVERT_VAL>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>		<OBJECT>			<NAME>LeadIndex__c</NAME>			<MAPPINGS>			 	<EMAIL_FIELD apiname="Rooms__c">				 	<EMAIL_TAG>○部屋数</EMAIL_TAG>				 	<EMAIL_BEG>：</EMAIL_BEG>	            	<EMAIL_END>部屋</EMAIL_END>			 	</EMAIL_FIELD> 				<!--  <EMAIL_FIELD apiname="RoomTypeRef__c">○部屋タイプ</EMAIL_FIELD>				<EMAIL_FIELD apiname="PlanRef__c">○プラン名</EMAIL_FIELD>				<EMAIL_FIELD apiname="No__c">予約Ｎｏ</EMAIL_FIELD>				<EMAIL_FIELD apiname="No__c">予約Ｎｏ</EMAIL_FIELD>-->			</MAPPINGS>		</OBJECT>		<!-- 		<OBJECT>			<NAME>LeadIndex__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Name1__c">宿泊代表者氏名</EMAIL_FIELD>				<EMAIL_FIELD apiname="Phone">【電話番号】</EMAIL_FIELD>				<EMAIL_FIELD apiname="Email">【メールアドレス】</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>		 -->		 <OBJECT>			<NAME>Contact</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Birthdate">					<EMAIL_TAG>○誕生日</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>            		<EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>					<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       	</EMAIL_FIELD>		       	<EMAIL_FIELD apiname="MobilePhone">					<EMAIL_TAG>携帯電話番号[Mobile Phone Number]</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>			</CUSTOMER_SETTING></AllotmentBookingReport>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;
    	ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailTemplateForIkyuu';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId(); 
    	mapString = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>	<TransactionType>		<DataFrom>FromMailImport</DataFrom>		<DataClassification>			<EMAIL_DETAIL>				<EMIAL_TAG_FORMAT>◆予約取消のお知らせ</EMIAL_TAG_FORMAT>				<CONVERT_VAL>CancellationReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>            	<EMIAL_TAG_FORMAT>◆予約受付のお知らせ</EMIAL_TAG_FORMAT>            	<CONVERT_VAL>NewBookReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>	            <EMIAL_TAG_FORMAT>◆予約内容一部変更のお知らせ</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>ModificationReport</CONVERT_VAL>			</EMAIL_DETAIL>		</DataClassification>        <DataID>            <EMAIL_TAG>●予約番号</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>        </DataID>        <!--         <TravelAgencyBookingDate></TravelAgencyBookingDate>        <TravelAgencyBookingTime></TravelAgencyBookingTime>        -->	</TransactionType>	<AccommodationInformation>		<AccommodationName>元湯陣屋</AccommodationName>		<AccommodationCode>02</AccommodationCode>	</AccommodationInformation>	<SalesOfficeInformation>		<SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>		<SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>	</SalesOfficeInformation>	<BasicInformation START_TAG="●予約番号" END_TAG="■明細■">>		<TravelAgencyBookingNumber>            <EMAIL_TAG>●予約番号</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>		</TravelAgencyBookingNumber>		<GuestOrGroupNameDoubleByte>            <EMAIL_TAG>●宿泊代表者氏名</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>		</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>        	<EMAIL_TAG>●宿泊代表者氏名</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>(</EMAIL_END>       	</GuestOrGroupNameKanjiName>       	<CheckInDate>       		<EMAIL_TAG>●到着日</EMAIL_TAG>			<EMAIL_BEGIN>：</EMAIL_BEGIN>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       	</CheckInDate>        <CheckInTime>			<EMAIL_DETAIL>				<EMAIL_TAG>●到着日</EMAIL_TAG>				<EMAIL_BEG>到着予定時間：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG>●到着日</EMAIL_TAG>				<EMAIL_BEG>C/IN可能時間：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>			</EMAIL_DETAIL>        </CheckInTime>        <CheckOutDate>       		<EMAIL_TAG>●出発日</EMAIL_TAG>			<EMAIL_BEGIN>：</EMAIL_BEGIN>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>        </CheckOutDate>        <CheckOutTime>        	<EMAIL_TAG>●出発日</EMAIL_TAG>			<EMAIL_BEG>C/OUT時間：</EMAIL_BEG>			<EMAIL_END>\n</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>        </CheckOutTime>        <PackagePlanName>        	<EMAIL_TAG>●プラン名称</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>        	<EMAIL_END>[</EMAIL_END>        </PackagePlanName>        <PackagePlanCode>        	<EMAIL_TAG>●プラン名称</EMAIL_TAG>        	<EMAIL_BEG>[</EMAIL_BEG>        	<EMAIL_END>]</EMAIL_END>        </PackagePlanCode>  		<RoomTypeCode>            <EMAIL_TAG>●部屋名称</EMAIL_TAG>            <EMAIL_BEG>[</EMAIL_BEG>            <EMAIL_END>]</EMAIL_END>		</RoomTypeCode>		<RoomTypeName>            <EMAIL_DETAIL>				<EMAIL_TAG>●部屋名称</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>[</EMAIL_END>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG>●部屋名称</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>\n</EMAIL_END>			</EMAIL_DETAIL>		</RoomTypeName>        <OtherServiceInformation>        	<EMAIL_LOGIC>SUM</EMAIL_LOGIC>        	<EMAIL_DETAIL>				<EMAIL_TAG saveKey="true">■質問・回答■</EMAIL_TAG>        		<EMAIL_END>---------------------------------------------------------</EMAIL_END>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG saveKey="true">■コメント■</EMAIL_TAG>        		<EMAIL_END>---------------------------------------------------------</EMAIL_END>			</EMAIL_DETAIL>        </OtherServiceInformation>        <!--          <MealCondition>			<EMAIL_TAG>●食事</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>		</MealCondition>		-->		<Option>			<EMAIL_TAG>●オプション</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>            <EMIAL_TAG_FORMAT>なし</EMIAL_TAG_FORMAT>            <CONVERT_VAL></CONVERT_VAL>		</Option>    </BasicInformation>    <BasicRateInformation START_TAG="■宿泊内容■" END_TAG="■明細■">    	<RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>			<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税・サービス料込</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>IncludingServiceAndTax</CONVERT_VAL>			</EMAIL_DETAIL>        	<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税別・サービス料込</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>IncludingServiceWithoutTax</CONVERT_VAL>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税別・サービス料別</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>WithoutServiceAndTax</CONVERT_VAL>	        </EMAIL_DETAIL>        	<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税込・サービス料別</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>WithoutServiceAndIncludingTax</CONVERT_VAL>       		</EMAIL_DETAIL>       	</TaxServiceFee>        <Payment>            <EMAIL_TAG>支払方法：</EMAIL_TAG>            <EMAIL_END>\n</EMAIL_END>            <EMAIL_EXCULDE>事前決済</EMAIL_EXCULDE>        </Payment>        <TotalAccommodationCharge>            <EMAIL_TAG>支払金額：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>        </TotalAccommodationCharge>        <CouponList>        	<CouponAmount>        		<EMAIL_TAG>割引クーポン利用額</EMAIL_TAG>        		<EMAIL_BEG>：</EMAIL_BEG>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>        	</CouponAmount>        	<CouponType>割引クーポン利用額</CouponType>        </CouponList>    </BasicRateInformation>	<RoomAndGuestInformation orderType="2"  								START_TAG="■明細■" 								END_TAG="============================================================"						SPLIT_TAG="泊目,部屋目">		<RoomInformation >			<PerRoomPaxCount>				<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>			</PerRoomPaxCount>            <RoomPaxMaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>男性：</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>            </RoomPaxMaleCount>            <RoomPaxFemaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>女性：</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>            </RoomPaxFemaleCount>                        <RoomChildA70Count>            	<EMAIL_TAG>小学生</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildA70Count>            <RoomChildB50Count>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>            </RoomChildB50Count>            <RoomChildC30Count>            	<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildC30Count>            <RoomChildDNoneCount>            	<EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildDNoneCount>		</RoomInformation>		<RoomRateInformation >			<PerPaxRate>				<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>名）</EMAIL_BEG>				<EMAIL_END>×</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerPaxRate>			<PerChildA70Rate>				<EMAIL_TAG>小学生</EMAIL_TAG>            	<EMAIL_BEG>(</EMAIL_BEG>				<EMAIL_END>円</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerChildA70Rate>			<PerChildB50Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>\\</EMAIL_BEG>					<EMAIL_END>×</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>\\</EMAIL_BEG>					<EMAIL_END>×</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>			</PerChildB50Rate>			<PerChildC30Rate>				<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>\\</EMAIL_BEG>				<EMAIL_END>×</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerChildC30Rate>			<PerChildDRate></PerChildDRate>			<TotalPerRoomRate></TotalPerRoomRate>			<TotalRoomHotSpringTax>			<EMAIL_DETAIL>			<EMAIL_TAG>入湯税</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalRoomHotSpringTax>			<TotalPerRoomServiceFee>			<EMAIL_DETAIL>			<EMAIL_TAG>サービス料</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalPerRoomServiceFee>		</RoomRateInformation>	</RoomAndGuestInformation>		<RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramData>                	<EMAIL_TAG></EMAIL_TAG>                </TelegramData><!-- 空白のまま -->                <PhoneNumber>                	<EMAIL_TAG>宿泊代表者連絡先</EMAIL_TAG>                	<EMAIL_BEG>：</EMAIL_BEG>                    <EMAIL_END>(</EMAIL_END>                    <EMIAL_TAG_FORMAT>([-0-9]+)</EMIAL_TAG_FORMAT>                </PhoneNumber>                <!--                 <Email>               		<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                	<EMAIL_BEG>【メールアドレス】</EMAIL_BEG>                	<EMAIL_END>&lt;</EMAIL_END>                	<EMIAL_TAG_FORMAT>(^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$)</EMIAL_TAG_FORMAT>                </Email>                <PostalCode>                	<EMAIL_TAG>【住所】</EMAIL_TAG>                	<EMAIL_BEG>〒</EMAIL_BEG>                	<EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>                </PostalCode>                <Address>                    <EMAIL_TAG>【住所】</EMAIL_TAG>                    <EMAIL_BEG> </EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([\\u4e00-\\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>                </Address>                 -->            </Basic>            <Member>	        	<UserUsePoints>	        		<EMAIL_TAG>ポイント・割引クーポン利用額</EMAIL_TAG>	            	<EMAIL_BEG>：</EMAIL_BEG>					<EMAIL_END>\n</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	        	</UserUsePoints>	        </Member>        </RisaplsCommonInformation>        <AgentNativeInformation>        	<Extend>        		<PointName>        		ポイント・割引クーポン        		</PointName>        		<Points>					<EMAIL_TAG>ポイント・割引クーポン利用額</EMAIL_TAG>	            	<EMAIL_BEG>：</EMAIL_BEG>					<EMAIL_END>\n</EMAIL_END>					 	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	            	         		</Points>        	</Extend>        	<Extendmytrip>        		<SettlementDiv>        			<EMAIL_LOGIC>AND</EMAIL_LOGIC>					<EMAIL_DETAIL>						<EMAIL_TAG>支払方法：</EMAIL_TAG>						<EMAIL_END>\n</EMAIL_END>						<EMIAL_TAG_FORMAT>事前決済</EMIAL_TAG_FORMAT>					</EMAIL_DETAIL>					<EMAIL_DETAIL>						<EMAIL_LOGIC>AND</EMAIL_LOGIC>						<EMAIL_DETAIL>							<EMAIL_TAG>支払方法：</EMAIL_TAG>							<EMAIL_END>\n</EMAIL_END>							<EMIAL_TAG_FORMAT>現金</EMIAL_TAG_FORMAT>						</EMAIL_DETAIL>						<EMAIL_DETAIL>							<EMAIL_LOGIC>OR</EMAIL_LOGIC>							<EMAIL_DETAIL>								<EMAIL_TAG>支払方法：</EMAIL_TAG>								<EMAIL_END>\n</EMAIL_END>								<EMIAL_TAG_FORMAT>現金</EMIAL_TAG_FORMAT>								<CONVERT_VAL>1</CONVERT_VAL>							</EMAIL_DETAIL>							<EMAIL_DETAIL>								<EMAIL_TAG>支払方法：</EMAIL_TAG>								<EMAIL_END>\n</EMAIL_END>								<EMIAL_TAG_FORMAT>事前決済</EMIAL_TAG_FORMAT>								<CONVERT_VAL>2</CONVERT_VAL>							</EMAIL_DETAIL>						</EMAIL_DETAIL>					</EMAIL_DETAIL>        		</SettlementDiv>        	</Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation>        <CUSTOMER_SETTING>		<OBJECT>			<NAME>Lead__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Field354__c">					<EMAIL_TAG>●食事</EMAIL_TAG>		            <EMAIL_BEG>：</EMAIL_BEG>		            <EMAIL_END>\n</EMAIL_END>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>	</CUSTOMER_SETTING></AllotmentBookingReport>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	ApplicationFormPdfConfig.id = null;
    	insert ApplicationFormPdfConfig;	
	}
	 private static void insertDoc1() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailTemplateForYoyakuPro';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
        String mapString = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>	<TransactionType START_TAG="■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■" END_TAG="【宿泊代表者氏名】">		<DataFrom>FromMailImport</DataFrom>		<DataClassification>			<EMAIL_DETAIL>				<EMIAL_TAG_FORMAT>キャンセルメール</EMIAL_TAG_FORMAT>				<CONVERT_VAL>CancellationReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>            	<EMIAL_TAG_FORMAT>新規予約メール</EMIAL_TAG_FORMAT>            	<CONVERT_VAL>NewBookReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>	            <EMIAL_TAG_FORMAT>予約変更メール</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>ModificationReport</CONVERT_VAL>			</EMAIL_DETAIL>		</DataClassification>        <DataID>            <EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>            <EMAIL_END>(</EMAIL_END>        </DataID>	</TransactionType>	<AccommodationInformation>		<AccommodationName>元湯陣屋</AccommodationName>		<AccommodationCode>02</AccommodationCode>	</AccommodationInformation>	<SalesOfficeInformation>		<SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>		<SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>	</SalesOfficeInformation>	<BasicInformation START_TAG="メール＞=========" END_TAG="料金明細">>		<TravelAgencyBookingNumber>			<EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>            <EMAIL_END>(</EMAIL_END>		</TravelAgencyBookingNumber>		<TravelAgencyBookingDate>			<EMAIL_TAG>受付時間：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>            <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		</TravelAgencyBookingDate>        <TravelAgencyBookingTime>            <EMAIL_TAG>受付時間：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>            <EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>        </TravelAgencyBookingTime>		<GuestOrGroupNameDoubleByte>            <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>		</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>        	<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>            <EMAIL_END>様</EMAIL_END>       	</GuestOrGroupNameKanjiName>       	<CheckInDate>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>				<EMAIL_END>)</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>				<EMAIL_END>)</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       	</CheckInDate>        <CheckInTime>        	<EMAIL_DETAIL>       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>				<EMAIL_BEG>)</EMAIL_BEG>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>				<EMAIL_BEG>)</EMAIL_BEG>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>        </CheckInTime>        <Nights>        	<EMAIL_TAG>○泊数</EMAIL_TAG>            <EMAIL_END>泊</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>        </Nights>        <TotalRoomCount>        	<EMAIL_TAG>○部屋数</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>部屋</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>        </TotalRoomCount>        <PackagePlanCode>        	<EMAIL_TAG>○プラン名</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>        </PackagePlanCode>        <PackagePlanName>       		<EMAIL_DETAIL>	        	<EMAIL_TAG>○プラン名</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>\n</EMAIL_END>       		</EMAIL_DETAIL>        </PackagePlanName>		<RoomTypeCode>            <EMAIL_TAG>○部屋タイプ</EMAIL_TAG>            <EMAIL_BEG>(</EMAIL_BEG>            <EMAIL_END>)</EMAIL_END>		</RoomTypeCode>		<RoomTypeName>			<EMAIL_DETAIL>				<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>(</EMAIL_END>            </EMAIL_DETAIL>            <EMAIL_DETAIL>	        	<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>)</EMAIL_END>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>	        	<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>○プラン名</EMAIL_END>       		</EMAIL_DETAIL>		</RoomTypeName>		<OtherServiceInformation>			<EMAIL_DETAIL>			<EMAIL_TAG>○プラン名</EMAIL_TAG>            <EMAIL_BEG>\n</EMAIL_BEG>            <EMAIL_END>---------</EMAIL_END>            </EMAIL_DETAIL>            <EMAIL_DETAIL>				<EMAIL_TAG>○ご要望・ご質問</EMAIL_TAG>        		<EMAIL_BEG>：</EMAIL_BEG>            	<EMAIL_END>\n</EMAIL_END>			</EMAIL_DETAIL>		</OtherServiceInformation>			</BasicInformation>	<BasicRateInformation>		<RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>  		 IncludingServiceWithOutTax/IncludingServiceAndTax/WithoutSerivceAndTax 	<TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>		 		<Payment></Payment>				<TotalAccommodationCharge>        	<EMAIL_TAG>【合計金額】</EMAIL_TAG>			<EMAIL_END>円</EMAIL_END>           	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		</TotalAccommodationCharge>	</BasicRateInformation>	<RoomAndGuestInformation orderType="1"  START_TAG="料金明細" SPLIT_TAG="泊目,部屋目：">				<RoomInformation >			 			<RoomTypeCode></RoomTypeCode>			<RoomTypeName>				<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>				<EMAIL_BEG>：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>			</RoomTypeName>						<PerRoomPaxCount>				<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>			</PerRoomPaxCount>            <RoomPaxMaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>男性</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomPaxMaleCount>            <RoomPaxFemaleCount>	            	<EMAIL_TAG>大人</EMAIL_TAG>					<EMAIL_BEG>女性</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomPaxFemaleCount>            <RoomChildA70Count>            	<EMAIL_TAG>小学生</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildA70Count>             <RoomChildB50Count>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>            </RoomChildB50Count>            <RoomChildC30Count>            	<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildC30Count>            <RoomChildDNoneCount>            	<EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildDNoneCount>                        <RoomChildDNoneCount>0</RoomChildDNoneCount> 		</RoomInformation>		<RoomRateInformation >			<PerPaxRate>				<EMAIL_DETAIL>					<EMAIL_TAG>大人</EMAIL_TAG>	            	<EMAIL_BEG>名)</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>            	<EMAIL_DETAIL>					<EMAIL_TAG>大人</EMAIL_TAG>	            	<EMAIL_BEG>名)</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>			</PerPaxRate>			<PerChildA70Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小学生</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>            	<EMAIL_DETAIL>					<EMAIL_TAG>小学生</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>			</PerChildA70Rate>			<PerChildB50Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>			</PerChildB50Rate>			<PerChildC30Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>							</PerChildC30Rate>			<PerChildDRate></PerChildDRate>			<TotalPerRoomRate>				<EMAIL_TAG>【合計金額】</EMAIL_TAG>					<EMAIL_END>円</EMAIL_END>				<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</TotalPerRoomRate>			<TotalRoomHotSpringTax>			<EMAIL_DETAIL>			<EMAIL_TAG>入湯税</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalRoomHotSpringTax>			<TotalPerRoomServiceFee>			<EMAIL_DETAIL>			<EMAIL_TAG>サービス料</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalPerRoomServiceFee>			 		</RoomRateInformation>		<GuestInformation>			<GuestInformationList>				<GuestNameSingleByte>					<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		        	<EMAIL_BEG>(</EMAIL_BEG>		        	<EMAIL_END>)</EMAIL_END>				</GuestNameSingleByte>				<GuestKanjiName>					<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>            		<EMAIL_END>様</EMAIL_END>				</GuestKanjiName>				<GuestDateOfBirth>					<EMAIL_TAG>○誕生日</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>				</GuestDateOfBirth>			</GuestInformationList>		</GuestInformation>	</RoomAndGuestInformation>	<RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>                <PhoneNumber>                	<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                    <EMAIL_BEG>【電話番号】</EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([-0-9]+)</EMIAL_TAG_FORMAT>                </PhoneNumber>                <Email>               		<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                	<EMAIL_BEG>【メールアドレス】</EMAIL_BEG>                	<EMAIL_END>\n</EMAIL_END>                </Email>                <PostalCode>                	<EMAIL_TAG>【住所】</EMAIL_TAG>                	<EMAIL_BEG>〒</EMAIL_BEG>                	<EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>                </PostalCode>                <Address>                    <EMAIL_TAG>【住所】</EMAIL_TAG>                    <EMAIL_BEG> </EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([\u4e00-\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>                </Address>            </Basic>        </RisaplsCommonInformation>        <AgentNativeInformation>        	<Extend>        		         		<PointName>        		        		</PointName>        		<Points>        		        		</Points>         		        	</Extend>        	<Extendmytrip>        		 <SettlementDiv></SettlementDiv>         	</Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation>    <CUSTOMER_SETTING>		<OBJECT>			<NAME>Lead__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Field375__c">					<EMAIL_DETAIL>		       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>						<EMAIL_END>)</EMAIL_END>			            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>						<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       		</EMAIL_DETAIL>		       		<EMAIL_DETAIL>		       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>						<EMAIL_END>)</EMAIL_END>			            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>						<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       		</EMAIL_DETAIL>		       	</EMAIL_FIELD>		       	<EMAIL_FIELD apiname="Field305__c">			       	<EMIAL_TAG_FORMAT>○ご利用日時</EMIAL_TAG_FORMAT>			       	<CONVERT_VAL>TRUE</CONVERT_VAL>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>		<OBJECT>			<NAME>LeadIndex__c</NAME>			<MAPPINGS>			 	<EMAIL_FIELD apiname="Rooms__c">				 	<EMAIL_TAG>○部屋数</EMAIL_TAG>				 	<EMAIL_BEG>：</EMAIL_BEG>	            	<EMAIL_END>部屋</EMAIL_END>			 	</EMAIL_FIELD> 				  <EMAIL_FIELD apiname="RoomTypeRef__c">○部屋タイプ</EMAIL_FIELD>				<EMAIL_FIELD apiname="PlanRef__c">○プラン名</EMAIL_FIELD>				<EMAIL_FIELD apiname="No__c">予約Ｎｏ</EMAIL_FIELD>				<EMAIL_FIELD apiname="No__c">予約Ｎｏ</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>				<OBJECT>			<NAME>LeadIndex__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Name1__c">宿泊代表者氏名</EMAIL_FIELD>				<EMAIL_FIELD apiname="Phone">【電話番号】</EMAIL_FIELD>				<EMAIL_FIELD apiname="Email">【メールアドレス】</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>		 		 <OBJECT>			<NAME>Contact</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Birthdate">					<EMAIL_TAG>○誕生日</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>            		<EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>					<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       	</EMAIL_FIELD>		       	<EMAIL_FIELD apiname="MobilePhone">					<EMAIL_TAG>携帯電話番号[Mobile Phone Number]</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>			</CUSTOMER_SETTING></AllotmentBookingReport>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;
    	ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailTemplateForIkyuu';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId(); 
    	mapString = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>	<TransactionType>		<DataFrom>FromMailImport</DataFrom>		<DataClassification>			<EMAIL_DETAIL>				<EMIAL_TAG_FORMAT>◆予約取消のお知らせ</EMIAL_TAG_FORMAT>				<CONVERT_VAL>CancellationReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>            	<EMIAL_TAG_FORMAT>◆予約受付のお知らせ</EMIAL_TAG_FORMAT>            	<CONVERT_VAL>NewBookReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>	            <EMIAL_TAG_FORMAT>◆予約内容一部変更のお知らせ</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>ModificationReport</CONVERT_VAL>			</EMAIL_DETAIL>		</DataClassification>        <DataID>            <EMAIL_TAG>●予約番号</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>        </DataID>        <!--         <TravelAgencyBookingDate></TravelAgencyBookingDate>        <TravelAgencyBookingTime></TravelAgencyBookingTime>        -->	</TransactionType>	<AccommodationInformation>		<AccommodationName>元湯陣屋</AccommodationName>		<AccommodationCode>02</AccommodationCode>	</AccommodationInformation>	<SalesOfficeInformation>		<SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>		<SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>	</SalesOfficeInformation>	<BasicInformation START_TAG="●予約番号" END_TAG="■明細■">>		<TravelAgencyBookingNumber>            <EMAIL_TAG>●予約番号</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>		</TravelAgencyBookingNumber>		<GuestOrGroupNameDoubleByte>            <EMAIL_TAG>●宿泊代表者氏名</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>		</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>        	<EMAIL_TAG>●宿泊代表者氏名</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>(</EMAIL_END>       	</GuestOrGroupNameKanjiName>       	<CheckInDate>       		<EMAIL_TAG>●到着日</EMAIL_TAG>			<EMAIL_BEGIN>：</EMAIL_BEGIN>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       	</CheckInDate>        <CheckInTime>			<EMAIL_DETAIL>				<EMAIL_TAG>●到着日</EMAIL_TAG>				<EMAIL_BEG>到着予定時間：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG>●到着日</EMAIL_TAG>				<EMAIL_BEG>C/IN可能時間：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>			</EMAIL_DETAIL>        </CheckInTime>        <CheckOutDate>       		<EMAIL_TAG>●出発日</EMAIL_TAG>			<EMAIL_BEGIN>：</EMAIL_BEGIN>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>        </CheckOutDate>        <CheckOutTime>        	<EMAIL_TAG>●出発日</EMAIL_TAG>			<EMAIL_BEG>C/OUT時間：</EMAIL_BEG>			<EMAIL_END>\n</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>        </CheckOutTime>        <PackagePlanName>        	<EMAIL_TAG>●プラン名称</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>        	<EMAIL_END>[</EMAIL_END>        </PackagePlanName>        <PackagePlanCode>        	<EMAIL_TAG>●プラン名称</EMAIL_TAG>        	<EMAIL_BEG>[</EMAIL_BEG>        	<EMAIL_END>]</EMAIL_END>        </PackagePlanCode>  		<RoomTypeCode>            <EMAIL_TAG>●部屋名称</EMAIL_TAG>            <EMAIL_BEG>[</EMAIL_BEG>            <EMAIL_END>]</EMAIL_END>		</RoomTypeCode>		<RoomTypeName>            <EMAIL_DETAIL>				<EMAIL_TAG>●部屋名称</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>[</EMAIL_END>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG>●部屋名称</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>\n</EMAIL_END>			</EMAIL_DETAIL>		</RoomTypeName>        <OtherServiceInformation>        	<EMAIL_LOGIC>SUM</EMAIL_LOGIC>        	<EMAIL_DETAIL>				<EMAIL_TAG saveKey="true">■質問・回答■</EMAIL_TAG>        		<EMAIL_END>---------------------------------------------------------</EMAIL_END>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG saveKey="true">■コメント■</EMAIL_TAG>        		<EMAIL_END>---------------------------------------------------------</EMAIL_END>			</EMAIL_DETAIL>        </OtherServiceInformation>        <!--          <MealCondition>			<EMAIL_TAG>●食事</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>		</MealCondition>		-->		<Option>			<EMAIL_TAG>●オプション</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>            <EMIAL_TAG_FORMAT>なし</EMIAL_TAG_FORMAT>            <CONVERT_VAL></CONVERT_VAL>		</Option>    </BasicInformation>    <BasicRateInformation START_TAG="■宿泊内容■" END_TAG="■明細■">    	<RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>			<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税・サービス料込</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>IncludingServiceAndTax</CONVERT_VAL>			</EMAIL_DETAIL>        	<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税別・サービス料込</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>IncludingServiceWithoutTax</CONVERT_VAL>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税別・サービス料別</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>WithoutServiceAndTax</CONVERT_VAL>	        </EMAIL_DETAIL>        	<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税込・サービス料別</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>WithoutServiceAndIncludingTax</CONVERT_VAL>       		</EMAIL_DETAIL>       	</TaxServiceFee>        <Payment>            <EMAIL_TAG>支払方法：</EMAIL_TAG>            <EMAIL_END>\n</EMAIL_END>            <EMAIL_EXCULDE>事前決済</EMAIL_EXCULDE>        </Payment>        <TotalAccommodationCharge>            <EMAIL_TAG>支払金額：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>        </TotalAccommodationCharge>        <CouponList>        	<CouponAmount>        		<EMAIL_TAG>割引クーポン利用額</EMAIL_TAG>        		<EMAIL_BEG>：</EMAIL_BEG>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>        	</CouponAmount>        	<CouponType>割引クーポン利用額</CouponType>        </CouponList>    </BasicRateInformation>	<RoomAndGuestInformation orderType="2"  								START_TAG="■明細■" 								END_TAG="============================================================"						SPLIT_TAG="泊目,部屋目">		<RoomInformation >			<PerRoomPaxCount>				<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>			</PerRoomPaxCount>            <RoomPaxMaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>男性：</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>            </RoomPaxMaleCount>            <RoomPaxFemaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>女性：</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>            </RoomPaxFemaleCount>                        <RoomChildA70Count>            	<EMAIL_TAG>小学生</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildA70Count>            <RoomChildB50Count>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>            </RoomChildB50Count>            <RoomChildC30Count>            	<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildC30Count>            <RoomChildDNoneCount>            	<EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildDNoneCount>		</RoomInformation>		<RoomRateInformation >			<PerPaxRate>				<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>名）</EMAIL_BEG>				<EMAIL_END>×</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerPaxRate>			<PerChildA70Rate>				<EMAIL_TAG>小学生</EMAIL_TAG>            	<EMAIL_BEG>(</EMAIL_BEG>				<EMAIL_END>円</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerChildA70Rate>			<PerChildB50Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>\\</EMAIL_BEG>					<EMAIL_END>×</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>\\</EMAIL_BEG>					<EMAIL_END>×</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>			</PerChildB50Rate>			<PerChildC30Rate>				<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>\\</EMAIL_BEG>				<EMAIL_END>×</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerChildC30Rate>			<PerChildDRate></PerChildDRate>			<TotalPerRoomRate>				<EMAIL_TAG>【合計金額】</EMAIL_TAG>					<EMAIL_END>円</EMAIL_END>				<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</TotalPerRoomRate>			<TotalRoomHotSpringTax>			<EMAIL_DETAIL>			<EMAIL_TAG>入湯税</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalRoomHotSpringTax>			<TotalPerRoomServiceFee>			<EMAIL_DETAIL>			<EMAIL_TAG>サービス料</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalPerRoomServiceFee>		</RoomRateInformation>	</RoomAndGuestInformation>		<RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramData>                	<EMAIL_TAG></EMAIL_TAG>                </TelegramData><!-- 空白のまま -->                <PhoneNumber>                	<EMAIL_TAG>宿泊代表者連絡先</EMAIL_TAG>                	<EMAIL_BEG>：</EMAIL_BEG>                    <EMAIL_END>(</EMAIL_END>                    <EMIAL_TAG_FORMAT>([-0-9]+)</EMIAL_TAG_FORMAT>                </PhoneNumber>                <!--                 <Email>               		<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                	<EMAIL_BEG>【メールアドレス】</EMAIL_BEG>                	<EMAIL_END>&lt;</EMAIL_END>                	<EMIAL_TAG_FORMAT>(^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$)</EMIAL_TAG_FORMAT>                </Email>                <PostalCode>                	<EMAIL_TAG>【住所】</EMAIL_TAG>                	<EMAIL_BEG>〒</EMAIL_BEG>                	<EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>                </PostalCode>                <Address>                    <EMAIL_TAG>【住所】</EMAIL_TAG>                    <EMAIL_BEG> </EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([\\u4e00-\\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>                </Address>                 -->            </Basic>            <Member>	        	<UserUsePoints>	        		<EMAIL_TAG>ポイント・割引クーポン利用額</EMAIL_TAG>	            	<EMAIL_BEG>：</EMAIL_BEG>					<EMAIL_END>\n</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	        	</UserUsePoints>	        </Member>        </RisaplsCommonInformation>        <AgentNativeInformation>        	<Extend>        		<PointName>        		ポイント・割引クーポン        		</PointName>        		<Points>					<EMAIL_TAG>ポイント・割引クーポン利用額</EMAIL_TAG>	            	<EMAIL_BEG>：</EMAIL_BEG>					<EMAIL_END>\n</EMAIL_END>					 	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	            	         		</Points>        	</Extend>        	<Extendmytrip>        		<SettlementDiv>        			<EMAIL_LOGIC>AND</EMAIL_LOGIC>					<EMAIL_DETAIL>						<EMAIL_TAG>支払方法：</EMAIL_TAG>						<EMAIL_END>\n</EMAIL_END>						<EMIAL_TAG_FORMAT>事前決済</EMIAL_TAG_FORMAT>					</EMAIL_DETAIL>					<EMAIL_DETAIL>						<EMAIL_LOGIC>AND</EMAIL_LOGIC>						<EMAIL_DETAIL>							<EMAIL_TAG>支払方法：</EMAIL_TAG>							<EMAIL_END>\n</EMAIL_END>							<EMIAL_TAG_FORMAT>現金</EMIAL_TAG_FORMAT>						</EMAIL_DETAIL>						<EMAIL_DETAIL>							<EMAIL_LOGIC>OR</EMAIL_LOGIC>							<EMAIL_DETAIL>								<EMAIL_TAG>支払方法：</EMAIL_TAG>								<EMAIL_END>\n</EMAIL_END>								<EMIAL_TAG_FORMAT>現金</EMIAL_TAG_FORMAT>								<CONVERT_VAL>1</CONVERT_VAL>							</EMAIL_DETAIL>							<EMAIL_DETAIL>								<EMAIL_TAG>支払方法：</EMAIL_TAG>								<EMAIL_END>\n</EMAIL_END>								<EMIAL_TAG_FORMAT>事前決済</EMIAL_TAG_FORMAT>								<CONVERT_VAL>2</CONVERT_VAL>							</EMAIL_DETAIL>						</EMAIL_DETAIL>					</EMAIL_DETAIL>        		</SettlementDiv>        	</Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation>        <CUSTOMER_SETTING>		<OBJECT>			<NAME>Lead__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Field354__c">					<EMAIL_TAG>●食事</EMAIL_TAG>		            <EMAIL_BEG>：</EMAIL_BEG>		            <EMAIL_END>\n</EMAIL_END>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>	</CUSTOMER_SETTING></AllotmentBookingReport>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	ApplicationFormPdfConfig.id = null;
    	insert ApplicationFormPdfConfig;	
	}
	private static void insertDoc2() {
		Document ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailTemplateForYoyakuPro';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId();
        String mapString = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>	<TransactionType START_TAG="■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■" END_TAG="【宿泊代表者氏名】">		<DataFrom>FromMailImport</DataFrom>		<DataClassification>			<EMAIL_DETAIL>				<EMIAL_TAG_FORMAT>キャンセルメール</EMIAL_TAG_FORMAT>				<CONVERT_VAL>CancellationReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>            	<EMIAL_TAG_FORMAT>新規予約メール</EMIAL_TAG_FORMAT>            	<CONVERT_VAL>NewBookReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>	            <EMIAL_TAG_FORMAT>予約変更メール</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>ModificationReport</CONVERT_VAL>			</EMAIL_DETAIL>		</DataClassification>        <DataID>            <EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>            <EMAIL_END>(</EMAIL_END>        </DataID>	</TransactionType>	<AccommodationInformation>		<AccommodationName>元湯陣屋</AccommodationName>		<AccommodationCode>02</AccommodationCode>	</AccommodationInformation>	<SalesOfficeInformation>		<SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>		<SalesOfficeCompanyCode></SalesOfficeCompanyCode>	</SalesOfficeInformation>	<BasicInformation START_TAG="メール＞=========" END_TAG="料金明細">>		<TravelAgencyBookingNumber>			<EMAIL_TAG>予約Ｎｏ：</EMAIL_TAG>            <EMAIL_END>(</EMAIL_END>		</TravelAgencyBookingNumber>		<TravelAgencyBookingDate>			<EMAIL_TAG>受付時間：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>            <EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		</TravelAgencyBookingDate>        <TravelAgencyBookingTime>            <EMAIL_TAG>受付時間：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>            <EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>        </TravelAgencyBookingTime>		<GuestOrGroupNameDoubleByte>            <EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>		</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>        	<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>            <EMAIL_END>様</EMAIL_END>       	</GuestOrGroupNameKanjiName>       	<CheckInDate>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>				<EMAIL_END>)</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>				<EMAIL_END>)</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       	</CheckInDate>        <CheckInTime>        	<EMAIL_DETAIL>       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>				<EMAIL_BEG>)</EMAIL_BEG>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>				<EMAIL_BEG>)</EMAIL_BEG>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1})時([0-9]{2}|[0-9]{1})分</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>       		</EMAIL_DETAIL>        </CheckInTime>        <Nights>        	<EMAIL_TAG>○泊数</EMAIL_TAG>            <EMAIL_END>泊</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>        </Nights>        <TotalRoomCount>        	<EMAIL_TAG>○部屋数</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>部屋</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>        </TotalRoomCount>        <PackagePlanCode>        	<EMAIL_TAG>○プラン名</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>        </PackagePlanCode>        <PackagePlanName>       		<EMAIL_DETAIL>	        	<EMAIL_TAG>○プラン名</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>\n</EMAIL_END>       		</EMAIL_DETAIL>        </PackagePlanName>		<RoomTypeCode>            <EMAIL_TAG>○部屋タイプ</EMAIL_TAG>            <EMAIL_BEG>(</EMAIL_BEG>            <EMAIL_END>)</EMAIL_END>		</RoomTypeCode>		<RoomTypeName>			<EMAIL_DETAIL>				<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>(</EMAIL_END>            </EMAIL_DETAIL>            <EMAIL_DETAIL>	        	<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>)</EMAIL_END>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>	        	<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>	        	<EMAIL_BEG>：</EMAIL_BEG>	        	<EMAIL_END>○プラン名</EMAIL_END>       		</EMAIL_DETAIL>		</RoomTypeName>		<OtherServiceInformation>			<EMAIL_DETAIL>			<EMAIL_TAG>○プラン名</EMAIL_TAG>            <EMAIL_BEG>\n</EMAIL_BEG>            <EMAIL_END>---------</EMAIL_END>            </EMAIL_DETAIL>            <EMAIL_DETAIL>				<EMAIL_TAG>○ご要望・ご質問</EMAIL_TAG>        		<EMAIL_BEG>：</EMAIL_BEG>            	<EMAIL_END>\n</EMAIL_END>			</EMAIL_DETAIL>		</OtherServiceInformation>			</BasicInformation>	<BasicRateInformation>		<RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>  		 IncludingServiceWithOutTax/IncludingServiceAndTax/WithoutSerivceAndTax 	<TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>		 		<Payment></Payment>				<TotalAccommodationCharge>        	<EMAIL_TAG>【合計金額】</EMAIL_TAG>			<EMAIL_END>円</EMAIL_END>           	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>		</TotalAccommodationCharge>	</BasicRateInformation>	<RoomAndGuestInformation orderType="1"  START_TAG="料金明細" SPLIT_TAG="泊目,部屋目：">				<RoomInformation >			 			<RoomTypeCode></RoomTypeCode>			<RoomTypeName>				<EMAIL_TAG>○部屋タイプ</EMAIL_TAG>				<EMAIL_BEG>：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>			</RoomTypeName>						<PerRoomPaxCount>				<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>			</PerRoomPaxCount>            <RoomPaxMaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>男性</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomPaxMaleCount>            <RoomPaxFemaleCount>	            	<EMAIL_TAG>大人</EMAIL_TAG>					<EMAIL_BEG>女性</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomPaxFemaleCount>            <RoomChildA70Count>            	<EMAIL_TAG>小学生</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildA70Count>             <RoomChildB50Count>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>            </RoomChildB50Count>            <RoomChildC30Count>            	<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildC30Count>            <RoomChildDNoneCount>            	<EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildDNoneCount>                        <RoomChildDNoneCount>0</RoomChildDNoneCount> 		</RoomInformation>		<RoomRateInformation >			<PerPaxRate>				<EMAIL_DETAIL>					<EMAIL_TAG>大人</EMAIL_TAG>	            	<EMAIL_BEG>名)</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>            	<EMAIL_DETAIL>					<EMAIL_TAG>大人</EMAIL_TAG>	            	<EMAIL_BEG>名)</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>			</PerPaxRate>			<PerChildA70Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小学生</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>            	<EMAIL_DETAIL>					<EMAIL_TAG>小学生</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>            	</EMAIL_DETAIL>			</PerChildA70Rate>			<PerChildB50Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>			</PerChildB50Rate>			<PerChildC30Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>）</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>	            	<EMAIL_BEG>(</EMAIL_BEG>					<EMAIL_END>)</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>							</PerChildC30Rate>			<PerChildDRate></PerChildDRate>			<TotalPerRoomRate>				<EMAIL_TAG>【合計金額】</EMAIL_TAG>					<EMAIL_END>円</EMAIL_END>				<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</TotalPerRoomRate>			<TotalRoomHotSpringTax>			<EMAIL_DETAIL>			<EMAIL_TAG>入湯税</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalRoomHotSpringTax>			<TotalPerRoomServiceFee>			<EMAIL_DETAIL>			<EMAIL_TAG>サービス料</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalPerRoomServiceFee>			 		</RoomRateInformation>		<GuestInformation>			<GuestInformationList>				<GuestNameSingleByte>					<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>		        	<EMAIL_BEG>(</EMAIL_BEG>		        	<EMAIL_END>)</EMAIL_END>				</GuestNameSingleByte>				<GuestKanjiName>					<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>            		<EMAIL_END>様</EMAIL_END>				</GuestKanjiName>				<GuestDateOfBirth>					<EMAIL_TAG>○誕生日</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>				</GuestDateOfBirth>			</GuestInformationList>		</GuestInformation>	</RoomAndGuestInformation>	<RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>66</SalesOfficeCompanyCode>                <PhoneNumber>                	<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                    <EMAIL_BEG>【電話番号】</EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([-0-9]+)</EMIAL_TAG_FORMAT>                </PhoneNumber>                <Email>               		<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                	<EMAIL_BEG>【メールアドレス】</EMAIL_BEG>                	<EMAIL_END>\n</EMAIL_END>                </Email>                <PostalCode>                	<EMAIL_TAG>【住所】</EMAIL_TAG>                	<EMAIL_BEG>〒</EMAIL_BEG>                	<EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>                </PostalCode>                <Address>                    <EMAIL_TAG>【住所】</EMAIL_TAG>                    <EMAIL_BEG> </EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([\u4e00-\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>                </Address>            </Basic>        </RisaplsCommonInformation>        <AgentNativeInformation>        	<Extend>        		         		<PointName>        		        		</PointName>        		<Points>        		        		</Points>         		        	</Extend>        	<Extendmytrip>        		 <SettlementDiv></SettlementDiv>         	</Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation>    <CUSTOMER_SETTING>		<OBJECT>			<NAME>Lead__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Field375__c">					<EMAIL_DETAIL>		       			<EMAIL_TAG>○チェックイン日時：</EMAIL_TAG>						<EMAIL_END>)</EMAIL_END>			            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>						<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       		</EMAIL_DETAIL>		       		<EMAIL_DETAIL>		       			<EMAIL_TAG>○ご利用日時</EMAIL_TAG>						<EMAIL_END>)</EMAIL_END>			            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>						<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       		</EMAIL_DETAIL>		       	</EMAIL_FIELD>		       	<EMAIL_FIELD apiname="Field305__c">			       	<EMIAL_TAG_FORMAT>○ご利用日時</EMIAL_TAG_FORMAT>			       	<CONVERT_VAL>TRUE</CONVERT_VAL>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>		<OBJECT>			<NAME>LeadIndex__c</NAME>			<MAPPINGS>			 	<EMAIL_FIELD apiname="Rooms__c">				 	<EMAIL_TAG>○部屋数</EMAIL_TAG>				 	<EMAIL_BEG>：</EMAIL_BEG>	            	<EMAIL_END>部屋</EMAIL_END>			 	</EMAIL_FIELD> 				  <EMAIL_FIELD apiname="RoomTypeRef__c">○部屋タイプ</EMAIL_FIELD>				<EMAIL_FIELD apiname="PlanRef__c">○プラン名</EMAIL_FIELD>				<EMAIL_FIELD apiname="No__c">予約Ｎｏ</EMAIL_FIELD>				<EMAIL_FIELD apiname="No__c">予約Ｎｏ</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>				<OBJECT>			<NAME>LeadIndex__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Name1__c">宿泊代表者氏名</EMAIL_FIELD>				<EMAIL_FIELD apiname="Phone">【電話番号】</EMAIL_FIELD>				<EMAIL_FIELD apiname="Email">【メールアドレス】</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>		 		 <OBJECT>			<NAME>Contact</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Birthdate">					<EMAIL_TAG>○誕生日</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>            		<EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>					<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>		       	</EMAIL_FIELD>		       	<EMAIL_FIELD apiname="MobilePhone">					<EMAIL_TAG>携帯電話番号[Mobile Phone Number]</EMAIL_TAG>            		<EMAIL_BEG>：</EMAIL_BEG>            		<EMAIL_END>\n</EMAIL_END>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>			</CUSTOMER_SETTING></AllotmentBookingReport>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	insert ApplicationFormPdfConfig;
    	ApplicationFormPdfConfig = new Document();
		ApplicationFormPdfConfig.Name = 'EmailTemplateForIkyuu';
		ApplicationFormPdfConfig.DeveloperName = ApplicationFormPdfConfig.Name;
    	ApplicationFormPdfConfig.FolderId = UserInfo.getUserId(); 
    	mapString = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>	<TransactionType>		<DataFrom>FromMailImport</DataFrom>		<DataClassification>			<EMAIL_DETAIL>				<EMIAL_TAG_FORMAT>◆予約取消のお知らせ</EMIAL_TAG_FORMAT>				<CONVERT_VAL>CancellationReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>            	<EMIAL_TAG_FORMAT>◆予約受付のお知らせ</EMIAL_TAG_FORMAT>            	<CONVERT_VAL>NewBookReport</CONVERT_VAL>			</EMAIL_DETAIL>			<EMAIL_DETAIL>	            <EMIAL_TAG_FORMAT>◆予約内容一部変更のお知らせ</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>ModificationReport</CONVERT_VAL>			</EMAIL_DETAIL>		</DataClassification>        <DataID>            <EMAIL_TAG>●予約番号</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>        </DataID>        <!--         <TravelAgencyBookingDate></TravelAgencyBookingDate>        <TravelAgencyBookingTime></TravelAgencyBookingTime>        -->	</TransactionType>	<AccommodationInformation>		<AccommodationName>元湯陣屋</AccommodationName>		<AccommodationCode>02</AccommodationCode>	</AccommodationInformation>	<SalesOfficeInformation>		<SalesOfficeCompanyName>一休.com</SalesOfficeCompanyName>		<SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>	</SalesOfficeInformation>	<BasicInformation START_TAG="●予約番号" END_TAG="■明細■">>		<TravelAgencyBookingNumber>            <EMAIL_TAG>●予約番号</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>		</TravelAgencyBookingNumber>		<GuestOrGroupNameDoubleByte>            <EMAIL_TAG>●宿泊代表者氏名</EMAIL_TAG>        	<EMAIL_BEG>(</EMAIL_BEG>        	<EMAIL_END>)</EMAIL_END>		</GuestOrGroupNameDoubleByte>        <GuestOrGroupNameKanjiName>        	<EMAIL_TAG>●宿泊代表者氏名</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>(</EMAIL_END>       	</GuestOrGroupNameKanjiName>       	<CheckInDate>       		<EMAIL_TAG>●到着日</EMAIL_TAG>			<EMAIL_BEGIN>：</EMAIL_BEGIN>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>       	</CheckInDate>        <CheckInTime>			<EMAIL_DETAIL>				<EMAIL_TAG>●到着日</EMAIL_TAG>				<EMAIL_BEG>到着予定時間：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG>●到着日</EMAIL_TAG>				<EMAIL_BEG>C/IN可能時間：</EMAIL_BEG>				<EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>				<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>			</EMAIL_DETAIL>        </CheckInTime>        <CheckOutDate>       		<EMAIL_TAG>●出発日</EMAIL_TAG>			<EMAIL_BEGIN>：</EMAIL_BEGIN>            <EMIAL_TAG_FORMAT>([0-9]{4})年([0-9]{1}|[0-9]{2})月([0-9]{1}|[0-9]{2})日</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>-</EMAIL_TAG_FORMAT_JOINKEY>        </CheckOutDate>        <CheckOutTime>        	<EMAIL_TAG>●出発日</EMAIL_TAG>			<EMAIL_BEG>C/OUT時間：</EMAIL_BEG>			<EMAIL_END>\n</EMAIL_END>            <EMIAL_TAG_FORMAT>([0-9]{2}|[0-9]{1}):([0-9]{2}|[0-9]{1})</EMIAL_TAG_FORMAT>			<EMAIL_TAG_FORMAT_JOINKEY>:</EMAIL_TAG_FORMAT_JOINKEY>        </CheckOutTime>        <PackagePlanName>        	<EMAIL_TAG>●プラン名称</EMAIL_TAG>        	<EMAIL_BEG>：</EMAIL_BEG>        	<EMAIL_END>[</EMAIL_END>        </PackagePlanName>        <PackagePlanCode>        	<EMAIL_TAG>●プラン名称</EMAIL_TAG>        	<EMAIL_BEG>[</EMAIL_BEG>        	<EMAIL_END>]</EMAIL_END>        </PackagePlanCode>  		<RoomTypeCode>            <EMAIL_TAG>●部屋名称</EMAIL_TAG>            <EMAIL_BEG>[</EMAIL_BEG>            <EMAIL_END>]</EMAIL_END>		</RoomTypeCode>		<RoomTypeName>            <EMAIL_DETAIL>				<EMAIL_TAG>●部屋名称</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>[</EMAIL_END>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG>●部屋名称</EMAIL_TAG>	            <EMAIL_BEG>：</EMAIL_BEG>	            <EMAIL_END>\n</EMAIL_END>			</EMAIL_DETAIL>		</RoomTypeName>        <OtherServiceInformation>        	<EMAIL_LOGIC>SUM</EMAIL_LOGIC>        	<EMAIL_DETAIL>				<EMAIL_TAG saveKey="true">■質問・回答■</EMAIL_TAG>        		<EMAIL_END>---------------------------------------------------------</EMAIL_END>			</EMAIL_DETAIL>			<EMAIL_DETAIL>				<EMAIL_TAG saveKey="true">■コメント■</EMAIL_TAG>        		<EMAIL_END>---------------------------------------------------------</EMAIL_END>			</EMAIL_DETAIL>        </OtherServiceInformation>        <!--          <MealCondition>			<EMAIL_TAG>●食事</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>		</MealCondition>		-->		<Option>			<EMAIL_TAG>●オプション</EMAIL_TAG>            <EMAIL_BEG>：</EMAIL_BEG>            <EMAIL_END>\n</EMAIL_END>            <EMIAL_TAG_FORMAT>なし</EMIAL_TAG_FORMAT>            <CONVERT_VAL></CONVERT_VAL>		</Option>    </BasicInformation>    <BasicRateInformation START_TAG="■宿泊内容■" END_TAG="■明細■">    	<RoomRateOrPersonalRate>RoomRate</RoomRateOrPersonalRate>        <TaxServiceFee>			<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税・サービス料込</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>IncludingServiceAndTax</CONVERT_VAL>			</EMAIL_DETAIL>        	<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税別・サービス料込</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>IncludingServiceWithoutTax</CONVERT_VAL>       		</EMAIL_DETAIL>       		<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税別・サービス料別</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>WithoutServiceAndTax</CONVERT_VAL>	        </EMAIL_DETAIL>        	<EMAIL_DETAIL>	            <EMAIL_TAG>支払金額：</EMAIL_TAG>	            <EMAIL_END>\n</EMAIL_END>	            <EMIAL_TAG_FORMAT>消費税込・サービス料別</EMIAL_TAG_FORMAT>	            <CONVERT_VAL>WithoutServiceAndIncludingTax</CONVERT_VAL>       		</EMAIL_DETAIL>       	</TaxServiceFee>        <Payment>            <EMAIL_TAG>支払方法：</EMAIL_TAG>            <EMAIL_END>\n</EMAIL_END>            <EMAIL_EXCULDE>事前決済</EMAIL_EXCULDE>        </Payment>        <TotalAccommodationCharge>            <EMAIL_TAG>支払金額：</EMAIL_TAG>            <EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>        </TotalAccommodationCharge>        <CouponList>        	<CouponAmount>        		<EMAIL_TAG>割引クーポン利用額</EMAIL_TAG>        		<EMAIL_BEG>：</EMAIL_BEG>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>        	</CouponAmount>        	<CouponType>割引クーポン利用額</CouponType>        </CouponList>    </BasicRateInformation>	<RoomAndGuestInformation orderType="2"  								START_TAG="■明細■" 								END_TAG="============================================================"						SPLIT_TAG="泊目,部屋目">		<RoomInformation >			<PerRoomPaxCount>				<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>			</PerRoomPaxCount>            <RoomPaxMaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>男性：</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>            </RoomPaxMaleCount>            <RoomPaxFemaleCount>            	<EMAIL_TAG>大人</EMAIL_TAG>				<EMAIL_BEG>女性：</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9]+)</EMIAL_TAG_FORMAT>            </RoomPaxFemaleCount>                        <RoomChildA70Count>            	<EMAIL_TAG>小学生</EMAIL_TAG>				<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildA70Count>            <RoomChildB50Count>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>	            <EMAIL_DETAIL>	            	<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>×</EMAIL_BEG>					<EMAIL_END>名</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>	            </EMAIL_DETAIL>            </RoomChildB50Count>            <RoomChildC30Count>            	<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildC30Count>            <RoomChildDNoneCount>            	<EMAIL_TAG>小児（布団のみ）</EMAIL_TAG>            	<EMAIL_BEG>×</EMAIL_BEG>				<EMAIL_END>名</EMAIL_END>            	<EMIAL_TAG_FORMAT>([0-9])</EMIAL_TAG_FORMAT>            </RoomChildDNoneCount>		</RoomInformation>		<RoomRateInformation >			<PerPaxRate>				<EMAIL_TAG>大人</EMAIL_TAG>            	<EMAIL_BEG>名）</EMAIL_BEG>				<EMAIL_END>×</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerPaxRate>			<PerChildA70Rate>				<EMAIL_TAG>小学生</EMAIL_TAG>            	<EMAIL_BEG>(</EMAIL_BEG>				<EMAIL_END>円</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerChildA70Rate>			<PerChildB50Rate>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団なし）</EMAIL_TAG>	            	<EMAIL_BEG>\\</EMAIL_BEG>					<EMAIL_END>×</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>				<EMAIL_DETAIL>					<EMAIL_TAG>小児（食事布団あり）</EMAIL_TAG>	            	<EMAIL_BEG>\\</EMAIL_BEG>					<EMAIL_END>×</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</EMAIL_DETAIL>			</PerChildB50Rate>			<PerChildC30Rate>				<EMAIL_TAG>小児（食事のみ）</EMAIL_TAG>            	<EMAIL_BEG>\\</EMAIL_BEG>				<EMAIL_END>×</EMAIL_END>            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</PerChildC30Rate>			<PerChildDRate></PerChildDRate>			<TotalPerRoomRate>				<EMAIL_TAG>【合計金額】</EMAIL_TAG>					<EMAIL_END>円</EMAIL_END>				<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>				</TotalPerRoomRate>			<TotalRoomHotSpringTax>			<EMAIL_DETAIL>			<EMAIL_TAG>入湯税</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalRoomHotSpringTax>			<TotalPerRoomServiceFee>			<EMAIL_DETAIL>			<EMAIL_TAG>サービス料</EMAIL_TAG>			<EMAIL_BEG>=</EMAIL_BEG>			<EMAIL_END>円</EMAIL_END>			<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>			</EMAIL_DETAIL>			</TotalPerRoomServiceFee>		</RoomRateInformation>	</RoomAndGuestInformation>		<RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramData>                	<EMAIL_TAG></EMAIL_TAG>                </TelegramData><!-- 空白のまま -->                <PhoneNumber>                	<EMAIL_TAG>宿泊代表者連絡先</EMAIL_TAG>                	<EMAIL_BEG>：</EMAIL_BEG>                    <EMAIL_END>(</EMAIL_END>                    <EMIAL_TAG_FORMAT>([-0-9]+)</EMIAL_TAG_FORMAT>                </PhoneNumber>                <!--                 <Email>               		<EMAIL_TAG>【宿泊代表者氏名】</EMAIL_TAG>                	<EMAIL_BEG>【メールアドレス】</EMAIL_BEG>                	<EMAIL_END>&lt;</EMAIL_END>                	<EMIAL_TAG_FORMAT>(^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$)</EMIAL_TAG_FORMAT>                </Email>                <PostalCode>                	<EMAIL_TAG>【住所】</EMAIL_TAG>                	<EMAIL_BEG>〒</EMAIL_BEG>                	<EMIAL_TAG_FORMAT>(\\d{3}-\\d{4})</EMIAL_TAG_FORMAT>                </PostalCode>                <Address>                    <EMAIL_TAG>【住所】</EMAIL_TAG>                    <EMAIL_BEG> </EMAIL_BEG>                    <EMAIL_END>\n</EMAIL_END>                    <EMIAL_TAG_FORMAT>([\\u4e00-\\u9fa5]+[-0-9]+)</EMIAL_TAG_FORMAT>                </Address>                 -->            </Basic>            <Member>	        	<UserUsePoints>	        		<EMAIL_TAG>ポイント・割引クーポン利用額</EMAIL_TAG>	            	<EMAIL_BEG>：</EMAIL_BEG>					<EMAIL_END>\n</EMAIL_END>	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	        	</UserUsePoints>	        </Member>        </RisaplsCommonInformation>        <AgentNativeInformation>        	<Extend>        		<PointName>        		ポイント・割引クーポン        		</PointName>        		<Points>					<EMAIL_TAG>ポイント・割引クーポン利用額</EMAIL_TAG>	            	<EMAIL_BEG>：</EMAIL_BEG>					<EMAIL_END>\n</EMAIL_END>					 	            	<EMIAL_TAG_FORMAT>([,0-9]+)</EMIAL_TAG_FORMAT>	            	         		</Points>        	</Extend>        	<Extendmytrip>        		<SettlementDiv>        			<EMAIL_LOGIC>AND</EMAIL_LOGIC>					<EMAIL_DETAIL>						<EMAIL_TAG>支払方法：</EMAIL_TAG>						<EMAIL_END>\n</EMAIL_END>						<EMIAL_TAG_FORMAT>事前決済</EMIAL_TAG_FORMAT>					</EMAIL_DETAIL>					<EMAIL_DETAIL>						<EMAIL_LOGIC>AND</EMAIL_LOGIC>						<EMAIL_DETAIL>							<EMAIL_TAG>支払方法：</EMAIL_TAG>							<EMAIL_END>\n</EMAIL_END>							<EMIAL_TAG_FORMAT>現金</EMIAL_TAG_FORMAT>						</EMAIL_DETAIL>						<EMAIL_DETAIL>							<EMAIL_LOGIC>OR</EMAIL_LOGIC>							<EMAIL_DETAIL>								<EMAIL_TAG>支払方法：</EMAIL_TAG>								<EMAIL_END>\n</EMAIL_END>								<EMIAL_TAG_FORMAT>現金</EMIAL_TAG_FORMAT>								<CONVERT_VAL>1</CONVERT_VAL>							</EMAIL_DETAIL>							<EMAIL_DETAIL>								<EMAIL_TAG>支払方法：</EMAIL_TAG>								<EMAIL_END>\n</EMAIL_END>								<EMIAL_TAG_FORMAT>事前決済</EMIAL_TAG_FORMAT>								<CONVERT_VAL>2</CONVERT_VAL>							</EMAIL_DETAIL>						</EMAIL_DETAIL>					</EMAIL_DETAIL>        		</SettlementDiv>        	</Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation>        <CUSTOMER_SETTING>		<OBJECT>			<NAME>Lead__c</NAME>			<MAPPINGS>				<EMAIL_FIELD apiname="Field354__c">					<EMAIL_TAG>●食事</EMAIL_TAG>		            <EMAIL_BEG>：</EMAIL_BEG>		            <EMAIL_END>\n</EMAIL_END>		       	</EMAIL_FIELD>			</MAPPINGS>		</OBJECT>	</CUSTOMER_SETTING></AllotmentBookingReport>';
    	ApplicationFormPdfConfig.Body = Blob.valueOf(mapString);
    	ApplicationFormPdfConfig.id = null;
    	insert ApplicationFormPdfConfig;	
	}
	public static JMST__c createTaxMst() {
    	JMST__c item = new JMST__c(
    	   TaxRate__c = 5
    	);
    	insert item;
    	// 室単料　会計商品
        AccountMaster__c shitulyoItem = new AccountMaster__c(
           Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME,
           ActionType__c = CommConst.PROD_ACTION_TYPE_RP,
           jmstRef__c = item.Id,
           StsTaxfee__c = '0',
           Field3__c = '100999',         // 商品コード
           Field5__c = 1050,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert shitulyoItem;
    	return item;
    }
	public static List<AccountMaster__c> createProductMst(Integer intNum) {
    	List<AccountMaster__c> insLst = new List<AccountMaster__c>();
    	Plan__c plan = new Plan__c();
    	JMST__c taxMst =  createTaxMst();
        for (Integer i =0; i < intNum; i++) {
	        AccountMaster__c item = new AccountMaster__c(
	           Name = plan.name,
	           jmstRef__c = taxMst.Id,
	           jmstRef__r = taxMst,
	           StsTaxfee__c = '0',
	           Field3__c = '1',         // 商品コード
	           Field5__c = 1050,
	           ServiceRate__c = 10,
	           SpecialTax__c = 100,
	           ActionType__c = CommConst.PROD_ACTION_TYPE_PL
	        );
        	insLst.add(item);
        }
        
        insert insLst; 
        // 入湯料　会計商品
        AccountMaster__c nyuutouItem = new AccountMaster__c(
           Name = '入湯料' + CommUtils.getRandom(9),
           jmstRef__c = taxMst.Id,
           StsTaxfee__c = '0',
           Field3__c = '5041',         // 商品コード
           Field5__c = 150,
           ServiceRate__c = 10,
           SpecialTax__c = 100
        );
        insert nyuutouItem;
        List<String> products = new List<String>{'M99000','M99001','M99002','M99003','M99004','M99005'};
        TestCommon.createPayProductMst(products);
        return insLst;
    }
    public static Plan__c createPlanHadHoomZero(String packageCode){
    	JMST__c taxMst =  TestCommon.createTaxMst();
    	if(CommUtils.isBlank(packageCode)) packageCode = '3333';
    	Plan__c plan = new Plan__c();
    	plan.name = '日帰り温泉入浴とレストランでのお食事プラン';
    	plan.PlanNo__c = CommUtils.getRandom(10);
    	plan.Price__c = 11500;
    	plan.PackageCode__c = '80';
    	plan.JmstRef__c = taxMst.Id;
    	insert plan;
        // 商品情報を作成する
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        productLst[2].Name = CommConst.APPOPTION_ROOMPRICE_PRODNAME;
        productLst[2].ActionType__c = CommConst.PROD_ACTION_TYPE_RP;
        update productLst; 
        
        ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
        PlanProductSetup ctrl = new PlanProductSetup(contrl);
        List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;
        planDeLst[0].productNm = productLst[0].Name;
        planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
        planDeLst[0].sobj.Price__c = 1000;
        planDeLst[0].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[1].productNm = productLst[1].Name;
        planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
        planDeLst[1].sobj.Price__c = 1500;
        planDeLst[2].productNm = productLst[2].Name;
        planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
        planDeLst[2].sobj.Price__c = 0;
        planDeLst[2].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[3].productNm = productLst[3].Name;
        planDeLst[3].sobj.AccountMasterRef__c = productLst[3].Id;
        planDeLst[3].sobj.Price__c = 300;
        planDeLst[3].sobj.taxRate__c = taxMst.taxRate__c;
        planDeLst[4].productNm = productLst[4].Name;
        planDeLst[4].sobj.AccountMasterRef__c = productLst[4].Id;
        planDeLst[4].sobj.Price__c = 500;
        planDeLst[4].sobj.ServiceRate__c = 150;
        planDeLst[4].sobj.taxRate__c = taxMst.taxRate__c;
        ctrl.savePlanDetail();
    	return plan;
    } 
    public static Contact createContact() {
    	Contact item1 = new Contact(
    		firstName = 'テスト　井桁かおる',
    		LastName = 'LASTNAME'+CommUtils.getRandom(6),
    		Katakana__c = 'Katakana__c'+CommUtils.getRandom(10),
    		KanaName1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Name1__c = 'KanaName1__c'+CommUtils.getRandom(10),
    		Phone = '0463771300'
    		);
    	insert item1;
    	return item1;
    }
    public static LeadIndex__c createLeadIndex() {
    	LeadIndex__c itemli = new LeadIndex__c(
    		ID__c = String.valueOf(Math.random()),
			EventSource__c = 'テストクラスから',
			Rooms__c = 1
    	);
    	insert itemli;
    	return itemli;
    }
   public static Lead__c createLead() {
    	Lead__c itemlis = new Lead__c(
    	BookingDataID__c = '87364827682',
    	ReservedDate__c = System.now(),
    	StayPersons__c = 4,
    	LeadIndexSubId__c = null,
    	//LeadIndexRef__c = LeadIndex.Id,
    	EntryTime__c = Date.today(),
    	RoomGroupNo__c = 3465
    	
    	);
    	insert itemlis;
    	return itemlis;
    }
    private static String importXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><AllotmentBookingReport>    <TransactionType>        <DataFrom>FromTravelAgency</DataFrom>        <DataClassification>ModificationReport</DataClassification>        <DataID>221866063-2</DataID>        <SystemDate>2015-10-13</SystemDate>    </TransactionType>    <AccommodationInformation>        <AccommodationName>元湯陣屋</AccommodationName>        <AccommodationCode>14000010</AccommodationCode>    </AccommodationInformation>    <SalesOfficeInformation>        <SalesOfficeCompanyName>予約プロ</SalesOfficeCompanyName>        <SalesOfficeName>予約プロ</SalesOfficeName>        <SalesOfficeCode>88</SalesOfficeCode>        <SalesOfficePhoneNumber>052-262-8041</SalesOfficePhoneNumber>    </SalesOfficeInformation>    <BasicInformation>        <TravelAgencyBookingNumber>A005135502</TravelAgencyBookingNumber>        <TravelAgencyBookingDate>2015-10-13</TravelAgencyBookingDate>        <TravelAgencyBookingTime>10:26:55</TravelAgencyBookingTime>        <TravelAgencyReportNumber>00002278</TravelAgencyReportNumber>        <GuestOrGroupNameSingleByte>ｼﾑﾗ ｹﾝｼﾞ _</GuestOrGroupNameSingleByte>        <GuestOrGroupNameKanjiName>志村　健司 _</GuestOrGroupNameKanjiName>        <CheckInDate>2015-10-18</CheckInDate>        <CheckInTime>16:00:00</CheckInTime>        <CheckOutDate>2015-10-20</CheckOutDate>        <Nights>2</Nights>        <TotalRoomCount>1</TotalRoomCount>        <GrandTotalPaxCount>4</GrandTotalPaxCount>        <TotalPaxMaleCount>1</TotalPaxMaleCount>        <TotalPaxFemaleCount>1</TotalPaxFemaleCount>        <TotalChildA70Count>1</TotalChildA70Count>        <TotalChildB50Count>1</TotalChildB50Count>        <TotalChildC30Count>0</TotalChildC30Count>        <TotalChildDNoneCount>0</TotalChildDNoneCount>        <PackagePlanName>本格逸品会席料理を堪能プラン</PackagePlanName>        <PackagePlanCode>233</PackagePlanCode>        <MealCondition>1night2meals</MealCondition>        <SpecificMealCondition>None Specified</SpecificMealCondition>        <ModificationPoint>・宿泊日(2015年10月19日→2015年10月18日)・宿泊人数(2名→4名)</ModificationPoint>        <OtherServiceInformation>○誕生日：1970年1月1日○携帯電話番号[Mobile Phone Number]：0463771303○ご要望・ご質問：テスト予約合計宿泊料金入湯税：300円</OtherServiceInformation>    </BasicInformation>    <BasicRateInformation>        <RoomRateOrPersonalRate>PersonalRate</RoomRateOrPersonalRate>        <TaxServiceFee>IncludingServiceAndTax</TaxServiceFee>        <TotalAccommodationCharge>135084</TotalAccommodationCharge>        <TotalAccommodationHotSpringTax>300</TotalAccommodationHotSpringTax>    </BasicRateInformation>    <RoomAndGuestInformation>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>40</RoomTypeCode>                <RoomTypeName>露天風呂付き客室</RoomTypeName>                <PerRoomPaxCount>4</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>1</RoomChildB50Count>                <RoomChildC30Count>0</RoomChildC30Count>                <RoomChildDNoneCount>0</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2015-10-18</RoomDate>                <PerPaxRate>42120</PerPaxRate>                <PerChildA70Rate>29484</PerChildA70Rate>                <PerChildB50Rate>21060</PerChildB50Rate>                <PerChildC30Rate>0</PerChildC30Rate>                <PerChildDRate>0</PerChildDRate>                <TotalRoomHotSpringTax>300</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>        </RoomAndGuestList>        <RoomAndGuestList>            <RoomInformation>                <RoomTypeCode>40</RoomTypeCode>                <RoomTypeName>露天風呂付き客室</RoomTypeName>                <PerRoomPaxCount>4</PerRoomPaxCount>                <RoomPaxMaleCount>1</RoomPaxMaleCount>                <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                <RoomChildA70Count>1</RoomChildA70Count>                <RoomChildB50Count>1</RoomChildB50Count>                <RoomChildC30Count>0</RoomChildC30Count>                <RoomChildDNoneCount>0</RoomChildDNoneCount>            </RoomInformation>            <RoomRateInformation>                <RoomDate>2015-10-19</RoomDate>                <PerPaxRate>42120</PerPaxRate>                <PerChildA70Rate>29484</PerChildA70Rate>                <PerChildB50Rate>21060</PerChildB50Rate>                <PerChildC30Rate>0</PerChildC30Rate>                <PerChildDRate>0</PerChildDRate>                <TotalRoomHotSpringTax>300</TotalRoomHotSpringTax>                <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>            </RoomRateInformation>        </RoomAndGuestList>    </RoomAndGuestInformation>    <RisaplsInformation>        <RisaplsCommonInformation>            <Basic>                <SalesOfficeCompanyCode>80</SalesOfficeCompanyCode>                <TelegramDiv></TelegramDiv>                <RisaplsDataID></RisaplsDataID>                <RisaplsTelegramNumber></RisaplsTelegramNumber>                <TelegramData>変更通知 予約プロ                                      SNT-NET 10-13 10:27 (88) 予約番号： A005135502  NO.00002278 元湯陣屋様(14000010)宿泊者情報：  志村　健司 _  TEL:0463771303  ｼﾑﾗ ｹﾝｼﾞ _  Mail:kenji_shimura@jinya-connect.com  住所:(〒257-0001)神奈川県秦野市鶴巻北2-8-24プラン名：本格逸品会席料理を堪能プラン(233)2015年10月18日から    1泊  ２食付  サ込税込入込方法：                   チェックイン時間：16:00人員総数：   4人  内訳：(男)1名+(女)1名+(Ａ)1名+(Ｂ)1名客室総数：   1室10月18日  4  (露天風呂付き客室)          大人（男）     1名    @42,120          大人（女）     1名    @42,120          子供Ａ         1名    @29,484  小学生          子供Ｂ         1名    @21,060  小児（食事布団あり）                                   宿泊料金計                ：   \\134,784                       合計料金                              ：   \\135,084                     【宿泊者への請求額】                    ：   \\135,084           ---------------------------------------------------------------------                                                                  (入湯税：\\300)ご確認事項：○誕生日：1970年1月1日○携帯電話番号[Mobile Phone Number]：0463771303○ご要望・ご質問：テスト予約合計宿泊料金入湯税：300円【★変更箇所説明★】・宿泊日(2015年10月19日→2015年10月18日)・宿泊人数(2名→4名)取扱個所：予約プロ(88)  TEL 052-262-8041  FAX 052-262-8042---</TelegramData>                <PhoneNumber>0463771303</PhoneNumber>                <Email>kenji_shimura@jinya-connect.com</Email>                <PostalCode>257-0001</PostalCode>                <Address>神奈川県秦野市鶴巻北2-8-24</Address>                <TotalPaxManCount>2</TotalPaxManCount>                <BranchFaxNumber>052-262-8042</BranchFaxNumber>                <Version>2.0</Version>                <AccommodationId>X36969</AccommodationId>            </Basic>            <Allotment>                <AssignDiv>1</AssignDiv>                <GenderDiv>1</GenderDiv>                <HandleDiv>1</HandleDiv>                <RsvUserDiv>0</RsvUserDiv>                <UseDiv>0</UseDiv>            </Allotment>            <RoomAndRoomRateInformation>                <RoomInformation>                    <RoomTypeCode>6</RoomTypeCode>                    <RoomTypeName>露天風呂付き客室</RoomTypeName>                    <PerRoomPaxCount>4</PerRoomPaxCount>                    <RoomPaxMaleCount>1</RoomPaxMaleCount>                    <RoomPaxFemaleCount>1</RoomPaxFemaleCount>                    <RoomChildA70Count>1</RoomChildA70Count>                    <RoomChildB50Count>1</RoomChildB50Count>                    <RoomChildC30Count>0</RoomChildC30Count>                    <RoomChildDNoneCount>0</RoomChildDNoneCount>                    <RoomChildA70Request>小学生</RoomChildA70Request>                    <RoomChildB50Request>小児（食事布団あり）</RoomChildB50Request>                    <RoomChildC30Request>小児（食事のみ）</RoomChildC30Request>                    <RoomChildDNoneRequest>小児（布団のみ）</RoomChildDNoneRequest>                    <RoomTypeAgent>88</RoomTypeAgent>                    <RoomFrame>--</RoomFrame>                    <NetRmTypeGroupCode>47</NetRmTypeGroupCode>                    <PlanGroupCode>68</PlanGroupCode>                </RoomInformation>                <RoomRateInformation>                    <RoomDate>2015-10-18</RoomDate>                    <PerPaxRate>42120</PerPaxRate>                    <PerChildA70Rate>29484</PerChildA70Rate>                    <PerChildB50Rate>21060</PerChildB50Rate>                    <PerChildC30Rate>0</PerChildC30Rate>                    <PerChildDRate>0</PerChildDRate>                    <TotalRoomHotSpringTax>300</TotalRoomHotSpringTax>                    <TotalPerRoomServiceFee>0</TotalPerRoomServiceFee>                    <PerMaleRate>42120</PerMaleRate>                    <PerFemaleRate>42120</PerFemaleRate>                    <RoomRatePaxMaleCount>1</RoomRatePaxMaleCount>                    <RoomRatePaxFemaleCount>1</RoomRatePaxFemaleCount>                    <RoomRateChildA70Count>1</RoomRateChildA70Count>                    <RoomRateChildB50Count>1</RoomRateChildB50Count>                    <RoomRateChildC30Count>0</RoomRateChildC30Count>                    <RoomRateChildDNoneCount>0</RoomRateChildDNoneCount>                    <RoomRateChildA70Request>小学生</RoomRateChildA70Request>                    <RoomRateChildB50Request>小児（食事布団あり）</RoomRateChildB50Request>                    <RoomRateChildC30Request>小児（食事のみ）</RoomRateChildC30Request>                    <RoomRateChildDNoneRequest>小児（布団のみ）</RoomRateChildDNoneRequest>                </RoomRateInformation>            </RoomAndRoomRateInformation>            <OtherInfo>                <GuestRequest>○誕生日：1970年1月1日○携帯電話番号[Mobile Phone Number]：0463771303○ご要望・ご質問：テスト予約</GuestRequest>                <AdditionalInformation>合計宿泊料金入湯税：300円</AdditionalInformation>            </OtherInfo>        </RisaplsCommonInformation>        <AgentNativeInformation>            <Extend>                <Points>84</Points>                <AmountClaimed>135000</AmountClaimed>            </Extend>            <Extendmytrip>                <SettlementDiv>2</SettlementDiv>            </Extendmytrip>        </AgentNativeInformation>    </RisaplsInformation></AllotmentBookingReport>';
    private static String emailIkkyu = '件名: 【通知連番：10001536 一休.com予約受付】予約番号：IK0207535831 \n'
									+'--------------------------------------------------------- \n'
									+'◆予約受付のお知らせ(通知連番：10001536)◆ \n'
									+'--------------------------------------------------------- \n'
									+'鶴巻温泉　元湯陣屋 御中 \n'
									
									+'いつも大変お世話になっております。 \n'
									+'以下の予約が申し込まれましたので、お手続きをお願い致します。 \n'
									+'--------------------------------------------------------- \n'
									+'●予約番号　　　　：IK0207535831 \n'
									+'●宿泊代表者氏名　：テスト 真也(てすと しんや) \n'
									+'●宿泊代表者連絡先：01012345678(自宅・携帯) \n'
									+'●予約者氏名　　　：テスト 真也( \n'
									
									+'　※お客様へメールにて返信をする場合は、管理画面の \n'
									+'　　「メール送信」機能をご利用ください。 \n'
									+'--------------------------------------------------------- \n'
									+'■宿泊内容■ \n'
									+'●到着日　　　：2016年05月01日（日）C/IN可能時間：15:30 \n'
									+'●出発日　　　：2016年05月03日（火）C/OUT時間：11:00 \n'
									+'●到着予定時間：15:30 \n'
									+'●プラン名称　：【早割35】35日前の予約でお得に！特選会席料理を堪能プラン /夕朝食付/ [C0001] \n'
									+'●部屋名称　　：露天風呂付き客室(和室)[A1] \n'
									+'●宿泊延べ人数：大人2名 \n'
									+'　　[1部屋目] \n'
									+'　　　大人 ： 2名　（男性：1名 女性：1名） \n'
									+'●食事　　　　：夕朝食付 \n'
									+'●オプション　：なし \n'
									+'--------------------------------------------------------- \n'
									+'支払方法：現地決済 \n'
									+'支払金額：\\172,800[消費税・サービス料込] \n'
									+'--------------------------------------------------------- \n'
									+'■支払金額明細■ \n'
									+'　予約金額合計：\\172,800[消費税・サービス料込] \n'
									+'　　　内訳（プラン料金　　　　　　：　\\172,800） \n'
									+'　ポイント・割引クーポン利用額　　：▲\\0 \n'
									+'　現地支払金額　　　　　　　　　　：　\\172,800[消費税・サービス料込] \n'
									+'--------------------------------------------------------- \n'
									+'■質問・回答■ \n'
									+'　・食材のアレルギー等はございますか。 \n'
									+'　　　⇒　ありません。 \n'
									+'　・当日の交通手段を教えて頂けますか？ \n'
									+'　　　⇒　自家用車です。 \n'
									
									+'--------------------------------------------------------- \n'
									+'■明細■ \n'
									+'2016年05月01日（日） \n'
									+'　[1部屋目]：　小計 \\82,080 \n'
									+'　　大人　（男性：1名 女性：1名） \n'
									+'　　　　\\41,040×2名=\\82,080 \n'
									+'2016年05月02日（月） \n'
									+'　[1部屋目]：　小計 \\90,720 \n'
									+'　　大人　（男性：1名 女性：1名） \n'
									+'　　　　\\45,360×2名=\\90,720 \n'
									+'	小児（食事布団なし） \n'
									+'			\\4000×2名=\\90,720 \n'
									+'		 小児（食事布団あり） \n'
									+'	    \\0×2名=\\90,720 \n'
									+'============================================================ \n'
									+'※本メールはシステムより自動送信しております。 \n'
									+'　送信専用のためこのメールにご返信いただいてもお答えすることは出来ませんのでご注意ください。 \n'
									+'============================================================ \n'
									+'一休.com ： http://www.ikyu.com/　運営・企画：株式会社一休 \n'
									+'TEL:03-6685-0065 FAX:03-6685-0080（平日10:00～18:00） \n'
									+'https://www.ikyu.com/accommodation/ap/AsfW10101.aspx; \n';
	private static String emailPointIkyuu = '件名: 【通知連番：10001583 一休.com予約受付】予約番号：IK0208786317 \n'
									+'◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇ \n'
									+'　ポイント・割引クーポン利用がございます。 \n'
									+'　（現地支払金額：\\80,850） \n'
									+'　※金額変更（減額）に伴い、割引額が変わる場合があります。ご注意ください。 \n'
									+'◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆ \n'
									+'--------------------------------------------------------- \n'
									+'◆予約受付のお知らせ(通知連番：10001583)◆ \n'
									+'--------------------------------------------------------- \n'
									+'鶴巻温泉　元湯陣屋 御中 \n'
									+'いつも大変お世話になっております。 \n'
									+'以下の予約が申し込まれましたので、お手続きをお願い致します。 \n'
									+'--------------------------------------------------------- \n'
									+'●予約番号　　　　：IK0208786317 \n'
									+'●宿泊代表者氏名　：松田 テスト(まつだ テスト) \n'
									+'●宿泊代表者連絡先：01012341234(自宅・携帯) \n'
									+'●予約者氏名　　　：松田 テスト \n'

									+'　※お客様へメールにて返信をする場合は、管理画面の \n'
									+'　　「メール送信」機能をご利用ください。 \n'
									+'--------------------------------------------------------- \n'
									+'■宿泊内容■ \n'
									+'●到着日　　　：2016年04月09日（土）C/IN可能時間：15:30 \n'
									+'●出発日　　　：2016年04月10日（日）C/OUT時間：11:00 \n'
									+'●到着予定時間：15:30 \n'
									+'●プラン名称　：＜GWも予約受付中＞【当館一番人気】季節の特選会席料理を堪能プラン /夕朝食付/ [N0006] \n'
									+'●部屋名称　　：露天風呂付き客室(和室)[A1] \n'
									+'●宿泊延べ人数：大人2名 \n'
									+'　　[1部屋目] \n'
									+'　　　大人 ： 2名　（男性：1名 女性：1名） \n'
									+'●食事　　　　：夕朝食付 \n'
									+'●オプション　：なし \n'
									+'--------------------------------------------------------- \n'
									+'支払方法：現地決済 \n'
									+'支払金額：\\80,850[消費税・サービス料込] \n'
									+'--------------------------------------------------------- \n'
									+'■支払金額明細■ \n'
									+'　予約金額合計：\\82,080[消費税・サービス料込] \n'
									+'　　　内訳（プラン料金　　　　　　：　\\82,080） \n'
									+'　ポイント・割引クーポン利用額　　：▲\\1,230 \n'
									+'　現地支払金額　　　　　　　　　　：　\\80,850[消費税・サービス料込] \n'
									+'--------------------------------------------------------- \n'
									+'■質問・回答■ \n'
									+'　・食材のアレルギー等はございますか。 \n'
									+'　　　⇒　いいえ \n'
									+'　・当日の交通手段を教えて頂けますか？ \n'
									+'　　　⇒　電車 \n'
									+'--------------------------------------------------------- \n'
									+'■明細■ \n'
									+'2016年04月09日（土） \n'
									+'　[1部屋目]：　小計 \\82,080 \n'
									+'　　大人　（男性：1名 女性：1名） \n'
									+'　　　　\\41,040×2名=\\82,080 \n'
									+'============================================================ \n'
									+'※本メールはシステムより自動送信しております。 \n'
									+'　送信専用のためこのメールにご返信いただいてもお答えすることは出来ませんのでご注意ください。 \n'
									+'============================================================ \n'
									+'一休.com ： http://www.ikyu.com/　運営・企画：株式会社一休 \n'
									+'TEL:03-6685-0065 FAX:03-6685-0080（平日10:00～18:00） \n'
									+'https://www.ikyu.com/accommodation/ap/AsfW10101.aspx';
    private static void insertCsvSetupConfig() {
    	/*
        String csv = '<?xml version="1.0" encoding="UTF-8"?><root><SHOP><SHOPCODE></SHOPCODE><PAYMENT><CONVERT><PAYTYPE>現金</PAYTYPE><MEIDALAB>預り／現計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>カード</PAYTYPE><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB></CONVERT><CONVERT><PAYTYPE>売掛金</PAYTYPE><MEIDALAB>掛計</MEIDALAB></CONVERT><CONVERT><PAYTYPE>クーポン</PAYTYPE><MEIDALAB>クーポン</MEIDALAB></CONVERT><CONVERT><PAYTYPE>値引</PAYTYPE><MEIDALAB>値引・割引券</MEIDALAB></CONVERT><CONVERT><PAYTYPE>予約金</PAYTYPE><MEIDALAB>予約金</MEIDALAB></CONVERT></PAYMENT><PAYMEIDA><CONVERT><MEIDALAB>預り／現計</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT><CONVERT><MEIDALAB>ｸﾚ計・掛計等</MEIDALAB><PRODCODE>85201</PRODCODE></CONVERT><CONVERT><MEIDALAB>掛計</MEIDALAB><PRODCODE>85101</PRODCODE></CONVERT><CONVERT><MEIDALAB>クーポン</MEIDALAB><PRODCODE>85610</PRODCODE></CONVERT><CONVERT><MEIDALAB>値引・割引券</MEIDALAB><PRODCODE>87005</PRODCODE></CONVERT><CONVERT><MEIDALAB>予約金</MEIDALAB><PRODCODE>87001</PRODCODE></CONVERT></PAYMEIDA></SHOP></root>';
        Document doc = new Document();
        doc.Name = 'BillSimpleHelpConfig';
        doc.DeveloperName = doc.Name;
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(csv);
        insert doc;*/
        TestCommon.createBillSimpleHelpConfigDoc();
        // Create mail Service
        
     }
}