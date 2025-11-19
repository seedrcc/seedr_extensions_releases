' ********** Stream URL Task for Video/Audio Streaming **********

sub init()
    print "[StreamUrlTask] Initializing..."
    m.top.functionName = "getStreamUrl"
end sub

sub getStreamUrl()
    print "[StreamUrlTask] Getting stream URL..."
    print "[StreamUrlTask] FileId: "; m.top.fileId
    print "[StreamUrlTask] IsAudio: "; m.top.isAudio

    ' Reset error
    m.top.error = ""
    m.top.streamUrl = ""

    ' Validate inputs
    if m.top.fileId = invalid or m.top.fileId = "" then
        m.top.error = "No file ID provided"
        return
    end if

    if m.top.accessToken = invalid or m.top.accessToken = "" then
        m.top.error = "No access token provided"
        return
    end if

    ' Log token info for debugging
    print "[StreamUrlTask] DEBUG: Token length: "; Len(m.top.accessToken)
    print "[StreamUrlTask] DEBUG: First 20 chars: "; Left(m.top.accessToken, 20)

    ' Build URL based on file type
    ' Ensure fileId is properly converted to string without scientific notation
    if Type(m.top.fileId) = "roString" then
        fileIdStr = m.top.fileId
    else
        fileIdStr = m.top.fileId.ToStr()
    end if

    print "[StreamUrlTask] FileId string: '"; fileIdStr; "'"

    if m.top.isAudio = true then
        ' Audio uses download endpoint
        url = "https://v2.seedr.cc/api/v0.1/p/download/file/" + fileIdStr + "/url"
        print "[StreamUrlTask] Making audio stream request to: "; url
    else
        ' Video uses HLS endpoint
        url = "https://v2.seedr.cc/api/v0.1/p/presentations/file/" + fileIdStr + "/hls"
        print "[StreamUrlTask] Making video stream request to: "; url
    end if

    ' Make HTTP request
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetMessagePort(CreateObject("roMessagePort"))

    ' Set headers
    headers = {}
    headers["Authorization"] = "Bearer " + m.top.accessToken
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    headers["User-Agent"] = "Roku/Seedr"
    request.SetHeaders(headers)

    ' Send request
    if request.AsyncGetToString() then
        msg = wait(10000, request.GetMessagePort()) ' 10 second timeout
        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()
            print "[StreamUrlTask] Response code: "; responseCode

            if responseCode = 200 then
                responseString = msg.GetString()
                print "[StreamUrlTask] Response: "; responseString

                json = ParseJson(responseString)
                if json <> invalid and json.url <> invalid and json.url <> "" then
                    m.top.streamUrl = json.url
                    print "[StreamUrlTask] Got stream URL: "; json.url
                    print "[StreamUrlTask] Stream URL complete: "; json.url
                else
                    m.top.error = "Invalid response format"
                    print "[StreamUrlTask] ERROR: Invalid JSON response"
                end if
            else if responseCode = 401 then
                print "[StreamUrlTask] ERROR: 401 Unauthorized - attempting token refresh"
                print "[StreamUrlTask] Token starts with: "; Left(m.top.accessToken, 10); "..."

                ' Try to refresh the token
                newToken = refreshAccessToken()
                if newToken <> invalid then
                    print "[StreamUrlTask] Token refreshed successfully, retrying request"
                    ' Retry the request with new token
                    headers["Authorization"] = "Bearer " + newToken
                    request.SetHeaders(headers)

                    ' Retry the request
                    if request.AsyncGetToString() then
                        msg = wait(10000, request.GetMessagePort())
                        if type(msg) = "roUrlEvent" and msg.GetResponseCode() = 200 then
                            responseString = msg.GetString()
                            json = ParseJson(responseString)
                            if json <> invalid and json.url <> invalid and json.url <> "" then
                                m.top.streamUrl = json.url
                                print "[StreamUrlTask] Got stream URL after token refresh: "; json.url
                                print "[StreamUrlTask] Stream URL complete: "; json.url
                                return
                            end if
                        end if
                    end if
                end if

                m.top.error = "Authentication failed - token refresh unsuccessful"
            else
                m.top.error = "HTTP error: " + responseCode.ToStr()
                print "[StreamUrlTask] ERROR: HTTP error: "; responseCode
            end if
        else
            m.top.error = "Request timeout"
            print "[StreamUrlTask] ERROR: Request timeout"
        end if
    else
        m.top.error = "Failed to start request"
        print "[StreamUrlTask] ERROR: Failed to start request"
    end if
end sub

' Refresh access token using refresh token
function refreshAccessToken() as string
    credentials = loadCredentials()
    if credentials = invalid or credentials.refreshToken = invalid then
        print "[StreamUrlTask] No refresh token available"
        return invalid
    end if

    config = getApiConfig()
    url = config.baseUrl + "/api/v0.1/p/oauth/token"

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest("POST")
    request.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    postData = "grant_type=refresh_token"
    postData += "&refresh_token=" + credentials.refreshToken
    postData += "&client_id=" + config.clientId

    ' Use synchronous request for simplicity
    response = request.PostFromString(postData)
    if response <> "" then
        json = ParseJson(response)
        if json <> invalid and json.access_token <> invalid then
            ' Save new credentials
            saveCredentials(json.access_token, json.refresh_token)
            print "[StreamUrlTask] Token refreshed successfully"
            return json.access_token
        end if
    end if

    print "[StreamUrlTask] Token refresh failed"
    return invalid
end function
