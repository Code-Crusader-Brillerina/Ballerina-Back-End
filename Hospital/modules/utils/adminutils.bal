import ballerina/constraint;

public type DoctorBody record {
    User userData;
    Doctor doctorData;

};

public type Pharmacy record {
    string phId;
    string name;
    string contactNomber;
    @constraint:String {
        pattern: re`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$`
    }
    string email;

};

public type Medicine record {
    string mediId;
    string name;
    string strength;
    string form;
};



