' ********** Simple Detail Screen with Dynamic Background **********

' Initialize the DetailScreen component
function Init()
    print "[DetailScreen] ==================== INITIALIZING ===================="
    print "[DetailScreen] Starting simple DetailScreen initialization..."

    ' Set up observers
    m.top.ObserveField("visible", "OnVisibleChange")
    m.top.ObserveField("itemFocused", "OnItemFocusedChanged")
    m.top.ObserveField("content", "OnContentChange")
    m.top.ObserveField("jumpToItem", "OnJumpToItem")

    ' Get references to UI elements
    m.buttons = m.top.FindNode("buttons")
    m.description = m.top.FindNode("descriptionLabel")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.itemCounter = m.top.findNode("itemCounter")

    ' Background elements for dynamic effect
    m.backgroundPoster = m.top.findNode("backgroundPoster")
    m.backgroundPosterSecondary = m.top.findNode("backgroundPosterSecondary")

    ' Set up button observer
    if m.buttons <> invalid
        m.buttons.observeField("itemSelected", "onButtonSelected")
    end if

    ' Initialize state
    m.isTransitioning = false
    m.currentItem = invalid

    print "[DetailScreen] Simple initialization complete"
    print "[DetailScreen] ============================================================="
end function

' Handle visibility changes
sub OnVisibleChange()
    print "[DetailScreen] ==================== VISIBILITY CHANGED ===================="
    print "[DetailScreen] DetailScreen visibility changed to: "; m.top.visible

    if m.top.visible = true
        print "[DetailScreen] Screen became visible - setting focus"
        if m.buttons <> invalid
            m.buttons.SetFocus(true)
        end if
        m.top.itemFocused = m.top.jumpToItem
        if m.currentItem <> invalid
            updateDisplay()
        end if
    end if
    print "[DetailScreen] ============================================================="
end sub

' Handle content changes
sub OnContentChange(event as object)
    print "[DetailScreen] ==================== CONTENT CHANGED ===================="
    content = event.getData()
    if content <> invalid
        m.isContentList = content.GetChildCount() > 0
        if m.isContentList = false
            ' Single item
            SetDetailsContent(content)
            if m.buttons <> invalid
                m.buttons.SetFocus(true)
            end if
        else
            ' Multiple items - set up for navigation
            print "[DetailScreen] Content loaded with "; content.getChildCount(); " items"

            ' Set initial item if needed
            if m.top.jumpToItem < 0 or m.top.jumpToItem >= content.getChildCount()
                m.top.jumpToItem = 0
            end if

            ' Show first item
            if content.getChildCount() > 0
                firstItem = content.getChild(m.top.jumpToItem)
                SetDetailsContent(firstItem)
                m.currentItem = firstItem
                updateBackgroundWithTransition()
                updateItemCounter()
            end if
        end if
    end if
    print "[DetailScreen] ============================================================="
end sub

' Handle jump to item
sub OnJumpToItem()
    content = m.top.content
    if content <> invalid and m.top.jumpToItem >= 0 and content.GetChildCount() > m.top.jumpToItem
        m.top.itemFocused = m.top.jumpToItem

        ' Update display for new item
        newItem = content.GetChild(m.top.jumpToItem)
        SetDetailsContent(newItem)
        m.currentItem = newItem
        updateBackgroundWithTransition()
        updateItemCounter()
    end if
end sub

' Handle item focus changes
sub OnItemFocusedChanged(event as object)
    focusedItem = event.GetData()
    if m.top.content <> invalid and m.top.content.GetChildCount() > 0 and focusedItem >= 0 and focusedItem < m.top.content.GetChildCount()
        content = m.top.content.GetChild(focusedItem)
        SetDetailsContent(content)
        m.currentItem = content
        updateBackgroundWithTransition()
        updateItemCounter()
    end if
end sub

' Set details content (simple version)
sub SetDetailsContent(content as object)
    if content = invalid then return

    ' Update title
    if content.title <> invalid
        m.titleLabel.text = content.title
    else
        m.titleLabel.text = "Unknown Title"
    end if

    ' Update description
    if content.description <> invalid and content.description <> ""
        m.description.text = content.description
    else
        ' Simple description based on file type
        fileType = ""
        if content.fileType <> invalid
            fileType = content.fileType
        end if

        if fileType = "video"
            m.description.text = "Video file ready to play. Use left/right arrows to browse files."
        else if fileType = "image"
            m.description.text = "Image file ready to view. Use left/right arrows to browse files."
        else if fileType = "audio"
            m.description.text = "Audio file ready to play. Use left/right arrows to browse files."
        else
            m.description.text = "File ready to open. Use left/right arrows to browse files."
        end if
    end if

    ' Create simple buttons
    result = []
    if content.fileType = "video"
        for each button in ["Play", "+ Queue", "Info"]
            result.Push({ title: button })
        end for
    else if content.fileType = "image"
        for each button in ["View", "Details", "Info"]
            result.Push({ title: button })
        end for
    else if content.fileType = "audio"
        for each button in ["Play", "Queue", "Info"]
            result.Push({ title: button })
        end for
    else
        for each button in ["Open", "Details", "Info"]
            result.Push({ title: button })
        end for
    end if

    if m.buttons <> invalid
        m.buttons.content = ContentListToSimpleNode(result)
    end if

    print "[DetailScreen] Display updated for: "; content.title
end sub

' Update display wrapper
sub updateDisplay()
    if m.currentItem <> invalid
        SetDetailsContent(m.currentItem)
    end if
end sub

' Update item counter
sub updateItemCounter()
    if m.top.content <> invalid and m.itemCounter <> invalid
        totalItems = m.top.content.getChildCount()
        currentIndex = m.top.itemFocused + 1
        m.itemCounter.text = currentIndex.toStr() + " of " + totalItems.toStr()
    end if
end sub

' Update background with smooth transition
sub updateBackgroundWithTransition()
    if m.currentItem = invalid or m.isTransitioning then return

    newBackgroundUri = ""

    ' Get background image URL
    if m.currentItem.hdPosterUrl <> invalid
        newBackgroundUri = m.currentItem.hdPosterUrl
    else if m.currentItem.HDPosterUrl <> invalid
        newBackgroundUri = m.currentItem.HDPosterUrl
    end if

    if newBackgroundUri <> "" and m.backgroundPoster <> invalid and newBackgroundUri <> m.backgroundPoster.uri
        print "[DetailScreen] Transitioning background to: "; newBackgroundUri
        performBackgroundTransition(newBackgroundUri)
    end if
end sub

' Perform smooth background transition
sub performBackgroundTransition(newUri as string)
    if m.backgroundPoster = invalid or m.backgroundPosterSecondary = invalid then return

    m.isTransitioning = true

    ' Set new image to secondary poster
    m.backgroundPosterSecondary.uri = newUri

    ' Create simple fade transition
    fadeOutAnimation = CreateObject("roSGNode", "Animation")
    fadeOutAnimation.duration = 0.3

    fadeOutInterpolator = CreateObject("roSGNode", "FloatFieldInterpolator")
    fadeOutInterpolator.key = [0.0, 1.0]
    fadeOutInterpolator.keyValue = [0.4, 0.0]
    fadeOutInterpolator.fieldToInterp = "backgroundPoster.opacity"
    fadeOutAnimation.appendChild(fadeOutInterpolator)

    fadeInAnimation = CreateObject("roSGNode", "Animation")
    fadeInAnimation.duration = 0.3

    fadeInInterpolator = CreateObject("roSGNode", "FloatFieldInterpolator")
    fadeInInterpolator.key = [0.0, 1.0]
    fadeInInterpolator.keyValue = [0.0, 0.4]
    fadeInInterpolator.fieldToInterp = "backgroundPosterSecondary.opacity"
    fadeInAnimation.appendChild(fadeInInterpolator)

    ' Observe completion
    fadeInAnimation.observeField("state", "onBackgroundTransitionComplete")

    ' Start animations
    m.top.appendChild(fadeOutAnimation)
    m.top.appendChild(fadeInAnimation)
    fadeOutAnimation.control = "start"
    fadeInAnimation.control = "start"
end sub

' Handle transition completion
sub onBackgroundTransitionComplete(event as object)
    animation = event.getRoSGNode()
    if animation.state = "stopped"
        ' Swap posters
        m.backgroundPoster.uri = m.backgroundPosterSecondary.uri
        m.backgroundPoster.opacity = 0.4
        m.backgroundPosterSecondary.uri = ""
        m.backgroundPosterSecondary.opacity = 0.0

        m.isTransitioning = false
        print "[DetailScreen] Background transition complete"
    end if
end sub

' Handle button selections
sub onButtonSelected(event as object)
    buttonIndex = event.getData()
    print "[DetailScreen] ==================== BUTTON SELECTED ===================="
    print "[DetailScreen] Button selected: "; buttonIndex

    if buttonIndex = 0 ' Play/View/Open button
        print "[DetailScreen] PLAY button pressed"
        if m.currentItem <> invalid
            m.top.playPressed = true
            print "[DetailScreen] Play signal sent for: "; m.currentItem.title
        end if
    else if buttonIndex = 1 ' Queue/Details button
        print "[DetailScreen] QUEUE button pressed"
    else if buttonIndex = 2 ' Info button
        print "[DetailScreen] INFO button pressed"
    end if
    print "[DetailScreen] ============================================================="
end sub

' Handle key events for navigation
function OnkeyEvent(key as string, press as boolean) as boolean
    result = false
    if press
        if key = "left"
            ' Navigate to previous item
            if m.top.content <> invalid and m.top.content.GetChildCount() > 0
                currentItem = m.top.itemFocused
                if currentItem > 0
                    m.top.jumpToItem = currentItem - 1
                else
                    ' Wrap to last item
                    m.top.jumpToItem = m.top.content.GetChildCount() - 1
                end if
                result = true
            end if
        else if key = "right"
            ' Navigate to next item
            if m.top.content <> invalid and m.top.content.GetChildCount() > 0
                currentItem = m.top.itemFocused
                if currentItem < m.top.content.GetChildCount() - 1
                    m.top.jumpToItem = currentItem + 1
                else
                    ' Wrap to first item
                    m.top.jumpToItem = 0
                end if
                result = true
            end if
        else if key = "back"
            ' Close detail screen
            m.top.visible = false
            result = true
        end if
    end if
    return result
end function

' Helper function to convert content list to simple node
function ContentListToSimpleNode(contentList as object, nodeType = "ContentNode" as string) as object
    result = CreateObject("roSGNode", nodeType)
    if result <> invalid
        for each itemAA in contentList
            item = CreateObject("roSGNode", nodeType)
            item.SetFields(itemAA)
            result.AppendChild(item)
        end for
    end if
    return result
end function