public without sharing class AccountingSyncBatchHelp {

	private string gShopCode;
	// 銀行振り込みCSV出力機能
	public static final String COOP_STATUS_PURCHASE_BANKIMP='仕入_買掛決済';
	// エンジン販売手数料、カード会社カード利用手数料集計機能
	public static final String COOP_STATUS_PURCHASE_CHARGE ='仕入_買掛';
	// 手数料カテゴリ１定義キーワード
	public static final String TESURYO_DIV_CARD = 'カード';
	public static final String TESURYO_DIV_AGT = 'AGT';
	
	public AccountingSyncBatchHelp(String shopCode) {
		gShopCode = shopCode;
		//
		readConfigXml();
	}
	public AccountingSyncBatchHelp(String shopCode, Boolean onlyAgtSalesRateConfigFlg) {
		gShopCode = shopCode;
		//
		// 該当店舗の設定情報を読み込みする「同店舗コードがなければ、１番目の店舗の設定情報を参照する」
		// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('AccountingSyncBatchConfig', gShopCode);
		// エージェント販売手数料
		Dom.XmlNode agtSalesRateNode =  targetNode.getChildElement('AGT_SALESRATE', null);
		if (agtSalesRateNode != null) {
			agtSalesRateConf = new AgtSalesRateConfig(agtSalesRateNode);
		}
	}
	private void readConfigXml() {
		
		// 該当店舗の設定情報を読み込みする「同店舗コードがなければ、１番目の店舗の設定情報を参照する」
		// 処理ターゲットのNODEを取得する
		Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('AccountingSyncBatchConfig', gShopCode);
		// 端末処理区分
		/*
		Dom.XmlNode roundTypeNode =  targetNode.getChildElement('ROUND_TYPE', null);
		if (roundTypeNode != null) {
			string roundTypeStr = CommUtils.nullToBlank(roundTypeNode.getText());
			roundMode = (roundTypeStr == '0' ? RoundingMode.FLOOR : (roundTypeStr == '2' ? RoundingMode.CEILING : RoundingMode.HALF_UP));
		} else roundMode = RoundingMode.HALF_UP;*/
		// 処理結果の通知先の情報設定
		sendMailAddr = new list<String>();
		Dom.XmlNode resultMailNode =  targetNode.getChildElement('RESULT_MAIL', null);
		if (resultMailNode != null) {
			String resultMailStr = CommUtils.nullToBlank(resultMailNode.getText());
			if (!CommUtils.isBlank(resultMailStr)) sendMailAddr.addAll(resultMailStr.split(','));
		}
		queryPlusFilter = '';
		Dom.XmlNode filterNode =  targetNode.getChildElement('FILTER', null);
		if (filterNode != null) {
			queryPlusFilter = CommUtils.nullToBlank(filterNode.getText());
		}
		filterBtnLst = new List<FilterBtn>();
		Dom.Xmlnode filterBtnNodes = targetNode.getChildElement('FILTERBUTTON', null);
		if (filterBtnNodes != null){
			for(Dom.XmlNode btnNode : filterBtnNodes.getChildElements()){
				FilterBtn btn = new FilterBtn(btnNode);
				filterBtnLst.add(btn);
			}
			
		}
		reqBatchWaitTimes = 60;
		Dom.XmlNode reqBathWaitTimeNode =  targetNode.getChildElement('REQBAT_WAIT_TIME', null);
		if (reqBathWaitTimeNode != null) {
			reqBatchWaitTimes = CommUtils.nullToIntZero(CommUtils.nullToBlank(reqBathWaitTimeNode.getText()));
		}	
		// 振り込み手数料
		Dom.XmlNode bankTransRateNode =  targetNode.getChildElement('BANK_TRANS_RATE', null);
		if (bankTransRateNode != null) {
			brankTransRateInf = new BankTransRate(bankTransRateNode);
		}
		// 各機能に定義されている口座情報
		Dom.XmlNode kouzaInfoNode =  targetNode.getChildElement('BANK_KOZAINFO', null);
		if (kouzaInfoNode != null) {
			// 買掛決済バッチ処理用口座
			Dom.XmlNode purSettlementNode =  kouzaInfoNode.getChildElement('PUR_SETTLEMENT', null);
			if (purSettlementNode != null) {
				purSettlementKouzaInfo = new FunctionBankNoInfo(purSettlementNode);
			}
			// 買掛の取引先に入金口座識別の「口座種別」定義情報
			Dom.XmlNode purReciveAccountNode =  kouzaInfoNode.getChildElement('PUR_RECIVEACCOUNT', null);
			if (purReciveAccountNode != null) {
				purReciveKouzaInfo = new FunctionBankNoInfo(purReciveAccountNode);
			}
		}
		// 銀行へ通信電文関連定義情報
		Dom.XmlNode bankTeleGramHeaderNode =  targetNode.getChildElement('BANK_TELEGRAM_HEADER', null);
		if (bankTeleGramHeaderNode != null) {
//System.debug(loggingLevel.INFO ,'bankTeleGramHeaderNode::'  +bankTeleGramHeaderNode);
			bankTeleGramHeaderInf = new BankTeleGramHeader(bankTeleGramHeaderNode);
		}
		Dom.XmlNode bankTeleGramDataNode =  targetNode.getChildElement('BANK_TELEGRAM_DETAIL', null);
		if (bankTeleGramDataNode != null) {
			bankTeleGramDataInf = new BankTeleGramData(bankTeleGramDataNode);
		}
		Dom.XmlNode bankTeleGramTrailerNode =  targetNode.getChildElement('BANK_TELEGRAM_TRAILER', null);
		if (bankTeleGramTrailerNode != null) {
			bankTeleGramTrailerInf = new BankTeleGramTrailer(bankTeleGramTrailerNode);
		}
		Dom.XmlNode bankTeleGramEndNode =  targetNode.getChildElement('BANK_TELEGRAM_END', null);
		if (bankTeleGramEndNode != null) {
			bankTeleGramEndInf = new BankTeleGramEnd(bankTeleGramEndNode);
		}
		
		// エージェント販売手数料
		Dom.XmlNode agtSalesRateNode =  targetNode.getChildElement('AGT_SALESRATE', null);
		if (agtSalesRateNode != null) {
			agtSalesRateConf = new AgtSalesRateConfig(agtSalesRateNode);
		}
		// カード販売手数料計算関連
		Dom.XmlNode cardSalesRateNode =  targetNode.getChildElement('CARD_SALESRATE', null);
		if (cardSalesRateNode != null) {
			cardSalesRateConf = new CardSalesRateConfig(cardSalesRateNode);
		}
		
		purchaseRepBtns = new list<ButtonItem>();
		// 仕入入力画面に表示用ボタン定義情報の取得
		Dom.XmlNode purchaseBtnsNode =  targetNode.getChildElement('BUTTONS', null);
		if (purchaseBtnsNode != null) {
			Dom.XmlNode[] buttonNodes = purchaseBtnsNode.getChildElements();
			for (Dom.XmlNode buttonNode : buttonNodes) {
				ButtonItem item = new ButtonItem(buttonNode);
				purchaseRepBtns.add(item);
			}
		}
		// 種別 to 科目
		Dom.XmlNode purTypeToDefkamokusNode =  targetNode.getChildElement('PUR_TYPE_TO_DEFKAMOKUS', null);
		if (purTypeToDefkamokusNode != null) {
			convertXmlTypeToKamokuLst(purTypeToDefkamokusNode);
		}
		
	}
	
	//public System.RoundingMode roundMode{get; private set;}
	public List<String> sendMailAddr{get; private set;}
	public String queryPlusFilter{get; private set;}
	public Integer reqBatchWaitTimes{get; private set;}	// 秒数単位[リクエストバッチキャンセル待ち秒数、０の場合、待ちなし、スケジュールは１０秒後起動を行う]
	public BankTransRate brankTransRateInf{get; private set;}
	public BankTeleGramHeader bankTeleGramHeaderInf{get; private set;}
	public BankTeleGramData bankTeleGramDataInf{get; private set;}
	public BankTeleGramTrailer bankTeleGramTrailerInf{get; private set;}
	public BankTeleGramEnd bankTeleGramEndInf{get; private set;}
	
	// 振り込み手数料
	public class BankTransRate {
		public BankTransRate(Dom.XmlNode node) {
			sameBankAndBranch = new List<BankTranRateItem>();
			sameBankAndDiffBranch = new List<BankTranRateItem>();
			diffBank = new List<BankTranRateItem>();
			// 同じ銀行
			Dom.XmlNode sameBankNode =  node.getChildElement('SAME_BANK', null);
			if (sameBankNode != null) {
				Dom.XmlNode sameBranchNode =  sameBankNode.getChildElement('SAME_BRANCH', null);
				Dom.XmlNode diffBranchNode =  sameBankNode.getChildElement('DIFF_BRANCH', null);
				if (sameBranchNode != null) {
					//BankTranRateItem item = new BankTranRateItem(sameBranchNode);
					Dom.XmlNode[] rateRankNodes = sameBranchNode.getChildElements();
					for (Dom.XmlNode rateRankNode : rateRankNodes) {
						BankTranRateItem item = new BankTranRateItem(rateRankNode);
						sameBankAndBranch.add(item);
					}
					
				}
				if (diffBranchNode != null) {
					Dom.XmlNode[] rateRankNodes = diffBranchNode.getChildElements();
					for (Dom.XmlNode rateRankNode : rateRankNodes) {
						BankTranRateItem item = new BankTranRateItem(rateRankNode);
						sameBankAndDiffBranch.add(item);
					}
				}
			}
			Dom.XmlNode diffBankNode =  node.getChildElement('DIFF_BANK', null);
			if (diffBankNode != null) {
				Dom.XmlNode[] rateRankNodes = diffBankNode.getChildElements();
				for (Dom.XmlNode rateRankNode : rateRankNodes) {
					BankTranRateItem item = new BankTranRateItem(rateRankNode);
					diffBank.add(item);
				}
			}
		}
		public List<BankTranRateItem> sameBankAndBranch{get; private set;}
		public List<BankTranRateItem> sameBankAndDiffBranch{get; private set;}
		public List<BankTranRateItem> diffBank{get; private set;}
	}
	public class BankTranRateItem{
		public BankTranRateItem(Dom.XmlNode node) {
			minAmount = transRate = 0;
			maxAmount = null;
			Dom.XmlNode minValNode =  node.getChildElement('<MIN_VAL>', null);
			Dom.XmlNode maxValNode =  node.getChildElement('MAX_VAL', null);
			Dom.XmlNode rateNode =  node.getChildElement('RATE', null);
			if (minValNode != null) minAmount = CommUtils.nullToZero(CommUtils.nullToBlank(minValNode.getText()));
			if (maxValNode != null) maxAmount = CommUtils.nullToZero(CommUtils.nullToBlank(maxValNode.getText()));
			if (rateNode != null) transRate = CommUtils.nullToZero(CommUtils.nullToBlank(rateNode.getText()));
		}
		public Decimal minAmount{get;set;}
		public Decimal maxAmount{get;set;}
		public Decimal transRate{get;set;}
	}
	// 仕入→買掛決済バッチ利用の口座情報
	public FunctionBankNoInfo purSettlementKouzaInfo{get;private set;}
	// 仕入→買掛決済バッチ→取引先に振込用の口座情報
	public FunctionBankNoInfo purReciveKouzaInfo{get;private set;}
	// 機能別の口座情報を格納する
	public class FunctionBankNoInfo {
		public FunctionBankNoInfo(Dom.XmlNode node) {
			transType = '';
			descript = '';
			kozaName = '';
			kozaType = '';
			if (node != null) {
				Dom.XmlNode tranTypeNode =  node.getChildElement('TRANS_TYPE', null);
				Dom.XmlNode kouzaSeqNode =  node.getChildElement('KOUZA_SEQ', null);
				Dom.XmlNode kouzaDescriptNode =  node.getChildElement('DESCRIPT', null);
				Dom.XmlNode kozaTypeNode =  node.getChildElement('KOUZA_TYPE', null);
	
				if (tranTypeNode != null) transType = CommUtils.nullToBlank(tranTypeNode.getText());
				if (kouzaSeqNode != null) kozaName = CommUtils.nullToBlank(kouzaSeqNode.getText());	
				if (kouzaDescriptNode != null) descript = CommUtils.nullToBlank(kouzaDescriptNode.getText());	
				if (kozaTypeNode != null) kozaType = CommUtils.nullToBlank(kozaTypeNode.getText());	
			}
		}
		public String transType{get; private set;}	// 業務種別
		public String descript{get; private set;}	// 説明
		public String kozaName{get; private set;}	// 口座SEQ
		public String kozaType{get; private set;}	// 口座種別
	}

	public class BankTeleGramHeader {
		public BankTeleGramHeader(Dom.XmlNode node) {
			dataKbn = '1';
			filedLayout = '';
			messageHeader = '';
			// XMLから設定情報を取得する
			Dom.XmlNode dataKbnNode =  node.getChildElement('DATA_KBN', null);
			Dom.XmlNode fieldLayoutNode =  node.getChildElement('MESSAGE_LAYOUT', null);
			Dom.XmlNode headerNode =  node.getChildElement('MESSAGE_HEADER', null);
			
			if (dataKbnNode != null) dataKbn = CommUtils.nullToBlank(dataKbnNode.getText());
			if (fieldLayoutNode != null) filedLayout = CommUtils.nullToBlank(fieldLayoutNode.getText()).deleteWhitespace();
			if (headerNode != null) messageHeader = CommUtils.nullToBlank(headerNode.getText());
		}
		public String dataKbn{get; private set;}
		public String filedLayout{get; private set;}
		public list<integer> fieldLenLst{get;private set;}
		public String messageHeader{get; private set;}
	}
	public class BankTeleGramData {
		public BankTeleGramData(Dom.XmlNode node) {
			dataKbn = '2';
			isEdi = false;
			//isPlusFormat = false;
			furikomiKbn = '7';
			filedLayout = '';
			//fieldLenLst = new list<integer>();
			messageHeader = '';
			
			// XMLから設定情報を取得する
			Dom.XmlNode dataKbnNode =  node.getChildElement('DATA_KBN', null);
			Dom.XmlNode isEdiNode =  node.getChildElement('IS_EDI', null);
			Dom.XmlNode furikomiKbnNode =  node.getChildElement('FURIKOMIKBN', null);
			Dom.XmlNode fieldLayoutNode =  node.getChildElement('MESSAGE_LAYOUT', null);
			Dom.XmlNode headerNode =  node.getChildElement('MESSAGE_HEADER', null);
			// 
			if (dataKbnNode != null) dataKbn = CommUtils.nullToBlank(dataKbnNode.getText());
			if (isEdiNode != null) isEdi = Boolean.valueOf(CommUtils.nullToBlank(isEdiNode.getText()));
			if (furikomiKbnNode != null) furikomiKbn = CommUtils.nullToBlank(furikomiKbnNode.getText());
			if (fieldLayoutNode != null) filedLayout = CommUtils.nullToBlank(fieldLayoutNode.getText()).deleteWhitespace();
			if (headerNode != null) messageHeader = CommUtils.nullToBlank(headerNode.getText());
		}
		
		public String dataKbn{get; private set;}
		public Boolean isEdi{get; private set;}
		public String furikomiKbn{get; private set;}	// 振込指定区分
		//public Boolean isPlusFormat{get; private set;}
		public string filedLayout{get; private set;}
		//public list<integer> fieldLenLst{get;private set;}
		public String messageHeader{get; private set;}
	}
	public class BankTeleGramTrailer {
		public BankTeleGramTrailer(Dom.XmlNode node) {
			dataKbn = '8';
			filedLayout = '';
			//fieldLenLst = new list<integer>();
			messageHeader = '';
			
			// XMLから設定情報を取得する
			Dom.XmlNode dataKbnNode =  node.getChildElement('DATA_KBN', null);
			Dom.XmlNode fieldLayoutNode =  node.getChildElement('MESSAGE_LAYOUT', null);
			//Dom.XmlNode fieldSizeNode =  node.getChildElement('LAYOUT_FIELD_LEN', null);
			Dom.XmlNode headerNode =  node.getChildElement('MESSAGE_HEADER', null);
			// 
			if (dataKbnNode != null) dataKbn = CommUtils.nullToBlank(dataKbnNode.getText());
			if (fieldLayoutNode != null) filedLayout = CommUtils.nullToBlank(fieldLayoutNode.getText()).deleteWhitespace();
			if (headerNode != null) messageHeader = CommUtils.nullToBlank(headerNode.getText());
			/*
			if (fieldSizeNode != null) {
				String fieldSizeStr = CommUtils.nullToBlank(fieldSizeNode.getText());
				if (!CommUtils.isBlank(fieldSizeStr)) {
					String[] fieldSizeStrLst = fieldSizeStr.split(',');
					for(String s : fieldSizeStrLst) fieldLenLst.add(CommUtils.nullToIntZero(s));
				}
			}*/
		}
		public String dataKbn{get; private set;}
		public string filedLayout{get; private set;}
		//public list<integer> fieldLenLst{get;private set;}
		public String messageHeader{get; private set;}
	}
	public class BankTeleGramEnd {
		public BankTeleGramEnd(Dom.XmlNode node) {
			dataKbn = '9';
			filedLayout = '';
			//fieldLenLst = new list<integer>();
			messageHeader = '';
			
			// XMLから設定情報を取得する
			Dom.XmlNode dataKbnNode =  node.getChildElement('DATA_KBN', null);
			Dom.XmlNode fieldLayoutNode =  node.getChildElement('MESSAGE_LAYOUT', null);
			//Dom.XmlNode fieldSizeNode =  node.getChildElement('LAYOUT_FIELD_LEN', null);
			Dom.XmlNode headerNode =  node.getChildElement('MESSAGE_HEADER', null);
			// 
			if (dataKbnNode != null) dataKbn = CommUtils.nullToBlank(dataKbnNode.getText());
			if (fieldLayoutNode != null) filedLayout = CommUtils.nullToBlank(fieldLayoutNode.getText()).deleteWhitespace();
			if (headerNode != null) messageHeader = CommUtils.nullToBlank(headerNode.getText());
			/*
			if (fieldSizeNode != null) {
				String fieldSizeStr = CommUtils.nullToBlank(fieldSizeNode.getText());
				if (!CommUtils.isBlank(fieldSizeStr)) {
					String[] fieldSizeStrLst = fieldSizeStr.split(',');
					for(String s : fieldSizeStrLst) fieldLenLst.add(CommUtils.nullToIntZero(s));
				}
			}*/
		}
		public String dataKbn{get; private set;}
		public string filedLayout{get; private set;}
		//public list<integer> fieldLenLst{get;private set;}
		public String messageHeader{get; private set;}
	}
	
	
	public AgtSalesRateConfig agtSalesRateConf{get; private set;}
	public CardSalesRateConfig cardSalesRateConf{get; private set;}
	public List<FilterBtn> filterBtnLst;
	// エージェント販売手数料計算用設定情報格納
	public class AgtSalesRateConfig {
		public AgtSalesRateConfig(Dom.XmlNode node) {
			Dom.XmlNode iTypeNameNode =  node.getChildElement('I_TYPENAME', null);
			Dom.XmlNode oKamokuNode =  node.getChildElement('O_KAMOKU', null);
			if (iTypeNameNode != null ) InTypeName = CommUtils.nullToBlank(iTypeNameNode.getText());
			if (oKamokuNode != null ) OuKamoku = CommUtils.nullToBlank(oKamokuNode.getText());
			Dom.XmlNode dataFilterNode =  node.getChildElement('DATA_FILTER', null);
			if (dataFilterNode != null) dataFilterStr = CommUtils.nullToBlank(dataFilterNode.getText());
			// 販売手数料複数判断ロジック機能対応 BEGIN
			chargeLogicMap = new Map<String,ChargeLogic>();
			Dom.XmlNode chargeLogicNode = node.getChildElement('CHARGERATE_LOGIC', null);
			if (chargeLogicNode != null) {
				for(Dom.XmlNode filterNode : chargeLogicNode.getChildElements()){
					ChargeLogic logic = new ChargeLogic(filterNode);
					chargeLogicMap.put(logic.tesuryoNo,logic);
				}
			}
			// 販売手数料複数判断ロジック機能対応 END
			// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
			holidayIncSat = false;
			Dom.XmlNode holidayIncSatNode = node.getChildElement('HOLIDAY_INC_SAT', null);
			if (holidayIncSatNode != null) holidayIncSat = Boolean.valueOf(CommUtils.nullToBlank(holidayIncSatNode.getText()));
			// 2016/03/21 休日前関連チェックロジックの対応 END
			// 2016/07/08 手数料集計単位により、日単位の場合、そのまま仕入オブジェクトに格納 BEGIN
			cancelProductCdSet = new set<string>();
			targetOutKeywordSet = new set<string>();
			prePaymentInfoMap = new map<string,decimal>();
			relPrePaymentInfoMap = new map<string, string>();
			Dom.XmlNode cancelProductCdNode = node.getChildElement('CANCEL_CODE', null);
			if (cancelProductCdNode != null) {
				list<string> cancelProductCdLst = CommUtils.nullToBlank(cancelProductCdNode.getText()).split(',');
				if (!cancelProductCdLst.isEmpty()) cancelProductCode = cancelProductCdLst[0];
				cancelProductCdSet.addAll(cancelProductCdLst);
			}
			Dom.XmlNode targetOutKeywordNode = node.getChildElement('SALES_TARGETOUT', null);
			if (targetOutKeywordNode != null) targetOutKeywordSet.addAll(CommUtils.nullToBlank(targetOutKeywordNode.getText()).split(','));
			Dom.XmlNode prePaymentInfoNode = node.getChildElement('PRE_PAYMENT_INFOS', null);
			if (prePaymentInfoNode != null) {
				for(Dom.XmlNode prePaymentNode : prePaymentInfoNode.getChildElements()){
					// 事前決済手数料レート
					Decimal rate = CommUtils.nullToZero(prePaymentNode.getAttribute('RATE',null));
					// 事前決済商品コード
					String prePaymentCode = CommUtils.nullToBlank(prePaymentNode.getAttribute('PRE_PAYMENT_CODE',null));
					// 事前決済商品が存在の場合、同じ会計に該当会計商品が存在すると、該当商品も事前決済対象
					String relPaymentCodes = CommUtils.nullToBlank(prePaymentNode.getAttribute('REL_PAYMENT_CODE',null));
					// 決済レートが非存在の場合、定義処理対象外になる
					if (rate == 0 || CommUtils.isBlank(prePaymentCode)) continue;
					if (!CommUtils.isBlank(relPaymentCodes)) {
						list<string> relPayCodes = relPaymentCodes.split(',');
						for (string relPayCode : relPayCodes) {
							relPrePaymentInfoMap.put(relPayCode, prePaymentCode);
						}
					}
					prePaymentInfoMap.put(prePaymentCode, rate);
				}
			}
			noTaxTargetFlg = false;
			String noTaxTargetFlgStr = CommUtils.nullToBlank(node.getAttribute('NOTAXFLG',null));
			if (!CommUtils.isBlank(noTaxTargetFlgStr)) noTaxTargetFlg = Boolean.valueOf(noTaxTargetFlgStr);
			// 2016/07/08 手数料集計単位により、日単位の場合、そのまま仕入オブジェクトに格納 END
		}
		public string dataFilterStr{get; private set;}
		public string InTypeName{get;set;}
		public string OuKamoku{get;set;}
		// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
		// 土曜日は休日として定義するがどうか制御フラグ：TRUE：土曜日も休日として、定義する, FALSE: 土曜日は平日として定義する
		public Boolean holidayIncSat {get;set;}
		// 2016/03/21 休日前関連チェックロジックの対応 END
		// 販売手数料複数判断ロジック機能対応 BEGIN
		public Map<String,ChargeLogic> chargeLogicMap{get;set;}
		// 販売手数料複数判断ロジック機能対応 END
		public set<String> cancelProductCdSet{get;private set;}
		public String cancelProductCode{get; private set;}
		public set<String> targetOutKeywordSet{get;private set;}
		//public map<string, set<string>> agtPrePaymentChkMap{get; private set;}
		//public set<string> prePaymentChkSet{get; private set;}
		public map<string,decimal> prePaymentInfoMap{get; private set;}
		//public map<string,set<string>> relPrePaymentInfoMap{get; private set;}
		public map<string,string> relPrePaymentInfoMap{get; private set;}
		// 税対象外がどうか制御
		public Boolean noTaxTargetFlg{get; private set;}
	}
	// 販売手数料複数判断ロジック機能対応 BEGIN
	public class ChargeLogic{
		public String logicStr{get;set;}
		//public String filterVal{get;set;}
		public String tesuryoNo{get;set;}
		// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
		// 該当手数料抽出ロジックに対して、休前日関連チェック定義あり、なし制御を行う
		// NULL:定義なし、TRUE：該当手数料は休前日の手数料定義、FALSE:該当手数料は休前日以外の手数料定義
		public Boolean befHolidayCheck{get;set;}
		// 2016/03/21 休日前関連チェックロジックの対応 END
		public ChargeLogic(Dom.XmlNode filterNode){
			// 販売手数料タグ
			tesuryoNo = filterNode.getAttribute('TESURYONO',null);
			// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
			// 2016/03/21 休日前するがどうかチェック区分を取得する[NULL:制御なし、TRUE:休日前は条件入れる、FALSE：休日前以外は条件入れる]
			String locBefHolidayCheck = filterNode.getAttribute('BEF_HOLIDAY',null);
			if (CommUtils.isBlank(locBefHolidayCheck)) befHolidayCheck = null;
			else befHolidayCheck = Boolean.valueOf(locBefHolidayCheck);
			// 2016/03/21 休日前関連チェックロジックの対応 END
			// 該当LOGIC関連の判断条件
			List<String> coonditionLst = new List<String>();
			for(Dom.XmlNode node : filterNode.getChildElements()){
				String nodeName = node.getName();
				if (nodeName == 'LOGIC') {
					logicStr = CommUtils.nullToBlank(node.getText());
				} else if(nodeName == 'COONDITION'){
					String coondition = CommUtils.nullToBlank(node.getText());
					coonditionLst.add(coondition);
				}
			}
			for(integer i = 0 ; i < coonditionLst.size() ; i++){
				logicStr = logicStr.replace('{' + i + '}',coonditionLst[i]);
			}
		}
	}
	// 販売手数料複数判断ロジック機能対応 END
	public class CardSalesRateConfig {
		public CardSalesRateConfig(Dom.XmlNode node) {
			Dom.XmlNode iTypeNameNode =  node.getChildElement('I_TYPENAME', null);
			Dom.XmlNode oKamokuNode =  node.getChildElement('O_KAMOKU', null);
			if (iTypeNameNode != null ) InTypeName = CommUtils.nullToBlank(iTypeNameNode.getText());
			if (oKamokuNode != null ) OuKamoku = CommUtils.nullToBlank(oKamokuNode.getText());
			noTaxTargetFlg = true;
			String noTaxTargetFlgStr = CommUtils.nullToBlank(node.getAttribute('NOTAXFLG',null));
			if (!CommUtils.isBlank(noTaxTargetFlgStr)) noTaxTargetFlg = Boolean.valueOf(noTaxTargetFlgStr);
		}
		public string InTypeName{get;set;}
		public string OuKamoku{get;set;}
		// 税対象外がどうか制御
		public Boolean noTaxTargetFlg{get; private set;}
	}
	// 仕入画面表示用ボタン情報
	public list<ButtonItem> purchaseRepBtns{get; private set;}	
	public  class ButtonItem {
		public ButtonItem(Dom.XmlNode node) {
			Dom.XmlNode btnLabelNode =  node.getChildElement('LABEL', null);
			Dom.XmlNode btnRepNode =  node.getChildElement('REP_NAME', null);
			if (btnLabelNode != null ) buttonLabel = CommUtils.nullToBlank(btnLabelNode.getText());
			if (btnRepNode != null ) buttonLinkRepNm = CommUtils.nullToBlank(btnRepNode.getText());
		}
		public string buttonLabel{get; private set;}
		public string buttonLinkRepNm{get; private set;}
	}
	
	// 販売手数料複数判断ロジック機能対応 BEGIN
	// 請求先（エンジントID[取引先ID,親取引先ID]/手数料リスト>
	// catDivSet:手数料カテゴリ１定義区分
	public static map<id, List<ChargeInfo__c>> getChargeInfosByAccount(set<id> accountIds, set<string> catDivSet) {
		
		Map<Id,List<ChargeInfo__c>> chargeLstMap = new map<Id,List<ChargeInfo__c>>();
		for (ChargeInfo__c chargeInfo : [select id,Name,PayChargeFlg__c,SalesRate__c,AccountRef__c,AccountRef__r.RoundType__c 
											,AccountRef__r.ChargeCalKbnLst__c,AccountRef__r.ChargeCalDateLst__c
											//,AccountRef__c
											//,AccountRef__r.RoundType__c
											,AccountRef__r.Name
											//,AccountRef__r.ParentId
											//,AccountRef__r.Parent.RoundType__c
											//,AccountRef__r.Parent.Name
											//2017/06/08 AGTごと、ご予約キャンセル料の販売手数料を計算する・しないを切替できるように改善対応 BEGIN
											,AccountRef__r.CancelChargeCalFlg__c
											//2017/06/08 AGTごと、ご予約キャンセル料の販売手数料を計算する・しないを切替できるように改善対応 END
											from ChargeInfo__c where AccountRef__c in :accountIds
											And CategoryMain__c in :catDivSet 
											order by Name]) {
			if(!chargeLstMap.containsKey(chargeInfo.AccountRef__c)){
				chargeLstMap.put(chargeInfo.AccountRef__c, new List<ChargeInfo__c>());
			} 
			chargeLstMap.get(chargeInfo.AccountRef__c).add(chargeInfo);
		}
		return chargeLstMap;
	}
	// 販売手数料複数判断ロジック機能対応 END
	
	// 2016/03/21 休日前関連チェックロジックの対応 BEGIN
	// 指定の日付は休前日するがどうかチェック
	// RETURN: TRUE: 休前日, FALSE:休前日以外
	public static Boolean isBefHoliday(AgtSalesRateConfig agtSalesRateConf, Date targetDt, Set<Date> holidaySet) {
		// 土曜日は休日として、定義される場合、金曜日も休前日として、判定する
		Date nextDay = targetDt.addDays(1);
		Integer dayNumOfWeek = CommUtils.getDayNumOfWeek(nextDay);
		if (agtSalesRateConf.holidayIncSat && dayNumOfWeek == 6) return true;	// 当前の日付は金曜日（土曜日の前日　かつ　土曜日は休日として、定義されているため、金曜日は休前日になる）
		if (dayNumOfWeek == 7) return true;	// 当前の日付は土曜日（日曜日の前日になるため、休前日になる）
		if (holidaySet.contains(nextDay)) return true;
		return false;
	}
	// 2016/03/21 休日前関連チェックロジックの対応 END
	// 取引先関連の手数料定義情報を取得する
	public static map<id,ChargeInfo__c> getChargeInfoByAccount(list<id> accountIds, set<string> catDivSet) {
		map<id, ChargeInfo__c> chargeInfoMap = new map<id, ChargeInfo__c>();
		for (ChargeInfo__c chargeInfo : [select id,AccountRef__c,PayChargeFlg__c,SalesRate__c from ChargeInfo__c where AccountRef__c in :accountIds and CategoryMain__c in :catDivSet order by seq__c]) {
			if (!chargeInfoMap.containsKey(chargeInfo.AccountRef__c)) {
				chargeInfoMap.put(chargeInfo.AccountRef__c, chargeInfo);
			}
		}
		// 手数料定義情報を戻る【定義ないと、処理対象外、】
		return chargeInfoMap;
	} 
	private void convertXmlTypeToKamokuLst(Dom.XmlNode purTypeToDefkamokuNode){
		//List<TypeToDefkamokuInf> typeToDefkamokuLst = new List<TypeToDefkamokuInf>();
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartArray();
		for(Dom.XmlNode childNode : purTypeToDefkamokuNode.getChildElements()){
			if(childNode.getName() == 'PUR_TYPE_TO_DEFKAMOKU'){
				String typeName = CommUtils.nullToBlank(childNode.getChildElement('PUR_TYPE_NAME', null).getText());
				String kamokuName = CommUtils.nullToBlank(childNode.getChildElement('PUR_KAMOKU_NAME', null).getText());
				if(!CommUtils.isBlank(typeName)){
					//typeToDefkamokuLst.add(new TypeToDefkamokuInf(typeName,kamokuName));
					gen.writeObject(new TypeToDefkamokuInf(typeName,kamokuName));
				}
				
			}
		}
		gen.writeEndArray();
		typeTokamokuJson = gen.getAsString();
	}
	public String typeTokamokuJson;
	public class TypeToDefkamokuInf{
		public String typeName;
		public String kamokuName;
		public TypeToDefkamokuInf(String name,String value){
			typeName = name;
			kamokuName = value;
		}
		
	}
	public class FilterBtn{
		public String btnLabel{get;set;}
		public String filter;
		public String cookieName;
		public FilterBtn(){
			btnLabel  = '' ;
			filter = '';
			cookieName = '';
		}  
		public FilterBtn(Dom.xmlNode btnNode){
			Dom.xmlNode labelNode = btnNode.getChildElement('LABEL', null);
			if(labelNode != null){
				btnLabel = labelNode.getText();
			}
			Dom.xmlNode filterNode = btnNode.getChildElement('FILTER', null);
			if(filterNode != null){
				filter = filterNode.getText();
			}
			Dom.xmlNode cookieNode = btnNode.getChildElement('COOKIE', null);
			if(cookieNode != null){
				cookieName  = cookieNode.getText();
			}
		}
		
	}
}