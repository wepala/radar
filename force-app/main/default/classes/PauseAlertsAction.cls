public with sharing class PauseAlertsAction {

    public class PauseInput {
        @InvocableVariable(Required=true)
        public String jsonInput; // JSON string with query, pauseStart, pauseEnd
    }

    public class PauseOutput {
        @InvocableVariable
        public Integer alertsUpdated;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(Label='Pause Alerts via JSON' Description='Sets Pause_Start__c and Pause_End__c on matched alerts')
    public static List<PauseOutput> pause(List<PauseInput> inputs) {
        List<PauseOutput> results = new List<PauseOutput>();

        for (PauseInput input : inputs) {
            PauseOutput output = new PauseOutput();
            try {
                System.debug(LoggingLevel.DEBUG, 'Input JSON: ' + input.jsonInput);
                String cleanedJson = input.jsonInput
                        .replaceAll('[\\u00A0\\u2007\\u202F]', ' ') // known weird spaces
                        .trim();
                Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(cleanedJson);

                String query = (String) payload.get('query');
                String startStr = (String) payload.get('pauseStart');
                String endStr = (String) payload.get('pauseEnd');

                if (String.isBlank(query)) {
                    throw new AuraHandledException('Missing required fields in JSON: query, pauseStart, pauseEnd');
                }

                DateTime pauseStart = String.isBlank(startStr) ? null : DateTime.valueOf(startStr);
                DateTime pauseEnd = String.isBlank(endStr) ? null : DateTime.valueOf(endStr);

                // Execute the dynamic query
                List<SObject> rawAlerts = Database.query(query);
                List<Alert__c> alerts = new List<Alert__c>();

                for (SObject record : rawAlerts) {
                    if (record instanceof Alert__c) {
                        Alert__c alert = (Alert__c) record;
                        alert.Pause_Start__c = pauseStart;
                        alert.Pause_End__c = pauseEnd;
                        alerts.add(alert);
                    }
                }

                if (!alerts.isEmpty()) {
                    update alerts;
                }

                output.alertsUpdated = alerts.size();
                if (alerts.isEmpty()) {
                    output.message = '⚠️ No matching alerts found';
                } else {
                    output.message = '✅ Updated ' + alerts.size() + ' alerts';
                }

                if (pauseStart != null && pauseEnd != null) {
                    output.message += ' from ' + String.valueOf(pauseStart) + ' to ' + String.valueOf(pauseEnd);
                } else if (pauseStart != null) {
                    output.message += ' starting at ' + String.valueOf(pauseStart);
                } else if (pauseEnd != null) {
                    output.message += ' ending at ' + String.valueOf(pauseEnd);
                }
            } catch (Exception e) {
                output.alertsUpdated = 0;
                output.message = '⚠️ Error pausing alerts';
                System.debug(LoggingLevel.ERROR, 'Error pausing alerts: ' + e.getMessage());
            }

            results.add(output);
        }

        return results;
    }
}