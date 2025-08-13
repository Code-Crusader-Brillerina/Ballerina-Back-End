import ballerina/io;
import ballerina/http;

import Hospital.config;
import Hospital.routes;
import Hospital.utils;


@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
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
    resource function post login(@http:Payload utils:UserLogin user) returns http:Response|error {
        return routes:login(user);
    }
    resource function post forgetPassword(@http:Payload utils:ForgetPassword forgetPBody) returns http:Response|error {
        return routes:forgetPassword(forgetPBody);
    }
    resource function post submitOTP(http:Request req,@http:Payload utils:submitOTP body) returns http:Response|error {
        return routes:submitOTP(req,body);
    }
    resource function post changePassword(http:Request req,@http:Payload utils:changePassword body) returns http:Response|error {
        return routes:changePassword(req,body);
    }
}
public function startServices()  {
    io:println("Start services.");
}

