import ballerina/http;
// import ballerina/io;

import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function addDoctor(http:Request req,utils:DoctorBody doctor) returns http:Response|error {
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
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


public function addPharmacy(http:Request req,utils:Pharmacy pharmacy) returns http:Response|error {
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    var newpharmacy = db:insertOneIntoCollection("pharmacies", pharmacy);
    if newpharmacy is error {
        return config:createresponse(false, newpharmacy.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Pharmacy added successfully.", pharmacy.toJson(), http:STATUS_CREATED);
}


