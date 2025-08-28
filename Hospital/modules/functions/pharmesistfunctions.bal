import ballerina/time;

public function calculateAge(string dobString) returns int|error {
    // FIX 1: Use the top-level 'time:civilFromString' to parse the string.
    // This function returns a 'time:Civil' record, which includes date and time info.
    time:Civil|error birthCivil = time:civilFromString(dobString);
    if birthCivil is error {
        return error("Invalid DOB format. Expected YYYY-MM-DD.", birthCivil);
    }

    // FIX 2: Create a 'time:Date' record from the parsed 'time:Civil' record.
    time:Date birthDate = {
        year: birthCivil.year,
        month: birthCivil.month,
        day: birthCivil.day
    };

    // Get the current date in UTC (this part was already correct)
    time:Civil currentCivil = time:utcToCivil(time:utcNow());
    time:Date currentDate = {
        year: currentCivil.year,
        month: currentCivil.month,
        day: currentCivil.day
    };

    // Calculate the difference in years (this part was already correct)
    int age = currentDate.year - birthDate.year;

    // Adjust age if the birthday hasn't occurred yet this year
    if (currentDate.month < birthDate.month || (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age = age - 1;
    }

    return age;
}