' ********** Seedr Hero Screen Component **********

' Called when the HeroScreen component is initialized
sub init()
    print "[HeroScreen] Initializing..."

    ' Get references to child nodes
    m.rowList = m.top.findNode("RowList")
    m.background = m.top.findNode("background")
    m.breadcrumbLabel = m.top.findNode("breadcrumbLabel")

    ' Initialize folder tracking
    m.top.currentFolderId = ""
    m.top.folderStack = []

    ' Create a task node to fetch the UI content and populate the screen
    m.contentHandler = CreateObject("roSGNode", "ContentHandler")
    m.contentHandler.observeField("content", "onContentChanged")

    ' Create observer events for when content is loaded
    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "onFocusedChildChange")

    ' Set up item selection observer
    m.rowList.observeField("itemSelected", "onItemSelected")

    ' Initialize DetailScreen integration - NEW ADDITION
    initDetailScreenIntegration()

    print "[HeroScreen] Initialization complete"
end sub

' Observer function to handle when content loads
sub onContentChanged()
    print "[HeroScreen] onContentChanged"
    m.top.numBadRequests = m.contentHandler.numBadRequests
    content = m.contentHandler.content

    if content <> invalid then
        print "[HeroScreen] Content received with "; content.getChildCount(); " rows"
        for i = 0 to content.getChildCount() - 1
            row = content.getChild(i)
            print "[HeroScreen] Row "; i; ": "; row.title; " with "; row.getChildCount(); " items"
        end for
        m.top.content = content
        m.rowList.setFocus(true)
    else
        print "[HeroScreen] ERROR: No content received"
    end if
end sub

' Load content when screen becomes visible
sub loadContent()
    print "[HeroScreen] Loading content..."

    ' Load credentials
    credentials = loadCredentials()
    if credentials <> invalid then
        m.contentHandler.accessToken = credentials.accessToken
        m.contentHandler.control = "RUN"
    else
        print "[HeroScreen] ERROR: No credentials found"
        m.top.numBadRequests = 1
    end if
end sub

' Handler of focused item in RowList
sub onItemFocused()
    print "[HeroScreen] onItemFocused called"
    itemFocused = m.top.itemFocused

    ' When an item gains the key focus, set to a 2-element array,
    ' where element 0 contains the index of the focused row,
    ' and element 1 contains the index of the focused item in that row.
    if itemFocused.Count() = 2 then
        focusedContent = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent = focusedContent

            ' Set background image if available (background is Rectangle, not Poster, so skip this)
            ' m.background.uri = focusedContent.hdBackgroundImageUrl
        end if
    end if
end sub

' Sets proper focus to RowList in case channel returns from other screens
sub onVisibleChange()
    print "[HeroScreen] onVisibleChange - visible: "; m.top.visible
    if m.top.visible then
        ' Load content if not already loaded
        if m.top.content = invalid then
            loadContent()
        end if
        m.rowList.setFocus(true)
    end if
end sub

' Set proper focus to RowList in case if return from other screens
sub onFocusedChildChange()
    print "[HeroScreen] onFocusedChildChange"
    if m.top.isInFocusChain() and not m.rowList.hasFocus() then
        m.rowList.setFocus(true)
    end if
end sub

' Update breadcrumb based on current navigation
sub updateBreadcrumb(path as string)
    m.breadcrumbLabel.text = path
end sub

' Handle item selection (folders and files)
sub onItemSelected()
    print "[HeroScreen] onItemSelected called"

    ' Get current row and item indices from RowList
    ' rowList.rowItemSelected gives us [rowIndex, itemIndex] array
    selectedIndices = m.rowList.rowItemSelected

    print "[HeroScreen] rowItemSelected: "; selectedIndices

    if selectedIndices <> invalid and selectedIndices.count() = 2 then
        rowIndex = selectedIndices[0]
        itemIndex = selectedIndices[1]

        print "[HeroScreen] Selected row: "; rowIndex; ", item: "; itemIndex

        if m.top.content <> invalid and m.top.content.getChildCount() > rowIndex then
            rowContent = m.top.content.getChild(rowIndex)
            if rowContent <> invalid and rowContent.getChildCount() > itemIndex then
                selectedItem = rowContent.getChild(itemIndex)

                if selectedItem <> invalid then
                    print "[HeroScreen] Selected item: "; selectedItem.title

                    ' Check if item has itemType field
                    if selectedItem.hasField("itemType") then
                        itemType = selectedItem.itemType
                        print "[HeroScreen] Item type: "; itemType

                        if itemType = "folder" then
                            ' Navigate to folder
                            if selectedItem.hasField("folderId") then
                                navigateToFolder(selectedItem.folderId, selectedItem.title)
                            else
                                print "[HeroScreen] ERROR: Folder item missing folderId"
                            end if
                        else if itemType = "back" then
                            ' Navigate back to root folder
                            navigateToRoot()
                        else if itemType = "file" then
                            ' Handle file based on type
                            handleFileSelection(selectedItem)
                        end if
                    else
                        print "[HeroScreen] ERROR: Selected item has no itemType field"
                    end if
                else
                    print "[HeroScreen] ERROR: Could not get selected item"
                end if
            else
                print "[HeroScreen] ERROR: Invalid row or item index"
            end if
        else
            print "[HeroScreen] ERROR: Invalid content or row index"
        end if
    else
        print "[HeroScreen] ERROR: rowItemSelected is not a valid array, trying alternative method"

        ' Alternative method: use itemFocused to get current position
        itemFocused = m.rowList.itemFocused
        if itemFocused <> invalid then
            ' For single integer itemFocused, we need to determine row/item differently
            ' Get the currently focused row
            focusedRowIndex = m.rowList.rowFocused
            if focusedRowIndex <> invalid and focusedRowIndex >= 0 then
                print "[HeroScreen] Using alternative: rowFocused="; focusedRowIndex; ", itemFocused="; itemFocused

                if m.top.content <> invalid and m.top.content.getChildCount() > focusedRowIndex then
                    rowContent = m.top.content.getChild(focusedRowIndex)
                    if rowContent <> invalid and rowContent.getChildCount() > itemFocused then
                        selectedItem = rowContent.getChild(itemFocused)

                        if selectedItem <> invalid then
                            print "[HeroScreen] Alternative method - Selected item: "; selectedItem.title

                            if selectedItem.hasField("itemType") then
                                itemType = selectedItem.itemType
                                print "[HeroScreen] Alternative method - Item type: "; itemType

                                if itemType = "folder" then
                                    if selectedItem.hasField("folderId") then
                                        navigateToFolder(selectedItem.folderId, selectedItem.title)
                                    else
                                        print "[HeroScreen] ERROR: Folder item missing folderId"
                                    end if
                                else if itemType = "back" then
                                    ' Navigate back to root folder
                                    navigateToRoot()
                                else if itemType = "file" then
                                    handleFileSelection(selectedItem)
                                end if
                            end if
                        end if
                    end if
                end if
            end if
        end if
    end if
end sub

' Navigate to a specific folder
sub navigateToFolder(folderId as string, folderName as string)
    print "[HeroScreen] Navigating to folder: "; folderName; " (ID: "; folderId; ")"

    ' Update breadcrumb
    currentBreadcrumb = m.breadcrumbLabel.text
    if currentBreadcrumb = "Home" then
        m.breadcrumbLabel.text = folderName
    else
        m.breadcrumbLabel.text = currentBreadcrumb + " > " + folderName
    end if

    ' Load folder contents using ContentHandler
    ' First get access token from credentials
    credentials = loadCredentials()
    if credentials <> invalid and credentials.accessToken <> invalid then
        m.contentHandler.accessToken = credentials.accessToken
        ' Ensure folderId is string to avoid scientific notation
        m.contentHandler.folderId = folderId.ToStr()
        m.contentHandler.control = "RUN"
        print "[HeroScreen] Loading folder contents with ID: "; folderId.ToStr()
    else
        print "[HeroScreen] ERROR: No valid credentials found for folder navigation"
    end if
end sub

' Navigate back to root folder
sub navigateToRoot()
    print "[HeroScreen] Navigating back to root folder"

    ' Reset breadcrumb to Home
    m.breadcrumbLabel.text = "Home"

    ' Load root folder contents using ContentHandler
    credentials = loadCredentials()
    if credentials <> invalid and credentials.accessToken <> invalid then
        m.contentHandler.accessToken = credentials.accessToken
        m.contentHandler.folderId = "" ' Empty means root
        m.contentHandler.control = "RUN"
        print "[HeroScreen] Loading root folder contents"
    else
        print "[HeroScreen] ERROR: No valid credentials found for root navigation"
    end if
end sub

' Handle different file types
sub handleFileSelection(fileItem as object)
    print "[HeroScreen] File selected: "; fileItem.title

    fileName = fileItem.title
    fileData = fileItem.fileData

    ' Check file type and handle accordingly
    if fileData <> invalid then
        if fileData.is_video = true then
            playVideoFile(fileItem)
        else if fileData.is_audio = true then
            playAudioFile(fileItem)
        else if fileData.is_image = true then
            showImageFile(fileItem)
        else
            showFileInfo(fileItem)
        end if
    else
        showFileInfo(fileItem)
    end if
end sub

' Play video file
sub playVideoFile(fileItem as object)
    print "[HeroScreen] Playing video: "; fileItem.title

    ' Signal parent scene to handle video playback (parent will handle API calls on proper thread)
    ' Navigate up the hierarchy to find the Scene node
    parentNode = m.top.getParent()
    sceneFound = false
    maxLevels = 5 ' Prevent infinite loop
    currentLevel = 0

    while parentNode <> invalid and currentLevel < maxLevels
        print "[HeroScreen] Checking parent node type: "; parentNode.subType(); " at level "; currentLevel
        if parentNode.subType() = "Scene" or parentNode.subType() = "HeroMainScene"
            sceneFound = true
            exit while
        end if
        parentNode = parentNode.getParent()
        currentLevel = currentLevel + 1
    end while

    if sceneFound and parentNode <> invalid then
        parentNode.playVideo = {
            fileId: fileItem.fileId,
            title: fileItem.title,
            fileData: fileItem.fileData
        }
        print "[HeroScreen] Signaled scene ("; parentNode.subType(); ") to play video with fileId: "; fileItem.fileId
    else
        print "[HeroScreen] ERROR: Could not find parent scene after checking "; currentLevel; " levels"
        ' Fallback: try to get the scene directly from the global scope
        scene = getScene()
        if scene <> invalid then
            scene.playVideo = {
                fileId: fileItem.fileId,
                title: fileItem.title,
                fileData: fileItem.fileData
            }
            print "[HeroScreen] Used fallback method to signal scene"
        else
            print "[HeroScreen] ERROR: Fallback method also failed"
        end if
    end if
end sub

' Play audio file
sub playAudioFile(fileItem as object)
    print "[HeroScreen] Playing audio: "; fileItem.title

    ' Signal parent scene to handle audio playback (parent will handle API calls on proper thread)
    ' Navigate up the hierarchy to find the Scene node
    parentNode = m.top.getParent()
    sceneFound = false
    maxLevels = 5 ' Prevent infinite loop
    currentLevel = 0

    while parentNode <> invalid and currentLevel < maxLevels
        print "[HeroScreen] Checking parent node type: "; parentNode.subType(); " at level "; currentLevel
        if parentNode.subType() = "Scene" or parentNode.subType() = "HeroMainScene"
            sceneFound = true
            exit while
        end if
        parentNode = parentNode.getParent()
        currentLevel = currentLevel + 1
    end while

    if sceneFound and parentNode <> invalid then
        parentNode.playVideo = {
            fileId: fileItem.fileId,
            title: fileItem.title,
            fileData: fileItem.fileData,
            isAudio: true
        }
        print "[HeroScreen] Signaled scene ("; parentNode.subType(); ") to play audio with fileId: "; fileItem.fileId
    else
        print "[HeroScreen] ERROR: Could not find parent scene after checking "; currentLevel; " levels"
        ' Fallback: try to get the scene directly from the global scope
        scene = getScene()
        if scene <> invalid then
            scene.playVideo = {
                fileId: fileItem.fileId,
                title: fileItem.title,
                fileData: fileItem.fileData,
                isAudio: true
            }
            print "[HeroScreen] Used fallback method to signal scene for audio"
        else
            print "[HeroScreen] ERROR: Fallback method also failed for audio"
        end if
    end if
end sub

' Show image file
sub showImageFile(fileItem as object)
    print "[HeroScreen] Showing image: "; fileItem.title
    ' For now, show file info - could be enhanced to show image viewer
    showFileInfo(fileItem)
end sub

' Show file information
sub showFileInfo(fileItem as object)
    print "[HeroScreen] Showing info for: "; fileItem.title
    ' Could show a dialog with file information
end sub

' ********** NEW DETAIL SCREEN INTEGRATION - ADDITIVE ONLY **********

' Enhanced item selection handler that launches DetailScreen
sub onItemSelectedEnhanced()
    selectedItem = m.rowList.rowItemSelected
    print "[HeroScreen] Enhanced item selection triggered: "; selectedItem

    if selectedItem <> invalid and selectedItem.count() = 2
        rowIndex = selectedItem[0]
        itemIndex = selectedItem[1]

        content = m.top.content
        if content <> invalid and rowIndex < content.getChildCount()
            row = content.getChild(rowIndex)
            if row <> invalid and itemIndex < row.getChildCount()
                item = row.getChild(itemIndex)

                print "[HeroScreen] Checking item for DetailScreen: "; item.title

                ' Check if this is a video/media file that should show detail screen
                if shouldShowDetailScreen(item)
                    print "[HeroScreen] Item is video, launching DetailScreen"
                    launchDetailScreen(row, itemIndex)
                    return ' Let DetailScreen handle this
                else
                    print "[HeroScreen] Item is not video, using existing handler"
                end if
            end if
        end if
    end if

    ' Fall back to existing selection handling
    onItemSelected()
end sub

' Determine if an item should show the detail screen
function shouldShowDetailScreen(item as object) as boolean
    if item = invalid then return false

    ' Use the same video detection logic as the existing system
    if item.title <> invalid
        return isVideoFile(item.title)
    end if

    return false
end function

' Launch the DetailScreen with the selected content
sub launchDetailScreen(rowContent as object, selectedIndex as integer)
    print "[HeroScreen] Launching DetailScreen for item "; selectedIndex

    ' Create DetailScreen if it doesn't exist
    if m.detailScreen = invalid
        m.detailScreen = CreateObject("roSGNode", "DetailScreen")
        m.detailScreen.visible = false
        m.top.appendChild(m.detailScreen)

        ' Set up observers for DetailScreen
        m.detailScreen.observeField("playPressed", "onDetailScreenPlayPressed")
        m.detailScreen.observeField("visible", "onDetailScreenVisibilityChanged")
    end if

    ' Set content and show DetailScreen
    m.detailScreen.content = rowContent
    m.detailScreen.selectedIndex = selectedIndex
    m.detailScreen.visible = true
    m.detailScreen.setFocus(true)

    ' Store reference for returning focus
    m.lastFocusedRowItem = m.rowList.rowItemFocused
end sub

' Handle play button press from DetailScreen - preserve existing play functionality
sub onDetailScreenPlayPressed()
    print "[HeroScreen] DetailScreen play button pressed"

    if m.detailScreen <> invalid and m.detailScreen.content <> invalid
        selectedIndex = m.detailScreen.selectedIndex
        row = m.detailScreen.content

        if selectedIndex >= 0 and selectedIndex < row.getChildCount()
            selectedItem = row.getChild(selectedIndex)

            ' Use existing video playing logic
            print "[HeroScreen] Playing video from DetailScreen: "; selectedItem.title
            playVideoFile(selectedItem)

            ' Hide DetailScreen after starting playback
            m.detailScreen.visible = false
        end if
    end if
end sub

' Handle DetailScreen visibility changes
sub onDetailScreenVisibilityChanged()
    if m.detailScreen <> invalid and m.detailScreen.visible = false
        print "[HeroScreen] DetailScreen closed, returning focus to grid"

        ' Return focus to the grid
        m.rowList.setFocus(true)

        ' Restore last focused position if available
        if m.lastFocusedRowItem <> invalid
            m.rowList.jumpToRowItem = m.lastFocusedRowItem
        end if
    end if
end sub

' Override the existing item selection observer to use enhanced version
sub setupDetailScreenIntegration()
    print "[HeroScreen] Setting up DetailScreen integration"

    ' Remove existing observer
    m.rowList.unobserveField("itemSelected")

    ' Add enhanced observer
    m.rowList.observeField("itemSelected", "onItemSelectedEnhanced")
end sub

' Initialize DetailScreen integration (call this from init or when needed)
sub initDetailScreenIntegration()
    print "[HeroScreen] Initializing DetailScreen integration"

    ' Set up the enhanced item selection handling
    setupDetailScreenIntegration()

    ' Initialize DetailScreen reference
    m.detailScreen = invalid
    m.lastFocusedRowItem = invalid
end sub