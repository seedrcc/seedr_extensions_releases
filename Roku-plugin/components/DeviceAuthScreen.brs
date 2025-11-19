' ********** Modern Device Authorization Screen Logic - Spotify Style **********

sub init()
    print "[DeviceAuthScreen] Initializing modern auth screen..."

    ' Get main container references
    m.mainAuthContainer = m.top.findNode("mainAuthContainer")
    m.loadingState = m.top.findNode("loadingState")
    m.authOptionsContainer = m.top.findNode("authOptionsContainer")
    m.successState = m.top.findNode("successState")
    m.errorState = m.top.findNode("errorState")
    m.successContent = m.top.findNode("successContent")
    m.errorContent = m.top.findNode("errorContent")

    ' Get UI element references
    m.authUrlLabel = m.top.findNode("authUrlLabel")
    m.userCodeLabel = m.top.findNode("userCodeLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.timerLabel = m.top.findNode("timerLabel")
    m.timerBar = m.top.findNode("timerBar")
    m.errorMessage = m.top.findNode("errorMessage")
    m.qrCodeText = m.top.findNode("qrCodeText")
    m.qrCodeImage = m.top.findNode("qrCodeImage")
    m.qrCodeLabel = m.top.findNode("qrCodeLabel")

    ' Get screen dimensions
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    m.screenWidth = displaySize.w
    m.screenHeight = displaySize.h
    print "[DeviceAuthScreen] Screen size: "; m.screenWidth; "x"; m.screenHeight

    ' Button references for navigation (these don't exist in current XML, so set to invalid)
    m.appLoginButton = invalid
    m.passwordLoginButton = invalid
    m.signUpButton = invalid

    ' Initialize focused button index
    m.focusedButton = 0
    m.buttons = []

    ' Code labels will use the single userCodeLabel from XML

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

    ' Animation timer for loading spinner
    m.spinnerTimer = CreateObject("roSGNode", "Timer")
    m.spinnerTimer.duration = 0.1
    m.spinnerTimer.repeat = true
    m.spinnerTimer.observeField("fire", "animateSpinner")
    m.spinnerRotation = 0

    ' Set up visibility observer
    m.top.observeField("visible", "onVisibilityChange")

    print "[DeviceAuthScreen] Modern auth screen initialized"
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
        stopAllTimers()
    end if
    print "[DeviceAuthScreen] ============================================================="
end sub

sub startAuthentication()
    ' Check for existing valid token
    if hasValidToken() then
        showSuccessState()
        m.successTimer = CreateObject("roSGNode", "Timer")
        m.successTimer.duration = 3.0
        m.successTimer.observeField("fire", "completeAuth")
        m.successTimer.control = "start"
        return
    end if

    ' Show loading briefly
    showLoadingState()

    ' Request device code
    print "[DeviceAuthScreen] Requesting device code..."
    m.apiTask.request = { method: "device_code" }
    m.apiTask.control = "RUN"
end sub

sub showLoadingState()
    m.loadingState.visible = true
    m.authOptionsContainer.visible = false
    m.successState.visible = false
    m.errorState.visible = false
    m.spinnerTimer.control = "start"
end sub

sub showAuthOptions()
    m.loadingState.visible = false
    m.authOptionsContainer.visible = true
    m.successState.visible = false
    m.errorState.visible = false
    m.spinnerTimer.control = "stop"

    ' Update button focus
    updateButtonFocus()
end sub

sub showSuccessState()
    m.loadingState.visible = false
    m.authOptionsContainer.visible = false

    ' Position success content at screen center
    if m.successContent <> invalid then
        centerX = m.screenWidth / 2
        centerY = m.screenHeight / 2
        m.successContent.translation = [centerX, centerY]
        print "[DeviceAuthScreen] Success content positioned at: "; m.successContent.translation
    end if

    m.successState.visible = true
    m.errorState.visible = false
    stopAllTimers()

    print "[DeviceAuthScreen] Success state shown for screen: "; m.screenWidth; "x"; m.screenHeight
end sub

sub showErrorState(message as string)
    m.loadingState.visible = false
    m.authOptionsContainer.visible = false
    m.successState.visible = false

    ' Position error content at screen center
    if m.errorContent <> invalid then
        centerX = m.screenWidth / 2
        centerY = m.screenHeight / 2
        m.errorContent.translation = [centerX, centerY]
        print "[DeviceAuthScreen] Error content positioned at: "; m.errorContent.translation
    end if

    m.errorState.visible = true
    m.errorMessage.text = message

    stopAllTimers()

    print "[DeviceAuthScreen] Error state shown for screen: "; m.screenWidth; "x"; m.screenHeight
end sub

sub onApiResponse()
    response = m.apiTask.response

    if response.type = "device_code" then
        if response.success and response.data <> invalid and response.data.user_code <> invalid then
            handleDeviceCodeResponse(response.data)
        else
            showErrorState("Could not get device code. Check network connection.")
        end if

    else if response.type = "poll_token" then
        handlePollResponse(response)
    end if
end sub

sub handleDeviceCodeResponse(data)
    print "[DeviceAuthScreen] ==================== DEVICE CODE RESPONSE ===================="
    print "[DeviceAuthScreen] Got device code: "; data.user_code
    print "[DeviceAuthScreen] Device Code: "; data.device_code

    ' Display the auth options
    showAuthOptions()

    ' Use the full verification URL like the working version
    fullVerificationUrl = "https://v2.seedr.cc/api/v0.1/p/oauth/device/verify?code=" + data.user_code
    m.authUrlLabel.text = fullVerificationUrl

    print "[DeviceAuthScreen] Full verification URL: "; fullVerificationUrl
    print "[DeviceAuthScreen] URL Length: "; Len(fullVerificationUrl)

    ' Display the user code in the single label (use directly like working version)
    if data.user_code <> invalid then
        m.userCodeLabel.text = data.user_code

        ' Update QR code label below the QR image
        if m.qrCodeLabel <> invalid then
            m.qrCodeLabel.text = "CODE: " + data.user_code
        end if

        ' Generate and load actual QR code image
        generateQRCode(fullVerificationUrl, data.user_code)
    end if

    ' Set up timer
    if data.expires_in <> invalid then
        m.expiresIn = Int(data.expires_in)
        print "[DeviceAuthScreen] API returned expires_in: "; data.expires_in; " seconds"
    else
        m.expiresIn = 1800 ' Default 30 minutes
        print "[DeviceAuthScreen] No expires_in from API, using default: 1800 seconds (30 minutes)"
    end if

    m.timeRemaining = m.expiresIn
    m.totalTime = m.expiresIn
    print "[DeviceAuthScreen] Timer initialized: timeRemaining="; m.timeRemaining; " totalTime="; m.totalTime
    updateTimerDisplay()
    m.countdownTimer.control = "start"
    print "[DeviceAuthScreen] Countdown timer started, will expire in "; m.expiresIn; " seconds ("; Int(m.expiresIn / 60); " minutes)"

    ' Start polling
    m.deviceCode = data.device_code
    m.pollingAttempts = 0

    print "[DeviceAuthScreen] ==================== STARTING POLLING ===================="
    print "[DeviceAuthScreen] Device Code for polling: "; m.deviceCode
    print "[DeviceAuthScreen] Polling interval: 5 seconds"
    print "[DeviceAuthScreen] Timer expires in: "; m.expiresIn; " seconds"
    print "[DeviceAuthScreen] Starting polling now..."
    print "[DeviceAuthScreen] Expires in: "; data.expires_in; " seconds"
    print "[DeviceAuthScreen] =============================================================="

    m.pollingTimer.control = "start"

    ' Update status
    m.statusLabel.text = "Waiting for authorization..."
end sub

sub handlePollResponse(response)
    if response.success and response.data <> invalid then
        if response.data.access_token <> invalid then
            ' Authentication successful
            stopAllTimers()

            ' Save credentials
            saveCredentials(response.data.access_token, response.data.refresh_token)

            ' Show success
            showSuccessState()

            ' Complete after delay
            m.successTimer = CreateObject("roSGNode", "Timer")
            m.successTimer.duration = 3.0
            m.successTimer.observeField("fire", "completeAuth")
            m.successTimer.control = "start"

        else if response.data.error <> invalid then
            handlePollError(response.data.error)
        end if
    end if
end sub

sub handlePollError(error as string)
    if error = "authorization_pending" then
        ' Normal - continue polling
        m.statusLabel.text = "Waiting for authorization..."
    else if error = "slow_down" then
        ' Slow down polling
        m.pollingTimer.duration = 10.0
        m.statusLabel.text = "Waiting for authorization..."
    else if error = "expired_token" then
        ' Check if client-side timer has actually expired
        if m.timeRemaining <> invalid and m.timeRemaining > 60 then
            ' Server says expired but client timer still has time - keep polling
            print "[DeviceAuthScreen] Server returned expired_token but client timer has "; m.timeRemaining; " seconds left - continuing to poll"
            m.statusLabel.text = "Waiting for authorization..."
        else
            ' Client timer is also expired or close to it - show error
            print "[DeviceAuthScreen] Timer expired ("; m.timeRemaining; " seconds remaining)"
            showErrorState("Device code expired. Please try again.")
        end if
    else
        print "[DeviceAuthScreen] Unknown polling error: "; error
        m.statusLabel.text = "Error: " + error
    end if
end sub

sub updateTimer()
    m.timeRemaining = m.timeRemaining - 1

    ' Log every 60 seconds for debugging
    if m.timeRemaining mod 60 = 0 then
        print "[DeviceAuthScreen] Timer update: "; m.timeRemaining; " seconds remaining ("; Int(m.timeRemaining / 60); " minutes)"
    end if

    if m.timeRemaining <= 0 then
        print "[DeviceAuthScreen] Timer expired! Showing error state"
        showErrorState("Device code expired. Please try again.")
        stopAllTimers()
    else
        updateTimerDisplay()
        updateTimerBar()
    end if
end sub

sub updateTimerDisplay()
    minutes = Int(m.timeRemaining / 60)
    seconds = m.timeRemaining - (minutes * 60)
    m.timerLabel.text = "Expires in " + minutes.toStr() + ":" + Right("0" + seconds.toStr(), 2)
end sub

sub updateTimerBar()
    ' Update the progress bar width based on time remaining
    if m.totalTime > 0 then
        progress = m.timeRemaining / m.totalTime
        newWidth = Int(950 * progress)
        m.timerBar.width = newWidth
    end if
end sub

sub pollForTokenNow()
    m.pollingAttempts = m.pollingAttempts + 1
    print "[DeviceAuthScreen] ==================== POLLING ATTEMPT ===================="
    print "[DeviceAuthScreen] Polling attempt #"; m.pollingAttempts
    print "[DeviceAuthScreen] Device Code: "; m.deviceCode
    print "[DeviceAuthScreen] Time remaining: "; m.timeRemaining; " seconds"
    print "[DeviceAuthScreen] Making API request for token..."
    print "[DeviceAuthScreen] =============================================================="

    m.apiTask.request = {
        method: "poll_token",
        deviceCode: m.deviceCode
    }
    m.apiTask.control = "RUN"
end sub

sub animateSpinner()
    ' Simple spinner rotation animation
    m.spinnerRotation = m.spinnerRotation + 10
    if m.spinnerRotation >= 360 then m.spinnerRotation = 0

    spinner = m.top.findNode("spinner")
    if spinner <> invalid then
        spinner.opacity = 0.5 + (Sin(m.spinnerRotation * 3.14159 / 180) * 0.5)
    end if
end sub

sub updateButtonFocus()
    ' Update visual focus on buttons (skip if no buttons exist)
    if m.buttons.count() = 0 then
        print "[DeviceAuthScreen] No buttons to focus, skipping button focus update"
        return
    end if

    for i = 0 to m.buttons.count() - 1
        buttonGroup = m.buttons[i]
        if buttonGroup <> invalid then
            buttonRect = buttonGroup.getChild(0)
            if buttonRect <> invalid then
                if i = m.focusedButton then
                    ' Highlighted state
                    buttonRect.color = "0x1DB954FF"
                else
                    ' Normal state
                    buttonRect.color = "0x333333FF"
                end if
            end if
        end if
    end for
end sub

sub stopAllTimers()
    if m.countdownTimer <> invalid then m.countdownTimer.control = "stop"
    if m.pollingTimer <> invalid then m.pollingTimer.control = "stop"
    if m.spinnerTimer <> invalid then m.spinnerTimer.control = "stop"
end sub

sub completeAuth()
    print "[DeviceAuthScreen] Authentication complete"
    m.top.authComplete = true
end sub

' Key event handling
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    handled = false

    if m.errorState.visible then
        if key = "OK" or key = "select" then
            ' Retry authentication
            startAuthentication()
            handled = true
        else if key = "back" then
            m.top.backPressed = true
            handled = true
        end if

    else if m.authOptionsContainer.visible then
        if key = "left" and m.buttons.count() > 0 then
            ' Navigate buttons left
            if m.focusedButton > 0 then
                m.focusedButton = m.focusedButton - 1
                updateButtonFocus()
            end if
            handled = true

        else if key = "right" and m.buttons.count() > 0 then
            ' Navigate buttons right
            if m.focusedButton < m.buttons.count() - 1 then
                m.focusedButton = m.focusedButton + 1
                updateButtonFocus()
            end if
            handled = true

        else if key = "OK" or key = "select" then
            ' Handle button selection (only if buttons exist)
            if m.buttons.count() > 0 then
                if m.focusedButton = 0 then
                    ' Log in with app
                    print "[DeviceAuthScreen] App login selected"
                else if m.focusedButton = 1 then
                    ' Log in with password
                    print "[DeviceAuthScreen] Password login selected"
                else if m.focusedButton = 2 then
                    ' Sign up
                    print "[DeviceAuthScreen] Sign up selected"
                end if
                handled = true
            end if

        else if key = "back" then
            stopAllTimers()
            m.top.backPressed = true
            handled = true
        end if

    else if key = "back" then
        stopAllTimers()
        m.top.backPressed = true
        handled = true
    end if

    return handled
end function

' ********** QR Code Generation Functions **********

sub generateQRCode(verificationUrl as string, userCode as string)
    print "[DeviceAuthScreen] ==================== QR CODE GENERATION ===================="
    print "[DeviceAuthScreen] Generating QR code for URL: "; verificationUrl

    ' URL encode the verification URL for QR service
    encodedUrl = encodeUriComponent(verificationUrl)

    ' Generate QR code using external service (qr-server.com)
    qrServiceUrl = "https://api.qrserver.com/v1/create-qr-code/?size=220x220&format=png&data=" + encodedUrl

    print "[DeviceAuthScreen] QR Service URL: "; qrServiceUrl
    print "[DeviceAuthScreen] QR Code will encode: "; verificationUrl
    print "[DeviceAuthScreen] User code: "; userCode

    ' Set loading state
    if m.qrCodeText <> invalid then
        m.qrCodeText.text = "Loading QR..."
        m.qrCodeText.color = "0x888888FF"
    end if

    ' Load QR code image
    if m.qrCodeImage <> invalid then
        m.qrCodeImage.uri = qrServiceUrl
        m.qrCodeImage.observeField("loadStatus", "onQRCodeLoaded")
        print "[DeviceAuthScreen] QR code image loading started..."
    end if

    print "[DeviceAuthScreen] =============================================================="
end sub

sub onQRCodeLoaded()
    loadStatus = m.qrCodeImage.loadStatus
    print "[DeviceAuthScreen] ==================== QR CODE LOAD STATUS ===================="
    print "[DeviceAuthScreen] QR Code load status: "; loadStatus

    if loadStatus = "ready" then
        ' QR code loaded successfully - show image, hide text
        m.qrCodeImage.visible = true
        if m.qrCodeText <> invalid then
            m.qrCodeText.text = ""
            m.qrCodeText.visible = false
        end if
        print "[DeviceAuthScreen] QR code image loaded successfully and displayed"

    else if loadStatus = "failed" then
        ' QR code failed to load - show fallback text
        m.qrCodeImage.visible = false
        if m.qrCodeText <> invalid then
            m.qrCodeText.text = "QR FAILED" + Chr(10) + "Use code below"
            m.qrCodeText.color = "0xFF3333FF"
            m.qrCodeText.visible = true
        end if
        print "[DeviceAuthScreen] QR code image failed to load, showing fallback text"
    end if

    print "[DeviceAuthScreen] =============================================================="
end sub

' Simple URI component encoder for QR code URL
function encodeUriComponent(str as string) as string
    ' Basic URL encoding for common characters
    encoded = str
    encoded = encoded.Replace(" ", "%20")
    encoded = encoded.Replace(":", "%3A")
    encoded = encoded.Replace("/", "%2F")
    encoded = encoded.Replace("?", "%3F")
    encoded = encoded.Replace("=", "%3D")
    encoded = encoded.Replace("&", "%26")
    encoded = encoded.Replace("#", "%23")
    return encoded
end function