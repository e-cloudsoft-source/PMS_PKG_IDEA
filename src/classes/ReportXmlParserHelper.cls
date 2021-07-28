public with sharing class ReportXmlParserHelper {
        // サポートのページサイズ
    public enum PAGETYPE{A4,A3,A5,B4,B5}
    public static String getPdfPagePaperSize (String pty) {
        if (pty == PAGETYPE.A4.name()) return '8.27in 11.69in;';
        else if (pty == PAGETYPE.B5.name()) return '6.93in 9.84in;';
        else if (pty == PAGETYPE.A3.name()) return '11.69in 16.54in;';
        else if (pty == PAGETYPE.A5.name()) return '5.83in 8.27in;';
        else if (pty == PAGETYPE.B4.name()) return '10.12in 14.33in;';
        else return '8.27in 11.69in;';
    }
    // 2018/03/05 PDF7横向的A5纸张 zyz BEGIN
    public static String getPdfPagePaperSizeTraverse (String pty,Boolean flg) {
    	if(flg) {
	        if (pty == PAGETYPE.A4.name()) return '11.69in 8.27in;';
	        else if (pty == PAGETYPE.B5.name()) return '9.84in 6.93in;';
	        else if (pty == PAGETYPE.A3.name()) return '16.54in 11.69in;';
	        else if (pty == PAGETYPE.A5.name()) return '8.27in 5.83in;';
	        else if (pty == PAGETYPE.B4.name()) return '14.33in 10.12in;';
	        else return '11.69in 8.27in;';
    	} else return getPdfPagePaperSize(pty);
    }
    // 2018/03/05 PDF7横向的A5纸张 zyz END
    //public static final String BLANK_IMG_URL = '/resource/'+CommConst.APPOTION_NAMESPACE+'reportFiles/img/blank';
    // XML定義内容「ROWS」間に定義したXML情報からHTMLへ変換処理ロジック
    // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
    public static String convertXmlTagToHtml(Dom.XMLNode xmlTag) {
     	return convertXmlTagToHtmlTemplate(xmlTag).parseHtml;
    }
    public static HtmlTemplate convertXmlTagToHtmlTemplate(Dom.XMLNode xmlTag) {
        String htmlStr='';
        HtmlTemplate template = new HtmlTemplate();
        //if (xmlTag == null) return htmlStr;
       	if (xmlTag == null) return template; 
       	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
        for (Dom.xmlNode rowNode : xmlTag.getChildElements()){
            string rowStyle = CommUtils.nullToBlank(rowNode.getAttribute('STYLE',null));
            // 2019/02/28 pdf4签名页面自定义为空BUG修正，特殊处理 BY zyz BEGIN
            htmlStr +='<tr style=" white-space:nowrap;'+rowStyle+'" class="divBlank"><td>';
            // 2019/02/28 pdf4签名页面自定义为空BUG修正，特殊处理 BY zyz END
            // COL定義情報
            for (Dom.xmlNode colNode : rowNode.getChildElements()) {
                String tagNm = colNode.getName();
                if(tagNm == 'COL'){
                    // 列の定義情報を作成する
                    string colStyle = CommUtils.nullToBlank(colNode.getAttribute('STYLE',null));
                    string colMode = CommUtils.nullToBlank(colNode.getAttribute('MODE',null));
                    String colText = CommUtils.nullToBlank(colNode.getText());
                    string begKey = (colMode != 'SPAN') ? '<div ' : '<span ';
                    string endKey = (colMode != 'SPAN') ? '</div>' : '</span>';
                    htmlStr += begKey + (CommUtils.isBlank(colStyle) ? '>' : (' style="'+colStyle + '">'));
                    // タグの次のタグが存在する場合
                    for (Dom.xmlNode colItemNode : colNode.getChildElements()) {
                        String colTagNm = colItemNode.getName();
                        String colItemStyle = CommUtils.nullToblank(colItemNode.getAttribute('STYLE',null));
                        if(colTagNm == 'SQUARE'){ 
                            String colBegKey = '<div style="border-width:1px;border-style:solid;font-size: 1em;background-color:white;';
                            htmlStr += colBegKey + colItemStyle + '"></div>';
                        } else if(colTagNm == 'UNDERLINE'){
                            String colBegKey = '<div style=" border-bottom: solid 1px #848689;';
                            // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
                            String colval = CommUtils.nullToblank(colItemNode.getText());
                            Integer underHeight = CommUtils.nullToIntZero(CommUtils.nullToBlank(colItemStyle).substringBetween( 'height:', 'px;' ));
                            // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
                            Integer repeater = CommUtils.nullToIntZero(colItemNode.getAttribute('REPEAT',null));
                            if (repeater <= 0) repeater = 1;
                            for (Integer i =0; i < repeater ;i++){
                            	// 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
                            	String  key = '';
                            	if (!CommUtils.isBlank(colval)) key = colval+'_' + i;
                            	if(underHeight-14 > 0) {
                            		htmlStr +='<div style="height:'+(underHeight-14)+'px;">&nbsp;</div>';
                            		colItemStyle = colItemStyle.Replace('height:'+underHeight,'height:14');
                            	}
                            	//htmlStr += colBegKey + colItemStyle + '"></div>';
                                htmlStr += colBegKey + colItemStyle + '">'+ key + '</div>';
                                if (!template.splitMap.containsKey(colval)) template.splitMap.put(colval,new List<String>());
                                template.splitMap.get(colval).add(key);
                                // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
                            }
                        }
                    }
                    htmlStr += colText + endKey;
                }
            }
            htmlStr += '</td></tr>';
        }
        // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
        template.parseHtml = htmlStr;
        // return htmlStr;
        return template;
        // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
    }
    // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz BEGIN
    public class HtmlTemplate{
    	public String parseHtml;
    	public Map<String,List<String>> splitMap;
    	public HtmlTemplate(){
    		parseHtml = '';
    		splitMap = new Map<String,List<String>>();
    	}
    }
    // 2018/12/30 レジカード４、お客様情報以下のセクションはカスタマイズできるように改善 BY zyz END
    // 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz BEGIN
    public static String convertXmlTagToSurveys(Dom.XMLNode xmlTag) {
        String htmlStr='';
        if (xmlTag == null) return htmlStr;
        for (Dom.xmlNode rowNode : xmlTag.getChildElements()){
        	// 黑色框一行显示处理
        	String rowItemTitle = CommUtils.nullToblank(rowNode.getAttribute('TITLE',null));
        	String rowItemStyle = CommUtils.nullToblank(rowNode.getAttribute('STYLE',null));
        	String itemTitleStr = itemTitle.replace('$$_ITEMTITLE_$$',rowItemTitle);
        	itemTitleStr = itemTitleStr.replace('$$_AUTO_$$',rowItemStyle);
        	if(!CommUtils.isBlank(rowItemTitle)) htmlStr += trItemBegin + itemTitleStr + trEnd;
        	for (Dom.xmlNode colNode : rowNode.getChildElements()) {
        		String colTagNm = colNode.getName();
        		// 白色框一行显示处理
        		if(colTagNm == 'ROW'){
	        		String colItemTitle = CommUtils.nullToblank(colNode.getAttribute('TITLE',null));
	        		String colItemStyle = CommUtils.nullToblank(colNode.getAttribute('STYLE',null));
	        		String colItemSize = CommUtils.nullToblank(colNode.getAttribute('SIZE',null));
	        		String valuationStr = valuation.replace('$$_VALUATION_$$',colItemTitle);
	        		valuationStr = valuationStr.replace('$$_AUTO_$$',colItemStyle);
	        		String colText = CommUtils.nullToBlank(colNode.getText());
	        		String trHtml ='';
	        		String[] colSizelst = colItemSize.split(',');
	        		String[] colTextlst = colText.split(',');
	        		for(Integer i=0;i < colTextlst.size();i++){
	        			if(CommUtils.isBlank(colTextlst[i])) continue;
	        			String appraisalStr = appraisal.replace('$$_APPRAISAL_$$',CommUtils.nullToblank(colTextlst[i]));
	        			String colSizeStr = (colSizelst.size() > i ? colSizelst[i]+'px' : 'auto');
	        			appraisalStr = appraisalStr.replace('$$_AUTO_$$',colSizeStr); 
	        			trHtml += appraisalStr;
	        		}
	        		htmlStr += trValuaBegin + valuationStr + trHtml + trEnd;
	        	// 下划线显示处理
        		}else if(colTagNm == 'UNDERLINE'){
        			htmlStr += trValuaBegin;
                    String colBegKey = '<div style=" border-bottom: solid 1px #848689;';
                    String colItemStyle = CommUtils.nullToblank(colNode.getAttribute('STYLE',null));
                    Integer repeater = CommUtils.nullToIntZero(colNode.getAttribute('REPEAT',null));
                    if (repeater <= 0) repeater = 1;
                    for (Integer i =0; i < repeater ;i++){
                        htmlStr += colBegKey + colItemStyle + '"></div>';
                    }
                    htmlStr +=trEnd;
        		}
        	}
        }
        return htmlStr;
    }
    // 黑色框title
	private static String itemTitle = '<div  style="display:inline-block;width:6px;$$_AUTO_$$"></div><div  style="display:inline-block;"><div style="border-width:1px;font-size: 1em;background-color:white;height:9px; width:9px;margin-right:3px;"></div></div><div  style="color: white;font-size: 12px;display:inline-block;">$$_ITEMTITLE_$$</div>';
	// 白色框title
	private static String valuation = '<div  style="display:inline-block;margin-left:25px;$$_AUTO_$$"><div style="border-width:1px;border-style:solid;font-size: 1em;background-color:white;height:7px; width:7px;background-color: black;margin-right:3px;"></div></div><div  style="width:280px;display:inline-block;">$$_VALUATION_$$</div>';
	// 评价
	private static String appraisal = '<div  style="display:inline-block;"><div style="border-width:1px;border-style:solid;font-size: 1em;background-color:white;height:7px; width:7px;margin-right:3px;"></div></div><div  style="width:$$_AUTO_$$;display:inline-block;font-size: 8pt;">$$_APPRAISAL_$$</div>';
	// 黑色框的行
	private static String trItemBegin = '<tr style=" white-space:nowrap;background: black;height: 22px;line-height:1%;"><td>';
	// 白色框的行
	private static String trValuaBegin = '<tr style=" white-space:nowrap;font-size: 9pt;height:24px;"><td>';
	// 行结尾
	private static String trEnd = '</td></tr>';
	// 2019/02/28 陣屋組織、アンケート出力の文言等のカスタマイズは可能機能対応 BY zyz END
	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz BEGIN
	public static String convertXmlTagToString (Dom.XMLNode xmlTag) {
        String htmlStr='';
        if (xmlTag == null) return htmlStr;
        // 设定的宽度取得
        string cols = CommUtils.nullToBlank(xmlTag.getAttribute('COLSIZE',null));
        String groupStr = '';
        if(!CommUtils.isBlank(cols)){
        	for(String gro : cols.split(',')){
        		groupStr +='<colgroup style="width:'+gro+'"></colgroup>';
        	}
        }
        htmlStr += groupStr;
        // 循环TR层
        for (Dom.xmlNode rowNode : xmlTag.getChildElements()){
            // tr的style属性获取
            string rowStyle = CommUtils.nullToBlank(rowNode.getAttribute('STYLE',null));
            htmlStr +='<tr style="' + rowStyle + ' " class="img_display divBlank" >';
            // 循环TD层
            for (Dom.xmlNode colNode : rowNode.getChildElements()) {
            	// td的style属性获取
            	string colStyle = CommUtils.nullToBlank(colNode.getAttribute('STYLE',null));
            	// 合并列的值
            	Integer colSpanNum = CommUtils.nullToIntZero(colNode.getAttribute('COLSPAN',null));
            	if(colSpanNum == 0) colSpanNum = 1;
            	// 显示的内容
            	String colText = CommUtils.nullToBlank(colNode.getText());
            	// 拼成td显示
            	htmlStr +='<td colspan="' + colSpanNum + '" style="' + colStyle + '" ><span style="margin-left:2px;">' + colText +'</span></td>';
            	
            }
            htmlStr +='</tr>';
        }
        return htmlStr;
	}
	// 2019/10/30 レジカード8のカスタマイズ機能の改善 BY zyz END
	// 2021/07/30 #JP10785 by zy BEGIN
    public static String convertNewXmlTagToString (Dom.XMLNode xmlTag) {
        String htmlStr = '';
        if (xmlTag == null) return htmlStr;
        return convertNewXmlTagToString(xmlTag,false);
    }
    private static String htmlTemp = '<_tagName_ _attrs_ >_content_</_tagName_>';
    public static String convertNewXmlTagToString (Dom.XMLNode xmlTag,boolean isTable) {
        String htmlStr = '';
        // 循环TR层
        for (Dom.xmlNode rowNode : xmlTag.getChildElements()){
            boolean ptableFlg = isTable;
            String tagName = rowNode.getName();

            boolean isHadChildFlg = rowNode.getChildElements().size() > 0;
            // style属性获取
            String attrStr = '';
            String tagType = '';
            if (tagName == 'TABLE') {
                ptableFlg = true;
                tagType = 'table';
            } else if (tagName == 'COL') {
                tagType = ptableFlg ? 'td' : 'span';
            } else if (tagName == 'ROW') {
                tagType = ptableFlg ? 'tr' : 'div';
            } else {
                tagType = tagName;
            }
            for (integer i = 0 ; i < rowNode.getAttributeCount() ; i++) {
                String key = rowNode.getAttributeKeyAt(i);
                String val = rowNode.getAttribute(key,null);
                if (!Commutils.isBlank(val)) {
                    attrStr += ' ' + key.toLowerCase() + '="' + val + '"';
                }
            }
            String hmltTxt = htmlTemp.replaceAll('_tagName_',tagType)
                        .replaceAll('_attrs_',attrStr);
            // 合并列的值
            Integer colSpanNum = CommUtils.nullToIntZero(rowNode.getAttribute('COLSPAN',null));
            String colspanStr = '';
            if(colSpanNum > 1) {
                colspanStr = 'colspan="' + colSpanNum + '"';
            }
            hmltTxt = hmltTxt.replace('_colspan_',colspanStr); 
            // 存在子节点回归调用
            if (isHadChildFlg) {
                hmltTxt = hmltTxt.replace('_content_', convertNewXmlTagToString(rowNode,ptableFlg));
            } else {
                // 显示的内容
                String colText = CommUtils.nullToBlank(rowNode.getText());
                hmltTxt = hmltTxt.replace('_content_', colText);
            }
            htmlStr += hmltTxt;

        }
        return htmlStr;
    }
	// 2021/07/30 #JP10785 by zy END
}