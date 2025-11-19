
sub Init()
    m.rowList = m.top.FindNode("rowList")
    m.rowList.SetFocus(true)
    m.descriptionLabel = m.top.FindNode("descriptionLabel")
    m.top.ObserveField("visible", "OnVisibleChange")
    m.poster = m.top.FindNode("poster")
    m.date = m.top.FindNode("date")
    m.genre = m.top.FindNode("genre")
    m.quality = m.top.FindNode("quality")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
end sub

sub OnVisibleChange() 
    if m.top.visible = true
        m.rowList.SetFocus(true) 
    end if
end sub

sub OnItemFocused() 
    focusedIndex = m.rowList.rowItemFocused 
    row = m.rowList.content.GetChild(focusedIndex[0]) 
    item = row.GetChild(focusedIndex[1]) 
    m.poster.uri = item.hdPosterUrl
    m.descriptionLabel.text = item.description
    m.titleLabel.text = item.title
    m.quality.text = item.quality
    m.genre.text = item.genre
    m.date.text = left(item.releaseDate,10)
end sub
