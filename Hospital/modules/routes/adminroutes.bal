import ballerina/http;
// import ballerina/io;

import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function addDoctor(http:Request req,utils:DoctorBody doctor) returns http:Response|error {
    var auth = config:autherise(req);
    if auth is error {
        return config:createresponse(false, auth.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    if auth.role != "admin" {
        return config:createresponse(false, "You need admin privilagers to access to this properties.", {}, http:STATUS_UNAUTHORIZED);
    }
    var exist = db:isEmailExist(doctor.userData.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if exist is true {
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }

    doctor.userData.password = functions:hashPassword(doctor.userData.password);
    var newrec = db:insertOneIntoCollection("users", doctor.userData);
    if newrec is error {
        return config:createresponse(false, newrec.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var newrecforDoctor = db:insertOneIntoCollection("doctors", doctor.doctorData);
    if newrecforDoctor is error {
        return config:createresponse(false, newrecforDoctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Doctor registered successfully.", doctor.toJson(), http:STATUS_CREATED);
}