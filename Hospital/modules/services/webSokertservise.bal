// import ballerina/io;
// import ballerina/websocket;

// service /chat on new websocket:Listener(9090, {
//     host: "0.0.0.0"   
// }) {

//     resource function get .() returns websocket:Service {
//         return new ChatService();
//     }
// }

// public websocket:Caller[] arr=[];
// service class ChatService {
//     *websocket:Service;

//     // Keep connected clients

//     // Runs when a client connects
//     remote function onOpen(websocket:Caller caller) returns error? {
//         arr.push(caller);
//         io:println("Client connected");
//     }


//     remote function onClose(websocket:Caller caller, int statusCode, string reason) returns error? {
//         // Remove disconnected client from the global array
//         int index = 0;
//         foreach websocket:Caller conn in arr {
//             if conn === caller {
//                 websocket:Caller _ = arr.remove(index);
//                 break;
//             }
//             index += 1;
//         }
//     }
//     // Runs when a client sends a message
//     remote function onMessage(websocket:Caller caller, string chatMessage) returns error? {
//         io:println("Received from client: ", chatMessage);
//         io:println(arr);
//         foreach websocket:Caller clientCaller in arr {
//             if clientCaller.isOpen() {
//                 check clientCaller->writeMessage(chatMessage);
//                 io:println(clientCaller);
//             }
//         }        
//     }
// }






import ballerina/websocket;

service /chat on new websocket:Listener(9090, {
    host: "0.0.0.0"   
}) {

    resource function get .() returns websocket:Service {
        return new ChatService();
    }
}

public type OpenSokert record {
    string message;
    string uid;
    string[] uidList;
};

public type SockertClients record {
    websocket:Caller caller;
    string uid;
};


public SockertClients[] doctors=[];
public SockertClients[] patients=[];

service class ChatService {
    *websocket:Service;
    // Runs when a client sends a message
    remote function onMessage(websocket:Caller caller, OpenSokert chatMessage) returns error? {
        match chatMessage.message {
            "doctorConnecting" => {
                SockertClients user={
                    caller:caller,
                    uid:chatMessage.uid
                };
                doctors.push(user);
            }
            "patientConecting" => {
                SockertClients user={
                    caller:caller,
                    uid:chatMessage.uid
                };
                patients.push(user);
            }
            "updatingQueue" => {
                foreach SockertClients patient in patients {
                    websocket:Caller temp=patient.caller;
                    foreach string user in chatMessage.uidList {
                        if patient.uid===user {
                            if temp.isOpen() {
                                check temp->writeMessage("chatMessage");
                            }
                        }
                    } 
                }   
            }
        }
    }
}

