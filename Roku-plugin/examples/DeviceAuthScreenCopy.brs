' ********** Seedr for Roku - Device Authorization Screen Logic **********

sub init()
    print "[DeviceAuthScreen] Initializing..."

    ' Get state group references
    m.connectingState = m.top.findNode("connectingState")
    m.authState = m.top.findNode("authState")
    m.successState = m.top.findNode("successState")

    ' Get label references
    m.connectingStatus = m.top.findNode("connectingStatus")
    m.connectingProgress = m.top.findNode("connectingProgress")
    m.authUrlLabel = m.top.findNode("authUrlLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.timerLabel = m.top.findNode("timerLabel")

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

    ' Set up visibility observer
    m.top.observeField("visible", "onVisibilityChange")

    print "[DeviceAuthScreen] Initialization complete"
end sub

sub onVisibilityChange()
    print "[DeviceAuthScreen] ==================== VISIBILITY CHANGE ===================="
    print "[DeviceAuthScreen] Visibility changed to: "; m.top.visible
    print "[DeviceAuthScreen] Screen dimensions: 1280x720 (full screen layout)"
    if m.top.visible then
        print "[DeviceAuthScreen] Screen became visible, starting authentication..."
        print "[DeviceAuthScreen] Layout: Upper-left positioning, full screen width"
        startAuthentication()
    else
        print "[DeviceAuthScreen] Screen became hidden, stopping timers..."
        ' Stop timers when screen is hidden
        if m.countdownTimer <> invalid then m.countdownTimer.control = "stop"
        if m.pollingTimer <> invalid then m.pollingTimer.control = "stop"
    end if
    print "[DeviceAuthScreen] ============================================================="
end sub

sub startAuthentication()
    print "[DeviceAuthScreen] Starting authentication process..."

    ' Check if we already have valid credentials
    if hasValidToken() then
        print "[DeviceAuthScreen] Valid token found, showing success..."
        showSuccessState()
        ' Add delay before completing auth
        m.successTimer = CreateObject("roSGNode", "Timer")
        m.successTimer.duration = 2.0
        m.successTimer.observeField("fire", "completeAuth")
        m.successTimer.control = "start"
        return
    end if

    ' Show connecting state and start device code request
    showConnectingState()
    m.connectingStatus.text = "Requesting device code from Seedr..."
    m.connectingProgress.text = "Connecting to Seedr..."

    print "[DeviceAuthScreen] Requesting device code via Task..."
    m.apiTask.request = { method: "device_code" }
    m.apiTask.control = "RUN"
end sub

sub showConnectingState()
    print "[DeviceAuthScreen] Showing connecting state"
    m.connectingState.visible = true
    m.authState.visible = false
    m.successState.visible = false
end sub

sub showAuthState()
    print "[DeviceAuthScreen] Showing auth state"
    m.connectingState.visible = false
    m.authState.visible = true
    m.successState.visible = false
end sub

sub showSuccessState()
    print "[DeviceAuthScreen] Showing success state"
    m.connectingState.visible = false
    m.authState.visible = false
    m.successState.visible = true
end sub

sub onApiResponse()
    response = m.apiTask.response

    if response.type = "device_code" then
        if response.success and response.data <> invalid and response.data.user_code <> invalid then
            print "[DeviceAuthScreen] Got device code: "; response.data.user_code

            ' Switch to auth state and display the authentication info
            showAuthState()

            ' Use the full verification URL
            fullVerificationUrl = "https://v2.seedr.cc/api/v0.1/p/oauth/device/verify?code=" + response.data.user_code
            m.authUrlLabel.text = fullVerificationUrl
            m.statusLabel.text = "Visit the URL above to complete authorization..."

            print "[DeviceAuthScreen] ==================== DEVICE CODE RESPONSE ===================="
            print "[DeviceAuthScreen] User Code: "; response.data.user_code
            print "[DeviceAuthScreen] Device Code: "; response.data.device_code
            print "[DeviceAuthScreen] Full verification URL: "; fullVerificationUrl
            print "[DeviceAuthScreen] URL Length: "; Len(fullVerificationUrl)
            print "[DeviceAuthScreen] Expires in: "; response.data.expires_in; " seconds"
            print "[DeviceAuthScreen] =========================================================="

            ' Set up timer countdown
            if response.data.expires_in <> invalid then
                m.expiresIn = Int(response.data.expires_in)
            else
                m.expiresIn = 600 ' Default 10 minutes
            end if
            m.timeRemaining = m.expiresIn
            updateTimerDisplay()
            m.countdownTimer.control = "start"

            ' Start polling for token
            m.deviceCode = response.data.device_code
            m.pollingAttempts = 0
            print "[DeviceAuthScreen] ==================== STARTING POLLING ===================="
            print "[DeviceAuthScreen] Device Code for polling: "; m.deviceCode
            print "[DeviceAuthScreen] Polling interval: 5 seconds"
            print "[DeviceAuthScreen] Timer expires in: "; m.expiresIn; " seconds"
            print "[DeviceAuthScreen] Starting polling now..."
            print "[DeviceAuthScreen] =============================================================="
            m.pollingTimer.control = "start"
        else
            print "[DeviceAuthScreen] ERROR: Could not get device code"
            if response.data <> invalid then
                print "[DeviceAuthScreen] Response details: "; response.data
            end if

            ' Show error in auth state
            showAuthState()
            m.authUrlLabel.text = "https://www.seedr.cc/devices"
            m.statusLabel.text = "Error: Could not get device code. Check network connection."
        end if

    else if response.type = "poll_token" then
        print "[DeviceAuthScreen] Poll response data: "; response.data
        if response.success and response.data <> invalid then
            if response.data.access_token <> invalid then
                ' Stop timers and show success
                m.countdownTimer.control = "stop"
                m.pollingTimer.control = "stop"

                print "[DeviceAuthScreen] Authentication successful! Stopping polling."

                ' Save tokens
                saveCredentials(response.data.access_token, response.data.refresh_token)

                ' Show success state
                showSuccessState()

                ' Add delay before completing auth
                m.successTimer = CreateObject("roSGNode", "Timer")
                m.successTimer.duration = 2.0
                m.successTimer.observeField("fire", "completeAuth")
                m.successTimer.control = "start"
            else if response.data.error <> invalid then
                if response.data.error = "authorization_pending" then
                    ' Continue polling - this is expected
                    print "[DeviceAuthScreen] Still waiting for user authorization..."
                else if response.data.error = "slow_down" then
                    print "[DeviceAuthScreen] Slowing down polling as requested"
                    m.pollingTimer.duration = 10.0 ' Increase to 10 seconds
                else if response.data.error = "expired_token" then
                    print "[DeviceAuthScreen] Device code expired"
                    m.statusLabel.text = "Device code expired. Please try again."
                    m.countdownTimer.control = "stop"
                    m.pollingTimer.control = "stop"
                else
                    print "[DeviceAuthScreen] Auth error: "; response.data.error
                    m.statusLabel.text = "Authorization error: " + response.data.error
                end if
            end if
        else
            print "[DeviceAuthScreen] Poll request failed"
        end if
    end if
end sub

sub updateTimer()
    m.timeRemaining = m.timeRemaining - 1
    if m.timeRemaining <= 0 then
        m.countdownTimer.control = "stop"
        m.pollingTimer.control = "stop"
        m.statusLabel.text = "Device code expired. Please try again."
        m.timerLabel.text = "Time remaining: 0 mins 0 seconds"
    else
        updateTimerDisplay()
    end if
end sub

sub updateTimerDisplay()
    minutes = Int(m.timeRemaining / 60)
    seconds = m.timeRemaining - (minutes * 60)
    m.timerLabel.text = "Time remaining: " + Str(minutes).Trim() + " mins " + Str(seconds).Trim() + " seconds"
end sub

sub pollForTokenNow()
    m.pollingAttempts = m.pollingAttempts + 1
    print "[DeviceAuthScreen] Polling attempt #"; m.pollingAttempts; " for device code: "; m.deviceCode

    m.apiTask.request = {
        method: "poll_token",
        deviceCode: m.deviceCode
    }
    m.apiTask.control = "RUN"
end sub

sub completeAuth()
    print "[DeviceAuthScreen] Completing authentication..."
    m.top.authComplete = true
end sub

' Key event handling
function onKeyEvent(key as string, press as boolean) as boolean
    print "[DeviceAuthScreen] Key pressed: "; key; " press: "; press

    if press then
        if key = "back" then
            print "[DeviceAuthScreen] Back button pressed, returning to main auth screen"
            ' Stop timers
            if m.countdownTimer <> invalid then m.countdownTimer.control = "stop"
            if m.pollingTimer <> invalid then m.pollingTimer.control = "stop"

            ' Signal back to parent
            m.top.backPressed = true
            return true
        end if
    end if

    return false
end function

