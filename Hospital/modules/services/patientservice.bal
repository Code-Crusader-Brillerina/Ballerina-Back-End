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
    resource function get getAllDoctors(http:Request req) returns http:Response|error {
        return routes:getAllDoctors(req);
    }
    resource function post createAppointment(http:Request req,@http:Payload utils:Appoinment body) returns http:Response|error {
        return routes:createAppointment(req,body);
    }
    resource function post getQueue(@http:Payload utils:GetQueue body) returns http:Response|error {
        return routes:getQueue(body);
    }
    resource function post updateAppoinmentPayment(http:Request req,@http:Payload utils:UpdateAppoinmentPayment body) returns http:Response|error {
        return routes:updateAppoinmentPayment(req,body);
    }
    resource function post getPrescription(http:Request req,@http:Payload utils:GetPrescription body) returns http:Response|error {
        return routes:getPrescription(req,body);
    }
}