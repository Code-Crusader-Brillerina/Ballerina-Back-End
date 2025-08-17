import ballerina/http;
import Hospital.db;
import Hospital.config;
import Hospital.utils;

public function addInventory(http:Request req, utils:AddInventoryBody body) returns http:Response|error {
    // Authorize the request as a pharmacist.
    var uid = config:autheriseAs(req, "pharmacy");
    if uid is error {
        return config:createresponse(false, uid.message(), {}, http:STATUS_UNAUTHORIZED);
    }

    // Create a unique inventory ID by combining pharmacyId and medicineId.
    string inventoryId = body.pharmacyId + "_" + body.medicineId;

    // Create a record of type 'PharmacyInventory' from the request body.
    utils:PharmacyInventory inventoryDocument = {
        inventoryId: inventoryId,
        pharmacyId: body.pharmacyId,
        medicineId: body.medicineId,
        availableState: body.inventoryData.availableState,
        price: body.inventoryData.price,
        latestUpdate: body.inventoryData.latestUpdate
    };
    
    // Insert the new inventory document into the 'pharmacyInventory' collection.
    var insertResult = db:insertOneIntoCollection("pharmacyInventory", inventoryDocument);
    if insertResult is error {
        return config:createresponse(false, insertResult.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Return a success response with the added data.
    return config:createresponse(true, "Pharmacy inventory added successfully.", inventoryDocument.toJson(), http:STATUS_OK);
}