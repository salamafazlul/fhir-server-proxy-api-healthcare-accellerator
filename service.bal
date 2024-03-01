import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;

configurable string systemServiceUrl = "http://localhost:9090";
configurable string resourceServiceUrl = "http://localhost:9090";
configurable map<string> systemComponentRoutes = {
    "metadata": "/fhir/r4/metadata",
    "well-known": "/fhir/r4/.well-known/smart-configuration"
};
configurable map<string> resourceComponentRoutes = {
    "Patient": "/fhir/r4/Patient"
};

final http:Client systemServiceEp = check new (systemServiceUrl);
final http:Client resourceServiceEp = check new (resourceServiceUrl);

# A service representing a network-accessible API
# bound to port `9091`.
service / on new http:Listener(9091) {

    # Resource for proxying metadata endpoint. This resource will be unsecured endpoint.
    #
    # + req - HTTP Request
    # + return - Returns the response from metadata component.
    isolated resource function get fhir/r4/metadata(http:Request req) returns http:Response|http:StatusCodeResponse|error {

        string? metadataEp = systemComponentRoutes["metadata"];
        if metadataEp is string {
            if metadataEp.startsWith(systemServiceUrl) {
                metadataEp = metadataEp.substring(systemServiceUrl.length());
            }
            log:printInfo("Metadata endpoint: " + <string>metadataEp);
            http:Response|http:ClientError matadataResponse = systemServiceEp->forward(<string>metadataEp, req);
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

        string? wellKnownEp = systemComponentRoutes["well-known"];
        if wellKnownEp is string {
            if wellKnownEp.startsWith(systemServiceUrl) {
                wellKnownEp = wellKnownEp.substring(systemServiceUrl.length());
            }
            http:Response|http:ClientError wellKnownEPResponse = systemServiceEp->forward(<string>wellKnownEp, req);
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
        string? resystemServiceEp = resourceComponentRoutes[resourceType];
        string resourceCtx = "";
        if resystemServiceEp is string {
            if resystemServiceEp.startsWith(resourceServiceUrl) {
                resystemServiceEp = resystemServiceEp.substring(resourceServiceUrl.length());
            }
            if paths.length() > 0 {
                foreach int i in 0 ... paths.length() - 1 {
                    resourceCtx += string `/${paths[i]}`;
                }
            }
            resystemServiceEp = string `${resystemServiceEp ?: ""}${resourceCtx}`;
            log:printInfo("Full path: " + resourceServiceUrl + <string>resystemServiceEp);
            json|http:ClientError fhirAPIResponse = systemServiceEp->forward(<string>resystemServiceEp, req);
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
    isolated resource function get fhir/r4/[string... paths](http:Request req) returns http:Response|http:StatusCodeResponse|error {
        log:printInfo("Paths Default: " + paths.toString());
        string resourceType = paths[0];
        string? resystemServiceEp = resourceComponentRoutes[resourceType];
        string resourceCtx = "";
        if resystemServiceEp is string {
            if resystemServiceEp.startsWith(resourceServiceUrl) {
                resystemServiceEp = resystemServiceEp.substring(resourceServiceUrl.length());
            }
            if paths.length() > 3 {
                foreach int i in 2 ... paths.length() - 1 {
                    resourceCtx += string `/${paths[i]}`;
                }
            }
            resystemServiceEp = string `${resystemServiceEp ?: ""}${resourceCtx}`;
            log:printInfo("Full path: " + resourceServiceUrl + <string>resystemServiceEp);
            http:Response|http:ClientError fhirAPIResponse = systemServiceEp->forward(<string>resystemServiceEp, req);
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
