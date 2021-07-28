@RestResource(urlMapping='/DragAndDrop/v1/*')
global with sharing class DragAndDropRESTAPI
{
    @HttpPost
    global static void attachDoc(){
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;

        String fName = req.params.get('FileName');
        String parId = req.params.get('parId');
        String lineNum = req.params.get('lineNum');
        Boolean isDel = req.params.get('del') == 'false' ? false : true;
        Blob postContent = req.requestBody; 

		Savepoint sp = Database.setSavepoint();
		try {
			// 既存ファイルをクリアする
			if(isDel) delete [select id from Attachment where ParentId = :parId for update];
				
	        Attachment a = new Attachment (ParentId = parId,
	                                       Body = postContent,
	                                       Name = fName);
	
			insert a;
	       
			String[] rsLst = new string[3];
			rsLst[0] = lineNum;
			rsLst[1] = a.Id;
			rsLst[2] = a.Name;
			
			res.addHeader('Content-Type', 'application/json');
			res.responseBody = Blob.valueOf(JSON.serialize(rsLst));
		} catch (Exception e) {
			DataBase.rollback(sp);
			throw e;
		}
   }
   
   public String hostName{get{
   		return CommUtils.getHostNameUrl();
   }}
}