<?xml version="1.0" encoding="UTF-8"?>
<root>
	<!--
		書式：
		SHOPCODE: 	店舗コード、支店が非存在する場合、空白のままに定義する
		FIELDS：		店舗単位に、予定表に表示したい項目定義情報	
								書式：項目ＡＰＩ名:画面に表示ラベル
								属性：SHOWFOOD
									　予約情報行の最後に「料理」情報追記するがどうか TRUE:表示/ FALSE:非表示
		LINKFIELD：	画面表示の項目はリンク追加の定義情報：　
								書式：項目ＡＰＩ名(LINKされる対象ＡＰＩ):リンクのSalesforceID
								注意：LINKFIELDに定義した「項目ＡＰＩ名」は必ずFIELDSに定義ください
		AGGREGATE:	自動合計項目
								注意：AGGREGATEに定義した「項目ＡＰＩ名」は必ずFIELDSに定義ください
	    HIDDENFIELD:定義されている項目は画面初期表示する場合、該当項目は非表示する
	    						書式：項目ＡＰＩ名
	    						注意：HIDDENFIELDに定義した「項目ＡＰＩ名」は必ずFIELDSに定義ください
	    COLNUMSIZE: 項目の横幅サイズ定義する
	                            書式：項目ＡＰＩ名:サイズ（例：100px or 10%)
	    						注意：HIDDENFIELDに定義した「項目ＡＰＩ名」は必ずFIELDSに定義ください
	    COLNUMTYPE:項目のデータタイプ定義する(文字列以外のデータタイプ定義する、設定しない項目は自動:文字列
	    						書式：項目ＡＰＩ名:データタイプ
	    						データタイプのキー：　数値：number / 日付：date
	    				　　  注意：日付の場合、書式は自動 yyyy/mm/ddに変換する
	    				                  画面に、数値、日付の項目を表示したい場合、必ず明示的にデータタイプを定義してください。
	-->
	<SHOP><!-- デフォルト設定情報、削除しない、支店舗追加したい場合、このＮＯＤＥコピーして、後ろに追加してください -->
		<SHOPCODE></SHOPCODE>
		<FIELDS SHOWFOOD="true">
		 refTypeOfRooms__r.ShopInfoRef__r.Name:支店
		,Rroom__r.Seq__c:SEQ
		,Rroom__r.Rnumber__c:R#
		,Field353__c:確
		,Rroom__r.Name:部屋
		,refTypeOfRooms__r.Name:部屋タイプ名
		,Field291__c:当日
		,Field4__c:到着時刻
		,Field278__c:昼
		,Check369__c:Check
		,Morningtime__c:朝食時間
		,Field300__c:布団戸締
		,Field281__c:補足$
		,Field302__c:補足
		,StayPersons__c:予約人数
		,Mans__c:男性
		,Femails__c:女性
		,ChildFA__c:小人A
		,Childs__c:小人B
		,Name:予約名
		,ReservedType__c:予約タイプ
		,Field293__c:夕食時間
		,Field303__c:処
		,Field306__c:[料]要注意
		,Field354__c:料理補足
		,Field301__c:食事開始
		,Comment3__c:特記事項
		</FIELDS>
		<LINKFIELD>
		Name:Id
		</LINKFIELD>
		<AGGREGATE><!-- 合計項目定義する -->
		StayPersons__c
		</AGGREGATE>
		<HIDDENFIELD><!-- 初期非表示項目 -->
		refTypeOfRooms__r.ShopInfoRef__r.Name
		</HIDDENFIELD>
		<COLNUMSIZE><!-- 項目の横幅サイズを設定する（例：100px, 10%) -->
		 Rroom__r.Seq__c:46px
		,Field353__c:36px
		,Comment3__c:20%
		</COLNUMSIZE>
		<COLNUMTYPE>
		 Rroom__r.Seq__c:number
		,Rroom__r.Rnumber__c:number
		,StayPersons__c:number
		,Mans__c:number
		,Femails__c:number
		,ChildFA__c:number
		,Childs__c:number
		</COLNUMTYPE>
	</SHOP>

</root>