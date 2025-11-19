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
        ' Store file ID for progress tracking
        m.currentFileId = playData.fileId
        playVideoUrl(playData.url, playData.title)
    end if
end sub

sub playVideoUrl(url as string, title as string)
    print "[VideoPlayer] playVideoUrl called with URL: "; Left(url, 50); "..."
    print "[VideoPlayer] Title: "; title

    ' Create video content
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = url
    videoContent.title = title
    videoContent.streamFormat = "hls" ' Seedr provides HLS streams
    videoContent.live = false
    videoContent.playStart = 0
    videoContent.hdPosterUrl = "pkg:/images/poster-video.jpg"

    ' Set content and play
    m.videoNode.content = videoContent
    m.videoNode.control = "play"

    print "[VideoPlayer] Video content set, starting playback"

    ' Show video player
    m.top.visible = true
    m.videoNode.setFocus(true)

    print "[VideoPlayer] Video player visibility set to: "; m.top.visible
    print "[VideoPlayer] Video node focus set"
end sub

sub onVideoStateChange()
    state = m.videoNode.state
    print "[VideoPlayer] Video state changed to: "; state

    if state = "error" then
        print "[VideoPlayer] Video playback error occurred"
        ' Get more details about the error
        if m.videoNode.errorCode <> invalid then
            print "[VideoPlayer] Error code: "; m.videoNode.errorCode
        end if
        if m.videoNode.errorMsg <> invalid then
            print "[VideoPlayer] Error message: "; m.videoNode.errorMsg
        end if
        showError("Video playback error: " + Str(m.videoNode.errorCode))
        hidePlayer()
    else if state = "finished" then
        print "[VideoPlayer] Video playback finished"
        ' Clear progress when video is completed
        if m.currentFileId <> invalid then
            clearVideoProgress(m.currentFileId)
        end if
        hidePlayer()
    else if state = "playing" then
        print "[VideoPlayer] Video is now playing"
    else if state = "buffering" then
        print "[VideoPlayer] Video is buffering"
    else if state = "paused" then
        print "[VideoPlayer] Video is paused"
    end if
end sub

sub onPositionChange()
    ' Track video progress for resume functionality
    if m.currentFileId <> invalid and m.videoNode.duration > 0 then
        updateVideoProgress(m.currentFileId, m.videoNode.position, m.videoNode.duration)
    end if
end sub

sub hidePlayer()
    print "[VideoPlayer] ==================== HIDING VIDEO PLAYER ===================="
    print "[VideoPlayer] Stopping video and implementing reverse navigation"
    m.top.visible = false

    ' REVERSE NAVIGATION: Return to FolderDetailsScreen instead of home
    parentScene = m.top.getParent()
    if parentScene <> invalid then
        folderDetailsScreen = parentScene.findNode("folderDetailsScreen")
        if folderDetailsScreen <> invalid then
            print "[VideoPlayer] Returning to FolderDetailsScreen (reverse navigation)"

            ' Hide all other screens
            seedrHomeScene = parentScene.findNode("seedrHomeScene")
            if seedrHomeScene <> invalid then
                seedrHomeScene.visible = false
            end if

            ' Show FolderDetailsScreen
            print "[VideoPlayer] 🟢 MAKING FOLDER DETAILS SCREEN VISIBLE"
            folderDetailsScreen.visible = true
            folderDetailsScreen.setFocus(true)
            print "[VideoPlayer] FolderDetailsScreen restored and focused"
            print "[VideoPlayer] FolderDetailsScreen.visible = "; folderDetailsScreen.visible
        else
            print "[VideoPlayer] WARNING: FolderDetailsScreen not found, falling back to home"
            ' Fallback to home scene if FolderDetailsScreen not found
            seedrHomeScene = parentScene.findNode("seedrHomeScene")
            if seedrHomeScene <> invalid then
                seedrHomeScene.visible = true
                buttonGroup = seedrHomeScene.findNode("button_group_1")
                if buttonGroup <> invalid then
                    buttonGroup.setFocus(true)
                    print "[VideoPlayer] Fallback: Returned focus to home scene"
                end if
            end if
        end if
    else
        print "[VideoPlayer] ERROR: No parent scene found"
    end if
    print "[VideoPlayer] ============================================================="
end sub

sub showError(message as string)
    errorDialog = m.top.getParent().findNode("errorDialog")
    if errorDialog <> invalid then
        errorDialog.findNode("errorMessage").text = message
        errorDialog.visible = true
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        if key = "back" then
            print "[VideoPlayer] ==================== BACK BUTTON PRESSED ===================="
            print "[VideoPlayer] 🔴 BACK BUTTON CLICKED FROM VIDEO PLAYER"
            print "[VideoPlayer] Current time: "; CreateObject("roDateTime").AsSeconds()
            print "[VideoPlayer] Back button pressed, stopping video and hiding player"
            ' Stop video playback
            m.videoNode.control = "stop"
            hidePlayer()
            return true
        else if key = "left" then
            print "[VideoPlayer] Left arrow pressed, seeking backward 10 seconds"
            ' Seek backward 10 seconds
            currentPosition = m.videoNode.position
            newPosition = currentPosition - 10
            if newPosition < 0 then newPosition = 0
            m.videoNode.seek = newPosition
            return true
        else if key = "right" then
            print "[VideoPlayer] Right arrow pressed, seeking forward 10 seconds"
            ' Seek forward 10 seconds
            currentPosition = m.videoNode.position
            duration = m.videoNode.duration
            newPosition = currentPosition + 10
            if newPosition > duration then newPosition = duration
            m.videoNode.seek = newPosition
            return true
        else if key = "fastforward" then
            print "[VideoPlayer] Fast forward pressed, seeking forward 30 seconds"
            ' Seek forward 30 seconds
            currentPosition = m.videoNode.position
            duration = m.videoNode.duration
            newPosition = currentPosition + 30
            if newPosition > duration then newPosition = duration
            m.videoNode.seek = newPosition
            return true
        else if key = "rewind" then
            print "[VideoPlayer] Rewind pressed, seeking backward 30 seconds"
            ' Seek backward 30 seconds
            currentPosition = m.videoNode.position
            newPosition = currentPosition - 30
            if newPosition < 0 then newPosition = 0
            m.videoNode.seek = newPosition
            return true
        else if key = "play" then
            print "[VideoPlayer] Play button pressed, toggling play/pause"
            ' Toggle play/pause
            if m.videoNode.state = "playing" then
                m.videoNode.control = "pause"
            else
                m.videoNode.control = "resume"
            end if
            return true
        end if
    end if
    return false
end function

' ********** Video Progress Tracking Functions **********

' Update progress during video playback
sub updateVideoProgress(fileId as string, position as float, duration as float)
    if duration > 0 then
        progressPercent = (position / duration) * 100.0

        ' Only save if progress is meaningful (between 1% and 95%)
        if progressPercent >= 1.0 and progressPercent <= 95.0 then
            saveVideoProgress(fileId, progressPercent)
        else if progressPercent > 95.0 then
            ' Video is essentially complete, clear progress
            clearVideoProgress(fileId)
        end if
    end if
end sub

' Save video progress to registry
sub saveVideoProgress(fileId as string, progressPercent as float)
    if fileId <> invalid and fileId <> "" then
        registry = CreateObject("roRegistry")
        section = registry.GetSection("VideoProgress")
        section.Write(fileId, progressPercent.ToStr())
        section.Flush()
    end if
end sub

' Clear video progress (when video is completed or reset)
sub clearVideoProgress(fileId as string)
    if fileId <> invalid and fileId <> "" then
        registry = CreateObject("roRegistry")
        section = registry.GetSection("VideoProgress")
        section.Delete(fileId)
        section.Flush()
    end if
end sub
