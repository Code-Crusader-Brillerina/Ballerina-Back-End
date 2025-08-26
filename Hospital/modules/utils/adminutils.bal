
public type DoctorBody record {
    User userData;
    Doctor doctorData;

};

public type PharmacyData record {
    string phId; 
  

};
public type AddPharmacyBody record {
    PharmacyData pharmacy;
    User user ;  

};


public type PharmacyBody record {
    User userData;
    PharmacyData pharmacyData;
};

public type Medicine record {
    string mediId;
    string name;
    string strength;
    string form;
    string medicineType;
    string size;
    string description;
    decimal price;
};

public type DeleteDoctor record {
    string did;
};

public type DeletePharmacy record {
    string phId;
};



