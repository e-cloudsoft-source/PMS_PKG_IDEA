/**
* BEANクラス
**/
public without sharing class OptionItem {
    public String val{get;set;}
    public String lab{get;set;}
    public OptionItem (String v, String l) {
    	val = v; lab = l;
    }
    public SelectOption toSelectOption() {
    	return new SelectOption(val,lab);
    }
}