import Hospital.config;
import Hospital.routes;
import Hospital.utils;

import ballerina/http;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:5173"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /pharmacy on config:serverListener {

    resource function post addInventory(http:Request req, @http:Payload utils:AddInventoryBody body) returns http:Response|error {
        return routes:addInventory(req, body);
    }

    // NEW: Get all inventory items for a specific pharmacy
    resource function get myinventory(http:Request req) returns http:Response|error {
        return routes:getMyInventory(req);
    }

    // NEW: Update a specific inventory item
    resource function put inventory/[string inventoryId](http:Request req, @http:Payload utils:AddInventoryBody body) returns http:Response|error {
        return routes:updateInventory(req, inventoryId, body);
    }

    // NEW: Delete a specific inventory item
    resource function delete inventory/[string inventoryId](http:Request req) returns http:Response|error {
        return routes:deleteInventory(req, inventoryId);
    }

    resource function get medicines(http:Request req) returns http:Response|error {
        return routes:getAllMedicinesForPharmacy(req);
    }
}
