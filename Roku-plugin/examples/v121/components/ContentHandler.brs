' ********** Content Handler for Seedr API **********

sub init()
    print "[ContentHandler] Initializing..."
    m.top.functionName = "loadContent"
end sub

sub loadContent()
    print "[ContentHandler] Loading content..."

    ' Reset bad requests counter
    m.top.numBadRequests = 0

    ' Check if we have access token
    if m.top.accessToken = invalid or m.top.accessToken = "" then
        print "[ContentHandler] ERROR: No access token provided"
        m.top.numBadRequests = 1
        return
    end if

    ' Determine what to load based on folderId
    if m.top.folderId = invalid or m.top.folderId = "" then
        ' Load root folder
        loadRootFolder()
    else
        ' Load specific folder
        loadFolder(m.top.folderId)
    end if
end sub

sub loadRootFolder()
    print "[ContentHandler] Loading root folder..."

    ' Make API request for root folder
    response = makeApiRequest("get_folders", {})

    if response <> invalid and response.success then
        ' Create content structure from response
        content = createContentFromResponse(response.data, "Home")
        m.top.content = content
    else
        print "[ContentHandler] ERROR: Failed to load root folder, creating sample data"
        m.top.numBadRequests = 1
        ' Create sample data to show the grid layout
        content = createSampleContent()
        m.top.content = content
    end if
end sub

sub loadFolder(folderId as string)
    print "[ContentHandler] Loading folder: "; folderId

    ' Make API request for specific folder
    response = makeApiRequest("get_folder", { folderId: folderId })

    if response <> invalid and response.success then
        ' Create content structure from response
        content = createContentFromResponse(response.data, "Folder")
        m.top.content = content
    else
        print "[ContentHandler] ERROR: Failed to load folder: "; folderId
        m.top.numBadRequests = 1
        ' Don't show sample data for folder errors, keep current content
    end if
end sub

function makeApiRequest(method as string, params as object) as object
    ' Create URL based on method - using correct Seedr v2 API endpoints
    baseUrl = "https://v2.seedr.cc/api/v0.1/p/fs/"
    url = ""

    if method = "get_folders" then
        url = baseUrl + "root/contents"
    else if method = "get_folder" then
        ' Ensure folderId is treated as string to avoid scientific notation
        folderIdStr = params.folderId.ToStr()
        url = baseUrl + "folder/" + folderIdStr + "/contents"
    else
        print "[ContentHandler] ERROR: Unknown method: "; method
        return invalid
    end if

    print "[ContentHandler] Making request to: "; url

    ' Make HTTP request with Bearer token authentication
    request = CreateObject("roUrlTransfer")
    request.SetUrl(url)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetMessagePort(CreateObject("roMessagePort"))

    ' Set headers for authentication and content type
    headers = {}
    headers["Authorization"] = "Bearer " + m.top.accessToken
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    headers["User-Agent"] = "Roku/Seedr App"
    headers["Accept"] = "application/json"
    request.SetHeaders(headers)

    if request.AsyncGetToString() then
        ' Wait for response
        msg = wait(10000, request.GetMessagePort()) ' 10 second timeout

        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()
            responseString = msg.GetString()

            print "[ContentHandler] Response code: "; responseCode

            if responseCode = 200 then
                ' Parse JSON response
                json = ParseJson(responseString)
                if json <> invalid then
                    return {
                        success: true,
                        data: json
                    }
                else
                    print "[ContentHandler] ERROR: Failed to parse JSON response"
                    return { success: false }
                end if
            else
                print "[ContentHandler] ERROR: HTTP error: "; responseCode
                return { success: false }
            end if
        else
            print "[ContentHandler] ERROR: Request timeout or failed"
            return { success: false }
        end if
    else
        print "[ContentHandler] ERROR: Failed to start request"
        return { success: false }
    end if
end function

function createContentFromResponse(data as object, contextName as string) as object
    print "[ContentHandler] Creating content from response for: "; contextName

    ' Create root content node
    content = CreateObject("roSGNode", "ContentNode")

    ' Create different rows for different content types
    ' Row 1: Featured/Recent (hero row)
    featuredRow = content.CreateChild("ContentNode")
    featuredRow.title = "Featured"

    ' Row 2: Folders
    folderRow = content.CreateChild("ContentNode")
    folderRow.title = "Folders"

    ' Row 3: Videos
    videoRow = content.CreateChild("ContentNode")
    videoRow.title = "Videos"

    ' Row 4: Other Files
    otherRow = content.CreateChild("ContentNode")
    otherRow.title = "Other Files"

    ' When in a folder, prioritize video files in Featured section
    inFolder = (m.top.folderId <> invalid and m.top.folderId <> "")
    if inFolder then
        ' Change Featured row title to show videos prominently
        featuredRow.title = "Videos"
    else
        featuredRow.title = "Featured"
    end if

    ' Add "Back" button if we're not in root folder (based on main.py logic)
    if inFolder then
        ' Add back navigation item to folder row
        backItem = folderRow.CreateChild("ContentNode")
        backItem.title = ".. (Back)"
        backItem.addFields({ "itemType": "back", "folderId": "" }) ' Empty folderId means go to root
        backItem.HDPosterUrl = "" ' No poster, will show background color
        backItem.hdBackgroundImageUrl = "pkg:/images/background.jpg"
        print "[ContentHandler] Added back navigation item"
    end if

    ' Process folders if available
    if data.folders <> invalid then
        print "[ContentHandler] Processing "; data.folders.Count(); " folders"

        for each folder in data.folders
            ' Add to folder row
            item = folderRow.CreateChild("ContentNode")
            item.title = getFolderName(folder)
            item.addFields({ "itemType": "folder", "folderId": folder.id.ToStr() })
            item.HDPosterUrl = "" ' No poster URL for folders - will show background color
            item.hdBackgroundImageUrl = "pkg:/images/background.jpg"

            ' Add first few folders to featured row as well
            if folderRow.getChildCount() <= 3 then
                featuredItem = featuredRow.CreateChild("ContentNode")
                featuredItem.title = item.title
                featuredItem.addFields({ "itemType": "folder", "folderId": folder.id.ToStr() })
                featuredItem.HDPosterUrl = "" ' No poster URL for folders
                featuredItem.hdBackgroundImageUrl = item.hdBackgroundImageUrl
            end if
        end for
    end if

    ' Process files if available
    if data.files <> invalid then
        print "[ContentHandler] Processing "; data.files.Count(); " files"

        for each file in data.files
            item = invalid
            fileName = file.name

            ' Determine file type based on Seedr API flags and file extension
            ' When in a folder (not root), prioritize video files by putting them in featured row too
            inFolder = (m.top.folderId <> invalid and m.top.folderId <> "")

            if file.is_video = true then
                if inFolder then
                    ' When in folders, put ALL videos in Featured row (large display)
                    item = featuredRow.CreateChild("ContentNode")
                    print "[ContentHandler] Added video to featured row: "; fileName
                else
                    ' When in root, put videos in Videos row
                    item = videoRow.CreateChild("ContentNode")
                    print "[ContentHandler] Added video file: "; fileName
                end if

            else if file.is_audio = true then
                item = videoRow.CreateChild("ContentNode") ' Put audio in video row
                print "[ContentHandler] Added audio file: "; fileName
            else if file.is_image = true or isImageFile(fileName) then
                item = otherRow.CreateChild("ContentNode")
                print "[ContentHandler] Added image file: "; fileName
            else
                item = otherRow.CreateChild("ContentNode")
                print "[ContentHandler] Added other file: "; fileName
            end if

            if item <> invalid then
                item.title = fileName
                item.addFields({ "itemType": "file", "fileId": file.id.ToStr(), "fileData": file })

                ' Set appropriate icon based on file type (based on main.py logic)
                if file.is_video = true then
                    ' For videos, try to get thumbnail first
                    posterUrl = getBestImageUrl(file)
                    if posterUrl <> "" then
                        item.HDPosterUrl = posterUrl
                    else
                        item.HDPosterUrl = "" ' No poster, will show background color
                    end if
                else if file.is_audio = true then
                    ' Audio files don't need posters, just background color
                    item.HDPosterUrl = ""
                else if file.is_image = true or isImageFile(fileName) then
                    ' For images, try to get the actual image as thumbnail
                    posterUrl = getBestImageUrl(file)
                    if posterUrl <> "" then
                        item.HDPosterUrl = posterUrl ' Use actual image as thumbnail
                    else
                        item.HDPosterUrl = "" ' No poster, will show background color
                    end if
                else
                    ' For other files (PDFs, docs, etc.), try to get preview
                    posterUrl = getBestImageUrl(file)
                    if posterUrl <> "" then
                        item.HDPosterUrl = posterUrl ' Use preview if available
                    else
                        item.HDPosterUrl = "" ' No poster, will show background color
                    end if
                end if

                item.hdBackgroundImageUrl = "pkg:/images/background.jpg"
            end if
        end for
    end if

    ' Remove empty rows to clean up the display
    childrenToRemove = []

    ' Check each row and mark empty ones for removal
    for i = content.getChildCount() - 1 to 0 step -1
        row = content.getChild(i)
        if row <> invalid and row.getChildCount() = 0 then
            print "[ContentHandler] Removing empty row: "; row.title
            content.removeChild(i)
        end if
    end for

    print "[ContentHandler] Content creation complete"
    print "[ContentHandler] Featured: "; featuredRow.getChildCount(); " items"
    print "[ContentHandler] Folders: "; folderRow.getChildCount(); " items"
    print "[ContentHandler] Videos: "; videoRow.getChildCount(); " items"
    print "[ContentHandler] Other: "; otherRow.getChildCount(); " items"

    return content
end function

function getFolderName(folder as object) as string
    ' Handle both folder.name and folder.path (extract name from path if needed)
    folderName = folder.path
    if folderName = invalid then
        folderName = folder.name
    end if

    if folderName = invalid then
        folderName = "Unknown Folder"
    end if

    return folderName
end function

' Helper functions (these should match your existing utils.brs functions)
function isVideoFile(fileName as string) as boolean
    if fileName = invalid then return false

    lowerName = LCase(fileName)
    videoExtensions = [".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v"]

    for each ext in videoExtensions
        if lowerName.EndsWith(ext) then
            return true
        end if
    end for

    return false
end function

function isImageFile(fileName as string) as boolean
    if fileName = invalid then return false

    lowerName = LCase(fileName)
    imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"]

    for each ext in imageExtensions
        if lowerName.EndsWith(ext) then
            return true
        end if
    end for

    return false
end function

function getImagePreviewUrl(file as object) as string
    ' For now, return empty string - could be enhanced to generate thumbnails
    return ""
end function

function getBestImageUrl(file as object) as string
    ' Get thumbnail from presentation_urls like in main.py (get_best_image_url function)
    ' Always prioritize 720 resolution for thumbnails, then 220 > 64 > 48

    if file <> invalid and file.DoesExist("presentation_urls") then
        presentationUrls = file.presentation_urls
        ' Check if presentationUrls is an associative array (not empty array)
        if presentationUrls <> invalid and type(presentationUrls) = "roAssociativeArray" and presentationUrls.DoesExist("image") then
            imageUrls = presentationUrls.image
            ' Check if imageUrls is also an associative array
            if imageUrls <> invalid and type(imageUrls) = "roAssociativeArray" then
                ' Try different resolutions in priority order (same as main.py)
                if imageUrls.DoesExist("720") then
                    return imageUrls["720"]
                else if imageUrls.DoesExist("220") then
                    return imageUrls["220"]
                else if imageUrls.DoesExist("64") then
                    return imageUrls["64"]
                else if imageUrls.DoesExist("48") then
                    return imageUrls["48"]
                end if
            end if
        end if
    end if

    ' Fallback to thumb if available (same as main.py)
    if file <> invalid and file.DoesExist("thumb") and file.thumb <> invalid and file.thumb <> "" then
        return file.thumb
    end if

    ' Return empty string if no image found (will show background color instead)
    return ""
end function

function createSampleContent() as object
    print "[ContentHandler] Creating sample content for demo"

    ' Create root content node
    content = CreateObject("roSGNode", "ContentNode")

    ' Create different rows for different content types
    ' Row 1: Featured/Recent (hero row)
    featuredRow = content.CreateChild("ContentNode")
    featuredRow.title = "Featured"

    ' Row 2: Folders
    folderRow = content.CreateChild("ContentNode")
    folderRow.title = "Folders"

    ' Row 3: Videos
    videoRow = content.CreateChild("ContentNode")
    videoRow.title = "Videos"

    ' Row 4: Other Files
    otherRow = content.CreateChild("ContentNode")
    otherRow.title = "Other Files"

    ' Add sample featured items
    for i = 1 to 3
        item = featuredRow.CreateChild("ContentNode")
        item.title = "Featured Item " + i.ToStr()
        item.addFields({ "itemType": "folder", "folderId": i.ToStr() })
        item.HDPosterUrl = "pkg:/images/icon_focus_hd.jpg"
        item.hdBackgroundImageUrl = "pkg:/images/background.jpg"
    end for

    ' Add sample folders
    folderNames = ["Movies", "TV Shows", "Music", "Documents", "Downloads"]
    for i = 0 to folderNames.Count() - 1
        item = folderRow.CreateChild("ContentNode")
        item.title = folderNames[i]
        item.addFields({ "itemType": "folder", "folderId": (i + 10).ToStr() })
        item.HDPosterUrl = "pkg:/images/icon_focus_hd.jpg"
        item.hdBackgroundImageUrl = "pkg:/images/background.jpg"
    end for

    ' Add sample videos
    videoNames = ["Sample Movie 1.mp4", "Sample Movie 2.avi", "TV Episode.mkv", "Documentary.mp4"]
    for i = 0 to videoNames.Count() - 1
        item = videoRow.CreateChild("ContentNode")
        item.title = videoNames[i]
        item.addFields({ "itemType": "file", "fileId": (i + 20).ToStr() })
        item.HDPosterUrl = "pkg:/images/icon_focus_hd.jpg"
        item.hdBackgroundImageUrl = "pkg:/images/background.jpg"
    end for

    ' Add sample other files
    otherNames = ["Document.pdf", "Image.jpg", "Archive.zip", "Text.txt"]
    for i = 0 to otherNames.Count() - 1
        item = otherRow.CreateChild("ContentNode")
        item.title = otherNames[i]
        item.addFields({ "itemType": "file", "fileId": (i + 30).ToStr() })
        item.HDPosterUrl = "pkg:/images/icon_focus_hd.jpg"
        item.hdBackgroundImageUrl = "pkg:/images/background.jpg"
    end for

    print "[ContentHandler] Sample content created"
    print "[ContentHandler] Featured: "; featuredRow.getChildCount(); " items"
    print "[ContentHandler] Folders: "; folderRow.getChildCount(); " items"
    print "[ContentHandler] Videos: "; videoRow.getChildCount(); " items"
    print "[ContentHandler] Other: "; otherRow.getChildCount(); " items"

    return content
end function
