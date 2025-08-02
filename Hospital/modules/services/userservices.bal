import ballerina/io;
import Hospital.config;
import Hospital.routes;
import Hospital.utils;
import ballerina/http;

service /user on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow user from Ballerina...";
    }
    resource function post register(@http:Payload utils:User user) returns json|error {
        return routes:register(user);
    }
}
public function startServices()  {
    io:println("Start services.");
}

