import ballerina/http;

import Hospital.config;
import Hospital.utils;
import Hospital.routes;

service /patient on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow patient from Ballerina...";
    }
    resource function post updatePatient(http:Request req,@http:Payload utils:PatientUpdateBody body) returns http:Response|error {
        return routes:updatePatient(req,body);
    }
}