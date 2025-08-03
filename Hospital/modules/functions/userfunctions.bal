import ballerina/crypto;
import Hospital.config;

public function hashPassword(string password) returns string {
    string salted = password + config:salt;
    byte[] hashed = crypto:hashSha512(salted.toBytes());
    return hashed.toBase16();
}
