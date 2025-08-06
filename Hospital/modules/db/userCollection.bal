
public function isEmailExist(string email) returns json|boolean|error{
    var document = getDocument("users",{"email":email});
    if document is error {
        return error(document.message());
    }
    if document is null {
        return false;
    }
    return true;
}

public function getUser(string email) returns json|null|error{
    var document = getDocument("users",{"email":email});
    if document is error {
        return error(document.message());
    }   
    return document;
}

public function getUserById(string uid) returns json|null|error{
    var document = getDocument("users",{"uid":uid});
    if document is error {
        return error(document.message());
    }   
    return document;
}