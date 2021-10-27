public with sharing class Ctrl_DateTimeComponent {
    public Date d {get; set;} 
    public DateTime dt {get; set;}
    public String definedFormat {get; set;} 
    
    public String getFormattedDatetime() {
        if (dt == null && d == null) {
            return ''; 
        } else { 
            Datetime dateTimeValue;
            if(dt != null){
                dateTimeValue = dt;
            } else {
                dateTimeValue = DateTime.newInstance(this.d,  Time.newInstance(0,0,0,0));
            }
             
            if (definedFormat == null) {
                return dateTimeValue.format(); //return the full date/time in user's locale and time zone
            } else { 
                return dateTimeValue.format(definedFormat, 'Europe/Amsterdam');
            }
        }
    }   
}