' ********** Seedr for Roku - File Grid Screen Logic **********

sub init()
    m.fileGrid = m.top.findNode("fileGrid")
    m.breadcrumbLabel = m.top.findNode("breadcrumbLabel")
    m.emptyState = m.top.findNode("emptyState")
    m.background = m.top.findNode("background")

    ' Set up grid event handling
    m.fileGrid.observeField("itemSelected", "onItemSelected")

    ' Set focus to grid
    m.fileGrid.setFocus(true)

    ' Load root folder when screen becomes visible
    m.top.observeField("visible", "onVisibilityChange")

    ' Set up parent observers after a delay to ensure parent is available
    m.setupTimer = CreateObject("roSGNode", "Timer")
    m.setupTimer.duration = 0.1
    m.setupTimer.observeField("fire", "setupParentObservers")
    m.setupTimer.control = "start"

    ' Set up API task
    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("response", "onApiResponse")

    ' Current folder tracking
    m.currentFolderId = ""
    m.folderStack = []
end sub

sub setupParentObservers()
    parent = m.top.getParent()
    if parent <> invalid then
        parent.observeField("screenWidth", "setupLayout")
        parent.observeField("screenHeight", "setupLayout")
        ' Trigger initial layout setup
        setupLayout()
    end if
end sub

sub setupLayout()
    parent = m.top.getParent()
    if parent <> invalid then
        ' Check if screen dimensions are available and valid
        screenWidth = 1280 ' Default HD width
        screenHeight = 720 ' Default HD height

        if parent.screenWidth <> invalid and parent.screenHeight <> invalid then
            if parent.screenWidth > 0 and parent.screenHeight > 0 then
                screenWidth = parent.screenWidth
                screenHeight = parent.screenHeight
            end if
        end if

        print "[GridScreen] Using screen dimensions: "; screenWidth; "x"; screenHeight

        ' Calculate content area (excluding header)
        headerHeight = 80
        if screenHeight >= 1080 then
            headerHeight = 100
        end if
        contentHeight = screenHeight - headerHeight

        ' Update background size
        m.background.width = screenWidth
        m.background.height = contentHeight

        ' Update grid dimensions and positioning
        margin = 50
        breadcrumbHeight = 60

        ' Position grid - don't set width/height as they're not valid RowList properties
        m.fileGrid.translation = [margin, breadcrumbHeight]

        ' Adjust item size based on screen width
        itemWidth = 300
        itemHeight = 225
        if screenWidth >= 1920 then
            itemWidth = 400
            itemHeight = 300
        else if screenWidth <= 1280 then
            itemWidth = 250
            itemHeight = 190
        end if

        ' Set valid RowList properties
        m.fileGrid.rowItemSize = [itemWidth, itemHeight]
        m.fileGrid.rowHeights = [itemHeight]

        ' Center empty state
        m.emptyState.translation = [screenWidth / 2, contentHeight / 2]
    end if
end sub

sub onVisibilityChange()
    if m.top.visible then
        print "[GridScreen] GridScreen became visible, loading root folder..."
        loadRootFolder()
    end if
end sub

sub loadRootFolder()
    print "[GridScreen] Loading root folder..."

    ' Load credentials
    credentials = loadCredentials()
    if credentials = invalid then
        print "[GridScreen] ERROR: No credentials found"
        showError("Authentication required")
        return
    end if

    print "[GridScreen] Credentials loaded, access token: "; Left(credentials.accessToken, 20); "..."

    ' Show loading
    showLoading(true)

    ' Request root folder contents via ApiTask
    print "[GridScreen] Requesting root folder contents via ApiTask..."
    m.apiTask.request = {
        method: "get_folders"
        accessToken: credentials.accessToken
    }
    m.apiTask.control = "RUN"
end sub

sub onApiResponse()
    response = m.apiTask.response
    print "[GridScreen] API response received, type: "; response.type

    ' Hide loading
    showLoading(false)

    if response.success then
        if response.type = "get_folders" then
            print "[GridScreen] Root folder contents received"
            if response.data <> invalid and response.data.folders <> invalid then
                print "[GridScreen] Found "; response.data.folders.Count(); " folders and "; response.data.files.Count(); " files"
                displayFolderContents(response.data)
                m.breadcrumbLabel.text = "Home"
                m.currentFolderId = ""
            else
                print "[GridScreen] ERROR: Invalid folder data structure"
                showError("Invalid folder data received")
            end if
        else if response.type = "get_folder" then
            print "[GridScreen] Folder contents received"
            if response.data <> invalid and response.data.folders <> invalid then
                print "[GridScreen] Found "; response.data.folders.Count(); " folders and "; response.data.files.Count(); " files"
                displayFolderContents(response.data)

                ' Update breadcrumb and folder state
                if m.pendingFolderName <> invalid and m.pendingFolderId <> invalid then
                    m.folderStack.Push({ id: m.currentFolderId, name: m.breadcrumbLabel.text })
                    m.currentFolderId = m.pendingFolderId
                    m.breadcrumbLabel.text = m.breadcrumbLabel.text + " > " + m.pendingFolderName
                    m.pendingFolderName = invalid
                    m.pendingFolderId = invalid
                end if
            else
                print "[GridScreen] ERROR: Invalid folder data structure"
                showError("Invalid folder data received")
            end if
        end if
    else
        print "[GridScreen] API request failed"
        showError("Failed to load folder contents")
    end if
end sub

sub loadFolder(folderId as string, folderName as string)
    print "[GridScreen] Loading folder: "; folderName; " (ID: "; folderId; ")"

    ' Load credentials
    credentials = loadCredentials()
    if credentials = invalid then
        print "[GridScreen] ERROR: No credentials found"
        showError("Authentication required")
        return
    end if

    ' Show loading
    showLoading(true)

    ' Request folder contents via ApiTask
    print "[GridScreen] Requesting folder contents via ApiTask..."
    m.apiTask.request = {
        method: "get_folder"
        accessToken: credentials.accessToken
        folderId: folderId
    }
    m.apiTask.control = "RUN"

    ' Store folder info for breadcrumb update
    m.pendingFolderName = folderName
    m.pendingFolderId = folderId
end sub

sub displayFolderContents(response as object)
    content = CreateObject("roSGNode", "ContentNode")

    ' Create rows for different file types
    folderRow = content.CreateChild("ContentNode")
    folderRow.title = "Folders"

    videoRow = content.CreateChild("ContentNode")
    videoRow.title = "Videos"

    audioRow = content.CreateChild("ContentNode")
    audioRow.title = "Audio"

    imageRow = content.CreateChild("ContentNode")
    imageRow.title = "Images"

    otherRow = content.CreateChild("ContentNode")
    otherRow.title = "Other Files"

    ' Add back button if not in root
    if m.folderStack.Count() > 0 then
        backItem = folderRow.CreateChild("ContentNode")
        backItem.title = ".. (Back)"
        backItem.itemType = "back"
        backItem.HDPosterUrl = "pkg:/images/icon_focus_hd.png"
    end if

    ' Process folders
    if response.folders <> invalid then
        for each folder in response.folders
            item = folderRow.CreateChild("ContentNode")
            ' Handle both folder.name and folder.path (extract name from path if needed)
            folderName = folder.name
            if folderName = invalid then
                folderName = folder.path
                if folderName <> invalid then
                    pathParts = folderName.Split("/")
                    if pathParts.Count() > 0 then
                        folderName = pathParts[pathParts.Count() - 1]
                    end if
                else
                    folderName = "Unknown Folder"
                end if
            end if
            item.title = folderName
            item.itemType = "folder"
            item.folderId = Str(folder.id)
            item.HDPosterUrl = "pkg:/images/icon_focus_hd.png"
        end for
    end if

    ' Process files
    if response.files <> invalid then
        for each file in response.files
            item = invalid

            if isVideoFile(file.name) then
                item = videoRow.CreateChild("ContentNode")
            else if isAudioFile(file.name) then
                item = audioRow.CreateChild("ContentNode")
            else if isImageFile(file.name) then
                item = imageRow.CreateChild("ContentNode")
            else
                item = otherRow.CreateChild("ContentNode")
            end if

            if item <> invalid then
                item.title = file.name
                item.itemType = "file"
                item.fileId = Str(file.id)
                item.fileData = file

                ' Set thumbnail
                posterUrl = getImagePreviewUrl(file)
                if posterUrl <> "" then
                    item.HDPosterUrl = posterUrl
                else
                    item.HDPosterUrl = "pkg:/images/icon_focus_hd.png"
                end if
            end if
        end for
    end if

    ' Set content to grid
    m.fileGrid.content = content

    ' Show empty state if no content
    hasContent = (folderRow.getChildCount() + videoRow.getChildCount() + audioRow.getChildCount() + imageRow.getChildCount() + otherRow.getChildCount()) > 0
    m.emptyState.visible = not hasContent

    print "[GridScreen] Content created - Total items: "; hasContent
end sub

sub onItemSelected()
    selectedItem = m.fileGrid.content.getChild(m.fileGrid.rowItemSelected[0]).getChild(m.fileGrid.rowItemSelected[1])

    if selectedItem.itemType = "back" then
        ' Go back to previous folder
        if m.folderStack.Count() > 0 then
            prevFolder = m.folderStack.Pop()
            m.currentFolderId = prevFolder.id
            m.breadcrumbLabel.text = prevFolder.name

            if m.currentFolderId = "" then
                loadRootFolder()
            else
                ' Load previous folder - would need to implement loadFolderById
                loadRootFolder() ' For now, just go to root
            end if
        end if

    else if selectedItem.itemType = "folder" then
        ' Navigate to folder
        loadFolder(selectedItem.folderId, selectedItem.title)

    else if selectedItem.itemType = "file" then
        ' Handle file selection
        if isVideoFile(selectedItem.title) then
            playVideo(selectedItem.fileId, selectedItem.title)
        else if isImageFile(selectedItem.title) then
            showImage(selectedItem.fileData)
        else
            showFileInfo(selectedItem.fileData)
        end if
    end if
end sub

sub playVideo(fileId as string, fileName as string)
    ' Load credentials
    credentials = loadCredentials()
    if credentials = invalid then
        showError("Authentication required")
        return
    end if

    ' Get video stream URL
    streamUrl = getVideoStreamUrl(fileId, credentials.accessToken)

    if streamUrl <> "" then
        ' Signal parent to show video player
        m.top.getParent().playVideo = {
            url: streamUrl,
            title: fileName
        }
    else
        showError("Could not get video stream URL")
    end if
end sub

sub showImage(fileData as object)
    ' For now, just show file info
    showFileInfo(fileData)
end sub

sub showFileInfo(fileData as object)
    message = "File: " + fileData.name + chr(10)
    message += "Size: " + formatFileSize(fileData.size) + chr(10)
    message += "Type: " + fileData.mime_type

    showError(message) ' Reusing error dialog for info
end sub

sub showLoading(show as boolean)
    loadingIndicator = m.top.getParent().findNode("loadingIndicator")
    if loadingIndicator <> invalid then
        loadingIndicator.visible = show
    end if
end sub

sub showError(message as string)
    errorDialog = m.top.getParent().findNode("errorDialog")
    if errorDialog <> invalid then
        errorDialog.findNode("errorMessage").text = message
        errorDialog.visible = true
    end if
end sub

