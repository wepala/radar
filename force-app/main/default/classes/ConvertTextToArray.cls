public with sharing class ConvertTextToArray {

    public class InputWrapper {
        @InvocableVariable(Label='JSON String Array' Required=true)
        public String jsonStringArray;
    }

    public class OutputWrapper {
        @InvocableVariable(Label='List of strings')
        public List<String> listString;
    }

    @InvocableMethod(Label='Parse JSON List')
    public static List<OutputWrapper> parse(List<InputWrapper> inputs) {
        List<OutputWrapper> output = new List<OutputWrapper>();
        if (inputs == null || inputs.isEmpty()) return output;
        for (InputWrapper input : inputs) {
            if (input.jsonStringArray == null) {
                System.debug(LoggingLevel.ERROR, 'Input json array is null or empty');
                continue;
            }
            OutputWrapper outputItem = new OutputWrapper();
            outputItem.listString = new List<String>();
            try {
                List<String> parsed = (List<String>) JSON.deserialize(input.jsonStringArray, List<String>.class);
                for (String item : parsed) {
                    if (item != null && item.trim().length() > 0) {
                        outputItem.listString.add(item);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error parsing list JSON: ' + e.getMessage());
            }
            output.add(outputItem);
        }
        return output;
    }
}