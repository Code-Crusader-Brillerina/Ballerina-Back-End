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
