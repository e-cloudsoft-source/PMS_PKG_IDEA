/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class DragAndDropRESTAPITest {
	
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
      Purchase__c item = TestCommon.createPurchase();
	  RestRequest req = new RestRequest(); // Build the REST Request for testing
	  String fileName = 'testfile' + CommUtils.getRandom(10) +'.txt';
	  req.addParameter('FileName', fileName);
	  req.addParameter('parId', item.Id);
	 // req.addParameter('parId', '88110');	  
	  req.addParameter('lineNum', '1');
	  req.addHeader('Content-Type', 'application/text'); // Add a Text Header as it is validated
	  req.requestURI = 'https://na11.salesforce.com/services/apexrest/DragAndDrop/v1/FileName/parId/lineNum';
	  req.httpMethod = 'POST';        // Perform a POST
	  req.requestBody = Blob.valueof('abc'); // Add JSON Message as a POST
	 	
	  RestResponse res = new RestResponse();
	  RestContext.request = req;
	  RestContext.response = res;
	  DragAndDropRESTAPI.attachDoc();
	  DragAndDropRESTAPI rl =new DragAndDropRESTAPI();
	  String s = rl.hostName;
	  String  ID = [select Id from Attachment where Name = :fileName And parentid = :item.Id].ID;
	  //System.debug(loggingLevel.INFO, 'RestContext.response:::' + RestContext.response);
	  String resBody = RestContext.response.responseBody.toString();
	  //System.debug(loggingLevel.INFO, 'RestContext.resBody:::' + resBody);
	  List<string> resLst = (List<string>)JSON.deserialize(resBody, List<String>.class);
	  //System.debug(loggingLevel.INFO, 'RestContext.resLst:::' + resLst);
      System.assertEquals('1',resLst[0]);     
  	  System.assertEquals(ID, resLst[1]);
  	  System.assertEquals(fileName, resLst[2]);
  	  
  	  
    }
    
    static testMethod void myUnitTest_Exception() {
        // TO DO: implement unit test
      Purchase__c item = TestCommon.createPurchase();
	  RestRequest req = new RestRequest(); // Build the REST Request for testing
	  String fileName = 'testfile' + CommUtils.getRandom(10) +'.txt';
	  req.addParameter('FileName', fileName);
	  req.addParameter('parId', item.Id+'1');
	 // req.addParameter('parId', '88110');	  
	  req.addParameter('lineNum', '1');
	  req.addHeader('Content-Type', 'application/text'); // Add a Text Header as it is validated
	  req.requestURI = 'https://na11.salesforce.com/services/apexrest/DragAndDrop/v1/FileName/parId/lineNum';
	  req.httpMethod = 'POST';        // Perform a POST
	  req.requestBody = Blob.valueof('abc'); // Add JSON Message as a POST
	 	
	  RestResponse res = new RestResponse();
	  RestContext.request = req;
	  RestContext.response = res;
	  try {
	  DragAndDropRESTAPI.attachDoc();	
	  } catch (Exception e) {
	  	System.assert(e.getMessage() != null);
	  }
    }
}