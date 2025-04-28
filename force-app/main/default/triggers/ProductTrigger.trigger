trigger ProductTrigger on Product2 (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        RadarTriggerHandler.handleTrigger(
                'Product2',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.CREATE
        );
    }

    if (Trigger.isUpdate) {
        RadarTriggerHandler.handleTrigger(
                'Product2',
                Trigger.newMap.keySet(),
                RadarTriggerHandler.EventType.MODIFY
        );
    }

    if (Trigger.isDelete) {
        RadarTriggerHandler.handleTrigger(
                'Product2',
                Trigger.oldMap.keySet(),
                RadarTriggerHandler.EventType.REMOVE
        );
    }
}