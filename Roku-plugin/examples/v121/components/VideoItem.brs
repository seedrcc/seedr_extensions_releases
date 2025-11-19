sub init()
    print "VideoItem init()"

    m.top.id = "videoItem"
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemMask = m.top.findNode("itemMask")
    m.playButtonOverlay = m.top.findNode("playButtonOverlay")
    m.progressBar = m.top.findNode("progressBar")
    m.progressMask = m.top.findNode("progressMask")
    m.videoTitle = m.top.findNode("videoTitle")

    ' Observe field changes
    m.top.observeField("itemContent", "onShowContent")
    m.top.observeField("focusPercent", "onShowFocus")
    m.top.observeField("progressPercent", "onProgressChange")
end sub

sub onShowContent()
    print "VideoItem onShowContent()"

    itemContent = m.top.itemContent
    if itemContent <> invalid
        ' Set video thumbnail
        if itemContent.posterUri <> invalid and itemContent.posterUri <> ""
            m.itemPoster.uri = itemContent.posterUri
        else
            ' Use default video poster if no thumbnail
            m.itemPoster.uri = "pkg:/images/poster-video.jpg"
        end if

        ' Set video title
        if itemContent.title <> invalid
            m.videoTitle.text = itemContent.title
        else if itemContent.name <> invalid
            m.videoTitle.text = itemContent.name
        else
            m.videoTitle.text = "Video"
        end if

        ' Set dimensions if provided (default to 300x160 for SeedrFileItem)
        posterWidth = 300
        posterHeight = 160

        if itemContent.posterWidth <> invalid
            posterWidth = itemContent.posterWidth
        end if

        if itemContent.posterHeight <> invalid
            posterHeight = itemContent.posterHeight
        end if

        ' Update all elements with correct dimensions
        m.itemPoster.width = posterWidth
        m.itemPoster.height = posterHeight
        m.itemMask.width = posterWidth
        m.itemMask.height = posterHeight
        m.progressBar.width = posterWidth
        m.progressMask.width = posterWidth
        m.videoTitle.width = posterWidth

        ' Center play button
        playButtonX = (posterWidth - 50) / 2
        playButtonY = (posterHeight - 50) / 2
        m.playButtonOverlay.translation = [playButtonX, playButtonY]

        ' Position progress bar at bottom
        progressY = posterHeight - 4
        m.progressBar.translation = [0, progressY]
        m.progressMask.translation = [0, progressY]

        ' Position title below poster
        m.videoTitle.translation = [0, posterHeight + 5]

        ' Set progress if available
        if itemContent.progressPercent <> invalid
            m.progressBar.progressPercent = itemContent.progressPercent
        end if

        ' Choose play button color based on thumbnail brightness
        ' Default to white, but could be enhanced with brightness detection
        m.playButtonOverlay.uri = "pkg:/images/button-img-show-white.png"
    end if
end sub

sub onShowFocus()
    print "VideoItem onShowFocus() - focusPercent:", m.top.focusPercent

    ' Fade overlay masks based on focus
    ' When focused (focusPercent = 1.0), masks become transparent
    ' When unfocused (focusPercent = 0.0), masks are more opaque
    maskOpacity = 0.4 - (m.top.focusPercent * 0.3) ' Range: 0.4 to 0.1
    progressMaskOpacity = 0.4 - (m.top.focusPercent * 0.4) ' Range: 0.4 to 0.0

    m.itemMask.opacity = maskOpacity
    m.progressMask.opacity = progressMaskOpacity

    ' Scale play button slightly on focus for emphasis
    buttonScale = 1.0 + (m.top.focusPercent * 0.1) ' Range: 1.0 to 1.1
    m.playButtonOverlay.scale = [buttonScale, buttonScale]
end sub

sub onProgressChange()
    print "VideoItem onProgressChange() - progressPercent:", m.top.progressPercent

    if m.progressBar <> invalid
        m.progressBar.progressPercent = m.top.progressPercent
    end if
end sub

' Function to update progress from external source
sub updateProgress(progressPercent as float)
    m.top.progressPercent = progressPercent
end sub

' Function to get video file info for playback
function getVideoInfo() as object
    if m.top.itemContent <> invalid
        return {
            url: m.top.itemContent.url,
            title: m.top.itemContent.title,
            streamFormat: m.top.itemContent.streamFormat
        }
    end if
    return invalid
end function
