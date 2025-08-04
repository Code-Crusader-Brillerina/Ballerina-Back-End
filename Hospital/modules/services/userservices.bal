import ballerina/io;
import Hospital.config;
import Hospital.routes;
import Hospital.utils;
import ballerina/http;


@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"],
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
    resource function post register(@http:Payload utils:User user) returns http:Response|error {
        return routes:register(user);
    }
    resource function post login(@http:Payload utils:UserLogin user) returns http:Response|error {
        return routes:login(user);
    }
    resource function post forgetPassword(@http:Payload utils:ForgetPassword forgetPBody) returns http:Response|error {
        return routes:forgetPassword(forgetPBody);
    }
}
public function startServices()  {
    io:println("Start services.");
}

