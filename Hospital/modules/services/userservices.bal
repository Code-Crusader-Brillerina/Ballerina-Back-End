import ballerina/io;
import Hospital.config;

service /user on config:serverListener {
    resource function get init() returns json|error {
        return "Hellow user from Ballerina...";
    }
}
public function startServices()  {
    io:println("Start services.");
}

