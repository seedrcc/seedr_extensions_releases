' ********** Seedr for Roku - Authentication Screen Logic **********

sub init()
    ' Get dialog references
    m.connectingDialog = m.top.findNode("connectingDialog")
    m.authDialog = m.top.findNode("authDialog")
    m.connectedDialog = m.top.findNode("connectedDialog")

    ' Get label references
    m.connectingStatus = m.top.findNode("connectingStatus")
    m.connectingProgress = m.top.findNode("connectingProgress")
    m.authUrlLabel = m.top.findNode("authUrlLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.timerLabel = m.top.findNode("timerLabel")
    m.background = m.top.findNode("background")

    ' Create API task for network requests
    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("response", "onApiResponse")

    ' Timer for countdown
    m.countdownTimer = CreateObject("roSGNode", "Timer")
    m.countdownTimer.duration = 1.0
    m.countdownTimer.repeat = true
    m.countdownTimer.observeField("fire", "updateTimer")

    ' Timer for polling (5 second intervals)
    m.pollingTimer = CreateObject("roSGNode", "Timer")
    m.pollingTimer.duration = 5.0
    m.pollingTimer.repeat = true
    m.pollingTimer.observeField("fire", "pollForTokenNow")

    ' Set up dynamic positioning
    m.top.observeField("visible", "onVisibilityChange")

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

        ' Also trigger authentication if we're visible
        if m.top.visible then
            print "[AuthScreen] Component is visible during setup, starting auth..."
            startAuthentication()
        end if
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

        print "[AuthScreen] Using screen dimensions: "; screenWidth; "x"; screenHeight

        ' Calculate content area (excluding header)
        headerHeight = 80
        if screenHeight >= 1080 then
            headerHeight = 100
        end if
        contentHeight = screenHeight - headerHeight

        ' Update background size
        m.background.width = screenWidth
        m.background.height = contentHeight

        ' Center all dialogs in the middle of the screen
        centerX = screenWidth / 2
        centerY = contentHeight / 2

        print "[AuthScreen] Centering dialogs at: "; centerX; ", "; centerY
        m.connectingDialog.translation = [centerX, centerY]
        m.authDialog.translation = [centerX, centerY]
        m.connectedDialog.translation = [centerX, centerY]
    end if
end sub

sub showConnectingDialog()
    print "[AuthScreen] Showing connecting dialog"
    m.connectingDialog.visible = true
    m.authDialog.visible = false
    m.connectedDialog.visible = false
end sub

sub showAuthDialog()
    print "[AuthScreen] Showing auth dialog"
    m.connectingDialog.visible = false
    m.authDialog.visible = true
    m.connectedDialog.visible = false
end sub

sub showConnectedDialog()
    print "[AuthScreen] Showing connected dialog"
    m.connectingDialog.visible = false
    m.authDialog.visible = false
    m.connectedDialog.visible = true
end sub

sub onVisibilityChange()
    print "[AuthScreen] Visibility changed to: "; m.top.visible
    if m.top.visible then
        print "[AuthScreen] AuthScreen became visible, starting auth process..."
        ' Add a small delay to ensure layout is set up first
        m.authTimer = CreateObject("roSGNode", "Timer")
        m.authTimer.duration = 0.5
        m.authTimer.observeField("fire", "startAuthenticationDelayed")
        m.authTimer.control = "start"
        print "[AuthScreen] Auth timer started..."
    end if
end sub

sub startAuthenticationDelayed()
    print "[AuthScreen] Auth timer fired, calling startAuthentication..."
    startAuthentication()
end sub

sub startAuthentication()
    print "[AuthScreen] Starting authentication process..."

    ' Check if we already have valid credentials
    if hasValidToken() then
        print "[AuthScreen] Valid token found, showing connected dialog..."
        showConnectedDialog()
        ' Add delay before completing auth
        m.connectedTimer = CreateObject("roSGNode", "Timer")
        m.connectedTimer.duration = 2.0
        m.connectedTimer.observeField("fire", "completeAuth")
        m.connectedTimer.control = "start"
        return
    end if

    ' Show connecting dialog and start device code request
    showConnectingDialog()
    m.connectingStatus.text = "Requesting device code from Seedr..."
    m.connectingProgress.text = "Connecting to Seedr..."

    print "[AuthScreen] Requesting device code via Task..."
    m.apiTask.request = { method: "device_code" }
    m.apiTask.control = "RUN"
end sub

sub completeAuth()
    print "[AuthScreen] Completing authentication..."

    ' Find the MainScene/HeroMainScene by traversing up the hierarchy
    mainScene = findMainScene()
    if mainScene <> invalid then
        print "[AuthScreen] Found MainScene/HeroMainScene, type: "; type(mainScene)
        print "[AuthScreen] MainScene/HeroMainScene ID: "; mainScene.id

        ' Set the authComplete field on MainScene
        mainScene.setField("authComplete", true)
        print "[AuthScreen] Set authComplete = true on MainScene/HeroMainScene"

        ' Verify it was set
        print "[AuthScreen] Verification - MainScene/HeroMainScene.authComplete = "; mainScene.authComplete
    else
        print "[AuthScreen] ERROR: Could not find MainScene/HeroMainScene"
    end if
end sub

function findMainScene() as object
    ' Start from current node and traverse up to find MainScene/HeroMainScene
    node = m.top
    while node <> invalid
        print "[AuthScreen] Checking node: "; type(node); " ID: "; node.id
        if type(node) = "roSGNode" and (node.subtype() = "MainScene" or node.subtype() = "HeroMainScene") then
            print "[AuthScreen] Found MainScene/HeroMainScene!"
            return node
        end if
        node = node.getParent()
    end while
    print "[AuthScreen] MainScene/HeroMainScene not found in hierarchy"
    return invalid
end function

sub onApiResponse()
    response = m.apiTask.response

    if response.type = "device_code" then
        if response.success and response.data <> invalid and response.data.user_code <> invalid then
            print "[AuthScreen] Got device code: "; response.data.user_code

            ' Switch to auth dialog and display the authentication info
            showAuthDialog()

            ' Use the full verification URL like Kodi - no separate code needed
            fullVerificationUrl = "https://v2.seedr.cc/api/v0.1/p/oauth/device/verify?code=" + response.data.user_code
            m.authUrlLabel.text = fullVerificationUrl
            m.statusLabel.text = "Visit the URL above to complete authorization..."

            print "[AuthScreen] Full verification URL: "; fullVerificationUrl

            ' Set up timer countdown
            if response.data.expires_in <> invalid then
                m.expiresIn = Int(response.data.expires_in) ' Ensure integer
            else
                m.expiresIn = 600 ' Default 10 minutes
            end if
            m.timeRemaining = m.expiresIn
            updateTimerDisplay()
            m.countdownTimer.control = "start"

            ' Start polling for token
            m.deviceCode = response.data.device_code
            m.pollingAttempts = 0
            print "[AuthScreen] Starting polling (5 second intervals)"
            m.pollingTimer.control = "start"
        else
            print "[AuthScreen] ERROR: Could not get device code"
            if response.data <> invalid then
                print "[AuthScreen] Response details: "; response.data
            end if

            ' Show error in auth dialog
            showAuthDialog()
            m.authUrlLabel.text = "https://www.seedr.cc/devices"
            m.statusLabel.text = "Error: Could not get device code. Check network connection."
        end if

    else if response.type = "poll_token" then
        print "[AuthScreen] Poll response data: "; response.data
        if response.success and response.data <> invalid then
            if response.data.access_token <> invalid then
                ' Stop timers and show success
                m.countdownTimer.control = "stop"
                m.pollingTimer.control = "stop"

                print "[AuthScreen] Authentication successful! Stopping polling."

                ' Save tokens
                saveCredentials(response.data.access_token, response.data.refresh_token)

                ' Show connected dialog
                showConnectedDialog()

                ' Add delay before completing auth
                m.connectedTimer = CreateObject("roSGNode", "Timer")
                m.connectedTimer.duration = 2.0
                m.connectedTimer.observeField("fire", "completeAuth")
                m.connectedTimer.control = "start"
            else if response.data.error <> invalid then
                if response.data.error = "authorization_pending" then
                    m.statusLabel.text = "Waiting for authorization..."
                    ' Continue polling silently
                else if response.data.error = "slow_down" then
                    m.statusLabel.text = "Slowing down requests..."
                    ' Continue polling silently
                else
                    m.statusLabel.text = "Error: " + response.data.error
                    print "[AuthScreen] Polling error: "; response.data.error
                end if
            end if
        end if
    end if
end sub

sub pollForTokenNow()
    if m.deviceCode <> invalid then
        m.pollingAttempts = m.pollingAttempts + 1
        ' print "[AuthScreen] Polling attempt #"; m.pollingAttempts; " (every 5 seconds)"

        m.apiTask.request = {
            method: "poll_token"
            deviceCode: m.deviceCode
        }
        m.apiTask.control = "RUN"
    else
        print "[AuthScreen] No device code available for polling"
    end if
end sub

' Old setTimeout mechanism removed - using timer-based polling now

sub updateTimer()
    if m.timeRemaining > 0 then
        m.timeRemaining = m.timeRemaining - 1
        updateTimerDisplay()
    else
        ' Timer expired
        m.countdownTimer.control = "stop"
        m.statusLabel.text = "Authorization timeout. Please try again."
    end if
end sub

sub updateTimerDisplay()
    if m.timeRemaining > 0 then
        minutes = Int(m.timeRemaining / 60)
        seconds = m.timeRemaining - (minutes * 60)
        m.timerLabel.text = "Time remaining: " + Str(minutes) + " mins " + Str(seconds) + " seconds"
    else
        m.timerLabel.text = "Time expired"
    end if
end sub

' Removed GetGlobalPort - not needed with SceneGraph
