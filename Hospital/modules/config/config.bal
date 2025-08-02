import ballerina/http;
import ballerina/io;
import ballerinax/mongodb;


public listener http:Listener serverListener = new (8080);
public mongodb:Client mongoClient = checkpanic new (connection = "mongodb://localhost:27017");
public string DATABASE="Hospital";

public function createresponse(boolean success, string message, json data) returns json {
    return {
        success: success,
        message: message,
        data: data
    };
}

public function startConfigs() {
    io:println("Start configs.");
}

