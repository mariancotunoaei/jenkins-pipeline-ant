public class Ctrl_CurrencyComponent { 
    public Decimal nr { get; set; } 
    public String nrString { get; set; }

    public String getFormattedString() { 
        String s = '';
        if(nrString != null){
            s = s + (Decimal.valueOf(nrString).setScale(2) + 0.001).format();
        } else if(nr != null) {
            s = s + (nr.setScale(2) + 0.001).format();
        } else {
            return '';
        }
        
        return s.substring(0,s.length()-1);
    }
}