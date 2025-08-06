import Hospital.utils;

public function updatePatient(string uid,utils:PatientUpdate patientData) returns record {| anydata...; |}|error{
    return  updateDocument("patients",{"pid":uid},{
        "DOB":patientData.DOB,
        "gender":patientData.gender
    });
}
