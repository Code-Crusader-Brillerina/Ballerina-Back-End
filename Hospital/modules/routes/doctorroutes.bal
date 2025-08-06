import ballerina/http;
// import ballerina/io;

import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function updateDoctor(http:Request req,utils:DoctorUpdateBody body) returns http:Response|error {
    // get email
    // remove email
    // remove email
    // cheack email exist
    // if exist add email again and remove the error
    // if not exist add new data to users
    // add data to doctors
    // update the token


    var uid = config:autheriseAs(req,"doctor");
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

    // add data to doctors
    var newdoctor = db:updateDocument("doctors",{"did":uid},{
        "specialization":body.doctorData.specialization,
        "licenseNomber":body.doctorData.licenseNomber,
        "experience":body.doctorData.experience,
        "consultationFee":body.doctorData.consultationFee,
        "availableTimes":body.doctorData.availableTimes,
        "description":body.doctorData.description
    });
    if newdoctor is error{
        return config:createresponse(false, newdoctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
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
