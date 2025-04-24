public with sharing class GenerateAlertPromptInputAction {

    public class AlertRequest {
        @InvocableVariable(Required=true)
        public Id alertId; // Id of the Alert__c record
    }

    public class PromptInput {
        @InvocableVariable
        public String jsonInput; // The JSON to feed into the LLM prompt
    }

    @InvocableMethod(Label='Generate Prompt Input JSON' Description='Generates JSON input for alert evaluation from an Alert__c record')
    public static List<PromptInput> generate(List<AlertRequest> requests) {
        List<PromptInput> responses = new List<PromptInput>();

        for (AlertRequest request : requests) {
            Alert__c alert = [
                    SELECT Name, Query__c, Trigger__c
                    FROM Alert__c
                    WHERE Id = :request.alertId
                    LIMIT 1
            ];

            // Run dynamic SOQL
            List<SObject> results;
            try {
                results = Database.query(alert.Query__c);
            } catch (Exception e) {
                throw new AuraHandledException('Failed to execute query: ' + e.getMessage());
            }

            // Serialize records to a list of maps for easy JSON
            List<Object> recordData = new List<Object>();
            for (SObject sObj : results) {
                recordData.add(sObj.getPopulatedFieldsAsMap());
            }

            // Add triggerCondition and currentDate
            Map<String, Object> promptJson = new Map<String, Object>();
            promptJson.put('records', recordData);
            promptJson.put('triggerCondition', alert.Trigger__c);
            promptJson.put('currentDate', Date.today().format());

            PromptInput input = new PromptInput();
            input.jsonInput = JSON.serialize(promptJson);

            responses.add(input);
        }

        return responses;
    }
}
