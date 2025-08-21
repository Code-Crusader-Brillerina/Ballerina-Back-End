import Hospital.config;
// import ballerina/io;

import Hospital.db;
import Hospital.functions;
import Hospital.utils;
import ballerina/http;

public function register(utils:RegisterBody body) returns http:Response|error {
    var exist = db:isEmailExist(body.userData.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if exist is true {
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }

    body.userData.password = functions:hashPassword(body.userData.password);
    var newUser = db:insertOneIntoCollection("users", body.userData);
    if newUser is error {
        return config:createresponse(false, newUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var newPatient = db:insertOneIntoCollection("patients", body.patientData);
    if newPatient is error {
        return config:createresponse(false, newPatient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    return config:createresponse(true, "User registered successfully.", body.toJson(), http:STATUS_CREATED);
}

public function login(utils:UserLogin user) returns http:Response|error {
    var document = db:getUser(user.email);
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "Please register first.", {}, http:STATUS_NOT_FOUND);
    }

    if document.password != functions:hashPassword(user.password) {
        return config:createresponse(false, "Invalid password.", {}, http:STATUS_UNAUTHORIZED);
    }

    utils:User convirtedDoc = check document.cloneWithType();
    var token = functions:crateJWT(convirtedDoc);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    // This is the cookie being set. Note the attributes: Name="JWT", Path="/", httpOnly=true.
    // The Domain is implicitly set to the host of the request (e.g., "localhost").
    http:Cookie cookie = new (
        "JWT",
        token,
        path = "/",
        httpOnly = true,
        secure = false // false for localhost, true in prod
    );

    return config:createresponse(true, "User login successful.", document, http:STATUS_OK, cookie);
}

public function logout() returns http:Response|error {
    // To log out, we overwrite the JWT cookie with one that has an expired maxAge.
    http:Cookie expiredCookie = new (
        "JWT",
        "kkk", // Value can be empty
        path = "/",
        maxAge = 0, // This tells the browser to expire the cookie immediately
        httpOnly = true,
        secure = false // Should match the login cookie's attributes
    );
    return config:createresponse(true, "User logged out successfully.", {}, http:STATUS_OK, expiredCookie);
}

// NEW FUNCTION: Handles session check
public function checkAuth(http:Request req) returns http:Response|error {
    var userData = config:autherise(req);
    if userData is error {
        return config:createresponse(false, "User not authenticated", {}, http:STATUS_UNAUTHORIZED);
    }
    return config:createresponse(true, "User is authenticated", userData, http:STATUS_OK);
}

public function forgetPassword(utils:ForgetPassword forgetPBody) returns http:Response|error {
    var document = db:getUser(forgetPBody.email);
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "User cannot fined.", {}, http:STATUS_NOT_FOUND);
    }
    string OTP = functions:generateOtpCode();
    var issent=functions:sendEmail(forgetPBody.email,"OTP form Halgouce",OTP);
    if issent is error{
        return config:createresponse(false, issent.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var newvalue = db:updateDocument("users",{"email":forgetPBody.email},{"OTP":OTP});
    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ("email", forgetPBody.email, path = "/",secure=true);
    return config:createresponse(true, "OTP sent successfully.", forgetPBody.toJson(), http:STATUS_OK,cookie);
}


public function submitOTP(http:Request req,utils:submitOTP body) returns http:Response|error {
    var email = config:getCookie(req,"email");
    if email is error {
        return config:createresponse(false, email.message(), {}, http:STATUS_NOT_FOUND);
    }
    var document = db:getDocument("users",{"email":email});
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "User cannot fined.", {}, http:STATUS_NOT_FOUND);
    }
    if document.OTP !=body.OTP{
        return config:createresponse(false, "Invalid OTP.", {}, http:STATUS_UNAUTHORIZED);
    }
    var newvalue = db:removeOneFromDocument("users",{"email":email},{"OTP":""});
    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "OTP submit successfully.", body.toJson(), http:STATUS_OK);
}


public function changePassword(http:Request req,utils:changePassword body) returns http:Response|error {
    var email = config:getCookie(req,"email");
    if email is error {
        return config:createresponse(false, email.message(), {}, http:STATUS_NOT_FOUND);
    }
    string pasword = functions:hashPassword(body.password);
    var newvalue = db:updateDocument("users",{"email":email},{"password":pasword});
    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "Password changed successfully.", body.toJson(), http:STATUS_OK);
}
