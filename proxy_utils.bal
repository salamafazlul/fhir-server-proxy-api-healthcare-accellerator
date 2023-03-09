public isolated function validateFHIRBasePath(string[] paths) returns boolean {
    if paths.length() < 3 {
        return false;
    }
    if paths[0] != "fhir" && paths[1] != "r4" {
        return false;
    }
    return true;
}
