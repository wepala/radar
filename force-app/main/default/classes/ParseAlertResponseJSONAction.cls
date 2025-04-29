public with sharing class ParseAlertResponseJSONAction {

    public class AlertRequest {
        @InvocableVariable(Required=true)
        public List<AlertRun__c> runs; // JSON string from LLM response
    }

    public class AlertResponse {
        @InvocableVariable(Required=true)
        public List<AlertRun__c> runs; // JSON string from LLM response
    }

    @InvocableMethod(Label='Parse Alert Response JSON' Description='Parses JSON from alert evaluation and returns alert status and message.')
    public static List<AlertResponse> parseJson(List<AlertRequest> requests) {
        List<AlertResponse> results = new List<AlertResponse>();

        // Get the Id for our custom notification type
        CustomNotificationType notificationType =
        [SELECT Id, DeveloperName
        FROM CustomNotificationType
        WHERE DeveloperName='Basic_Alert'];


        for (AlertRequest req : requests) {
            //setup a response for each request
            AlertResponse resp = new AlertResponse();
            resp.runs = new List<AlertRun__c>();

            for (AlertRun__c run : req.runs) {
                if (String.isBlank(run.LLM_Response__c)) {
                    System.debug(LoggingLevel.ERROR,'[Radar] AI Response is null or empty');
                    resp.runs.add(run);
                    continue;
                }

                try {
                    //check if JSON is wrapped in ```json ``` and remove it
                    if (run.LLM_Response__c.startsWith('```json')) {
                        run.LLM_Response__c = run.LLM_Response__c.replace('```json', '').replace('```', '').trim();
                    }
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(run.LLM_Response__c);


                    run.Triggered__c = (Boolean) jsonMap.get('alert');
                    String message = (String) jsonMap.get('message');

                    if (run.Triggered__c) {
                        try {
                            //get alert record so we can get the owner
                            Alert__c alert = [SELECT Id, Name FROM Alert__c WHERE Id = :run.Alert__c LIMIT 1];
                            //get alert recipients
                            List<AlertRecipient__c> recipients = [SELECT Id, Recipient__c FROM AlertRecipient__c WHERE Alert__c = :run.Alert__c];
                            List<String> recipientIds = new List<String>();
                            for (AlertRecipient__c recipient : recipients) {
                                recipientIds.add(recipient.Recipient__c);
                            }

                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            notification.setTitle('New Alert');
                            notification.setBody(message);

                            if (run.RelatedRecord__c != null) {
                                notification.setTargetId(run.RelatedRecord__c);
                            }

                            notification.setTargetId(run.Id);
                            notification.setNotificationTypeId(notificationType.Id);

                            notification.send(recipientIds);
                            // Send to user (Set<String>)
                            System.debug('[Radar] Sending notification: ' + message + ' notification id: '+notificationType.Id);

                            //send as email as well
//                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
//                            email.setToAddresses(new String[]{'butch@wepala.com'});
//                            email.setSubject('New Alert: ' + alert.Name);
//                            email.setPlainTextBody(message);
//                            email.setHtmlBody(message);
//                            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
//
//                            System.debug('[Radar] Sending email: ' + message + ' to user: butch@wepala.com');
                        } catch (Exception ex) {
                            System.debug('Error sending notification: ' + ex.getMessage());
                            // Optional: log error or rethrow
                        }
                    }

                    //save alert run
                    run.End_Time__c = DateTime.now();
                    update run;
                    resp.runs.add(run);


                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR,'[Radar] AI Response not processed: ' + e.getMessage());
                }
            }
            results.add(resp);

        }

        return results;
    }
}