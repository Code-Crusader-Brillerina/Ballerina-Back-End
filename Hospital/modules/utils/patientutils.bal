public type Patient record {
    string pid;
    string DOB;
    string gender;
};

public type PatientUpdate record {
    string DOB;
    string gender;
};
public type PatientUpdateBody record {
    UserUpdate userData;
    PatientUpdate patientData;
};

public type Appoinment record {
    string aid;
    string pid;
    string did;
    string date;
    string time;
    // time = morning or evening
    string status;
    string description;
    string[] reports;
    string paymentState;
};


public type GetQueue record {
    string did;
    string date;
};

public type UpdateAppoinmentPayment record {
    string aid;
};

public type GetPrescription record {
    string preId;
};

public type GetDoctor record {
    string did;
};