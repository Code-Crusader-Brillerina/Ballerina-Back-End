import Hospital.db;
import Hospital.utils;
import Hospital.config;
import Hospital.functions;

public function register(utils:User user)returns json|error {
    var exist =db:isEmailExist(user.email);
    if exist is error {
        return config:createresponse(false, exist.message(), {});
    }
    if exist is true {
        return config:createresponse(false, "User email already exists.", {});
    }
    user.pasword=functions:hashPassword(user.pasword);
    var newrec =db:insertOneIntoDocument("users",user);
    if newrec is error {
        return config:createresponse(false, newrec.message(), {});
    }
    return config:createresponse(true, "User registered successfully.", newrec.toJson());
}

public function login(utils:UserLogin user)returns json|error {
    var document =db:getUser(user.email);
    if document is error {
        return config:createresponse(false, document.message(), {});
    }
    if document is null {
        return config:createresponse(false, "Please register first.", {});
    }
    if document.pasword != functions:hashPassword(user.pasword) {
        return config:createresponse(false, "Invalid Password.", {});
    }
    // create jwt token
    // return config:createresponse(true, "User registered successfully.", newrec.toJson());
    return config:createresponse(true, "User login successfully.", user.toJson());
}