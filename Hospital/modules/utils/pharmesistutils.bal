
public type PharmacyInventory record {
    string inventoryId;
    string pharmacyId;
    string medicineId;
    string availableState;
    string price;
    string latestUpdate;
};

public type InventoryData record {
    string availableState;
    string price;
    string latestUpdate;
};

public type AddInventoryBody record {
    string medicineId;
    InventoryData inventoryData;
};


public type UpdatePrescriptionOrderStatusRequestBody record {
    string preId;
    // This makes the field required.
    string newStatus; 
};

public type DetailedPrice record {
    string preId;
    decimal totalPrice;
    string dateTime;
};

public type PrescriptionFinancials record {
    decimal grandTotal;
    DetailedPrice[] detailedPrices;
};