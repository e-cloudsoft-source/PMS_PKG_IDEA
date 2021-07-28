/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class BI_OrderWebService {
    webservice static String getOrderInfo(String orderIds){
        Map<String,String> reqMap = (Map<String,String>) JSON.deserializeStrict(orderIds,map<String,String>.class);
        String result = '';
        String orderId = reqMap.get('orderId');
        String localIp = reqMap.get('localIp');
        if (!CommUtils.isBlank(orderId)) {
            List<CooperationResult__c> coos = [select id,ManageID__c,Status__c,AccountAcountRef__c from CooperationResult__c where id = :orderId];
            if (!coos.isEmpty()) {
                String shopOrderId = coos[0].ManageID__c;
                String accountId = coos[0].AccountAcountRef__c;
                if (!CommUtils.isBlank(shopOrderId)) {
                    result = orderPrintInfo(shopOrderId,localIp);
                }
                if (!CommUtils.isBlank(result))
                        update new CooperationResult__c(id = orderId , Status__c = '予約取込完了');
            }
        }
        return result;
    }
    private static String orderPrintInfo(String shopOrderId,String localIp){
        String result = '';
        List<OrderEntryInfo__c> infos = [select AccountRef__c,PrintInfo__c,RoomRef__r.ShopInfoRef__r.shopcode__c from OrderEntryInfo__c where id = :shopOrderId];
            if (!infos.isEmpty()) {
                String spcd = infos[0].RoomRef__r.ShopInfoRef__r.shopcode__c;
                OrderServiceHelp.setInstance(spcd);
                List<OrderServiceHelp.PrintInfo> prints = OrderServiceHelp.getPrintLst();
                boolean hadLocalFlg = false;
                OrderServiceHelp.PrintInfo defInfo = null;
                for (OrderServiceHelp.PrintInfo info : prints) {
                    if (info.deviceUrl == localIp && info.printName == infos[0].PrintInfo__c){
                        hadLocalFlg = true;
                        defInfo = info;
                        break;
                    }
                }
                if (hadLocalFlg) {
                Map<String,Object> objMap = new Map<String,Object>{'accId' => infos[0].AccountRef__c,'orderIds' => new List<String>{shopOrderId},
                                                                        'printName' => infos[0].PrintInfo__c, 'processType' => defInfo.roomOrderLayout};
                    OrderMainCtrl.ProcessResult pt = (OrderMainCtrl.ProcessResult) OrderMainCtrl.remoteCenter('rePrintOrder',JSON.serialize(objMap));
                    result = pt.printInfo;
            }
        }
        return result;
    }
}