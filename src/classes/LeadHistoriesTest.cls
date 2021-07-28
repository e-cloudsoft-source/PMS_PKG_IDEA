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
private class LeadHistoriesTest {
	@isTest(SeeAllData=true)
    static void myUnitTest() {
        // TO DO: implement unit test
		//system.debug(LoggingLevel.INFO,'historySl------------' + [Select ParentId,Parent.Name, OldValue, NewValue, Field, CreatedDate,CreatedById,CreatedBy.Name From Lead__History limit 10]);
		List<Lead__History> historySl = [Select ParentId,Parent.Name, OldValue, NewValue, Field, CreatedDate,CreatedById,CreatedBy.Name From Lead__History 
										where  Field != 'created'
										order by ParentId, CreatedDate desc limit 200 ];
    	
    	List<Id> leadIds = new List<Id>();
    	for (Lead__History h : historySl) {
    		leadIds.add(h.ParentId);
    	}
    	//System.currentPageReference().getParameters().put('leadIds',String.valueOf(leadIds));
    	LeadHistories l  = new LeadHistories(leadIds);
    	l.init();
    	Map<Id, LeadHistories.LeadHistoryItem> rs = l.resultMap;
    	System.assertNotEquals(rs.size(), 0, rs);
    	
    	System.currentPageReference().getParameters().put('leadIds',String.valueOf(leadIds[0]));
    	LeadHistories ctrl  = new LeadHistories();
    	ctrl.init();
    }
}