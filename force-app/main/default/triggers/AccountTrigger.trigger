trigger AccountTrigger on Account (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        RadarTriggerHandler.handleTrigger(
                'Account',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.CREATE
        );
    }

    if (Trigger.isUpdate) {
        RadarTriggerHandler.handleTrigger(
                'Account',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.MODIFY
        );
    }

    if (Trigger.isDelete) {
        RadarTriggerHandler.handleTrigger(
                'Account',
                Trigger.oldMap.keySet(),
                RadarTriggerHandler.EventType.REMOVE
        );
    }
}