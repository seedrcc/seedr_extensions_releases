' ********** Netflix-Style Authentication Screen Logic **********

sub init()
    print "[AuthScreen] Initializing Netflix-style auth screen..."

    ' Get component references
    m.mainCard = m.top.findNode("mainCard")
    m.signInButton = m.top.findNode("signInButton")
    m.signInBg = m.top.findNode("signInBg")
    m.focusBorder = m.top.findNode("focusBorder")
    m.cardGlow = m.top.findNode("cardGlow")
    m.getHelpGroup = m.top.findNode("getHelpGroup")
    m.helpUnderline = m.top.findNode("helpUnderline")
    m.background = m.top.findNode("background")
    m.featureImage = m.top.findNode("featureImage")

    ' Initialize flags
    m.authTriggered = false

    ' Initialize animations
    initializeAnimations()

    ' Set up dynamic positioning for different screen sizes
    m.top.observeField("visible", "onVisibilityChange")
    m.top.observeField("focusedChild", "onFocusChange")

    ' Set up parent observers after a delay
    m.setupTimer = CreateObject("roSGNode", "Timer")
    m.setupTimer.duration = 0.1
    m.setupTimer.observeField("fire", "setupParentObservers")
    m.setupTimer.control = "start"

    ' Set up focus timer
    m.focusTimer = CreateObject("roSGNode", "Timer")
    m.focusTimer.duration = 0.3
    m.focusTimer.observeField("fire", "setInitialFocus")
    m.focusTimer.control = "start"

    ' Set up button focus observer for visual feedback
    m.signInButton.observeField("hasFocus", "onSignInButtonFocusChange")
    m.mainCard.observeField("hasFocus", "onMainCardFocusChange")

    ' Start card entrance animation
    startEntranceAnimation()

    print "[AuthScreen] Netflix-style auth screen initialized successfully"
end sub

sub initializeAnimations()
    ' Create fade-in animation for card
    m.cardFadeIn = CreateObject("roSGNode", "Animation")
    m.cardFadeIn.duration = 0.8
    m.cardFadeIn.easeFunction = "outQuad"

    ' Create opacity interpolator for card
    m.cardOpacityInterp = CreateObject("roSGNode", "FloatFieldInterpolator")
    m.cardOpacityInterp.key = [0.0, 1.0]
    m.cardOpacityInterp.keyValue = [0.0, 1.0]
    m.cardOpacityInterp.fieldToInterp = "mainCard.opacity"
    m.cardFadeIn.appendChild(m.cardOpacityInterp)

    ' Create slide-in animation for card
    m.cardSlideIn = CreateObject("roSGNode", "Animation")
    m.cardSlideIn.duration = 0.6
    m.cardSlideIn.easeFunction = "outQuad"

    ' Create position interpolator for card
    m.cardPosInterp = CreateObject("roSGNode", "Vector2DFieldInterpolator")
    m.cardPosInterp.key = [0.0, 1.0]
    m.cardPosInterp.keyValue = [[820, 240], [720, 240]]
    m.cardPosInterp.fieldToInterp = "mainCard.translation"
    m.cardSlideIn.appendChild(m.cardPosInterp)

    ' Create glow pulse animation
    m.glowPulse = CreateObject("roSGNode", "Animation")
    m.glowPulse.duration = 2.0
    m.glowPulse.repeat = true
    m.glowPulse.easeFunction = "inOutQuad"

    m.glowOpacityInterp = CreateObject("roSGNode", "FloatFieldInterpolator")
    m.glowOpacityInterp.key = [0.0, 0.5, 1.0]
    m.glowOpacityInterp.keyValue = [0.1, 0.3, 0.1]
    m.glowOpacityInterp.fieldToInterp = "cardGlow.opacity"
    m.glowPulse.appendChild(m.glowOpacityInterp)
end sub

sub startEntranceAnimation()
    ' Set initial state
    m.mainCard.opacity = 0
    m.mainCard.translation = [820, 240]

    ' Start animations
    m.cardFadeIn.control = "start"
    m.cardSlideIn.control = "start"
    m.glowPulse.control = "start"
end sub

sub setupParentObservers()
    parent = m.top.getParent()
    if parent <> invalid then
        parent.observeField("screenWidth", "setupLayout")
        parent.observeField("screenHeight", "setupLayout")
        setupLayout()
    else
        print "[AuthScreen] Parent not found, using default layout"
    end if
end sub

sub setInitialFocus()
    print "[AuthScreen] Setting initial focus..."
    if m.top.visible then
        print "[AuthScreen] Attempting to set focus on Sign In button"
        m.signInButton.setFocus(true)
        print "[AuthScreen] Sign In button focus set, checking result..."
        if m.signInButton.hasFocus() then
            print "[AuthScreen] Sign In button successfully has focus"
            animateButtonFocus(true)
        else
            print "[AuthScreen] ERROR: Sign In button does not have focus"
        end if
    end if
end sub

sub onSignInButtonFocusChange()
    hasFocus = m.signInButton.hasFocus()
    animateButtonFocus(hasFocus)

    if hasFocus then
        print "[AuthScreen] Sign In button gained focus"
    else
        print "[AuthScreen] Sign In button lost focus"
    end if
end sub

sub onMainCardFocusChange()
    hasFocus = m.mainCard.hasFocus()
    print "[AuthScreen] Main card focus changed to: "; hasFocus
    if hasFocus then
        print "[AuthScreen] Main card gained focus, setting focus on Sign In button"
        m.signInButton.setFocus(true)
        ' Check if it worked
        if m.signInButton.hasFocus() then
            print "[AuthScreen] Sign In button now has focus"
        else
            print "[AuthScreen] ERROR: Sign In button still does not have focus"
        end if
    end if
end sub

sub animateButtonFocus(focused as boolean)
    ' Create smooth button animation
    buttonAnim = CreateObject("roSGNode", "Animation")
    buttonAnim.duration = 0.2
    buttonAnim.easeFunction = "outQuad"

    ' Color animation
    colorInterp = CreateObject("roSGNode", "ColorFieldInterpolator")
    colorInterp.key = [0.0, 1.0]

    if focused then
        ' Brighten button and show border
        colorInterp.keyValue = ["0xE50914FF", "0xFF0A16FF"]
        m.focusBorder.opacity = 0.3
        m.helpUnderline.visible = false
    else
        ' Return to normal color
        colorInterp.keyValue = ["0xFF0A16FF", "0xE50914FF"]
        m.focusBorder.opacity = 0
    end if

    colorInterp.fieldToInterp = "signInBg.color"
    buttonAnim.appendChild(colorInterp)
    buttonAnim.control = "start"
end sub

sub setupLayout()
    parent = m.top.getParent()
    if parent <> invalid then
        screenWidth = parent.screenWidth
        screenHeight = parent.screenHeight

        if screenWidth = invalid or screenHeight = invalid then
            screenWidth = 1920
            screenHeight = 1080
        end if
    else
        screenWidth = 1920
        screenHeight = 1080
    end if

    print "[AuthScreen] Setting up layout for screen: "; screenWidth; "x"; screenHeight

    ' Position feature image centered in the left side
    if m.featureImage <> invalid then
        ' Calculate left side space (from edge to card start)
        leftSideWidth = 720 ' Card starts at x=720
        imageWidth = 620 ' Actual image width from XML
        imageHeight = 480 ' Actual image height from XML

        ' Center horizontally in left side space
        imageX = (leftSideWidth - imageWidth) / 2
        ' Position much higher up on screen
        imageY = 150 ' Fixed higher position

        m.featureImage.translation = [imageX, imageY]
        print "[AuthScreen] Feature image positioned at: ["; imageX; ", "; imageY; "] with size: ["; imageWidth; ", "; imageHeight; "]"
    end if

    ' Position main card to the right of the feature image
    if m.mainCard <> invalid then
        cardX = 720 ' Fixed position to the right of image
        cardY = (screenHeight - 420) / 2 ' Center vertically
        m.mainCard.translation = [cardX, cardY]

        ' Adjust glow position
        m.cardGlow.translation = [cardX - 20, cardY - 20]
    end if
end sub

sub onVisibilityChange()
    print "[AuthScreen] Visibility changed to: "; m.top.visible
    if m.top.visible then
        ' Reset authentication trigger flag when screen becomes visible
        m.authTriggered = false
        print "[AuthScreen] Reset authTriggered flag to allow Sign In again"

        m.mainCard.visible = true
        startEntranceAnimation()
        m.signInButton.setFocus(true)
    end if
end sub

sub onFocusChange()
    print "[AuthScreen] Focus changed, setting focus on Sign In button directly"
    if m.top.visible then
        ' Reset authentication trigger flag when screen gains focus
        m.authTriggered = false
        print "[AuthScreen] Reset authTriggered flag on focus change"

        m.signInButton.setFocus(true)
        if m.signInButton.hasFocus() then
            print "[AuthScreen] Sign In button now has focus after focus change"
        else
            print "[AuthScreen] ERROR: Sign In button still does not have focus after focus change"
        end if
    end if
end sub

' Enhanced key event handling with smooth interactions
function onKeyEvent(key as string, press as boolean) as boolean
    print "[AuthScreen] Key event received: "; key; " press: "; press
    handled = false

    if press then
        ' Ensure Sign In button has focus for any key press
        if not m.signInButton.hasFocus() then
            print "[AuthScreen] Sign In button doesn't have focus, setting it now"
            m.signInButton.setFocus(true)
        end if

        if key = "OK" or key = "select" then
            print "[AuthScreen] OK/select pressed, checking Sign In button focus"
            if m.signInButton.hasFocus() then
                print "[AuthScreen] Sign In button has focus, triggering authentication"

                ' Prevent multiple rapid presses
                if m.authTriggered = true then
                    print "[AuthScreen] Authentication already triggered, ignoring"
                    handled = true
                    return handled
                end if

                ' Set flag to prevent multiple triggers
                m.authTriggered = true

                ' Animate button press
                animateButtonPress()

                ' Trigger auth directly (no timer delay)
                print "[AuthScreen] Triggering authentication immediately"
                triggerAuth()

                handled = true
            else
                print "[AuthScreen] ERROR: Sign In button does not have focus even after setting it"
            end if
        else if key = "up" then
            ' Could navigate to Get Help if implemented
            handled = true
        else if key = "down" then
            ' Keep focus on Sign In
            if not m.signInButton.hasFocus() then
                m.signInButton.setFocus(true)
            end if
            handled = true
        else if key = "back" then
            ' Handle back button
            handled = false
        end if
    end if

    return handled
end function

sub animateButtonPress()
    ' Create button press animation
    pressAnim = CreateObject("roSGNode", "Animation")
    pressAnim.duration = 0.15
    pressAnim.easeFunction = "linear"

    ' Color animation for press effect (width is not animatable)
    colorInterp = CreateObject("roSGNode", "ColorFieldInterpolator")
    colorInterp.key = [0.0, 0.5, 1.0]
    colorInterp.keyValue = ["0xE50914FF", "0xCC0812FF", "0xE50914FF"]
    colorInterp.fieldToInterp = "signInBg.color"
    pressAnim.appendChild(colorInterp)

    pressAnim.control = "start"
end sub

sub triggerAuth()
    print "[AuthScreen] ==================== TRIGGERING AUTHENTICATION ===================="
    print "[AuthScreen] Current showDeviceAuth value: "; m.top.showDeviceAuth
    print "[AuthScreen] Setting showDeviceAuth to true"

    ' Set the field that will trigger the transition
    m.top.showDeviceAuth = true

    print "[AuthScreen] showDeviceAuth field set to: "; m.top.showDeviceAuth
    print "[AuthScreen] Field type: "; type(m.top.showDeviceAuth)
    print "[AuthScreen] Waiting for HeroMainScene to observe field change..."

    ' Add a small delay to see if the field change is processed
    m.checkTimer = CreateObject("roSGNode", "Timer")
    m.checkTimer.duration = 0.5
    m.checkTimer.observeField("fire", "checkFieldChange")
    m.checkTimer.control = "start"

    print "[AuthScreen] ============================================================================"
end sub

sub checkFieldChange()
    print "[AuthScreen] Checking field after delay - showDeviceAuth: "; m.top.showDeviceAuth
    if m.checkTimer <> invalid then
        m.checkTimer = invalid
    end if
end sub