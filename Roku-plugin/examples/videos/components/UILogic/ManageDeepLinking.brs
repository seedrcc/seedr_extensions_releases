function GetSupportedMediaTypes() 
    return {
        "movie": "movies"
        "shortFormVideo": "shortFormVideos"
    }
end function

sub OnInputDeepLinking(event as Object)  
    args = event.getData()
    if args <> invalid and ValidateDeepLink(args) 
        DeepLink(m.Grid.content, args.mediatype, args.contentid)
    end if
end sub


function ValidateDeepLink(args as Object) as Boolean
    mediatype = args.mediatype
    contentid = args.contentid
    types = GetSupportedMediaTypes()
    return mediatype <> invalid and contentid <> invalid and types[mediatype] <> invalid
 end function

 sub DeepLink(content as Object, mediatype as String, contentid as String)
    playableItem = FindNodeById(content, contentid)
    if playableItem <> invalid 
        ClearScreen() 
        if mediatype = "movie" or mediaType = "shortFormVideo"
            PrepareDetailsScreen(playableItem)
        end if
    end if
end sub

sub PrepareDetailsScreen(content as Object)
    m.deepLinkDetailsScreen = CreateObject("roSGNode", "Detail")
    m.deepLinkDetailsScreen.content = content
    m.deepLinkDetailsScreen.ObserveField("visible", "OnDeepLinkDetailsScreenVisibilityChanged")
    m.deepLinkDetailsScreen.ObserveField("buttonSelected", "OnDeepLinkDetailsScreenButtonSelected")
   
    AddScreen(m.deepLinkDetailsScreen)
end sub

sub OnDeepLinkDetailsScreenVisibilityChanged(event as Object) 
    visible = event.GetData()
    screen = event.GetRoSGNode()
    if visible = false and IsScreenAvailable(screen) = false
        content = screen.content
        if content <> invalid
            m.Grid.jumpToRowItem = [content.homeRowIndex, content.homeItemIndex]
            if m.deepLinkDetailsScreen <> invalid
                m.deepLinkDetailsScreen = invalid
            end if
        end if
    end if
end sub


sub buttonSelectedOnDeeplink(event as object)
    selectedIndex = event.GetData()
    details = event.GetRoSGNode()
    content = m.deepLinkDetailsScreen.content
    if selectedIndex[1] = 0  
        content.bookmarkPosition = 0
        ShowVideoScreen(content, 0) 
    end if
end sub

sub OnDeepLinkDetailsScreenButtonSelected(event as Object)
    buttonIndex = event.getData() 
    details = event.GetRoSGNode()
    content = m.deepLinkDetailsScreen.content.clone(true)
    if buttonIndex = 0
        content.bookmarkPosition = 0
        ShowVideoScreen(content, 0) 
    end if
end sub

function FindNodeById(content as Object, contentid as String) as Object

    for each element in content.getChildren(-1, 0)
        if element.id = contentid
            return element
        else if element.getChildCount() > 0
            result = FindNodeById(element, contentid)
            if result <> invalid
                return result
            end if
        end if
    end for
    return invalid
end function
