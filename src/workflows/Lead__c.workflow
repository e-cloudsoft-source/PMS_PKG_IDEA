<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>ReservedMailFeedBack</fullName>
        <description>サイトから予約取込の自動返信</description>
        <protected>false</protected>
        <recipients>
            <field>Relcontact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Jinyaconnect/SiteLeadFeedBackMail</template>
    </alerts>
    <alerts>
        <fullName>ReservedMailNotify</fullName>
        <description>サイトから予約取込の自動返信(施設へ送信）</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Jinyaconnect/SiteLeadFeedBackMailNotify</template>
    </alerts>
    <rules>
        <fullName>サイトから予約取込の自動返信</fullName>
        <actions>
            <name>ReservedMailFeedBack</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>ReservedMailNotify</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead__c.EventSource__c</field>
            <operation>equals</operation>
            <value>メール取込</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
