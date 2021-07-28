global with sharing class BookingPlus {
	
	@TestVisible private static date checkinday;																		/* Current checkin day */
	private List<Lead__c> BookingData;																/* Real time Booking data */
	private List<Room__c> RoomData;																/* Room Data*/
	private id recordid;																				/* Current Record Id*/
	
	public BookingPlus(ApexPages.StandardController stdController) {
		recordid = stdController.getId();
																										/* Get current BookingPlus record */
		checkinday = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :stdController.getId() limit 1].Checkinday__c;
		BookingData = new List<Lead__c>();
																										/* Getting nearby account with current account */
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, ReservedStatus__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, rRoom__c, rRoom__r.Name, refTypeOfRooms__r.Name, rRoom__r.centreLat__c, rRoom__r.centreLng__c
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
		RoomData = new List<Room__c>();
		RoomData = [select id, Name, Seq__c, Lat__c, Lng__c, Height__c, Width__c, centreLat__c, centreLng__c from Room__c where Name != null order by Seq__c ASC];
	}
	
	public Object[] getBookingData(){																	/* Create JSON DATA */
		Object[] jsonData = new Object[]{};
		double cLat = 0;																				/* Default Position of Marker */
		double cLng = 0;
		double wLat = 83.04752889355734;																/* Default Position of Marker if it is Not Assigned */
		double wLng = -22.5;
		string plan;
		for (integer i = 0; i < BookingData.size(); i++ ) {
			if ( BookingData[i].rRoom__c != null ) {													/* Check not assigned room ? */
				cLat = BookingData[i].rRoom__r.centreLat__c;
				cLng = BookingData[i].rRoom__r.centreLng__c;
			} else {
				cLat = wLat;
				cLng = wLng;
				wLat -= 3;																				/* for vertical position */
			}
			jsonData.add(																				/* Define JSON Data */
				'{name:\'' + ((BookingData[i].Name != null)? esc(BookingData[i].Name) : '') + 														/* Booking Name */
				'\', id:\'' + BookingData[i].Id + 														/* Booking Id */
				'\', flag:\'' + 0 + 																	/* Flag */
				'\', cLat:\'' + cLat + 																	/* If Assigned to Room, Set Marker Position on the Room Area in the map */
				'\', cLng:\'' + cLng + 
				'\', status:\'' + ((BookingData[i].ReservedStatus__c != null)? esc(BookingData[i].ReservedStatus__c) : '') + 									/* Reservation Sattus */
				'\', persons:\'' + BookingData[i].StayPersons__c + 										/* Number of Stay Persons */
				'\', roomid:\'' + BookingData[i].rRoom__c + 											/* Id of Room which Assigned to */
				'\', room:\'' + ((BookingData[i].rRoom__r.Name != null)? esc(BookingData[i].rRoom__r.Name) : '') + 											/* Name of Room which Assigned to */
				'\', roomType:\'' + ((BookingData[i].refTypeOfRooms__r.Name != null)? esc(BookingData[i].refTypeOfRooms__r.Name) : '') +								/* Name of RoomType which Assigned to */
				'\', plan:\'' + ((BookingData[i].Field310__r.Name != null)? esc(BookingData[i].Field310__r.Name) : '') +																	/* Plan name */
				'\', planid:\'' + BookingData[i].Field310__r.Id +								/* Plan Id */
				'\', segment:\'' + ((BookingData[i].Field2__c != null)? esc(BookingData[i].Field2__c) : '') +											/* Segment */
				'\', booktype:\'' + ((BookingData[i].ReservedType__c != null)? esc(BookingData[i].ReservedType__c) : '') +									/* Reservation Type */
				'\'}'
			);
	    }
//		system.debug('*************Debug:jsonData '+ jsonData);
		return jsonData;
	}
	public Object[] getRoomData(){																		/* Create Room JSON DATA */
		Object[] jsonData = new Object[]{};
		double clat1;
		double clng1;
		double clat2;
		double clng2;
		for (integer i = 0; i < RoomData.size(); i++ ) {
			clat1 = ((RoomData[i].Lat__c != null)&&(RoomData[i].Height__c != null))? (RoomData[i].Lat__c - RoomData[i].Height__c) : 0;
			clng1 = (RoomData[i].Lng__c != null)? RoomData[i].Lng__c : 0;
			clat2 = (RoomData[i].Lat__c != null)? RoomData[i].Lat__c : 0;
			clng2 = ((RoomData[i].Lng__c != null)&&(RoomData[i].Width__c  != null))? (RoomData[i].Lng__c + RoomData[i].Width__c): 0;
			
			jsonData.add(																				/* Define JSON Data */
				'{name:\'' + ((RoomData[i].Name != null)? esc(RoomData[i].Name) : '') + 														/* Room Name */
					'\', id:\'' + RoomData[i].Id + 														/* Room Id */
					'\', flag:\'' + 0 + 																/* Flag */
					'\', cLat1:\'' + clat1 + 															/* Room Lat Bottom-Left */
					'\', cLng1:\'' + clng1 + 															/* Room Lng Bottom-Left */
					'\', cLat2:\'' + clat2 + 															/* Room Lat Top-Right */
					'\', cLng2:\'' + clng2 + 															/* Room Lng Top-Right */
					'\', cCentreLat:\'' + RoomData[i].centreLat__c + 									/* Room Centre Lat */
					'\', cCentreLng:\'' + RoomData[i].centreLng__c + 									/* Room Centre Lat */
				'\'}'
			);
		}
		//system.debug('*************Debug:jsonData '+ jsonData);
		return jsonData;
	}
	public List<Lead__c> getbooking() {																/* get booking data*/
  		return BookingData;
    }
	public string getfixedday() {																			/* Get checkin date of current BookingPlus record */
		string cyear = string.valueof(checkinday.year());
		string cmonth = string.valueof(checkinday.month());
		string cday = string.valueof(checkinday.day());
		return cyear + '年 ' + cmonth + '月 ' + cday +'日';
    }
	public string getRecordId() {																		/* get cuurent record id */
		string json = '{id:\''+recordid+'\'}';
		return json;
		//return string.valueOf(recordid);
	}
	
	WebService static integer setRoomAssign(id recid, string jsondata){									/* Web Service Method Update Booking Data */
		integer result = 0;
		id nullval = null;
		if(!((recid==null)||(jsondata==null))){															/* Check Parameters null or not */
																										/* Get current BookingPlus record */
			checkinday = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :recid limit 1].Checkinday__c;
			List<Lead__c> booking = new List<Lead__c>();
			List<Room__c> room = new List<Room__c>();
																										/* Get Booking data */
			booking = [SELECT Id, Name, ReservedStatus__c, rRoom__c, rRoom__r.Name FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
																										/* Get Room data */
			room = [select id, Name from Room__c where Name != null];
			integer bookingsize = booking.size();
			integer roomsize = room.size();
			if((bookingsize > 0)&&(roomsize > 0)){														/* Check records exist or not */
																										/* Deserialize JSONstring to Object */
				system.debug('***DEBUG***_ACdata: ' +jsondata);
				List<AC> acdata = (List<AC>)JSON.deserialize(jsondata, List<AC>.class);
				integer acsize = acdata.size();
				if(acsize == bookingsize){																/* Compare current record size to booking size of parameter */
					
					integer i=0;
					while(i<acsize){																	/* Assign to Room */
						system.debug('***DEBUG***_ACdata: name:'+acdata[i].name+',id:'+acdata[i].id+',flag:'+acdata[i].flag+',cLat:'+acdata[i].cLat+',cLng:'+acdata[i].cLng+',status:'+acdata[i].status+',persons:'+acdata[i].persons+',roomid:'+acdata[i].roomid+',room:'+acdata[i].room+',roomType:'+acdata[i].roomType+',plan:'+acdata[i].plan+',planid:'+acdata[i].planid+',booktype:'+acdata[i].segment+acdata[i].booktype);
						//system.debug('***DEBUG***_ACdata: name:'+acdata[i].name+',id:'+acdata[i].id+',flag:'+acdata[i].flag+',cLat:'+acdata[i].cLat+',cLng:'+acdata[i].cLng+',status:'+acdata[i].status+',persons:'+acdata[i].persons+',roomid:'+acdata[i].roomid+',room:'+acdata[i].room+',plan:'+acdata[i].plan+',planid:'+acdata[i].planid+',booktype:'+acdata[i].segment+acdata[i].booktype);
						if(acdata[i].roomid != 'null'){
							booking[i].rRoom__c = acdata[i].roomid;
						}else{
							booking[i].rRoom__c = nullval;
						}
						booking[i].ReservedStatus__c = acdata[i].status;								/* Put Cancel List */
						i++;
					}
					
					try{																				/* Update Booking Data */
						update booking;
						result = 1;
					} catch (Exception e) {
						result = 2;
					}
				}else{
					result = 3;
				}
			}else{
				result = 4;
			}
		}else{
			result = 5;
		}
		return result;			/* result
									1: Success
									2: Update Error
									3: Booking records has changed by other user
									4: Booking or Room record no more exist
									5: Either Parameter is null
								*/
	}
	
	@TestVisible class AC{					/* ACdata Class for creating Update data from JSON data */
		string name;
		string id;
		integer flag;
		double cLat;
		double cLng;
		string status;
		string persons;
		string roomid;
		string room;
		string roomType;
		string plan;
		string planid;
		string segment;
		string booktype;
	}
	
	public string esc(string str){									/* Escape for XSS (characters: \ " / < > { } % = ; : ( ) & + - ) */
		return str.replace('\\', '\\\\').replace('&', '&amp').replace(';','&#59;').replace('&amp', '&amp;').replace('\'', '&#39;').replace('\"', '&quot;').replace('/','&#47;').replace('<', '&lt;').replace('>', '&gt;').replace('{','&#123;').replace('}','&#125').replace('%', '&#37;').replace('=','&#61;').replace(':','&#58;').replace('(','&#40;').replace(')','&#41;').replace('+','&#43;').replace('-','&#45;');
	}

}