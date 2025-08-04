import ballerinax/mongodb;
// import ballerina/io;

import Hospital.config;

public function getDBCollection(string collectionName) returns mongodb:Collection|error {
    mongodb:Database db = check config:mongoClient->getDatabase(config:DATABASE);
    return check db->getCollection(collectionName);
}

public function getDocumentFromCollection(mongodb:Collection collection, map<json> filter) returns json|error {
    record {| anydata...; |}? result = check collection->findOne(filter, {});
    return result.toJson();
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

public function insertOneIntoCollection(string collectionName,record {} data) returns record {}|error{
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

public function updateOneIntoDocument(string collectionName, map<json> filter, map<json> data) returns record {}|error {
    var collection = getDBCollection(collectionName);
    if collection is error {
        return error("Failed to get the connection with the database.");
    }
    mongodb:Collection resultCollection = collection;

    mongodb:Update update = {"set": data };
    var insertResult = resultCollection->updateOne(filter, update);
    if insertResult is error {
        return error("Failed inserting the document.");
    }
    return data;
}

public function removeOneFromDocument(string collectionName, map<json> filter, map<json> data) returns record {}|error {
    var collection = getDBCollection(collectionName);
    if collection is error {
        return error("Failed to get the connection with the database.");
    }
    mongodb:Collection resultCollection = collection;

    mongodb:Update update = {"unset": data };

    var insertResult = resultCollection->updateOne(filter, update);
    if insertResult is error {
        return error("Failed inserting the document.");
    }
    return data;
}


