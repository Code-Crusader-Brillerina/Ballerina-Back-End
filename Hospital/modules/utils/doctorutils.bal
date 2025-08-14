public type Doctor record {
    string did;
    string specialization;
    string licenseNomber;
    string experience;
    string consultationFee;
    string[] availableTimes;
    string description;

};

public type DoctorUpdate record {
    string specialization;
    string licenseNomber;
    string experience;
    string consultationFee;
    string[] availableTimes;
    string description;
};
public type DoctorUpdateBody record {
    UserUpdate userData;
    DoctorUpdate doctorData;
};

public type UpdateAppoinmentStatus record {
    string aid;
    string status;
};

public type PrescriptionItem record {
    string preItemId;
    string mediId;
    string dosage;
    string frequency;
    string duration;
    string quantity;
    string instructions;
};

public type Prescription record {
    string preId;
    string pid;
    string did;
    string aid;
    string dateTime;
    string diliveryMethod;
    string phId;
    string status;
    string note;
    PrescriptionItem[] items;
};


public type DoctorGetQueue record {
    string date;
};

public type GetAppoinment record {
    string aid;
};

 