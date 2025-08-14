import ballerina/http;

import Hospital.config;
import Hospital.utils;
import Hospital.routes;




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

service /admin on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow admin from Ballerina...";
    }
    resource function post addDoctor(http:Request req,@http:Payload utils:DoctorBody doctor) returns http:Response|error {
        return routes:addDoctor(req,doctor);
    }
resource function post addPharmacy(http:Request req, @http:Payload utils:PharmacyBody pharmacy) returns http:Response|error {
    return routes:addPharmacy(req, pharmacy);
}
    resource function get getAllPharmacies(http:Request req) returns http:Response|error {
        return routes:getAllPharmacies(req);
    }
    resource function post addMedicine(http:Request req,@http:Payload utils:Medicine medicine) returns http:Response|error {
        return routes:addMedicine(req,medicine);
    }
    resource function get getAllMedicines(http:Request req) returns http:Response|error {
        return routes:getAllMedicines(req);
    }

    resource function delete deleteDoctor(http:Request req,@http:Payload utils:DeleteDoctor body) returns http:Response|error {
        return routes:deleteDoctor(req,body);
    }
}