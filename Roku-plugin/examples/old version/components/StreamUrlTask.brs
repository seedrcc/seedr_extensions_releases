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

    ' Build URL based on file type
    fileIdStr = m.top.fileId.ToStr()
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
                else
                    m.top.error = "Invalid response format"
                    print "[StreamUrlTask] ERROR: Invalid JSON response"
                end if
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
