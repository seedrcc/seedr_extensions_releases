sub init()
    ' Regular item nodes
    m.regularItem = m.top.findNode("regularItem")
    m.poster_node = m.top.findNode("itemPoster")
    m.label_node = m.top.findNode("itemLabel")

    ' Video item node
    m.videoItem = m.top.findNode("videoItem")

    ' Track which type is currently active
    m.isVideoItem = false
end sub

sub showcontent()
    item_content = m.top.itemContent
    if item_content <> invalid then
        ' Check if this is a video file
        isVideo = false
        if item_content.title <> invalid then
            isVideo = isVideoFile(item_content.title)
            print "SeedrFileItem: File '" + item_content.title + "' is video:", isVideo
        end if

        if isVideo then
            print "SeedrFileItem: Showing VideoItem for:", item_content.title
            ' Show video item, hide regular item
            m.regularItem.visible = false
            m.videoItem.visible = true
            m.isVideoItem = true

            ' Create video content node with proper fields
            videoContent = CreateObject("roSGNode", "ContentNode")
            videoContent.title = item_content.title
            videoContent.addFields({
                "posterUri": item_content.HDPosterUrl,
                "url": item_content.url,
                "streamFormat": getVideoFormat(item_content.title),
                "posterWidth": 300,
                "posterHeight": 160
            })

            ' Set progress if available (temporarily disabled for testing)
            progressPercent = 0.0
            ' if item_content.hasField("fileId") then
            '     progressPercent = getVideoProgress(item_content.fileId)
            ' end if
            videoContent.addFields({ "progressPercent": progressPercent })

            ' Pass content to video item
            m.videoItem.itemContent = videoContent
        else
            ' Show regular item, hide video item
            m.regularItem.visible = true
            m.videoItem.visible = false
            m.isVideoItem = false

            ' Regular file handling
            if item_content.HDPosterUrl <> invalid and item_content.HDPosterUrl <> "" then
                m.poster_node.uri = item_content.HDPosterUrl
            else
                m.poster_node.uri = "pkg:/images/icon_focus_hd.jpg"
            end if

            if item_content.title <> invalid then
                m.label_node.text = item_content.title
            else
                m.label_node.text = "Unknown"
            end if
        end if
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
        if registry <> invalid then
            section = registry.GetSection("VideoProgress")
            if section <> invalid then
                progressStr = section.Read(fileId)
                if progressStr <> invalid and progressStr <> "" then
                    progress = progressStr.ToFloat()
                    if progress <> invalid then
                        return progress
                    end if
                end if
            end if
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

' Handle focus changes
sub onFocusPercentChange()
    focusPercent = m.top.focusPercent

    if m.isVideoItem then
        ' Pass focus to video item
        m.videoItem.focusPercent = focusPercent
    else
        ' No focus effects - keep it completely clean and simple
        ' User requested no colors or effects on focus
    end if
end sub
