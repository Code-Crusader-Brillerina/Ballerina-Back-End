import ballerina/io;
import ballerina/http;
import Hospital.config;
import Hospital.utils;
import Hospital.db;




service /user on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow user from Ballerina...";
    }
    resource function post register(@http:Payload utils:User user)returns json|error {
        var exist =db:isEmailExist(user.email);
        if exist is error {
            return config:createresponse(false, exist.message(), {});
        }
        if exist is true {
            return config:createresponse(false, "User email already exists.", {});
        }
        var newrec =db:insertOneIntoDocument("users",user);
        if newrec is error {
            return config:createresponse(false, newrec.message(), {});
        }
        return config:createresponse(true, "User registered successfully.", newrec.toJson());
    }
}
public function startServices()  {
    io:println("Start services.");
}

