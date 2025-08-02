import Hospital.config;

service /phamesist on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow phamesist from Ballerina...";
    }
}