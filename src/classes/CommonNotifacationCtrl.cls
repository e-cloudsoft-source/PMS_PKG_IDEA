/*
* 項目変更により、自動アラート、通知機能の対応（予約と見積明細のみ連動検知機能を対応する）
*/
// 2019/08/15 20190725.01.予約変更履歴Chatter通知機能ですが、陣屋組織で設定したところ、システム管理者が変更した時しか通知されないようです。 by zy BEGIN
public without sharing class CommonNotifacationCtrl {
//public with sharing class CommonNotifacationCtrl {
// 2019/08/15 20190725.01.予約変更履歴Chatter通知機能ですが、陣屋組織で設定したところ、システム管理者が変更した時しか通知されないようです。 by zy END
    // 初期のメッセージのテンプレート
    private static String messsageTemp = '_label_ _action_ ';
    // オブジェクト変更検知対象チェック
    public static void updNoticationSobjectName(List<Sobject> news,List<Sobject> olds,String objectName,CommConst.TriggerMethod action){
        updNoticationSobjectName(news,olds,objectName,action,null);
    }
    // オブジェクト変更検知対象チェック
    public static void updNoticationSobjectName(List<Sobject> news,List<Sobject> olds,String objectName,CommConst.TriggerMethod action,String groupFieldName){
        // カスタム設定有効
        if (!Commconst.AUTO_ALARM_FLG) return;
        // XML設定チャターグループ集合
        Set<String> chatterGroupSet = new Set<String>();
        // XML設定検知対象集合
        set<String> chkFieldSet = new Set<String>();
        try {
            // XML読み込み
            Dom.XmlNode targetNode = CommXmlUtils.encodeParseXmlNoShopCodeNodeDoc('CommObjectListenConfig',new String[]{'<COONDITION>','</COONDITION>'});
            // 通知対象データの条件を設定
            String whereSQL = '';
            // カスタムのメッセージのテンプレート
            String customTemp = '';
            if(targetNode != null) {
                Dom.XmlNode contactNode = targetNode.getChildElement(objectName,null);
                if (contactNode != null) {
                    // 通知グループ設定
                    Dom.XmlNode groupNode = contactNode.getChildElement('CHATTERGROUP',null);
                    if (groupNode != null) chatterGroupSet.addAll(CommUtils.nullToBlank(groupNode.getText()).split(','));
                    // 通知内容カスタム設定
                    Dom.XmlNode notifyTemp = contactNode.getChildElement('NOTIFY',null);
                    if (notifyTemp != null) customTemp = CommUtils.nullTOBlank(notifyTemp.getText());
                    // チェック変更字段
                    Dom.XmlNode fieldNode = contactNode.getChildElement('LISTENFIELD',null);
                    if (fieldNode != null) chkFieldSet.addAll(CommUtils.nullToBlank(fieldNode.getText()).split(','));
                    // チェック条件
                    Dom.XmlNode whereNode = contactNode.getChildElement('LISTENFILTER',null);
                    if (whereNode != null) whereSQL = CommUtils.nullToBlank(whereNode.getText());
                }
                // 指定条件フィルター
                if (!CommUtils.isBlank(whereSQL)) {
                    // 更新Id作成
                    Set<Id> checkIds = new Set<Id>();
                    if (action == CommConst.TriggerMethod.IsUpdate || action == CommConst.TriggerMethod.IsInsert) {
                        for(integer i = 0;i < news.size();i++){
                            checkIds.add(news[i].id);
                        }
                    } else if (action == CommConst.TriggerMethod.IsDelete){
                        for(integer i = 0;i < olds.size();i++){
                            checkIds.add(olds[i].id);
                        }
                        whereSQL += ' all Rows';
                    }
                    // 指定オブジェクト条件フィルター
                    String querySQL = 'select id from ' + objectName + ' where  id = :checkIds and ' + whereSQL;
                    List<Sobject> results = Database.query(querySQL);
                    // 指定条件内、データなし
                    if (results.size() == 0) return;
                }
            } 
            // 未指定字段
            if (chkFieldSet.isEmpty()) return;
            // 指定オブジェクト取得
            SObjectType objToken = Schema.getGlobalDescribe().get(Commconst.APPOTION_NAMESPACE + objectName);
            // 該当オブジェクト字段取得
            Map<String, Schema.DescribeFieldResult> describeMap = CommSqlUtils.getAllFieldLst(objToken,true,true);
            // フィルターのデータの変更位置集合
            Set<Integer> changeInt = new Set<Integer>();
            integer maxSize = action == CommConst.TriggerMethod.IsDelete ? olds.size() : news.size();
            // 指定字段変更チェック
            for(integer i = 0;i < maxSize;i++){
                // 新規と削除の場合
                if (action == CommConst.TriggerMethod.IsInsert || action == CommConst.TriggerMethod.IsDelete){
                    changeInt.add(i);
                // 変更の場合
                }else {
                    Sobject newObj = news[i];
                    Sobject oldObj = olds[i];
                    // 検知対象チェック
                    for (String typeName : chkFieldSet) {
                        // 指定字段不存在
                        if (!describeMap.containsKey(typeName.toLowerCase())) continue;
                        Object oldVal = oldObj.get(typeName);
                        Object newVal = newObj.get(typeName);
                        if(oldVal != newVal) {
                            changeInt.add(i);
                            break;
                        }
                    }
                }
            }
            String acctionStr = '';

            if (action == CommConst.TriggerMethod.IsInsert) acctionStr = ' (新規)';
            else if (action == CommConst.TriggerMethod.IsUpdate) acctionStr = ' (変更)';
            else if (action == CommConst.TriggerMethod.IsDelete) acctionStr = ' (削除)';
            // テンプレート指定メッセージ作成
            Map<String,String> formatMessageField = new Map<String,String>();
            // カスタム設定通知テンプレート
            if (!CommUtils.isBlank(customTemp)) {
                String partternFormat = '\\$[a-zA-Z\\.\\_\\d]+';
                Pattern isnumbersPattern = Pattern.Compile(partternFormat);
                Matcher numberMatch = isnumbersPattern.matcher(customTemp);
                while(numberMatch.find()){
                    String changeAfterNm = numberMatch.group(0).replace('$','');
                    formatMessageField.put('$' + changeAfterNm + '$', changeAfterNm);
                }
            }
            // 変更内容集合
            List<String> results = new List<String>();
            String objectLabel = objToken.getDescribe().getLabel();
            Map<String,List<String>> groupRsultMap = new Map<String,List<String>>();
            // 指定字段変更後、通知内容作成
            for (integer i : changeInt) {
                // 変更後データ
                Sobject notify = action == CommConst.TriggerMethod.IsDelete ? olds[i] : news[i];
                // メッセージ内容
                String body = '';
                Sobject old = action == CommConst.TriggerMethod.IsInsert ? null : olds[i];
                // テンプレート内容作成
                if (!formatMessageField.isEmpty()) {
                    String messageTempStr = customTemp;
                    boolean hadNoBlankFlg = false;
                    for (String messageNm : formatMessageField.keySet()) {
                        String oldValue = '';String newValue = '';
                        String changeField = formatMessageField.get(messageNm);
                        if (changeField.indexOf('old') >= 0) {
                            
                            if (action != CommConst.TriggerMethod.IsInsert && old != null) {
                                String localName = changeField.replace('old.','');
                                Schema.DescribeFieldResult dr = describeMap.get(localName.toLowerCase());
                                if (dr != null) {
                                    Object value = old.get(localName);
                                    oldValue = CommUtils.nullToBlank(value);
                                }
                            }
                            messageTempStr = messageTempStr.replace(messageNm,oldValue);
                        } else {
                            if (action != CommConst.TriggerMethod.IsDelete && notify != null) {
                                String localName = changeField.replace('new.','');
                                Schema.DescribeFieldResult dr = describeMap.get(localName.toLowerCase());
                                if (dr != null) {
                                    Object value = notify.get(localName);
                                    newValue = CommUtils.nullToBlank(value);
                                }
                            }
                            messageTempStr = messageTempStr.replace(messageNm,newValue);
                        }
                        if (!hadNoBlankFlg) 
                            hadNoBlankFlg = !CommUtils.isBlank(oldValue) || !CommUtils.isBlank(newValue);
                        
                    }
                    if (hadNoBlankFlg) body += messageTempStr  + '\n';
                } else {
                    // TODO 类型区分
                    String bodyMsg = '';
                    List<String> deleteMsgs = new List<String>();
                    for (String typeName : chkFieldSet) {
                        Object value = notify.get(typeName);
                        String localTypeName = typeName.toLowerCase();
                        Schema.DescribeFieldResult dr = describeMap.get(localTypeName);
                        if (dr != null) {
                            String newValue = CommUtils.nullToBlank(value);
                            if (dr.getType() == DisplayType.Date) {
                                newValue = value != null ? ((Date)value).format() : '';
                            } else if (dr.getType() == DisplayType.Datetime) {
                                newValue = value != null ? ((Datetime)value).format() : '';
                            }
                            String typeLabel = dr.getLabel();
                            if (CommUtils.isBLank(bodyMsg)) {
                                if (action == CommConst.TriggerMethod.IsDelete) 
                                    bodyMsg = objectLabel + ':' + notify.get('name') + acctionStr + '\n';
                                else 
                                    bodyMsg = objectLabel + ':' + notify.get('name') + acctionStr + '\n' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + notify.get('id') + '\n';
                            }
                            String actionMsg = '';
                            if (action == CommConst.TriggerMethod.IsInsert) actionMsg = CommUtils.nullToBlank(value) ;
                            else if (action == CommConst.TriggerMethod.IsUpdate) {
                                Object oldVal = old.get(localTypeName);
                                String oldValue = CommUtils.nullToBlank(oldVal);
                                if (dr.getType() == DisplayType.Date) {
                                    oldValue = oldVal != null ? ((Date) oldVal).format() : '';
                                } else if (dr.getType() == DisplayType.Datetime) {
                                    oldValue = oldVal != null ? ((Datetime) oldVal).format() : '';
                                }
                                if (oldValue != newValue) {
                                    if (DisplayType.textarea == dr.getType() && dr.getLength() > 1000) {
                                        actionMsg = 'が' + ' に変更されました';
                                    } else {
                                        actionMsg = 'は ';
                                        if (!CommUtils.isBLank(oldValue))
                                            actionMsg += oldValue + ' から ';
                                        actionMsg += newValue + ' に変更されました';
                                    }
                                }
                            
                            } else if (action == CommConst.TriggerMethod.IsDelete) {
                                String oldValue = CommUtils.nullToBlank(old.get(localTypeName));
                                if (!CommUtils.isBlank(oldValue))
                                    deleteMsgs.add((typeLabel + ':' + oldValue));
                            }
                            if (!CommUtils.isBlank(actionMsg))
                                bodyMsg += messsageTemp.replace('_label_',typeLabel).replace('_action_',actionMsg) + '\n';
                        }
                    }
                    if (action == CommConst.TriggerMethod.IsDelete) {
                        if (deleteMsgs.size() > 0 ) bodyMsg += String.join(deleteMsgs, '\n'); 
                    }
                    if (!CommUtils.isBlank(bodyMsg)) body += bodyMsg;
                }
                if (!CommUtils.isBlank(groupFieldName)) {
                    String groupId = CommUtils.nullToBlank(notify.get(groupFieldName));
//system.debug(logginglevel.info,'groupId::::' + groupId);
                    if (!groupRsultMap.containsKey(groupId)) groupRsultMap.put(groupId,new List<String>());
                    if (!CommUtils.isBlank(body)) groupRsultMap.get(groupId).add(body);
                } else 
                if (!CommUtils.isBlank(body)) results.add(body);
            }
            // 通知内容処理
            if(!results.isEmpty()) {
                String result = String.join(results, '\n');
                callPostItem(chatterGroupSet,result);
            } else if (!groupRsultMap.isEmpty()) {
//system.debug(logginglevel.info,'groupRsultMap:::' + groupRsultMap);
                callPostItem(chatterGroupSet,groupRsultMap);
            }
        } catch(Exception e){
        }
    }
    private static void callPostItem(Set<String> chatterGroupSet,Map<String,List<String>> groupRsultMap){
        // 2019/09/15 Security Check BY zyz BEGIN
        List<String> chkFieldsLst = new List<String>{'feeditemid','commentbody'};
        Map<String,Schema.SObjectField> mm = Schema.SObjectType.FeedComment.fields.getMap();
        if (!CommSecurityUtils.isCanCreateable(chkFieldsLst, mm)) {
        	return ;
        }
        // 2019/09/15 Security Check BY zyz END
        Set<String> groupIdSet = groupRsultMap.keySet();
        List<String> groupLst = new List<String>(groupIdSet);
        if (!groupLst.isEmpty()) {
            String groupId = groupLst[0];
            // what id 前三位== account开始才可以设名字
            String leadPrex = Lead__c.sObjectType.getDescribe().getKeyPrefix();
            if (groupId.startsWith(leadPrex)){
                List<String> chatterGroupNamesLst = new LIst<String>();
                // 指定オブジェクト取得
                SObjectType objToken = Schema.getGlobalDescribe().get(Commconst.APPOTION_NAMESPACE + 'Lead__c');
                String objectLabel = objToken.getDescribe().getLabel();
                for (String chatterCode : chatterGroupSet) {
                    chatterGroupNamesLst.addAll(CommConst.GetChatterGroupNameByCode(chatterCode));
                }
                Map<String,CollaborationGroup> chatterGroups = new Map<String,CollaborationGroup>([select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false]);
                if (chatterGroups.isEmpty()) return;
                Map<String,FeedItem> chatterMap = new Map<String,FeedItem>();
                Map<String,String> postGroupMap = new Map<String,String>();
                for (CollaborationGroup cGroup : chatterGroups.values()) {
                    for (String gourpId : groupIdSet) postGroupMap.put( gourpId + '_' + cGroup.id, cGroup.id);
                }
                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                List<FeedItem> updItems = new List<FeedItem>();
                Set<String> leadSet = new Set<String>(); 
                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
                for (FeedItem item : [select id,ParentId,title from FeedItem where title = :groupIdSet and ParentId =:chatterGroups.keySet()]) {
                    String itemKey = item.title + '_' + item.ParentId;
                    // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                    updItems.add(item);
                    leadSet.add(item.title);
                    // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
                    chatterMap.put( itemKey, item);
                    postGroupMap.remove(itemKey);
                }
                if (!postGroupMap.isEmpty()) {
		            // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                    // Set<String> leadSet = new Set<String>(); 
		            // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
                    for (String itemKey : postGroupMap.keySet()) {
                        String chatGpId = postGroupMap.get(itemKey);
                        String leadId = itemKey.replace('_' + chatGpId, '');
                        leadSet.add(leadId);
                    }
		        // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                }
		        // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
                List<FeedItem> feedItems = new List<FeedItem>();
                Map<String,Lead__c> leadMap = new Map<String,Lead__c>([select id,name from Lead__c where id = :leadSet]);
                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
		        if (!postGroupMap.isEmpty()) {
		        // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
                    for (String leadId : groupIdSet) {
                        if (leadMap.containsKey(leadId)) {
                            Lead__c lead = leadMap.get(leadId);
			                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                            List<String> messages = groupRsultMap.get(lead.id);
                            // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
                            // 2020/03/31 項目変更通知修正 by zy BEGIN
			                for (String chatGpId : new Set<String>(postGroupMap.values())) {
                            // 2020/03/31 項目変更通知修正 by zy END
                                FeedItem post = new FeedItem();
                                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                                post.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + lead.id ;
                                post.Type = 'LinkPost';
                                String orgLeadLabel = objectLabel + ':' + lead.name ;
                                post.Body = processNotifyBody(orgLeadLabel,messages);
                                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
				                post.title = lead.id ;
                                post.ParentId = chatGpId;
                                feedItems.add(post);
                            }
                        }
                    }
                    if (!feedItems.isEmpty()) {
                        insert feedItems;
                        for (FeedItem item : feedItems) {
                            String itemKey = item.title + '_' + item.ParentId;
                            chatterMap.put( itemKey, item);
                        }
                    }
                }
                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
                if (!updItems.isEmpty()) {
                    for (FeedItem item : updItems) {
                        if (!leadMap.containsKey(item.title)) continue;
                        Lead__c lead = leadMap.get(item.title);
                        String orgLeadLabel = objectLabel + ':' + lead.name ;
                        List<String> messages = groupRsultMap.get(lead.id);
                        item.body = processNotifyBody(orgLeadLabel,messages);
                    }
                    update updItems;
                }
                // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
//system.debug(logginglevel.info,'chatterMap:::' + chatterMap);
                if (!chatterMap.isEmpty()) {
//system.debug(logginglevel.info,'groupRsultMap:::' + groupRsultMap);
                    List<FeedComment> insertFeedComments = new List<FeedComment>();
                    for (String leadId : groupRsultMap.keySet()) {
                        List<String> messages = groupRsultMap.get(leadId);
//system.debug(logginglevel.info,'messages:::' + messages);
                        for (String message  : messages) {
                            for (CollaborationGroup cGroup : chatterGroups.values()) {
                                String itemKey = leadId + '_' + cGroup.id;
                                if (chatterMap.containsKey(itemKey)) {
                                    FeedItem post = chatterMap.get(itemKey);
                                    FeedComment contentFC = new FeedComment();
                                    contentFC.CommentBody = message;    
                                    contentFC.FeedItemId = post.id; 
                                    insertFeedComments.add(contentFC);
                                } 
                            }
                        }
                        
                    }
                    if (!insertFeedComments.isEmpty()) insert insertFeedComments;
                }
            }
        }

    }
    private static void callPostItem(Set<String> chatterGroupSet,String message){
        List<String> chatterGroupNamesLst = new LIst<String>();
        for (String chatterCode : chatterGroupSet) {
            chatterGroupNamesLst.addAll(CommConst.GetChatterGroupNameByCode(chatterCode));
        }
        List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupNamesLst and isarchived = false];
        if (chatterGroups.isEmpty()) return;
        
        List<FeedItem> feedItems = new List<FeedItem>();
        for (CollaborationGroup cGroup : chatterGroups) {
            
            FeedItem post = new FeedItem();
            post.Type = 'TextPost';
            post.Body = message;
            post.title = 'GROUPCHATTER';
            post.ParentId = cGroup.Id;
            feedItems.add(post);
        }
        if (!feedItems.isEmpty()) insert feedItems;
    }
    // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy BEGIN
    private static String processNotifyBody(String title,List<String> messages){
        String msg = '';
        if (messages != null && !messages.isEmpty()){
            msg = messages[messages.size() - 1].replaceFirst('[a-zA-z]+://[^\\s]*\\n', '');
        }
        if (!msg.startsWith(title))
            msg = title + '\n' + msg;
        return msg;
    }
    // 2019/09/15 項目変更Chatter通知機能、ポストメッセージの変更 by zy END
}