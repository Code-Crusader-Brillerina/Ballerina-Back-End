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
}