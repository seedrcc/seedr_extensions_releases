sub OnContentSet() 
    content = m.top.itemContent
    if content <> invalid 
        m.top.FindNode("poster").uri = content.hdPosterUrl
        m.top.FindNode("bottomTitle").text = content.title
    end if
end sub
