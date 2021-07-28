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
private class PhoneNumberUtilsTest {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        TestCommon.createConfigDoc();
        // 2015/12/01 Assert BEGIN
        System.assertEquals([select Id from Document where Name = 'PhoneConfig'].size(), 1);
        System.assertEquals(PhoneNumberUtils.splitNumber('09033320000',''), '090-3332-0000');
        System.assertEquals(PhoneNumberUtils.splitNumber('070333200000',''), '070333200000');
        System.assertEquals(PhoneNumberUtils.splitNumber('0126700010',''), '01267-0-0010');
        System.assertEquals(PhoneNumberUtils.splitNumber('0154202221',''), '0154-20-2221');
        System.assertEquals(PhoneNumberUtils.splitNumber('0539623200',''), '0539-62-3200');
        System.assertEquals(PhoneNumberUtils.splitNumber('5210033002',''), '521-003-3002');
        System.assertEquals(PhoneNumberUtils.splitNumber('',''), '');
        //System.assertEquals(PhoneNumberUtils.splitNumber('09033320000',''), '090-3332-0000');
        System.assertEquals(PhoneNumberUtils.splitNumber('(03)11113111','-'), '03-1111-3111');
        System.assertEquals(PhoneNumberUtils.splitNumber('(03)(111)(13111)','-'), '03-1111-3111');
        System.assertEquals(PhoneNumberUtils.splitNumber('5556667777','-'), '555-666-7777');
        System.assertEquals(PhoneNumberUtils.splitNumber('9998887777','-'), '999-888-7777');
        System.assertEquals(PhoneNumberUtils.splitNumber('1','-'), '1');
        System.assertEquals(PhoneNumberUtils.splitNumber('12','-'), '12');
        System.assertEquals(PhoneNumberUtils.splitNumber('123','-'), '123');
        System.assertEquals(PhoneNumberUtils.splitNumber('4567','-'), '4567');
        System.assertEquals(PhoneNumberUtils.splitNumber('12345','-'), '12345');
        System.assertEquals(PhoneNumberUtils.splitNumber('123456','-'), '123456');
        System.assertEquals(PhoneNumberUtils.splitNumber('1234567','-'), '1234567');
        System.assertEquals(PhoneNumberUtils.splitNumber('12345678','-'), '12345678');
        System.assertEquals(PhoneNumberUtils.splitNumber('123456789','-'), '123456789');
        System.assertEquals(PhoneNumberUtils.splitNumber('1234567890','-'), '123-456-7890');
        System.assertEquals(PhoneNumberUtils.splitNumber('12345678901','-'), '12345678901');
        System.assertEquals(PhoneNumberUtils.splitNumber('09045678901','-'), '090-4567-8901');
        System.assertEquals(PhoneNumberUtils.splitNumber('090456789012','-'), '090456789012');
        System.assertEquals(PhoneNumberUtils.splitNumber('015420',''), '015420');
        System.assertEquals(PhoneNumberUtils.splitNumber('0154202',''), '0154202');
        System.assertEquals(PhoneNumberUtils.splitNumber('01542022',''), '01542022');
        System.assertEquals(PhoneNumberUtils.splitNumber('015420222',''), '015420222');
        System.assertEquals(PhoneNumberUtils.splitNumber('01542022211',''), '01542022211');
    }

    
}