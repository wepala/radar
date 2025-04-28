public with sharing class GetScheduledAlertsAction {

    public class AlertRequest {
        @InvocableVariable(Required=true)
        public List<Alert__c> alerts; // JSON string from LLM response
    }

    public class ScheduledAlertResponse {
        @InvocableVariable
        public List<AlertRun__c> runs;
    }

    @InvocableMethod(Label='Alerts: Get Scheduled Alerts' Description='Retrieve active scheduled alerts ready for evaluation')
    public static List<ScheduledAlertResponse> getAlerts(List<AlertRequest> requests) {

        List<ScheduledAlertResponse> responses = new List<ScheduledAlertResponse>();

        for (AlertRequest req : requests) {
            if (req.alerts == null || req.alerts.isEmpty()) {
                System.debug(LoggingLevel.ERROR, '[Radar] No alerts found in request');
                continue;
            }

            try {
                ScheduledAlertResponse response = new ScheduledAlertResponse();
                response.runs = new List<AlertRun__c>();

                for (Alert__c alert : req.alerts) {
                    DateTime previousRun = alert.Last_Run__c;
                    alert.Last_Run__c = DateTime.now();
                    //save the alert record
                    update alert;

                    AlertRun__c alertRun = new AlertRun__c();
                    alertRun.Alert__c = alert.Id;
                    alertRun.Name = alert.Name;
                    alertRun.Start_Time__c = DateTime.now();

                    // Run dynamic SOQL
                    List<SObject> results;
                    try {
                        //replace SINCELAST_RUN with the previous run date in the query if it exists
                        if (previousRun == null) {
                            previousRun = DateTime.now().addDays(-30);//default to 30 days prior
                        }
                        System.debug('[Radar] Previous run date: ' + previousRun);
                        String query = alert.Query__c.replace('SINCELAST_RUN', ':previousRun');
                        System.debug('[Radar] ' + query);
                        results = Database.query(query);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, '[Radar] Error running query ' + alert.Query__c + ' ' + e.getMessage());
                        throw new AuraHandledException('Error running query for alert ' + alert.Name + ': ' + e.getMessage());
                    }

                    List<Object> recordData = new List<Object>();
                    for (SObject sObj : results) {
                        recordData.add(sObj.getPopulatedFieldsAsMap());
                    }

                    Map<String, Object> promptJson = new Map<String, Object>();
                    promptJson.put('previousRun', previousRun.format());
                    promptJson.put('records', recordData);
                    promptJson.put('triggerCondition', alert.Trigger__c);
                    promptJson.put('currentDate', Date.today().format());
                    String jsonInput = JSON.serialize(promptJson);

                    alertRun.PromptInputJSON__c = jsonInput;

                    insert alertRun;
                    response.runs.add(alertRun);
                }

                responses.add(response);

                return responses;


            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '[GetScheduledAlertsAction] ' + e.getMessage());
                throw new AuraHandledException('Error fetching scheduled alerts: ' + e.getMessage());
            }
        }

        return responses;
    }
}