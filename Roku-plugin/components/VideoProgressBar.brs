sub init()
    print "VideoProgressBar init()"

    m.progressBackground = m.top.findNode("progressBackground")
    m.progressFill = m.top.findNode("progressFill")

    ' Set default values
    m.top.color = "0x8A2BE2FF"
    m.top.width = 200
    m.top.height = 4
    m.top.progressPercent = 0

    ' Observe field changes
    m.top.observeField("color", "onColorChange")
    m.top.observeField("width", "onWidthChange")
    m.top.observeField("height", "onHeightChange")
    m.top.observeField("progressPercent", "onProgressChange")

    ' Initialize appearance
    updateAppearance()
end sub

sub onColorChange()
    m.progressFill.color = m.top.color
end sub

sub onWidthChange()
    updateAppearance()
end sub

sub onHeightChange()
    updateAppearance()
end sub

sub onProgressChange()
    updateProgressWidth()
end sub

sub updateAppearance()
    ' Update background bar
    m.progressBackground.width = m.top.width
    m.progressBackground.height = m.top.height

    ' Update progress fill
    m.progressFill.height = m.top.height
    updateProgressWidth()
end sub

sub updateProgressWidth()
    ' Calculate progress width based on percentage
    progressWidth = (m.top.progressPercent / 100.0) * m.top.width
    if progressWidth < 0 then progressWidth = 0
    if progressWidth > m.top.width then progressWidth = m.top.width

    m.progressFill.width = progressWidth
end sub
