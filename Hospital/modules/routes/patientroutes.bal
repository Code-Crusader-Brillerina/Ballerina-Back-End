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

public function createAppointment(http:Request req,utils:Appoinment body) returns http:Response|error {
    // autherise as pationt and get the uid
    // add uid to the apoinment body to pid
    // save theapoinment on db

    // autherise as pationt and get the uid
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // add uid to the apoinment body to pid
    body.pid=uid.toString();

    var newAppoinment = db:insertOneIntoCollection("appoinments", body);
    if newAppoinment is error {
        return config:createresponse(false, newAppoinment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Appinment created successfully.", body.toJson(), http:STATUS_OK);
}

public function getQueue(utils:GetQueue body) returns http:Response|error{
    // get did
    // get date
    // find all the feilds in apoinment
    var documents =  db:getDocumentList("appoinments",{did:body.did,date:body.date});
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Doctors details found successfully.", documents, http:STATUS_OK);
    
}



public function updateAppoinmentPayment(http:Request req,@http:Payload utils:UpdateAppoinmentPayment body) returns http:Response|error {
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var newvalue = db:updateDocument("appoinments",{"aid":body.aid},{"paymentState":"paid"});
    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Appoinment Payment status updated succesfully.", body.toJson(), http:STATUS_OK);
}


public function getPrescription(http:Request req,utils:GetPrescription body) returns error|http:Response{
    // get pid from token
    // get prescription fron db
    // get appoinment from db
    // get pharmacy from db
    // loop throug items
        // get medicine from database
        // create finel data
    
    // get pid from token
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get prescription fron db
    var prescription=  db:getDocument("prescriptions",{"preId":body.preId});
    if prescription is error{
        return config:createresponse(false, prescription.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // get appoinment from db
    var appoinment=  db:getDocument("appoinments",{"aid":check prescription.aid});
    if appoinment is error{
        return config:createresponse(false, appoinment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // get pharmacy from db
    var pharmacy=  db:getDocument("pharmacies",{"phId":check prescription.phId});
    if pharmacy is error{
        return config:createresponse(false, pharmacy.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // get the doctor
    var doctor=  db:getDocument("users",{"uid":check prescription.did});
    if doctor is error{
        return config:createresponse(false, doctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
  

    // loop throug items
    json[] arr = [];
    json[] items = <json[]> check  prescription.items;
    foreach json item in items {
        var mediId = check item.mediId;
        var medicine= check db:getDocument("medicines",{"mediId":mediId});
        json obj = {
            mediId: mediId,
            name:check medicine.name,
            strength:check medicine.strength,
            form:check medicine.form,

            preItemId:check item.preItemId,
            dosage:check item.dosage,
            frequency:check item.frequency,
            duration:check item.duration,
            quantity:check item.quantity,
            instructions:check item.instructions
        };

        arr.push(obj.toJson());
    }

    json result = {
        preId:body.preId,
        pid:check prescription.pid,

        doctor:{
            name:check doctor.username,
            profilepic:check doctor.profilepic
        },

        appoinment:appoinment,

        dateTime:check prescription.dateTime,
        diliveryMethod:check prescription.diliveryMethod,

        pharmacy:pharmacy,

        status:check prescription.status,
        note:check prescription.note,

        items:arr
    };

    return config:createresponse(true, "Prescription found succesfully.", result, http:STATUS_OK);

}

public function getAllAppoinments(http:Request req) returns error|http:Response{
    // get pid from token
    // get allapoinments relate to the uid
    // get doctors related to the apoinment 
    // send the result

    // get pid from token
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get allapoinments relate to the uid
    var documents =  db:getDocumentList("appoinments",{pid:uid});
    if documents is error{
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] arr = [];
    foreach json item in documents {
        var did = check item.did;
        var user= check db:getDocument("users",{"uid":did});
        var doctor= check db:getDocument("doctors",{"did":did});
        json obj = {
            aid:check item.aid,
            pid:uid,
            doctor:{
                did: did,
                name: check user.username,
                profilepic: check user.profilepic,
                specialization: check doctor.specialization,
                licenseNomber: check doctor.licenseNomber,
                experience: check doctor.experience,
                consultationFee: check doctor.consultationFee,
                availableTimes: check doctor.availableTimes,
                description: check doctor.description
            },
            date:check item.date,
            time:check item.time,
            status:check item.status,
            description:check item.description,
            reports:check item.reports,
            paymentState:check item.paymentState
            
        };

        arr.push(obj.toJson());
    }
    return config:createresponse(true, "Apoinments found succesfully.", arr, http:STATUS_OK);

}

public function getPatient(http:Request req) returns error|http:Response{
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var user=  db:getDocument("users",{"uid":uid});
    if user is error{
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    var partient=  db:getDocument("patients",{"pid":uid});
    if partient is error{
        return config:createresponse(false, partient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json result={
        user:user,
        partient:partient
    };
    return config:createresponse(true, "Patient foud succesfully.", result, http:STATUS_OK);

}


public function getDoctorforPatient(http:Request req,utils:GetDoctor body)returns error|http:Response{
    var uid = config:autheriseAs(req,"patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var user=  db:getDocument("users",{"uid":body.did});
    if user is error{
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    var doctor=  db:getDocument("doctors",{"did":body.did});
    if doctor is error{
        return config:createresponse(false, doctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json result={
        did:check user.uid ,
        username:check user.username ,
        email:check user.email ,
        profilepic:check user.profilepic ,

        specialization:check doctor.specialization ,
        licenseNomber:check doctor.licenseNomber ,
        experience:check doctor.experience ,
        consultationFee:check doctor.consultationFee ,
        availableTimes:check doctor.availableTimes ,
        description:check doctor.description 
    };
    return config:createresponse(true, "Prescription foound succesfully.", result, http:STATUS_OK);

}