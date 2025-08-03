import ballerina/io;
import Hospital.config;
import Hospital.routes;
import Hospital.utils;
import ballerina/http;

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
}
public function startServices()  {
    io:println("Start services.");
}

