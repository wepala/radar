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

        for (AlertRequest req : requests) {

            for (AlertRun__c run : req.runs) {
                if (String.isBlank(run.LLM_Response__c)) {
                    System.debug(LoggingLevel.ERROR,'[Radar] AI Response is null or empty');
                    throw new AuraHandledException('AI Response is null or empty');
                }

                try {
                    //check if JSON is wrapped in ```json ``` and remove it
                    if (run.LLM_Response__c.startsWith('```json')) {
                        run.LLM_Response__c = run.LLM_Response__c.replace('```json', '').replace('```', '').trim();
                    }
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(run.LLM_Response__c);

                    AlertResponse resp = new AlertResponse();
                    resp.runs = new List<AlertRun__c>();
                    run.Triggered__c = (Boolean) jsonMap.get('alert');
                    String message = (String) jsonMap.get('message');

                    if (run.Triggered__c) {
                        try {
                            Messaging.CustomNotification notification = new Messaging.CustomNotification();
                            notification.setTitle('New Alert');
                            notification.setBody(message);

                            //get alert record so we can get the owner
                            Alert__c alert = [SELECT Id, OwnerId FROM Alert__c WHERE Id = :run.Alert__c LIMIT 1];
                            notification.setTargetId(run.Id);

                            // Send to user (Set<String>)

                            notification.send(new Set<String>{ alert.OwnerId });

                        } catch (Exception ex) {
                            System.debug('Error sending notification: ' + ex.getMessage());
                            // Optional: log error or rethrow
                        }
                    }

                    //save alert run
                    run.End_Time__c = DateTime.now();
                    update run;
                    resp.runs.add(run);

                    results.add(resp);
                } catch (Exception e) {
                    throw new AuraHandledException('Failed to parse JSON: ' + e.getMessage());
                }
            }


        }

        return results;
    }
}