trigger LeadTrigger on Lead (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        RadarTriggerHandler.handleTrigger(
                'Lead',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.CREATE
        );
    }

    if (Trigger.isUpdate) {
        RadarTriggerHandler.handleTrigger(
                'Lead',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.MODIFY
        );
    }

    if (Trigger.isDelete) {
        RadarTriggerHandler.handleTrigger(
                'Lead',
                Trigger.oldMap.keySet(),
                RadarTriggerHandler.EventType.REMOVE
        );
    }
}