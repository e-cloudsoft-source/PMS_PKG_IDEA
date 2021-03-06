<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>ExpoNewUserNofity</fullName>
        <description>Expoユーザ新規通知</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Jinyaconnect/ExpoNewUserNotify</template>
    </alerts>
    <alerts>
        <fullName>ExpoPwdReset</fullName>
        <description>Expoユーザパスワードのリセット</description>
        <protected>false</protected>
        <recipients>
            <field>Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Jinyaconnect/ExpoPwdChange</template>
    </alerts>
    <rules>
        <fullName>Expoユーザパスワード変更通知</fullName>
        <actions>
            <name>ExpoPwdReset</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>AND(
LEN( Email__c ) &gt; 1,
ISCHANGED( PwdResetSendMalFlg__c )
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Expoユーザ新規通知</fullName>
        <actions>
            <name>ExpoNewUserNofity</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ExpoUser__c.Email__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
