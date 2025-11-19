' ********** Seedr API Task Component **********

sub init()
    m.top.functionName = "makeApiRequest"
end sub

sub makeApiRequest()
    request = m.top.request
    ' Reduced logging for cleaner output

    if request.method = "device_code" then
        result = requestDeviceCode()
        m.top.response = {
            success: (result <> invalid)
            data: result
            type: "device_code"
        }
    else if request.method = "poll_token" then
        result = pollForToken(request.deviceCode)
        m.top.response = {
            success: (result <> invalid)
            data: result
            type: "poll_token"
        }
    else if request.method = "refresh_token" then
        result = refreshAccessToken(request.refreshToken)
        m.top.response = {
            success: (result <> invalid)
            data: result
            type: "refresh_token"
        }
    else if request.method = "get_folders" then
        result = getRootFolderContents(request.accessToken)
        m.top.response = {
            success: (result <> invalid)
            data: result
            type: "get_folders"
        }
    else if request.method = "get_folder" then
        result = getFolderContents(request.accessToken, request.folderId)
        m.top.response = {
            success: (result <> invalid)
            data: result
            type: "get_folder"
        }
    else if request.method = "get_user" then
        result = getUserData(request.accessToken)
        errorMsg = ""
        if result = invalid then errorMsg = "Failed to get user data"
        m.top.response = {
            success: (result <> invalid)
            data: result
            type: "subscription"
            message: errorMsg
        }
    else
        print "[ApiTask] Unknown request method: "; request.method
        m.top.response = {
            success: false
            data: invalid
            type: "error"
        }
    end if
end sub

' Request device code from Seedr OAuth2 API
function requestDeviceCode() as object
    print "[ApiTask] Requesting device code..."
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/oauth/device/code"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    postData = "client_id=" + config.clientId + "&scope=" + config.scopes

    ' Use asynchronous request with message port
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncPostFromString(postData) then
        msg = wait(10000, port) ' 10 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                if response <> "" then
                    return ParseJson(response)
                end if
            end if
        end if
    end if

    return invalid
end function

' Poll for access token using device code
function pollForToken(deviceCode as string) as object
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/oauth/token"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    postData = "grant_type=urn:ietf:params:oauth:grant-type:device_code"
    postData += "&device_code=" + deviceCode
    postData += "&client_id=" + config.clientId

    ' Use asynchronous request with message port
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncPostFromString(postData) then
        msg = wait(10000, port) ' 10 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                if response <> "" then
                    return ParseJson(response)
                end if
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
    if request.AsyncPostFromString(postData) then
        msg = wait(10000, port) ' 10 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                if response <> "" then
                    return ParseJson(response)
                end if
            end if
        end if
    end if

    return invalid
end function

' Get root folder contents from Seedr API
function getRootFolderContents(accessToken as string) as object
    print "[ApiTask] Getting root folder contents..."
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/fs/root/contents"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncGetToString() then
        msg = wait(30000, port) ' 30 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                print "[ApiTask] Root folder API response received"
                return ParseJson(response)
            else if msg.GetResponseCode() = 401 then
                print "[ApiTask] Root folder API 401 error - attempting token refresh"
                ' Attempt to refresh the token
                refreshToken = getRefreshToken()
                if refreshToken <> invalid and refreshToken <> "" then
                    print "[ApiTask] Refreshing token..."
                    newTokens = refreshAccessToken(refreshToken)

                    if newTokens <> invalid and newTokens.access_token <> invalid then
                        print "[ApiTask] Token refresh successful! Saving new token and retrying..."
                        ' Save the new tokens
                        saveCredentials(newTokens.access_token, newTokens.refresh_token)

                        ' Retry the request with the new token
                        print "[ApiTask] Retrying root folder request with new token..."
                        return getRootFolderContentsWithToken(newTokens.access_token)
                    else
                        print "[ApiTask] Token refresh failed - user needs to re-authenticate"
                    end if
                else
                    print "[ApiTask] No refresh token available"
                end if
            else
                print "[ApiTask] Root folder API error: "; msg.GetResponseCode()
            end if
        else
            print "[ApiTask] Root folder API timeout or invalid response"
        end if
    end if

    return invalid
end function

' Helper function to get root folder contents with a specific token (no retry)
function getRootFolderContentsWithToken(accessToken as string) as object
    print "[ApiTask] Getting root folder contents with token..."
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/fs/root/contents"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncGetToString() then
        msg = wait(30000, port) ' 30 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                print "[ApiTask] Root folder API response received (after refresh)"
                return ParseJson(response)
            else
                print "[ApiTask] Root folder API error after token refresh: "; msg.GetResponseCode()
            end if
        end if
    end if

    return invalid
end function

' Get specific folder contents from Seedr API
function getFolderContents(accessToken as string, folderId as string) as object
    print "[ApiTask] Getting folder contents for ID: "; folderId
    config = getApiConfig()
    ' Try different API versions to find the working one
    url = config.baseUrl + "/api/v0.1/p/fs/folder/" + folderId + "/contents"
    print "[ApiTask] Trying API v0.1 with folder/ prefix"
    print "[ApiTask] Constructed URL: "; url

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    print "[ApiTask] Making request with access token: "; Left(accessToken, 20) + "..."

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncGetToString() then
        msg = wait(30000, port) ' 30 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                print "[ApiTask] Folder API response received"
                return ParseJson(response)
            else if msg.GetResponseCode() = 401 then
                print "[ApiTask] Folder API 401 error - attempting token refresh"
                ' Attempt to refresh the token
                refreshToken = getRefreshToken()
                if refreshToken <> invalid and refreshToken <> "" then
                    print "[ApiTask] Refreshing token..."
                    newTokens = refreshAccessToken(refreshToken)

                    if newTokens <> invalid and newTokens.access_token <> invalid then
                        print "[ApiTask] Token refresh successful! Saving new token and retrying..."
                        ' Save the new tokens
                        saveCredentials(newTokens.access_token, newTokens.refresh_token)

                        ' Retry the request with the new token
                        print "[ApiTask] Retrying folder request with new token..."
                        return getFolderContentsWithToken(newTokens.access_token, folderId)
                    else
                        print "[ApiTask] Token refresh failed - user needs to re-authenticate"
                    end if
                else
                    print "[ApiTask] No refresh token available"
                end if
            else
                print "[ApiTask] Folder API error: "; msg.GetResponseCode()
                print "[ApiTask] Error response: "; msg.GetString()

                ' Try alternative endpoint format if first one fails
                if msg.GetResponseCode() = 404 then
                    print "[ApiTask] Trying alternative endpoint format..."
                    altUrl = config.baseUrl + "/api/v0.1/p/fs/" + folderId + "/contents"
                    print "[ApiTask] Alternative URL: "; altUrl

                    request2 = CreateObject("roUrlTransfer")
                    request2.SetUrl(altUrl)
                    request2.SetRequest("GET")
                    request2.AddHeader("Authorization", "Bearer " + accessToken)
                    request2.AddHeader("Accept", "application/json")
                    request2.SetCertificatesFile("common:/certs/ca-bundle.crt")

                    port2 = CreateObject("roMessagePort")
                    request2.SetMessagePort(port2)
                    if request2.AsyncGetToString() then
                        msg2 = wait(30000, port2)
                        if msg2 <> invalid and type(msg2) = "roUrlEvent" then
                            if msg2.GetResponseCode() = 200 then
                                response2 = msg2.GetString()
                                print "[ApiTask] Alternative API response received"
                                return ParseJson(response2)
                            else
                                print "[ApiTask] Alternative API error: "; msg2.GetResponseCode()
                                print "[ApiTask] Alternative error response: "; msg2.GetString()
                            end if
                        end if
                    end if
                end if
            end if
        else
            print "[ApiTask] Folder API timeout or invalid response"
        end if
    end if

    return invalid
end function

' Helper function to get folder contents with a specific token (no retry)
function getFolderContentsWithToken(accessToken as string, folderId as string) as object
    print "[ApiTask] Getting folder contents with token for ID: "; folderId
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/fs/folder/" + folderId + "/contents"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncGetToString() then
        msg = wait(30000, port) ' 30 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                print "[ApiTask] Folder API response received (after refresh)"
                return ParseJson(response)
            else if msg.GetResponseCode() = 404 then
                ' Try alternative endpoint format
                print "[ApiTask] Trying alternative endpoint format..."
                altUrl = config.baseUrl + "/api/v0.1/p/fs/" + folderId + "/contents"

                request2 = CreateObject("roUrlTransfer")
                request2.SetUrl(altUrl)
                request2.SetRequest("GET")
                request2.AddHeader("Authorization", "Bearer " + accessToken)
                request2.AddHeader("Accept", "application/json")
                request2.SetCertificatesFile("common:/certs/ca-bundle.crt")

                port2 = CreateObject("roMessagePort")
                request2.SetMessagePort(port2)
                if request2.AsyncGetToString() then
                    msg2 = wait(30000, port2)
                    if msg2 <> invalid and type(msg2) = "roUrlEvent" then
                        if msg2.GetResponseCode() = 200 then
                            response2 = msg2.GetString()
                            print "[ApiTask] Alternative API response received (after refresh)"
                            return ParseJson(response2)
                        end if
                    end if
                end if
            else
                print "[ApiTask] Folder API error after token refresh: "; msg.GetResponseCode()
            end if
        end if
    end if

    return invalid
end function

' Get user data from Seedr API
function getUserData(accessToken as string) as object
    print "[ApiTask] Getting user data..."
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/user"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncGetToString() then
        msg = wait(10000, port) ' 10 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                print "[ApiTask] User data received successfully"
                return ParseJson(response)
            else if msg.GetResponseCode() = 401 then
                print "[ApiTask] User data API 401 error - attempting token refresh"
                ' Attempt to refresh the token
                refreshToken = getRefreshToken()
                if refreshToken <> invalid and refreshToken <> "" then
                    print "[ApiTask] Refreshing token..."
                    newTokens = refreshAccessToken(refreshToken)

                    if newTokens <> invalid and newTokens.access_token <> invalid then
                        print "[ApiTask] Token refresh successful! Saving new token and retrying..."
                        ' Save the new tokens
                        saveCredentials(newTokens.access_token, newTokens.refresh_token)

                        ' Retry the request with the new token
                        print "[ApiTask] Retrying user data request with new token..."
                        return getUserDataWithToken(newTokens.access_token)
                    else
                        print "[ApiTask] Token refresh failed - user needs to re-authenticate"
                    end if
                else
                    print "[ApiTask] No refresh token available"
                end if
            else
                print "[ApiTask] User data API error: "; msg.GetResponseCode()
            end if
        else
            print "[ApiTask] User data API timeout or invalid response"
        end if
    end if

    return invalid
end function

' Helper function to get user data with a specific token (no retry)
function getUserDataWithToken(accessToken as string) as object
    print "[ApiTask] Getting user data with token..."
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/user"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("GET")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    if request.AsyncGetToString() then
        msg = wait(10000, port) ' 10 second timeout
        if msg <> invalid and type(msg) = "roUrlEvent" then
            if msg.GetResponseCode() = 200 then
                response = msg.GetString()
                print "[ApiTask] User data received successfully (after refresh)"
                return ParseJson(response)
            else
                print "[ApiTask] User data API error after token refresh: "; msg.GetResponseCode()
            end if
        end if
    end if

    return invalid
end function