import ballerina/constraint;

public type Doctor record {
    string did;
    string specialization;
    string licenseNomber;
    string experience;
    string consultationFee;
    string[] availableTimes;
    string description;

};

public type DoctorUserDataUpdate record {
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

public type DoctorDoctorDataUpdate record {
    string specialization;
    string licenseNomber;
    string experience;
    string consultationFee;
    string[] availableTimes;
    string description;
};
public type DoctorUpdateBody record {
    DoctorUserDataUpdate userData;
    DoctorDoctorDataUpdate doctorData;
};

