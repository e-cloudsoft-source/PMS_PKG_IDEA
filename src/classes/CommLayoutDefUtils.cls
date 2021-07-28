public with sharing class CommLayoutDefUtils {
	/*
 	//セクション
 	public List<Section> sectionList{get; private set;}
 	public String outApiName{get; private set;}
 	private static final String nameSpace = CommConst.APPOTION_NAMESPACE;
 	//根据object名和recordTypeId读取layout
	public String getLayoutFields(String sobjectNm, String recordTypeId, String pInstanceUrl) {
        //namespace取得 
        String instanceUrl = pInstanceUrl; 
        if (CommUtils.isBlank(instanceUrl)) {
       		instanceUrl = URL.getSalesforceBaseUrl().getHost();
		    String sfBaseProtocol = URL.getSalesforceBaseUrl().getProtocol();
		    //remove namespace
		    integer firstDotPos = instanceUrl.indexOf('.');
		    instanceUrl = instanceUrl.substring(firstDotPos+1);
		    //replace visual.force with salesforce
		    instanceUrl = instanceUrl.replace('visual.force', 'salesforce');
		    instanceUrl = sfBaseProtocol+'://'+instanceUrl;
        }      
		String endpoint = instanceUrl+'/services/data/v35.0/sobjects/'+sobjectNm+'/describe/layouts/';
		if (!CommUtils.isBlank(recordTypeId)) {
			endpoint += recordTypeId;
		}
//system.debug(logginglevel.info, 'endpoint:::' + endpoint); 
		HttpRequest	req	= new HttpRequest();
		req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionID() );
		req.setHeader( 'Content-Type', 'application/json' );
		req.setEndpoint( endpoint );
		req.setMethod( 'GET' );
		HttpResponse res = new Http().send( req );
		String	respBody = res.getBody();
		
		List<Object> editLayoutSections;
		Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(respBody);
		//recordTypeId为空、读取layout、layout→editLayoutSections
		if (CommUtils.isBlank(recordTypeId)) {
			List<Object> allLayouts = (List<Object>)root.get( 'layouts' );
			if (!allLayouts.isEmpty()) {
				Map<String, Object> currentlayout = (Map<String, Object>)(allLayouts[0]);
				editLayoutSections = (List<Object>)currentlayout.get( 'editLayoutSections' );
			}
		//recordTypeId不为空、读取layout→editLayoutSections
		} else {
			editLayoutSections = (List<Object>)root.get( 'editLayoutSections' );
		}
		sectionList = new List<Section>();
			for ( Object editLayout : editLayoutSections ){
				Map<String, Object> editLayoutMap = (Map<String, Object>)editLayout;
				sectionList.add(new Section(editLayoutMap));
			}
//System.debug(loggingLevel.info, 'editLayoutSections='+editLayoutSections);
		outApiName = '';
        for (Section sec : sectionList) {
        	outApiName += sec.fieldsToStr();
        }
        outApiName = outApiName.removeEnd(',');
		return outApiName;
	}
	
	public class Section{
    	public Section(map<string, object> editLayoutMap){
    		columns = CommUtils.nullToBlank(editLayoutMap.get('columns'));
    		headingInvisible = CommUtils.nullToBlank(editLayoutMap.get('useHeading'));
    		sectionHeading = CommUtils.nullToBlank(editLayoutMap.get('heading'));
			items = new list<Item>();
			for ( String key : editLayoutMap.keySet() ){
				if ( key == 'layoutRows' ){
					list<Object> layoutRowList = (List<Object>)editLayoutMap.get( 'layoutRows' );
					for ( Object layoutRow : layoutRowList ){
						Map<String, Object>	layoutRowMap = (Map<String, Object>)layoutRow;
						list<Object> layoutItemsList = (List<Object>)( (Map<String, Object>)layoutRowMap ).get( 'layoutItems' );
						for ( Object layoutItems : layoutItemsList ){
							Map<String, Object> itemsMap = (Map<String, Object>)layoutItems;
							items.add(new Item(itemsMap));
						}
					}
				}
			}
			//根据layout定义的字段顺序、taborder作为key、item为value
			Map<Decimal, Item> locSortMap = new Map<Decimal, Item>();
			for (Item item : items) {
				locSortMap.put(CommUtils.nullToIntZero(item.itemOrder),item);
			}
			List<Decimal> sortKeyLst = new List<Decimal>();
			//把taborder放到list里
			sortKeyLst.addAll(locSortMap.keySet());
			//将taborder排序
			sortKeyLst.sort();
			items.clear();
			//根据taborder重新排序的字段重新放到list里
			for (Decimal key : sortKeyLst) {
				Item orgItem = locSortMap.get(key);
				items.add(orgItem);
			}
    	}	
    	public String headingInvisible{get;set;}
    	public String sectionHeading{get;set;}
    	public String layoutRows{get;set;}
    	public String columns{get;set;}
    	public List<Item> items{get; private set;}
    	public String fieldsToStr() {
    		String strFieldApis = '';
    		for (Item inf : items) {
				if(inf.itemApiNm == null) continue;
    			strFieldApis += inf.toItemXml() + ',';
    		}
    		return strFieldApis;
    	}
    }
    
    public class Item {
    	public Item(map<string, object> itemMap) {
    		//控制不可编辑字段的显示
    		itemEditFlg = true;
    		for ( String itemkey : itemMap.keySet() ){
    			itemEdit = CommUtils.nullToBlank(itemMap.get('editableForNew'));
    			itemLabel = CommUtils.nullToBlank(itemMap.get('label'));
    			required = Boolean.valueOf(CommUtils.nullToBlank(itemMap.get('required')));
    			if(itemEditFlg){
    				if(itemEdit == 'false') continue;
    			}
    			if ( itemkey == 'layoutComponents' ){
    				list<Object> layoutComponentList = (List<Object>)( (Map<String, Object>)itemMap ).get( 'layoutComponents' );
					for ( Object layoutComponent : layoutComponentList ){
						Map<String, Object> layoutComponentMap = (Map<String, Object>)layoutComponent;
						for ( String componentkey : layoutComponentMap.keySet() ){
							itemApiNm = CommUtils.nullToBlank(layoutComponentMap.get('value'));
							itemOrder = CommUtils.nullToZero(layoutComponentMap.get('tabOrder'));
						}
					}
    			}
    		}
			//system.debug(logginglevel.info,'itemLabel='+ itemLabel);	
			//system.debug(logginglevel.info,'itemOrder='+ itemOrder);	
			//system.debug(logginglevel.info,'itemRequired='+ itemRequired);				
    	}
    	public boolean required{get;set;}
    	public Decimal itemOrder{get;set;}
    	public String itemEdit{get;set;}
    	public String itemLabel{get;set;}
    	public String itemApiNm{get;set;}
    	public boolean itemEditFlg{get;set;}
    	public String toItemXml() {
    		if(!CommUtils.isBlank(nameSpace) && itemApiNm.startsWith(nameSpace)) itemApiNm = itemApiNm.substringAfter(nameSpace);
    		return itemApiNm;
    	}
    }*/
}