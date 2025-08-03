import ballerina/http;
import ballerina/io;
import ballerinax/mongodb;


public listener http:Listener serverListener = new (8080);
public mongodb:Client mongoClient = checkpanic new (connection = "mongodb://localhost:27017");
public string DATABASE="Hospital";
public string salt="We can won this price.";

public function createresponse(boolean success, string message, json data, int statusCode) returns http:Response {
    http:Response res = new;
    res.statusCode = statusCode;
    res.setJsonPayload({
        success: success,
        message: message,
        data: data
    });
    return res;
}

public function startConfigs() {
    io:println("Start configs.");
}

