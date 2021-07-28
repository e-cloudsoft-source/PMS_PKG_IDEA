public with sharing class CommStringUtils {
	
	private static final CommStringUtils instance = new CommStringUtils();
	
    public CommStringUtils() {
		replaceHankakuKanaMap = new Map<String, String>();
		replaceHankakuEisujiMap = new Map<String, String>();
		putMapInfo();
    }
    
    private void putMapInfo() {
      	// 半角カナ置換 Map 作成
    	replaceHankakuKanaMap.put('ァ', 'ｧ');
        replaceHankakuKanaMap.put('ィ', 'ｨ');
        replaceHankakuKanaMap.put('ゥ', 'ｩ');
        replaceHankakuKanaMap.put('ェ', 'ｪ');
        replaceHankakuKanaMap.put('ォ', 'ｫ');
        replaceHankakuKanaMap.put('ャ', 'ｬ');
        replaceHankakuKanaMap.put('ュ', 'ｭ');
        replaceHankakuKanaMap.put('ョ', 'ｮ');
        replaceHankakuKanaMap.put('ッ', 'ｯ');
        replaceHankakuKanaMap.put('ー', 'ｰ');
        replaceHankakuKanaMap.put('ア', 'ｱ');
        replaceHankakuKanaMap.put('イ', 'ｲ');
        replaceHankakuKanaMap.put('ウ', 'ｳ');
        replaceHankakuKanaMap.put('エ', 'ｴ');
        replaceHankakuKanaMap.put('オ', 'ｵ');
        replaceHankakuKanaMap.put('カ', 'ｶ');
        replaceHankakuKanaMap.put('キ', 'ｷ');
        replaceHankakuKanaMap.put('ク', 'ｸ');
        replaceHankakuKanaMap.put('ケ', 'ｹ');
        replaceHankakuKanaMap.put('コ', 'ｺ');
        replaceHankakuKanaMap.put('サ', 'ｻ');
        replaceHankakuKanaMap.put('シ', 'ｼ');
        replaceHankakuKanaMap.put('ス', 'ｽ');
        replaceHankakuKanaMap.put('セ', 'ｾ');
        replaceHankakuKanaMap.put('ソ', 'ｿ');
        replaceHankakuKanaMap.put('タ', 'ﾀ');
        replaceHankakuKanaMap.put('チ', 'ﾁ');
        replaceHankakuKanaMap.put('ツ', 'ﾂ');
        replaceHankakuKanaMap.put('テ', 'ﾃ');
        replaceHankakuKanaMap.put('ト', 'ﾄ');
        replaceHankakuKanaMap.put('ナ', 'ﾅ');
        replaceHankakuKanaMap.put('ニ', 'ﾆ');
        replaceHankakuKanaMap.put('ヌ', 'ﾇ');
        replaceHankakuKanaMap.put('ネ', 'ﾈ');
        replaceHankakuKanaMap.put('ノ', 'ﾉ');
        replaceHankakuKanaMap.put('ハ', 'ﾊ');
        replaceHankakuKanaMap.put('ヒ', 'ﾋ');
        replaceHankakuKanaMap.put('フ', 'ﾌ');
        replaceHankakuKanaMap.put('ヘ', 'ﾍ');
        replaceHankakuKanaMap.put('ホ', 'ﾎ');
        replaceHankakuKanaMap.put('マ', 'ﾏ');
        replaceHankakuKanaMap.put('ミ', 'ﾐ');
        replaceHankakuKanaMap.put('ム', 'ﾑ');
        replaceHankakuKanaMap.put('メ', 'ﾒ');
        replaceHankakuKanaMap.put('モ', 'ﾓ');
        replaceHankakuKanaMap.put('ヤ', 'ﾔ');
        replaceHankakuKanaMap.put('ユ', 'ﾕ');
        replaceHankakuKanaMap.put('ヨ', 'ﾖ');
        replaceHankakuKanaMap.put('ラ', 'ﾗ');
        replaceHankakuKanaMap.put('リ', 'ﾘ');
        replaceHankakuKanaMap.put('ル', 'ﾙ');
        replaceHankakuKanaMap.put('レ', 'ﾚ');
        replaceHankakuKanaMap.put('ロ', 'ﾛ');
        replaceHankakuKanaMap.put('ワ', 'ﾜ');
        replaceHankakuKanaMap.put('ヲ', 'ｦ');
        replaceHankakuKanaMap.put('ン', 'ﾝ');
        replaceHankakuKanaMap.put('ガ', 'ｶﾞ');
        replaceHankakuKanaMap.put('ギ', 'ｷﾞ');
        replaceHankakuKanaMap.put('グ', 'ｸﾞ');
        replaceHankakuKanaMap.put('ゲ', 'ｹﾞ');
        replaceHankakuKanaMap.put('ゴ', 'ｺﾞ');
        replaceHankakuKanaMap.put('ザ', 'ｻﾞ');
        replaceHankakuKanaMap.put('ジ', 'ｼﾞ');
        replaceHankakuKanaMap.put('ズ', 'ｽﾞ');
        replaceHankakuKanaMap.put('ゼ', 'ｾﾞ');
        replaceHankakuKanaMap.put('ゾ', 'ｿﾞ');
        replaceHankakuKanaMap.put('ダ', 'ﾀﾞ');
        replaceHankakuKanaMap.put('ヂ', 'ﾁﾞ');
        replaceHankakuKanaMap.put('ヅ', 'ﾂﾞ');
        replaceHankakuKanaMap.put('デ', 'ﾃﾞ');
        replaceHankakuKanaMap.put('ド', 'ﾄﾞ');
        replaceHankakuKanaMap.put('パ', 'ﾊﾟ');
        replaceHankakuKanaMap.put('ピ', 'ﾋﾟ');
        replaceHankakuKanaMap.put('プ', 'ﾌﾟ');
        replaceHankakuKanaMap.put('ペ', 'ﾍﾟ');
        replaceHankakuKanaMap.put('ポ', 'ﾎﾟ');
        replaceHankakuKanaMap.put('バ', 'ﾊﾞ');
        replaceHankakuKanaMap.put('ビ', 'ﾋﾞ');
        replaceHankakuKanaMap.put('ブ', 'ﾌﾞ');
        replaceHankakuKanaMap.put('ベ', 'ﾍﾞ');
        replaceHankakuKanaMap.put('ボ', 'ﾎﾞ');
        replaceHankakuKanaMap.put('ヴ', 'ｳﾞ');

        // 20150628 ひらがな検索機能追加
        replaceHankakuKanaMap.put('ぁ', 'ｧ');
        replaceHankakuKanaMap.put('ぃ', 'ｨ');
        replaceHankakuKanaMap.put('ぅ', 'ｩ');
        replaceHankakuKanaMap.put('ぇ', 'ｪ');
        replaceHankakuKanaMap.put('ぉ', 'ｫ');
        replaceHankakuKanaMap.put('ゃ', 'ｬ');
        replaceHankakuKanaMap.put('ゅ', 'ｭ');
        replaceHankakuKanaMap.put('ょ', 'ｮ');
        replaceHankakuKanaMap.put('っ', 'ｯ');

        replaceHankakuKanaMap.put('あ', 'ｱ');
        replaceHankakuKanaMap.put('い', 'ｲ');
        replaceHankakuKanaMap.put('う', 'ｳ');
        replaceHankakuKanaMap.put('え', 'ｴ');
        replaceHankakuKanaMap.put('お', 'ｵ');
        replaceHankakuKanaMap.put('か', 'ｶ');
        replaceHankakuKanaMap.put('き', 'ｷ');
        replaceHankakuKanaMap.put('く', 'ｸ');
        replaceHankakuKanaMap.put('け', 'ｹ');
        replaceHankakuKanaMap.put('こ', 'ｺ');
        replaceHankakuKanaMap.put('さ', 'ｻ');
        replaceHankakuKanaMap.put('し', 'ｼ');
        replaceHankakuKanaMap.put('す', 'ｽ');
        replaceHankakuKanaMap.put('せ', 'ｾ');
        replaceHankakuKanaMap.put('そ', 'ｿ');
        replaceHankakuKanaMap.put('た', 'ﾀ');
        replaceHankakuKanaMap.put('ち', 'ﾁ');
        replaceHankakuKanaMap.put('つ', 'ﾂ');
        replaceHankakuKanaMap.put('て', 'ﾃ');
        replaceHankakuKanaMap.put('と', 'ﾄ');
        replaceHankakuKanaMap.put('な', 'ﾅ');
        replaceHankakuKanaMap.put('に', 'ﾆ');
        replaceHankakuKanaMap.put('ぬ', 'ﾇ');
        replaceHankakuKanaMap.put('ね', 'ﾈ');
        replaceHankakuKanaMap.put('の', 'ﾉ');
        replaceHankakuKanaMap.put('は', 'ﾊ');
        replaceHankakuKanaMap.put('ひ', 'ﾋ');
        replaceHankakuKanaMap.put('ふ', 'ﾌ');
        replaceHankakuKanaMap.put('へ', 'ﾍ');
        replaceHankakuKanaMap.put('ほ', 'ﾎ');
        replaceHankakuKanaMap.put('ま', 'ﾏ');
        replaceHankakuKanaMap.put('み', 'ﾐ');
        replaceHankakuKanaMap.put('む', 'ﾑ');
        replaceHankakuKanaMap.put('め', 'ﾒ');
        replaceHankakuKanaMap.put('も', 'ﾓ');
        replaceHankakuKanaMap.put('や', 'ﾔ');
        replaceHankakuKanaMap.put('ゆ', 'ﾕ');
        replaceHankakuKanaMap.put('よ', 'ﾖ');
        replaceHankakuKanaMap.put('ら', 'ﾗ');
        replaceHankakuKanaMap.put('り', 'ﾘ');
        replaceHankakuKanaMap.put('る', 'ﾙ');
        replaceHankakuKanaMap.put('れ', 'ﾚ');
        replaceHankakuKanaMap.put('ろ', 'ﾛ');
        replaceHankakuKanaMap.put('わ', 'ﾜ');
        replaceHankakuKanaMap.put('を', 'ｦ');
        replaceHankakuKanaMap.put('ん', 'ﾝ');

        replaceHankakuKanaMap.put('が', 'ｶﾞ');
        replaceHankakuKanaMap.put('ぎ', 'ｷﾞ');
        replaceHankakuKanaMap.put('ぐ', 'ｸﾞ');
        replaceHankakuKanaMap.put('げ', 'ｹﾞ');
        replaceHankakuKanaMap.put('ご', 'ｺﾞ');
        replaceHankakuKanaMap.put('ざ', 'ｻﾞ');
        replaceHankakuKanaMap.put('じ', 'ｼﾞ');
        replaceHankakuKanaMap.put('ず', 'ｽﾞ');
        replaceHankakuKanaMap.put('ぜ', 'ｾﾞ');
        replaceHankakuKanaMap.put('ぞ', 'ｿﾞ');
        replaceHankakuKanaMap.put('だ', 'ﾀﾞ');
        replaceHankakuKanaMap.put('ぢ', 'ﾁﾞ');
        replaceHankakuKanaMap.put('づ', 'ﾂﾞ');
        replaceHankakuKanaMap.put('で', 'ﾃﾞ');
        replaceHankakuKanaMap.put('ど', 'ﾄﾞ');
        replaceHankakuKanaMap.put('ぱ', 'ﾊﾟ');
        replaceHankakuKanaMap.put('ぴ', 'ﾋﾟ');
        replaceHankakuKanaMap.put('ぷ', 'ﾌﾟ');
        replaceHankakuKanaMap.put('ぺ', 'ﾍﾟ');
        replaceHankakuKanaMap.put('ぽ', 'ﾎﾟ');
        replaceHankakuKanaMap.put('ば', 'ﾊﾞ');
        replaceHankakuKanaMap.put('び', 'ﾋﾞ');
        replaceHankakuKanaMap.put('ぶ', 'ﾌﾞ');
        replaceHankakuKanaMap.put('べ', 'ﾍﾞ');
        replaceHankakuKanaMap.put('ぼ', 'ﾎﾞ');

        // 英語数字カナに置換 Map
        replaceHankakuEisujiMap.put('！', '!'); 
        replaceHankakuEisujiMap.put('”' , '\"'); 
        replaceHankakuEisujiMap.put('＃', '#'); 
        replaceHankakuEisujiMap.put('＄', '$'); 
        replaceHankakuEisujiMap.put('￥', '\\'); 
        replaceHankakuEisujiMap.put('％', '%'); 
        replaceHankakuEisujiMap.put('＆', '&'); 
        replaceHankakuEisujiMap.put('’', '\''); 
        replaceHankakuEisujiMap.put('（', '('); 
        replaceHankakuEisujiMap.put('）', ')'); 
        replaceHankakuEisujiMap.put('＊', '*'); 
        replaceHankakuEisujiMap.put('＋', '+'); 
        replaceHankakuEisujiMap.put('，', ','); 
        replaceHankakuEisujiMap.put('－', '-'); 
        replaceHankakuEisujiMap.put('．', '.'); 
        replaceHankakuEisujiMap.put('／', '/'); 
        replaceHankakuEisujiMap.put('０', '0'); 
        replaceHankakuEisujiMap.put('１', '1'); 
        replaceHankakuEisujiMap.put('２', '2'); 
        replaceHankakuEisujiMap.put('３', '3'); 
        replaceHankakuEisujiMap.put('４', '4'); 
        replaceHankakuEisujiMap.put('５', '5'); 
        replaceHankakuEisujiMap.put('６', '6'); 
        replaceHankakuEisujiMap.put('７', '7'); 
        replaceHankakuEisujiMap.put('８', '8'); 
        replaceHankakuEisujiMap.put('９', '9'); 
        replaceHankakuEisujiMap.put('：', ':'); 
        replaceHankakuEisujiMap.put('；', ';'); 
        replaceHankakuEisujiMap.put('＜' ,'<'); 
        replaceHankakuEisujiMap.put('＝', '='); 
        replaceHankakuEisujiMap.put('＞' ,'>'); 
        replaceHankakuEisujiMap.put('？', '?'); 
        replaceHankakuEisujiMap.put('＠', '@'); 
        replaceHankakuEisujiMap.put('Ａ', 'A'); 
        replaceHankakuEisujiMap.put('Ｂ', 'B'); 
        replaceHankakuEisujiMap.put('Ｃ', 'C'); 
        replaceHankakuEisujiMap.put('Ｄ', 'D'); 
        replaceHankakuEisujiMap.put('Ｅ', 'E'); 
        replaceHankakuEisujiMap.put('Ｆ', 'F'); 
        replaceHankakuEisujiMap.put('Ｇ', 'G'); 
        replaceHankakuEisujiMap.put('Ｈ', 'H'); 
        replaceHankakuEisujiMap.put('Ｉ', 'I'); 
        replaceHankakuEisujiMap.put('Ｊ', 'J'); 
        replaceHankakuEisujiMap.put('Ｋ', 'K'); 
        replaceHankakuEisujiMap.put('Ｌ', 'L'); 
        replaceHankakuEisujiMap.put('Ｍ', 'M'); 
        replaceHankakuEisujiMap.put('Ｎ', 'N'); 
        replaceHankakuEisujiMap.put('Ｏ', 'O'); 
        replaceHankakuEisujiMap.put('Ｐ', 'P'); 
        replaceHankakuEisujiMap.put('Ｑ', 'Q'); 
        replaceHankakuEisujiMap.put('Ｒ', 'R'); 
        replaceHankakuEisujiMap.put('Ｓ', 'S'); 
        replaceHankakuEisujiMap.put('Ｔ', 'T'); 
        replaceHankakuEisujiMap.put('Ｕ', 'U'); 
        replaceHankakuEisujiMap.put('Ｖ', 'V'); 
        replaceHankakuEisujiMap.put('Ｗ', 'W'); 
        replaceHankakuEisujiMap.put('Ｘ', 'X'); 
        replaceHankakuEisujiMap.put('Ｙ', 'Y'); 
        replaceHankakuEisujiMap.put('Ｚ', 'Z'); 
        replaceHankakuEisujiMap.put('＾', '^'); 
        replaceHankakuEisujiMap.put('＿', '_'); 
        replaceHankakuEisujiMap.put('‘', '`'); 
        replaceHankakuEisujiMap.put('ａ', 'a'); 
        replaceHankakuEisujiMap.put('ｂ', 'b'); 
        replaceHankakuEisujiMap.put('ｃ', 'c'); 
        replaceHankakuEisujiMap.put('ｄ', 'd'); 
        replaceHankakuEisujiMap.put('ｅ', 'e'); 
        replaceHankakuEisujiMap.put('ｆ', 'f'); 
        replaceHankakuEisujiMap.put('ｇ', 'g'); 
        replaceHankakuEisujiMap.put('ｈ', 'h'); 
        replaceHankakuEisujiMap.put('ｉ', 'i'); 
        replaceHankakuEisujiMap.put('ｊ', 'j'); 
        replaceHankakuEisujiMap.put('ｋ', 'k'); 
        replaceHankakuEisujiMap.put('ｌ', 'l'); 
        replaceHankakuEisujiMap.put('ｍ', 'm'); 
        replaceHankakuEisujiMap.put('ｎ', 'n'); 
        replaceHankakuEisujiMap.put('ｏ', 'o'); 
        replaceHankakuEisujiMap.put('ｐ', 'p'); 
        replaceHankakuEisujiMap.put('ｑ', 'q'); 
        replaceHankakuEisujiMap.put('ｒ', 'r'); 
        replaceHankakuEisujiMap.put('ｓ', 's'); 
        replaceHankakuEisujiMap.put('ｔ', 't'); 
        replaceHankakuEisujiMap.put('ｕ', 'u'); 
        replaceHankakuEisujiMap.put('ｖ', 'v'); 
        replaceHankakuEisujiMap.put('ｗ', 'w'); 
        replaceHankakuEisujiMap.put('ｘ', 'x'); 
        replaceHankakuEisujiMap.put('ｙ', 'y'); 
        replaceHankakuEisujiMap.put('ｚ', 'z'); 
        replaceHankakuEisujiMap.put('｛', '{'); 
        replaceHankakuEisujiMap.put('｜', '|'); 
        replaceHankakuEisujiMap.put('｝', '}'); 
        replaceHankakuEisujiMap.put('。', '｡'); 
        replaceHankakuEisujiMap.put('「', '｢'); 
        replaceHankakuEisujiMap.put('」', '｣'); 
        replaceHankakuEisujiMap.put('、', '､'); 
        replaceHankakuEisujiMap.put('・', '･'); 
        replaceHankakuEisujiMap.put('　', ' '); 
    }
    // 全角文字内容をすべて半角文字内容に変換.
    public static String zenkakuToHankaku(String value) {
        if( value == null || value.length() <= 0 ) {
            return '' ;
        }
        List<String> StringList = new List<String>();
        for( Integer i = 0 ; i < value.length() ; i ++ ) {
    
           String strChar = value.substring(i, i+1);
           // 半角カナに置換 
           String strCharTo = instance.replaceHankakuKanaMap.get(strChar);
           if( strCharTo != null && strCharTo.length() > 0 ) {
               strChar = strCharTo ;
           } else {
               // 全角英数字が半角英数字に置換 
               strCharTo = instance.replaceHankakuEisujiMap.get(strChar);
               if( strCharTo != null && strCharTo.length() > 0 ) {
                   strChar = strCharTo ;
               }
           }
           // 半角に置換 
           StringList.add(strChar);
        }
        return String.join(StringList, '');
    }
    // 全角英数字文字内容をすべて半角英数字文字内容に変換.
    public static String zenkakuEisujiToHankakuEisuji(String value) {
        if( value == null || value.length() <= 0 ) {
            return '' ;
        }
        List<String> StringList = new List<String>();
        for( Integer i = 0 ; i < value.length() ; i ++ ) {
           String strChar = value.substring(i, i+1);
           // 全角英数字が半角英数字に置換 
           String strCharTo = instance.replaceHankakuEisujiMap.get(strChar);
           if( strCharTo != null && strCharTo.length() > 0 ) {
               strChar = strCharTo ;
           }
           StringList.add(strChar);
        }
        return String.join(StringList, '');
    }
    private Map<String, String> replaceHankakuKanaMap;
    private Map<String, String> replaceHankakuEisujiMap;
    private static Map<String,Object> engTreeMap = new Map<String,Object>{
        'a'=> 'ア', 'i'=> 'イ', 'u'=> 'ウ', 'e'=> 'エ', 'o'=> 'オ',
        'k'=> new Map<String,Object>{
            'a'=> 'カ', 'i'=> 'キ', 'u'=> 'ク', 'e'=> 'ケ', 'o'=> 'コ',
            'y'=> new Map<String,String>{ 'a'=> 'キャ', 'i'=> 'キィ', 'u'=> 'キュ', 'e'=> 'キェ', 'o'=> 'キョ' }
        },
        's'=> new Map<String,Object>{
            'a'=> 'サ', 'i'=> 'シ', 'u'=> 'ス', 'e'=> 'セ', 'o'=> 'ソ',
            'h'=> new Map<String,String>{ 'a'=> 'シャ', 'i'=> 'シ', 'u'=> 'シュ', 'e'=> 'シェ', 'o'=> 'ショ' },
            'y'=> new Map<String,String>{ 'a'=> 'キャ', 'i'=> 'キィ', 'u'=> 'キュ', 'e'=> 'キェ', 'o'=> 'キョ' }
        },
        't'=> new Map<String,Object>{
            'a'=> 'タ', 'i'=> 'チ', 'u'=> 'ツ', 'e'=> 'テ', 'o'=> 'ト',
            'h'=> new Map<String,String>{ 'a'=> 'テャ', 'i'=> 'ティ', 'u'=> 'テュ', 'e'=> 'テェ', 'o'=> 'テョ' },
            'y'=> new Map<String,String>{ 'a'=> 'チャ', 'i'=> 'チィ', 'u'=> 'チュ', 'e'=> 'チェ', 'o'=> 'チョ' },
            's'=> new Map<String,String>{ 'a'=> 'ツァ', 'i'=> 'ツィ', 'u'=> 'ツ', 'e'=> 'ツェ', 'o'=> 'ツォ' }
        },
        'c'=> new Map<String,Object>{
            'a'=> 'カ', 'i'=> 'シ', 'u'=> 'ク', 'e'=> 'セ', 'o'=> 'コ',
            'h'=> new Map<String,String>{ 'a'=> 'チャ', 'i'=> 'チ', 'u'=> 'チュ', 'e'=> 'チェ', 'o'=> 'チョ' },
            'y'=> new Map<String,String>{ 'a'=> 'チャ', 'i'=> 'チィ', 'u'=> 'チュ', 'e'=> 'チェ', 'o'=> 'チョ' }
        },
        'q'=> new Map<String,String>{
            'a'=> 'クァ', 'i'=> 'クィ', 'u'=> 'ク', 'e'=> 'クェ', 'o'=> 'クォ'
        },
        'n'=> new Map<String,Object>{
            'a'=> 'ナ', 'i'=> 'ニ', 'u'=> 'ヌ', 'e'=> 'ネ', 'o'=> 'ノ', 'n'=> 'ン',
            'y'=> new Map<String,String>{ 'a'=> 'ニャ', 'i'=> 'ニィ', 'u'=> 'ニュ', 'e'=> 'ニェ', 'o'=> 'ニョ' }
        },
        'h'=> new Map<String,Object>{
            'a'=> 'ハ', 'i'=> 'ヒ', 'u'=> 'フ', 'e'=> 'ヘ', 'o'=> 'ホ',
            'y'=> new Map<String,String>{ 'a'=> 'ヒャ', 'i'=> 'ヒィ', 'u'=> 'ヒュ', 'e'=> 'ヒェ', 'o'=> 'ヒョ' }
        },
        'f'=> new Map<String,Object>{
            'a'=> 'ファ', 'i'=> 'フィ', 'u'=> 'フ', 'e'=> 'フェ', 'o'=> 'フォ',
            'y'=> new Map<String,String>{ 'a'=> 'フャ', 'u'=> 'フュ', 'o'=> 'フョ' }
        },
        'm'=> new Map<String,Object>{
            'a'=> 'マ', 'i'=> 'ミ', 'u'=> 'ム', 'e'=> 'メ', 'o'=> 'モ',
            'y'=> new Map<String,String>{ 'a'=> 'ミャ', 'i'=> 'ミィ', 'u'=> 'ミュ', 'e'=> 'ミェ', 'o'=> 'ミョ' }
        },
        'y'=> new Map<String,Object>{ 'a'=> 'ヤ', 'i'=> 'イ', 'u'=> 'ユ', 'e'=> 'イェ', 'o'=> 'ヨ' },
        'r'=> new Map<String,Object>{
            'a'=> 'ラ', 'i'=> 'リ', 'u'=> 'ル', 'e'=> 'レ', 'o'=> 'ロ',
            'y'=> new Map<String,String>{ 'a'=> 'リャ', 'i'=> 'リィ', 'u'=> 'リュ', 'e'=> 'リェ', 'o'=> 'リョ' }
        },
        'w'=> new Map<String,String>{ 'a'=> 'ワ', 'i'=> 'ウィ', 'u'=> 'ウ', 'e'=> 'ウェ', 'o'=> 'ヲ' },
        'g'=> new Map<String,Object>{
            'a'=> 'ガ', 'i'=> 'ギ', 'u'=> 'グ', 'e'=> 'ゲ', 'o'=> 'ゴ',
            'y'=> new Map<String,String>{ 'a'=> 'ギャ', 'i'=> 'ギィ', 'u'=> 'ギュ', 'e'=> 'ギェ', 'o'=> 'ギョ' }
        },
        'z'=> new Map<String,Object>{
            'a'=> 'ザ', 'i'=> 'ジ', 'u'=> 'ズ', 'e'=> 'ゼ', 'o'=> 'ゾ',
            'y'=> new Map<String,String>{ 'a'=> 'ジャ', 'i'=> 'ジィ', 'u'=> 'ジュ', 'e'=> 'ジェ', 'o'=> 'ジョ' }
        },
        'j'=> new Map<String,Object>{
            'a'=> 'ジャ', 'i'=> 'ジ', 'u'=> 'ジュ', 'e'=> 'ジェ', 'o'=> 'ジョ',
            'y'=> new Map<String,String>{ 'a'=> 'ジャ', 'i'=> 'ジィ', 'u'=> 'ジュ', 'e'=> 'ジェ', 'o'=> 'ジョ' }
        },
        'd'=> new Map<String,Object>{
            'a'=> 'ダ', 'i'=> 'ヂ', 'u'=> 'ヅ', 'e'=> 'デ', 'o'=> 'ド',
            'h'=> new Map<String,String>{ 'a'=> 'デャ', 'i'=> 'ディ', 'u'=> 'デュ', 'e'=> 'デェ', 'o'=> 'デョ' },
            'y'=> new Map<String,String>{ 'a'=> 'ヂャ', 'i'=> 'ヂィ', 'u'=> 'ヂュ', 'e'=> 'ヂェ', 'o'=> 'ヂョ' }
        },
        'b'=> new Map<String,Object>{
            'a'=> 'バ', 'i'=> 'ビ', 'u'=> 'ブ', 'e'=> 'ベ', 'o'=> 'ボ',
            'y'=> new Map<String,String>{ 'a'=> 'ビャ', 'i'=> 'ビィ', 'u'=> 'ビュ', 'e'=> 'ビェ', 'o'=> 'ビョ' }
        },
        'v'=> new Map<String,Object>{
            'a'=> 'ヴァ', 'i'=> 'ヴィ', 'u'=> 'ヴ', 'e'=> 'ヴェ', 'o'=> 'ヴォ',
            'y'=> new Map<String,String>{ 'a'=> 'ヴャ', 'i'=> 'ヴィ', 'u'=> 'ヴュ', 'e'=> 'ヴェ', 'o'=> 'ヴョ' }
        },
        'p'=> new Map<String,Object>{
            'a'=> 'パ', 'i'=> 'ピ', 'u'=> 'プ', 'e'=> 'ペ', 'o'=> 'ポ',
            'y'=> new Map<String,String>{ 'a'=> 'ピャ', 'i'=> 'ピィ', 'u'=> 'ピュ', 'e'=> 'ピェ', 'o'=> 'ピョ' }
        },
        'x'=> new Map<String,Object>{
            'a'=> 'ァ', 'i'=> 'ィ', 'u'=> 'ゥ', 'e'=> 'ェ', 'o'=> 'ォ',
            'y'=> new Map<String,String>{
                'a'=> 'ャ', 'i'=> 'ィ', 'u'=> 'ュ', 'e'=> 'ェ', 'o'=> 'ョ'
            },
            't'=> new Map<String,Object>{
                'u'=> 'ッ',
                's'=> new Map<String,String>{
                    'u'=> 'ッ'
                }
            }
        },
        'l'=> new Map<String,Object>{
            'a'=> 'ァ', 'i'=> 'ィ', 'u'=> 'ゥ', 'e'=> 'ェ', 'o'=> 'ォ',
            'y'=> new Map<String,String>{
                'a'=> 'ャ', 'i'=> 'ィ', 'u'=> 'ュ', 'e'=> 'ェ', 'o'=> 'ョ'
            },
            't'=> new Map<String,Object>{
                'u'=> 'ッ',
                's'=> new Map<String,String>{
                    'u'=> 'ッ'
                }
            }
        }
    };
    public class converRomanInfo{
        String result; 
        String tmp;
        Map<String,Object> node;
        Map<String,Object> tree;
        public converRomanInfo(){
            result = '';
            tmp = '';
            node = engTreeMap;
            tree = engTreeMap;
        }
        // ローマ字からカタカナへ変換ロジック
        // original：変更元文字列
        // allornone:true(ローマ字でお客様名が入って来た場合にカナに変換する、１文字でも変換できなかった場合（通常の英名だった場合など）は何もしない)
        public String process(String original, Boolean allornone){
            // original.replace('/[Ａ-Ｚａ-ｚ]/', s => String.fromCharCode(s.charCodeAt(0) - 65248)).toLowerCase();
            if (CommUtils.isBlank(original)) return '';
            String str = original.toLowerCase(); // 全角→半角→小文字
            Integer index = 0;
            Integer len = str.length();
            while (index < len) {
                String charStr = str.mid(index,1);
//system.debug(logginglevel.info,'charStr:::' + charStr);
                if (charStr.isAlpha()) { // 英数字以外は考慮しない
                    if (node.containsKey(charStr)) {
                        Object next = node.get(charStr);
//system.debug(LoggingLevel.info, 'next:::' + next);
                        if (CommUtils.nulltoBlank(next).isAlpha()) {
                            push(CommUtils.nullTOBlank(next),true);
                        } else {
                            tmp += original.mid(index,1);
                            node = (Map<String,Object>)next;
                        }
                        index++;
                        continue;
                    }
                    String prevStr = str.mid(index - 1,1);
                    // 2020/01/30 汉字问题修复 by zy BEGIN
                    if (index != 0 && !CommUtils.isBlank(prevStr) && (prevStr == 'n' || prevStr == charStr)) { // 促音やnへの対応
                    // 2020/01/30 汉字问题修复 by zy END
                        push(prevStr == 'n' ? 'ン' : 'ッ', false);
                    }
                    if (node !== tree && tree.containsKey(charStr)) { // 今のノードがルート以外だった場合、仕切り直してチェックする
                        push(tmp,true);
                        continue;
                    }
                }
//system.debug(logginglevel.info,'charStr【end】:::' + charStr);
                push(tmp + charStr,true);
                index++;
            }
            tmp = tmp.replaceAll('[n$]', 'ン'); // 末尾のnは変換する
            push(tmp,true);
//system.debug(logginglevel.info,'result:::' + result);
            if (allornone) {
                String regExp = '[a-zA-Z]';
                String changeRes = result.replaceAll(regExp, '');
                boolean hadAlphaFlg = changeRes.length() == result.length();
                if (!hadAlphaFlg) return original;
            }
            return result;
        }
        private void push(String charStr ,boolean toRoot){
            result += charStr;
            tmp = '';
            node = toRoot ? tree : node;
        }
    }
    
    // ローマ字からカタカナへ変換ロジック
    // original：変更元文字列
    // allornone:true(ローマ字でお客様名が入って来た場合にカナに変換する、１文字でも変換できなかった場合（通常の英名だった場合など）は何もしない)
    public static String convertRomanToKana(String original, Boolean allornone){
        ConverRomanInfo info = new converRomanInfo();
        return info.process(original,allornone);
        /*
        // original.replace('/[Ａ-Ｚａ-ｚ]/', s => String.fromCharCode(s.charCodeAt(0) - 65248)).toLowerCase();
        String str = original.toLowerCase(); // 全角→半角→小文字
        Integer index = 0;
        Integer len = str.length();
        String result = '';
        String tmp = '';
        Map<String,Object> node = engTreeMap;
        while (index < len) {
            String charStr = str.mid(index,1);
system.debug(logginglevel.info,'charStr:::' + charStr);
            if (charStr.isAlpha()) { // 英数字以外は考慮しない
                if (node.containsKey(charStr)) {
                    Object next = node.get(charStr);
                    if (CommUtils.nulltoBlank(next).isAlpha()) {
                        push(CommUtils.nullTOBlank(next),true);
                    } else {
                        tmp += original.mid(index,1);
                        node = (Map<String,Object>)next;
                    }
                    index++;
                    continue;
                }
                String prevStr = str.mid(index - 1,1);
                if (!CommUtils.isBlank(prevStr) && (prevStr == 'n' || prevStr == charStr)) { // 促音やnへの対応
                    push(prevStr == 'n' ? 'ン' : 'ッ', false);
                }
                if (node !== engTreeMap && engTreeMap.containsKey(charStr)) { // 今のノードがルート以外だった場合、仕切り直してチェックする
                    push(tmp,true);
                    continue;
                }
            }
system.debug(logginglevel.info,'charStr【end】:::' + charStr);
            push(tmp + charStr,true);
            index++;
        }
        tmp = tmp.replaceAll('[n$]', 'ン'); // 末尾のnは変換する
        push(tmp,true);
system.debug(logginglevel.info,'result:::' + result);
*/
/*
		if (allornone) {
			index = 0;
			while (index < len) {
				String charStr = str.mid(index,1);
			}
		}*/
        // return result;
    }
}