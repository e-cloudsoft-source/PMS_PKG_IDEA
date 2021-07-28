public with sharing class SalaryPdfCTRL {
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
    
    public String selectedUserName{get;set;}
	public String userNames{get;set;}
	public String companyName{get;set;}
    public String selectedDepartment{get;set;}
    
    public String calYear{get;set;}
    public String calMonth{get;set;}
    public String calStartDay{get;set;}
    public String calEndDay{get;set;}
    public String calDayCount{get;set;}
    
    public SalaryPdfCTRL(){
		BaseSalary = System.currentPageReference().getParameters().get('BaseSalary');
		ManagementAllowance = System.currentPageReference().getParameters().get('ManagementAllowance');
		TitleAllowance = System.currentPageReference().getParameters().get('TitleAllowance');
		TravelAllowance = System.currentPageReference().getParameters().get('TravelAllowance');
		OvertimeAllowance = System.currentPageReference().getParameters().get('OvertimeAllowance');
		MidnightAllowance = System.currentPageReference().getParameters().get('MidnightAllowance');
		EarlyShiftAllowance = System.currentPageReference().getParameters().get('EarlyShiftAllowance');
		HealthInsurance = System.currentPageReference().getParameters().get('HealthInsurance');
		EmploymentInsurance = System.currentPageReference().getParameters().get('EmploymentInsurance');
		CareInsurance = System.currentPageReference().getParameters().get('CareInsurance');
		WelfarePension = System.currentPageReference().getParameters().get('WelfarePension');
		IncomeTax = System.currentPageReference().getParameters().get('IncomeTax');
		ResidentTax = System.currentPageReference().getParameters().get('ResidentTax');
		Bonus = System.currentPageReference().getParameters().get('Bonus');
		BoardingFees = System.currentPageReference().getParameters().get('BoardingFees');
		MealCharges = System.currentPageReference().getParameters().get('MealCharges');
		UtilityCosts = System.currentPageReference().getParameters().get('UtilityCosts');
		TemporaryAdvance = System.currentPageReference().getParameters().get('TemporaryAdvance');
		WorkDays = System.currentPageReference().getParameters().get('WorkDays');
		RealWorkDays = System.currentPageReference().getParameters().get('RealWorkDays');
		NotWorkDays = System.currentPageReference().getParameters().get('NotWorkDays');
		WorkHours = System.currentPageReference().getParameters().get('WorkHours');
		UseRestDays = System.currentPageReference().getParameters().get('UseRestDays');
		RemainRestDays = System.currentPageReference().getParameters().get('RemainRestDays');
		OvertimeHours = System.currentPageReference().getParameters().get('OvertimeHours');
		TaxationSum = System.currentPageReference().getParameters().get('TaxationSum');
		NoTaxationSum = System.currentPageReference().getParameters().get('NoTaxationSum');
		PaymentsSum = System.currentPageReference().getParameters().get('PaymentsSum');
		TaxationTargetSum = System.currentPageReference().getParameters().get('TaxationTargetSum');
		DeductionSum = System.currentPageReference().getParameters().get('DeductionSum');
		AccumulationTaxationSum = System.currentPageReference().getParameters().get('AccumulationTaxationSum');
		NetPayments = System.currentPageReference().getParameters().get('NetPayments');
		selectedUserName = System.currentPageReference().getParameters().get('selectedUserName');
		//userNames = System.currentPageReference().getParameters().get('userNames');
		companyName = System.currentPageReference().getParameters().get('companyName');
		selectedDepartment = System.currentPageReference().getParameters().get('selectedDepartment');
		calYear = System.currentPageReference().getParameters().get('calYear');
		calMonth = System.currentPageReference().getParameters().get('calMonth');
		calStartDay = System.currentPageReference().getParameters().get('calStartDay');
		calEndDay = System.currentPageReference().getParameters().get('calEndDay');
		calDayCount = System.currentPageReference().getParameters().get('calDayCount');

    }
	    
}