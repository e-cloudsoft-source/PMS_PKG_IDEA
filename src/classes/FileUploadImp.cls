/**
* マスタ設定情報のアップロード処理クラス
* Ver0.1 リアルAGTのCSV設定ファイルのアップロード
**/
public class FileUploadImp extends FileUploadBase {

    public static final Pattern datePattern = Pattern.compile('^(?:((1[6-9]|[2-9][0-9])[0-9]{2}).(?:(?:0[1-9]|1[0-2]).(?:0[1-9]|1[0-9]|2[0-8])|(?:0[13-9]|1[0-2]).(?:29|30)|(?:0[13578]|1[02]).31)|(?:[0-9]{2}(?:0[48]|[2468][048]|[13579][26])|(?:0[48]|[2468][048]|[13579][26])00).02.29)$');
    /**
    * クラスインスタンス化
    **/
    public FileUploadImp() { 
        super(); 
        result = new UploadResult();
    }

    /**
    * リアルＡＧＴのＣＳＶファイル処理を行う
    **/
    public List<String[]> processCsvFile () {
    	return processCsvFile(0);
    }
    
    public List<String[]> processCsvFile (Integer skipColIdx) {
        // 処理結果をクリアする
        result.clear();
        // パラメータ情報チェックを行う
        if (!preProcessUpload()) {
            // upload 情報クリックする
            super.clear();
            return null;
        }
        // CSV読み込みクラス初期化する
        CommCsvUtils.CsvReader reader = null;
        try {
            // 取込ファイル内容をParse処理
            reader = new CommCsvUtils.CsvReader(this.getFileBody().toString());
        } catch (StringException e) {
            String msg = e.getMessage();
            if (msg.contains('BLOB is not a valid UTF-8')) {
                result.addMessage(Label.ERR_0002);
            } else {
                result.addMessage(Label.ERR_9000 + '(' + e.getmessage() + ')');
            }
        } catch (Exception e) {
            result.addMessage(Label.ERR_9000 + '(' + e.getmessage() + ')');
        }
        // CSV分析エラーがありの場合
        if (result.isHasErrMsg) {
            super.clear();
            return null;
        }
        // Header処理をSKIPする
        reader.readLine();
System.debug(LoggingLevel.INFO,  'reader::' + reader);
		// TITLE以外のデータがない場合
		if (reader == null) {
        	// 成功結果は画面に戻って、設定を行う
        	//(0件)
        	result.addInfoMessage(Label.MSG_9001 + Label.MSG_9002);
        	return null;
		}
        // 全体情報を配列に入れる
        List<String[]> csvLines = new List<String[]>();
        // CSVへーダー以外の明細データを読む
        do {
            // 次の行目情報を取得する
            String[]csvLine = reader.readLine();
System.debug(LoggingLevel.INFO,  'csvLine::' + csvLine);
            // 全体処理終了場合
            if (csvLine == null) {
                break;
            }
            if (csvLine.size() <= skipColIdx) continue;
            // 第一列情報は未設定する場合、次の行に移動する
            if (CommUtils.isBlank(csvLine[skipColIdx])) continue;
            // 処理対象を設定する
            csvLines.add(csvLine);
        } while (reader.isHaveUnReacCsv());
        
        return csvLines;
    }
    
    // 処理結果クラス可能
    public UploadResult result{get; private set;}
    public class UploadResult {
        public UploadResult() {
            errorMessage = new List<String>();
            infoMessage = new List<String>();
        }
        public void addMessage(String err) {
            errorMessage.add(err);
        }
        /*
        public void addAllMessage(List<String> pMsgs) {
            errorMessage.addAll(pMsgs);
        }*/
        // 異常発生するがどうか判別フラグ
        public Boolean isHasErrMsg{get{return !errorMessage.isEmpty();}}
        // エラー配列情報を取得する
        private List<String> errorMessage;
        public List<String> getLstErorMessage() {
            return errorMessage;
        }
        // 画面に表示用エラー文字列を作成する
        public String getStrErrorMessage() {
            return getOutPutMessage(errorMessage);
        }
        private List<String> infoMessage;
        public void addInfoMessage(String msg) {
        	infoMessage.add(msg);
        }
        public String getInfoMessage() {
        	return getOutPutMessage(infoMessage);
        }
        public Boolean isHasInfoMsg{get{return !infoMessage.isEmpty();}}
        
        
        private String getOutPutMessage(List<String> msglst) {
            String msg = '';
            for (String s : msglst) {
                msg += s + '<br/>';
            }
            return msg;
        }
        
        // 情報クリアする
        public void clear() {
            errorMessage.clear();
            infoMessage.clear();
        }
    }

    // 必須チェックを行う
    public Boolean strIsEmpty(String valueStr, Integer lineNo, String labelstr) {
System.debug(LoggingLevel.INFO, 'strIsEmpty:::' + CommUtils.isBlank(valueStr));
        if (CommUtils.isBlank(valueStr)) {
            result.addMessage(String.valueOf(lineNo).leftPad(5) + Label.ERR_0100 + labelstr + Label.ERR_0103);
System.debug(LoggingLevel.INFO, 'result:::' + result);
            return true;
        }
        return false;
    }
    // 日付有効性チェック
    public Boolean isValidate(String valueStr, Integer lineNo, String labelstr) {
        if (CommUtils.isBlank(valueStr)) return true;
        // 存在する場合、日付有効性チェックを行う
        //if (!(datePattern.matcher(valueStr).matches())) {
        Date wkDate = CommUtils.stringToDate(valueStr);
        if (wkDate == null) {
            result.addMessage(String.valueOf(lineNo).leftPad(5) + Label.ERR_0100 + labelstr + Label.ERR_0104);
            return false;
        }
        return true;
    }
    // 数値有効性チェック
    public Boolean isNumber(String valueStr, Integer lineNo, String labelstr) {
        if (CommUtils.isBlank(valueStr)) return true;
        if (!valueStr.isNumeric()) {
            result.addMessage(String.valueOf(lineNo).leftPad(5) + Label.ERR_0100 + labelstr + Label.ERR_0104);
            return false;
        }
        return true;
    }

    /**
    * パラメータチェック
    * ファイル存在チェックを行う
    **/
    private boolean preProcessUpload() {
        // 処理前、クリックを行う
       //this.errorMessage = null;
        if (this.getFileBody() == null) {
            result.addMessage(Label.ERR_0001);
            return false;
        }
        return true;
    }
}