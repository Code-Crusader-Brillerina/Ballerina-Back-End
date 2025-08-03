import Hospital.utils;

public function isEmailExist(string email) returns json|boolean|error{
    var document = getDocument("users",{"email":email});
    if document is error {
        return error(document.message());
    }
    if document is utils:User {
        return true;
    }
    return false;
}

public function getUser(string email) returns utils:User|null|error{
    var document = getDocument("users",{"email":email});
    if document is error {
        return error(document.message());
    }
    if document is utils:User {
        return document;
    }
    return null;
}