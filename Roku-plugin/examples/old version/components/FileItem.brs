' ********** Seedr for Roku - File Item Logic **********

sub init()
    m.background = m.top.findNode("background")
    m.focusRect = m.top.findNode("focusRect")
    m.poster = m.top.findNode("poster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.titleBg = m.top.findNode("titleBg")
end sub

sub showContent()
    itemData = m.top.itemContent
    if itemData <> invalid then
        ' Set title
        m.titleLabel.text = itemData.title

        ' Set poster/thumbnail
        if itemData.HDPosterUrl <> invalid and itemData.HDPosterUrl <> "" then
            m.poster.uri = itemData.HDPosterUrl
        else
            ' Use the existing icon_focus_hd.png for all items
            m.poster.uri = "pkg:/images/icon_focus_hd.png"
        end if

        ' Set background color based on item type
        if itemData.itemType = "folder" then
            m.background.color = "0x3a3a3aFF"
        else if itemData.itemType = "back" then
            m.background.color = "0x4a4a4aFF"
        else
            m.background.color = "0x2a2a2aFF"
        end if
    end if
end sub

sub focusPercentChanged()
    focusPercent = m.top.focusPercent

    ' Animate focus rectangle opacity
    m.focusRect.opacity = focusPercent * 0.8

    ' Scale effect on focus
    scale = 1.0 + (focusPercent * 0.1)
    m.top.scale = [scale, scale]

    ' Adjust z-order when focused
    if focusPercent > 0.5 then
        m.top.renderOrder = 1
    else
        m.top.renderOrder = 0
    end if
end sub
