/*************************************
*
*************************************/
public with sharing class ExpoAccountMasterUndeleteCtrl extends ExpoCommBaseCtrl{
  // 初始化页面读取
  public PageReference initAct(){
    // *****************************
    // 共通処理呼び出す
    // *****************************
    PageReference pg = checkLogin();
    if (pg != null) return pg;
    // *****************************
    // 実際の業務ロジック処理展開
    // *****************************
    init();
    return null;
  }
  public void init(){
    list<deleteMasterInfo> masterInfo = new list<deleteMasterInfo>();
    String expoOrgInfoId = '';
    if(currentUser != null) expoOrgInfoId = CommUtils.nullToBlank(currentUser.ExpoOrgInfoRef__c);
    list<AccountMaster__c> deleteMasterLst = [Select Id, Name, isDeleted,ExpoDeleteUser__c,  CreatedDate,LastModifiedById,LastModifiedBy.Name,CreatedById,LastModifiedDate,ExpoOrgInfoRef__c From AccountMaster__c Where isDeleted=:TRUE and ExpoOrgInfoRef__c=:expoOrgInfoId order by LastModifiedDate desc all rows];
    for(AccountMaster__c acc : deleteMasterLst){
      masterInfo.add(new deleteMasterInfo(acc,false));
    }
    masterInfoJson = JSON.serialize(masterInfo);
  }
  // 数据的json
  public String masterInfoJson{get;set;}
  public class deleteMasterInfo{
    public AccountMaster__c accountMasterlst{get;set;}
    public Boolean deleteFlg{get;set;}     // アクション
    public String accId{get;set;}      // ID
    public String accName{get;set;}      // 名前
    public String deleteUser{get;set;}    // 削除したユーザ
    public String createDateStr{get;set;}  // 削除日
    public deleteMasterInfo(AccountMaster__c mas,Boolean delFlg){
      accountMasterlst = mas;
      deleteFlg = delFlg;
      accId = mas.Id;
      accName = CommUtils.nullToBlank(mas.Name);
      deleteUser = CommUtils.nullToBlank(mas.ExpoDeleteUser__c);
      createDateStr = mas.LastModifiedDate.format('yyyy/MM/dd HH:ss');
    }
  }
  // 删除的数据恢复响应事件
  @remoteAction
  public static void recovery(list<String> idLst) {
    if(!idLst.isEmpty()){
      list<AccountMaster__c> undeleteLst = [Select Id, Name, isDeleted From AccountMaster__c Where Id =: idLst order by LastModifiedDate desc all rows];
      if(!undeleteLst.isEmpty()) undelete undeleteLst;
    }
  }
}