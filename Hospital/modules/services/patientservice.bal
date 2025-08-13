import ballerina/http;

import Hospital.config;
import Hospital.utils;
import Hospital.routes;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        exposeHeaders: ["X-CUSTOM-HEADER"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 3600
    }
}

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
    resource function get getAllAppoinments(http:Request req) returns http:Response|error {
        return routes:getAllAppoinments(req);
    }
    resource function get getPatient(http:Request req) returns http:Response|error {
        return routes:getPatient(req);
    }
    resource function post getDoctor(http:Request req,@http:Payload utils:GetDoctor body) returns http:Response|error {
        return routes:getDoctorforPatient(req,body);
    }
    resource function get getAllPharmacis(http:Request req) returns http:Response|error {
        return routes:getAllPharmacis(req);
    }
    resource function post updatePrescriptionPharmacy(http:Request req,@http:Payload utils:UpdatePrescriptionPharmacy body) returns http:Response|error {
        return routes:updatePrescriptionPharmacy(req,body);
    }

}