trigger ContactTrigger on Contact (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        RadarTriggerHandler.handleTrigger(
                'Contact',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.CREATE
        );
    }

    if (Trigger.isUpdate) {
        RadarTriggerHandler.handleTrigger(
                'Contact',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.MODIFY
        );
    }

    if (Trigger.isDelete) {
        RadarTriggerHandler.handleTrigger(
                'Contact',
                Trigger.oldMap.keySet(),
                RadarTriggerHandler.EventType.REMOVE
        );
    }
}