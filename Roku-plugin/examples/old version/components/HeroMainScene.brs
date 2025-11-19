' ********** Seedr for Roku - Hero Main Scene Logic **********

sub init()
    ' Get references to UI components
    m.authScreen = m.top.findNode("authScreen")
    m.heroScreen = m.top.findNode("heroScreen")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.audioPlayer = m.top.findNode("audioPlayer")
    m.loadingIndicator = m.top.findNode("loadingIndicator")
    m.errorDialog = m.top.findNode("errorDialog")
    m.warningDialog = m.top.findNode("warningDialog")
    m.statusLabel = m.top.findNode("statusLabel")
    m.background = m.top.findNode("background")
    m.header = m.top.findNode("header")
    m.fadeIn = m.top.findNode("fadeIn")
    m.fadeOut = m.top.findNode("fadeOut")

    ' Set up dynamic screen sizing
    setupScreenSize()

    ' Set up observers
    print "[HeroMainScene] Setting up observers..."
    m.top.observeField("authComplete", "onAuthComplete")
    m.top.observeField("playVideo", "onPlayVideo")
    m.top.observeField("content", "onChangeContent")
    m.top.observeField("navigateToFolder", "onNavigateToFolder")
    m.top.observeField("rowItemSelected", "onRowItemSelected")

    ' Create stream URL task
    m.streamUrlTask = CreateObject("roSGNode", "StreamUrlTask")
    m.streamUrlTask.observeField("streamUrl", "onStreamUrlReceived")
    m.streamUrlTask.observeField("error", "onStreamUrlError")

    ' Set up player observers
    m.audioPlayer.observeField("onBackPressed", "onAudioPlayerBack")
    print "[HeroMainScene] Observers set up complete"

    ' Set up error dialog
    errorOkButton = m.errorDialog.findNode("errorOkButton")
    if errorOkButton <> invalid then
        errorOkButton.observeField("buttonSelected", "onErrorOkPressed")
    end if

    ' Set focus to scene
    m.top.setFocus(true)

    ' Check authentication status
    checkAuthStatus()
end sub

sub setupScreenSize()
    ' Get screen resolution
    deviceInfo = CreateObject("roDeviceInfo")
    screenSize = deviceInfo.GetDisplaySize()
    m.screenWidth = screenSize.w
    m.screenHeight = screenSize.h

    print "[HeroMainScene] Detected screen size: "; m.screenWidth; "x"; m.screenHeight

    ' Update background size
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight

    ' Update header size and position
    headerHeight = 80
    if m.screenHeight >= 1080 then
        headerHeight = 100
    end if

    m.header.width = m.screenWidth
    m.header.height = headerHeight

    ' Update status label position
    m.statusLabel.translation = [m.screenWidth - 230, headerHeight * 0.375]

    ' Update content group position
    m.top.findNode("contentGroup").translation = [0, headerHeight]

    ' Update loading indicator size
    m.loadingIndicator.width = m.screenWidth
    m.loadingIndicator.height = m.screenHeight

    ' Update error dialog position (center of screen)
    dialogWidth = 1000
    dialogHeight = 400
    ' Ensure dialog fits on screen
    if dialogWidth > m.screenWidth - 40 then
        dialogWidth = m.screenWidth - 40
    end if
    if dialogHeight > m.screenHeight - 40 then
        dialogHeight = m.screenHeight - 40
    end if

    m.errorDialog.translation = [(m.screenWidth - dialogWidth) / 2, (m.screenHeight - dialogHeight) / 2]

    ' Update dialog size
    errorRect = m.errorDialog.findNode("Rectangle")
    if errorRect <> invalid then
        errorRect.width = dialogWidth
        errorRect.height = dialogHeight
    end if

    ' Store screen dimensions for child components
    m.top.screenWidth = m.screenWidth
    m.top.screenHeight = m.screenHeight

    print "[HeroMainScene] Set screen dimensions on interface: "; m.top.screenWidth; "x"; m.top.screenHeight
end sub

sub checkAuthStatus()
    print "[HeroMainScene] Checking authentication status..."
    if hasValidToken() then
        print "[HeroMainScene] Valid token found, showing hero screen"
        ' Already authenticated, show hero grid
        showHeroScreen()
    else
        print "[HeroMainScene] No valid token, showing auth screen"
        ' Show authentication screen
        showAuthScreen()
    end if
end sub

sub showAuthScreen()
    print "[HeroMainScene] Showing AuthScreen..."
    m.authScreen.visible = true
    m.heroScreen.visible = false
    m.videoPlayer.visible = false
    m.statusLabel.text = "Not authenticated"
    print "[HeroMainScene] AuthScreen visibility set to: "; m.authScreen.visible
end sub

sub showHeroScreen()
    print "[HeroMainScene] Showing HeroScreen..."
    m.authScreen.visible = false
    m.heroScreen.visible = true
    m.videoPlayer.visible = false
    m.statusLabel.text = "Connected"

    print "[HeroMainScene] HeroScreen visibility set to: "; m.heroScreen.visible
end sub

' Content handling is now done by HeroScreen directly

sub playVideo(fileContent as object)
    print "[HeroMainScene] Playing video: "; fileContent.title

    ' Load credentials
    credentials = loadCredentials()
    if credentials = invalid then
        showError("Authentication required")
        return
    end if

    ' Get video stream URL
    streamUrl = getVideoStreamUrlMain(fileContent.fileId, credentials.accessToken)

    if streamUrl <> "" then
        ' Signal to show video player
        m.top.playVideo = {
            url: streamUrl,
            title: fileContent.title
        }
    else
        showError("Could not get video stream URL")
    end if
end sub

sub showImage(fileContent as object)
    ' For now, just show file info
    showFileInfo(fileContent)
end sub

sub showFileInfo(fileContent as object)
    message = "File: " + fileContent.title + chr(10)
    if fileContent.fileData <> invalid then
        if fileContent.fileData.size <> invalid then
            message += "Size: " + formatFileSize(fileContent.fileData.size) + chr(10)
        end if
        if fileContent.fileData.mime_type <> invalid then
            message += "Type: " + fileContent.fileData.mime_type
        end if
    end if
    showError(message) ' Reusing error dialog for info
end sub

sub onAuthComplete()
    print "[HeroMainScene] onAuthComplete called!"
    print "[HeroMainScene] m.top.authComplete = "; m.top.authComplete
    print "[HeroMainScene] Field type: "; type(m.top.authComplete)

    if m.top.authComplete = true then
        print "[HeroMainScene] Authentication confirmed successful, showing hero screen"
        showHeroScreen()
    else
        print "[HeroMainScene] authComplete is not true, value: "; m.top.authComplete
    end if
end sub

sub onPlayVideo()
    playVideoData = m.top.playVideo
    if playVideoData <> invalid then
        print "[HeroMainScene] Received play video request: "; playVideoData.title

        ' Store video data for later use
        m.pendingVideoData = playVideoData

        ' Check if we have a fileId (new format) or url (old format)
        if playVideoData.fileId <> invalid then
            ' New format - get stream URL using Task
            print "[HeroMainScene] Getting stream URL for fileId: "; playVideoData.fileId

            ' Load credentials
            credentials = loadCredentials()
            if credentials <> invalid and credentials.accessToken <> invalid then
                ' Set up task parameters
                m.streamUrlTask.fileId = playVideoData.fileId
                m.streamUrlTask.accessToken = credentials.accessToken
                m.streamUrlTask.isAudio = (playVideoData.isAudio = true)

                ' Start the task
                m.streamUrlTask.control = "RUN"
                print "[HeroMainScene] Started stream URL task"
            else
                print "[HeroMainScene] ERROR: No valid credentials"
                showError("Authentication required")
            end if
        else if playVideoData.url <> invalid then
            ' Old format - direct URL
            print "[HeroMainScene] Using direct URL: "; playVideoData.url

            ' Hide other screens and show video player
            m.authScreen.visible = false
            m.heroScreen.visible = false
            m.videoPlayer.visible = true

            ' Pass video data to player
            m.videoPlayer.playVideo = playVideoData
        else
            print "[HeroMainScene] ERROR: No fileId or url provided"
            showError("Invalid video data")
        end if
    end if
end sub

sub onStreamUrlReceived()
    streamUrl = m.streamUrlTask.streamUrl
    if streamUrl <> invalid and streamUrl <> "" then
        print "[HeroMainScene] Received stream URL: "; streamUrl

        if m.pendingVideoData <> invalid then
            ' Hide other screens
            m.authScreen.visible = false
            m.heroScreen.visible = false
            m.videoPlayer.visible = false
            m.audioPlayer.visible = false

            ' Check if this is audio or video
            if m.pendingVideoData.isAudio = true then
                ' Show audio player for all audio files
                m.audioPlayer.visible = true

                ' Set up audio player with stream URL and metadata
                m.audioPlayer.fileName = m.pendingVideoData.title
                m.audioPlayer.artist = "Seedr"
                m.audioPlayer.album = "My Files"
                m.audioPlayer.albumArt = "" ' No album art for now
                m.audioPlayer.isPlaying = true

                ' For FLAC files, trick Roku into thinking it's MP3
                if streamUrl.InStr(".flac") > 0 then
                    print "[HeroMainScene] FLAC detected - masquerading as MP3 for Roku compatibility"

                    ' Set up audio player with content for actual playback - force MP3 format
                    m.audioPlayer.audioContent = {
                        url: streamUrl,
                        title: m.pendingVideoData.title,
                        streamFormat: "mp3" ' Tell Roku it's MP3 even though it's FLAC
                    }

                    print "[HeroMainScene] FLAC file passed as MP3 format to AudioPlayer"
                else
                    ' Set up audio player with content for actual playback
                    m.audioPlayer.audioContent = {
                        url: streamUrl,
                        title: m.pendingVideoData.title,
                        streamFormat: "mp3"
                    }

                    print "[HeroMainScene] Started regular audio playback: "; m.pendingVideoData.title
                end if
            else
                ' Show video player
                m.videoPlayer.visible = true

                ' Pass stream URL to video player
                m.videoPlayer.playVideo = {
                    url: streamUrl,
                    title: m.pendingVideoData.title
                }

                print "[HeroMainScene] Started video playback: "; m.pendingVideoData.title
            end if
        else
            print "[HeroMainScene] ERROR: No pending video data"
        end if
    else
        print "[HeroMainScene] ERROR: Empty stream URL received"
        showError("Could not get stream URL")
    end if
end sub

sub onStreamUrlError()
    errorMsg = m.streamUrlTask.error
    print "[HeroMainScene] Stream URL error: "; errorMsg
    showError("Stream error: " + errorMsg)
end sub

sub onAudioPlayerBack()
    print "[HeroMainScene] Audio player back pressed"
    ' Hide audio player and show hero screen
    m.audioPlayer.visible = false
    m.heroScreen.visible = true
    m.heroScreen.setFocus(true)
end sub

sub onNavigateToFolder()
    navigationData = m.top.navigateToFolder
    if navigationData <> invalid then
        print "[HeroMainScene] Navigating to folder: "; navigationData.folderName; " (ID: "; navigationData.folderId; ")"

        ' Tell hero screen to navigate to the folder
        m.heroScreen.navigateToFolder = navigationData
    end if
end sub

sub onErrorOkPressed()
    ' Hide error dialog
    m.errorDialog.visible = false

    ' Return focus to appropriate screen
    if m.heroScreen.visible then
        m.heroScreen.setFocus(true)
    else if m.authScreen.visible then
        m.authScreen.setFocus(true)
    end if
end sub

sub showError(message as string)
    m.errorDialog.findNode("errorMessage").text = message
    m.errorDialog.visible = true
end sub

' Key handling
function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        if key = "back" then
            if m.errorDialog.visible then
                m.errorDialog.visible = false
                return true
            else if m.warningDialog.visible then
                m.warningDialog.visible = false
                if m.heroScreen.visible then
                    m.heroScreen.setFocus(true)
                end if
                return true
            else if m.videoPlayer.visible then
                ' Stop video and return to hero screen
                m.videoPlayer.findNode("videoNode").control = "stop"
                m.videoPlayer.visible = false
                showHeroScreen()
                return true
            end if
        else if key = "OK" then
            if m.warningDialog.visible then
                m.warningDialog.visible = false
                if m.heroScreen.visible then
                    m.heroScreen.setFocus(true)
                end if
                return true
            end if
        else if key = "options" then
            if m.warningDialog.visible then
                m.warningDialog.visible = false
                if m.heroScreen.visible then
                    m.heroScreen.setFocus(true)
                end if
                return true
            end if
        end if
    end if
    return false
end function

