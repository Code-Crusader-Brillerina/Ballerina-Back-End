import ballerina/http;
import ballerina/uuid;
// import ballerina/io;
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


public function addPharmacy(http:Request req, utils:PharmacyBody pharmacy) returns http:Response|error {
    // Authorize as admin
    var uid = config:autheriseAs(req, "admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    // Check if the user email already exists
    var exist = db:isEmailExist(pharmacy.userData.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if exist is true {
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }

    // --- Start of Changes ---

    // 1. Generate a new unique ID
    string newSharedId = uuid:createType1AsString();

    // 2. Assign the SAME ID to both records using their respective field names
    pharmacy.pharmacyData.phId = newSharedId; // Use phId for PharmacyData
    pharmacy.userData.uid = newSharedId;      // Use uid for UserData

    // --- End of Changes ---

    // Hash the password and set the role
    pharmacy.userData.password = functions:hashPassword(pharmacy.userData.password);
    pharmacy.userData.role = "pharmacy";

    // Insert user data into the 'users' collection
    var newUser = db:insertOneIntoCollection("users", pharmacy.userData);
    if newUser is error {
        return config:createresponse(false, newUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Insert pharmacy-specific data into the 'pharmacies' collection
    var newPharmacy = db:insertOneIntoCollection("pharmacies", pharmacy.pharmacyData);
    if newPharmacy is error {
        return config:createresponse(false, newPharmacy.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Return a success response
    return config:createresponse(true, "Pharmacy and user added successfully.", pharmacy.toJson(), http:STATUS_CREATED);
}


public function getAllPharmacies(http:Request req) returns http:Response|error{
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get whole Doctor collection
    var documents =  db:getAllDocumentsFromCollection("pharmacies");
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // mach and return json object
    return config:createresponse(true, "Pharmacy details found successfully.", documents, http:STATUS_OK);
}


public function addMedicine(http:Request req,utils:Medicine medicine) returns http:Response|error {
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    var newmedicine = db:insertOneIntoCollection("medicines", medicine);
    if newmedicine is error {
        return config:createresponse(false, newmedicine.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Medicine added successfully.", medicine.toJson(), http:STATUS_CREATED);
}

public function getAllMedicines(http:Request req) returns http:Response|error{
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get whole Doctor collection
    var documents =  db:getAllDocumentsFromCollection("medicines");
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // mach and return json object
    return config:createresponse(true, "Medicine details found successfully.", documents, http:STATUS_OK);
}

public function allGetDoctors(http:Request req) returns http:Response|error{
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get whole Doctor collection
    var documents =  db:getAllDocumentsFromCollection("doctors");
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // mach and return json object
    return config:createresponse(true, "Doctor details found successfully.", documents, http:STATUS_OK);
}

public function getAllPatient(http:Request req) returns http:Response|error{
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get whole Doctor collection
    var documents =  db:getAllDocumentsFromCollection("patients");
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // mach and return json object
    return config:createresponse(true, "Patient details found successfully.", documents, http:STATUS_OK);
}


public  function deleteDoctor(http:Request req,utils:DeleteDoctor body) returns http:Response|error {
    // get body
    // delete row
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var doctor =  db:deleteDocument("doctors",{did:body.did});
    if doctor is error{
        return config:createresponse(false, doctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var user =  db:deleteDocument("users",{uid:body.did});
    if user is error{
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Medicine details found successfully.", doctor.toJson(), http:STATUS_OK);
}

public  function deletePharmacy(http:Request req,utils:DeletePharmacy body) returns http:Response|error {
    // get body
    // delete row
    var uid = config:autheriseAs(req,"admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var pharmacies =  db:deleteDocument("pharmacies",{phId:body.phId});
    if pharmacies is error{
        return config:createresponse(false, pharmacies.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Medicine details found successfully.", pharmacies.toJson(), http:STATUS_OK);
}