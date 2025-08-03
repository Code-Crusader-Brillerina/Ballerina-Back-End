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

    var token=functions:crateJWT(document);
    if token is error {
        return config:createresponse(false, "Error creating JWT.", {}, http:STATUS_INTERNAL_SERVER_ERROR);
    }
    http:Cookie cookie = new ("JWT", token, path = "/");
    return config:createresponse(true, "User login successful.", user.toJson(), http:STATUS_OK,cookie);
}
