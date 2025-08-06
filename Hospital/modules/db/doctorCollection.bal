import Hospital.utils;

public function updateDoctor(string uid,utils:DoctorUpdate doctorData) returns record {| anydata...; |}|error{
    return  updateDocument("doctors",{"did":uid},{
        "specialization":doctorData.specialization,
        "licenseNomber":doctorData.licenseNomber,
        "experience":doctorData.experience,
        "consultationFee":doctorData.consultationFee,
        "availableTimes":doctorData.availableTimes,
        "description":doctorData.description
    });
    
}