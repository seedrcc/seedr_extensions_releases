' ********** Seedr for Roku - Utility Functions **********

' API Configuration
function getApiConfig() as object
    return {
        baseUrl: "https://v2.seedr.cc"
        clientId: "yWbNgXonQzzPY2osP9fJQzN3Sv00YECC"
        scopes: "files.read profile account.read media.read"
    }
end function

' Check if file is a supported video format
function isVideoFile(fileName as string) as boolean
    fileName = LCase(fileName)
    videoExtensions = [".mp4", ".mkv", ".avi", ".mov", ".m4v", ".wmv", ".flv", ".webm"]

    for each ext in videoExtensions
        if Right(fileName, Len(ext)) = ext then
            return true
        end if
    end for

    return false
end function

' Check if file is a supported audio format
function isAudioFile(fileName as string) as boolean
    fileName = LCase(fileName)
    audioExtensions = [".mp3", ".flac", ".wav", ".aac", ".ogg", ".m4a", ".wma"]

    for each ext in audioExtensions
        if Right(fileName, Len(ext)) = ext then
            return true
        end if
    end for

    return false
end function

' Check if file is a supported image format
function isImageFile(fileName as string) as boolean
    fileName = LCase(fileName)
    imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"]

    for each ext in imageExtensions
        if Right(fileName, Len(ext)) = ext then
            return true
        end if
    end for

    return false
end function

' Format file size for display
function formatFileSize(sizeBytes as longinteger) as string
    if sizeBytes < 1024 then
        return Str(sizeBytes) + " B"
    else if sizeBytes < 1048576 then ' 1024^2
        return Str(Int(sizeBytes / 1024)) + " KB"
    else if sizeBytes < 1073741824 then ' 1024^3
        return Str(Int(sizeBytes / 1048576)) + " MB"
    else
        ' Calculate GB with one decimal place manually
        gbSize = sizeBytes / 1073741824
        gbInt = Int(gbSize)
        gbDecimal = Int((gbSize - gbInt) * 10)
        return Str(gbInt) + "." + Str(gbDecimal) + " GB"
    end if
end function

' Get image preview URL - finds best quality thumbnail
function getImagePreviewUrl(fileData as object) as string
    if fileData.presentation_urls <> invalid then
        ' Check if it's an associative array (has image property) or empty array
        if type(fileData.presentation_urls) = "roAssociativeArray" then
            ' It's an associative array, try to access image property
            if fileData.presentation_urls.image <> invalid then
                imageUrls = fileData.presentation_urls.image

                if type(imageUrls) = "roAssociativeArray" then
                    ' Try to get highest quality image available
                    if imageUrls["720"] <> invalid then
                        return imageUrls["720"]
                    else if imageUrls["220"] <> invalid then
                        return imageUrls["220"]
                    else if imageUrls["64"] <> invalid then
                        return imageUrls["64"]
                    else if imageUrls["48"] <> invalid then
                        return imageUrls["48"]
                    end if
                end if
            end if
            ' else: it's an empty array [] - skip to fallback
        end if
    end if

    ' Fallback to thumb if available
    if fileData.thumb <> invalid then
        return fileData.thumb
    end if

    ' No image available
    return ""
end function


