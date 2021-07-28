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
private class RoomCommTriggerProcessTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        List<TypeOfRooms__c> typeRooms = TestCommon.createTypeOfRoom(new List<String>{'001','002'});
        List<Room__c> createRooms = TestCommon.createRooms(1, typeRooms[0].Id);
        List<Room__c> createRoomOth = TestCommon.createRooms(1, typeRooms[1].Id);
        Date todayDt = system.today().addDays(2);
        Lead__c lead = TestCommon.createEnkaiLead(todayDt,createRooms[0].id);
        lead.rroom__c = createRooms[0].id;
        lead.refTypeOfRooms__c = typeRooms[0].id;
        update lead;
        createRooms[0].typeRoomRef__c = typeRooms[1].id;
        update createRooms[0];
        List<Lead__c> leads = [select id,refTypeOfRooms__c from lead__c where id = :lead.id];
        if (!leads.isEmpty()){
        	System.assertEquals(lead.refTypeOfRooms__c, typeRooms[0].Id);
        }
    }
}