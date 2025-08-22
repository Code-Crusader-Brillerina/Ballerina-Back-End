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
service /pharmacy on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow phamesist from Ballerina...";
    }


    resource function post addInventory(http:Request req, @http:Payload utils:AddInventoryBody body) returns http:Response|error {
        return routes:addInventory(req, body);
    }
}