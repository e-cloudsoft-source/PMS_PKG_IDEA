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
private class ProductItemUtilsTest {

    @isTest 
    static void myUnit() {
		List<AccountMaster__c> accLst = TestCommon.createProductMst(10);
		ProductItemUtils.ProductItem item = ProductItemUtils.getSingProdcutItemByCode(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		Boolean isNotFound = false;
		Try {
			item = ProductItemUtils.getSingProdcutItemByCode('ABCD' + CommUtils.getRandom(9));
		} catch (Exception e) {
			isNotFound = true;
		}
		System.assertEquals(isNotFound, true);
		// 関連の呼び出しクラス呼び出す
		item = BillInput_Ctrl.getProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		item = BookingEstimateItemSetup.getProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		item = SimpleAccountsCtrl.getProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(item.prodcutCode,accLst[0].Field3__c);
		List<ProductItemUtils.ProductItem> items = ProductItemUtils.getArrayProdcutItemByCode(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		items = ProductItemUtils.getArrayProdcutItemByCode('ABCD' + CommUtils.getRandom(9));
		System.assertEquals(items.size(),0);
		items = BillInput_Ctrl.getArrayProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		items = BookingEstimateItemSetup.getArrayProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		items = SimpleAccountsCtrl.getArrayProductItemInfo(accLst[0].Field3__c);
		System.assertEquals(items[0].prodcutCode,accLst[0].Field3__c);
		
		String roomPriceProdName = CommUtils.nullToBlank(CommDefine__c.getOrgDefaults().RoomPriceProdName__c);
		ProductItemUtils.getRoomRateProduct(roomPriceProdName);
		
		Plan__c plan = TestCommon.createPlan();
		List<ProductItemUtils.PlanDetail> rs1 = ProductItemUtils.getPlanDetailList(plan.Id);
		List<ProductItemUtils.PlanDetail> rs2 = ProductItemUtils.getPlanDetailList(plan.Id, Date.today());
		Set<Id> planIdSet = new Set<Id>();
		planIdSet.add(plan.id);
									
		ProductItemUtils planutil = new ProductItemUtils();
		//Map<Id, List<PlanDetail__c>> rs3 = planutil.getRoomItemByPlanId(planIdSet);
		plan = TestCommon.createPlanIncRoom();
		Id planProdId = [select PlanProdcut__c from PlanDetail__c where PlanRef__c = :plan.Id limit 1].PlanProdcut__c;
		ProductItemUtils.getRoomPriceByProdIds(new Set<Id>{planProdId});
		ProductItemUtils.checkRoomProduct(new Set<Id>{planProdId});
		List<PlanDetail__c> planDetailLst = [Select AccountMasterRef__c,PlanProdcut__c, Price__c, OptionAccMstFLG__c,TaxRate__c From PlanDetail__c  where PlanProdcut__c = :planProdId];
		ProductItemUtils.getPlanOrgPdInfo(planDetailLst,new ProductItemUtils.LeadInfoSync());
		// getNwDetailLst
	}
}