' ********** Custom Item Component for Hero Grid **********

sub init()
    print "[CustomItem] Initializing..."

    ' Get references to child nodes
    m.itemBackground = m.top.findNode("itemBackground")
    m.focusIndicator = m.top.findNode("focusIndicator")
    m.itemPoster = m.top.findNode("itemPoster")
    m.textOverlay = m.top.findNode("textOverlay")
    m.itemTitle = m.top.findNode("itemTitle")
    m.typeIndicator = m.top.findNode("typeIndicator")
    m.typeLabel = m.top.findNode("typeLabel")

    print "[CustomItem] Initialization complete"
end sub

sub itemContentChanged()
    print "[CustomItem] Item content changed"

    itemData = m.top.itemContent
    if itemData = invalid then return

    ' Set title
    if itemData.title <> invalid then
        m.itemTitle.text = itemData.title
    end if

    ' Set poster/thumbnail based on item type
    if itemData.HDPosterUrl <> invalid and itemData.HDPosterUrl <> "" then
        m.itemPoster.uri = itemData.HDPosterUrl
        m.itemPoster.visible = true
    else
        ' Hide poster to show background color instead (for folders and files without thumbnails)
        m.itemPoster.visible = false
    end if

    ' Set type indicator and styling based on item type
    itemType = itemData.itemType
    if itemType = invalid then
        ' Try to get it from addFields
        if itemData.hasField("itemType") then
            itemType = itemData.itemType
        end if
    end if

    ' Also check file data for more specific file type styling
    fileData = invalid
    if itemData.hasField("fileData") then
        fileData = itemData.fileData
    end if

    if itemType <> invalid then
        setupItemType(itemType, fileData)
    end if

    print "[CustomItem] Content setup complete for: "; itemData.title
end sub

sub setupItemType(itemType as string, fileData = invalid as dynamic)
    print "[CustomItem] Setting up item type: "; itemType

    if itemType = "folder" then
        m.typeLabel.text = "📁" ' Folder emoji or "DIR"
        m.typeIndicator.color = "0x0066CCFF" ' Blue for folders
        m.itemBackground.color = "0x1E4A8CFF" ' Bright blue background for folders

        ' Make text overlay more prominent for folders
        m.textOverlay.color = "0x1E4A8CBB" ' Semi-transparent blue overlay
        m.textOverlay.visible = true

    else if itemType = "file" then
        ' Determine specific file type for better styling
        if fileData <> invalid then
            if fileData.DoesExist("is_video") and fileData.is_video = true then
                m.typeLabel.text = "VIDEO" ' Video file
                m.typeIndicator.color = "0xCC0066FF" ' Pink/Red for videos
                m.itemBackground.color = "0x4A1A2AFF" ' Dark red background
            else if fileData.DoesExist("is_audio") and fileData.is_audio = true then
                m.typeLabel.text = "AUDIO" ' Audio file
                m.typeIndicator.color = "0x9966CCFF" ' Purple for audio
                m.itemBackground.color = "0x2A1A3AFF" ' Dark purple background
            else if fileData.DoesExist("is_image") and fileData.is_image = true then
                m.typeLabel.text = "IMAGE" ' Image file
                m.typeIndicator.color = "0x66CC00FF" ' Lime green for images
                m.itemBackground.color = "0x1A3A1AFF" ' Dark green background
            else
                m.typeLabel.text = "FILE" ' Generic file
                m.typeIndicator.color = "0x00CC66FF" ' Green for generic files
                m.itemBackground.color = "0x1A2A1AFF" ' Dark green background
            end if
        else
            m.typeLabel.text = "FILE" ' Generic file text
            m.typeIndicator.color = "0x00CC66FF" ' Green for files
            m.itemBackground.color = "0x262626FF"
        end if

        ' Standard text overlay for files
        m.textOverlay.color = "0x000000CC" ' Semi-transparent black
        m.textOverlay.visible = true

    else if itemType = "back" then
        m.typeLabel.text = "BACK" ' Back text
        m.typeIndicator.color = "0xCC6600FF" ' Orange for back
        m.itemBackground.color = "0x2A2626FF"

        ' Standard text overlay for back
        m.textOverlay.color = "0x000000CC"
        m.textOverlay.visible = true

    else
        m.typeLabel.text = ""
        m.typeIndicator.visible = false
        m.itemBackground.color = "0x262626FF"
        m.textOverlay.color = "0x000000CC"
    end if
end sub

sub focusPercentChanged()
    focusPercent = m.top.focusPercent
    print "[CustomItem] Focus percent changed to: "; focusPercent

    ' Animate focus indicator opacity
    m.focusIndicator.opacity = focusPercent * 0.8

    ' Scale effect on focus
    scale = 1.0 + (focusPercent * 0.05) ' Slight scale up on focus
    m.top.scale = [scale, scale]

    ' Adjust text overlay opacity for better readability when focused
    overlayOpacity = 0.8 + (focusPercent * 0.2)
    m.textOverlay.color = "0x000000" + Int(overlayOpacity * 255).ToStr()
end sub
