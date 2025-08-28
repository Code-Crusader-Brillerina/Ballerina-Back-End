import Hospital.config;
import Hospital.db;
import Hospital.utils;
import Hospital.functions;

import ballerina/http;

// Your existing addInventory function...
public function addInventory(http:Request req, utils:AddInventoryBody body) returns http:Response|error {
    // 1. Authorize and get pharmacy ID (uid) directly from the JWT token.
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // 2. Use the authenticated 'uid' as the pharmacyId.
    //    The 'pharmacyId' from the request body is no longer used.
    string pharmacyId = uid.toString();
    string inventoryId = pharmacyId + "_" + body.medicineId;

    // 3. Create the document using the authenticated pharmacyId.
    utils:PharmacyInventory inventoryDocument = {
        inventoryId: inventoryId,
        pharmacyId: pharmacyId, // Use the ID from the token
        medicineId: body.medicineId,
        availableState: body.inventoryData.availableState,
        price: body.inventoryData.price,
        latestUpdate: body.inventoryData.latestUpdate
    };

    var insertResult = db:insertOneIntoCollection("pharmacyInventory", inventoryDocument);
    if insertResult is error {
        return config:createresponse(false, insertResult.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Pharmacy inventory added successfully.", inventoryDocument.toJson(), http:STATUS_OK);
}

public function getMyInventory(http:Request req) returns http:Response|error {
    // ... (code before the loop is correct)
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    string pharmacyId = uid.toString();
    var inventoryDocs = db:getDocumentList("pharmacyInventory", {"pharmacyId": pharmacyId});
    if inventoryDocs is error {
        return config:createresponse(false, inventoryDocs.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] combinedInventory = [];

    foreach json inventoryItem in inventoryDocs {
        if inventoryItem !is map<json> {
            continue;
        }

        var medicineIdResult = inventoryItem?.medicineId;
        if medicineIdResult !is string {
            continue;
        }
        string medicineId = medicineIdResult;

        // FIX: Change "medicineId" to "mediId" to match your database field name.
        var medicineDetails = db:getDocument("medicines", {"mediId": medicineId});

        json combinedItem = {
            inventoryId: check inventoryItem.inventoryId,
            pharmacyId: check inventoryItem.pharmacyId,
            medicineId: medicineId,
            availableState: check inventoryItem.availableState,
            price: check inventoryItem.price,
            latestUpdate: check inventoryItem.latestUpdate,
            name: medicineDetails is map<json> ? (check medicineDetails.name) : "Unknown Medicine",
            form: medicineDetails is map<json> ? (check medicineDetails.form) : "-"
        };
        combinedInventory.push(combinedItem);
    }

    return config:createresponse(true, "Inventory fetched successfully.", combinedInventory, http:STATUS_OK);
}

// NEW FUNCTION: Update an inventory item
public function updateInventory(http:Request req, string inventoryId, utils:AddInventoryBody body) returns http:Response|error {
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // Prepare the update payload from the request body's inventoryData
    map<json> updates = {
        "availableState": body.inventoryData.availableState,
        "price": body.inventoryData.price,
        "latestUpdate": body.inventoryData.latestUpdate
    };

    var result = db:updateDocument("pharmacyInventory", {"inventoryId": inventoryId}, updates);
    if result is error {
        return config:createresponse(false, result.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Inventory updated successfully.", {}, http:STATUS_OK);
}

// NEW FUNCTION: Delete an inventory item
public function deleteInventory(http:Request req, string inventoryId) returns http:Response|error {
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    var result = db:deleteDocument("pharmacyInventory", {"inventoryId": inventoryId});
    if result is error {
        return config:createresponse(false, result.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Inventory item deleted successfully.", {}, http:STATUS_OK);
}

public function getAllMedicinesForPharmacy(http:Request req) returns http:Response|error {
    // 1. Authorize the user as a pharmacy.
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // 2. Fetch all documents from the master 'medicines' collection.
    var allMedicines = db:getAllDocumentsFromCollection("medicines");
    if allMedicines is error {
        return config:createresponse(false, allMedicines.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // 3. Create a simplified list containing only the ID and name for the frontend.
    json[] simplifiedMedicines = [];
    foreach json medicine in allMedicines {
        json simplifiedItem = {
            mediId: check medicine.mediId,
            name: check medicine.name
        };
        simplifiedMedicines.push(simplifiedItem);
    }

    return config:createresponse(true, "Master medicine list fetched successfully.", simplifiedMedicines, http:STATUS_OK);
}



public function getPrescriptionsForPharmacy(http:Request req) returns http:Response|error {
    // 1. Authorize the request and get the pharmacy's ID (uid) from the JWT token.
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    string pharmacyId = uid.toString();

    // 2. Fetch all prescriptions where 'phId' matches the logged-in pharmacy's ID.
    var prescriptionDocs = db:getDocumentList("prescriptions", {"phId": pharmacyId});
    if prescriptionDocs is error {
        return config:createresponse(false, prescriptionDocs.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] enrichedPrescriptions = [];

    // 3. Loop through each prescription to fetch and attach patient details.
    foreach json prescription in prescriptionDocs {
        if prescription !is map<json> {
            continue; // Skip malformed prescription data
        }

        var patientIdResult = prescription?.pid;
        if patientIdResult !is string {
            continue; // Skip if patient ID is missing
        }
        string patientId = patientIdResult;

        // Fetch the patient's user data (for name, contact, location)
        var userDetails = db:getDocument("users", {"uid": patientId});
        // Fetch the patient's profile data (for DOB and gender)
        var patientDetails = db:getDocument("patients", {"pid": patientId});

        int age = -1; // Default age if DOB is not found or invalid
        if patientDetails is map<json> {
            var dobResult = patientDetails?.DOB;
            if dobResult is string {
                var calculatedAge = functions:calculateAge(dobResult);
                if calculatedAge is int {
                    age = calculatedAge;
                }
            }
        }
        
        // 4. Construct the patient information object.
        json patientInfo = {
            username: userDetails is map<json> ? (userDetails?.username ?: "") : "",
            age: age,
            city: userDetails is map<json> ? (userDetails?.city ?: "") : "",
            district: userDetails is map<json> ? (userDetails?.district ?: "") : "",
            phoneNumber: userDetails is map<json> ? (userDetails?.phoneNumber ?: "") : "",
            // ADDED: Get DOB and gender directly from the patientDetails document
            DOB: patientDetails is map<json> ? (patientDetails?.DOB ?: "N/A") : "N/A",
            gender: patientDetails is map<json> ? (patientDetails?.gender ?: "N/A") : "N/A"
        };

        // 5. Combine the original prescription with the new patient info.
        map<json> enrichedPrescription = prescription.clone();
        enrichedPrescription["patientInfo"] = patientInfo;
        
        enrichedPrescriptions.push(enrichedPrescription);
    }

    // 6. Return the final, combined list.
    return config:createresponse(true, "Prescriptions fetched successfully.", enrichedPrescriptions, http:STATUS_OK);
}



public function updatePrescriptionOrderStatus(http:Request req, utils:UpdatePrescriptionOrderStatusRequestBody body) returns http:Response|error {
    // 1. Authorize the user as a pharmacy and get their ID.
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    string pharmacyId = uid.toString();

    // 2. Security Check: Verify that the pharmacy owns this prescription.
    var prescription = db:getDocument("prescriptions", {"preId": body.preId});
    if prescription is error {
        return config:createresponse(false, "Database error finding prescription.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if prescription is () {
        return config:createresponse(false, "Prescription not found.", {}, http:STATUS_NOT_FOUND);
    }
    // Ensure the 'phId' in the document matches the logged-in pharmacy's ID.
    if prescription?.phId != pharmacyId {
        return config:createresponse(false, "Unauthorized to update this prescription.", {}, http:STATUS_FORBIDDEN);
    }

    // 3. Prepare and execute the update operation.
    map<json> updates = {"status": body.newStatus};
    var result = db:updateDocument("prescriptions", {"preId": body.preId}, updates);
    if result is error {
        return config:createresponse(false, result.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "Prescription status updated successfully.", {}, http:STATUS_OK);
}


// NEW FUNCTION: Provides aggregated counts for the dashboard summary.
public function getDashboardStats(http:Request req) returns http:Response|error {
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    string pharmacyId = uid.toString();

    // Fetch all prescriptions for this pharmacy
    var prescriptions = db:getDocumentList("prescriptions", {"phId": pharmacyId});
    if prescriptions is error {
        return config:createresponse(false, prescriptions.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Calculate counts by status
    int processingCount = 0;
    int shippedCount = 0;
    int deliveredCount = 0;

    foreach json p in prescriptions {
        // FIX: Wrap each statement in a block with curly braces {}
        match p?.status {
            "Order Confirmed"|"Order Packed" => {
                processingCount += 1;
            }
            "Shipped" => {
                shippedCount += 1;
            }
            "Delivered" => {
                deliveredCount += 1;
            }
        }
    }
    
    json stats = {
        processing: processingCount,
        sending: shippedCount, // Mapping "Shipped" to "sending" for the frontend
        received: deliveredCount // Mapping "Delivered" to "received"
    };

    return config:createresponse(true, "Dashboard stats fetched", stats, http:STATUS_OK);
}

// NEW FUNCTION: Gets a list of all doctors for the pharmacy to see.
public function getDoctorsForPharmacy(http:Request req) returns http:Response|error {
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }
    
    var doctorDocs = db:getAllDocumentsFromCollection("doctors");
    if doctorDocs is error {
        return config:createresponse(false, doctorDocs.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json[] doctorList = [];
    foreach json doctor in doctorDocs {
        if doctor is map<json> {
            var userDetails = db:getDocument("users", {"uid": doctor?.did});
            if userDetails is map<json> {
                json combined = {
                    id: check userDetails.uid,
                    name: check userDetails.username,
                    specialization: check doctor.specialization
                };
                doctorList.push(combined);
            }
        }
    }
    return config:createresponse(true, "Doctors list fetched", doctorList, http:STATUS_OK);
}
