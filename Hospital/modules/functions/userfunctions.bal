import ballerina/crypto;
import ballerina/jwt;

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
            "email": user.email
        }
    };
    string token = check jwt:issue(config);
    return  token;
}


