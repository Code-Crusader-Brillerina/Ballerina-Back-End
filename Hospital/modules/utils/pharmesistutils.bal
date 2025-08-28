
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