import ballerina/http;
// import ballerina/io;

import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function updatePatient(http:Request req,utils:PatientUpdateBody body) returns http:Response|error {
    // get email
    // remove email
    // remove email
    // cheack email exist
    // if exist add email again and remove the error
    // if not exist add new data to users
    // add data to patients
    // update the token

    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get email
    var existuser=db:getUserById(uid.toString());
    if existuser is error {
        return config:createresponse(false, existuser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if existuser is null {
        return config:createresponse(false, "User cannot fined.", {}, http:STATUS_NOT_FOUND);
    }
    var existMail=existuser.email;
    if existMail is error {
        return config:createresponse(false, existMail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // remove email
    var removeemail = db:removeOneFromDocument("users",{"uid":uid},{"email":""});
    if removeemail is error{
        return config:createresponse(false, removeemail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // cheack email exist
    var exist = db:isEmailExist(body.userData.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // if exist add email again and remove the error
    if exist is true {
        var addemail = db:updateDocument("users",{"uid":uid},{"email":existMail});
        if addemail is error{
            return config:createresponse(false, addemail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }
    

    var newUser =db:updateUser(uid.toString(),body.userData);
    if newUser is error{
        return config:createresponse(false, newUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // add data to doctors
    var newpatient = db:updatePatient(uid.toString(),body.patientData);
    if newpatient is error{
        return config:createresponse(false, newpatient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // update the token
    var token=functions:updateJWT(uid.toString(),"patient",body.userData);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    http:Cookie cookie = new ("JWT", token, path = "/");
    return config:createresponse(true, "Patient update successful.", body.toJson(), http:STATUS_OK,cookie);
}

public function getAllDoctors(http:Request req) returns http:Response|error{
    // get whole Doctor collection
    var documents =  db:getAllDocumentsFromCollection("doctors");
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // get the username and profilepictures from user collection role equal doctore
    json[] arr = [];
    foreach json item in documents {
        var did = check item.did;
        var user= check db:getDocument("users",{"uid":did});
        json obj = {
            did: did,
            specialization: check item.specialization,
            licenseNomber: check item.licenseNomber,
            experience: check item.experience,
            consultationFee: check item.consultationFee,
            availableTimes: check item.availableTimes,
            description: check item.description,
            username: check user.username,
            profilepic: check user.profilepic
        };

        arr.push(obj.toJson());
    }
    // mach and return json object
    return config:createresponse(true, "Doctors details found successfully.", arr, http:STATUS_OK);



}
