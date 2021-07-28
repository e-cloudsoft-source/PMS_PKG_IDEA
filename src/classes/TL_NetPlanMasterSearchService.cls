//Generated by wsdl2apex

public class TL_NetPlanMasterSearchService {
    public class planMstSearchForNetRequest {
        public TL_NetPlanMasterSearchService.commonRequest commonRequest;
        public TL_NetPlanMasterSearchService.extractionCondition extractionCondition;
        private String[] commonRequest_type_info = new String[]{'commonRequest','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] extractionCondition_type_info = new String[]{'extractionCondition','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'commonRequest','extractionCondition'};
    }
    public class extractionCondition {
        public String extractionProcedureCode;
        public String agtCode;
        public String netAgtRmTypeCode;
        public String planCode;
        public String offereeCode;
        private String[] extractionProcedureCode_type_info = new String[]{'extractionProcedureCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] agtCode_type_info = new String[]{'agtCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] netAgtRmTypeCode_type_info = new String[]{'netAgtRmTypeCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] planCode_type_info = new String[]{'planCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] offereeCode_type_info = new String[]{'offereeCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'extractionProcedureCode','agtCode','netAgtRmTypeCode','planCode','offereeCode'};
    }
    public class execute {
        public TL_NetPlanMasterSearchService.planMstSearchForNetRequest arg0;
        private String[] arg0_type_info = new String[]{'arg0','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'arg0'};
    }
    public class planMstSearchForNetResponse {
        public TL_NetPlanMasterSearchService.commonResponse commonResponse;
        public TL_NetPlanMasterSearchService.planGroup[] planGroupList;
        public TL_NetPlanMasterSearchService.plan[] planList;
        private String[] commonResponse_type_info = new String[]{'commonResponse','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] planGroupList_type_info = new String[]{'planGroupList','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','-1','true'};
        private String[] planList_type_info = new String[]{'planList','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'commonResponse','planGroupList','planList'};
    }
    public class plan {
        public String agtCode;
        public String netAgtRmTypeCode;
        public String planCode;
        public String offereeCode;
        public String planName;
        public String netAgtRmTypeName;
        public Boolean isChargeAdjustable;
        public String saleDurationFrom;
        public String saleDurationTo;
        public String planGroupCode;
        public String priceRangeName1;
        public String priceRangeCount1;
        public String priceRangeName2;
        public String priceRangeCount2;
        public String priceRangeName3;
        public String priceRangeCount3;
        public String priceRangeName4;
        public String priceRangeCount4;
        public String priceRangeName5;
        public String priceRangeCount5;
        public String priceRangeName6;
        public String priceRangeCount6;
        public String priceRangeName7;
        public String priceRangeCount7;
        public String priceRangeName8;
        public String priceRangeCount8;
        public String priceRangeName9;
        public String priceRangeCount9;
        public String priceRangeName10;
        public String priceRangeCount10;
        public String lincolnUseFlag;
        public String coordinationPrice;
        public String coordinationRate;
        public String coordinationPriceNew;
        public String coordinationRateNew;
        private String[] agtCode_type_info = new String[]{'agtCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] netAgtRmTypeCode_type_info = new String[]{'netAgtRmTypeCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] planCode_type_info = new String[]{'planCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] offereeCode_type_info = new String[]{'offereeCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] planName_type_info = new String[]{'planName','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] netAgtRmTypeName_type_info = new String[]{'netAgtRmTypeName','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] isChargeAdjustable_type_info = new String[]{'isChargeAdjustable','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'1','1','false'};
        private String[] saleDurationFrom_type_info = new String[]{'saleDurationFrom','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] saleDurationTo_type_info = new String[]{'saleDurationTo','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] planGroupCode_type_info = new String[]{'planGroupCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName1_type_info = new String[]{'priceRangeName1','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount1_type_info = new String[]{'priceRangeCount1','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName2_type_info = new String[]{'priceRangeName2','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount2_type_info = new String[]{'priceRangeCount2','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName3_type_info = new String[]{'priceRangeName3','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount3_type_info = new String[]{'priceRangeCount3','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName4_type_info = new String[]{'priceRangeName4','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount4_type_info = new String[]{'priceRangeCount4','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName5_type_info = new String[]{'priceRangeName5','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount5_type_info = new String[]{'priceRangeCount5','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName6_type_info = new String[]{'priceRangeName6','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount6_type_info = new String[]{'priceRangeCount6','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName7_type_info = new String[]{'priceRangeName7','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount7_type_info = new String[]{'priceRangeCount7','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName8_type_info = new String[]{'priceRangeName8','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount8_type_info = new String[]{'priceRangeCount8','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName9_type_info = new String[]{'priceRangeName9','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount9_type_info = new String[]{'priceRangeCount9','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName10_type_info = new String[]{'priceRangeName10','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount10_type_info = new String[]{'priceRangeCount10','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] lincolnUseFlag_type_info = new String[]{'lincolnUseFlag','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] coordinationPrice_type_info = new String[]{'coordinationPrice','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] coordinationRate_type_info = new String[]{'coordinationRate','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] coordinationPriceNew_type_info = new String[]{'coordinationPriceNew','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] coordinationRateNew_type_info = new String[]{'coordinationRateNew','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'agtCode','netAgtRmTypeCode','planCode','offereeCode','planName','netAgtRmTypeName','isChargeAdjustable','saleDurationFrom','saleDurationTo','planGroupCode','priceRangeName1','priceRangeCount1','priceRangeName2','priceRangeCount2','priceRangeName3','priceRangeCount3','priceRangeName4','priceRangeCount4','priceRangeName5','priceRangeCount5','priceRangeName6','priceRangeCount6','priceRangeName7','priceRangeCount7','priceRangeName8','priceRangeCount8','priceRangeName9','priceRangeCount9','priceRangeName10','priceRangeCount10','lincolnUseFlag','coordinationPrice','coordinationRate','coordinationPriceNew','coordinationRateNew'};
    }
    public class planGroup {
        public String planGroupCode;
        public String planGroupName;
        public String priceRangeName1;
        public String priceRangeCount1;
        public String priceRangeName2;
        public String priceRangeCount2;
        public String priceRangeName3;
        public String priceRangeCount3;
        public String priceRangeName4;
        public String priceRangeCount4;
        public String priceRangeName5;
        public String priceRangeCount5;
        public String priceRangeName6;
        public String priceRangeCount6;
        public String priceRangeName7;
        public String priceRangeCount7;
        public String priceRangeName8;
        public String priceRangeCount8;
        public String priceRangeName9;
        public String priceRangeCount9;
        public String priceRangeName10;
        public String priceRangeCount10;
        public String ratePlanCode;
        /** 最新API定義と合せて、Methdo定義を行う BEGIN **/
        public String minPriceInputMissAlarmFlg;
        public String minPrice;
        public String maxPriceInputMissAlarmFlg;
        public String maxPrice;
        /** 最新API定義と合せて、Methdo定義を行う END **/
        public TL_NetPlanMasterSearchService.planRankPrice[] planRankPriceList;
        private String[] planGroupCode_type_info = new String[]{'planGroupCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] planGroupName_type_info = new String[]{'planGroupName','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName1_type_info = new String[]{'priceRangeName1','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount1_type_info = new String[]{'priceRangeCount1','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName2_type_info = new String[]{'priceRangeName2','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount2_type_info = new String[]{'priceRangeCount2','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName3_type_info = new String[]{'priceRangeName3','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount3_type_info = new String[]{'priceRangeCount3','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName4_type_info = new String[]{'priceRangeName4','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount4_type_info = new String[]{'priceRangeCount4','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName5_type_info = new String[]{'priceRangeName5','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount5_type_info = new String[]{'priceRangeCount5','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName6_type_info = new String[]{'priceRangeName6','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount6_type_info = new String[]{'priceRangeCount6','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName7_type_info = new String[]{'priceRangeName7','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount7_type_info = new String[]{'priceRangeCount7','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName8_type_info = new String[]{'priceRangeName8','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount8_type_info = new String[]{'priceRangeCount8','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName9_type_info = new String[]{'priceRangeName9','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount9_type_info = new String[]{'priceRangeCount9','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeName10_type_info = new String[]{'priceRangeName10','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRangeCount10_type_info = new String[]{'priceRangeCount10','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] ratePlanCode_type_info = new String[]{'ratePlanCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        /** 最新API定義と合せて、Methdo定義を行う BEGIN **/
        private String[] minPriceInputMissAlarmFlg_type_info = new String[]{'minPriceInputMissAlarmFlg','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] minPrice_type_info = new String[]{'minPrice','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] maxPriceInputMissAlarmFlg_type_info = new String[]{'maxPriceInputMissAlarmFlg','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] maxPrice_type_info = new String[]{'maxPrice','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        /** 最新API定義と合せて、Methdo定義を行う END **/
        private String[] planRankPriceList_type_info = new String[]{'planRankPriceList','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'planGroupCode','planGroupName','priceRangeName1','priceRangeCount1','priceRangeName2','priceRangeCount2','priceRangeName3','priceRangeCount3','priceRangeName4','priceRangeCount4','priceRangeName5','priceRangeCount5','priceRangeName6','priceRangeCount6','priceRangeName7','priceRangeCount7','priceRangeName8','priceRangeCount8','priceRangeName9','priceRangeCount9','priceRangeName10','priceRangeCount10','ratePlanCode','planRankPriceList'};
    }
    public class commonRequest {
        public String systemId;
        public String pmsUserId;
        public String pmsPassword;
        private String[] systemId_type_info = new String[]{'systemId','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] pmsUserId_type_info = new String[]{'pmsUserId','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] pmsPassword_type_info = new String[]{'pmsPassword','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'systemId','pmsUserId','pmsPassword'};
    }
    public class executeResponse {
        public TL_NetPlanMasterSearchService.planMstSearchForNetResponse return_x;
        private String[] return_x_type_info = new String[]{'return','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'return_x'};
    }
    public class commonResponse {
        public Boolean isSuccess;
        public String failureReason;
        public String errorDescription;
        private String[] isSuccess_type_info = new String[]{'isSuccess','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'1','1','false'};
        private String[] failureReason_type_info = new String[]{'failureReason','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] errorDescription_type_info = new String[]{'errorDescription','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'isSuccess','failureReason','errorDescription'};
    }
    public class planRankPrice {
        public String priceRankCode;
        public String priceRankName;
        public String priceRankFrom;
        public String priceEffectiveDate;
        public String priceRange1;
        public String priceRange2;
        public String priceRange3;
        public String priceRange4;
        public String priceRange5;
        public String priceRange6;
        public String priceRange7;
        public String priceRange8;
        public String priceRange9;
        public String priceRange10;
        private String[] priceRankCode_type_info = new String[]{'priceRankCode','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRankName_type_info = new String[]{'priceRankName','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRankFrom_type_info = new String[]{'priceRankFrom','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceEffectiveDate_type_info = new String[]{'priceEffectiveDate','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange1_type_info = new String[]{'priceRange1','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange2_type_info = new String[]{'priceRange2','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange3_type_info = new String[]{'priceRange3','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange4_type_info = new String[]{'priceRange4','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange5_type_info = new String[]{'priceRange5','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange6_type_info = new String[]{'priceRange6','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange7_type_info = new String[]{'priceRange7','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange8_type_info = new String[]{'priceRange8','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange9_type_info = new String[]{'priceRange9','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] priceRange10_type_info = new String[]{'priceRange10','http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'priceRankCode','priceRankName','priceRankFrom','priceEffectiveDate','priceRange1','priceRange2','priceRange3','priceRange4','priceRange5','priceRange6','priceRange7','priceRange8','priceRange9','priceRange10'};
    }
    public class NetPlanMasterSearchPort {
  		// E-CLOUDSOFT EDIT BEGIN
    	public NetPlanMasterSearchPort(String serviceUrl) {
    		endpoint_x = serviceUrl+'/NetPlanMasterSearchService';
    	}
    	// E-CLOUDSOFT EDIT END
        public String endpoint_x = 'https://test472.tl-lincoln.net/pmsservice/V1/NetPlanMasterSearchService';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/', 'TL_NetPlanMasterSearchService'};
        public TL_NetPlanMasterSearchService.planMstSearchForNetResponse execute(TL_NetPlanMasterSearchService.planMstSearchForNetRequest arg0) {
            TL_NetPlanMasterSearchService.execute request_x = new TL_NetPlanMasterSearchService.execute();
            request_x.arg0 = arg0;
            TL_NetPlanMasterSearchService.executeResponse response_x;
            Map<String, TL_NetPlanMasterSearchService.executeResponse> response_map_x = new Map<String, TL_NetPlanMasterSearchService.executeResponse>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',
              'execute',
              'http://pmsfc1003.pmsfc10.pms.lincoln.seanuts.co.jp/',
              'executeResponse',
              'TL_NetPlanMasterSearchService.executeResponse'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.return_x;
        }
    }
}