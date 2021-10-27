@isTest 
private class OutboundManagerTest {

	@isTest
	private static void testName() {
		Account acc = new Account(Name = 'test');
		Test.startTest();
		insert acc;
		Test.stopTest();
	}
}