public with sharing class CreateAlertAction {

    // Input structure for the invocable method
    public class CreateAlertRequest {

        @InvocableVariable(Required=true Description='the cadence of the alert and when it should be evaluated')
        public String schedule; // Cron expression or friendly schedule

        @InvocableVariable(Required=true Description='what is the condition that will trigger the alert')
        public String triggerCondition; // Condition to check (e.g., "Amount > 50000")

        @InvocableVariable(Required=true Description='This is the data that must be evaluated to see if the alert should be triggered')
        public String objects; // Field names, object names, etc.

        @InvocableVariable(Required=true Description='The query that should be run to get the data that needs to be evaluated')
        public String query; // Field names, object names, etc.
    }

    // Output structure if needed later
    public class CreateAlertResponse {
        @InvocableVariable(Description='The id of the alert')
        public Id alertId;

        @InvocableVariable(Description='How often the alert is checked')
        public Id cadence;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(Label='Create Alert' Description='Creates an alert record and schedules monitoring job')
    public static List<CreateAlertResponse> createAlert(List<CreateAlertRequest> requests) {
        List<CreateAlertResponse> responses = new List<CreateAlertResponse>();

        for (CreateAlertRequest req : requests) {
            try {
                Alert__c alert = new Alert__c();
//                alert.UserContext__c = UserInfo.getUserId();
                alert.Schedule__c = req.schedule;
                alert.Query__c = req.query;
                alert.Trigger__c = req.triggerCondition;
                insert alert;

                // Step 3: Schedule the alert if needed
                if (req.schedule != null && req.schedule != '') {
                    scheduleAlert(alert);
                }

                // Step 4: Build successful response
                CreateAlertResponse response = new CreateAlertResponse();
                response.alertId = alert.Id;
                response.message = 'Alert created and scheduled successfully.';
                responses.add(response);
            } catch (Exception e) {
                // Handle failure and send back error if necessary
                CreateAlertResponse response = new CreateAlertResponse();
                response.alertId = null;
                response.message = 'Error creating alert: ' + e.getMessage();
                responses.add(response);
            }
        }

        return responses;
    }
    // Utility to schedule the alert job
    private static void scheduleAlert(Alert__c alert) {
        String jobName = 'TuneInAlert_' + alert.Id;

        // TuneInScheduler must implement Schedulable
//        System.schedule(jobName, alert.Schedule__c, new TuneInScheduler(alert.Id));
    }
}