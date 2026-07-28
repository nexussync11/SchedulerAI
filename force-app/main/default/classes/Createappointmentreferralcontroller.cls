public class Createappointmentreferralcontroller {
 
   @AuraEnabled
public static Boolean isComponentExpired(String componentName) {
    try {
        Component_Config__mdt cfg = [ SELECT ExpiryDateTime__c FROM Component_Config__mdt WHERE DeveloperName = :componentName LIMIT 1];
        if (cfg == null || cfg.ExpiryDateTime__c == null) {
             return false;
        }
        DateTime nowUTC = System.now();
        TimeZone ukTimeZone = TimeZone.getTimeZone('Europe/London');
        Integer offsetMillis = ukTimeZone.getOffset(nowUTC);
        DateTime nowUK = nowUTC.addSeconds(offsetMillis / 1000);
        Boolean expired = nowUK > cfg.ExpiryDateTime__c;
        return expired;
        
    } catch (Exception e) {
        return false;
    }
}
    @AuraEnabled
    public static String getLeadName(String leadId) {
        Lead leadRecord = [SELECT Name FROM Lead WHERE Id = :leadId LIMIT 1];
        return leadRecord.Name;
    }
    
    @Auraenabled
    public static lead convertToDateTime(String reffSubject, String bookedBy , String reffDeatils, string objid,string[] starttime, Date startDate,string emailAddress,string eventName,String bookingSource,String leadName,string bookingstatus){
                                             System.debug('### METHOD CALLED ###');

                                             string singleStartTime=starttime[0];
                                             string formatDate=startDate.format();
                                             string newDateTime=formatDate+', '+singleStartTime;
                                             Datetime startDateTymInstnce=Datetime.parse(newDateTime);
                                             Datetime endDateTymInstnce=startDateTymInstnce.addMinutes(30);
                                             String dateTimeCheck='('+String.valueOf(startDateTymInstnce.format('MM/dd/yyyy hh:mm a'))+', '+String.valueOf(endDateTymInstnce.format('MM/dd/yyyy hh:mm a'))+')';  //'(03/24/2023 09:00 AM, 03/24/2023 09:30 AM)'
                                             
                                             Lead led =[Select id, Name , Status from Lead where Id=: objid];
                                             string loginName=UserInfo.getFirstName()+' '+UserInfo.getLastName();
                                             map<string,list<String>> serwitSA= new map<string,list<String>>();
                                             Set<String> serviceKeyset=new Set<String>();
                                             list<String>serviceKeysetlist= new list<String>();
                                             Service_Resource__c srObj = new Service_Resource__c();
                                             Map<String,Service_Resource__c> serviceResMap = new  Map<String,Service_Resource__c>(); 
                                             
                                             list<Service_Resource__c>  InatlizeSRwithnull = new list<Service_Resource__c>();
                                             List<Service_Resource__c> serResObj=[SELECT Id,Name,RelatedRecordId__c,Active__c,RelatedRecordId__r.IsActive FROM Service_Resource__c Where Active__c=true and RelatedRecordId__r.IsActive=true ];
                                             
                                             for(Service_Resource__c srsource :serResObj){
                                                 serwitSA.put(srsource.Name,new List<String>());
                                                 serviceResMap.put(srsource.Name,srsource);
                                             }
                                                 list<ServiceAppointment__c> sachecklist=[SELECT Id, Account__c, Scheduled_Start__c, Scheduled_End__c, Service_Resource_Name__c, Scheduled_start_text__c, Scheduled_end_text__c FROM ServiceAppointment__c where Scheduled_start_text__c LIKE :'%'+formatDate+'%' ORDER BY CreatedDate ASC];
                                                 for(ServiceAppointment__c sr :sachecklist){
                                                     string srtappiont='('+string.valueOf(sr.Scheduled_start_text__c)+', '+string.valueOf(sr.Scheduled_end_text__c)+')';
                                                     if (serwitSA.containsKey(sr.Service_Resource_Name__c)) {
                                                         serwitSA.get(sr.Service_Resource_Name__c).add(srtappiont);
                                                         
                                                     }      
                                                 }
                                                 serviceKeyset=serwitSA.keyset();
                                                 serviceKeysetlist.addAll(serviceKeyset);   
                                             
                                             if(eventName!=null){
                                                 srObj=[Select Name,RelatedRecordId__c from Service_Resource__c where Id=:eventName];
                                              }
                                             User usrObj=[Select Name,Email from User where Id=:srObj.RelatedRecordId__c];
                                             string usrEmail=String.valueOf(usrObj.Email);
                                             if(led!=null){
                                                 led.Referral_Subject__c=reffSubject;
                                                 led.Referral_Details__c=reffDeatils;
                                                 update led;
                                             }
                                              System.debug('led '+led);
                                             ServiceAppointment__c sp =  new ServiceAppointment__c();
                                             sp.Subject__c=reffSubject;
                                             sp.Booked_By__c =String.valueOf(bookedBy);
                                             sp.Parent_Record1__c = led.Id;
                                             sp.Status__c='Scheduled';
                                             sp.Service_Resource_Name__c=srObj.Name;
                                             sp.Scheduled_Start__c = startDateTymInstnce; 
                                             sp.Scheduled_End__c = endDateTymInstnce;
                                             sp.Scheduled_start_text__c=startDateTymInstnce.format();
                                             sp.Scheduled_end_text__c=endDateTymInstnce.format();
                                             sp.Appointment_Mode__c = String.valueOf(bookingSource);
                                             sp.Name = leadName;
                                             sp.Status__c = bookingstatus;
                                             sp.Lead_Stage_At_Booking__c = led.Status;

                                             insert sp;
                                             System.debug('sp '+sp);
                                             Event evtObj=new Event();
                                             evtObj.Subject=led.Referral_Subject__c;
                                             evtObj.WhoId=led.Id;
                                             evtObj.start_date_time__c=String.valueOf(startDateTymInstnce.format('MM/dd/yyyy hh:mm a'));
                                             evtObj.End_Date_Time__c=String.valueOf(endDateTymInstnce.format('MM/dd/yyyy hh:mm a'));
                                             evtObj.OwnerId=srObj.RelatedRecordId__c;
                                             Long dt1Long = startDateTymInstnce.getTime();
                                             Long dt2Long = endDateTymInstnce.getTime();
                                             Long milliseconds = dt2Long - dt1Long;
                                             Long seconds = milliseconds / 1000;
                                             Long minutes = seconds / 60;
                                             evtObj.DurationInMinutes=Integer.valueof(minutes);
                                             evtObj.ActivityDateTime=startDateTymInstnce;
                                             evtObj.Status__c = sp.Status__c;
                                             insert evtObj;
                                             
                                             Assigned_Resource__c ar=new Assigned_Resource__c();
                                             ar.Service_Appointment__c=sp.Id;
                                             ar.Service_Resource__c=srObj.Id;
                                                 insert ar;
                                             return led;
                                         }
    @Auraenabled
    public static string getUserName(){
        string loginName=UserInfo.getFirstName()+' '+UserInfo.getLastName();
        return loginName;
    }
    
    @Auraenabled
    public static String getPiklistValues1(String RecordId) {
        string EmailValue='';
        lead led = [Select id,Name,Email from Lead where Id =: RecordId limit 1];
        if(led.Email!=null) EmailValue=led.Email;
        return EmailValue;
    }
    @AuraEnabled
    public static void setObjectToRecentItems(Id recordId) {
        if (!String.isBlank(recordId)) {
            Schema.SObjectType sObjectType = recordId.getSobjectType();
            String queryString = String.format('SELECT Id, Name FROM {0} WHERE Id =: recordId FOR VIEW', new List<Object>{sObjectType});
            system.debug(queryString);
            Database.query(queryString);}
        
    }
  
@AuraEnabled
public static List<List<String>> availableStartTimeSlot(String serResId, Date schedstrttime) {
    List<List<String>> finalSlots = new List<List<String>>();

    if (serResId == null || schedstrttime == null) {
        return finalSlots;
    }
    Datetime dt = Datetime.newInstance(schedstrttime.year(), schedstrttime.month(), schedstrttime.day(), 0, 0, 0);
    String weekday = dt.format('EEEE'); 
    List<Resource_Availability__c> availList = [
        SELECT Id, Name, Day_Of_Week__c, Start_Time__c, End_Time__c, Break_Start__c, Break_End__c, Is_Active__c
        FROM Resource_Availability__c
        WHERE Service_Resource__c = :serResId
        AND Day_Of_Week__c = :weekday
        AND Is_Active__c = true
    ];

    if (availList.isEmpty()) {
        return finalSlots;
    }
    for (Resource_Availability__c avail : availList) {
        if (avail.Start_Time__c == null || avail.End_Time__c == null) {
            continue;
        }

        Time startTime = avail.Start_Time__c;
        Time endTime = avail.End_Time__c;
        Time breakStart = avail.Break_Start__c;
        Time breakEnd = avail.Break_End__c;

        if (startTime >= endTime) {
            continue;
        }

        Integer slotMinutes = 30;
        Time cursor = startTime;

        while (cursor.addMinutes(slotMinutes) <= endTime) {
            Time next = cursor.addMinutes(slotMinutes);
			Boolean skip = false;
            if (breakStart != null && breakEnd != null) {
                if ((cursor >= breakStart && cursor < breakEnd) ||
                    (next > breakStart && next <= breakEnd)) {
                    skip = true;
                }
            }

            if (!skip) {
                String startHour   = String.valueOf(cursor.hour());
                String startMinute = String.valueOf(cursor.minute());
                String endHour     = String.valueOf(next.hour());
                String endMinute   = String.valueOf(next.minute());

                if (startHour.length() == 1) startHour = '0' + startHour;
                if (startMinute.length() == 1) startMinute = '0' + startMinute;
                if (endHour.length() == 1) endHour = '0' + endHour;
                if (endMinute.length() == 1) endMinute = '0' + endMinute;

                String startStr = startHour + ':' + startMinute;
                String endStr   = endHour + ':' + endMinute;

                finalSlots.add(new List<String>{ startStr, endStr });
            }
            cursor = next;
        }
    }
    return finalSlots;
}
   
    @AuraEnabled
    public static string returnAccountName (string recid)
    {
        Account accObj=[select name from account where id=:recid];
        return String.valueOf(accObj.name);
    }
    @AuraEnabled
    public static string fetchContactEmail (string conid)
    {
        Contact conObj=[select id,name,email from contact where id=:conid];
        return String.valueOf(conObj.email);
    }
    
    //*********** A C H STARTS******************************
      @AuraEnabled
public static String getInhouseCreatedBy(Id recordId) {
    if (recordId == null) return null;

    Lead ld = [
        SELECT Inhouse_Created_By__c
        FROM Lead
        WHERE Id = :recordId
        LIMIT 1
    ];

    return ld.Inhouse_Created_By__c;

}
    
    @AuraEnabled
public static List<String> getBookedByPicklistValues() {
    List<String> values = new List<String>();

    Schema.DescribeFieldResult dfr =
        Lead.Booked_By__c.getDescribe();

    for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
        if (ple.isActive()) {
            values.add(ple.getValue()); // API value
        }
    }
    return values;
}
@AuraEnabled
public static String getBookedByValue(Id recordId) {
    if (recordId == null) return null;

    return [
        SELECT Booked_By__c
        FROM Lead
        WHERE Id = :recordId
        LIMIT 1
    ].Booked_By__c;
}
@AuraEnabled
public static void updateBookedBy(Id recordId, String bookedBy) {
    if (recordId == null || String.isBlank(bookedBy)) return;

    update new Lead(
        Id = recordId,
        Booked_By__c = bookedBy
    );
}

// ************************************* ACH OVER*************************************
}