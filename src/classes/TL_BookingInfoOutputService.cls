//Generated by wsdl2apex

public class TL_BookingInfoOutputService {
    public class bookingInfoResponse {
        public TL_BookingInfoOutputService.commonResponse commonResponse;
        public TL_BookingInfoOutputService.configurationSettings configurationSettings;
        public TL_BookingInfoOutputService.bookingInfo[] bookingInfoList;
        private String[] commonResponse_type_info = new String[]{'commonResponse','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] configurationSettings_type_info = new String[]{'configurationSettings','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] bookingInfoList_type_info = new String[]{'bookingInfoList','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'commonResponse','configurationSettings','bookingInfoList'};
    }
    public class execute {
        public TL_BookingInfoOutputService.bookingInfoRequest arg0;
        private String[] arg0_type_info = new String[]{'arg0','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'arg0'};
    }
    public class bookingInfo {
        public String info2048;
        public String info4096;
        public String infoTravelXML;
        public String infoOriginal;
        public String infoSequence;
        public String bookSeq;
        public String bookEdaban;
        private String[] info2048_type_info = new String[]{'info2048','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] info4096_type_info = new String[]{'info4096','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] infoTravelXML_type_info = new String[]{'infoTravelXML','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] infoOriginal_type_info = new String[]{'infoOriginal','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] infoSequence_type_info = new String[]{'infoSequence','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] bookSeq_type_info = new String[]{'bookSeq','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] bookEdaban_type_info = new String[]{'bookEdaban','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'info2048','info4096','infoTravelXML','infoOriginal','infoSequence','bookSeq','bookEdaban'};
    }
    public class outputTarget {
        public String systemCode;
        public String bookingInfoOutputIdForResend;
        public String agtTypeCode;
        private String[] systemCode_type_info = new String[]{'systemCode','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] bookingInfoOutputIdForResend_type_info = new String[]{'bookingInfoOutputIdForResend','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] agtTypeCode_type_info = new String[]{'agtTypeCode','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'systemCode','bookingInfoOutputIdForResend','agtTypeCode'};
    }
    public class bookingInfoRequest {
        public TL_BookingInfoOutputService.commonRequest commonRequest;
        public TL_BookingInfoOutputService.outputTarget outputTarget;
        private String[] commonRequest_type_info = new String[]{'commonRequest','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] outputTarget_type_info = new String[]{'outputTarget','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'commonRequest','outputTarget'};
    }
    public class commonRequest {
        public String systemId;
        public String pmsUserId;
        public String pmsPassword;
        private String[] systemId_type_info = new String[]{'systemId','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] pmsUserId_type_info = new String[]{'pmsUserId','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] pmsPassword_type_info = new String[]{'pmsPassword','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'systemId','pmsUserId','pmsPassword'};
    }
    public class executeResponse {
        public TL_BookingInfoOutputService.bookingInfoResponse return_x;
        private String[] return_x_type_info = new String[]{'return','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'return_x'};
    }
    public class configurationSettings {
        public String outputFileName;
        public String outputFileType;
        public String outputId;
        public Integer outputsCount;
        private String[] outputFileName_type_info = new String[]{'outputFileName','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] outputFileType_type_info = new String[]{'outputFileType','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] outputId_type_info = new String[]{'outputId','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] outputsCount_type_info = new String[]{'outputsCount','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'outputFileName','outputFileType','outputId','outputsCount'};
    }
    public class commonResponse {
        public Boolean isSuccess;
        public String failureReason;
        public String errorDescription;
        private String[] isSuccess_type_info = new String[]{'isSuccess','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'1','1','false'};
        private String[] failureReason_type_info = new String[]{'failureReason','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] errorDescription_type_info = new String[]{'errorDescription','http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/','false','false'};
        private String[] field_order_type_info = new String[]{'isSuccess','failureReason','errorDescription'};
    }
    public class BookingInfoOutputPort {
    	// E-CLOUDSOFT EDIT BEGIN
    	public BookingInfoOutputPort(String serviceUrl) {
    		endpoint_x = serviceUrl+'/BookingInfoOutputService';
    	}
    	// E-CLOUDSOFT EDIT END
        public String endpoint_x = 'https://test472.tl-lincoln.net/pmsservice/V1/BookingInfoOutputService';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/', 'TL_BookingInfoOutputService'};
        public TL_BookingInfoOutputService.bookingInfoResponse execute(TL_BookingInfoOutputService.bookingInfoRequest arg0) {
            TL_BookingInfoOutputService.execute request_x = new TL_BookingInfoOutputService.execute();
            request_x.arg0 = arg0;
            TL_BookingInfoOutputService.executeResponse response_x;
            Map<String, TL_BookingInfoOutputService.executeResponse> response_map_x = new Map<String, TL_BookingInfoOutputService.executeResponse>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',
              'execute',
              'http://pmsfc5001.pmsfc50.pms.lincoln.seanuts.co.jp/',
              'executeResponse',
              'TL_BookingInfoOutputService.executeResponse'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.return_x;
        }
    }
}