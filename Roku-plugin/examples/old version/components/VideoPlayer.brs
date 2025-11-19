' ********** Seedr for Roku - Video Player Logic **********

sub init()
    m.videoNode = m.top.findNode("videoNode")

    ' Set up video event handling
    m.videoNode.observeField("state", "onVideoStateChange")
    m.videoNode.observeField("position", "onPositionChange")

    ' Handle playback requests from parent
    m.top.observeField("playVideo", "onPlayVideo")

    ' Set up parent observers after a delay to ensure parent is available
    m.setupTimer = CreateObject("roSGNode", "Timer")
    m.setupTimer.duration = 0.1
    m.setupTimer.observeField("fire", "setupParentObservers")
    m.setupTimer.control = "start"
end sub

sub setupParentObservers()
    parent = m.top.getParent()
    if parent <> invalid then
        parent.observeField("screenWidth", "setupLayout")
        parent.observeField("screenHeight", "setupLayout")
        ' Trigger initial layout setup
        setupLayout()
    end if
end sub

sub setupLayout()
    parent = m.top.getParent()
    if parent <> invalid then
        ' Check if screen dimensions are available and valid
        screenWidth = 1280 ' Default HD width
        screenHeight = 720 ' Default HD height

        if parent.screenWidth <> invalid and parent.screenHeight <> invalid then
            if parent.screenWidth > 0 and parent.screenHeight > 0 then
                screenWidth = parent.screenWidth
                screenHeight = parent.screenHeight
            end if
        end if

        print "[VideoPlayer] Using screen dimensions: "; screenWidth; "x"; screenHeight

        m.videoNode.width = screenWidth
        m.videoNode.height = screenHeight
    end if
end sub

sub onPlayVideo()
    playData = m.top.playVideo
    if playData <> invalid then
        playVideoUrl(playData.url, playData.title)
    end if
end sub

sub playVideoUrl(url as string, title as string)
    ' Create video content
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = url
    videoContent.title = title
    videoContent.streamFormat = "hls" ' Seedr provides HLS streams

    ' Set content and play
    m.videoNode.content = videoContent
    m.videoNode.control = "play"

    ' Show video player
    m.top.visible = true
    m.videoNode.setFocus(true)
end sub

sub onVideoStateChange()
    state = m.videoNode.state

    if state = "error" then
        showError("Video playback error")
        hidePlayer()
    else if state = "finished" then
        hidePlayer()
    end if
end sub

sub onPositionChange()
    ' Could implement progress tracking here
end sub

sub hidePlayer()
    m.top.visible = false

    ' Return focus to grid
    gridScreen = m.top.getParent().findNode("gridScreen")
    if gridScreen <> invalid then
        gridScreen.findNode("fileGrid").setFocus(true)
    end if
end sub

sub showError(message as string)
    errorDialog = m.top.getParent().findNode("errorDialog")
    if errorDialog <> invalid then
        errorDialog.findNode("errorMessage").text = message
        errorDialog.visible = true
    end if
end sub
