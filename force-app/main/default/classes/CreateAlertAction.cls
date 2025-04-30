public with sharing class CreateAlertAction {

    public class CreateAlertRequest {
        @InvocableVariable(Required=true Description='The JSON output from the prompt')
        public String promptOutputJson; // The raw JSON returned from the prompt
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
            if (String.isBlank(req.promptOutputJson)) {
                throw new AuraHandledException('Prompt output JSON cannot be blank.');
            }


            try {
                // Parse the JSON into a generic object
                Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(req.promptOutputJson);
                String schedule = (String) parsedJson.get('schedule');
                String triggerCondition = (String) parsedJson.get('trigger');
                String query = (String) parsedJson.get('query');
                String objects;
                //if there is a sendEmail field in the JSON, set it to true or false
                Boolean sendEmail = false;

                if (parsedJson.containsKey('sendEmail') && parsedJson.get('sendEmail') != null) {
                    Object value = parsedJson.get('sendEmail');
                    if (value instanceof Boolean) {
                        sendEmail = (Boolean) value;
                    } else if (value instanceof String) {
                        sendEmail = ((String) value).toLowerCase() == 'true';
                    }
                }

                // Handle objects array
                Object objectsRaw = parsedJson.get('objects');
                if (objectsRaw != null && objectsRaw instanceof List<Object>) {
                    List<Object> objectsList = (List<Object>) objectsRaw;
                    List<String> stringList = new List<String>();
                    for (Object o : objectsList) {
                        stringList.add((String) o);
                    }
                    objects = String.join(stringList, ',');
                } else {
                    objects = null;
                }

                String notificationEmail = null;
                if (parsedJson.containsKey('notificationEmail') && parsedJson.get('notificationEmail') != null) {
                    notificationEmail = (String) parsedJson.get('notificationEmail');
                }

                //TODO: Add logic to parse recipient names and resolve them to IDs
                List<Id> recipientIds = new List<Id>();

                // Map fields
                Alert__c alert = new Alert__c();
                alert.Schedule__c = schedule;
                alert.Query__c = query;
                alert.Trigger__c = triggerCondition;
                alert.Send_Email__c = sendEmail;
                alert.Objects__c = objects;
                alert.Notification_Email__c = notificationEmail;
                insert alert;

                // Create one or more AlertRecipient__c records
                List<AlertRecipient__c> recipients = new List<AlertRecipient__c>();
                // Loop through the recipient IDs and create AlertRecipient__c records
                for (Id userId : recipientIds) {
                    System.debug('Adding recipient: ' + userId);
                    recipients.add(new AlertRecipient__c(
                            Alert__c = alert.Id,
                            Recipient__c = userId
                    ));
                }

                //if the recipient list is empty use the User in the context
                if (recipients.isEmpty()) {
                    recipients.add(new AlertRecipient__c(
                            Alert__c = alert.Id,
                            Recipient__c = UserInfo.getUserId()
                    ));
                }

                // Insert all recipients at once
                if (!recipients.isEmpty()) {
                    insert recipients;
                }


                CreateAlertResponse response = new CreateAlertResponse();
                String link = URL.getOrgDomainUrl().toExternalForm() + '/'+ alert.Id;
                response.alertId = alert.Id;
                response.message = '\uD83D\uDD14 <a href="'+link+'" target="_blank">'+alert.Trigger__c+'</a>';
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
}