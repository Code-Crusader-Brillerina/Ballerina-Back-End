import Hospital.config;
import Hospital.db;
import Hospital.functions;
import Hospital.utils;

import ballerina/http;
import ballerina/io;

public function updateDoctor(http:Request req, utils:DoctorUpdateBody body) returns http:Response|error {
    // get email
    // remove email
    // remove email
    // cheack email exist
    // if exist add email again and remove the error
    // if not exist add new data to users
    // add data to doctors
    // update the token

    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // get email
    var existuser = db:getUserById(uid.toString());
    if existuser is error {
        return config:createresponse(false, existuser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if existuser is null {
        return config:createresponse(false, "User cannot fined.", {}, http:STATUS_NOT_FOUND);
    }
    var existMail = existuser.email;
    if existMail is error {
        return config:createresponse(false, existMail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // remove email
    var removeemail = db:removeOneFromDocument("users", {"uid": uid}, {"email": ""});
    if removeemail is error {
        return config:createresponse(false, removeemail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // cheack email exist
    var exist = db:isEmailExist(body.userData.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // if exist add email again and remove the error
    if exist is true {
        var addemail = db:updateDocument("users", {"uid": uid}, {"email": existMail});
        if addemail is error {
            return config:createresponse(false, addemail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }

    // if not exist add new data to users
    var newUser = db:updateUser(uid.toString(), body.userData);
    if newUser is error {
        return config:createresponse(false, newUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // add data to doctors
    var newdoctor = db:updateDoctor(uid.toString(), body.doctorData);
    if newdoctor is error {
        return config:createresponse(false, newdoctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // update the token
    var token = functions:updateJWT(uid.toString(), "doctor", body.userData);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ("JWT", token, path = "/", secure = true);
    return config:createresponse(true, "Patient update successful.", body.toJson(), http:STATUS_OK, cookie);
}

public function getDoctorHistory(http:Request req) returns http:Response|error {

    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    var documents = db:getDocumentList("appoinments", {did: uid});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Doctors history found successfully.", documents, http:STATUS_OK);
}

public function updateAppoinmentStatus(http:Request req, utils:UpdateAppoinmentStatus body) returns http:Response|error {

    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    var newvalue = db:updateDocument("appoinments", {"aid": body.aid}, {"status": body.status});
    if newvalue is error {
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Appoinment status updated succesfully.", body.toJson(), http:STATUS_OK);
}

public function createPrescription(http:Request req, utils:Prescription body) returns http:Response|error {

    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    body.did = uid.toString();
    var newPrescription = db:insertOneIntoCollection("prescriptions", body);
    if newPrescription is error {
        return config:createresponse(false, newPrescription.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Prescription created succesfully.", body.toJson(), http:STATUS_OK);
}

public function getAllMedicinesDoctor(http:Request req) returns http:Response|error {
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get whole Doctor collection
    var documents = db:getAllDocumentsFromCollection("medicines");
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // mach and return json object
    return config:createresponse(true, "Medicine details found successfully.", documents, http:STATUS_OK);
}

public function getDoctor(http:Request req) returns error|http:Response {
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var user = db:getDocument("users", {"uid": uid});
    if user is error {
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    var doctor = db:getDocument("doctors", {"did": uid});
    if doctor is error {
        return config:createresponse(false, doctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json result = {
        user: user,
        doctor: doctor
    };
    return config:createresponse(true, "Prescription foound succesfully.", result, http:STATUS_OK);

}

public function doctorGetQueue(http:Request req, utils:DoctorGetQueue body) returns http:Response|error {
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get did
    // get date
    // find all the feilds in apoinment
    var documents = db:getDocumentList("appoinments", {did: uid, date: body.date});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Details found successfully.", documents, http:STATUS_OK);

}

public function doctorGetAllAppoinments(http:Request req) returns error|http:Response {
    // get pid from token
    // get allapoinments relate to the uid
    // get doctors related to the apoinment 
    // send the result

    // get pid from token
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get allapoinments relate to the uid
    var documents = db:getDocumentList("appoinments", {did: uid});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] arr = [];
    foreach json item in documents {
        var pid = check item.pid;
        var user = check db:getDocument("users", {"uid": pid});
        io:println(user);
        var patient = check db:getDocument("patients", {"pid": pid});
        io:println(patient);
        json obj = {
            aid: check item.aid,
            did: uid,
            patient: {
                pid: pid,
                name: check user.username,
                phoneNumber: check user.phoneNumber,
                city: check user.city,
                profilepic: check user.profilepic,
                DOB: check patient.DOB,
                gender: check patient.gender
            },
            date: check item.date,
            time: check item.time,
            status: check item.status,
            description: check item.description,
            reports: check item.reports,
            paymentState: check item.paymentState

        };

        arr.push(obj.toJson());
    }
    return config:createresponse(true, "Apoinments found succesfully.", arr, http:STATUS_OK);

}
