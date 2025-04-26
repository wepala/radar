public with sharing class GenerateAlertPromptInputAction {

    public class AlertCollectionRequest {
        @InvocableVariable(required=true)
        public List<Alert__c> alerts;
    }

    public class PromptInputResponse {
        @InvocableVariable
        public List<String> inputs;
    }

    @InvocableMethod(label='Generate Prompt Input JSON' description='Generates JSON input for alert evaluation from a list of Alert__c records')
    public static List<PromptInputResponse> generate(List<AlertCollectionRequest> requests) {
        List<PromptInputResponse> responses = new List<PromptInputResponse>();

        if (requests.isEmpty() || requests[0].alerts == null) {
            return responses;
        }

        PromptInputResponse response = new PromptInputResponse();
        response.inputs = new List<String>();

        for (Alert__c alert : requests[0].alerts) {
            // Run dynamic SOQL
            List<SObject> results;
            try {
                System.debug('[Radar] ' + alert.Query__c);
                results = Database.query(alert.Query__c);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '[Radar] Error running query ' + alert.Query__c + ' ' + e.getMessage());
                throw new AuraHandledException('Error running query for alert ' + alert.Name + ': ' + e.getMessage());
            }

            List<Object> recordData = new List<Object>();
            for (SObject sObj : results) {
                recordData.add(sObj.getPopulatedFieldsAsMap());
            }

            Map<String, Object> promptJson = new Map<String, Object>();
            promptJson.put('records', recordData);
            promptJson.put('triggerCondition', alert.Trigger__c);
            promptJson.put('currentDate', Date.today().format());
            String jsonInput = JSON.serialize(promptJson);

            response.inputs.add(jsonInput);

        }

        responses.add(response);
        return responses;
    }
}
