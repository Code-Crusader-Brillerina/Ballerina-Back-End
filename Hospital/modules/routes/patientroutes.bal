import ballerina/http;
// import ballerina/io;

import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function updatePatient(http:Request req,utils:PatientUpdateBody body) returns http:Response|error {
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
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
        var addemail = db:updateDocument("users",{"uid":uid},{"email":body.userData.email});
        if addemail is error{
            return config:createresponse(false, addemail.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }
    // if not exist add new data to users
    
    var newuser = db:updateDocument("users",{"uid":uid},{
        "email":body.userData.email,
        "username":body.userData.username,
        "phoneNumber":body.userData.phoneNumber,
        "city":body.userData.city,
        "district":body.userData.district,
        "profilepic":body.userData.profilepic
    });
    if newuser is error{
        return config:createresponse(false, newuser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // add data to patiend
    var newpatient = db:updateDocument("patients",{"pid":uid},{
        "DOB":body.patientData.DOB,
        "gender":body.patientData.gender
    });
    if newpatient is error{
        return config:createresponse(false, newpatient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // update the token
    utils:User user={
        username: body.userData.username,
        email: body.userData.email,
        uid: uid.toString(),
        password: "",
        role:"patient",
        phoneNumber:"",
        city:"",
        district:"",
        profilepic:""

    };
    var token=functions:crateJWT(user);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ("JWT", token, path = "/");
    return config:createresponse(true, "Patient update successful.", body.toJson(), http:STATUS_OK,cookie);
}
