@isTest
public class Test_DataHelper {
	
	public static B25__Reservation__c createBooker() {
		Account a = Test_DataHelper.createAccount(true);
		Contact c = Test_DataHelper.createContact(a.Id, true);
		Test_DataHelper.createBooker25Tree();

		B25__Resource_Type__c t = [SELECT Id FROM B25__Resource_Type__c WHERE Name = 'Meeting Room'];
		B25__Resource__c p = [SELECT Id FROM B25__Resource__c WHERE Name = 'Zuidas'];
		B25__Resource__c r = new B25__Resource__c(Name = 'MR1', B25__Resource_Type__c = t.Id, B25__Parent__c = p.Id, B25__Is_Active__c = true);
		Database.insert(r);

		B25__Reservation_Type__c type = new B25__Reservation_Type__c();
		type.Name = 'DR';
		Database.insert(type);		

		B25__Service_Type__c st = new B25__Service_Type__c(Name = 'st1');
		Database.insert(st);

		B25__Service__c ser = new B25__Service__c(Name = 's1', B25__Service_Type__c = st.Id, B25__Is_Active__c = true, B25__Price__c = 10);
		Database.insert(ser);

		B25__Reservation_Status__c s = new B25__Reservation_Status__c(Name = 'Booking Engine Option');
		s.B25__Background_Color__c = '000000';
		s.B25__Border_Color__c = '000000';
		s.B25__Text_Color__c = '000000';
		Database.insert(s);

		B25__Service_Availability__c bsa = new B25__Service_Availability__c();
		bsa.B25__Service__c = ser.Id;
		bsa.B25__Quantity__c = 1000;
		bsa.B25__Resource__c = r.Id;
		bsa.B25__Start__c = Date.today().addMonths(-12);
		bsa.B25__End__c = Date.today().addMonths(12);
		Database.insert(bsa);

		B25__Reservation__c rsv = new B25__Reservation__c();
		rsv.B25__Account__c = a.Id;
		rsv.B25__Resource__c = r.Id;
		rsv.B25__Contact__c = c.Id;
		rsv.B25__Reservation_Type__c = type.Id;
		rsv.B25__Start__c = Datetime.now();
		rsv.B25__End__c = Datetime.now().addHours(1);
		rsv.B25__Calculation_Method__c = B25.Util_Enums.PriceCalculation.PER_TIME_UNIT.name();
		rsv.B25__Status__c = s.Id;
		rsv.Cost_Centre_Code__c ='a';
		rsv.Purchase_Order_Number__c = 'a';
		Database.insert(rsv);

		B25__Service_Reservation__c sr = new B25__Service_Reservation__c();
		sr.B25__Reservation__c = rsv.Id;
		sr.B25__Quantity__c = 1;
		sr.Original_Quantity__c = 1;
		sr.B25__Notes__c = 'aa';
		sr.B25__Service__c = ser.Id;
		Database.insert(sr);

		return rsv;
	}

	
	public static void createBooker25Tree () {
		B25__Resource_Type__c t1 = new B25__Resource_Type__c(Name = 'Organization');
		Database.insert(t1);

		B25__Resource_Type__c t2 = new B25__Resource_Type__c(Name = 'Country', B25__Parent__c = t1.Id);
		Database.insert(t2);

		B25__Resource_Type__c t3 = new B25__Resource_Type__c(Name = 'City', B25__Parent__c = t2.Id);
		Database.insert(t3);

		B25__Resource_Type__c t4 = new B25__Resource_Type__c(Name = 'Location', B25__Parent__c = t3.Id);
		Database.insert(t4);

		B25__Resource_Type__c t5 = new B25__Resource_Type__c(Name = 'Meeting room', B25__Parent__c = t4.Id, B25__Rentable__c = true);
		Database.insert(t5);

		B25__Resource__c r1 = new B25__Resource__c(Name = 'Spaces', B25__Resource_Type__c = t1.Id, B25__Is_Active__c = true);
		Database.insert(r1);

		B25__Resource__c r2 = new B25__Resource__c(Name = 'Netherlands', B25__Resource_Type__c = t2.Id, B25__Parent__c = r1.Id, B25__Is_Active__c = true, B25__Timezone__c = 'Europe/Amsterdam');
		B25__Resource__c r3 = new B25__Resource__c(Name = 'United States', B25__Resource_Type__c = t2.Id, B25__Parent__c = r1.Id, B25__Is_Active__c = true);
		Database.insert(new B25__Resource__c[]{r2, r3});

		B25__Resource__c r4 = new B25__Resource__c(Name = 'Amsterdam', B25__Resource_Type__c = t3.Id, B25__Parent__c = r2.Id, B25__Is_Active__c = true);
		B25__Resource__c r5 = new B25__Resource__c(Name = 'New York', B25__Resource_Type__c = t3.Id, B25__Parent__c = r3.Id, B25__Is_Active__c = true, B25__Timezone__c = 'United States/New York');
		Database.insert(new B25__Resource__c[]{r4, r5});

		B25__Resource__c r6 = new B25__Resource__c(Name = 'Zuidas', B25__Resource_Type__c = t4.Id, B25__Parent__c = r4.Id, B25__Is_Active__c = true);
		Database.insert(r6);


	}
	
	public static Account createAccount (Boolean doDml) {
		Account a = new Account();
		a.Name = 'Test';

		if (doDml) {
			Database.insert(a);
		}
		return a;
	}

	public static Contact createContact (Id accountId, Boolean doDml) {
		Contact c = new Contact();
		c.FirstName = 'Test';
		c.LastName = 'Test';
		c.Email = 'test@test.nl';
		c.AccountId = accountId;

		if (doDml) {
			Database.insert(c);
		}

		return c;
	}
	
}