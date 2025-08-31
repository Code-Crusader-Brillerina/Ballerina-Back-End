import Hospital.config;
// import ballerina/io;

import Hospital.db;
import Hospital.functions;
import Hospital.utils;

import ballerina/log;
import ballerina/http;
import ballerina/uuid;

configurable string stripeSecretKey = ?;

public function updatePatient(http:Request req, utils:PatientUpdateBody body) returns http:Response|error {
    // get email
    // remove email
    // remove email
    // cheack email exist
    // if exist add email again and remove the error
    // if not exist add new data to users
    // add data to patients
    // update the token

    var uid = config:autheriseAs(req, "patient");
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

    var newUser = db:updateUser(uid.toString(), body.userData);
    if newUser is error {
        return config:createresponse(false, newUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // add data to doctors
    var newpatient = db:updatePatient(uid.toString(), body.patientData);
    if newpatient is error {
        return config:createresponse(false, newpatient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // update the token
    var token = functions:updateJWT(uid.toString(), "patient", body.userData);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    http:Cookie cookie = new ("JWT", token, path = "/", secure = true);
    return config:createresponse(true, "Patient update successful.", body.toJson(), http:STATUS_OK, cookie);
}

public function getAllDoctors() returns http:Response|error {
    // get whole Doctor collection
    var documents = db:getAllDocumentsFromCollection("doctors");
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // get the username and profilepictures from user collection role equal doctore
    json[] arr = [];
    foreach json item in documents {
        var did = check item.did;
        var user = check db:getDocument("users", {"uid": did});
        json obj = {
            did: did,
            specialization: check item.specialization,
            licenseNomber: check item.licenseNomber,
            experience: check item.experience,
            consultationFee: check item.consultationFee,
            availableTimes: check item.availableTimes,
            description: check item.description,
            username: check user.username,
            email:check user.email,
            profilepic: check user.profilepic
        };

        arr.push(obj.toJson());
    }
    // mach and return json object
    return config:createresponse(true, "Doctors details found successfully.", arr, http:STATUS_OK);
}

public function createAppointment(http:Request req, utils:Appoinment body) returns http:Response|error {
    // autherise as pationt and get the uid
    // add uid to the apoinment body to pid
    // save theapoinment on db

    // autherise as pationt and get the uid
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // add uid to the apoinment body to pid
    body.pid = uid.toString();

    var newAppoinment = db:insertOneIntoCollection("appoinments", body);
    if newAppoinment is error {
        return config:createresponse(false, newAppoinment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Appinment created successfully.", body.toJson(), http:STATUS_OK);
}

public function getQueue(utils:GetQueue body) returns http:Response|error {
    // get did
    // get date
    // find all the feilds in apoinment
    var documents = db:getDocumentList("appoinments", {did: body.did, date: body.date,time: body.time,paymentState:"paid"});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var queue =
    from var e in documents
    let int num = check e.number
    order by num ascending
    select e;
    return config:createresponse(true, "Details found successfully.", queue, http:STATUS_OK);

}

public function updateAppoinmentPayment(http:Request req, @http:Payload utils:UpdateAppoinmentPayment body) returns http:Response|error {
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var newvalue = db:updateDocument("appoinments", {"aid": body.aid}, {"paymentState": "paid"});
    if newvalue is error {
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Appoinment Payment status updated succesfully.", body.toJson(), http:STATUS_OK);
}

public function getPrescription(http:Request req, utils:GetPrescription body) returns error|http:Response {
    // get pid from token
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // get prescription from db
    var prescription = db:getDocument("prescriptions", {"preId": body.preId});
    if prescription is error {
        return config:createresponse(false, prescription.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if prescription is () {
        return config:createresponse(false, "Prescription not found.", {}, http:STATUS_NOT_FOUND);
    }

    // --- START OF THE FIX ---

    // Get related pharmacy data conditionally
    json|error phIdResult = prescription.phId;
    json pharmacyData;

    if phIdResult is string && phIdResult != "N/A" {
        // If there's a real pharmacy ID, try to fetch it
        var pharmacyDoc = db:getDocument("pharmacies", {"phId": phIdResult});
        if pharmacyDoc is error || pharmacyDoc is () {
            // If the pharmacy is not found for a given ID, log it and use a placeholder
            log:printWarn("Pharmacy not found for phId: " + phIdResult);
            pharmacyData = {"name": "Pharmacy Not Found"};
        } else {
            pharmacyData = pharmacyDoc;
        }
    } else {
        // If phId is "N/A" or missing, create a placeholder object for the frontend
        pharmacyData = {"name": "Not Assigned Yet", "phId": "N/A"};
    }

    // --- END OF THE FIX ---

    // get patient user data
    var user = db:getDocument("users", {"uid": check prescription.pid});
    if user is error || user is () {
        return config:createresponse(false, "Patient user not found.", {}, http:STATUS_NOT_FOUND);
    }

    // Get patient profile data (gender, DOB)
    var patientProfile = db:getDocument("patients", {"pid": check prescription.pid});
    if patientProfile is error || patientProfile is () {
        return config:createresponse(false, "Patient profile not found.", {}, http:STATUS_NOT_FOUND);
    }

    // get appointment from db
    var appoinment = db:getDocument("appoinments", {"aid": check prescription.aid});
    if appoinment is error || appoinment is () {
        return config:createresponse(false, "Appointment not found.", {}, http:STATUS_NOT_FOUND);
    }

    // get the doctor user and profile data
    var doctorUser = db:getDocument("users", {"uid": check prescription.did});
    if doctorUser is error || doctorUser is () {
        return config:createresponse(false, "Doctor not found.", {}, http:STATUS_NOT_FOUND);
    }

    // Get doctor profile data (specialization, licenseNomber, etc.)
    var doctorProfile = db:getDocument("doctors", {"did": check prescription.did});
    if doctorProfile is error || doctorProfile is () {
        return config:createresponse(false, "Doctor profile not found.", {}, http:STATUS_NOT_FOUND);
    }

    // loop through items
    json[] arr = [];
    json[]? items = <json[]?>check prescription.items;
    if items is json[] {
        foreach json item in items {
            var mediId = check item.mediId;
            var medicine = check db:getDocument("medicines", {"mediId": mediId});
            if medicine is () {
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
    }

    json result = {
        preId: body.preId,
        patient: {
            name: check user.username,
            phoneNumber: check user.phoneNumber,
            email: check user.email,
            city: check user.city,
            district: check user.district,
            gender: check patientProfile.gender,
            DOB: check patientProfile.DOB
        },
        doctor: {
            name: check doctorUser.username,
            profilepic: check doctorUser.profilepic,
            specialization: check doctorProfile.specialization,
            licenseNomber: check doctorProfile.licenseNomber
        },
        appoinment: appoinment,
        dateTime: check prescription.dateTime,
        diliveryMethod: check prescription.diliveryMethod,
        pharmacy: pharmacyData, // Use the new, safe variable here
        status: check prescription.status,
        note: check prescription.note,
        items: arr
    };

    return config:createresponse(true, "Prescription found successfully.", result, http:STATUS_OK);
}

public function getAllAppoinments(http:Request req) returns error|http:Response {
    // get pid from token
    // get allapoinments relate to the uid
    // get doctors related to the apoinment 
    // send the result

    // get pid from token
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    // get allapoinments relate to the uid
    var documents = db:getDocumentList("appoinments", {pid: uid});
    if documents is error {
        return config:createresponse(false, documents.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] arr = [];
    foreach json item in documents {
        var did = check item.did;
        // --- FIX START ---
        var user = check db:getDocument("users", {"uid": did.toJson()}); // Explicitly cast 'did' to json
        var doctor = check db:getDocument("doctors", {"did": did.toJson()}); // Do the same for 'doctor'
        // --- FIX END ---

        // You should also check for `null` results from `getDocument`
        if user is null || doctor is null {
            // Handle cases where a related user or doctor is not found
            // This prevents future errors if data is inconsistent.
            continue; // Skip this appointment or return an error as appropriate
        }

        json obj = {
            aid: check item.aid,
            pid: uid,
            doctor: {
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
            date: check item.date,
            time: check item.time,
            status: check item.status,
            description: check item.description,
            reports: check item.reports,
            paymentState: check item.paymentState,
            number: check item.number,
            url: check item.url

        };

        arr.push(obj.toJson());
    }
    return config:createresponse(true, "Apoinments found succesfully.", arr, http:STATUS_OK);

}

public function getPatient(http:Request req) returns error|http:Response {
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var user = db:getDocument("users", {"uid": uid});
    if user is error {
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    var partient = db:getDocument("patients", {"pid": uid});
    if partient is error {
        return config:createresponse(false, partient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json result = {
        user: user,
        partient: partient
    };
    return config:createresponse(true, "Patient foud succesfully.", result, http:STATUS_OK);

}

public function getDoctorforPatient(http:Request req, utils:GetDoctor body) returns error|http:Response {
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    var user = db:getDocument("users", {"uid": body.did});
    if user is error {
        return config:createresponse(false, user.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    var doctor = db:getDocument("doctors", {"did": body.did});
    if doctor is error {
        return config:createresponse(false, doctor.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json result = {
        did: check user.uid,
        username: check user.username,
        email: check user.email,
        profilepic: check user.profilepic,

        specialization: check doctor.specialization,
        licenseNomber: check doctor.licenseNomber,
        experience: check doctor.experience,
        consultationFee: check doctor.consultationFee,
        availableTimes: check doctor.availableTimes,
        description: check doctor.description
    };
    return config:createresponse(true, "Doctor found succesfully.", result, http:STATUS_OK);

}
public function getAllPharmacis(http:Request req) returns http:Response|error {

    var pharmacyDocuments = db:getAllDocumentsFromCollection("pharmacies");
    if pharmacyDocuments is error {
        return config:createresponse(false, pharmacyDocuments.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] combinedPharmacies = [];
    foreach json pharmacyDoc in pharmacyDocuments {

        // Safely get the pharmacy ID (phId)
        var phId = pharmacyDoc?.phId;
        if phId !is string {
            log:printWarn("Skipping pharmacy document due to missing or invalid 'phId'", document = pharmacyDoc);
            continue; // Skip to the next pharmacy document
        }

        // Get the corresponding user document
        var userDoc = db:getDocument("users", {"uid": phId});
        if userDoc is error || userDoc is () {
            log:printWarn("Skipping pharmacy because a matching user document was not found", phId = phId);
            continue; // Skip if no user found or if there's a DB error
        }

        // --- SAFER FIELD ACCESS ---
        // Instead of using 'check' directly, safely extract each value.
        // The `?` is optional chaining, and `?: ""` provides a default value if the field is null.
        string|error name = pharmacyDoc?.name.ensureType(string);
        string|error contact = pharmacyDoc?.contactNomber.ensureType(string);
        string|error username = userDoc?.username.ensureType(string);
        string|error email = userDoc?.email.ensureType(string);
        string|error phone = userDoc?.phoneNumber.ensureType(string);
        string|error city = userDoc?.city.ensureType(string);
        string|error district = userDoc?.district.ensureType(string);
        json profilepic = check userDoc?.profilepic ?: ""; // Provide a default for optional fields

        // Check if any of the essential fields failed to be extracted
        if name is error || contact is error || username is error || email is error || phone is error || city is error || district is error {
             log:printWarn("Skipping pharmacy due to malformed data", phId = phId);
             continue;
        }

        // Now that all data is validated, create the combined object
        json combinedDoc = {
            phId: phId,
            name: name,
            contactNomber: contact,
            userDetails: {
                uid: phId, // We already have this
                username: username,
                email: email,
                phoneNumber: phone,
                city: city,
                district: district,
                profilepic: profilepic
            }
        };
        combinedPharmacies.push(combinedDoc);
    }

    return config:createresponse(true, "Pharmacies found successfully.", combinedPharmacies, http:STATUS_OK);
}

public function updatePrescriptionPharmacy(http:Request req, utils:UpdatePrescriptionPharmacy body) returns error|http:Response {
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    var newvalue = db:updateDocument("prescriptions", {"preId": body.preId}, {"phId": body.phId});
    if newvalue is error {
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Prescription pharmacy updated succesfully.", body.toJson(), http:STATUS_OK);
}

public function getAllPrescriptions(http:Request req) returns error|http:Response {
    // 1. Authorize patient
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // 2. Get all prescriptions for the patient
    var prescriptions = db:getDocumentList("prescriptions", {pid: uid});
    if prescriptions is error {
        return config:createresponse(false, prescriptions.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] allPrescriptions = [];

    foreach json prescriptionDoc in prescriptions {
        // --- START OF THE FIX ---

        // Get related pharmacy data conditionally
        json|error phIdResult = prescriptionDoc.phId;
        json pharmacyData;

        if phIdResult is string && phIdResult != "N/A" {
            // If there's a real pharmacy ID, try to fetch it
            var pharmacyDoc = db:getDocument("pharmacies", {"phId": phIdResult});
            if pharmacyDoc is error || pharmacyDoc is () {
                // If the pharmacy is not found for a given ID, log it and use a placeholder
                log:printWarn("Pharmacy not found for phId: " + phIdResult);
                pharmacyData = {"name": "Pharmacy Not Found"};
            } else {
                pharmacyData = pharmacyDoc;
            }
        } else {
            // If phId is "N/A" or missing, create a placeholder object for the frontend
            pharmacyData = {"name": "Not Assigned Yet", "phId": "N/A"};
        }

        // --- END OF THE FIX ---

        // Get other related data (appointment, doctor, etc.)
        var aid = check prescriptionDoc.aid;
        var appoinment = db:getDocument("appoinments", {"aid": aid});
        if appoinment is error || appoinment is () {
            return config:createresponse(false, "Appointment not found for a prescription.", {}, http:STATUS_NOT_FOUND);
        }

        var did = check prescriptionDoc.did;
        var doctorUser = db:getDocument("users", {"uid": did});
        if doctorUser is error || doctorUser is () {
            return config:createresponse(false, "Doctor user not found for a prescription.", {}, http:STATUS_NOT_FOUND);
        }
        
        // Loop through items to get medicine details (no changes here)
        json[] prescriptionItems = [];
        json[]? items = <json[]?>check prescriptionDoc.items;
        if items is json[] {
            foreach json item in items {
                var mediId = check item.mediId;
                var medicine = db:getDocument("medicines", {"mediId": mediId});
                if medicine is error || medicine is () {
                    return config:createresponse(false, "Medicine not found in prescription item.", {}, http:STATUS_NOT_FOUND);
                }
                json combinedItem = {
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
                prescriptionItems.push(combinedItem);
            }
        }

        // Construct the final prescription object with the safe pharmacyData
        json finalPrescription = {
            preId: check prescriptionDoc.preId,
            doctor: {
                name: check doctorUser.username,
                profilepic: check doctorUser.profilepic
            },
            appoinment: appoinment,
            dateTime: check prescriptionDoc.dateTime,
            diliveryMethod: check prescriptionDoc.diliveryMethod,
            pharmacy: pharmacyData, // Use the new, safe variable here
            status: check prescriptionDoc.status,
            note: check prescriptionDoc.note,
            items: prescriptionItems
        };

        allPrescriptions.push(finalPrescription);
    }

    return config:createresponse(true, "All prescriptions found successfully.", allPrescriptions, http:STATUS_OK);
}

public function getAppointmentDetailsById(http:Request req, string aid) returns http:Response|error {
    // 1. Authorize the patient
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // 2. Get the appointment details using the provided aid
    var appointment = db:getDocument("appoinments", {"aid": aid});
    if appointment is error {
        return config:createresponse(false, appointment.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if appointment is null {
        return config:createresponse(false, "Appointment not found.", {}, http:STATUS_NOT_FOUND);
    }

    // 3. Ensure the authenticated patient is the owner of this appointment
    var appointmentPid = check appointment.pid;
    if (appointmentPid != uid) {
        return config:createresponse(false, "Unauthorized access to appointment.", {}, http:STATUS_FORBIDDEN);
    }

    // 4. Get the doctor's details associated with this appointment
    var did = check appointment.did;
    var doctorUser = db:getDocument("users", {"uid": did});
    if doctorUser is error || doctorUser is null {
        return config:createresponse(false, "Doctor user not found.", {}, http:STATUS_NOT_FOUND);
    }
    var doctorDetails = db:getDocument("doctors", {"did": did});
    if doctorDetails is error || doctorDetails is null {
        return config:createresponse(false, "Doctor details not found.", {}, http:STATUS_NOT_FOUND);
    }

    // 5. Combine the data into a single JSON object
    json combinedDetails = {
        aid: check appointment.aid,
        pid: check appointment.pid,
        date: check appointment.date,
        time: check appointment.time,
        status: check appointment.status,
        description: check appointment.description,
        reports: check appointment.reports,
        paymentState: check appointment.paymentState,
        number: check appointment.number,
            url: check appointment.url,
        doctor: {
            did: did,
            name: check doctorUser.username,
            profilepic: check doctorUser.profilepic,
            specialization: check doctorDetails.specialization,
            licenseNomber: check doctorDetails.licenseNomber,
            experience: check doctorDetails.experience,
            consultationFee: check doctorDetails.consultationFee,
            availableTimes: check doctorDetails.availableTimes,
            description: check doctorDetails.description
        }
    };

    return config:createresponse(true, "Appointment details found successfully.", combinedDetails, http:STATUS_OK);
}

public function updateAppointmentStatusAndPayment(http:Request req, string aid) returns http:Response|error {
    // 1. Authorize the patient
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // 2. Get appointment details
    var appointment = db:getDocument("appoinments", {"aid": aid});
    if appointment is error || appointment is null {
        return config:createresponse(false, "Appointment not found.", {}, http:STATUS_NOT_FOUND);
    }

    // 3. Calculate the queue number based on already paid appointments
    var queue = db:getDocumentList("appoinments", {did: check appointment.did, date: check appointment.date, time: check appointment.'time, paymentState: "paid"});
    if queue is error {
        return config:createresponse(false, queue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    int queueNumber = queue.length() + 1;

    // 4. Generate a unique meeting URL
    string url = "https://meet.jit.si/" + uuid:createType1AsString();

    // 5. Define the updates
    map<json> updates = {
        status: "scheduled",
        paymentState: "paid",
        number: queueNumber,
        url: url
    };

    // 6. Update the document
    var result = db:updateDocument("appoinments", {"aid": aid, "pid": uid}, updates);
    if result is error {
        return config:createresponse(false, result.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    
    // 7. Retrieve the final updated appointment for the email
    var updatedAppointment = db:getDocument("appoinments", {"aid": aid});
    if updatedAppointment is error || updatedAppointment is null {
        return config:createresponse(false, "Updated appointment not found after update.", {}, http:STATUS_NOT_FOUND);
    }

    // --- EMAIL SENDING LOGIC ---
    var patientUser = db:getDocument("users", {"uid": uid});
    var doctorUser = db:getDocument("users", {"uid": check updatedAppointment.did});

    if patientUser is json && doctorUser is json {
        string patientName = check patientUser.username;
        string patientEmail = check patientUser.email;
        string doctorName = check doctorUser.username;
        string doctorEmail = check doctorUser.email;

        // CORRECTED: Call functions from the 'config' module
        json patientEmailContent = config:patientAppointmentConfirmationEmail(patientName, doctorName, <string>check updatedAppointment.date, <string>check updatedAppointment.'time, queueNumber, url);
        var patientEmailResult = functions:sendEmail(patientEmail, <string>check patientEmailContent.subject, <string>check patientEmailContent.message);
        if patientEmailResult is error {
            log:printError("Failed to send appointment confirmation to patient.", 'error = patientEmailResult);
        }

        // CORRECTED: Call functions from the 'config' module
        json doctorEmailContent = config:doctorAppointmentNotificationEmail(doctorName, patientName, <string>check updatedAppointment.date, <string>check updatedAppointment.'time, queueNumber, url);
        var doctorEmailResult = functions:sendEmail(doctorEmail, <string>check doctorEmailContent.subject, <string>check doctorEmailContent.message);
        if doctorEmailResult is error {
            log:printError("Failed to send appointment notification to doctor.", 'error = doctorEmailResult);
        }
    } else {
        log:printError("Could not fetch user details for email notification.", aid = aid);
    }

    // 8. Return a successful response
    return config:createresponse(true, "Appointment updated. Confirmation emails sent.", updatedAppointment, http:STATUS_OK);
}

public function calculatePrescriptionPrices(http:Request req, utils:CalculatePricesRequest body) returns http:Response|error {
    // 1. Authorize the patient and get their user ID.
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // Get logged-in user's location for sorting.
    var loggedInUserDetails = db:getDocument("users", {"uid": uid});
    if loggedInUserDetails is error || loggedInUserDetails is () {
        return config:createresponse(false, "Could not retrieve details for the logged-in user.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    string userCity = check loggedInUserDetails.city;
    string userDistrict = check loggedInUserDetails.district;

    // 2. Fetch the prescription.
    var prescription = db:getDocument("prescriptions", {"preId": body.preId});
    if prescription is error {
        return config:createresponse(false, prescription.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if prescription is () {
        return config:createresponse(false, "Prescription not found.", {}, http:STATUS_NOT_FOUND);
    }

    // 3. Verify ownership.
    if check prescription.pid != uid {
        return config:createresponse(false, "You are not authorized to access this prescription.", {}, http:STATUS_FORBIDDEN);
    }

    // 4. Get medicine items.
    json[]|error itemsResult = <json[]|error>prescription.items;
    if itemsResult is error || itemsResult.length() == 0 {
        return config:createresponse(false, "Prescription contains no items to price.", {}, http:STATUS_BAD_REQUEST);
    }
    json[] items = itemsResult;

    // 5. Get all pharmacies.
    var allPharmacies = db:getAllDocumentsFromCollection("pharmacies");
    if allPharmacies is error {
        return config:createresponse(false, allPharmacies.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // --- MODIFIED: Create three lists for the new sorting order ---
    json[] cityMatchPharmacies = [];
    json[] districtMatchPharmacies = [];
    json[] otherPharmacies = [];

    // 6. Loop through each pharmacy.
    foreach json pharmacy in allPharmacies {
        decimal totalPrice = 0.0;
        boolean canFulfill = true;
        json[] itemizedPrices = [];
        string phId = check pharmacy.phId;

        // 7. Check inventory for each required medicine.
        foreach json item in items {
            string mediId = check item.mediId;
            var inventoryItem = db:getDocument("pharmacyInventory", {"pharmacyId": phId, "medicineId": mediId});

            if inventoryItem is json && inventoryItem !is () {
                decimal price = check decimal:fromString(check inventoryItem.price);
                int quantity = check int:fromString(check item.quantity);
                decimal subTotal = price * quantity;
                totalPrice += subTotal;

                var medicineDetails = db:getDocument("medicines", {"mediId": mediId});
                if medicineDetails is error || medicineDetails is () {
                    canFulfill = false;
                    break;
                }
                itemizedPrices.push({
                    medicineName: check medicineDetails.name,
                    quantity: quantity,
                    unitPrice: price,
                    subTotal: subTotal
                });
            } else {
                canFulfill = false;
                break;
            }
        }

        // 8. If the pharmacy can fulfill the order, add it to the correct list for sorting.
        if canFulfill {
            var userDetails = db:getDocument("users", {"uid": phId});
            if userDetails is error || userDetails is () {
                continue;
            }
            json combinedPharmacyInfo = {
                phId: phId,
                name: check pharmacy.name,
                contactNomber: check pharmacy.contactNomber,
                email: check pharmacy.email,
                city: check userDetails.city,
                district: check userDetails.district,
                profilepic: check userDetails.profilepic
            };

            json resultItem = {
                pharmacyInfo: combinedPharmacyInfo,
                totalPrice: totalPrice,
                itemizedPrices: itemizedPrices
            };

            // --- MODIFIED: The new multi-level sorting logic ---
            if (check userDetails.city == userCity) { // City match implies district match
                cityMatchPharmacies.push(resultItem);
            } else if (check userDetails.district == userDistrict) {
                districtMatchPharmacies.push(resultItem);
            } else {
                otherPharmacies.push(resultItem);
            }
        }
    }

    // 9. --- NEW: Combine the three lists in the correct priority order. ---
    json[] finalSortedResults = [];
    finalSortedResults.push(...cityMatchPharmacies);
    finalSortedResults.push(...districtMatchPharmacies);
    finalSortedResults.push(...otherPharmacies);

    // 10. Return the final sorted list.
    return config:createresponse(true, "Prescription pricing calculated successfully.", finalSortedResults, http:STATUS_OK);
}


// in patient_routes.bal

public function updatePrescriptionStatus(http:Request req, utils:UpdatePrescriptionStatusBody body) returns http:Response|error {
    var uid = config:autheriseAs(req, "patient");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    var prescription = db:getDocument("prescriptions", {"preId": body.preId});
    if prescription is error {
        return config:createresponse(false, prescription.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if prescription is () {
        return config:createresponse(false, "Prescription not found.", {}, http:STATUS_NOT_FOUND);
    }

    if check prescription.pid != uid {
        return config:createresponse(false, "You are not authorized to update this prescription.", {}, http:STATUS_FORBIDDEN);
    }

    map<json> updates = {
        "diliveryMethod": "paid",
        "status": "order confirmed",
        "phId": body.phId
    };
    var result = db:updateDocument("prescriptions", {"preId": body.preId}, updates);

    if result is error {
        return config:createresponse(false, "Failed to update prescription status.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Prescription successfully confirmed and marked as paid.", {}, http:STATUS_OK);
}

public function createPaymentIntent(http:Request req, utils:PaymentIntentRequest payload) returns http:Response|error {
    // The stripeSecretKey is now a module-level variable, no need to declare it here.
    int amount = payload.amount;

    http:Client stripeApiClient = check new ("https://api.stripe.com");

    // Use the configurable variable directly
    http:Response|error paymentIntentResponse = stripeApiClient->post("/v1/payment_intents",
        string`amount=${amount}&currency=lkr`,
        {"Authorization": "Bearer " + stripeSecretKey, "Content-Type": "application/x-www-form-urlencoded"}
    );

    if paymentIntentResponse is http:Response {
        if paymentIntentResponse.statusCode == http:STATUS_OK {
            json|error responseBody = paymentIntentResponse.getJsonPayload();
            if responseBody is json {
                string|error clientSecret = responseBody.client_secret.ensureType(string);
                if clientSecret is string {
                    json clientSecretPayload = {"clientSecret": clientSecret};
                    return config:createresponse(true, "PaymentIntent created", clientSecretPayload, http:STATUS_OK);
                }
            }
        }
    }
    
    if paymentIntentResponse is error {
        log:printError("Failed to create PaymentIntent from Stripe", 'error = paymentIntentResponse);
    } else {
        log:printError("Stripe returned a non-OK response", 
            statusCode = paymentIntentResponse.statusCode, 
            responseBody = check paymentIntentResponse.getTextPayload()
        );
    }

    return config:createresponse(false, "Failed to create PaymentIntent", {}, http:STATUS_INTERNAL_SERVER_ERROR);
}

public function chat(utils:ChatBody body) returns http:Response|error {
    // get data
    json requiredData={};
    match body.requiredData {
        "getAllDetailsOfDoctors" => {
            requiredData=check functions:doctorDetailsForChat();
        }
        "getAllDetailsOfPharmacies" => {
            requiredData= check functions:pharmacyDetailsForChat();
        }
    }
    var answer =functions:genereteAnswer(body.question,requiredData);
    if answer is error {
        return config:createresponse(false, answer.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    return config:createresponse(true, "Answer genereted successful.", answer, http:STATUS_OK);

}
