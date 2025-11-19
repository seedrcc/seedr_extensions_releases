' ********** Seedr API Client **********

' Make authenticated API request
function makeApiRequest(endpoint as string, accessToken as string, method = "GET" as string) as object
    config = getApiConfig()
    url = config.baseUrl + endpoint

    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetRequest(method)
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Accept", "application/json")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")

    if method = "GET" then
        response = request.GetToString()
    else
        response = request.PostFromString("")
    end if

    if response <> "" then
        return ParseJson(response)
    end if

    return invalid
end function

' Get root folder contents
function getRootFolderContents(accessToken as string) as object
    return makeApiRequest("/api/v0.1/p/fs/root/contents", accessToken)
end function

' Get folder contents by ID
function getFolderContents(folderId as string, accessToken as string) as object
    endpoint = "/api/v0.1/p/fs/folder/" + folderId + "/contents"
    return makeApiRequest(endpoint, accessToken)
end function

' Get file details
function getFileDetails(fileId as string, accessToken as string) as object
    endpoint = "/api/v0.1/p/fs/file/" + fileId
    return makeApiRequest(endpoint, accessToken)
end function

' Get video HLS streaming URL
function getVideoStreamUrl(fileId as string, accessToken as string) as string
    endpoint = "/api/v0.1/p/presentations/file/" + fileId + "/hls"
    response = makeApiRequest(endpoint, accessToken)

    if response <> invalid and response.url <> invalid then
        return response.url
    end if

    return ""
end function

' getImagePreviewUrl moved to utils.brs

' All utility functions moved to utils.brs