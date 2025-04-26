public with sharing class SendCustomNotificationAction {

    public class NotificationRequest {
        @InvocableVariable(Required=true Description='The ID of the user to notify')
        public Id userId;  // The ID of the user to notify

        @InvocableVariable(Description='The title of the notification' DefaultValue='New Alert')
        public String title;  // Notification title

        @InvocableVariable(Required=true)
        public String message;  // Notification body

        @InvocableVariable
        public Id targetRecordId;  // Optional: record to deep link to
    }

    @InvocableMethod(Label='Send Custom Notification')
    public static void sendNotifications(List<NotificationRequest> requests) {
        for (NotificationRequest req : requests) {
            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(req.title);
                notification.setBody(req.message);

                if (String.isNotBlank(req.targetRecordId)) {
                    notification.setTargetId(req.targetRecordId);
                }

                // Send to user (Set<String>)
                notification.send(new Set<String>{ req.userId });
            } catch (Exception ex) {
                System.debug('Error sending notification: ' + ex.getMessage());
                // Optional: log error or rethrow
            }
        }
    }
}