import ballerina/http;
import ballerina/uuid;
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
    json getEmail=config:addDoctorEmail(doctor.userData.username,doctor.userData.email,"111");
    var issent=functions:sendEmail(doctor.userData.email,check getEmail.subject,check getEmail.message);
    if issent is error{
        return config:createresponse(false, issent.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
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

    json getEmail=config:addDoctorEmail(pharmacy.userData.username,pharmacy.userData.email,"111");
    var issent=functions:sendEmail(pharmacy.userData.email,check getEmail.subject,check getEmail.message);
    if issent is error{
        return config:createresponse(false, issent.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
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

public function getAllPatient(http:Request req) returns http:Response|error {
    var uid = config:autheriseAs(req, "admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    // Get whole Patient collection
    var documents = db:getAllDocumentsFromCollection("patients");
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Enrich each patient with their corresponding user data
    json[] enrichedPatients = [];
    
    foreach json patientJson in <json[]>documents {
        // Convert json to map<json> for easier manipulation
        map<json> patient = <map<json>>patientJson;
        map<json> enrichedPatient = patient.clone();
        
        // Get the pid from patient data
        json|error pidResult = patient["pid"];
        if pidResult is json {
            // Find the corresponding user where uid matches pid
            var userResult = db:getDocument("users", {"uid": pidResult});
            if userResult is json {
                // Add user data to the patient record
                enrichedPatient["userData"] = userResult;
            } else {
                // If no user found, add null or empty object
                enrichedPatient["userData"] = ();
            }
        } else {
            enrichedPatient["userData"] = ();
        }
        
        enrichedPatients.push(enrichedPatient);
    }
    
    return config:createresponse(true, "Patient details with user data found successfully.", enrichedPatients, http:STATUS_OK);
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

public function adminGetAllAppoinments(http:Request req) returns error|http:Response {
    // Authorize as admin
    var uid = config:autheriseAs(req, "admin");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    // Get ALL appointments (not filtered by doctor ID since this is admin endpoint)
    var documents = db:getAllDocumentsFromCollection("appoinments");
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    
    json[] arr = [];
    foreach json item in documents {
        // Extract appointment data with error handling
        json|error aidResult = item.aid;
        json|error didResult = item.did;  // Get the doctor ID from appointment
        json|error pidResult = item.pid;
        json|error dateResult = item.date;
        json|error timeResult = item.time;
        json|error statusResult = item.status;
        json|error descriptionResult = item.description;
        json|error reportsResult = item.reports;
        json|error paymentStateResult = item.paymentState;
        json|error numberResult = item.number;
        json|error urlResult = item.url;
        
        // Skip if essential data is missing
        if pidResult is error || didResult is error {
            continue;
        }
        
        var pid = pidResult;
        var did = didResult;
        
        // Get patient user data
        var userResult = db:getDocument("users", {"uid": pid});
        if userResult is error {
            continue; // Skip this appointment if user not found
        }
        var user = userResult;
        
        // Get patient data
        var patientResult = db:getDocument("patients", {"pid": pid});
        if patientResult is error {
            continue; // Skip this appointment if patient not found
        }
        var patient = patientResult;
        
        // Get doctor data for this appointment
        var doctorResult = db:getDocument("doctors", {"did": did});
        json doctorData = {};
        if doctorResult is json {
            doctorData = doctorResult;
        }
        
        // Get doctor user data
        var doctorUserResult = db:getDocument("users", {"uid": did});
        json doctorUserData = {};
        if doctorUserResult is json {
            doctorUserData = doctorUserResult;
        }
        
        // Extract user data with error handling
        json|error usernameResult = user.username;
        json|error phoneNumberResult = user.phoneNumber;
        json|error cityResult = user.city;
        json|error profilepicResult = user.profilepic;
        
        // Extract patient data with error handling
        json|error dobResult = patient.DOB;
        json|error genderResult = patient.gender;
        
        // Extract doctor user data with error handling
        json|error doctorNameResult = doctorUserData.username;
        json|error doctorEmailResult = doctorUserData.email;
        
        // Extract doctor specific data
        json|error specializationResult = doctorData.specialization;
        json|error experienceResult = doctorData.experience;
        
        json obj = {
            aid: aidResult is json ? aidResult : "",
            appointment: {
                date: dateResult is json ? dateResult : "",
                time: timeResult is json ? timeResult : "",
                status: statusResult is json ? statusResult : "",
                description: descriptionResult is json ? descriptionResult : "",
                reports: reportsResult is json ? reportsResult : [],
                paymentState: paymentStateResult is json ? paymentStateResult : "",
                number: numberResult is json ? numberResult : "",
                url: urlResult is json ? urlResult : ""
            },
            patient: {
                pid: pid,
                name: usernameResult is json ? usernameResult : "",
                phoneNumber: phoneNumberResult is json ? phoneNumberResult : "",
                city: cityResult is json ? cityResult : "",
                profilepic: profilepicResult is json ? profilepicResult : "",
                DOB: dobResult is json ? dobResult : "",
                gender: genderResult is json ? genderResult : ""
            },
            doctor: {
                did: did,
                name: doctorNameResult is json ? doctorNameResult : "",
                email: doctorEmailResult is json ? doctorEmailResult : "",
                specialization: specializationResult is json ? specializationResult : "",
                experience: experienceResult is json ? experienceResult : ""
            }
        };
        
        arr.push(obj);
    }
    
    return config:createresponse(true, "All appointments found successfully.", arr, http:STATUS_OK);
}