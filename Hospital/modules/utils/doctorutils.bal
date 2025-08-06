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

