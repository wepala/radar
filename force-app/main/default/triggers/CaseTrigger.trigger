trigger CaseTrigger on Case (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        RadarTriggerHandler.handleTrigger(
                'Case',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.CREATE
        );
    }

    if (Trigger.isUpdate) {
        RadarTriggerHandler.handleTrigger(
                'Case',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.MODIFY
        );
    }

    if (Trigger.isDelete) {
        RadarTriggerHandler.handleTrigger(
                'Case',
                Trigger.oldMap.keySet(),
                RadarTriggerHandler.EventType.REMOVE
        );
    }
}