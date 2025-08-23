import ballerina/http;
// import ballerina/io;

import Hospital.db;

public function genereteAnswer(string question,json requiredData) returns json|error{
    http:Client openAIClient = check new ("https://openrouter.ai/api/v1");
    json payload = {
        model: "meta-llama/llama-3.1-405b-instruct:free",
        messages: [
            {
                role: "system",
                content: "You are a hospital receptionist AI. Answer concisely, do not provide long explanations. Your goal is to guide the user to the hospital. Only answer based on the provided JSON data bellow. Do not make up any names or departments."
            },
            {
                role: "system",
                content: requiredData.toBalString()
            },
            {
                role: "user",
                content: question
            }
        ]


    };

    http:Request req = new;
    req.setHeader("Authorization", "Bearer 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");
    req.setHeader("Content-Type", "application/json");
    req.setPayload(payload);

    string path = string `/chat/completions`;
    
    http:Response res = check openAIClient->post(path, req);

    json responsePayload = check res.getJsonPayload();
    json choices = check responsePayload.choices;
    json[] content = check choices.cloneWithType();
    json answer = check content[0].message.content;

    return answer;

}

public function doctorDetailsForChat()returns json|error{
    var documents = db:getAllDocumentsFromCollection("doctors");
    if documents is error {
        return error("I cannot provide doctor details");
    }

    json[] arr = [];
    foreach json item in documents {
        var did = check item.did;
        var user = check db:getDocument("users", {"uid": did});
        json obj = {
            specialization: check item.specialization,
            licenseNomber: check item.licenseNomber,
            experience: check item.experience,
            consultationFee: check item.consultationFee,
            availableTimes: check item.availableTimes,
            description: check item.description,
            username: check user.username,
            email:check user.email
        };

        arr.push(obj.toJson());
    }
    return arr;
}

public function pharmacyDetailsForChat()returns json|error{
    var documents = db:getAllDocumentsFromCollection("pharmacies");
    if documents is error {
        return error("I cannot provide doctor details");
    }

    json[] arr = [];
    foreach json pharmacyDoc in documents {
        var phId = check pharmacyDoc.phId;
        var userDocResult = check db:getDocument("users", {"uid": phId});
        json combinedDoc = {
            phId: check pharmacyDoc.phId, 
            name: check pharmacyDoc.name,
            contactNomber: check pharmacyDoc.contactNomber,
            userDetails: {
                uid: check userDocResult.uid,
                username: check userDocResult.username,
                email: check userDocResult.email,
                phoneNumber: check userDocResult.phoneNumber,
                city: check userDocResult.city,
                district: check userDocResult.district
            }
        };
        arr.push(combinedDoc);
    }
    return arr;
}
