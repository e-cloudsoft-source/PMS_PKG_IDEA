public with sharing class DatePickerCtrl extends CommBaseCtrl{
 
 	public String dateFormat{get;private set;}
 	public String jsLang{get;private set;}
 	public String jsHolidayDS{get;private set;}
	public DatePickerCtrl() {
		// 基本情報を設定する
		//dateFormat = CommBaseCtrl.getDateFormat().toUpperCase();
		dateFormat = CommBaseCtrl.getDateFormat().toLowerCase();
		dateFormat = dateFormat.replace('yyyy','yy');
		jsLang = (CommBaseCtrl.getLocalIsJapanese() ? 'ja' : 'en');
		// 休暇日
		CalendarExtend calExt = new CalendarExtend(true);
		string apexDateFormat = CommBaseCtrl.getDateFormat();
		map<string,string> jsHolidayMap = new map<string,string>();
		for (Date vDate : calExt.holidayMap.keySet()) {
			Datetime tDate = datetime.newInstance(vDate.year(), vDate.month(), vDate.day());
			String strDate = tDate.format(apexDateFormat);
			jsHolidayMap.put(strDate,calExt.holidayMap.get(vDate));
		}
		jsHolidayDS = JSON.serialize(jsHolidayMap);

	}
}