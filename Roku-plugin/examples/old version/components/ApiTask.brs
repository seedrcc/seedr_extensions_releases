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
            else
                print "[ApiTask] Root folder API error: "; msg.GetResponseCode()
            end if
        else
            print "[ApiTask] Root folder API timeout or invalid response"
        end if
    end if

    return invalid
end function

' Get specific folder contents from Seedr API
function getFolderContents(accessToken as string, folderId as string) as object
    print "[ApiTask] Getting folder contents for ID: "; folderId
    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/fs/" + folderId + "/contents"

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
                print "[ApiTask] Folder API response received"
                return ParseJson(response)
            else
                print "[ApiTask] Folder API error: "; msg.GetResponseCode()
            end if
        else
            print "[ApiTask] Folder API timeout or invalid response"
        end if
    end if

    return invalid
end function