import Hospital.config;
import ballerinax/mongodb;
import Hospital.utils;

public function getDBCollection(string collectionName) returns mongodb:Collection|error {
    mongodb:Database db = check config:mongoClient->getDatabase(config:DATABASE);
    return check db->getCollection(collectionName);
}

public function getDocumentFromCollection(mongodb:Collection collection,map<json> value) returns json|error{
    utils:User? document = check collection->findOne(value, {});
    return document;
}

public function getDocument(string collectionName,map<json> value)returns json|error{
    var collection = getDBCollection(collectionName);
    if collection is error {
        return error("Failed to get the connection with the database.");
    }
    mongodb:Collection resultCollection = collection;

    var document=getDocumentFromCollection(resultCollection,value);
    if document is error {
        return error("Error from finding the document.");
    }
    return document;

}

public function insertOneIntoDocument(string collectionName,record {} data) returns record {}|error{
    var collection = getDBCollection(collectionName);
    if collection is error {
        return error("Failed to get the connection with the database.");
    }
    mongodb:Collection resultCollection = collection;

    // Insert the user into the collection
    var insertResult = resultCollection->insertOne(data);

    // Handle insertion failure
    if insertResult is error {
        return error("Failed inserting the document.");
    }
    return data;
}
