import Hospital.config;
import Hospital.db;
import Hospital.utils;

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
