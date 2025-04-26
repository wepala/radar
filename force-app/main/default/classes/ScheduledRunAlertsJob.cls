global with sharing class ScheduledRunAlertsJob implements Schedulable {

    global void execute(SchedulableContext sc) {
        try {
            // Query all active scheduled alerts
            List<Alert__c> alerts = [
                    SELECT Id, Name, Trigger__c, Query__c
                    FROM Alert__c
            ];

            if (alerts.isEmpty()) {
                System.debug('[ScheduledRunAlertsJob] No alerts due today.');
                return;
            }

            // Batch if needed, or pass them all
            launchFlow(alerts);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[ScheduledRunAlertsJob] ' + e.getMessage());
        }
    }

    private static void launchFlow(List<Alert__c> alerts) {
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('scheduledAlerts', alerts); // expects a collection input of Alert__c records
        Flow.Interview.Run_Alert flow = (Flow.Interview.Run_Alert) Flow.Interview.createInterview('Run_Alert', flowInputs);
        flow.start();
    }
}