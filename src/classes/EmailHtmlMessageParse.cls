/*
* メール取込の機能のHTMLレイアウトの解析と取り込みクラス
* by shuu 
*/
public with sharing class EmailHtmlMessageParse {
	//会計明細区分
	String detailBef = 'Check-In';
	//
	List<HtmlInfo> headLst;
	List<HtmlInfo> footLst;
	List<HtmlInfo> detailLst;
	//
	List<DetailIdx> detailIdxLst;
	//
	String afterText;
	//タンプレート
	Template beginTemp;
	Template endTemp;
	Template detailTemp;
	String mailHonbon = ' $$head$$ \n $$body$$ \n $$foot$$ ';
	String changeDetailIdx = '';
	String headBegin = '';
	String detailBegin = '';
	String footBegin = '';
	Map<String,DetailIdx> spicalMap;
    public EmailHtmlMessageParse(EmailMessageToLeadHelp.AgtInfo agtInfo){
    	String templateName = agtInfo.emailTemplate;
    	Dom.XMLNode root = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc(templateName,new String[]{'',''});
		headLst = new List<HtmlInfo>();
		footLst = new List<HtmlInfo>();
		detailLst = new List<HtmlInfo>();
		detailIdxLst = new List<DetailIdx>();
		spicalMap = new Map<String,DetailIdx>();
		for ( Dom.xmlNode node : root.getChildElements()){
			if ( node.getName() == 'EMAIL_TEMPLATE') {
				Dom.xmlNode beginTempNode = node.getChildElement('EMAIL_HEAD',null);
				if (beginTempNode != null) {
					beginTemp = new Template(beginTempNode);
				}
				Dom.xmlNode endTempNode = node.getChildElement('EMAIL_END',null);
				if (endTempNode != null) {
					endTemp = new Template(endTempNode);
				}
				Dom.xmlNode detailTempNode = node.getChildElement('EMAIL_DETAIL',null);
				if (detailTempNode != null) {
					detailTemp = new Template(detailTempNode);
				}
			}else if ( node.getName() == 'EMIAL_DATA'){
				for (Dom.xmlNode dNode : node.getChildElements()) {
					if ( dNode.getName() == 'EMAIL_FOOT') {
						for (Dom.xmlNode detailNode : dNode.getChildElements()) {
							String detailName = detailNode.getName();
							if (detailName == 'HTML_BEG') {
								footBegin = detailNode.getText();
							}else{
								HtmlInfo html = new HtmlInfo(detailNode);
								footLst.add(html);
							}
						}
					} else if ( dNode.getName() == 'EMAIL_DETAIL' ) {
						for ( Dom.xmlNode htmlNode : dNode.getChildElements() ) {
							String nodeName = htmlNode.getName();
							if (nodeName == 'DETAIL_IDX') {
								DetailIdx d = new DetailIdx(htmlNode);
								detailIdxLst.add(d);
							} else if (nodeName == 'HTML_DETAIL') {
								HtmlInfo html = new HtmlInfo(htmlNode);
								detailLst.add(html);
							} else if (nodeName == 'HTML_BEG') {
								detailBegin = htmlNode.getText();
							}
						}
						changeDetailIdx = dNode.getAttribute('detailidx',null);
					} else if (dNode.getName() == 'EMAIL_HEAD') {
						for ( Dom.xmlNode htmlNode : dNode.getChildElements() ) {
							String detailName = htmlNode.getName();
							if (detailName == 'HTML_BEG') {
								headBegin = htmlNode.getText();
							}else{
								HtmlInfo html = new HtmlInfo(htmlNode);
								headLst.add(html);
							}
						}
					}
				}
			}
		}
    }
    public String exportEamil(String htmlBody){
    	//system.debug(logginglevel.info,'htmlBody:::' + htmlBody);
    	//邮件开头
    	String emailHead = '';
    	String headBody = htmlBody;
    	if(!CommUtils.isBlank(headBegin)) headBody = headBody.subStringAfter(headBegin);
    	if(!CommUtils.isBlank(beginTemp.endReg)) headBody = headBody.subStringBefore(beginTemp.endReg);
    	if(!CommUtils.isBlank(beginTemp.tempContent)) mailHonbon = mailHonbon.replace('$$head$$',beginTemp.tempContent);
    	
    	//邮件结尾
		String emailFoot = '';
    	String footBody = htmlBody;
    	if(!CommUtils.isBlank(footBegin)) footBody = footBody.subStringAfter(footBegin);
    	if(!CommUtils.isBlank(endTemp.endReg)) footBody = footBody.subStringBefore(endTemp.endReg);
    	if(!CommUtils.isBlank(endTemp.tempContent)) mailHonbon = mailHonbon.replace('$$foot$$',endTemp.tempContent);
    	
    	for (integer i = 0; i < headLst.size() ; i++) {
    		HtmlInfo html = headLst.get(i);
    		html.getText(headBody);
    		String splitStr = html.oneRowFlag ? '\n' : '';
			for (DetailIdx detail : html.detailLst) {
				String idx =  detail.index; 
				String value = html.value;
				if (!CommUtils.isBlank(detail.template)) value = detail.getValue(value);
				//system.debug(logginglevel.info,'idx:::' + idx);
				mailHonbon = mailHonbon.replace(idx,value);
			}
				//detailExpotMap.put(html.setposition,i);
				//contengText += splitStr + html.getLabel();
    	}
    	
    	//system.debug(logginglevel.info,'emailHead:::' + emailHead);
    	//明细处理
    	String detailBody = htmlBody;
    	String emailDetail = '';
    	String detailContent = '';
    	// 过滤明细内容
    	if(!CommUtils.isBlank(detailBegin)) {
    		String firstContent = detailBody.substringBefore(detailBegin);
			String secondContent = detailBody.substringAfter(detailBegin);
			detailContent = firstContent.subString(firstContent.lastindexof('<table '));
			detailContent += detailBef;
			//system.debug(logginglevel.info,'secondContent:::' + secondContent);
			detailContent += secondContent.subString(0,secondContent.indexof('</table>') + '</table>'.length());
    		//detailBody = detailBody.subStringAfter(detailTemp.beforeReg);
    	}
    	//if(!CommUtils.isBlank(detailTemp.endReg)) detailBody = detailBody.subStringBefore(detailTemp.endReg);
    	if(!CommUtils.isBlank(detailTemp.tempContent)) emailDetail = detailTemp.tempContent;
		// 明细所在table构成
		
		TableInfo tableInfo = new TableInfo(detailContent);
		//System.debug(logginglevel.info,'tableInfo:::' + tableInfo);
		String detailValueContent = '';
		HtmlInfo loopHtml;
		integer trIndex = 0;
		for (TrInfo tr :  tableInfo.tbody) {
			String headContent = detailTemp.head;
			trIndex ++;
			headContent = headContent.replace('$_$',trIndex+'');
			integer loopIndex = 1;
			for (HtmlInfo html : detailLst) {
				if(html.loopFlag) {
					integer idx = tableInfo.titleTr.getIdx(html.htmlTag);
					TdInfo td = tr.getTdInfoByIdx(idx);
					//System.debug(logginglevel.info,'tr:::' + tr);
					if (td != null) {
						loopIndex = CommUtils.nullToIntZero(td.text);
						loopHtml = html;
					}
				}
			}
			String parentContent = '';
			for (integer i = 0 ; i < loopIndex ; i++) {
				String content = emailDetail;
				for (HtmlInfo html : detailLst) {
					integer idx = tableInfo.titleTr.getIdx(html.htmlTag);
					TdInfo td = tr.getTdInfoByIdx(idx);
					if (td != null) {
						if (html.getValueType == 'loopDate') {
							//System.debug(logginglevel.info,'td.text:::' + td.text);
							Date d = CommUtils.stringEnToDate(td.value);
							d = d.addDays(i);
							Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
							td.text = dt.format('yyyy/MM/dd');
							//System.debug(logginglevel.info,'html.detailLst:::' + html.detailLst); 
						}
						for (DetailIdx detail : html.detailLst) {
							if (detail.specialFlag) {
								detail.compareValue(td.text);
								spicalMap.put(html.htmlTag,detail);
								continue;
							}
							String idxStr = detail.index;
							String tdValue = td.text;
							if (!CommUtils.isBlank(detail.template)) tdValue = detail.getValue(tdValue);
							content = content.replace(idxStr,tdValue);
						}
					}
				}
				//system.debug(logginglevel.info,'content:::' + content);
				//content = content.replace();
				parentContent += content;
			}
			for (DetailIdx detail : detailIdxLst) {
				String idxStr = detail.index;
				if (!CommUtils.isBlank(detail.template)) parentContent = parentContent.replace(idxStr,detail.template);
			}
			detailValueContent += (headContent + parentContent + '\n');
		}
		//system.debug(logginglevel.info,'detailValueContent:::' + detailValueContent);
		mailHonbon = mailHonbon.replace('$$body$$',detailValueContent);
		//system.debug(logginglevel.info,'changeDetailIdx:::' + changeDetailIdx);
		if (!CommUtils.isBlank(changeDetailIdx)){
			String idxStr = changeDetailIdx;
			mailHonbon = mailHonbon.replace(idxStr,trIndex+'');
		}
    	for (integer i = 0; i < footLst.size() ; i++) {
    		HtmlInfo html = footLst.get(i);
    		html.getText(headBody);
    		String splitStr = html.oneRowFlag ? '\n' : '';
			for (DetailIdx detail : html.detailLst) {
				String idx = detail.index;
				String value = html.value;
				if (!CommUtils.isBlank(detail.template)) value = detail.getValue(value);
				//detail.template.replace('$_$',value);
				//system.debug(logginglevel.info,'idx:::' + idx);
				mailHonbon = mailHonbon.replace(idx,value);
			}
    	}
    	//system.debug(logginglevel.info,'spicalMap:::' + spicalMap);
    	for (String htmlTag : spicalMap.keySet()) {
    		DetailIdx d = spicalMap.get(htmlTag);
    		String idx = d.index;
    		mailHonbon = mailHonbon.replace(idx,d.compareValue);
    	}
		//system.debug(logginglevel.info,'mailHonbon:::' + mailHonbon);
		String emailContent = '';
		for (String line : mailHonbon.split('\n')) {
			if (!line.contains('$$')) emailContent += ( line + '\n');
		}
		//emailEndContent
		//system.debug(logginglevel.info,'emailContent:::' + emailContent);
		return emailContent;
    }
    class Template{
    	String beforeReg;
    	String tempContent;
    	String endReg;
    	String head;
    	public Template(Dom.xmlNode htmlNode){
    		Dom.xmlNode htmlBegNode = htmlNode.getChildElement('HTML_BEG',null);
    		if (htmlBegNode != null) {
    			beforeReg = htmlBegNode.getText();
    		}
    		Dom.xmlNode htmlTemNode = htmlNode.getChildElement('HTML_TEM',null);
    		if (htmlTemNode != null) {
    			tempContent = htmlTemNode.getText();
    		}
    		Dom.xmlNode htmlEndNode = htmlNode.getChildElement('HTML_END',null);
    		if (htmlEndNode != null) {
    			endReg = htmlEndNode.getText();
    		}
    		Dom.xmlNode htmlHeadNode = htmlNode.getChildElement('HTML_HEAD',null);
    		if (htmlHeadNode != null) {
    			head = htmlHeadNode.getText();
    		}
    		
    	}
    }
    class HtmlInfo{
		String htmlTag;
		String htmlBeg;
		String htmlEnd;
		String htmlName;
		String htmlValue;
		String format;
		String value;
		String htmlIdx;
		integer skipIdx;
		integer cycidx;
		List<DetailIdx> detailLst; 
		boolean oneRowFlag;
		boolean oneColProcessFlag;
		boolean loopFlag;
		Object changeValue;
		String getValueType;
		public HtmlInfo(Dom.xmlNode htmlNode){
			oneColProcessFlag = true;
			oneRowFlag = true;
			loopFlag = false;
			detailLst = new List<DetailIdx>();
			String oneRow = htmlNode.getAttribute('onerow',null);
			if ( oneRow == 'false') oneRowFlag = false;
			
			for (Dom.xmlNode node : htmlNode.getChildElements()) {
				String nodeName = node.getName();
				if (nodeName == 'HTML_TAG') {
					htmlTag = node.getText();
					getValueType = node.getAttribute('type',null);
					cycidx = CommUtils.nullToIntZero(node.getAttribute('cycidx',null));
					skipIdx = CommUtils.nullToIntZero(node.getAttribute('skiptd',null));
				} else if (nodeName == 'HTML_BEG') {
					htmlBeg = node.getText();
				} else if (nodeName == 'HTML_END') {
					htmlEnd = node.getText();
				} else if (nodeName == 'HTML_NAME') {
					htmlName = node.getText();	
				} else if (nodeName == 'HTML_FORMAT') {
					format = node.getText();
				} else if (nodeName == 'DETAIL_IDX') {
					DetailIdx d = new DetailIdx(node);
					detailLst.add(d);
				} else if (nodeName == 'HTML_VALUE') {
					htmlValue = node.getText();
				}
			}
			if ( getValueType == 'moreTd' || getValueType == 'vertical') oneColProcessFlag = false;
			if ( getValueType == 'loop') loopFlag = true;
		}
		public String getText(String htmlContent){
			String content = '';
			//system.debug(logginglevel.info,'htmlTag::::' + htmlTag);
			List<String> tagLst = htmlTag.split(',');
			String currentTag = '';
			for (String tag : tagLst) {
				if ( htmlContent.contains(tag) ) {
					currentTag = tag;
					break;
				}
			}
			
			if (oneColProcessFlag) {
				content = htmlContent.subStringAfter(htmlTag);
				if ( !CommUtils.isBlank(htmlBeg) ) {
					//findContent = findContent.subStringAfter(htmlBeg);
					content = content.subStringAfter(htmlBeg);
				}
				String endString = CommUtils.isBlank(htmlEnd) ? '</td>' : htmlEnd;
				content = content.subStringBefore(endString);
			} else {
				String findContentBef = htmlContent.subStringBefore(htmlTag);
				findContentBef = findContentBef + htmlTag;
				String findContentAft = htmlContent.subStringAfter(htmlTag);
				integer tagBeforeIdx =  findContentBef.lastIndexof('<tr');
				String beforeContent = findContentBef.subString(tagBeforeIdx);
				String afterContent = findContentAft.subStringBefore('</tr>');
				String processedContent = beforeContent + afterContent + '</tr>';
				//system.debug(logginglevel.info,'processedContent::::' + processedContent);
				TrInfo tr =  new TrInfo(processedContent);
				integer idx = tr.getIdx(htmlTag);
				idx += skipIdx;
				if ( getValueType == 'vertical' ) {
					findContentAft = htmlContent.subStringAfter(processedContent);
					findContentAft = findContentAft.subStringBefore('</tr>') + '</tr>';
					//system.debug(logginglevel.info,'findContentAft::::' + findContentAft);
					TrInfo processedTr =  new TrInfo(findContentAft);
					content = processedTr.getTextByIdx(idx);
				} else {
					idx++;
					content = tr.getTextByIdx(idx);
				}
			}
			if(!CommUtils.isBlank(format)) {
				Pattern isnumbersPattern = Pattern.Compile(format);
				Matcher numberMatch = isnumbersPattern.matcher(content);
				if(numberMatch.find()){
					if (!CommUtils.isBlank(htmlValue)) {
						if (htmlValue.contains('$$')) {
							value = htmlValue.replace('$$',value);
						} else
							value = htmlValue;
					}else {
						value =  numberMatch.group();
					}
					return value;
				}
			}
			
			//system.debug(logginglevel.info,'content::::' + content);
			value = content.stripHtmlTags();
			if (!CommUtils.isBlank(htmlValue)) {
				if (htmlValue.contains('$$')) {
					value = htmlValue.replace('$$',value);
				} else
					value = htmlValue;
			}
				
			
			return content;
		}
		public string getTdtext(String content){
			//content = content.subStringAfter(htmlTag);
			if ( !CommUtils.isBlank(htmlBeg) ) {
				//findContent = findContent.subStringAfter(htmlBeg);
				content = content.subStringAfter(htmlBeg);
			}
			if (!CommUtils.isBlank(htmlEnd) ) {
				content = content.subStringBefore(htmlEnd);
			}
			return content;
		}
		public String getLabel(){
			String label = '';
			if (!CommUtils.isBlank(htmlName))
				label = htmlName;
			else if (oneRowFlag)
				label = htmlTag;
			return label + value;
		}
	}
	class DetailIdx{
		String template;
		String index;
		String value;
		String compareValue;
		boolean specialFlag;
		String detailType;
		String dateTimeFormat = '([a-zA-Z]+) [\\d]{2} [\\d]{4} [\\d]{2}:[\\d]{2}';
		public DetailIdx(Dom.xmlnode node){
			specialFlag = false;
			if (node != null){
				index = node.getText();
				detailType = node.getAttribute('type',null);
				template = node.getAttribute('template',null);
				
				if (!CommUtils.isBlank(detailType) && CommUtils.isBlank(template)) template = '$_$';
				
				if ( template == 'SUM' || template == 'MAX' || template == 'MIN') specialFlag = true;
			}
		}
		public void compareValue(String tValue){
			if (template == 'SUM') {
				if (compareValue == null) compareValue = tValue;
				else {
					if (compareValue.isNumeric()) {
						compareValue = CommUtils.nullToblank(CommUtils.nullToZero(compareValue) + CommUtils.nullToZero(tValue));
					} else {
						compareValue = tValue;
					}
					
				}
			} else if (template == 'MAX') {
				if (compareValue == null) compareValue = tValue;
				else if(compareValue < tValue) compareValue = tValue;
			} else if (template == 'MIN') {
				if (compareValue == null) compareValue = tValue;
				else if(compareValue > tValue) compareValue = tValue;
			}
		}
		public String getValue(String inputValue){
			if (detailType == 'datetime') {
				inputValue = CommUtils.stringEnToDateTime(inputValue).format('yyyy年MM月dd日 HH:mm:ss');
			}
			return template.replace('$_$',inputValue);
		}
	}
	class TableInfo{
		TrInfo titleTr;
		List<TrInfo> tbody;
		List<TrInfo> thead;
		List<TrInfo> tfoot;
		List<TableInfo> childrenTbl;
		String textContent;
		Set<String> allSet;
		String format = '<tr\\s[\\s\\S]*?(</tr>)';
		public TableInfo(String htmlContent){
			tbody = new List<TrInfo>();
			allSet = new Set<String>();
			textContent = htmlContent;
			//system.debug(logginglevel.info,'textContent:::' + textContent);
			//beforStr + afterStr
			SetTrInfo(htmlContent);
		}
		private void SetTrInfo(String content){
			
			List<TableInfo> tableLst = new List<TableInfo>();
			for (String splitString : content.split(format)) {
				content = content.replace(splitString,'');
			}
			String beforeTrString = '<tr';
			List<String> contentLst = content.split(beforeTrString);
			//system.debug(logginglevel.info,'contentLst:::' + contentLst);
			for (integer i = 1 ; i < contentLst.size() ; i++ ) {
				String row = beforeTrString + contentLst[i];
				//system.debug(logginglevel.info,'row:::' + row);
				TrInfo trInfo = new TrInfo(row);
				allSet.addAll(trInfo.romMap.keySet());
				if ( i == 1) {
					titleTr = trInfo;
					continue;
				}
				tbody.add(trInfo);
			}
		}
		private string getText(){
			string contentStr = '';
			//system.debug(logginglevel.info,'childrenTbl:::' + childrenTbl);
			if (!childrenTbl.isEmpty()) {
				for(TableInfo tb : childrenTbl){
					contentStr += tb.textContent;
				}
			}
			//system.debug(logginglevel.info,'textContent1123:::' + textContent);
			return textContent + contentStr;
		}
	}
	class TrInfo{
		Map<String,String> attributeMap;
		List<TdInfo> children;
		String format = '<td\\s[\\s\\S]*?(</td>)';
		String text;
		Map<String,Integer> romMap;
		public TrInfo(String row){
			romMap = new Map<String,Integer>();
			
			children = new List<TdInfo>();
			for (String splitString : row.split(format)) {
				row = row.replace(splitString,'');
			}
			String beforeTrString = '<td';
			List<String> contentLst = row.split(beforeTrString);
			for (integer i = 1 ; i < contentLst.size() ; i++ ) {
				String col = beforeTrString + contentLst[i];
				TdInfo tdInfo = new TdInfo(col);
				romMap.put(tdInfo.text,children.size());
				children.add(tdInfo);
			}
		}
		public TdInfo getTdInfoByIdx(Integer idx){
			//system.debug(logginglevel.info,'children:::' + children);
			if(children.size() <= idx) return null;
			return children.get(idx); 
		}
		public String getTextByIdx(Integer idx){
			if(children.size() <= idx) return '';
			return children.get(idx).text;
		}
		public Integer getIdx(String content){
			for(String key : romMap.keySet()){
				if ( key.contains(content) ) {
					return romMap.get(key);
				}
			}
			return null;
		}
	}
	class TdInfo{
		Map<String,String> attributeMap;
		String text;
		String html;
		String value;
		Set<String> keySet;
		public TdInfo(String col){
			keySet = new Set<String>();
			//system.debug(logginglevel.info,'col:::' + col);
			String content = col.stripHtmlTags();
			//col.subString(col.indexOf('>') + 1,col.lastIndexOf('<'));
			html = col;
			//if (content.contains('<')) {
				
			//} else {
				value = content;
				text = content;
				keySet.add(text);
			//}
		}
	}
}