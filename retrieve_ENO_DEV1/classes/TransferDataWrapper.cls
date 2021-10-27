public class TransferDataWrapper implements Comparable
{
    //The transferdata object
    public Outbound_Transfer__c transferData;

    /**
     * Constructor
     *
     * @param transferData
     */
    public TransferDataWrapper(Outbound_Transfer__c transferData)
    {
        this.transferData = transferData;
    }

    /**
     * Implement the compareTo function
     *
     * @param compareTo
     *
     * @return
     */
    public Integer compareTo(Object compareTo)
    {
        TransferDataWrapper compareToILData = (TransferDataWrapper) compareTo;

        if(transferData.inserted_time_in_ms__c < compareToILData.transferData.inserted_time_in_ms__c)
        {
            return -1;
        }

        return 1;
    }
}