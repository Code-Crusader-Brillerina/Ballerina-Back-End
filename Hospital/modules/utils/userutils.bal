import ballerina/constraint;

public type User record {
    string uid;
    string username;
    @constraint:String {
        pattern: re`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$`
    }
    string email;
    string password;
    string role;
    string phoneNumber;
    string city;
    string district;
    string profilepic;

};

public type UserLogin record {
    @constraint:String {
        pattern: re`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$`
    }
    string email;

    string password;
    
};

public type ForgetPassword record {
    @constraint:String {
        pattern: re`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}$`
    }
    string email;
    
};

public type submitOTP record {
    string OTP;
};


public type changePassword record {
    string password;
};
