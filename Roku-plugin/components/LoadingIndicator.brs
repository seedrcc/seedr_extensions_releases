' ********** Loading Indicator Component **********

sub init()
    print "[LoadingIndicator] Initializing..."

    ' Get references to child nodes
    m.backgroundRect = m.top.findNode("backgroundRect")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.spinner = m.top.findNode("spinner")
    m.loadingText = m.top.findNode("loadingText")

    ' Set up observers
    m.top.observeField("control", "onControlChange")
    m.top.observeField("text", "onTextChange")
    m.top.observeField("imageUri", "onImageUriChange")
    m.top.observeField("backgroundColor", "onBackgroundColorChange")
    m.top.observeField("backgroundOpacity", "onBackgroundOpacityChange")

    ' Create rotation animation
    createSpinAnimation()

    ' Apply initial settings
    applySettings()

    print "[LoadingIndicator] Initialization complete"
end sub

sub createSpinAnimation()
    ' Create rotation animation for spinner
    m.spinAnimation = CreateObject("roSGNode", "Animation")
    m.spinAnimation.duration = m.top.spinInterval
    m.spinAnimation.repeat = true
    m.spinAnimation.easeFunction = "linear"

    ' Create rotation interpolator
    m.rotationInterp = CreateObject("roSGNode", "FloatFieldInterpolator")
    m.rotationInterp.key = [0, 1]

    if m.top.clockwise then
        m.rotationInterp.keyValue = [0, 360]
    else
        m.rotationInterp.keyValue = [360, 0]
    end if

    m.rotationInterp.fieldToInterp = "spinner.rotation"
    m.spinAnimation.appendChild(m.rotationInterp)
    m.top.appendChild(m.spinAnimation)
end sub

sub applySettings()
    ' Apply text
    if m.top.text <> invalid then
        m.loadingText.text = m.top.text
    end if

    ' Apply image URI
    if m.top.imageUri <> invalid then
        m.spinner.uri = m.top.imageUri
    end if

    ' Apply background color and opacity
    if m.top.backgroundColor <> invalid then
        m.backgroundRect.color = m.top.backgroundColor
    end if

    if m.top.backgroundOpacity <> invalid then
        m.backgroundRect.opacity = m.top.backgroundOpacity
    end if

    ' Apply spinner size
    if m.top.imageWidth <> invalid then
        m.spinner.width = m.top.imageWidth
        m.spinner.height = m.top.imageWidth
        m.spinner.translation = [-m.top.imageWidth / 2, -80]
    end if

    ' Apply font
    if m.top.font <> invalid then
        m.loadingText.font = m.top.font
    end if
end sub

sub onControlChange()
    control = m.top.control
    print "[LoadingIndicator] Control changed to: "; control

    if control = "start" then
        startLoading()
    else if control = "stop" then
        stopLoading()
    end if
end sub

sub startLoading()
    print "[LoadingIndicator] Starting loading animation"
    m.top.visible = true

    if m.spinAnimation <> invalid then
        m.spinAnimation.control = "start"
    end if
end sub

sub stopLoading()
    print "[LoadingIndicator] Stopping loading animation"

    if m.spinAnimation <> invalid then
        m.spinAnimation.control = "stop"
    end if

    m.top.visible = false
end sub

sub onTextChange()
    if m.loadingText <> invalid then
        m.loadingText.text = m.top.text
    end if
end sub

sub onImageUriChange()
    if m.spinner <> invalid then
        m.spinner.uri = m.top.imageUri
    end if
end sub

sub onBackgroundColorChange()
    if m.backgroundRect <> invalid then
        m.backgroundRect.color = m.top.backgroundColor
    end if
end sub

sub onBackgroundOpacityChange()
    if m.backgroundRect <> invalid then
        m.backgroundRect.opacity = m.top.backgroundOpacity
    end if
end sub
