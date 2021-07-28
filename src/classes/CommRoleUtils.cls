public with sharing class CommRoleUtils {
	public final static Integer MaxRoleLevel = 7;
	private static Integer curRoleLevel = 0;
	
	public static Set<ID> getRoleSubordinateUsers(Id userId) {
	
		curRoleLevel = 0;
		
	    // get requested user's role
	    Id roleId = [select UserRoleId from User where Id = :userId].UserRoleId;
	    // get all of the roles underneath the user
	    Set<Id> allSubRoleIds = getAllSubRoleIds(new Set<ID>{roleId});
	    // get all of the ids for the users in those roles
	    Map<Id,User> users = new Map<Id, User>([Select Id, Name From User where 
	      UserRoleId IN :allSubRoleIds]);
	    // return the ids as a set so you can do what you want with them
	    return users.keySet();
	
	  }
	
	  private static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
	
		curRoleLevel++;
		//ログイン者の下位ロールは10階層以上になるので、ロールは10階層以内を定義ください。
		if (curRoleLevel > MaxRoleLevel) throw New CommException(Label.MSG_012_0418);
	    Set<ID> currentRoleIds = new Set<ID>();
	
	    // get all of the roles underneath the passed roles
	    for(UserRole userRole :[select Id from UserRole where ParentRoleId 
	      IN :roleIds AND ParentRoleID != null])
	    currentRoleIds.add(userRole.Id);
	
	    // go fetch some more rolls!
	    if(currentRoleIds.size() > 0)
	      currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
	
	    return currentRoleIds;
	
	  }

}