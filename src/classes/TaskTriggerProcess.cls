/**
* TODO関連対応バッチ
* 2018/08/28
**/
public with sharing class TaskTriggerProcess {
    
    // 関連先は取込先の場合、該当取込先変更に従って、子取込先情報を連動更新を行う
    public void updRelationAcccounts(Task[] newList, Task[] oldList, CommConst.TriggerMethod action){
        AccountMulitiSelectorCtrl ctrl = new AccountMulitiSelectorCtrl();
        ctrl.updRelationAccount(newList,oldList,action);
    }
}