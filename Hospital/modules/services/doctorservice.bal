import ballerina/http;

import Hospital.config;
import Hospital.routes;
import Hospital.utils;

service /doctor on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow doctor from Ballerina...";
    }
    resource function post updateDoctor(http:Request req,@http:Payload utils:DoctorUpdateBody body) returns http:Response|error {
        return routes:updateDoctor(req,body);
    }
}