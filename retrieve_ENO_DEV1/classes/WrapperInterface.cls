public abstract class WrapperInterface
{
    protected SObject o;

    public abstract WSDLExample.wsdlResponse send();
    public WrapperInterface()
    {
    }

    public WrapperInterface(Id sfdcId)
    {
        o = getSObject(sfdcId);
    }

    public enum Operation
    {
        UPDATE_OPERATION,
        INSERT_OPERATION,
        DELETE_OPERATION,
        UPSERT_OPERATION
    }

    public abstract String getEndpoint();

    public virtual String getEndpoint(Operation operation)
    {
        return getEndpoint();
    }

    public abstract SObject getSObject(String salesforceId);

    public abstract void parse(SObject objectToParse);


    public abstract String getJSONString();

    public String getJSONString(String salesforceId)
    {
        if(o == null)
            o = getSObject(salesforceId);

        System.debug(o);

        if(o == null)
            throw new IllegalArgumentException('Found no record with the mentioned ID which matches the criteria in the specific getSobject() implementation');

        this.parse(o);
        return this.getJSONString();
    }

    public static String getFormattedDatetime(Datetime value)
    {
        return  value.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }

    public static String getFormattedDate(Date value)
    {
        return ((Datetime)value).formatGmt('yyyy-MM-dd');
    }
}