' ********** Seedr OAuth2 Device Authentication **********

' Request device code from Seedr OAuth2 API
function requestDeviceCode() as object
    print "[API] requestDeviceCode() - Starting device code request"
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/oauth/device/code"
    print "[API] Target URL: " + url
    print "[API] Client ID: " + config.clientId
    print "[API] Scopes: " + config.scopes

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    print "[API] HTTP request configured"

    postData = "client_id=" + config.clientId + "&scope=" + config.scopes
    print "[API] POST data: " + postData

    ' Use asynchronous request with message port
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    print "[API] Making async POST request..."
    request.AsyncPostFromString(postData)

    ' Wait for response
    print "[API] Waiting for response (10 second timeout)..."
    msg = wait(10000, port) ' 10 second timeout

    if msg <> invalid then
        print "[API] Response received, type: " + type(msg)
        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()
            print "[API] HTTP Response Code: " + Str(responseCode)

            if responseCode = 200 then
                response = msg.GetString()
                print "[API] Response body length: " + Str(Len(response))
                if response <> "" then
                    print "[API] Parsing JSON response..."
                    result = ParseJson(response)
                    if result <> invalid then
                        print "[API] JSON parsed successfully"
                        return result
                    else
                        print "[API] ERROR: Failed to parse JSON response"
                    end if
                else
                    print "[API] ERROR: Empty response body"
                end if
            else
                print "[API] ERROR: HTTP " + Str(responseCode) + " - " + msg.GetString()
            end if
        else
            print "[API] ERROR: Unexpected message type: " + type(msg)
        end if
    else
        print "[API] ERROR: Request timeout after 10 seconds"
    end if

    return invalid
end function

' Poll for access token using device code
function pollForToken(deviceCode as string) as object
    print "[API] pollForToken() - Polling for access token"
    print "[API] Device code (first 10 chars): " + Left(deviceCode, 10) + "..."
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/oauth/token"
    print "[API] Poll URL: " + url

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    print "[API] Poll request configured"

    postData = "grant_type=urn:ietf:params:oauth:grant-type:device_code"
    postData += "&device_code=" + deviceCode
    postData += "&client_id=" + config.clientId

    ' Use asynchronous request with message port
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.AsyncPostFromString(postData)

    ' Wait for response
    msg = wait(10000, port) ' 10 second timeout
    if msg <> invalid and type(msg) = "roUrlEvent" then
        if msg.GetResponseCode() = 200 then
            response = msg.GetString()
            if response <> "" then
                return ParseJson(response)
            end if
        else
            ' Return error response for proper error handling
            response = msg.GetString()
            if response <> "" then
                return ParseJson(response)
            end if
        end if
    end if

    return invalid
end function

' Refresh access token using refresh token
function refreshAccessToken(refreshToken as string) as object
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/oauth/token"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    postData = "grant_type=refresh_token"
    postData += "&refresh_token=" + refreshToken
    postData += "&client_id=" + config.clientId

    ' Use asynchronous request with message port
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    request.AsyncPostFromString(postData)

    ' Wait for response
    msg = wait(10000, port) ' 10 second timeout
    if msg <> invalid and type(msg) = "roUrlEvent" then
        if msg.GetResponseCode() = 200 then
            response = msg.GetString()
            if response <> "" then
                return ParseJson(response)
            end if
        end if
    end if

    return invalid
end function

' Save credentials to registry
sub saveCredentials(accessToken as string, refreshToken as string)
    registry = CreateObject("roRegistrySection", "seedr_auth")
    registry.Write("access_token", accessToken)
    registry.Write("refresh_token", refreshToken)
    registry.Write("auth_time", Str(CreateObject("roDateTime").AsSeconds()))
    registry.Flush()
end sub

' Load credentials from registry
function loadCredentials() as object
    registry = CreateObject("roRegistrySection", "seedr_auth")

    if registry.Exists("access_token") then
        return {
            accessToken: registry.Read("access_token")
            refreshToken: registry.Read("refresh_token")
            authTime: Val(registry.Read("auth_time"))
        }
    end if

    return invalid
end function

' Clear stored credentials
sub clearCredentials()
    registry = CreateObject("roRegistrySection", "seedr_auth")
    registry.Delete("access_token")
    registry.Delete("refresh_token")
    registry.Delete("auth_time")
    registry.Flush()
end sub

' Get the current access token (returns invalid if not available)
function getAccessToken() as dynamic
    credentials = loadCredentials()
    if credentials <> invalid and credentials.accessToken <> invalid then
        return credentials.accessToken
    end if
    return invalid
end function

' Get the current refresh token (returns invalid if not available)
function getRefreshToken() as dynamic
    credentials = loadCredentials()
    if credentials <> invalid and credentials.refreshToken <> invalid then
        return credentials.refreshToken
    end if
    return invalid
end function

' Check if we have valid credentials
function hasValidToken() as boolean
    credentials = loadCredentials()
    if credentials <> invalid then
        ' Check if token is not too old (30 days = 2592000 seconds)
        ' Tokens should be valid for a long time
        currentTime = CreateObject("roDateTime").AsSeconds()
        tokenAge = currentTime - credentials.authTime

        ' If token is less than 30 days old, it's valid
        if tokenAge < 2592000 then
            print "[AUTH] Token is valid, age: "; Int(tokenAge / 86400); " days"
            return true
        else
            print "[AUTH] Token expired, age: "; Int(tokenAge / 86400); " days"

            ' Try to refresh the token if we have a refresh token
            if credentials.refreshToken <> invalid and credentials.refreshToken <> "" then
                print "[AUTH] Attempting to refresh expired token..."
                newTokens = refreshAccessToken(credentials.refreshToken)

                if newTokens <> invalid and newTokens.access_token <> invalid then
                    print "[AUTH] Token refresh successful!"
                    ' Save the new tokens
                    saveCredentials(newTokens.access_token, newTokens.refresh_token)
                    return true
                else
                    print "[AUTH] Token refresh failed, user needs to re-authenticate"
                end if
            end if
        end if
    end if
    return false
end function