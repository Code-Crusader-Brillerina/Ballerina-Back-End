import ballerina/http;


import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function register(utils:User user) returns http:Response|error {
    var exist = db:isEmailExist(user.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if exist is true {
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }

    user.pasword = functions:hashPassword(user.pasword);
    var newrec = db:insertOneIntoDocument("users", user);
    if newrec is error {
        return config:createresponse(false, newrec.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "User registered successfully.", newrec.toJson(), http:STATUS_CREATED);
}

public function login(utils:UserLogin user) returns http:Response|error {
    var document = db:getUser(user.email);
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "Please register first.", {}, http:STATUS_NOT_FOUND);
    }

    if document.pasword != functions:hashPassword(user.pasword) {
        return config:createresponse(false, "Invalid password.", {}, http:STATUS_UNAUTHORIZED);
    }

    utils:User convirtedDoc = check document.cloneWithType();
    var token=functions:crateJWT(convirtedDoc);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ("JWT", token, path = "/");
    return config:createresponse(true, "User login successful.", user.toJson(), http:STATUS_OK,cookie);
}

public function forgetPassword(utils:ForgetPassword forgetPBody) returns http:Response|error {
    var document = db:getUser(forgetPBody.email);
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "User cannor fined.", {}, http:STATUS_NOT_FOUND);
    }
    string OTP = functions:generateOtpCode();
    var issent=functions:sendEmail(forgetPBody.email,"OTP form Halgouce",OTP);
    if issent is error{
        return config:createresponse(false, issent.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var newvalue = db:insertOneIntoDocument("otp", {"otp":OTP,"email":forgetPBody.email});
    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "OTP sent successfully.", forgetPBody.toJson(), http:STATUS_OK);
}


public function submitOTP(utils:submitOTP body) returns http:Response|error {
    var document = db:getDocument("otp",{"email":body.email});
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "User cannor fined.", {}, http:STATUS_NOT_FOUND);
    }
    return config:createresponse(true, "OTP sent successfully.", body.toJson(), http:STATUS_OK);
}
