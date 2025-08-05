import ballerina/http;

import Hospital.config;
import Hospital.utils;
import Hospital.routes;

service /admin on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow admin from Ballerina...";
    }

    resource function post addDoctor(@http:Payload utils:DoctorBody doctor) returns http:Response|error {
        return routes:addDoctor(doctor);
    }
}