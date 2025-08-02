import Hospital.config;

service /admin on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow admin from Ballerina...";
    }
}