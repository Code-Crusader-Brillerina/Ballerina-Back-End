import ballerina/constraint;

public type Patient record {
    string pid;
    string DOB;
    string gender;
};

public type PatientUserDataUpdate record {
    @constraint:String {
        pattern: re`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$`
    }
    string email;
    string username;
    string phoneNumber;
    string city;
    string district;
    string profilepic;
};

public type PatientPatientDataUpdate record {
    string DOB;
    string gender;
};
public type PatientUpdateBody record {
    PatientUserDataUpdate userData;
    PatientPatientDataUpdate patientData;
};
