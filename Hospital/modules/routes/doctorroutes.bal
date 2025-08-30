import Hospital.config;
import Hospital.db;
import Hospital.functions;
import Hospital.utils;

import ballerina/http;

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

# Description.
#
# + req - parameter description  
# + body - parameter description
# + return - return value description
public function doctorGetQueue(http:Request req, utils:DoctorGetQueue body) returns http:Response|error {
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    // Get appointments for the doctor on specified date and time
    var documents = db:getDocumentList("appoinments", {did: uid, date: body.date, time: body.time});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    
    // Get patient and user data for each appointment
    json[] appointmentsWithPatients = [];
    
    foreach var appointment in documents {
        // Get patient data
        var patient = db:getDocument("patients", {"pid": check appointment.pid});
        if patient is error {
            return config:createresponse(false, patient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
        }
        if patient is null {
            return config:createresponse(false, "Patient not found.", {}, http:STATUS_NOT_FOUND);
        }
        
        // Get user data for the patient using pid
        var userResult = db:getDocument("users", {"uid": check patient.pid});
        json? user = ();
        
        if userResult is json {
            user = userResult;
        }
        // Note: If user not found, we continue without failing the request
        
        // Combine appointment and patient data, include user data if found
        json appointmentWithPatientAndUser = {
            "appointment": appointment,
            "patient": patient
        };
        
        // Add user data only if found
        if user is json {
            appointmentWithPatientAndUser = {
                "appointment": appointment,
                "patient": patient,
                "user": user
            };
        }
        appointmentsWithPatients.push(appointmentWithPatientAndUser);
    }
    
    return config:createresponse(true, "Queue details found successfully.", appointmentsWithPatients, http:STATUS_OK);
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
public function getAppoinment(http:Request req, utils:GetAppoinment body) returns error|http:Response {
    // get uid from token
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    // get appointment from db
    var appoinment = db:getDocument("appoinments", {"aid": body.aid});
    if appoinment is error {
        return config:createresponse(false, appoinment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if appoinment is null {
        return config:createresponse(false, "Appointment not found.", {}, http:STATUS_NOT_FOUND);
    }

    // Get patient data
    var patient = db:getDocument("patients", {"pid": check appoinment.pid});
    if patient is error {
        return config:createresponse(false, patient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if patient is null {
        return config:createresponse(false, "Patient not found.", {}, http:STATUS_NOT_FOUND);
    }
    
    // Get user data for the patient using pid
    var userResult = db:getDocument("users", {"uid": check appoinment.pid});
    json? user = ();
    
    if userResult is json {
        user = userResult;
    }
    // Note: If user not found, we continue without failing the request
    
    // Combine appointment and patient data, include user data if found
    json appointmentWithPatientAndUser = {
        "appointment": appoinment,
        "patient": patient
    };
    
    // Add user data only if found
    if user is json {
        appointmentWithPatientAndUser = {
            "appointment": appoinment,
            "patient": patient,
            "user": user
        };
    }

    return config:createresponse(true, "Appointment found successfully.", appointmentWithPatientAndUser, http:STATUS_OK);
}

public function getDoctorPrescription(http:Request req, utils:GetPrescription body) returns error|http:Response {
    // get pid from token
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // get prescription from db
    var prescription = db:getDocument("prescriptions", {"preId": body.preId});
    if prescription is error {
        return config:createresponse(false, prescription.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if prescription is null {
        return config:createresponse(false, "Prescription not found.", {}, http:STATUS_NOT_FOUND);
    }

    // get patient user data
    var user = db:getDocument("users", {"uid": check prescription.pid});
    if user is error {
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if user is null {
        return config:createresponse(false, "Patient user not found.", {}, http:STATUS_NOT_FOUND);
    }

    // Get patient profile data (gender, DOB)
    var patientProfile = db:getDocument("patients", {"pid": check prescription.pid});
    if patientProfile is error {
        return config:createresponse(false, patientProfile.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if patientProfile is null {
        return config:createresponse(false, "Patient profile not found.", {}, http:STATUS_NOT_FOUND);
    }

    // get appointment from db
    var appoinment = db:getDocument("appoinments", {"aid": check prescription.aid});
    if appoinment is error {
        return config:createresponse(false, appoinment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if appoinment is null {
        return config:createresponse(false, "Appointment not found.", {}, http:STATUS_NOT_FOUND);
    }

    // get pharmacy from db
    var pharmacy = db:getDocument("pharmacies", {"phId": check prescription.phId});
    if pharmacy is error {
        return config:createresponse(false, pharmacy.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if pharmacy is null {
        return config:createresponse(false, "Pharmacy not found.", {}, http:STATUS_NOT_FOUND);
    }

    // get the doctor user and profile data
    var doctorUser = db:getDocument("users", {"uid": check prescription.did});
    if doctorUser is error {
        return config:createresponse(false, doctorUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if doctorUser is null {
        return config:createresponse(false, "Doctor not found.", {}, http:STATUS_NOT_FOUND);
    }

    // Get doctor profile data (specialization, licenseNomber, etc.)
    var doctorProfile = db:getDocument("doctors", {"did": check prescription.did});
    if doctorProfile is error {
        return config:createresponse(false, doctorProfile.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if doctorProfile is null {
        return config:createresponse(false, "Doctor profile not found.", {}, http:STATUS_NOT_FOUND);
    }

    // loop through items
    json[] arr = [];
    json[] items = <json[]>check prescription.items;
    foreach json item in items {
        var mediId = check item.mediId;
        var medicine = check db:getDocument("medicines", {"mediId": mediId});
        if medicine is null {
            return config:createresponse(false, "Medicine not found.", {}, http:STATUS_NOT_FOUND);
        }
        json obj = {
            mediId: mediId,
            name: check medicine.name,
            strength: check medicine.strength,
            form: check medicine.form,
            preItemId: check item.preItemId,
            dosage: check item.dosage,
            frequency: check item.frequency,
            duration: check item.duration,
            quantity: check item.quantity,
            instructions: check item.instructions
        };
        arr.push(obj.toJson());
    }

    json result = {
        preId: body.preId,
        patient: {
            name: check user.username,
            phoneNumber: check user.phoneNumber,
            email: check user.email,
            city: check user.city,
            district: check user.district,
            gender: check patientProfile.gender, // Added patient gender
            DOB: check patientProfile.DOB // Added patient DOB
        },
        doctor: {
            name: check doctorUser.username,
            profilepic: check doctorUser.profilepic,
            specialization: check doctorProfile.specialization, // Added doctor specialization
            licenseNomber: check doctorProfile.licenseNomber // Added doctor license number
        },
        appoinment: appoinment,
        dateTime: check prescription.dateTime,
        diliveryMethod: check prescription.diliveryMethod,
        pharmacy: pharmacy,
        status: check prescription.status,
        note: check prescription.note,
        items: arr
    };

    return config:createresponse(true, "Prescription found successfully.", result, http:STATUS_OK);
}


// Paste this into your doctorroutes.bal file

public function getCompletedAppointmentRevenue(http:Request req) returns http:Response|error {
    // 1. Authorize as a doctor
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    string doctorId = uid.toString();

    // 2. Get the doctor's consultation fee
    var doctorDetails = db:getDocument("doctors", {"did": doctorId});
    if doctorDetails is error || doctorDetails is () {
        return config:createresponse(false, "Doctor details not found.", {}, http:STATUS_NOT_FOUND);
    }
    
    // --- START OF THE FIX ---
    // First, get the fee as a string because that's how it's stored in the DB.
    string feeString = check doctorDetails.consultationFee;
    
    // Then, parse the string to a decimal. This returns `decimal|error`.
    decimal|error consultationFeeResult = decimal:fromString(feeString);
    
    // Check if the conversion was successful. If not, the string was not a valid number.
    if consultationFeeResult is error {
        return config:createresponse(false, "Invalid consultation fee format for doctor.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // Now you have the correct decimal value.
    decimal consultationFee = consultationFeeResult;
    // --- END OF THE FIX ---


    // 3. Get all COMPLETED appointments for this doctor
    var completedAppointments = db:getDocumentList("appoinments", {"did": doctorId, "status": "completed"});
    if completedAppointments is error {
        return config:createresponse(false, completedAppointments.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // 4. Calculate totals using the correct fee
    decimal grandTotal = completedAppointments.length() * consultationFee;
    utils:AppointmentRevenueDetail[] detailedRevenue = [];

    foreach json app in completedAppointments {
        if app is map<json> {
            var aidResult = (check app.aid).cloneWithType(string);
            var dateResult = (check app.date).cloneWithType(string);

            if aidResult is string && dateResult is string {
                detailedRevenue.push({
                    aid: aidResult,
                    date: dateResult,
                    price: consultationFee // This will now have the correct value
                });
            }
        }
    }

    utils:DoctorFinancials financials = {
        grandTotal: grandTotal,
        detailedRevenue: detailedRevenue
    };

    return config:createresponse(true, "Completed revenue fetched successfully.", financials.toJson(), http:STATUS_OK);
}

public function getPendingAppointmentRevenue(http:Request req) returns http:Response|error {
    // 1. Authorize as a doctor
    var uid = config:autheriseAs(req, "doctor");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    string doctorId = uid.toString();

    // 2. Get the doctor's consultation fee
    var doctorDetails = db:getDocument("doctors", {"did": doctorId});
    if doctorDetails is error || doctorDetails is () {
        return config:createresponse(false, "Doctor details not found.", {}, http:STATUS_NOT_FOUND);
    }

    // --- START OF THE FIX ---
    // First, get the fee as a string because that's how it's stored in the DB.
    string feeString = check doctorDetails.consultationFee;
    
    // Then, parse the string to a decimal. This returns `decimal|error`.
    decimal|error consultationFeeResult = decimal:fromString(feeString);
    
    // Check if the conversion was successful. If not, the string was not a valid number.
    if consultationFeeResult is error {
        return config:createresponse(false, "Invalid consultation fee format for doctor.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // Now you have the correct decimal value.
    decimal consultationFee = consultationFeeResult;
    // --- END OF THE FIX ---

    // 3. Get all SCHEDULED (pending) appointments for this doctor
    var pendingAppointments = db:getDocumentList("appoinments", {"did": doctorId, "status": "scheduled"});
    if pendingAppointments is error {
        return config:createresponse(false, pendingAppointments.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // 4. Calculate totals using the correct fee
    decimal grandTotal = pendingAppointments.length() * consultationFee;
    utils:AppointmentRevenueDetail[] detailedRevenue = [];

    foreach json app in pendingAppointments {
        if app is map<json> {
            var aidResult = (check app.aid).cloneWithType(string);
            var dateResult = (check app.date).cloneWithType(string);

            if aidResult is string && dateResult is string {
                detailedRevenue.push({
                    aid: aidResult,
                    date: dateResult,
                    price: consultationFee // This will now have the correct value
                });
            }
        }
    }

    utils:DoctorFinancials financials = {
        grandTotal: grandTotal,
        detailedRevenue: detailedRevenue
    };

    return config:createresponse(true, "Pending revenue fetched successfully.", financials.toJson(), http:STATUS_OK);
}