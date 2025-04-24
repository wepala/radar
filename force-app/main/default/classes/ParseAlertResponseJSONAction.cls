public with sharing class ParseAlertResponseJSONAction {

    public class AlertRequest {
        @InvocableVariable(required=true)
        public String jsonOutput; // JSON string from LLM response
    }

    public class AlertResponse {
        @InvocableVariable
        public Boolean alert;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Parse Alert Response JSON' description='Parses JSON from alert evaluation and returns alert status and message.')
    public static List<AlertResponse> parseJson(List<AlertRequest> requests) {
        List<AlertResponse> results = new List<AlertResponse>();

        for (AlertRequest req : requests) {
            if (String.isBlank(req.jsonOutput)) {
                throw new AuraHandledException('Input JSON cannot be blank.');
            }

            try {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(req.jsonOutput);

                AlertResponse resp = new AlertResponse();
                resp.alert = (Boolean) jsonMap.get('alert');
                resp.message = (String) jsonMap.get('message');

                results.add(resp);
            } catch (Exception e) {
                throw new AuraHandledException('Failed to parse JSON: ' + e.getMessage());
            }
        }

        return results;
    }
}
