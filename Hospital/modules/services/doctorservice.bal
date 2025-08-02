import Hospital.config;

service /doctor on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow doctor from Ballerina...";
    }
}