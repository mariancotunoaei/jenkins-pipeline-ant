global with sharing class ENOFormLogic implements B25.Form.Customizer {

    global void customize(B25.Form form) {

        List<B25.FormEventHandler> clonedList = form.getRelatedList(B25__Service_Reservation__c.SObjectType).onAdd().clone();

        //We need to overwrite the default handler because we want to make sure that we
        //can use internal and external pricing
        form.getRelatedList(B25__Service_Reservation__c.SObjectType).onAdd().clear();
        for(B25.FormEventHandler eventHandler : clonedList) {
            form.getRelatedList(B25__Service_Reservation__c.SObjectType).onAdd(eventHandler);
            if (eventHandler.getHandlerName() == 'B25 Service Reservation Added Price Defaults') {
                form.getRelatedList(B25__Service_Reservation__c.SObjectType).onAdd(new ReservationServiceHandler());
            }
        }

        form.getRelatedList(Reservation_Performer__c.SObjectType).onSearch(new PerformerSearchHandler());
        form.getRelatedList(Reservation_Performer__c.SObjectType).onAdd(new ReservationPerformerAndStaffHandler());

        form.getRelatedList(Reservation_Staff__c.SObjectType).onSearch(new StaffSearchHandler());
        form.getRelatedList(Reservation_Staff__c.SObjectType).onAdd(new ReservationPerformerAndStaffHandler());
        
        form.getRelatedList(Shift_Staff__c.SObjectType).onSearch(new StaffSearchHandler());
        form.getRelatedList(Shift_Staff__c.SObjectType).onAdd(new ReservationPerformerAndStaffHandler());


        form.getLookup(B25__Reservation__c.B25__Resource__c).onSearch(new ResourceSearchHandler());
        form.getField(B25__Reservation__c.B25__Resource__c).onUpdate(new ResourceHandler());

        form.getRelatedList(B25__Service_Reservation__c.SObjectType)
            .getField(B25__Service_Reservation__c.Original_Quantity__c)
            .onUpdate(new ReservationServiceQuantityFieldHandler());
    }


    //This class adds options to the Performer related list dropdown.
    global with sharing class PerformerSearchHandler extends B25.SearchHandler {
        global override B25.SearchResultCollection getSearchResults(B25.SearchContext context) {
            B25.SearchResultCollection resultCollection = new B25.SearchResultCollection();

            String firstLetter = context.getSearchTerm().left(1);
            if (context.getForm().getReservation().Run__c != null && firstLetter == '-') {
                resultCollection.addSearchResults(ENOFormLogic.addCastItemsOptions(context));
            }

            if(firstLetter == '-'){
                resultCollection.addSearchResults(ENOFormLogic.addChorusItemsOptions(context));
            }

            if(firstLetter == '>'){
                resultCollection.addSearchResults(ENOFormLogic.addPersonGroupOptions(context));
            }
            
            if(firstLetter != '-' && firstLetter != '>'){
                //resultCollection.addSearchResults(context.getDefaultResults().getSearchResults());
                resultCollection.addSearchResults(ENOFormLogic.addPerformerOptions(context));
            }

            return resultCollection;
        }
    }

    global with sharing class ReservationServiceHandler extends B25.FormEventHandler {
        global override void handleEvent(B25.FormEvent event, B25.Form form) {
            B25__Reservation__c reservation = form.getReservation();

            B25__Service__c selectedService = this.getService((Id) event.getNewValue());
            Decimal defaultQuantity = selectedService.B25__Default_Quantity__c != null
                ? selectedService.B25__Default_Quantity__c
                : reservation.B25__Quantity__c;

            Decimal price = selectedService.B25__Price__c;
            if(reservation.Pricing__c == 'Internal Pricing'){
                price = selectedService.Internal_Price__c;
            }

            B25.RelatedListItem newItem = form.getRelatedList(B25__Service_Reservation__c.SObjectType).getItemByGuid(event.getGuid());
            newItem.getField(B25__Service_Reservation__c.B25__Quantity__c).updateValue(defaultQuantity);
            newItem.getField(B25__Service_Reservation__c.Original_Quantity__c).updateValue(defaultQuantity);
            newItem.getField(B25__Service_Reservation__c.B25__Unit_Price__c).updateValue(price);
            if (defaultQuantity != null && price != null) {
                newItem.getField(B25__Service_Reservation__c.B25__Subtotal__c).updateValue(defaultQuantity * price);
            }
            
        }

        public B25__Service__c getService(Id serviceId) {
            return [SELECT Id, B25__Price__c, B25__Default_Quantity__c, Internal_Price__c FROM B25__Service__c WHERE id = :serviceId];
        }

    }

    global with sharing class ReservationServiceQuantityFieldHandler extends B25.FormEventHandler {
        global override void handleEvent(B25.FormEvent event, B25.Form form) {
            List<B25.RelatedListItem> serviceItems = form.getRelatedList(B25__Service_Reservation__c.SObjectType).getItems();

            for(B25.RelatedListItem serviceItem : serviceItems){
                if(serviceItem.getGuid() == event.getGuid()){
                    serviceItem.getField(B25__Service_Reservation__c.B25__Quantity__c).updateValue(event.getNewValue());
                }
            }            
        }
    }

    //This class adds options to the Staff related list dropdown.
    global with sharing class StaffSearchHandler extends B25.SearchHandler {
        global override B25.SearchResultCollection getSearchResults(B25.SearchContext context) {
            B25.SearchResultCollection resultCollection = new B25.SearchResultCollection();
            
            B25__Reservation__c reservation = context.getForm().getReservation();
            String firstLetter = context.getSearchTerm().left(1);

            String workPeriodRecordId = reservation.Work_Period__c;
            if(firstLetter == '>'){
                resultCollection.addSearchResults(ENOFormLogic.addPersonGroupOptions(context));
            } else {
                resultCollection.addSearchResults(ENOFormLogic.addStaffMemberOptions(context));
            } 
            
            
            return resultCollection;
        }
    }

    //This class processes the clicks on a item in the performer or the staff related list
    global with sharing class ReservationPerformerAndStaffHandler extends B25.FormEventHandler {
        global override void handleEvent(B25.FormEvent event, B25.Form form) {
            B25__Reservation__c reservation = form.getReservation();

            String eventValue = String.valueOf(event.getNewValue());

            if(ENOFormLogic.findObjectAPIName(eventValue) == 'Person_Group__c') {
                ENOFormLogic.addPersonGroupItemToRelatedLists(eventValue, form);
            }
            
            ENOFormLogic.addCastMemberItemsToRelatedList(eventValue, form);          

            if(eventValue == 'all-chorus'){
                ENOFormLogic.addChorusMembersToRelatedList(form);
            }

            //Update shift-counter for everything not overtime
            if(reservation.Work_Period__c != null && !reservation.Overtime__c){
                Integer nrOfRecords = form.getRelatedList(Shift_Staff__c.SObjectType).getItems().size();
                if(reservation.Required_Number_of_Employees__c < nrOfRecords){
                    form.getField(B25__Reservation__c.Required_Number_of_Employees__c).updateValue(nrOfRecords);
                }
            }
        }
    }

    public static void addPersonGroupItemToRelatedLists(String eventValue, B25.Form form){
        Person_group__c selectedPersonGroup = [
            SELECT Id, Name, Store_in_Selected_Person_Groups__c,
                (SELECT Performer__c 
                    FROM Person_Group_Performers__r
                    WHERE Performer__r.Active__c = true),
                (SELECT Staff__c, Staff__r.Department__c
                    FROM Person_Group_Staff_Members__r
                    WHERE Staff__r.B25__Is_Active__c = true)
            FROM Person_Group__c
            WHERE Id = :eventValue
            LIMIT 1
        ];

        Set<String> addedPerformerIds = new Set<String>();
        List<B25.RelatedListItem> reservationPerformerItems = form.getRelatedList(Reservation_Performer__c.SObjectType).getItems();
        for(B25.RelatedListItem r : reservationPerformerItems){
            addedPerformerIds.add((String)r.getRecord().get('Performer__c'));
        }

        for(Person_Group_Performer__c personGroupPerformer : selectedPersonGroup.Person_Group_Performers__r){
            if(addedPerformerIds.contains(personGroupPerformer.Performer__c)){
                continue;
            }
            form.getRelatedList(Reservation_Performer__c.SObjectType).addRecord(
                new Reservation_Performer__c(
                    Performer__c = personGroupPerformer.Performer__c
                )
            );
        }
        
        Set<String> addedStaffIds = new Set<String>();
        List<B25.RelatedListItem> reservationStaffItems = form.getRelatedList(Reservation_Staff__c.SObjectType).getItems();
        for(B25.RelatedListItem r : reservationStaffItems){
            addedStaffIds.add((String)r.getRecord().get('Staff__c'));
        }
        
        for(Person_Group_Staff_Member__c personGroupStaff : selectedPersonGroup.Person_Group_Staff_Members__r){
            if(addedStaffIds.contains(personGroupStaff.Staff__c)){
                continue;
            }

            form.getRelatedList(Reservation_Staff__c.SObjectType).addRecord(
                new Reservation_Staff__c(
                    Staff__c = personGroupStaff.Staff__c
                )
            );
        }

        String workPeriodId = form.getReservation()?.Work_Period__c;
        String workPeriodDepartment = [SELECT Department__c FROM Work_Period__c WHERE Id = :workPeriodId]?.Department__c;

        //Be aware this looks similare but is for shift_Staff__c instead of the code above which is reservation_staff
        Set<String> addedShiftStaffIds = new Set<String>();
        List<B25.RelatedListItem> shiftStaffItems = form.getRelatedList(Shift_Staff__c.SObjectType).getItems();
        for(B25.RelatedListItem r : shiftStaffItems){
            addedShiftStaffIds.add((String)r.getRecord().get('Staff__c'));
        }
        
        for(Person_Group_Staff_Member__c personGroupStaff : selectedPersonGroup.Person_Group_Staff_Members__r){
            if(addedShiftStaffIds.contains(personGroupStaff.Staff__c) || 
                (workPeriodDepartment != null && workPeriodDepartment != personGroupStaff.Staff__r.Department__c)){
                continue;
            }

            form.getRelatedList(Shift_Staff__c.SObjectType).addRecord(
                new Shift_Staff__c(
                    Staff__c = personGroupStaff.Staff__c
                )
            );
        }

        //Finally for the call sheet we keep track of which group is selected
        if(selectedPersonGroup.Store_in_Selected_Person_Groups__c){
            ENOFormLogic.setPersonGroupSelectedField(selectedPersonGroup.Name, form);
        }
    }
    
    public static void setPersonGroupSelectedField(String name, B25.Form form){
        B25__Reservation__c reservation = form.getReservation();

        String curValue = reservation.Selected_Person_Groups__c;

        if(curValue == null){
            form.getField(B25__Reservation__c.Selected_Person_Groups__c).updateValue(name);
            return;
        }

        List<String> splittedValues = curValue.split(', ');
        if(!splittedValues.contains(name)){
            splittedValues.add(name);
        }

        form.getField(B25__Reservation__c.Selected_Person_Groups__c).updateValue(String.join(splittedValues,', '));
    }


    public static void addCastMemberItemsToRelatedList(String eventValue, B25.Form form) {
        B25__Reservation__c reservation = form.getReservation();
        Map<String, String> eventList = new Map<String, String>();
        eventList.put('all-castA','Cast A');
        eventList.put('all-castB','Cast B');
        eventList.put('all-castC','Cast C');
        eventList.put('all-castD','Cast D');
        eventList.put('all-covers','Cover');
        
        if(reservation.Run__c != null && eventList.containsKey(eventValue)){
            List<Cast_Member__c> castMembers = [
                SELECT Performer__c 
                FROM Cast_Member__c 
                WHERE Run__c = :reservation.Run__c 
                AND Cast_Cover__c = :eventList.get(eventValue)
                AND Performer__c != null
            ];

            Set<String> addedPerformerIds = new Set<String>();
            List<B25.RelatedListItem> reservationPerformerItems = form.getRelatedList(Reservation_Performer__c.SObjectType).getItems();
            for(B25.RelatedListItem r : reservationPerformerItems){
                addedPerformerIds.add((String)r.getRecord().get('Performer__c'));
            }

            for(Cast_Member__c castMember : castMembers){
                if(addedPerformerIds.contains(castMember.Performer__c)){
                    continue;
                }

                form.getRelatedList(Reservation_Performer__c.SObjectType).addRecord(
                    new Reservation_Performer__c(
                        Performer__c = castMember.Performer__c
                    )
                );
            }
        
        }
    }

    public static void addChorusMembersToRelatedList(B25.Form form){
        List<String> roles = new List<String>();
        roles.add('Chorus (soprano)');
        roles.add('Chorus (mezzo)');
        roles.add('Chorus (Tenor)');
        roles.add('Chorus (Bass)');
        roles.add('Chorus (Countertenor)');
        
        List<Performer__c> performers = [
            SELECT Id 
            FROM Performer__c 
            WHERE Role__c = :roles
            AND Active__c = true
        ];
        
        Set<String> addedPerformerIds = new Set<String>();
        List<B25.RelatedListItem> reservationPerformerItems = form.getRelatedList(Reservation_Performer__c.SObjectType).getItems();
        for(B25.RelatedListItem r : reservationPerformerItems){
            addedPerformerIds.add((String)r.getRecord().get('Performer__c'));
        }
        
        for(Performer__c performer : performers){
            if(addedPerformerIds.contains(performer.Id)){
                continue;
            }

            form.getRelatedList(Reservation_Performer__c.SObjectType).addRecord(
                new Reservation_Performer__c(
                    Performer__c = performer.Id
                )
            );
        }
    }

    public static List<B25.SearchResult> addPersonGroupOptions(B25.SearchContext context) {
        List<B25.SearchResult> searchItems = new List<B25.SearchResult>();

        String searchString = '%' + context.getSearchTerm().replace('>','') + '%';
        List<Person_Group__c> personGroups = [
            SELECT Id, Name 
            FROM Person_Group__c
            WHERE Name LIKE :searchString
        ];

        for(Person_Group__c personGroup : personGroups){
            searchItems.add(
                new B25.SearchResult(personGroup.Id, 'Add all members of ' + personGroup.Name)
                    .setPreventDefault(true)
                    .setIcon('standard:contact_list')
            );
        }

        return searchItems;
    }


    public static List<B25.SearchResult> addCastItemsOptions(B25.SearchContext context){
        List<B25.SearchResult> searchItems = new List<B25.SearchResult>();
        searchItems.add(
            new B25.SearchResult('all-castA', 'Add all performers in Cast A')
                .setPreventDefault(true)
                .setIcon('standard:contact_list')
        );
        searchItems.add(
            new B25.SearchResult('all-castB', 'Add all performers in Cast B')
                .setPreventDefault(true)
                .setIcon('standard:contact_list')
        );
        searchItems.add(
            new B25.SearchResult('all-castC', 'Add all performers in Cast C')
                .setPreventDefault(true)
                .setIcon('standard:contact_list')
        );
        searchItems.add(
            new B25.SearchResult('all-castD', 'Add all performers in Cast D')
                .setPreventDefault(true)
                .setIcon('standard:contact_list')
        );
        searchItems.add(
            new B25.SearchResult('all-covers', 'Add all Cover performers')
                .setPreventDefault(true)
                .setIcon('standard:contact_list')
        );

        return searchItems;
    }

    public static List<B25.SearchResult> addChorusItemsOptions(B25.SearchContext context){
        List<B25.SearchResult> searchItems = new List<B25.SearchResult>();
        searchItems.add(
            new B25.SearchResult('all-chorus', 'Add all performers in the Chorus')
                .setPreventDefault(true)
                .setIcon('standard:contact_list')
        );
        return searchItems;
    }

    public static List<B25.SearchResult> addPerformerOptions(B25.SearchContext context){
        List<B25.SearchResult> searchItems = new List<B25.SearchResult>();

        //remove all the selected items
        Set<String> addedPerformerIds = new Set<String>();
        List<B25.RelatedListItem> reservationPerformerItems = context.getForm().getRelatedList(Reservation_Performer__c.SObjectType).getItems();
        for(B25.RelatedListItem r : reservationPerformerItems){
            addedPerformerIds.add((String)r.getRecord().get('Performer__c'));
        }

        String searchString = '%' + context.getSearchTerm() + '%';
        List<Performer__c> performers  = [
            SELECT Id, Name
            FROM Performer__c 
            WHERE Name LIKE :searchString
            AND Id NOT IN :addedPerformerIds
        ];
        
        for(Performer__c performer : performers){
            searchItems.add(
                new B25.SearchResult(performer.Id, performer.Name)
                    .setIcon('standard:contact')
            );
        }
        return searchItems;

    }

    public static List<B25.SearchResult> addStaffMemberOptions(B25.SearchContext context){
        List<B25.SearchResult> searchItems = new List<B25.SearchResult>();
        
        String workPeriodRecordId = context.getForm().getReservation().Work_Period__c;
        String searchString = '%' + context.getSearchTerm() + '%';
        List<B25__Staff__c> staffMembers = new List<B25__Staff__c>();
        if(workPeriodRecordId != null){
            Work_Period__c workPeriod = [SELECT ID, Department__c FROM Work_Period__c WHERE Id = :workPeriodRecordId];
            
            //remove all the selected items
            Set<String> addedStaffIds = new Set<String>();
            List<B25.RelatedListItem> shiftStaffItems = context.getForm().getRelatedList(Shift_Staff__c.SObjectType).getItems();
            for(B25.RelatedListItem r : shiftStaffItems){
                addedStaffIds.add((String)r.getRecord().get('Staff__c'));
            }

            staffMembers = [
                SELECT Id, Name
                FROM B25__Staff__c 
                WHERE Name LIKE :searchString
                AND Department__c = :workPeriod.Department__c
                AND B25__Is_Active__c = true
                AND Virtual__c = false
                AND Id NOT IN :addedStaffIds
            ];

        } else {

            //remove all the selected items
            Set<String> addedStaffIds = new Set<String>();
            List<B25.RelatedListItem> reservationStaffItems = context.getForm().getRelatedList(Reservation_Staff__c.SObjectType).getItems();
            for(B25.RelatedListItem r : reservationSTaffItems){
                addedStaffIds.add((String)r.getRecord().get('Staff__c'));
            }

            staffMembers = [
                SELECT Id, Name
                FROM B25__Staff__c 
                WHERE Name LIKE :searchString
                AND B25__Is_Active__c = true
                AND Virtual__c = false
                AND Id NOT IN :addedStaffIds
            ];
        }
        
        for(B25__Staff__c staff : staffMembers){
            searchItems.add(
                new B25.SearchResult(staff.Id, staff.Name)
                    .setIcon('standard:contact')
            );
        }

        return searchItems;
    }

    global with sharing class ResourceSearchHandler extends B25.SearchHandler {
        global override B25.SearchResultCollection getSearchResults(B25.SearchContext context) {
            Id resTypeId = context.getForm().getReservation().B25__Reservation_Type__c;

            String superType = [SELECT B25__Super_Type__c FROM B25__Reservation_Type__c WHERE Id = :resTypeId].B25__Super_Type__c;

            if (superType == 'Staff Scheduling') {
                String searchTerm = '%' + context.getSearchTerm() + '%';
                List<B25__Resource__c> resources = [
                    SELECT ID, Name, B25__Context__c
                    FROM B25__Resource__c
                    WHERE B25__Is_Active__c = true
                    AND B25__Resource_Type__r.B25__Rentable__c = true
                    AND B25__IsVirtual__c = false
                    AND Name LIKE :searchTerm
                    ORDER BY Name
                ];

                B25.SearchResultCollection collection = new B25.SearchResultCollection();
                for(B25__Resource__c resource : resources){
                    B25.SearchResult searchResult = new B25.SearchResult(resource.Id, resource.Name);
                    searchResult.setMetaText(resource.B25__Context__c);
                    collection.addSearchResult(searchResult);
                }
                return collection;
            } 
                
            return context.getDefaultResults();
        }
    }

    global with sharing class ResourceHandler extends B25.FormEventHandler {
        global override void handleEvent(B25.FormEvent event, B25.Form form) {

            B25__Reservation__c reservation = form.getReservation();

            String resourceName = [SELECT Name from B25__Resource__c WHERE Id = :reservation.B25__Resource__c].Name;
            if(resourceName != 'Stage'){
                return;
            }

            Id cardId = [SELECT Id FROM Card__c WHERE API_Name__c = 'Stage']?.Id;
            system.debug(reservation.Card__c);
            system.debug(cardId);
            if(reservation.Card__c == cardId){
                return;
            }   

            form.getRelatedList(Reservation_Card__c.SObjectType).addRecord(
                new Reservation_Card__c(
                    Card__c = cardId
                )
            );
        }
    }


    public static String findObjectAPIName( String recordId ){
        if(recordId == null){
            return null;
        }
        String objectAPIName = '';
        String keyPrefix = recordId.substring(0,3);
        for( Schema.SObjectType obj : Schema.getGlobalDescribe().Values() ){
            String prefix = obj.getDescribe().getKeyPrefix();
            if(prefix == keyPrefix){
                objectAPIName = obj.getDescribe().getName();
                break;
            }
        }

        return objectAPIName;
    }
}