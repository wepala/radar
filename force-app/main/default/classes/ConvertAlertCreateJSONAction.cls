public with sharing class ConvertAlertCreateJSONAction {

    public class ConvertRequest {
        @InvocableVariable(Required=true Description='The JSON output from the prompt')
        public String promptOutputJson; // The raw JSON returned from the prompt
    }

    public class ConvertResponse {
        @InvocableVariable(Required=true Description='The cadence of the alert and when it should be evaluated')
        public String schedule;

        @InvocableVariable(Required=true Description='What is the condition that will trigger the alert')
        public String triggerCondition;

        @InvocableVariable(Required=true Description='The query that should be run to get the data that needs to be evaluated')
        public String query;

        @InvocableVariable(Required=true Description='This is the data that must be evaluated to see if the alert should be triggered')
        public String objects; // This will now be a comma-separated list
    }

    @InvocableMethod(Label='Convert Alert Create JSON' Description='Maps prompt JSON output to session variables')
    public static List<ConvertResponse> convert(List<ConvertRequest> requests) {
        List<ConvertResponse> responses = new List<ConvertResponse>();

        for (ConvertRequest req : requests) {
            if (String.isBlank(req.promptOutputJson)) {
                throw new AuraHandledException('Prompt output JSON cannot be blank.');
            }

            try {
                // Parse the JSON into a generic object
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(req.promptOutputJson);

                // Map fields
                ConvertResponse resp = new ConvertResponse();
                resp.schedule = (String) parsedJson.get('schedule');
                resp.triggerCondition = (String) parsedJson.get('trigger');
                resp.query = (String) parsedJson.get('query');

                // Handle objects array
                Object objectsRaw = parsedJson.get('objects');
                if (objectsRaw != null && objectsRaw instanceof List<Object>) {
                    List<Object> objectsList = (List<Object>) objectsRaw;
                    List<String> stringList = new List<String>();
                    for (Object o : objectsList) {
                        stringList.add((String) o);
                    }
                    resp.objects = String.join(stringList, ',');
                } else {
                    resp.objects = null;
                }

                responses.add(resp);

            } catch (Exception e) {
                throw new AuraHandledException('Error parsing prompt JSON: ' + e.getMessage());
            }
        }

        return responses;
    }
}
