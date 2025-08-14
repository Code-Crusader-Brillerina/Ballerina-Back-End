import ballerina/http;

import Hospital.config;
import Hospital.routes;
import Hospital.utils;

@http:ServiceConfig {
    cors: {
        allowOrigins: [],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        exposeHeaders: ["X-CUSTOM-HEADER"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 3600
    }
}

service /doctor on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow doctor from Ballerina...";
    }
    resource function post updateDoctor(http:Request req,@http:Payload utils:DoctorUpdateBody body) returns http:Response|error {
        return routes:updateDoctor(req,body);
    }
    resource function get getDoctorHistory(http:Request req) returns http:Response|error {
        return routes:getDoctorHistory(req);
    }
    resource function post updateAppoinmentStatus(http:Request req,@http:Payload utils:UpdateAppoinmentStatus body) returns http:Response|error {
        return routes:updateAppoinmentStatus(req,body);
    }
    resource function post createPrescription(http:Request req,@http:Payload utils:Prescription body) returns http:Response|error {
        return routes:createPrescription(req,body);
    }
    resource function get getAllMedicines(http:Request req) returns http:Response|error {
        return routes:getAllMedicinesDoctor(req);
    }
    resource function get getDoctor(http:Request req) returns http:Response|error {
        return routes:getDoctor(req);
    }

    resource function post getQueue(http:Request req,@http:Payload utils:DoctorGetQueue body) returns http:Response|error {
        return routes:doctorGetQueue(req,body);
    }

    resource function get getAllAppoinments(http:Request req) returns http:Response|error {
        return routes:doctorGetAllAppoinments(req);
    }
}