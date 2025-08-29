import Hospital.config;
import Hospital.routes;
import Hospital.utils;

import ballerina/http;
import ballerina/io;

@http:ServiceConfig {
    cors: {
        allowOrigins: [], // leave empty
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        exposeHeaders: ["X-CUSTOM-HEADER"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        maxAge: 3600
    }
}

service /user on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow user from Ballerina...";
    }

    resource function post register(@http:Payload utils:RegisterBody body) returns http:Response|error {
        return routes:register(body);
    }

    resource function post emailValidate(http:Request req, @http:Payload utils:EmailValidateBody body) returns http:Response|error {
        return routes:emailValidate(req, body);
    }

    resource function post login(@http:Payload utils:UserLogin user) returns http:Response|error {
        return routes:login(user);
    }

    resource function post logout() returns http:Response|error {
        return routes:logout();
    }

    resource function get check\-auth(http:Request req) returns http:Response|error {
        return routes:checkAuth(req);
    }

    resource function post forgetPassword(@http:Payload utils:ForgetPassword forgetPBody) returns http:Response|error {
        return routes:forgetPassword(forgetPBody);
    }

    resource function post submitOTP(http:Request req, @http:Payload utils:submitOTP body) returns http:Response|error {
        return routes:submitOTP(req, body);
    }

    resource function post changePassword(http:Request req, @http:Payload utils:changePassword body) returns http:Response|error {
        return routes:changePassword(req, body);
    }

    resource function get getUser(http:Request req) returns http:Response|error {
        return routes:getUser(req);
    }

    resource function get dumby() returns http:Response|error {
        return routes:dumby();
    }
}

public function startServices() {
    io:println("Start services.");
}
