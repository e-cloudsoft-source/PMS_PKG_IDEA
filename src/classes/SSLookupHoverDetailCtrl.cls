public with sharing class SSLookupHoverDetailCtrl {

	// =========================
	// 			予約名 | Name
	//  予約ステータス | ReservedStatus__c
	// 		予約受付日 | ReservedDate__c
	// 			到着日 | EntryTime__c
	// 		  到着時刻 | Field4Cal__c
	// 			出発日 | Departure__c
	// 		  出発時刻 | Field3__c
	// 		  予約人数 | StayPersons__c
	// 	  予約チャネル | Field2__c
	// 		  広告媒体 | Field308__c
	// 			プラン | Field310__c
	// 			  部屋 | Rroom__c
	// 		  特記事項 | Comment3__c
	// 			お客様 | Relcontact__c
	// 		お客様電話 | Relcontact__r.Phone
	// 	  お客様メール | Relcontact__r.Email
	// =========================
	/*
	@RemoteAction
	public static String getLeadInfo(String leadId) {
		if(String.escapeSingleQuotes(leadId) != ''){
		    Lead__c leadDetail = [	select Id, Name, ReservedStatus__c, ReservedDate__c, EntryTime__c, Field4Cal__c, Departure__c,
		    						Field3__c, StayPersons__c, Field2__c, Field308__c, Field310__c, Rroom__c, Comment3__c,
		    						Relcontact__c, Field310__r.Name, Rroom__r.Name, Relcontact__r.Name,
		    						Relcontact__r.Phone, Relcontact__r.Email from Lead__c where Id = :leadId];

			Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('LookupHoverDetailInfo', '');
    		Dom.XmlNode obNmNode = targetNode.getChildElement('FIELDS', null);
    		Dom.XmlNode colNumNode = targetNode.getChildElement('COLNUMS', null);
    		String strFields = (obNmNode == null ? '' : CommUtils.nullToBlank(obNmNode.getText()).deleteWhitespace());
    		String colNumFields = (colNumNode == null ? '' : CommUtils.nullToBlank(colNumNode.getText()).deleteWhitespace());
    		List<String> fieldsSplits = strFields.split(',');

    		String st = '';
			String fv = '';
    		st += '<div class="bPageBlock brandSecondaryBrd secondaryPalette" style="box-shadow: 0 0 3px #000;"><div class="pbHeader brandSecondaryBrd"><table border="0" cellpadding="0" cellspacing="0"><tbody><tr><td class="pbTitle"><h2 class="mainTitle">ご予約</h2></td></tr></tbody></table></div><div class="pbBody"><table class="detailList" border="0" cellpadding="0" cellspacing="0"><tbody>';
    		for (String fieldKey : fieldsSplits) {
    			Datetime rDate = leadDetail.ReservedDate__c;
				String reservedDate = rDate.format('yyyy/MM/dd HH:mm');
    			Datetime eDate = leadDetail.EntryTime__c;
				String entryTime = eDate.format('yyyy/MM/dd HH:mm');
    			Datetime dDate = leadDetail.Departure__c;
				String departure = dDate.format('yyyy/MM/dd HH:mm');
    			if (fieldKey == 'Name') {
    			    fv += '<tr><td class="labelCol">予約名</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Name) + '</td></tr>';
    			} if (fieldKey == 'ReservedStatus__c') {
    			    fv += '<tr><td class="labelCol">予約ステータス</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.ReservedStatus__c) + '</td></tr>';
    			} if (fieldKey == 'ReservedDate__c') {
    			    fv += '<tr><td class="labelCol">予約受付日</td><td class="dataCol">' + CommUtils.nullToBlank(reservedDate) + '</td></tr>';
    			} if (fieldKey == 'EntryTime__c') {
    			    fv += '<tr><td class="labelCol">到着日</td><td class="dataCol">' + CommUtils.nullToBlank(entryTime) + '</td></tr>';
    			} if (fieldKey == 'Field4Cal__c') {
    			    fv += '<tr><td class="labelCol">到着時刻</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Field4Cal__c) + '</td></tr>';
    			} if (fieldKey == 'Departure__c') {
    			    fv += '<tr><td class="labelCol">出発日</td><td class="dataCol">' + CommUtils.nullToBlank(departure) + '</td></tr>';
    			} if (fieldKey == 'Field3__c') {
    			    fv += '<tr><td class="labelCol">出発時刻</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Field3__c) + '</td></tr>';
    			} if (fieldKey == 'StayPersons__c') {
    			    fv += '<tr><td class="labelCol">予約人数</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.StayPersons__c) + '</td></tr>';
    			} if (fieldKey == 'Field2__c') {
    			    fv += '<tr><td class="labelCol">予約チャネル</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Field2__c) + '</td></tr>';
    			} if (fieldKey == 'Field308__c') {
    			    fv += '<tr><td class="labelCol">広告媒体</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Field308__c) + '</td></tr>';
    			} if (fieldKey == 'Field310__c') {
    			    fv += '<tr><td class="labelCol">プラン</td><td class="dataCol"><a href="/'+ leadDetail.Field310__c +'">' + CommUtils.nullToBlank(leadDetail.Field310__r.Name) + '</a></td></tr>';
    			} if (fieldKey == 'Rroom__c') {
    			    fv += '<tr><td class="labelCol">部屋</td><td class="dataCol"><a href="/'+ leadDetail.Rroom__c +'">' + CommUtils.nullToBlank(leadDetail.Rroom__r.Name) + '</a></td></tr>';
    			} if (fieldKey == 'Comment3__c') {
    			    fv += '<tr><td class="labelCol">特記事項</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Comment3__c) + '</td></tr>';
    			} if (fieldKey == 'Relcontact__c') {
    			    fv += '<tr><td class="labelCol">お客様</td><td class="dataCol"><a href="/'+ leadDetail.Relcontact__c +'">' + CommUtils.nullToBlank(leadDetail.Relcontact__r.Name) + '</a></td></tr>';
    			} if (fieldKey == 'Relcontact__r.Phone') {
    			    fv += '<tr><td class="labelCol">電話</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Relcontact__r.Phone) + '</td></tr>';
    			} if (fieldKey == 'Relcontact__r.Email') {
    			    fv += '<tr><td class="labelCol">メール</td><td class="dataCol">' + CommUtils.nullToBlank(leadDetail.Relcontact__r.Email) + '</td></tr>';
    			}
    		}
			if (colNumFields == '2') {
                String colFlg = '</tr><tr>';
                Integer counter = 0;  
                while(fv.indexOf(colFlg) != -1){
                    counter++;
                    if (math.mod(counter,2) == 0) {
                        fv = fv.replaceFirst('</tr><tr>','</tr><tr >');
                    }else{
                        fv = fv.replaceFirst('</tr><tr>','');
                    }
                    // fv=fv.substring(fv.indexOf(colFlg)+colFlg.length());
                }
            }
            st += fv;
            // st += '</tbody></table></div></div>';
            System.debug(LoggingLevel.INFO, ':::' + st);
			return st;
		}else {
			return '';
		}
	}
	*/
    @RemoteAction
    public static String getTaskInfo(String userId, String taskDt) {
        if(!CommUtils.isBlank(userId)){
            //taskDt = taskDt.replace('/', '-');
            //Date dt = Date.valueOf(taskDt);
            Date dt = CommUtils.stringToDate(taskDt);
            // 2015/07/30 Todoは表示対象になる
            //List<Task> taskDetail = [select Id, OwnerId, Subject, ActivityDate, Description, Status from Task where OwnerId =:userId and ActivityDate =:dt];
            // 2018/07/17 終了日拡張するため、拡張項目終了日を追加対応 BEGIN
            //List<Event> eventDetail = [select Id, OwnerId, Subject, ActivityDate, Description, StartDateTime, EndDateTime, IsAllDayEvent from Event where OwnerId =:userId and ActivityDate =:dt];
			List<Event> eventDetail = [select Id, OwnerId, Subject, ActivityDate, Description, StartDateTime, EndDateTime, EndDateTime__c, IsAllDayEvent 
                                        // 2019/06/30 jinya bug fix JINYABUG-1873 by zy BEGIN
                                        ,EventIndex__c
                                        // 2019/06/30 jinya bug fix JINYABUG-1873 by zy END
                                        from Event where OwnerId =:userId and ActivityDate =:dt
										// 2018/07/24 定期のタスク、親定期タスク非表示JINYABUG-745 by BEGIN
                                         and IsRecurrence = false	
                                         // 2018/07/24 定期のタスク、親定期タスク非表示JINYABUG-745 by END
										];
			// 2018/07/17 終了日拡張するため、拡張項目終了日を追加対応 END
            String st = '';
            String fv = '';
            //行動
            st += '<div class="bPageBlock brandSecondaryBrd secondaryPalette" style="box-shadow: 0 0 3px #000;"><div class="pbHeader brandSecondaryBrd"><table border="0" cellpadding="0" cellspacing="0"><tbody><tr><td class="pbTitle"><h2 class="mainTitle">'+ Label.CONST_035_0135 +'</h2></td></tr></tbody></table></div><div class="pbBody"><table class="detailList" border="0" cellpadding="0" cellspacing="0"><tbody>';

            for (Event fieldKey : eventDetail) {
                    
	            Datetime sDate = fieldKey.StartDateTime;
				//String startDate = fieldkey.IsAllDayEvent ? sDate.format('yyyy/MM/dd') : sDate.format('yyyy/MM/dd HH:mm');
				// 2016/11/25 TIMEZON fix BEGIN by zh
				//String startDate = fieldkey.IsAllDayEvent ? sDate.format(CommBaseCtrl.getDateFormat()) : sDate.format(CommBaseCtrl.getDateTimeFormat());
				String startDate = fieldkey.IsAllDayEvent ? sDate.format(CommBaseCtrl.getDateFormat()) : sDate.format();
				// 2016/11/25 TIMEZON fix END by zh
	            Datetime eDate = fieldKey.EndDateTime;
	            // 2018/07/17 終了日拡張するため、拡張項目終了日を追加対応 BEGIN
	            // 終日行動の場合、表示メッセージ不正
	            // 所以終日行動读取值用原来的enddatetime
                // 2019/06/30 jinya bug fix JINYABUG-1873 by zy BEGIN
	            if (!fieldkey.IsAllDayEvent && fieldKey.EndDateTime__c != null && fieldkey.EventIndex__c == null) eDate = fieldKey.EndDateTime__c;
	            // 2019/06/30 jinya bug fix JINYABUG-1873 by zy END
                // 2018/07/17 終了日拡張するため、拡張項目終了日を追加対応 END
				//String endDate =  fieldkey.IsAllDayEvent ? eDate.format('yyyy/MM/dd') : eDate.format('yyyy/MM/dd HH:mm');
				// 2016/11/25 TIMEZON fix BEGIN by zh
				//String endDate =  fieldkey.IsAllDayEvent ? eDate.format(CommBaseCtrl.getDateFormat()) : eDate.format(CommBaseCtrl.getDateTimeFormat());
				String endDate =  fieldkey.IsAllDayEvent ? eDate.format(CommBaseCtrl.getDateFormat()) : eDate.format();
				// 2016/11/25 TIMEZON fix END by zh
				//件名
				//開始日時
                fv += '<tr><td class="labelCol" rowspan="2">'+ Label.CONST_035_0136 +'</td><td class="dataCol" rowspan="2"><a href="/'+ fieldKey.Id +'">' + CommUtils.nullToBlank(fieldKey.Subject) + '</a></td><td class="labelCol">'+ Label.CONST_035_0137 +'</td><td class="dataCol">' + CommUtils.nullToBlank(startDate) + '</td></tr>';
                //終了日時
                fv += '<tr><td class="labelCol">'+ Label.CONST_035_0138 +'</td><td class="dataCol">' + CommUtils.nullToBlank(endDate) + '</td></tr>';
            }
            st += fv;
            return st;
        }else {
            return '';
        }
    }
    @RemoteAction
    // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw BEGIN
    public static String getLeadsInfo(String leadIds, String spcd){
    //public static String getLeadsInfo(String leadIds) {
    // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw END
    	// 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw BEGIN
    	String result = '';
		FieldStruct fieldStruct = loadDocument(spcd);
		if(!CommUtils.isBlank(leadIds)){
        /*
        !fieldStruct.allFieldSet.isEmpty()
        	List<String> leadIdLst = CommUtils.nullToBlank(leadIds).split(',');
			Integer leadCancelFlg = CommConst.LEAD_ST_CANCEL_FLG;
            // 2015/07/30 Todoは表示対象になる
            //List<Task> taskDetail = [select Id, OwnerId, Subject, ActivityDate, Description, Status from Task where OwnerId =:userId and ActivityDate =:dt];
            List<Lead__c> leadDetails = [	select Id, Name, ReservedStatus__c, ReservedDate__c, EntryTime__c, Field4Cal__c, Departure__c,
		    						Field3__c, StayPersons__c, Field2__c, Field308__c, Field310__c, Rroom__c, Comment3__c,
		    						Relcontact__c, Field310__r.Name, Rroom__r.Name, Relcontact__r.Name,
		    						Relcontact__r.Phone, Relcontact__r.Email from Lead__c where  id = :leadIdLst];
			*/
			List<String> leadIdLst = CommUtils.nullToBlank(leadIds).split(',');
			String sql = 'SELECT ' + fieldStruct.getSql() + ' FROM lead__c WHERE id = :leadIdLst';
			List<Lead__c> leadDetails = Database.query(sql);
			// 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw END
//System.debug(LoggingLevel.INFO, 'leadDetails:::' + leadDetails);
            String st = '';
            String fv = '';
            //ご予約
            st += '<div class="bPageBlock brandSecondaryBrd secondaryPalette" style="box-shadow: 0 0 3px #000;"><div class=" brandSecondaryBrd"><table border="0" cellpadding="0" cellspacing="0"><tbody><tr><td class="pbTitle"><h2 class="mainTitle">'+ Label.CONST_035_0139 +'</h2></td></tr></tbody></table></div><div class="pbBody"><table class="detailList" border="0" cellpadding="0" cellspacing="0"><tbody>';

            for (Lead__c fieldKey : leadDetails) {
                // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw BEGIN
                /*
                // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw END
	            Datetime sDate = fieldKey.EntryTime__c;
				//String startDate = sDate.format('yyyy/MM/dd');
				String startDate = sDate.format(CommBaseCtrl.getDateFormat());
	            Datetime eDate = fieldKey.Departure__c;
				//String endDate =  eDate.format('yyyy/MM/dd');
				String endDate =  eDate.format(CommBaseCtrl.getDateFormat());
				//予約
				//お客様
                fv += '<tr><td class="labelCol" >'+ Label.CONST_035_0140 +'</td><td class="dataCol" ><a href="/'+ fieldKey.Id +'" target="_blank">' + CommUtils.nullToBlank(fieldKey.Name) + '</a></td><td class="labelCol">'+ Label.CONST_035_0141 +'</td><td class="dataCol"><a href="/'+ fieldKey.Relcontact__c +'">' + CommUtils.nullToBlank(fieldKey.Relcontact__r.Name) + '</a></td></tr>';
                // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw BEGIN
                */
                fv += '<tr>';
				for(String field : fieldStruct.xmlOrderLst){
					String fieldLab = fieldStruct.fieldsMap.get(field);
					String fieldVal = '';
					fieldVal = getValue(fieldKey, field);
					String fieldId = getValue(fieldKey, fieldStruct.linksMap.get(field));
					String item = generateItem(fieldVal, fieldLab, fieldId);
					fv += item;
				}
				fv += '</tr>';
				// 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw END
            }
            st += fv;
            st += '</tbody></table></div></div>';
///System.debug(LoggingLevel.INFO, ':::' + st);
            return st;
        }else {
            return '';
        }
    }
    // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw BEGIN
    // 解析XML
    private static FieldStruct loadDocument(String spcd){
    	FieldStruct fs = new FieldStruct();
    	try{
	    	Dom.XmlNode targetNode = CommXmlUtils.parseXmlDoc('StaffScheduleConfigXml', spcd);
	    	if(targetNode != null){
	    		Dom.XmlNode node = targetNode.getChildElement('SUMMARYEXTFIELD', null);
	    		if(node != null){
	    			String field = '';
	    			String link = '';
	    			Dom.XmlNode fieldNode = node.getChildElement('FIELDS', null);
	    			if(fieldNode != null) field = CommUtils.nullToBlank(fieldNode.getText()).toLowerCase().trim();
	    			Dom.XmlNode linkNode = node.getChildElement('LINKFIELD', null);
	    			if(linkNode != null) link = CommUtils.nullToBlank(linkNode.getText()).toLowerCase().trim();
	    			parse(field, fs, 'FIELDS');
	    			parse(link, fs, 'LINKFIELD');
	    			
	    		}
	    	}
    	}catch(Exception e){
    		return new FieldStruct();
    	}
    	return fs;
    }
    // 解析xml字符串信息
    private static void parse(String text, FieldStruct fs, String tpy){
    	if(CommUtils.isBlank(text) || fs == null) return;
		for(String items : text.split(',')){
			String[] item = items.split(':');
			if(item.size() > 0){
				item[0] = item[0].trim(); // api
				if(tpy == 'FIELDS'){
					fs.add(item[0], item.size() > 1 ? item[1] : null);
				}else if(tpy == 'LINKFIELD'){
					fs.addLink(item[0], item.size() > 1 ? item[1] : null);
				}
			}
		}
    }
    // 存储所有的字段信息
    private class FieldStruct {
    	public Map<String, String> fieldsMap; // Sql 对应名字
    	public List<String> xmlOrderLst; // 遍历
    	private Map<String, Schema.DescribeFieldResult> defValMaps; // 所有字段
    	private Boolean isDefault = true; // 默认
    	public Set<String> exitSet; // sql
    	public Map<String, String> linksMap; // link 对应
    	
    	public FieldStruct(){
    		xmlOrderLst = new List<String>{'name', 'relcontact__r.name'}; // 遍历顺序
    		fieldsMap = new Map<String, String>{'name'=>Label.CONST_035_0140, 'relcontact__r.name'=>Label.CONST_035_0141}; // 别名
    		defValMaps = CommSqlUtils.getAllFieldLst(Lead__c.sobjectType, false, true); // 获取所有字段
    		linksMap = new Map<String, String>{'name'=>'id', 'relcontact__r.name'=>'relcontact__c'}; // link对应
    		exitSet = new Set<String>{'name', 'id', 'relcontact__c', 'relcontact__r.name'}; // sql
    	}
    	// 添加字段相关信息
    	public void add(String fieldName, String fieldLable){
    		if(isDefault){
    			xmlOrderLst.clear();
    			fieldsMap.clear();
    			isDefault = false;
    			linksMap.clear();
    			exitSet.clear();
    		}
    		fieldName = refTo2f(fieldName);
    		Schema.DescribeFieldResult dr = isExistForSobject(fieldName);
    		if(exitSet.contains(fieldName) || dr == null) return;
    		xmlOrderLst.add(fieldName); // 需要遍历的list
    		fieldsMap.put(fieldName, CommUtils.isBlank(fieldLable) ? dr.getLabel() : fieldLable);
    		exitSet.add(fieldName); // sql
    		
    	}
    	
    	public void addLink(String fieldApi, String linkApi){
    		if(CommUtils.isBlank(CommUtils.nullToBlank(fieldApi)) || CommUtils.isBlank(CommUtils.nullToBlank(linkApi))) return;
    		fieldApi = refTo2f(fieldApi);
    		if(!exitSet.contains(fieldApi)) return;
    		linkApi = refTo2f(linkApi);
    		// 是否为lead的字段
    		Schema.DescribeFieldResult dr = isExistForSobject(linkApi);
    		if(dr == null || (dr.getType() != DisplayType.Reference && dr.getType() != DisplayType.ID)) return;
    		if(!exitSet.contains(linkApi)) exitSet.add(linkApi);
    		linksMap.put(fieldApi, linkApi);
    	}
    	private String fieldToNormal(String fieldName, Boolean isFront){
    		return fieldName.indexOf('__r.') != -1 ? isFront ? fieldName.split('__r.')[0] + '__c' : fieldName.split('__r.')[1] : fieldName;
    	}
    	
    	private Boolean isRef(String fieldName){
    		return fieldName.indexOf('__r.') != -1;
    	}
    	
    	private Schema.DescribeFieldResult isExistForSobject(String fieldName){
    		Schema.DescribeFieldResult dr = defValMaps.get(fieldToNormal(fieldName, true));
    		if(dr != null && isRef(fieldName)){
    			List<SobjectType> sts = dr.getReferenceTo();
    			if(!sts.isEmpty()){
    				SobjectType firstST = sts.get(0);
    				Map<String, Schema.DescribeFieldResult> refAllFieldMap = CommSqlUtils.getAllFieldLst(firstST, false, true);
    				if(!refAllFieldMap.containsKey(fieldToNormal(fieldName, false))) return null;
    				return refAllFieldMap.get(fieldToNormal(fieldName, false));
    			}
    		}
    		return dr;
    	}
    	private String refTo2f(String fieldName){
    		String[] item = fieldName.split('__r.');
    		if(item.size() > 1) return item[0] + '__r.' + item[1];
    		return fieldName;
    	}
    	
    	public String getSql(){
    		return String.join(new List<String>(exitSet), ',');
    	}
    }
    // 生成item
    private static String generateItem(String fieldValue, String fieldLabel, String fieldId){
    	String result = '<td class="labelCol">';
    	result += fieldLabel;
    	result += '</td><td class="dataCol">';
    	if(!CommUtils.isBlank(fieldId)){
    		result += '<a href="/';
    		result += fieldId;
    		result += '" target="_blank">';
    		result += fieldValue;
    		result += '</a>';
    	}else{
    		result += fieldValue;
    	}
    	result += '</td>';
		return result;    	
    }
    
    // 两层或者一层的获取值
    private static String getValue(Sobject sobj, String fieldName){
    	try{
    		String[] fieldArr = fieldName.split('__r.');
	    	if(fieldArr.size() == 2){
	    		return CommUtils.nullToBlank(sobj.getSobject(fieldArr[0] + '__r').get(fieldArr[1]));
	    	}else if(fieldArr.size() == 1){
	    		return CommUtils.nullToBlank(sobj.get(fieldArr[0]));
	    	}else{
	    		return '';
	    	}
    	}catch(Exception e){
    		return '';
    	}
    }
    // 2018/10/26 マルチタスクとシフトの合計欄の表示内容はカスタマイズできるように改善 by cxw END
}