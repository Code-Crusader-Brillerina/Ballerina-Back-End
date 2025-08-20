import Hospital.config;
import Hospital.db;
import Hospital.functions;
import Hospital.utils;

import ballerina/http;
// import ballerina/io;

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
    var documents = db:getDocumentList("appoinments", {did: uid, date: body.date,time:body.time});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // create que by sorting document
    var queue =
    from var e in documents
    let int num = check e.number
    order by num ascending
    select e;
    return config:createresponse(true, "Details found successfully.", queue, http:STATUS_OK);

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
        // Add error handling for each extraction
        json|error pidResult = item.pid;
        if pidResult is error {
            continue; // Skip this item if pid is missing
        }
        var pid = pidResult;
        
        var userResult = db:getDocument("users", {"uid": pid});
        if userResult is error {
            continue; // Skip this item if user not found
        }
        var user = userResult;
        
        var patientResult = db:getDocument("patients", {"pid": pid});
        if patientResult is error {
            continue; // Skip this item if patient not found
        }
        var patient = patientResult;
        
        // Create the response object with proper error handling
        json|error aidResult = item.aid;
        json|error dateResult = item.date;
        json|error timeResult = item.time;
        json|error statusResult = item.status;
        json|error descriptionResult = item.description;
        json|error reportsResult = item.reports;
        json|error paymentStateResult = item.paymentState;
        
        json|error usernameResult = user.username;
        json|error phoneNumberResult = user.phoneNumber;
        json|error cityResult = user.city;
        json|error profilepicResult = user.profilepic;
        
        json|error dobResult = patient.DOB;
        json|error genderResult = patient.gender;
        
        json obj = {
            aid: aidResult is json ? aidResult : "",
            did: uid,
            patient: {
                pid: pid,
                name: usernameResult is json ? usernameResult : "",
                phoneNumber: phoneNumberResult is json ? phoneNumberResult : "",
                city: cityResult is json ? cityResult : "",
                profilepic: profilepicResult is json ? profilepicResult : "",
                DOB: dobResult is json ? dobResult : "",
                gender: genderResult is json ? genderResult : ""
            },
            date: dateResult is json ? dateResult : "",
            time: timeResult is json ? timeResult : "",
            status: statusResult is json ? statusResult : "",
            description: descriptionResult is json ? descriptionResult : "",
            reports: reportsResult is json ? reportsResult : [],
            paymentState: paymentStateResult is json ? paymentStateResult : "",
            number: check item.number,
            url: check item.url
        };
        
        // Push the json object directly without .toJson()
        arr.push(obj);
    }
    
    return config:createresponse(true, "Appointments found successfully.", arr, http:STATUS_OK);
}
public function getAppoinment(http:Request req,utils:GetAppoinment body) returns error|http:Response{
    // get pid from token
    var uid = config:autheriseAs(req,"doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get prescription fron db
    var appoinment=  db:getDocument("appoinments",{"aid":body.aid});
    if appoinment is error{
        return config:createresponse(false, appoinment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Prescription found succesfully.", appoinment, http:STATUS_OK);

}
