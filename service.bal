import ballerina/http;
import ballerina/log;
import wso2healthcare/healthcare.fhir.r4;

configurable string sourceSystem = "http://localhost:9090";
configurable map<string> serverComponentRoutes = {
    "Patient": "/fhir/r4/Patient",
    "metadata": "/fhir/r4/metadata",
    "well-known": "/fhir/r4/.well-known/smart-configuration"
};

final http:Client sourceEp = check new (sourceSystem);

# A service representing a network-accessible API
# bound to port `9091`.
service / on new http:Listener(9091) {


    # Resource for proxying metadata endpoint. This resource will be unsecured endpoint.
    #
    # + req - HTTP Request
    # + return - Returns the response from metadata component.
    isolated resource function get fhir/r4/metadata(http:Request req) returns http:Response|http:StatusCodeResponse|error {

        string? metadataEp = serverComponentRoutes["metadata"];
        if metadataEp is string {
            if metadataEp.startsWith(sourceSystem) {
                metadataEp = metadataEp.substring(sourceSystem.length());
            }
            log:printInfo("Metadata endpoint: " + <string>metadataEp);
            http:Response|http:ClientError matadataResponse = sourceEp->forward(<string>metadataEp, req);
            return matadataResponse;
        }
        r4:OperationOutcome opOutcome = {
            issue: [
                {
                    severity: r4:ERROR,
                    code: r4:PROCESSING,
                    diagnostics: "Metadata endpoint not configured to route the request."
                }
            ]
        };
        http:InternalServerError internalError = {
            body: opOutcome
        };
        return internalError;
    }

    # Resource for proxying SMART well-known endpoint. This resource will be unsecured endpoint.
    #
    # + req - HTTP Request
    # + return - Returns the response from SMART well-known component.
    isolated resource function get fhir/r4/\.well\-known/smart\-configuration(http:Request req) returns http:Response|http:StatusCodeResponse|error {

        string? wellKnownEp = serverComponentRoutes["well-known"];
        if wellKnownEp is string {
            if wellKnownEp.startsWith(sourceSystem) {
                wellKnownEp = wellKnownEp.substring(sourceSystem.length());
            }
            http:Response|http:ClientError wellKnownEPResponse = sourceEp->forward(<string>wellKnownEp, req);
            return wellKnownEPResponse;
        }
        r4:OperationOutcome opOutcome = {
            issue: [
                {
                    severity: r4:ERROR,
                    code: r4:PROCESSING,
                    diagnostics: "SMART well-known endpoint not configured to route the request."
                }
            ]
        };
        http:InternalServerError internalError = {
            body: opOutcome
        };
        return internalError;
    }

    # Resource for proxying all read/search interactions of FHIR resources. 
    # This resource will be secured endpoint as all the FHIR resources needs to be secured.
    #
    # + paths - Path parameters 
    # + req - HTTP Request
    # + return - Returns the response from FHIR resource component.
    isolated resource function get fhir/r4/[string resourceType]/[string... paths](http:Request req) returns json|http:StatusCodeResponse|error {
        log:printInfo("Paths: " + paths.toString());
        log:printInfo("Resource Type: " + resourceType);
        log:printInfo(req.getHeaderNames().toJsonString());
        string[]|http:HeaderNotFoundError headers = req.getHeaders("x-jwt-assertion");
        if headers is string[] {
            log:printInfo("JWT: " + headers.toJsonString());
        }
        string? resourceEP = serverComponentRoutes[resourceType];
        string resourceCtx = "";
        if resourceEP is string {
            if resourceEP.startsWith(sourceSystem) {
                resourceEP = resourceEP.substring(sourceSystem.length());
            }
            if paths.length() > 0 {
                foreach int i in 0 ... paths.length() - 1 {
                    resourceCtx += string `/${paths[i]}`;
                }
            }
            resourceEP = string `${resourceEP ?: ""}${resourceCtx}`;
            log:printInfo("Full path: " + sourceSystem + <string>resourceEP);
            json|http:ClientError fhirAPIResponse = sourceEp->forward(<string>resourceEP, req);
            return fhirAPIResponse;
        }
        r4:OperationOutcome opOutcome = {
            issue: [
                {
                    severity: r4:ERROR,
                    code: r4:PROCESSING,
                    diagnostics: string `FHIR resource type: ${resourceType} not configured to route the request.`
                }
            ]
        };
        http:InternalServerError internalError = {
            body: opOutcome
        };
        return internalError;
    }

    # Resource for proxying FHIR resources. This resource will be secured endpoint as all the FHIR resources needs to be secured.
    #
    # + paths - Path parameters 
    # + req - HTTP Request
    # + return - Returns the response from FHIR resource component.
    isolated resource function 'default [string... paths](http:Request req) returns http:Response|http:StatusCodeResponse|error {
        log:printInfo("Paths Default: " + paths.toString());
        if validateFHIRBasePath(paths) {
            r4:OperationOutcome opOutcome = {
                issue: [
                    {
                        severity: r4:ERROR,
                        code: r4:PROCESSING,
                        diagnostics: "Invalid FHIR base path."
                    }
                ]
            };
            http:InternalServerError internalError = {
                body: opOutcome
            };
            return internalError;
        }
        string resourceType = paths[2];
        string? resourceEP = serverComponentRoutes[resourceType];
        string resourceCtx = "";
        if resourceEP is string {
            if resourceEP.startsWith(sourceSystem) {
                resourceEP = resourceEP.substring(sourceSystem.length());
            }
            if paths.length() > 3 {
                foreach int i in 2 ... paths.length() - 1 {
                    resourceCtx += string `/${paths[i]}`;
                }
            }
            resourceEP = string `${resourceEP ?: ""}${resourceCtx}`;
            log:printInfo("Full path: " + sourceSystem + <string>resourceEP);
            http:Response|http:ClientError fhirAPIResponse = sourceEp->forward(<string>resourceEP, req);
            return fhirAPIResponse;
        }
        r4:OperationOutcome opOutcome = {
            issue: [
                {
                    severity: r4:ERROR,
                    code: r4:PROCESSING,
                    diagnostics: string `FHIR resource type: ${resourceType} not configured to route the request.`
                }
            ]
        };
        http:InternalServerError internalError = {
            body: opOutcome
        };
        return internalError;
    }
}
