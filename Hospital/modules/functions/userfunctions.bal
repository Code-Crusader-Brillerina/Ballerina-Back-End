import ballerina/crypto;
import ballerina/jwt;
import ballerina/email;
import ballerina/random;
// import ballerina/io;

import Hospital.config;
import Hospital.utils;


public function hashPassword(string password) returns string {
    string salted = password + config:salt;
    byte[] hashed = crypto:hashSha512(salted.toBytes());
    return hashed.toBase16();
}

public function crateJWT(utils:User user) returns string|error{
    jwt:IssuerConfig config = {
        username: user.email,
        issuer: config:jwtIssuerConfig.issuer,
        audience: config:jwtIssuerConfig.audience,
        signatureConfig: config:jwtIssuerConfig.signatureConfig,
        expTime: config:jwtIssuerConfig.expTime,
        customClaims: {
            "role": user.role,
            "username": user.username,
            "email": user.email,
            "uid":user.uid
        }
    };
    string token = check jwt:issue(config);
    return  token;
}

public function updateJWT(string uid,string role,utils:UserUpdate userData) returns string|error{
    utils:User newuser={
        username: userData.username,
        email: userData.email,
        uid: uid,
        role:role,
        password: "",
        phoneNumber:"",
        city:"",
        district:"",
        profilepic:""

    };
    var token=crateJWT(newuser);
    return  token;
}


public function sendEmail(string reciver,string subject,string message) returns error? {
    email:SmtpClient smtpClient = check new ("smtp.gmail.com", "r.k.fashionkurunegala@gmail.com" , "ifou lnky aiot hoim");
    email:Message email = {
        to: reciver,
        subject: subject,
        body: message
    };
    var issent= smtpClient->sendMessage(email);
    if issent is error {
        return error("Error from sending the email.");
    } 
}


public function generateOtpCode() returns string {
    int code = checkpanic random:createIntInRange(100000, 999999);
    return code.toString();
}



