import Hospital.config;

service /patient on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow patient from Ballerina...";
    }
}