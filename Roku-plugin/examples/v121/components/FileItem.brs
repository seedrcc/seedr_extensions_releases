' ********** Seedr for Roku - File Item Logic **********

sub init()
    ' Regular item nodes
    m.regularItem = m.top.findNode("regularItem")
    m.background = m.top.findNode("background")
    m.focusRect = m.top.findNode("focusRect")
    m.poster = m.top.findNode("poster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.titleBg = m.top.findNode("titleBg")

    ' Video item node
    m.videoItem = m.top.findNode("videoItem")

    ' Track which type is currently active
    m.isVideoItem = false
end sub

sub showContent()
    itemData = m.top.itemContent
    if itemData <> invalid then
        ' Check if this is a video file
        isVideo = false
        if itemData.title <> invalid then
            isVideo = isVideoFile(itemData.title)
        end if

        if isVideo then
            ' Show video item, hide regular item
            m.regularItem.visible = false
            m.videoItem.visible = true
            m.isVideoItem = true

            ' Create video content node with proper fields
            videoContent = CreateObject("roSGNode", "ContentNode")
            videoContent.title = itemData.title
            videoContent.posterUri = itemData.HDPosterUrl
            videoContent.url = itemData.url
            videoContent.streamFormat = getVideoFormat(itemData.title)
            videoContent.posterWidth = 400
            videoContent.posterHeight = 225

            ' Set progress if available (could be loaded from storage)
            videoContent.progressPercent = getVideoProgress(itemData.id)

            ' Pass content to video item
            m.videoItem.itemContent = videoContent
        else
            ' Show regular item, hide video item
            m.regularItem.visible = true
            m.videoItem.visible = false
            m.isVideoItem = false

            ' Set title
            m.titleLabel.text = itemData.title

            ' Set poster/thumbnail
            if itemData.HDPosterUrl <> invalid and itemData.HDPosterUrl <> "" then
                m.poster.uri = itemData.HDPosterUrl
            else
                ' Use the existing icon_focus_hd.jpg for all items
                m.poster.uri = "pkg:/images/icon_focus_hd.jpg"
            end if

            ' Set background color based on item type
            if itemData.itemType = "folder" then
                m.background.color = "0x3a3a3aFF"
            else if itemData.itemType = "back" then
                m.background.color = "0x4a4a4aFF"
            else
                m.background.color = "0x2a2a2aFF"
            end if
        end if
    end if
end sub

sub focusPercentChanged()
    focusPercent = m.top.focusPercent

    if m.isVideoItem then
        ' Pass focus to video item
        m.videoItem.focusPercent = focusPercent
    else
        ' Handle regular item focus
        ' Animate focus rectangle opacity
        m.focusRect.opacity = focusPercent * 0.8

        ' Scale effect on focus
        scale = 1.0 + (focusPercent * 0.1)
        m.top.scale = [scale, scale]
    end if

    ' Adjust z-order when focused
    if focusPercent > 0.5 then
        m.top.renderOrder = 1
    else
        m.top.renderOrder = 0
    end if
end sub

' Helper function to determine video format from filename
function getVideoFormat(fileName as string) as string
    fileName = LCase(fileName)
    if Right(fileName, 4) = ".mp4" or Right(fileName, 4) = ".m4v" then
        return "mp4"
    else if Right(fileName, 4) = ".mkv" then
        return "mkv"
    else if Right(fileName, 4) = ".avi" then
        return "avi"
    else if Right(fileName, 4) = ".mov" then
        return "mov"
    else if Right(fileName, 5) = ".webm" then
        return "webm"
    else
        return "mp4" ' Default
    end if
end function

' Helper function to get video progress from storage
function getVideoProgress(fileId as string) as float
    if fileId <> invalid and fileId <> "" then
        registry = CreateObject("roRegistry")
        section = registry.GetSection("VideoProgress")
        progressStr = section.Read(fileId)
        if progressStr <> invalid and progressStr <> "" then
            progress = progressStr.ToFloat()
            return progress
        end if
    end if
    return 0.0
end function

' Helper function to check if file is video (local copy of utils function)
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
