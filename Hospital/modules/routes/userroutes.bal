import Hospital.config;
// import ballerina/io;

import Hospital.db;
import Hospital.functions;
import Hospital.utils;
import ballerina/websocket;
import ballerina/http;
import ballerina/io;

public function register(utils:RegisterBody body) returns http:Response|error {
    var exist = db:isEmailExist(body.userData.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if exist is true {
        return config:createresponse(false, "User email already exists.", {}, http:STATUS_CONFLICT);
    }

    string OTP = functions:generateOtpCode();
    body.userData.password = functions:hashPassword(body.userData.password);
    body.userData.OTP = OTP;
    body.userData.emailConfirmed = 0;

    var newUser = db:insertOneIntoCollection("users", body.userData);
    if newUser is error {
        return config:createresponse(false, newUser.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var newPatient = db:insertOneIntoCollection("patients", body.patientData);
    if newPatient is error {
        var rollbackResult = db:deleteDocument("users", {"uid": body.userData.uid});
        if rollbackResult is error {
            io:println("User rollback failed for uid: ", body.userData.uid);
        }
        return config:createresponse(false, newPatient.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    json getEmail = config:sendConfirmationEmail(OTP);
    var isSent = functions:sendEmail(body.userData.email, check getEmail.subject, check getEmail.message);
    if isSent is error {
        io:println("Email sending failed for ", body.userData.email, ": ", isSent.message());
    }
    
    http:Cookie cookie = new ("email", body.userData.email, path = "/", secure = false, maxAge = 600);
    return config:createresponse(true, "User registered successfully. Please check your email to verify your account.", {}, http:STATUS_CREATED, cookie);
}

public function emailValidate(http:Request req, utils:EmailValidateBody body) returns http:Response|error {
    var email = config:getCookie(req, "email");
    if email is error {
        return config:createresponse(false, "Verification session expired. Please register again.", {}, http:STATUS_NOT_FOUND);
    }

    var document = db:getDocument("users", {"email": email});
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "User not found.", {}, http:STATUS_NOT_FOUND);
    }

    if document.OTP != body.OTP {
        return config:createresponse(false, "Invalid OTP.", {}, http:STATUS_UNAUTHORIZED);
    }

    var updateResult = db:updateDocument("users", {"email": email}, {"emailConfirmed": 1, "OTP": ()});
    if updateResult is error {
        return config:createresponse(false, updateResult.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    
    http:Cookie expiredCookie = new ("email", "", path = "/", maxAge = 0);
    return config:createresponse(true, "Email confirmed successfully. You can now log in.", {}, http:STATUS_OK, expiredCookie);
}

public function login(utils:UserLogin user) returns http:Response|error {
    var document = db:getUser(user.email);
    if document is error {
        return config:createresponse(false, document.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    if document is null {
        return config:createresponse(false, "Please register first.", {}, http:STATUS_NOT_FOUND);
    }

    // --- NEW STRATEGY: Convert to a typed record immediately to fix all type errors ---
    var userRecord = document.cloneWithType(utils:User);
    if userRecord is error {
        // This means the data in the DB doesn't match the User record shape.
        return config:createresponse(false, "User data is corrupted or invalid.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Now, all checks are 100% type-safe.
    if userRecord.emailConfirmed is int && userRecord.emailConfirmed == 0 {
        return config:createresponse(false, "Please verify your email address before logging in.", {}, http:STATUS_FORBIDDEN);
    }
    
    if userRecord.password != functions:hashPassword(user.password) {
        return config:createresponse(false, "Invalid password.", {}, http:STATUS_UNAUTHORIZED);
    }

    // We already have the strongly-typed 'userRecord', no need to convert again.
    var token = functions:crateJWT(userRecord);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ( "JWT", token, path = "/", httpOnly = true, secure = false );
    // We return the original 'document' json in the response body.
    return config:createresponse(true, "User login successful.", document, http:STATUS_OK, cookie);
}

public function logout() returns http:Response|error {
    // To log out, we overwrite the JWT cookie with one that has an expired maxAge.
    http:Cookie expiredCookie = new (
        "JWT",
        "expired", // Value can be empty
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
    json getEmail=config:sendOTPEmail(OTP);
    var issent=functions:sendEmail(forgetPBody.email,check getEmail.subject,check getEmail.message);
    if issent is error{
        return config:createresponse(false, issent.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    var newvalue = db:updateDocument("users",{"email":forgetPBody.email},{"OTP":OTP});
    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ("email", forgetPBody.email, path = "/", secure = false);
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
        return config:createresponse(false, "User cannot be found.", {}, http:STATUS_NOT_FOUND);
    }
    if document.OTP != body.OTP {
        return config:createresponse(false, "Invalid OTP.", {}, http:STATUS_UNAUTHORIZED);
    }

    // --- FIX STARTS HERE ---
    // Use updateDocument to set the OTP field to nil, effectively clearing it.
    var newvalue = db:updateDocument("users", {"email": email}, {"OTP": ()});
    // --- FIX ENDS HERE ---

    if newvalue is error{
        return config:createresponse(false, newvalue.message(), {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return config:createresponse(true, "OTP submitted successfully.", body.toJson(), http:STATUS_OK);
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

public function getUser(http:Request req) returns http:Response|error {
    var user = config:autherise(req);
    if user is error {
        return config:createresponse(false, user.message(), {}, http:STATUS_NOT_FOUND);
    }
    return config:createresponse(true, "User Found successfully.", user, http:STATUS_OK);
}

public function dumby() returns http:Response|error {
    websocket:Client wsClient = check new("ws://localhost:9090/chat");
    check wsClient->writeMessage("Text message");
    return config:createresponse(true, "Password changed successfully.", {cool:"good"}, http:STATUS_OK);
}
