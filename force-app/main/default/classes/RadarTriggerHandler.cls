public with sharing class RadarTriggerHandler {
    public enum EventType {
        CREATE,
        MODIFY,
        REMOVE
    }

    public static void handleTrigger(String objectName, Set<Id> recordIds, EventType eventType) {
        List<Radar_Blip__e> eventsToPublish = new List<Radar_Blip__e>();
        System.debug('Handling trigger for object: ' + objectName + ', event type: ' + eventType);
        for (Id recordId : recordIds) {
            Radar_Blip__e eventPayload = new Radar_Blip__e(
                    Object_Name__c = objectName,
                    Record_ID__c = recordId,
                    Change_Type__c = String.valueOf(eventType)
            );
            eventsToPublish.add(eventPayload);
        }

        // Publish all events in bulk
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
            System.debug('Published ' + results.size() + ' events to EventBus.');
            // (Optional) Error handling
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to publish event: ' + result.getErrors()[0].getMessage());
                } else {
                    System.debug('Successfully published event with ID: ' + result.getId());
                }
            }
        }
    }
}