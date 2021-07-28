public with sharing class BookingFixedDay {
	
	@TestVisible private date checkinday;																			/* Current checkin day */
	private List<Lead__c> BookingData;																	/* Real time Booking data */
	
	public BookingFixedDay(ApexPages.StandardController stdController) {
																										/* query current BookingPlus record */
		checkinday = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :stdController.getId() limit 1].Checkinday__c;
		BookingData = new List<Lead__c>();
																										/* query the same date Booking */
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, Rroom__c, Rroom__r.Name, refTypeOfRooms__r.Name
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
	}
	
	public List<Lead__c> getbooking() {																	/* get booking data*/
		return BookingData;
	}
	
	public date getfixedday() {																			/* Get checkin date of current BookingPlus record */
		return checkinday;
	}
	public PageReference incrementCounter() { 															/* get update booking data */
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, Rroom__c, Rroom__r.Name, refTypeOfRooms__r.Name
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
		return null;
	}

}