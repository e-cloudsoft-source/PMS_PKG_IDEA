<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ActionFieldUpdate</fullName>
        <field>Result__c</field>
        <literalValue>修理済</literalValue>
        <name>故障解除</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>自動故障解除</fullName>
        <active>false</active>
        <criteriaItems>
            <field>RoomsStatus__c.Status__c</field>
            <operation>equals</operation>
            <value>故障</value>
        </criteriaItems>
        <criteriaItems>
            <field>RoomsStatus__c.Result__c</field>
            <operation>notEqual</operation>
            <value>修理済</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
