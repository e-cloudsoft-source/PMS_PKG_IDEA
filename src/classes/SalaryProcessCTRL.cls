public with sharing class SalaryProcessCTRL {
	//氏名
	public String selectedUserName{get;set;}
	public String userNames{get;set;}
	//支店
	public String selectedCompanyName{get;set;}
    public List<SelectOption> selectedCompanyNames{get;set;}
    //部署
    public String selectedDepartment{get;set;}
    public List<SelectOption> selectedDepartments{get;set;}
    private map<String,List<Option>> departmentUserMap = new map<String,List<Option>>();
    private map<String,String> userIdNameMap = new map<String,String>();
    //期間
    public TimeManagement__c timeManagementStart{get;set;}
    public TimeManagement__c timeManagementEnd{get;set;}
    //始業時刻
    public String startTimeOfMaster{get;set;}
    //終業時刻
    public String endTimeOfMaster{get;set;}
    //休憩時間
    public String restTimeOfMaster{get;set;}
    //
    public SalaryItem SalaryItemInfo{get;set;}
    //PDFのパラメータ
    public String parameterOfPDF{get;set;}
    
    public String calYear{get;set;}
    public String calMonth{get;set;}
    public String calStartDay{get;set;}
    public String calEndDay{get;set;}
    public String calDayCount{get;set;}
    public String errorMessage{get;set;}
    public Boolean isShowPageDetail{get;set;}
        
    public SalaryProcessCTRL(){
    	
        selectedUserName = '';
        parameterOfPDF = '';
        
        calYear = '';
	    calMonth = '';
	    calStartDay = '';
	    calEndDay = '';
	    calDayCount = '';
	    //アクセス権限がないため要求を実行できません。データの所有者または、システム管理者にお問い合わせください。
	    errorMessage = Label.MSG_035_0132;
	    isShowPageDetail = false;
	    //アクセス権限を持つユーザ情報を取得
	    List<Document> documentList = [select body, name from Document where DeveloperName = 'AccessSalaryUserXml'];
	    if (!documentList.isEmpty()){
	    	Blob xmlBody = documentList[0].Body;
	    	String strXmlBody = xmlBody.toString();
	    	Dom.XmlNode targetNode, firstNode = null;
			Dom.Document doc = new Dom.Document();
			doc.load(strXmlBody);
			Dom.XMLNode root = doc.getRootElement();
			for(Dom.XMLNode shop : root.getChildElements()) {
				Dom.XmlNode usernameNode =  shop.getChildElement('USERNAME', null);
				if(CommUtils.nullToBlank(usernameNode.getText()) == UserInfo.getUserName()){
			    	isShowPageDetail = true;
			    	break;
			    }
			}
	    }
        SalaryItemInfo = new SalaryItem();
        
        timeManagementStart = new TimeManagement__c();
        Date firstDayOfMonth = System.now().date().addMonths(-1).toStartOfMonth();
        timeManagementStart.WorkDay__c = firstDayOfMonth;
        timeManagementEnd = new TimeManagement__c();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        timeManagementEnd.WorkDay__c = lastDayOfMonth;
		
		selectedCompanyNames = new List<SelectOption>();
	// 2015/09/01 多店舗機能対応 BEGIN
		UserUtil.UserShopInfo userInf = UserUtil.CurrentUserInfo;
		List<ShopInformation__c> shopList = ShopInfoUtil.getBranchShopInfLst(userInf.shops);
		
	    // for (ShopInformation__c shop : [select id,name,ShopCode__c from ShopInformation__c order by Seq__c limit 5000]) {
	    for (ShopInformation__c shop : shopList) {
	// 2015/09/01 多店舗機能対応 END
           selectedCompanyNames.add(new SelectOption(shop.name,shop.name));
        }
		
        //ユーザ 部署の初期化
        selectedDepartments = new List<SelectOption>();
        
        List<User> userList = [select Id,Name,Alias,Department from User where IsActive = true];
        //部門とユーザのマッピング
        List<Option> userNamsLst = new List<Option>();
        List<Option> tempLst = new List<Option>();
        departmentUserMap.put('全部部門',tempLst);
        for(User item : userList){
        	userIdNameMap.put(item.Id,item.Alias);
        	if(item.Department != null){
        		if(departmentUserMap.containsKey(item.Department)){
        			departmentUserMap.get(item.Department).add(new Option(item.Id,item.Alias));
        		}else{
        			tempLst = new List<Option>();
        			tempLst.add(new Option(item.Id,item.Alias));
        			departmentUserMap.put(item.Department,tempLst);
        		}
        	}
        	departmentUserMap.get('全部部門').add(new Option(item.Id,item.Alias));
        }
        selectedDepartments.add(new SelectOption('全部部門',''));
        for(String item : departmentUserMap.keySet()){
        	if(item != '全部部門'){
        		selectedDepartments.add(new SelectOption(item,item));
        	}
        }
        userNames = JSON.serialize(departmentUserMap.get('全部部門'));
    }
    
    public void SalaryCalculation(){
    	if(SalaryItemInfo != null){
    		//数字チェック
    		if(!AllNumberOrNot()){
    			//数字を入力してください。
    			ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.FATAL,Label.MSG_035_0134);
                ApexPages.addMessage(errMsg);
                return;
    		}
    		//課税合計
			Integer iTaxationSum = (String.isEmpty(SalaryItemInfo.BaseSalary) ? 0 : Integer.valueOf(SalaryItemInfo.BaseSalary))  + 
									 (String.isEmpty(SalaryItemInfo.ManagementAllowance) ? 0 : Integer.valueOf(SalaryItemInfo.ManagementAllowance))  +
									 (String.isEmpty(SalaryItemInfo.TitleAllowance) ? 0 : Integer.valueOf(SalaryItemInfo.TitleAllowance))  +
									 (String.isEmpty(SalaryItemInfo.OvertimeAllowance) ? 0 : Integer.valueOf(SalaryItemInfo.OvertimeAllowance))  +
									 (String.isEmpty(SalaryItemInfo.MidnightAllowance) ? 0 : Integer.valueOf(SalaryItemInfo.MidnightAllowance))  +
									 (String.isEmpty(SalaryItemInfo.EarlyShiftAllowance) ? 0 : Integer.valueOf(SalaryItemInfo.EarlyShiftAllowance)) +
									 (String.isEmpty(SalaryItemInfo.TemporaryAdvance) ? 0 : Integer.valueOf(SalaryItemInfo.TemporaryAdvance));
			if(iTaxationSum != 0) SalaryItemInfo.TaxationSum = String.valueOf(iTaxationSum);
			//非課税合計
			Integer iNoTaxationSum = 0;
			iNoTaxationSum = (String.isEmpty(SalaryItemInfo.TravelAllowance) ? 0 : Integer.valueOf(SalaryItemInfo.TravelAllowance));
		    if(iNoTaxationSum != 0) SalaryItemInfo.NoTaxationSum = String.valueOf(iNoTaxationSum);
		    //総支給額合計
		    Integer iPaymentsSum = 0;
		    iPaymentsSum = (String.isEmpty(SalaryItemInfo.TaxationSum) ? 0 : Integer.valueOf(SalaryItemInfo.TaxationSum)) + 
		                   (String.isEmpty(SalaryItemInfo.NoTaxationSum) ? 0 : Integer.valueOf(SalaryItemInfo.NoTaxationSum));
		    if(iPaymentsSum != 0) SalaryItemInfo.PaymentsSum = String.valueOf(iPaymentsSum);
		    //課税対象額
		    Integer iTaxationTargetSum = 0;
		    iTaxationTargetSum = (String.isEmpty(SalaryItemInfo.HealthInsurance) ? 0 : Integer.valueOf(SalaryItemInfo.HealthInsurance)) + 
		    					 (String.isEmpty(SalaryItemInfo.EmploymentInsurance) ? 0 : Integer.valueOf(SalaryItemInfo.EmploymentInsurance)) + 
		    					 (String.isEmpty(SalaryItemInfo.CareInsurance) ? 0 : Integer.valueOf(SalaryItemInfo.CareInsurance)) + 
		    					 (String.isEmpty(SalaryItemInfo.WelfarePension) ? 0 : Integer.valueOf(SalaryItemInfo.WelfarePension));
		    if(iTaxationTargetSum != 0) SalaryItemInfo.TaxationTargetSum = String.valueOf(iTaxationTargetSum);
		    //控除額合計
		    Integer iDeductionSum = 0;
		    iDeductionSum = (String.isEmpty(SalaryItemInfo.IncomeTax) ? 0 : Integer.valueOf(SalaryItemInfo.IncomeTax)) + 
		                    (String.isEmpty(SalaryItemInfo.ResidentTax) ? 0 : Integer.valueOf(SalaryItemInfo.ResidentTax)) + 
		                    (String.isEmpty(SalaryItemInfo.Bonus) ? 0 : Integer.valueOf(SalaryItemInfo.Bonus)) + 
		                    (String.isEmpty(SalaryItemInfo.BoardingFees) ? 0 : Integer.valueOf(SalaryItemInfo.BoardingFees)) + 
		                    (String.isEmpty(SalaryItemInfo.MealCharges) ? 0 : Integer.valueOf(SalaryItemInfo.MealCharges)) + 
		                    (String.isEmpty(SalaryItemInfo.UtilityCosts) ? 0 : Integer.valueOf(SalaryItemInfo.UtilityCosts));
		    if(iDeductionSum != 0) SalaryItemInfo.DeductionSum = String.valueOf(iTaxationTargetSum != 0 ? (iTaxationTargetSum + iDeductionSum) : iDeductionSum);
		    //累積課税合計
		    if(iTaxationTargetSum != 0) SalaryItemInfo.AccumulationTaxationSum = String.valueOf(iTaxationTargetSum);
		    //差引支給額
		    Integer iNetPayments = 0;
		    if(iPaymentsSum != 0) iNetPayments = iPaymentsSum - (iDeductionSum != 0 ? iDeductionSum : 0);
		    if(iNetPayments != 0) SalaryItemInfo.NetPayments = String.valueOf(iNetPayments);
		    system.debug('jiashixin test ::' + timeManagementStart.WorkDay__c);
		    system.debug('jiashixin test ::' + timeManagementEnd.WorkDay__c);
		    
		    system.debug('jiashixin test ::' + userIdNameMap.get(selectedUserName));
		    system.debug('jiashixin test ::' + selectedUserName);
        	if(timeManagementStart.WorkDay__c != null && timeManagementEnd.WorkDay__c != null && !String.isEmpty(selectedUserName)){
        		List<TimeManagement__c> timeManangeList = [select Id,WorksT__c from TimeManagement__c 
        		where WorkerRef__c = :selectedUserName and 
        		      WorkDay__c <= :timeManagementEnd.WorkDay__c and 
        		      WorkDay__c >= :timeManagementStart.WorkDay__c];
        		system.debug('jiashixin test ::' + timeManangeList.size());
             	if(!timeManangeList.isEmpty()){
             		//出勤日数
             		SalaryItemInfo.RealWorkDays = String.valueOf(timeManangeList.size());
             		Decimal iWorksTimeSum = 0;
             		for(TimeManagement__c item : timeManangeList){
             			if(item.WorksT__c != null) iWorksTimeSum += item.WorksT__c;
             		}
             		//勤務時間数
             		if(iWorksTimeSum != 0){
             			SalaryItemInfo.WorkHours = String.valueOf(iWorksTimeSum);
             		}else{
             			SalaryItemInfo.WorkHours = '';
             		}
             		
             	}else{
             		SalaryItemInfo.RealWorkDays = '';
             		SalaryItemInfo.WorkHours = '';
             	}
        	}		    
    	}
    	
    	
    }
    public void printFromPDF(){
    	system.debug('jiashixin here is method calculate selectedUserName :::' + selectedUserName);
    	parameterOfPDF = '';
    	//数字チェック
    	//if(AllNumberOrNot()) return;
    		//パラメータの作成
    		parameterOfPDF += 'BaseSalary=' + SalaryItemInfo.BaseSalary + '&';
			parameterOfPDF += 'ManagementAllowance=' + SalaryItemInfo.ManagementAllowance + '&';
			parameterOfPDF += 'TitleAllowance=' + SalaryItemInfo.TitleAllowance + '&';
			parameterOfPDF += 'TravelAllowance=' + SalaryItemInfo.TravelAllowance + '&';
			parameterOfPDF += 'OvertimeAllowance=' + SalaryItemInfo.OvertimeAllowance + '&';
			parameterOfPDF += 'MidnightAllowance=' + SalaryItemInfo.MidnightAllowance + '&';
			parameterOfPDF += 'EarlyShiftAllowance=' + SalaryItemInfo.EarlyShiftAllowance + '&';
			parameterOfPDF += 'HealthInsurance=' + SalaryItemInfo.HealthInsurance + '&';
			parameterOfPDF += 'EmploymentInsurance=' + SalaryItemInfo.EmploymentInsurance + '&';
			parameterOfPDF += 'CareInsurance=' + SalaryItemInfo.CareInsurance + '&';
			parameterOfPDF += 'WelfarePension=' + SalaryItemInfo.WelfarePension + '&';
			parameterOfPDF += 'IncomeTax=' + SalaryItemInfo.IncomeTax + '&';
			parameterOfPDF += 'ResidentTax=' + SalaryItemInfo.ResidentTax + '&';
			parameterOfPDF += 'Bonus=' + SalaryItemInfo.Bonus + '&';
			parameterOfPDF += 'BoardingFees=' + SalaryItemInfo.BoardingFees + '&';
			parameterOfPDF += 'MealCharges=' + SalaryItemInfo.MealCharges + '&';
			parameterOfPDF += 'UtilityCosts=' + SalaryItemInfo.UtilityCosts + '&';
			parameterOfPDF += 'TemporaryAdvance=' + SalaryItemInfo.TemporaryAdvance + '&';
			parameterOfPDF += 'WorkDays=' + SalaryItemInfo.WorkDays + '&';
			parameterOfPDF += 'RealWorkDays=' + SalaryItemInfo.RealWorkDays + '&';
			parameterOfPDF += 'NotWorkDays=' + SalaryItemInfo.NotWorkDays + '&';
			parameterOfPDF += 'WorkHours=' + SalaryItemInfo.WorkHours + '&';
			parameterOfPDF += 'UseRestDays=' + SalaryItemInfo.UseRestDays + '&';
			parameterOfPDF += 'RemainRestDays=' + SalaryItemInfo.RemainRestDays + '&';
			parameterOfPDF += 'OvertimeHours=' + SalaryItemInfo.OvertimeHours + '&';
			parameterOfPDF += 'TaxationSum=' + SalaryItemInfo.TaxationSum + '&';
			parameterOfPDF += 'NoTaxationSum=' + SalaryItemInfo.NoTaxationSum + '&';
			parameterOfPDF += 'PaymentsSum=' + SalaryItemInfo.PaymentsSum + '&';
			parameterOfPDF += 'TaxationTargetSum=' + SalaryItemInfo.TaxationTargetSum + '&';
			parameterOfPDF += 'DeductionSum=' + SalaryItemInfo.DeductionSum + '&';
			parameterOfPDF += 'AccumulationTaxationSum=' + SalaryItemInfo.AccumulationTaxationSum + '&';
			parameterOfPDF += 'NetPayments=' + SalaryItemInfo.NetPayments + '&';
			
			if(timeManagementStart.WorkDay__c != null){
				parameterOfPDF += 'calYear=' + timeManagementStart.WorkDay__c.year()  + '&';
				parameterOfPDF += 'calMonth=' + timeManagementStart.WorkDay__c.month()  + '&';
				parameterOfPDF += 'calStartDay=' +  timeManagementStart.WorkDay__c.day()  + '&';
			}
			if(timeManagementEnd.WorkDay__c != null){
				parameterOfPDF += 'calEndDay=' + timeManagementEnd.WorkDay__c.day()  + '&';
			}
			if(timeManagementStart.WorkDay__c != null && timeManagementEnd.WorkDay__c != null){
				parameterOfPDF += 'calDayCount=' + timeManagementStart.WorkDay__c.daysBetween(timeManagementEnd.WorkDay__c)  + '&';
			}
			parameterOfPDF += 'selectedUserName=' + (userIdNameMap.containsKey(selectedUserName) ? userIdNameMap.get(selectedUserName) : selectedUserName) + '&';
			parameterOfPDF += 'selectedDepartment=' + selectedDepartment + '&';
			parameterOfPDF += 'companyName=' + CommUtils.nullToBlank(selectedCompanyName);
			
			system.debug('jiashixin test20140302 ::' + parameterOfPDF);
    		
    }
    
    public void DepartmentChanged(){
    	String currentSelectPara = Apexpages.currentPage().getParameters().get('selectPara');
        userNames = JSON.serialize(departmentUserMap.get(selectedDepartment));
        system.debug('jiashixin test currentSelectPara::::' + currentSelectPara);
        if(!String.isEmpty(currentSelectPara)){
        	if(currentSelectPara == '1'){
        		selectedUserName = '';
        	}
        }
    }
    
    public class Option {
		public Option (String value, String label) {
			this.value = value;
			this.label = label;
		}
		public String value{get;set;}
		public String label{get;set;}
	}
	private Boolean AllNumberOrNot(){
		if(SalaryItemInfo == null) return true;
		if(!IsHalfNumber(SalaryItemInfo.BaseSalary)) return false;
		if(!IsHalfNumber(SalaryItemInfo.ManagementAllowance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.TitleAllowance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.TravelAllowance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.OvertimeAllowance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.MidnightAllowance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.EarlyShiftAllowance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.HealthInsurance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.EmploymentInsurance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.CareInsurance)) return false;
		if(!IsHalfNumber(SalaryItemInfo.WelfarePension)) return false;
		if(!IsHalfNumber(SalaryItemInfo.IncomeTax)) return false;
		if(!IsHalfNumber(SalaryItemInfo.ResidentTax)) return false;
		if(!IsHalfNumber(SalaryItemInfo.Bonus)) return false;
		if(!IsHalfNumber(SalaryItemInfo.BoardingFees)) return false;
		if(!IsHalfNumber(SalaryItemInfo.MealCharges)) return false;
		if(!IsHalfNumber(SalaryItemInfo.UtilityCosts)) return false;
		if(!IsHalfNumber(SalaryItemInfo.TemporaryAdvance)) return false;
		/*
		if(!IsHalfNumber(SalaryItemInfo.WorkDays)) return false;
		if(!IsHalfNumber(SalaryItemInfo.RealWorkDays)) return false;
		if(!IsHalfNumber(SalaryItemInfo.NotWorkDays)) return false;
		if(!IsHalfNumber(SalaryItemInfo.WorkHours)) return false;
		if(!IsHalfNumber(SalaryItemInfo.UseRestDays)) return false;
		if(!IsHalfNumber(SalaryItemInfo.RemainRestDays)) return false;
		if(!IsHalfNumber(SalaryItemInfo.OvertimeHours)) return false;
		*/
		if(!IsHalfNumber(SalaryItemInfo.TaxationSum)) return false;
		if(!IsHalfNumber(SalaryItemInfo.NoTaxationSum)) return false;
		if(!IsHalfNumber(SalaryItemInfo.PaymentsSum)) return false;
		if(!IsHalfNumber(SalaryItemInfo.TaxationTargetSum)) return false;
		if(!IsHalfNumber(SalaryItemInfo.DeductionSum)) return false;
		if(!IsHalfNumber(SalaryItemInfo.AccumulationTaxationSum)) return false;
		if(!IsHalfNumber(SalaryItemInfo.NetPayments)) return false;
		return true;
	}
	
	//半角数字チェック
	private Boolean IsHalfNumber(String src) {
		if(String.isEmpty(src)){
			return true;
		}else{
			return Pattern.matches('^[0-9]+$', src.replaceAll('-',''));
		}
	}
		
	public class SalaryItem{
		//基本給
	    public String BaseSalary{get;set;}
	    //管理職手当
	    public String ManagementAllowance{get;set;}
	    //役付手当
	    public String TitleAllowance{get;set;}
	    //通勤手当
	    public String TravelAllowance{get;set;}
	    //残業手当
	    public String OvertimeAllowance{get;set;}
	    //深夜手当
	    public String MidnightAllowance{get;set;}
	    //早出手当
	    public String EarlyShiftAllowance{get;set;}
	    //健康保険
	    public String HealthInsurance{get;set;}
	    //雇用保険
	    public String EmploymentInsurance{get;set;}
	    //介護保険
	    public String CareInsurance{get;set;}
	    //厚生年金
	    public String WelfarePension{get;set;}
	    //賞与
	    public String Bonus{get;set;}
	    //寮費
	    public String BoardingFees{get;set;}
	    //食事代
	    public String MealCharges{get;set;}
	    //光熱費
	    public String UtilityCosts{get;set;}
	    //仮払い
	    public String TemporaryAdvance{get;set;}
	    //所得税
	    public String IncomeTax{get;set;}
	    //住民税
	    public String ResidentTax{get;set;}
	    //要勤務日数
	    public String WorkDays{get;set;}
	    //出勤日数
	    public String RealWorkDays{get;set;}
	    //欠勤日数
	    public String NotWorkDays{get;set;}
	    //勤務時間数
	    public String WorkHours{get;set;}
	    //有休消化日数
	    public String UseRestDays{get;set;}
	    //有休残日数
	    public String RemainRestDays{get;set;}
	    //残業時間
	    public String OvertimeHours{get;set;}
	    //課税合計
	    public String TaxationSum{get;set;}
	    //非課税合計
	    public String NoTaxationSum{get;set;}
	    //総支給額合計
	    public String PaymentsSum{get;set;}
	    //課税対象額
	    public String TaxationTargetSum{get;set;}
	    //控除額合計
	    public String DeductionSum{get;set;}
	    //累積課税合計
	    public String AccumulationTaxationSum{get;set;}
	    //差引支給額
	    public String NetPayments{get;set;}
	    
	    public SalaryItem(){
	        //基本給
	        BaseSalary = '';
	        //管理職手当
	        ManagementAllowance = '';
	        //役付手当
		    TitleAllowance = '';
		    //通勤手当
		    TravelAllowance = '';
		    //残業手当
		    OvertimeAllowance = '';
		    //深夜手当
		    MidnightAllowance = '';
		    //早出手当
		    EarlyShiftAllowance = '';
		    //健康保険
		    HealthInsurance = '';
		    //雇用保険
		    EmploymentInsurance = '';
		    //介護保険
		    CareInsurance = '';
		    //厚生年金
		    WelfarePension = '';
		    //所得税
		    IncomeTax = '';
		    //住民税
		    ResidentTax = '';
		    //賞与
		    Bonus = '';
		    //寮費
		    BoardingFees = '';
		    //食事代
		    MealCharges = '';
		    //光熱費
		    UtilityCosts = '';
		    //仮払い
		    TemporaryAdvance = '';
		    //要勤務日数
		    WorkDays = '';
		    //出勤日数
		    RealWorkDays = '';
		    //欠勤日数
		    NotWorkDays = '';
		    //勤務時間数
		    WorkHours = '';
		    //有休消化日数
		    UseRestDays = '';
		    //有休残日数
		    RemainRestDays = '';
		    //残業時間
	    	OvertimeHours = '';
	    	//課税合計
		    TaxationSum = '';
		    //非課税合計
		    NoTaxationSum = '';
		    //総支給額合計
		    PaymentsSum = '';
		    //課税対象額
		    TaxationTargetSum = '';
		    //控除額合計
		    DeductionSum = '';
		    //累積課税合計
		    AccumulationTaxationSum = '';
		    //差引支給額
		    NetPayments = '';
	    }
	}
}