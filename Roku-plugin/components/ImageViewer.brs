sub init()
    print "[ImageViewer] ImageViewer init()"

    ' Get references to UI elements
    m.background = m.top.findNode("background")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.mainImage = m.top.findNode("mainImage")
    m.infoOverlay = m.top.findNode("infoOverlay")
    m.imageTitle = m.top.findNode("imageTitle")
    m.imageInfo = m.top.findNode("imageInfo")
    m.controlsHint = m.top.findNode("controlsHint")
    m.errorGroup = m.top.findNode("errorGroup")
    m.errorMessage = m.top.findNode("errorMessage")

    ' Set up observers
    m.top.observeField("imageData", "onImageDataChanged")

    ' Initialize state
    m.infoVisible = true
end sub

sub onImageDataChanged()
    imageData = m.top.imageData
    if imageData <> invalid then
        print "[ImageViewer] Loading image: "; imageData.title
        loadImage(imageData)
    end if
end sub

sub loadImage(imageData as object)
    ' Show loading state
    m.loadingLabel.visible = true
    m.mainImage.visible = false
    m.errorGroup.visible = false
    m.infoOverlay.visible = true

    ' Set image info
    m.imageTitle.text = imageData.title

    ' Build info text
    infoText = ""
    if imageData.fileData <> invalid then
        if imageData.fileData.size <> invalid then
            infoText = infoText + "Size: " + formatFileSizeLocal(imageData.fileData.size)
        end if
        if imageData.fileData.last_update <> invalid then
            if infoText <> "" then infoText = infoText + " • "
            infoText = infoText + "Modified: " + formatDate(imageData.fileData.last_update)
        end if
    end if
    if infoText = "" then infoText = "Image file"
    m.imageInfo.text = infoText

    ' Get image URL
    imageUrl = getImageUrl(imageData)
    if imageUrl <> invalid and imageUrl <> "" then
        print "[ImageViewer] Loading image from URL: "; Left(imageUrl, 50); "..."

        ' Set up image loading
        m.mainImage.observeField("loadStatus", "onImageLoaded")
        m.mainImage.uri = imageUrl
    else
        showError("Could not get image URL")
    end if
end sub

function getImageUrl(imageData as object) as string
    ' Try to get image URL from different possible sources

    ' First check for direct poster URLs (most likely to work)
    if imageData.hdPosterUrl <> invalid and imageData.hdPosterUrl <> "" then
        print "[ImageViewer] Using hdPosterUrl: "; Left(imageData.hdPosterUrl, 50); "..."
        return imageData.hdPosterUrl
    end if

    if imageData.HDPosterUrl <> invalid and imageData.HDPosterUrl <> "" then
        print "[ImageViewer] Using HDPosterUrl: "; Left(imageData.HDPosterUrl, 50); "..."
        return imageData.HDPosterUrl
    end if

    ' Check file data for URLs
    if imageData.fileData <> invalid then
        ' Check for presentation URLs (like thumbnails)
        if imageData.fileData.presentation_urls <> invalid then
            ' Use the first available presentation URL
            for each urlKey in imageData.fileData.presentation_urls
                url = imageData.fileData.presentation_urls[urlKey]
                if url <> invalid and url <> "" then
                    print "[ImageViewer] Using presentation URL: "; Left(url, 50); "..."
                    return url
                end if
            end for
        end if

        ' Check for thumb URL
        if imageData.fileData.thumb <> invalid and imageData.fileData.thumb <> "" then
            print "[ImageViewer] Using thumb URL: "; Left(imageData.fileData.thumb, 50); "..."
            return imageData.fileData.thumb
        end if
    end if

    ' No direct image URL available - this will be handled by the error case
    print "[ImageViewer] No image URL found in file data"
    return ""
end function

sub onImageLoaded()
    loadStatus = m.mainImage.loadStatus
    print "[ImageViewer] Image load status: "; loadStatus

    if loadStatus = "ready" then
        ' Image loaded successfully
        m.loadingLabel.visible = false
        m.mainImage.visible = true

        ' Fit image to screen while maintaining aspect ratio
        fitImageToScreen()

    else if loadStatus = "failed" then
        ' Image failed to load
        showError("Failed to load image")
    end if
end sub

sub fitImageToScreen()
    ' Get image dimensions (if available)
    bitmapInfo = m.mainImage.bitmapInfo
    if bitmapInfo <> invalid then
        imageWidth = bitmapInfo.width
        imageHeight = bitmapInfo.height
        screenWidth = 1280
        screenHeight = 720

        print "[ImageViewer] Image size: "; imageWidth; "x"; imageHeight

        ' Calculate scaling to fit screen while maintaining aspect ratio
        scaleX = screenWidth / imageWidth
        scaleY = screenHeight / imageHeight
        if scaleX < scaleY then
            scale = scaleX
        else
            scale = scaleY
        end if

        ' Apply scaling and centering
        newWidth = imageWidth * scale
        newHeight = imageHeight * scale

        m.mainImage.width = newWidth
        m.mainImage.height = newHeight
        m.mainImage.translation = [(screenWidth - newWidth) / 2, (screenHeight - newHeight) / 2]

        print "[ImageViewer] Scaled image to: "; newWidth; "x"; newHeight
    else
        ' Fallback: use full screen
        m.mainImage.width = 1280
        m.mainImage.height = 720
        m.mainImage.translation = [0, 0]
    end if
end sub

sub showError(message as string)
    print "[ImageViewer] Error: "; message

    m.loadingLabel.visible = false
    m.mainImage.visible = false
    m.infoOverlay.visible = false
    m.errorGroup.visible = true
    m.errorMessage.text = message
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        print "[ImageViewer] Key pressed: "; key

        if key = "back" then
            print "[ImageViewer] Back pressed - returning to previous screen"
            m.top.onBackPressed = true
            return true

        else if key = "OK" then
            ' Toggle info overlay visibility
            m.infoVisible = not m.infoVisible
            m.infoOverlay.visible = m.infoVisible
            print "[ImageViewer] Toggled info overlay: "; m.infoVisible
            return true
        end if
    end if

    return false
end function

' Helper function to format file size (local implementation)
function formatFileSizeLocal(sizeBytes as longinteger) as string
    if sizeBytes < 1024 then
        return sizeBytes.ToStr() + " B"
    else if sizeBytes < 1048576 then ' 1024 * 1024
        return Int(sizeBytes / 1024).ToStr() + " KB"
    else if sizeBytes < 1073741824 then ' 1024 * 1024 * 1024
        return Int(sizeBytes / 1048576).ToStr() + " MB"
    else
        return Int(sizeBytes / 1073741824).ToStr() + " GB"
    end if
end function

' Helper function to format date
function formatDate(timestamp as string) as string
    ' Simple date formatting - could be enhanced
    if timestamp <> invalid and Len(timestamp) >= 10 then
        return Left(timestamp, 10) ' Just return YYYY-MM-DD part
    end if
    return "Unknown"
end function
