' ********** Seedr for Roku - Main Scene Logic **********

sub init()
    ' Get references to UI components
    m.authScreen = m.top.findNode("authScreen")
    m.gridScreen = m.top.findNode("gridScreen")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.loadingIndicator = m.top.findNode("loadingIndicator")
    m.errorDialog = m.top.findNode("errorDialog")
    m.statusLabel = m.top.findNode("statusLabel")
    m.background = m.top.findNode("background")
    m.header = m.top.findNode("header")

    ' Set up dynamic screen sizing
    setupScreenSize()

    ' Set up observers
    print "[MainScene] Setting up authComplete observer..."
    m.top.observeField("authComplete", "onAuthComplete")
    m.top.observeField("playVideo", "onPlayVideo")
    print "[MainScene] Observers set up complete"

    ' Set up error dialog
    errorOkButton = m.errorDialog.findNode("errorOkButton")
    if errorOkButton <> invalid then
        errorOkButton.observeField("buttonSelected", "onErrorOkPressed")
    end if

    ' Check authentication status
    checkAuthStatus()
end sub

sub setupScreenSize()
    ' Get screen resolution
    deviceInfo = CreateObject("roDeviceInfo")
    screenSize = deviceInfo.GetDisplaySize()
    m.screenWidth = screenSize.w
    m.screenHeight = screenSize.h

    print "[MainScene] Detected screen size: "; m.screenWidth; "x"; m.screenHeight

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

    ' Update loading indicator position (center of screen)
    m.loadingIndicator.translation = [(m.screenWidth - 200) / 2, (m.screenHeight - 100) / 2]

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

    print "[MainScene] Set screen dimensions on interface: "; m.top.screenWidth; "x"; m.top.screenHeight
end sub

sub checkAuthStatus()
    print "[MainScene] Checking authentication status..."
    if hasValidToken() then
        print "[MainScene] Valid token found, showing grid screen"
        ' Already authenticated, show grid
        showGridScreen()
    else
        print "[MainScene] No valid token, showing auth screen"
        ' Show authentication screen
        showAuthScreen()
    end if
end sub

sub showAuthScreen()
    print "[MainScene] Showing AuthScreen..."
    m.authScreen.visible = true
    m.gridScreen.visible = false
    m.videoPlayer.visible = false
    m.statusLabel.text = "Not authenticated"
    print "[MainScene] AuthScreen visibility set to: "; m.authScreen.visible
end sub

sub showGridScreen()
    print "[MainScene] Showing GridScreen..."
    m.authScreen.visible = false
    m.gridScreen.visible = true
    m.videoPlayer.visible = false
    m.statusLabel.text = "Connected"
    print "[MainScene] GridScreen visibility set to: "; m.gridScreen.visible
end sub

sub onAuthComplete()
    print "[MainScene] onAuthComplete called!"
    print "[MainScene] m.top.authComplete = "; m.top.authComplete
    print "[MainScene] Field type: "; type(m.top.authComplete)

    if m.top.authComplete = true then
        print "[MainScene] Authentication confirmed successful, showing grid screen"
        showGridScreen()
    else
        print "[MainScene] authComplete is not true, value: "; m.top.authComplete
    end if
end sub

sub onPlayVideo()
    if m.top.playVideo <> invalid then
        ' Hide other screens and show video player
        m.authScreen.visible = false
        m.gridScreen.visible = false
        m.videoPlayer.visible = true

        ' Pass video data to player
        m.videoPlayer.playVideo = m.top.playVideo
    end if
end sub

sub onErrorOkPressed()
    ' Hide error dialog
    m.errorDialog.visible = false

    ' Return focus to appropriate screen
    if m.gridScreen.visible then
        m.gridScreen.findNode("fileGrid").setFocus(true)
    else if m.authScreen.visible then
        m.authScreen.setFocus(true)
    end if
end sub

' Key handling
function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        if key = "back" then
            if m.errorDialog.visible then
                m.errorDialog.visible = false
                return true
            else if m.videoPlayer.visible then
                ' Stop video and return to grid
                m.videoPlayer.findNode("videoNode").control = "stop"
                m.videoPlayer.visible = false
                showGridScreen()
                return true
            end if
        end if
    end if
    return false
end function