public class WSDLExample extends WrapperInterface {

	public  string firstName{ get; set; }
	public  string id{ get; set; }


	public class wsdlResponse{
		public String code;
		public string errorMessage;
	}
	public override wsdlResponse send(){
		//standard 
		wsdlResponse resp = new wsdlResponse();
		resp.code='500';
		resp.errorMessage = 'Generic Error';
		return resp;
	}

	public WSDLExample() {
    }

    public WSDLExample(Boolean lifecycleStatusEvent) {
    }

	public Account getAccount(id accId){
		return [select id,name from account where id=:accId];
	}

	public override String getEndpoint()
    {
        return 'Generic endpoint untill provided!';
    }

	public override void parse (SObject objectToParse)
    {
        this.parse((Account) objectToParse);
    }

	public void parse (account acc){
		this.firstName = acc.Name;
		this.id = acc.Id;
	}

	 public override SObject getSObject(String sfdcId)
    {
        List<String> additionalFields = new List<String>();

        List<SObject> records = Database.query(
            getQuerySObjWithAllFields('Account', 'Id = \'' + sfdcId + '\'', null, additionalFields,false)
        );

        return (SObject) records.iterator().next();
    }

	public static String getQuerySObjWithAllFields (String sObj,
            String whereClause,
            List <Object> objectList,
            List <String> additionalFields,
            Boolean lockForUpdate) {

        List <String> fields = getSObjFieldList(sObj);

        if (additionalFields != null) {
            //query += ',' + String.join(additionalFields, ',');
            fields.addAll(additionalFields);
        }

       

        String query = ' SELECT ' + String.join(fields, ',');
        query += ' FROM ' + sObj;

        if (whereClause != null) {
            query += ' WHERE '+ whereClause;
        }
        if (objectList != null) {
            query += ' :objectList';
        }

        if (lockForUpdate == true) {
            query += ' FOR UPDATE';
        }
        return query;
    }

	public override String getJSONString()
    {
        return JSON.serialize(new Account(Id=this.id,Name=this.firstName));
    }

	public static List <String> getSObjFieldList (String sObj) {

        Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(sObj);
        return new List<String>(sobjType.getDescribe().fields.getMap().KeySet());
    }


}