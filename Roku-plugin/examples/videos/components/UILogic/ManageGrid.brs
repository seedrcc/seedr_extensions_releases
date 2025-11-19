sub ShowGridScreen()
    m.Grid = CreateObject("roSGNode", "Grid")
    m.Grid.visible = false
    m.Grid.ObserveField("rowItemSelected", "OnGridScreenItemSelected")
    ShowScreen(m.Grid) 
end sub

sub OnGridScreenItemSelected(event as Object) 
    grid = event.GetRoSGNode()
    m.selectedIndex = event.GetData()
    rowContent = grid.content.GetChild(m.selectedIndex[0])
    itemIndex = m.selectedIndex[1]
    ShowDetailsScreen(rowContent, itemIndex)
end sub