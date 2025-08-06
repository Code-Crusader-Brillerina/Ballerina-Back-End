import ballerina/http;
import ballerina/io;
import ballerinax/mongodb;
import ballerina/jwt;


public listener http:Listener serverListener = new (8080);
public mongodb:Client mongoClient = checkpanic new (connection = "mongodb://localhost:27017");
public string DATABASE="Hospital";
public string salt="We can won this price.";

public function createresponse(boolean success, string message, json data, int statusCode, http:Cookie? cookie = ()) returns http:Response {
    http:Response res = new;
    res.statusCode = statusCode;
    res.setPayload({
        success: success,
        message: message,
        data: data
    });

    if cookie is http:Cookie {
        res.addCookie(cookie);
    }

    return res;
}


public  function  getCookie(http:Request req,string cookieName) returns string|error {
    http:Cookie[] cookies = req.getCookies();
    http:Cookie[] newCookie = cookies.filter(function(http:Cookie cookie) returns boolean {
        return cookie.name == cookieName;
    });

    if newCookie.length() > 0 {
        string? reqCookie = newCookie[0].value;
        if reqCookie is string {
            return reqCookie;
        }
    }
    return error("Cookie not found.");
}


public jwt:IssuerConfig jwtIssuerConfig = {
    username: "ballerina",
    issuer: "ballerina",
    audience: ["ballerina.io"],
    signatureConfig: {
        config: {
            keyFile: "resources/jwt/private.key"
        }
    },
    expTime: 3600
};


public jwt:ValidatorConfig jwtValidatorConfig = {
    issuer: "ballerina",
    audience: ["ballerina.io"],
    signatureConfig: {
        certFile: "resources/jwt/public.crt"
    },
    clockSkew: 60
};


public function autherise(http:Request req) returns json|error {
    string|error token = getCookie(req,"JWT");
    if (token is error) {
        return token.message();
    }

    jwt:Payload|error payload = check jwt:validate(token, jwtValidatorConfig);
    if (payload is jwt:Payload) {
        return {
            role:payload["role"].toString(),
            username:payload["username"].toString(),
            email:payload["email"].toString(),
            uid:payload["uid"].toString()
        };
    } else {
        return error("Unauthorized");
    }
}


public function startConfigs() {
    io:println("Start configs.");
}

