sub init()
    m.button_group_1 = m.top.findNode("button_group_1")
    m.row_list = m.top.findNode("row_list_1")
    m.video = m.top.findNode("video_1")
    m.row_borders = m.top.findNode("rowBorders")
    m.category_title = m.top.findNode("categoryTitle")

    ' Subscription Panel references
    m.subscriptionPanel = m.top.findNode("subscriptionPanel")
    m.subUserEmail = m.top.findNode("subUserEmail")
    m.subPremiumBadge = m.top.findNode("subPremiumBadge")
    m.subPremiumStatusLabel = m.top.findNode("subPremiumStatusLabel")
    m.subStorageUsed = m.top.findNode("subStorageUsed")
    m.subStorageLimit = m.top.findNode("subStorageLimit")
    m.subStoragePercentage = m.top.findNode("subStoragePercentage")
    m.subStorageBarFill = m.top.findNode("subStorageBarFill")
    
    ' Debug: Verify bar node is found
    if m.subStorageBarFill <> invalid then
        print "[SeedrHomeScene] ✓ Progress bar node found successfully"
    else
        print "[SeedrHomeScene] ✗ ERROR: Progress bar node NOT found!"
    end if
    m.subMaxTorrents = m.top.findNode("subMaxTorrents")
    m.subActiveTorrents = m.top.findNode("subActiveTorrents")
    m.subConcurrentDownloads = m.top.findNode("subConcurrentDownloads")
    m.subViewPlansButtonGroup = m.top.findNode("subViewPlansButtonGroup")
    m.subViewPlansButton = m.top.findNode("subViewPlansButton")
    m.subViewPlansButtonBorder = m.top.findNode("subViewPlansButtonBorder")
    
    ' Track settings panel button focus state
    m.subscriptionButtonFocused = false

    ' Now Playing tile references
    m.nowPlayingTile = m.top.findNode("nowPlayingTile")
    m.nowPlayingTitle = m.top.findNode("nowPlayingTitle")
    m.nowPlayingInfo = m.top.findNode("nowPlayingInfo")

    ' Debug: Check if Now Playing elements were found
    print "[SeedrHomeScene] DEBUG: nowPlayingTile found: "; (m.nowPlayingTile <> invalid)
    print "[SeedrHomeScene] DEBUG: nowPlayingTitle found: "; (m.nowPlayingTitle <> invalid)
    print "[SeedrHomeScene] DEBUG: nowPlayingInfo found: "; (m.nowPlayingInfo <> invalid)

    ' Set background color on the component
    setBackgroundColor("0x035C78ff")

    m.button_group_1.observeField("buttonFocused", "onButtonGroupFocused")
    m.row_list.observeField("itemSelected", "onRowListSelected")
    m.row_list.observeField("itemFocused", "onRowListFocused")

    ' Home button trigger observer
    m.top.observeField("loadRootFolder", "onLoadRootFolderTriggered")

    ' Global audio state observers - observe parent's audio player
    m.top.observeField("visible", "onVisibleForAudioObserver")

    ' Set up audio observers immediately if visible
    if m.top.visible then
        onVisibleForAudioObserver()
    end if

    ' Force update now playing display on init
    updateNowPlayingDisplay()

    ' DEBUG: Force show now playing tile for testing (commented out for real testing)
    ' if m.nowPlayingTile <> invalid then
    '     print "[SeedrHomeScene] DEBUG: Force showing now playing tile for testing"
    '     m.nowPlayingTile.visible = true
    '     if m.nowPlayingTitle <> invalid then
    '         m.nowPlayingTitle.text = "TEST: Debug Track"
    '     end if
    '     if m.nowPlayingInfo <> invalid then
    '         m.nowPlayingInfo.text = "DEBUG: Testing visibility"
    '     end if
    ' end if

    ' Set up a timer to periodically update now playing display
    m.nowPlayingTimer = m.top.createChild("Timer")
    m.nowPlayingTimer.duration = 5.0 ' Reduced frequency to 5 seconds
    m.nowPlayingTimer.repeat = true
    m.nowPlayingTimer.observeField("fire", "onNowPlayingTimer")
    m.nowPlayingTimer.control = "start"

    m.button_group_1.setFocus(true)

    ' Make sure this component can receive key events
    m.top.setFocus(true)

    ' Set up API task
    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("response", "onApiResponse")

    ' Current folder tracking - using interface fields
    m.top.currentFolderId = ""
    m.top.skipAutoRestore = false
    m.folderStack = []
    m.currentCategory = 0
    m.allData = invalid

    ' Content type navigation within Home view
    m.currentContentType = 0 ' 0=folders, 1=audio, 2=videos, 3=images
    m.availableContentTypes = [] ' Will store available content types

    ' Load root folder when visible
    m.top.observeField("visible", "onVisibilityChange")

    ' Set initial title
    m.category_title.text = "All Files"

    ' Initialize DetailScreen integration - NEW ADDITION
    initDetailScreenIntegration()

    ' Initialize Screen Manager - NEW ADDITION
    initScreenManager()
end sub

sub setBackgroundColor(colour as string)
    ' SeedrHomeScene doesn't support backgroundColor directly
    ' Background will be handled by parent scene
    ' Note: colour parameter is intentionally unused as this function is a placeholder
end sub


sub createRowBorders()
    ' Clear existing borders by removing all children
    while m.row_borders.getChildCount() > 0
        m.row_borders.removeChild(m.row_borders.getChild(0))
    end while

    ' Show borders when content is available
    if m.row_list.content <> invalid then
        ' Row positions calculated elsewhere - borders were removed for cleaner UI design
        ' White borders removed - no more lines below rows
    end if
end sub

sub onVisibilityChange()
    if m.top.visible then
        print "[SeedrHomeScene] ==================== VISIBILITY CHANGED ===================="
        print "[SeedrHomeScene] 🟢 SEEDR HOME SCENE BECAME VISIBLE"
        print "[SeedrHomeScene] Current time: "; CreateObject("roDateTime").AsSeconds()
        print "[SeedrHomeScene] onVisibleChange - visible: true"
        print "[SeedrHomeScene] About to call restoreCurrentFolderState()"
        ' Restore current folder state instead of always loading root
        restoreCurrentFolderState()

        ' Ensure proper focus when becoming visible
        m.top.setFocus(true)
        if m.button_group_1 <> invalid then
            m.button_group_1.setFocus(true)
        end if

        ' Create a timer to ensure focus is properly set after a short delay
        focusTimer = m.top.createChild("Timer")
        focusTimer.duration = 0.1
        focusTimer.observeField("fire", "onFocusTimer")
        focusTimer.control = "start"

        print "[SeedrHomeScene] Focus restored after visibility change"
    end if
end sub

sub onFocusTimer()
    print "[SeedrHomeScene] Focus timer fired - ensuring focus is set"
    m.top.setFocus(true)
    if m.button_group_1 <> invalid then
        m.button_group_1.setFocus(true)
    end if
    print "[SeedrHomeScene] Focus timer completed"
end sub

sub restoreCurrentFolderState()
    print "[SeedrHomeScene] ==================== RESTORE FOLDER STATE ===================="
    print "[SeedrHomeScene] skipAutoRestore flag: "; m.top.skipAutoRestore
    print "[SeedrHomeScene] currentFolderId: "; m.top.currentFolderId

    ' Check if we should skip auto-restore (e.g., coming back from FolderDetailsScreen)
    if m.top.skipAutoRestore = true then
        print "[SeedrHomeScene] SKIPPING auto-restore as requested by flag"
        m.top.skipAutoRestore = false ' Reset the flag
        print "[SeedrHomeScene] Reset skipAutoRestore flag to false"
        print "[SeedrHomeScene] ============================================================="
        return
    end if

    ' If we have a current folder, load it; otherwise load root
    if m.top.currentFolderId <> "" then
        print "[SeedrHomeScene] RESTORING folder state for ID: "; m.top.currentFolderId
        ' Load the current folder to refresh its contents
        credentials = loadCredentials()
        if credentials <> invalid then
            print "[SeedrHomeScene] Making API request to restore folder: "; m.top.currentFolderId
            m.apiTask.request = {
                method: "get_folder"
                accessToken: credentials.accessToken
                folderId: m.top.currentFolderId
            }
            m.apiTask.control = "RUN"
            print "[SeedrHomeScene] API request sent for folder restoration"
        else
            print "[SeedrHomeScene] ERROR: No credentials for folder restoration"
        end if
    else
        print "[SeedrHomeScene] No current folder, loading root"
        loadRootFolder()
    end if
    print "[SeedrHomeScene] ============================================================="
end sub

sub loadRootFolder()
    print "[SeedrHomeScene] ==================== LOAD ROOT FOLDER FUNCTION ===================="
    print "[SeedrHomeScene] 📁 loadRootFolder() function called"
    print "[SeedrHomeScene] Current time: "; CreateObject("roDateTime").AsSeconds()

    credentials = loadCredentials()
    if credentials = invalid then
        print "[SeedrHomeScene] ❌ ERROR: No credentials available for root folder load"
        return
    end if

    print "[SeedrHomeScene] ✅ Credentials loaded successfully"
    print "[SeedrHomeScene] Access token length: "; Len(credentials.accessToken)

    ' Set current folder to root
    print "[SeedrHomeScene] Setting current folder to ROOT (empty string)"
    m.top.currentFolderId = ""
    m.folderStack = []
    print "[SeedrHomeScene] Folder stack cleared, current count: "; m.folderStack.Count()
    ' Breadcrumb removed - no longer needed

    print "[SeedrHomeScene] 🌐 Preparing API request for root folders"
    m.apiTask.request = {
        method: "get_folders"
        accessToken: credentials.accessToken
    }
    print "[SeedrHomeScene] API request configured with method: get_folders"
    print "[SeedrHomeScene] 🚀 Starting API task execution..."
    m.apiTask.control = "RUN"
    print "[SeedrHomeScene] API task control set to RUN"
    print "[SeedrHomeScene] ============================================================="
end sub

sub onApiResponse()
    print "[SeedrHomeScene] ==================== API RESPONSE ===================="
    response = m.apiTask.response
    print "[SeedrHomeScene] API Response success: "; response.success
    print "[SeedrHomeScene] API Response type: "; response.type

    if response.success then
        if response.type = "get_folders" then
            print "[SeedrHomeScene] Processing GET_FOLDERS response"
            m.allData = response.data
            print "[SeedrHomeScene] Response data keys: "; response.data.keys()
            displayFolderContents(response.data)
            ' Breadcrumb removed - no longer needed
            m.top.currentFolderId = ""

        else if response.type = "get_folder" then
            print "[SeedrHomeScene] Processing GET_FOLDER response"
            m.allData = response.data
            print "[SeedrHomeScene] Response data keys: "; response.data.keys()

            if response.data.files <> invalid
                print "[SeedrHomeScene] Folder contains "; response.data.files.count(); " files"
                for i = 0 to response.data.files.count() - 1
                    file = response.data.files[i]
                    print "[SeedrHomeScene] File "; i; ": "; file.name; " (type: "; getFileType(file.name); ")"
                end for
            else
                print "[SeedrHomeScene] No files in folder response"
            end if

            if response.data.folders <> invalid
                print "[SeedrHomeScene] Folder contains "; response.data.folders.count(); " subfolders"
            else
                print "[SeedrHomeScene] No subfolders in folder response"
            end if

            ' NEW: Check if this is a folder with contents that should show DetailScreen
            print "[SeedrHomeScene] Checking if folder should show DetailScreen..."
            if shouldShowFolderDetailScreen(response.data) then
                print "[SeedrHomeScene] YES - Launching DetailScreen for folder contents"
                showFolderDetailScreen(response.data)
            else
                print "[SeedrHomeScene] NO - Using traditional folder display"
                displayFolderContents(response.data)
            end if

            ' Update current folder ID for the loaded folder
            if m.pendingFolderName <> invalid and m.pendingFolderId <> invalid then
                m.top.currentFolderId = m.pendingFolderId
                print "[SeedrHomeScene] Updated current folder ID to: "; m.top.currentFolderId
                ' Breadcrumb removed - no longer needed
                m.pendingFolderName = invalid
                m.pendingFolderId = invalid
            end if
        else if response.type = "subscription" then
            print "[SeedrHomeScene] Processing SUBSCRIPTION response"
            if response.data <> invalid then
                print "[SeedrHomeScene] Subscription data received, displaying..."
                displaySubscriptionInfo(response.data)
            else
                print "[SeedrHomeScene] Subscription response has no data"
                displayDefaultSubscriptionInfo("No data available")
            end if
        else
            print "[SeedrHomeScene] Unknown API response type: "; response.type
        end if
    else
        print "[SeedrHomeScene] API Error: "; response.message
        ' If subscription request failed, show error
        if response.type = "subscription" then
            displayDefaultSubscriptionInfo("Error: " + response.message)
        end if
    end if
    print "[SeedrHomeScene] ============================================================="
end sub

sub displayFolderContents(response as object)
    ' Store folder contents for playlist functionality
    m.currentFolderContents = response

    content = CreateObject("roSGNode", "ContentNode")

    ' For Home view (category 0), show only one content type at a time
    if m.currentCategory = 0 then
        ' Determine available content types
        m.availableContentTypes = []
        if response.folders <> invalid and response.folders.Count() > 0 then
            m.availableContentTypes.Push("folders")
        end if
        if response.files <> invalid and response.files.Count() > 0 then
            ' Check what file types exist
            hasAudio = false
            hasVideo = false
            hasImages = false
            for each file in response.files
                if isAudioFile(file.name) then hasAudio = true
                if isVideoFile(file.name) then hasVideo = true
                if isImageFile(file.name) then hasImages = true
            end for
            if hasAudio then m.availableContentTypes.Push("audio")
            if hasVideo then m.availableContentTypes.Push("videos")
            if hasImages then m.availableContentTypes.Push("images")
        end if

        ' Show current content type
        showCurrentContentType(content, response)
    else
        ' For specific categories, show that content type
        if m.currentCategory = 1 and response.folders <> invalid and response.folders.Count() > 0 then
            showFolders(content, response)
        end if
    end if

    if response.files <> invalid and response.files.Count() > 0 then
        videoFiles = []
        audioFiles = []
        imageFiles = []
        documentFiles = []
        otherFiles = []

        for each file in response.files
            if isVideoFile(file.name) then
                videoFiles.Push(file)
            else if isAudioFile(file.name) then
                audioFiles.Push(file)
            else if isImageFile(file.name) then
                imageFiles.Push(file)
            else if isDocumentFile(file.name) then
                documentFiles.Push(file)
            else
                otherFiles.Push(file)
            end if
        end for

        if (m.currentCategory = 0 or m.currentCategory = 2) and videoFiles.Count() > 0 then
            addFileRow(content, "", videoFiles) ' Remove individual row title
        end if

        if (m.currentCategory = 0 or m.currentCategory = 3) and audioFiles.Count() > 0 then
            addFileRow(content, "", audioFiles) ' Remove individual row title
        end if

        if (m.currentCategory = 0 or m.currentCategory = 4) and imageFiles.Count() > 0 then
            addFileRow(content, "", imageFiles) ' Remove individual row title
        end if

        if m.currentCategory = 0 and documentFiles.Count() > 0 then
            addFileRow(content, "", documentFiles) ' Remove individual row title
        end if

        if m.currentCategory = 0 and otherFiles.Count() > 0 then
            addFileRow(content, "", otherFiles) ' Remove individual row title
        end if
    end if

    m.row_list.content = content

    ' Create white borders below each row (only on home screen)
    createRowBorders()
end sub

' Show current content type based on navigation
sub showCurrentContentType(content as object, response as object)
    if m.availableContentTypes.Count() = 0 then
        m.category_title.text = "No Content"
        return
    end if

    ' Ensure currentContentType is within bounds
    if m.currentContentType >= m.availableContentTypes.Count() then
        m.currentContentType = 0
    end if

    ' Get current content type
    currentType = m.availableContentTypes[m.currentContentType]

    ' Show appropriate content and update title
    if currentType = "folders" then
        showFolders(content, response)
        m.category_title.text = "Folders"
    else if currentType = "audio" then
        showAudioFiles(content, response)
        m.category_title.text = "Audio"
    else if currentType = "videos" then
        showVideoFiles(content, response)
        m.category_title.text = "Videos"
    else if currentType = "images" then
        showImageFiles(content, response)
        m.category_title.text = "Images"
    end if
end sub

' Show folders content
sub showFolders(content as object, response as object)
    if response.folders <> invalid and response.folders.Count() > 0 then
        folderRow = content.CreateChild("ContentNode")
        folderRow.title = ""

        if m.folderStack.Count() > 0 then
            backItem = folderRow.CreateChild("ContentNode")
            backItem.title = ".. (Back)"
            backItem.addFields({ "itemType": "back" })
            backItem.HDPosterUrl = "pkg:/images/folder 3.png"
        end if

        for each folder in response.folders
            item = folderRow.CreateChild("ContentNode")
            folderName = folder.path
            if folderName = invalid then
                folderName = folder.name
            end if
            if folderName = invalid then
                folderName = "Unknown Folder"
            end if
            item.title = folderName
            item.addFields({ "itemType": "folder", "folderId": folder.id.ToStr() })
            item.HDPosterUrl = "pkg:/images/folder 3.png"
        end for
    end if
end sub

' Show audio files content
sub showAudioFiles(content as object, response as object)
    if response.files <> invalid and response.files.Count() > 0 then
        audioFiles = []
        for each file in response.files
            if isAudioFile(file.name) then
                audioFiles.Push(file)
            end if
        end for

        if audioFiles.Count() > 0 then
            addFileRow(content, "", audioFiles)
        end if
    end if
end sub

' Handle global Home button trigger from HeroMainScene
sub onLoadRootFolderTriggered()
    print "[SeedrHomeScene] ==================== GLOBAL HOME TRIGGER RECEIVED ===================="
    print "[SeedrHomeScene] 📡 onLoadRootFolderTriggered() called"
    print "[SeedrHomeScene] loadRootFolder field value: "; m.top.loadRootFolder
    print "[SeedrHomeScene] Current time: "; CreateObject("roDateTime").AsSeconds()

    if m.top.loadRootFolder = true then
        print "[SeedrHomeScene] ✅ Global Home trigger confirmed - processing..."
        print "[SeedrHomeScene] 🏠 Global Home button triggered - loading root folder"

        ' Log current state BEFORE clearing
        print "[SeedrHomeScene] BEFORE - Folder stack count: "; m.folderStack.Count()
        print "[SeedrHomeScene] BEFORE - Current folder ID: "; m.top.currentFolderId
        print "[SeedrHomeScene] BEFORE - Skip auto restore: "; m.top.skipAutoRestore
        print "[SeedrHomeScene] BEFORE - Button focused: "; m.button_group_1.buttonFocused
        print "[SeedrHomeScene] BEFORE - Current category: "; m.currentCategory
        print "[SeedrHomeScene] BEFORE - Category title: "; m.category_title.text

        ' Clear all navigation state
        print "[SeedrHomeScene] 🧹 Clearing all navigation state..."
        m.folderStack = []
        m.top.currentFolderId = ""
        m.top.skipAutoRestore = false

        ' Reset to Home category (index 0)
        print "[SeedrHomeScene] 🔄 Resetting to Home category..."
        m.button_group_1.buttonFocused = 0
        m.currentCategory = 0
        m.category_title.text = "All Files"

        ' Log state AFTER clearing
        print "[SeedrHomeScene] AFTER - Folder stack count: "; m.folderStack.Count()
        print "[SeedrHomeScene] AFTER - Current folder ID: "; m.top.currentFolderId
        print "[SeedrHomeScene] AFTER - Skip auto restore: "; m.top.skipAutoRestore
        print "[SeedrHomeScene] AFTER - Button focused: "; m.button_group_1.buttonFocused
        print "[SeedrHomeScene] AFTER - Current category: "; m.currentCategory
        print "[SeedrHomeScene] AFTER - Category title: "; m.category_title.text

        ' Load root folder
        print "[SeedrHomeScene] 🚀 Calling loadRootFolder() from global trigger..."
        loadRootFolder()

        ' Reset the trigger field
        print "[SeedrHomeScene] 🔄 Resetting trigger field to false..."
        m.top.loadRootFolder = false
        print "[SeedrHomeScene] Trigger field reset to: "; m.top.loadRootFolder

        print "[SeedrHomeScene] ✅ Global Home navigation completed successfully"
    else
        print "[SeedrHomeScene] ⚠️  Global Home trigger received but field is false"
    end if
    print "[SeedrHomeScene] ============================================================="
end sub

' Show video files content
sub showVideoFiles(content as object, response as object)
    if response.files <> invalid and response.files.Count() > 0 then
        videoFiles = []
        for each file in response.files
            if isVideoFile(file.name) then
                videoFiles.Push(file)
            end if
        end for

        if videoFiles.Count() > 0 then
            addFileRow(content, "", videoFiles)
        end if
    end if
end sub

' Show image files content
sub showImageFiles(content as object, response as object)
    if response.files <> invalid and response.files.Count() > 0 then
        imageFiles = []
        for each file in response.files
            if isImageFile(file.name) then
                imageFiles.Push(file)
            end if
        end for

        if imageFiles.Count() > 0 then
            addFileRow(content, "", imageFiles)
        end if
    end if
end sub

sub addFileRow(content as object, rowTitle as string, files as object)
    fileRow = content.CreateChild("ContentNode")
    fileRow.title = rowTitle

    for each file in files
        item = fileRow.CreateChild("ContentNode")
        item.title = file.name
        item.addFields({ "itemType": "file", "fileId": file.id.ToStr(), "fileData": file })

        posterUrl = getImagePreviewUrl(file)
        if posterUrl <> "" then
            item.HDPosterUrl = posterUrl
        else
            ' Set appropriate icon based on file type
            if isAudioFile(file.name) then
                item.HDPosterUrl = "pkg:/images/audio5.png"
            else if isDocumentFile(file.name) then
                item.HDPosterUrl = "pkg:/images/doc 2.png"
            else if isImageFile(file.name) then
                item.HDPosterUrl = "pkg:/images/icon_focus_hd.png" ' Could add image icon later
            else
                item.HDPosterUrl = "pkg:/images/icon_focus_hd.png"
            end if
        end if
    end for

end sub

sub onButtonGroupFocused()
    m.currentCategory = m.button_group_1.buttonFocused

    ' Update the dynamic title based on selected category
    if m.currentCategory = 0 then
        m.category_title.text = "All Files"
    else if m.currentCategory = 1 then
        m.category_title.text = "Folders"
    else if m.currentCategory = 2 then
        m.category_title.text = "Videos"
    else if m.currentCategory = 3 then
        m.category_title.text = "Audio"
    else if m.currentCategory = 4 then
        m.category_title.text = "Images"
    else if m.currentCategory = 5 then
        m.category_title.text = "Account"
    end if

    ' Handle settings/account category (button 5)
    if m.currentCategory = 5 then
        ' SETTINGS FOCUSED - Show account panel in content area
        print "[SeedrHomeScene] ⚙️ SETTINGS FOCUSED - Showing account info on right"
        
        ' Hide row list and borders, show subscription panel
        if m.row_list <> invalid then m.row_list.visible = false
        if m.row_borders <> invalid then m.row_borders.visible = false
        if m.subscriptionPanel <> invalid then m.subscriptionPanel.visible = true
        
        ' Load subscription data
        loadSubscriptionData()
    else
        ' Other categories - show row list, hide subscription panel
        if m.subscriptionPanel <> invalid then m.subscriptionPanel.visible = false
        if m.row_list <> invalid then m.row_list.visible = true
        if m.row_borders <> invalid then m.row_borders.visible = true
        
        ' Unfocus settings button if it was focused
        if m.subscriptionButtonFocused then
            m.subscriptionButtonFocused = false
            if m.subViewPlansButtonBorder <> invalid then m.subViewPlansButtonBorder.visible = false
            if m.subViewPlansButton <> invalid then m.subViewPlansButton.color = "0xFF4444FF"
        end if
        
        ' Display folder contents for non-subscription categories
        if m.allData <> invalid then
            displayFolderContents(m.allData)
        end if
    end if
end sub

sub onRowListSelected()
    print "[SeedrHomeScene] ==================== ROW LIST SELECTION ===================="
    rowItemSelected = m.row_list.rowItemSelected
    print "[SeedrHomeScene] Row item selected: "; rowItemSelected

    rowListContent = m.row_list.content
    selectedRow = rowListContent.getChild(rowItemSelected.getEntry(0))
    selectedItem = selectedRow.getChild(rowItemSelected.getEntry(1))

    print "[SeedrHomeScene] Selected row: "; rowItemSelected.getEntry(0); ", item: "; rowItemSelected.getEntry(1)
    print "[SeedrHomeScene] Selected item title: "; selectedItem.title
    if selectedItem.hasField("itemType")
        print "[SeedrHomeScene] Item type: "; selectedItem.itemType
    else
        print "[SeedrHomeScene] No itemType field found"
    end if

    if selectedItem.hasField("itemType") and selectedItem.itemType = "back" then
        print "[SeedrHomeScene] BACK button selected"
        if m.folderStack.Count() > 0 then
            prevFolder = m.folderStack.Pop()
            m.top.currentFolderId = prevFolder.id
            print "[SeedrHomeScene] Going back to folder: "; prevFolder.name; " (ID: "; prevFolder.id; ")"
            ' Breadcrumb removed - no longer needed
            if m.top.currentFolderId = "" then
                print "[SeedrHomeScene] Loading root folder"
                loadRootFolder()
            else
                ' Load the previous folder, not root folder
                print "[SeedrHomeScene] Loading previous folder"
                loadFolder(prevFolder.id, prevFolder.name)
            end if
        else
            print "[SeedrHomeScene] No previous folder in stack"
        end if
    else if selectedItem.hasField("itemType") and selectedItem.itemType = "folder" then
        print "[SeedrHomeScene] FOLDER selected: "; selectedItem.title; " (ID: "; selectedItem.folderId; ")"
        print "[SeedrHomeScene] CRITICAL: About to call loadFolder - checking if we should skip"
        print "[SeedrHomeScene] skipAutoRestore flag: "; m.top.skipAutoRestore

        if m.top.skipAutoRestore = true then
            print "[SeedrHomeScene] SKIPPING folder load due to skipAutoRestore flag"
            m.top.skipAutoRestore = false
            print "[SeedrHomeScene] Reset skipAutoRestore flag"
        else
            print "[SeedrHomeScene] Proceeding with folder load"
            loadFolder(selectedItem.folderId, selectedItem.title)
        end if
    else if selectedItem.hasField("itemType") and selectedItem.itemType = "file" then
        print "[SeedrHomeScene] FILE selected: "; selectedItem.title
        handleFileSelection(selectedItem)
    else
        print "[SeedrHomeScene] UNKNOWN item type or missing itemType field"
    end if
    print "[SeedrHomeScene] ============================================================="
end sub

sub loadFolder(folderId as string, folderName as string)
    print "[SeedrHomeScene] Navigating to folder: "; folderName; " (ID: "; folderId; ")"

    credentials = loadCredentials()
    if credentials = invalid then
        return
    end if

    ' Add current folder to stack for back navigation BEFORE updating
    if m.top.currentFolderId <> "" then
        m.folderStack.Push({
            id: m.top.currentFolderId,
            name: "Previous Folder" ' Breadcrumb removed - using generic name
        })
    end if

    ' Breadcrumb removed - no longer needed

    ' Ensure folderId is string to avoid scientific notation
    folderIdStr = folderId.ToStr()
    print "[SeedrHomeScene] Loading folder contents with ID: "; folderIdStr

    m.apiTask.request = {
        method: "get_folder"
        accessToken: credentials.accessToken
        folderId: folderIdStr
    }
    m.apiTask.control = "RUN"

    m.pendingFolderName = folderName
    m.pendingFolderId = folderIdStr
    m.top.currentFolderId = folderIdStr
end sub

sub playVideo(fileId as string, fileName as string)
    credentials = loadCredentials()
    if credentials = invalid then
        return
    end if

    streamUrl = getVideoStreamUrl(fileId, credentials.accessToken)
    if streamUrl <> "" then
        m.top.getParent().playVideo = {
            url: streamUrl,
            title: fileName
        }
    end if
end sub

sub onRowListFocused()
    rowListFocusedItem = m.row_list.itemFocused
    if rowListFocusedItem <> invalid then
        setCategoryName()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    ' Only handle key events if this scene is visible
    if not m.top.visible then
        return false
    end if

    ' Log ALL key events for debugging
    print "[SeedrHomeScene] ==================== KEY EVENT ===================="
    print "[SeedrHomeScene] 🎮 Key pressed: '"; key; "' (press="; press; ")"
    print "[SeedrHomeScene] Current time: "; CreateObject("roDateTime").AsSeconds()
    print "[SeedrHomeScene] Button group has focus: "; m.button_group_1.isInFocusChain()
    print "[SeedrHomeScene] Row list has focus: "; m.row_list.isInFocusChain()
    if m.button_group_1.isInFocusChain() then
        print "[SeedrHomeScene] Currently focused button: "; m.button_group_1.buttonFocused
    end if
    print "[SeedrHomeScene] ============================================================="

    handled = false

    ' Handle OK key when Settings Logout button is focused (CHECK FIRST!)
    if key = "OK" and m.subscriptionButtonFocused then
        print "[SeedrHomeScene] 🚪 OK pressed on Logout button - Logging out"
        handleLogout()
        
        ' Reset button focus state after logout
        m.subscriptionButtonFocused = false
        if m.subViewPlansButtonBorder <> invalid then m.subViewPlansButtonBorder.visible = false
        if m.subViewPlansButton <> invalid then m.subViewPlansButton.color = "0xFF4444FF"
        
        return true
    end if

    ' Handle OK key for Home button (works on both press and release)
    if key = "OK" and m.button_group_1.isInFocusChain() then
        ' Handle button selection (OK press on button group)
        selectedButton = m.button_group_1.buttonFocused
        print "[SeedrHomeScene] ==================== BUTTON SELECTED ===================="
        print "[SeedrHomeScene] 🎮 LOCAL BUTTON PRESSED: "; selectedButton
        print "[SeedrHomeScene] Button focus chain status: "; m.button_group_1.isInFocusChain()
        print "[SeedrHomeScene] Key press state: "; press
        print "[SeedrHomeScene] Current time: "; CreateObject("roDateTime").AsSeconds()

        if selectedButton = 0 then
            ' HOME BUTTON - Always load root folder regardless of current location
            print "[SeedrHomeScene] 🏠 LOCAL HOME BUTTON PRESSED - Loading root folder"
            print "[SeedrHomeScene] BEFORE - Current folder ID: "; m.top.currentFolderId
            print "[SeedrHomeScene] BEFORE - Folder stack count: "; m.folderStack.Count()
            print "[SeedrHomeScene] BEFORE - Skip auto restore: "; m.top.skipAutoRestore
            print "[SeedrHomeScene] BEFORE - Current category: "; m.currentCategory
            print "[SeedrHomeScene] Forcing navigation to ROOT FOLDER"

            ' Hide subscription panel and show row list
            if m.subscriptionPanel <> invalid then m.subscriptionPanel.visible = false
            if m.row_list <> invalid then m.row_list.visible = true
            if m.row_borders <> invalid then m.row_borders.visible = true

            ' Clear folder stack and current folder
            m.folderStack = []
            m.top.currentFolderId = ""
            m.top.skipAutoRestore = false

            print "[SeedrHomeScene] AFTER - Folder stack cleared, count: "; m.folderStack.Count()
            print "[SeedrHomeScene] AFTER - Current folder ID cleared: "; m.top.currentFolderId
            print "[SeedrHomeScene] AFTER - Skip auto restore reset: "; m.top.skipAutoRestore

            ' Load root folder
            print "[SeedrHomeScene] 🚀 CALLING loadRootFolder() function..."
            loadRootFolder()
            print "[SeedrHomeScene] ✅ Root folder load initiated successfully"
        else
            ' Other buttons - just change focus/filter (existing behavior)
            print "[SeedrHomeScene] Category button pressed: "; selectedButton
            
            ' Hide subscription panel and show row list
            if m.subscriptionPanel <> invalid then m.subscriptionPanel.visible = false
            if m.row_list <> invalid then m.row_list.visible = true
            if m.row_borders <> invalid then m.row_borders.visible = true
            
            ' Don't use jumpToItem - just set focus and maintain current position
            ' This prevents unwanted jumps when switching categories
            m.row_list.setFocus(true)
            onRowListFocused()
        end if
        print "[SeedrHomeScene] ============================================================="
        return true
    end if

    if press = true then
        if key = "up" and m.currentCategory = 0 then
            ' Navigate to previous content type
            if m.availableContentTypes.Count() > 0 then
                m.currentContentType = m.currentContentType - 1
                if m.currentContentType < 0 then
                    m.currentContentType = m.availableContentTypes.Count() - 1
                end if
                if m.allData <> invalid then
                    displayFolderContents(m.allData)
                end if
            end if
            handled = true
        else if key = "down" and m.currentCategory = 0 then
            ' Navigate to next content type
            if m.availableContentTypes.Count() > 0 then
                m.currentContentType = m.currentContentType + 1
                if m.currentContentType >= m.availableContentTypes.Count() then
                    m.currentContentType = 0
                end if
                if m.allData <> invalid then
                    displayFolderContents(m.allData)
                end if
            end if
            handled = true
        else if key = "right" and m.button_group_1.isInFocusChain() then
            ' Check if on settings button - if so, focus the Logout button
            if m.currentCategory = 5 then
                print "[SeedrHomeScene] 🚪 RIGHT pressed on Account - Focusing Logout button"
                m.subscriptionButtonFocused = true
                if m.subViewPlansButtonBorder <> invalid then m.subViewPlansButtonBorder.visible = true
                if m.subViewPlansButton <> invalid then m.subViewPlansButton.color = "0xFF6666FF" ' Brighter red for focus
                handled = true
            else
                ' Don't use jumpToItem - just set focus and stay at current position
                ' This prevents jumping back to old positions when navigating back and forth
                m.row_list.setFocus(true)
                onRowListFocused()
                handled = true
            end if
        else if key = "left" then
            ' Check if settings button is focused - unfocus it
            if m.subscriptionButtonFocused then
                print "[SeedrHomeScene] LEFT pressed - Unfocusing Logout button"
                m.subscriptionButtonFocused = false
                if m.subViewPlansButtonBorder <> invalid then m.subViewPlansButtonBorder.visible = false
                if m.subViewPlansButton <> invalid then m.subViewPlansButton.color = "0xFF4444FF" ' Normal red
                m.button_group_1.setFocus(true)
                handled = true
            else if m.row_list.rowItemFocused.GetEntry(1) = 0 then
                m.button_group_1.setFocus(true)
                handled = true
            end if
            ' Global audio controls - work from home screen
        else if key = "fastforward" then
            print "[SeedrHomeScene] Fastforward key pressed - Global audio next"
            if sendGlobalAudioCommand("next") then handled = true

        else if key = "rewind" then
            print "[SeedrHomeScene] Rewind key pressed - Global audio previous"
            if sendGlobalAudioCommand("previous") then handled = true

        else if key = "play" then
            print "[SeedrHomeScene] Play key pressed - Global audio play/pause"
            if sendGlobalAudioCommand("play_pause") then handled = true

        else if key = "*" then
            print "[SeedrHomeScene] * key pressed - Global audio previous"
            if sendGlobalAudioCommand("previous") then handled = true

        else if key = "#" then
            print "[SeedrHomeScene] # key pressed - Global audio next"
            if sendGlobalAudioCommand("next") then handled = true

        else if key = "back" then
            if m.video.hasFocus() then
                m.video.control = "stop"
                m.video.visible = "false"
                m.row_list.setFocus(true)
                handled = true
            else if m.top.currentFolderId = "" and m.row_list.hasFocus() then
                ' BACK from file list on home screen - return to sidebar WITHOUT changing button
                print "[SeedrHomeScene] BACK pressed from file list - returning to sidebar"
                m.button_group_1.setFocus(true)
                handled = true
            else if m.top.currentFolderId = "" and m.button_group_1.hasFocus() then
                ' BACK on sidebar buttons - cycle through buttons
                currentButton = m.button_group_1.buttonFocused
                if currentButton > 0 then
                    ' Go to previous category button
                    m.button_group_1.buttonFocused = currentButton - 1
                else
                    ' If on first button, go to last button
                    m.button_group_1.buttonFocused = m.button_group_1.getChildCount() - 1
                end if
                m.button_group_1.setFocus(true)
                handled = true
            else
                ' In a subfolder, go back to parent folder
                if m.folderStack.Count() > 0 then
                    prevFolder = m.folderStack.Pop()
                    m.top.currentFolderId = prevFolder.id
                    ' Breadcrumb removed - no longer needed
                    if m.top.currentFolderId = "" then
                        loadRootFolder()
                    else
                        loadFolder(prevFolder.id, prevFolder.name)
                    end if
                    handled = true
                else
                    ' If no folder stack, go back to home/root
                    print "[SeedrHomeScene] No folder stack, going back to home"
                    m.top.currentFolderId = ""
                    ' Breadcrumb removed - no longer needed
                    loadRootFolder()
                    handled = true
                end if
            end if
        end if
    end if
    return handled
end function

sub setCategoryName()
    ' Breadcrumb removed - no longer needed
    ' This function is kept for compatibility but no longer requires parameters
end sub

' Handle file selection based on file type
sub handleFileSelection(fileItem as object)
    print "[SeedrHomeScene] ==================== FILE SELECTION ===================="
    print "[SeedrHomeScene] handleFileSelection: "; fileItem.title
    print "[SeedrHomeScene] File item keys: "; fileItem.keys()

    ' Check if we have file metadata
    fileData = fileItem.fileData
    if fileData <> invalid then
        print "[SeedrHomeScene] File has metadata - using metadata detection"
        print "[SeedrHomeScene] File metadata keys: "; fileData.keys()

        if fileData.is_video = true then
            print "[SeedrHomeScene] File is VIDEO (metadata) - launching DetailScreen"
            launchDetailScreenForFile(fileItem)
        else if fileData.is_audio = true then
            print "[SeedrHomeScene] File is AUDIO (metadata) - playing audio"
            playAudioFile(fileItem)
        else if fileData.is_image = true then
            print "[SeedrHomeScene] File is IMAGE (metadata) - showing image"
            showImageFile(fileItem)
        else
            print "[SeedrHomeScene] File is OTHER (metadata) - showing info"
            showFileInfo(fileItem)
        end if
    else
        print "[SeedrHomeScene] No file metadata - using filename detection"

        if isVideoFile(fileItem.title) then
            print "[SeedrHomeScene] File is VIDEO (filename) - launching DetailScreen"
            launchDetailScreenForFile(fileItem)
        else if isAudioFile(fileItem.title) then
            print "[SeedrHomeScene] File is AUDIO (filename) - playing audio"
            playAudioFile(fileItem)
        else if isImageFile(fileItem.title) then
            print "[SeedrHomeScene] File is IMAGE (filename) - showing image"
            showImageFile(fileItem)
        else if isDocumentFile(fileItem.title) then
            print "[SeedrHomeScene] File is DOCUMENT (filename) - showing document"
            showDocumentFile(fileItem)
        else
            print "[SeedrHomeScene] File is UNKNOWN (filename) - showing info"
            showFileInfo(fileItem)
        end if
    end if
    print "[SeedrHomeScene] ============================================================="
end sub

' Play video file
sub playVideoFile(fileItem as object)
    print "[SeedrHomeScene] Playing video: "; fileItem.title

    ' Signal parent scene to handle video playback
    parentNode = m.top.getParent()
    sceneFound = false
    maxLevels = 5
    currentLevel = 0

    while parentNode <> invalid and currentLevel < maxLevels
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
            isAudio: false
        }
        print "[SeedrHomeScene] Signaled scene to play video with fileId: "; fileItem.fileId
    else
        print "[SeedrHomeScene] ERROR: Could not find parent scene"
    end if
end sub

' Play audio file
sub playAudioFile(fileItem as object)
    print "[SeedrHomeScene] ======= PLAY AUDIO FILE CALLED ======="
    print "[SeedrHomeScene] Playing audio: "; fileItem.title

    ' Signal parent scene to handle audio playback
    parentNode = m.top.getParent()
    sceneFound = false
    maxLevels = 5
    currentLevel = 0

    while parentNode <> invalid and currentLevel < maxLevels
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
            isAudio: true,
            folderData: m.currentFolderContents, ' Pass folder data for playlist setup
            currentFileItem: fileItem ' Pass current file for index calculation
        }
        print "[SeedrHomeScene] Signaled scene to play audio with fileId: "; fileItem.fileId
        print "[SeedrHomeScene] Folder data passed to HeroMainScene for playlist setup"

        ' Set up folder files for next/previous navigation
        setupFolderFilesForAudioPlayer(fileItem)
    else
        print "[SeedrHomeScene] ERROR: Could not find parent scene"
    end if
end sub

' Set up folder files for audio player next/previous navigation
sub setupFolderFilesForAudioPlayer(currentFileItem as object)
    print "[SeedrHomeScene] setupFolderFilesForAudioPlayer called for: "; currentFileItem.title

    ' Get current folder files (audio files only)
    audioFiles = []

    print "[SeedrHomeScene] m.currentFolderContents valid: "; (m.currentFolderContents <> invalid)
    if m.currentFolderContents <> invalid then
        print "[SeedrHomeScene] m.currentFolderContents.files valid: "; (m.currentFolderContents.files <> invalid)
        if m.currentFolderContents.files <> invalid then
            print "[SeedrHomeScene] Total files in current folder: "; m.currentFolderContents.files.count()
            for i = 0 to m.currentFolderContents.files.count() - 1
                file = m.currentFolderContents.files[i]
                if file <> invalid then
                    fileName = invalid
                    if file.title <> invalid then
                        fileName = file.title
                    else if file.name <> invalid then
                        fileName = file.name
                    end if

                    if fileName <> invalid and isAudioFile(fileName) then
                        ' Transform file to match expected format for SeedrAudioPlayer
                        audioFileItem = {
                            title: fileName,
                            fileId: file.id.ToStr(),
                            fileData: file
                        }
                        audioFiles.Push(audioFileItem)
                        print "[SeedrHomeScene] Added to playlist: "; fileName
                    end if
                end if
            end for
        else
            print "[SeedrHomeScene] ERROR: m.currentFolderContents.files is invalid"
        end if
    else
        print "[SeedrHomeScene] ERROR: m.currentFolderContents is invalid - folder contents not stored"
    end if

    print "[SeedrHomeScene] Total audio files found: "; audioFiles.count()

    ' Find current file index
    currentIndex = 0
    for i = 0 to audioFiles.Count() - 1
        if audioFiles[i].fileId = currentFileItem.fileId then
            currentIndex = i
            exit for
        end if
    end for

    ' Set up audio player with folder files
    parentNode = m.top.getParent()
    print "[SeedrHomeScene] Parent node valid: "; (parentNode <> invalid)

    if parentNode <> invalid then
        audioPlayer = parentNode.findNode("seedrAudioPlayer")
        print "[SeedrHomeScene] Audio player found: "; (audioPlayer <> invalid)

        if audioPlayer <> invalid then
            print "[SeedrHomeScene] Sending playlist to audio player..."
            audioPlayer.setCurrentFolderFiles = {
                files: audioFiles,
                currentIndex: currentIndex,
                folderId: m.top.currentFolderId
            }
            print "[SeedrHomeScene] ✅ Set up audio player with "; audioFiles.Count(); " audio files, current index: "; currentIndex
        else
            print "[SeedrHomeScene] ❌ ERROR: seedrAudioPlayer not found in parent"
        end if
    else
        print "[SeedrHomeScene] ❌ ERROR: Parent node is invalid"
    end if
end sub

' Show image file
sub showImageFile(fileItem as object)
    print "[SeedrHomeScene] Showing image: "; fileItem.title

    ' Signal parent scene to show image viewer
    parentNode = m.top.getParent()
    sceneFound = false
    maxLevels = 5
    currentLevel = 0

    while parentNode <> invalid and currentLevel < maxLevels
        if parentNode.subType() = "Scene" or parentNode.subType() = "HeroMainScene"
            sceneFound = true
            exit while
        end if
        parentNode = parentNode.getParent()
        currentLevel = currentLevel + 1
    end while

    if sceneFound and parentNode <> invalid then
        ' Prepare image data
        imageData = {
            title: fileItem.title,
            fileId: fileItem.fileId,
            fileData: fileItem.fileData,
            hdPosterUrl: fileItem.hdPosterUrl,
            HDPosterUrl: fileItem.HDPosterUrl
        }

        ' Signal parent to show image viewer using interface
        parentNode.showImageViewer = {
            imageData: imageData,
            source: "SeedrHomeScene"
        }
        print "[SeedrHomeScene] Signaled parent to show image viewer"
    else
        print "[SeedrHomeScene] ERROR: Could not find parent scene for image viewer"
    end if
end sub

' Show document file
sub showDocumentFile(fileItem as object)
    print "[SeedrHomeScene] Showing document: "; fileItem.title

    ' Signal parent scene to show document viewer
    parentNode = m.top.getParent()
    sceneFound = false
    maxLevels = 5
    currentLevel = 0

    while parentNode <> invalid and currentLevel < maxLevels
        if parentNode.subType() = "Scene" or parentNode.subType() = "HeroMainScene"
            sceneFound = true
            exit while
        end if
        parentNode = parentNode.getParent()
        currentLevel = currentLevel + 1
    end while

    if sceneFound and parentNode <> invalid then
        ' Prepare document data
        documentData = {
            title: fileItem.title,
            fileId: fileItem.fileId,
            fileData: fileItem.fileData
        }

        ' Signal parent to show document viewer using interface
        parentNode.showDocumentViewer = {
            documentData: documentData,
            source: "SeedrHomeScene"
        }
        print "[SeedrHomeScene] Signaled parent to show document viewer"
    else
        print "[SeedrHomeScene] ERROR: Could not find parent scene for document viewer"
    end if
end sub

' Show file information
sub showFileInfo(fileItem as object)
    print "[SeedrHomeScene] File info for: "; fileItem.title

    ' Could show a dialog with file details
    ' For now, just print to console
    if fileItem.fileData <> invalid then
        print "[SeedrHomeScene] File size: "; fileItem.fileData.size
        print "[SeedrHomeScene] File type: "; fileItem.fileData.type
    end if
end sub

' ********** NEW DETAIL SCREEN INTEGRATION - ADDITIVE ONLY **********

' Launch DetailScreen for a single video file
sub launchDetailScreenForFile(fileItem as object)
    print "[SeedrHomeScene] ================ LAUNCHING DETAIL SCREEN ================"
    print "[SeedrHomeScene] Launching DetailScreen for file: "; fileItem.title
    print "[SeedrHomeScene] File item keys: "; fileItem.keys()

    ' Create DetailScreen if it doesn't exist
    if m.detailScreen = invalid then
        print "[SeedrHomeScene] Creating new DetailScreen component..."
        m.detailScreen = CreateObject("roSGNode", "DetailScreen")
        if m.detailScreen = invalid
            print "[SeedrHomeScene] ERROR: Failed to create DetailScreen component!"
            return
        end if
        print "[SeedrHomeScene] DetailScreen created successfully"

        m.detailScreen.visible = false
        m.top.appendChild(m.detailScreen)

        ' Set up observers for DetailScreen
        print "[SeedrHomeScene] Setting up DetailScreen observers..."
        m.detailScreen.observeField("playPressed", "onDetailScreenPlayPressed")
        m.detailScreen.observeField("visible", "onDetailScreenVisibilityChanged")
        print "[SeedrHomeScene] DetailScreen observers set up"
    else
        print "[SeedrHomeScene] Using existing DetailScreen component"
    end if

    ' Create a content node containing just this file
    rowContent = CreateObject("roSGNode", "ContentNode")

    ' Create the video item content with proper fields for DetailScreen
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.title = fileItem.title

    ' Set up metadata for the DetailScreen
    if fileItem.fileData <> invalid then
        videoContent.size = fileItem.fileData.size
        if fileItem.fileData.type <> invalid then
            videoContent.streamformat = fileItem.fileData.type
        end if

        ' Use presentation URLs for poster if available
        if fileItem.fileData.presentation_urls <> invalid and type(fileItem.fileData.presentation_urls) = "roAssociativeArray" then
            if fileItem.fileData.presentation_urls.image <> invalid then
                imageUrls = fileItem.fileData.presentation_urls.image
                if type(imageUrls) = "roAssociativeArray" then
                    if imageUrls["720"] <> invalid then
                        videoContent.hdPosterUrl = imageUrls["720"]
                        videoContent.posterUrl = imageUrls["720"]
                    else if imageUrls["220"] <> invalid then
                        videoContent.hdPosterUrl = imageUrls["220"]
                        videoContent.posterUrl = imageUrls["220"]
                    end if
                end if
            end if
        end if
    end if

    ' Add description if available
    if fileItem.description <> invalid then
        videoContent.description = fileItem.description
    else
        videoContent.description = "Video file from Seedr"
    end if

    ' Store the original fileItem for playback
    videoContent.addFields({
        "url": fileItem.url,
        "fileId": fileItem.fileId,
        "originalFileItem": fileItem
    })

    ' Add the video content to the row
    rowContent.appendChild(videoContent)

    ' Set content and show DetailScreen
    m.detailScreen.content = rowContent
    m.detailScreen.selectedIndex = 0
    m.detailScreen.visible = true
    m.detailScreen.setFocus(true)

    print "[SeedrHomeScene] DetailScreen launched for: "; fileItem.title
end sub

' Handle play button press from DetailScreen - preserve existing play functionality
sub onDetailScreenPlayPressed()
    print "[SeedrHomeScene] DetailScreen play button pressed"

    if m.detailScreen <> invalid and m.detailScreen.content <> invalid then
        selectedIndex = m.detailScreen.selectedIndex
        row = m.detailScreen.content

        if selectedIndex >= 0 and selectedIndex < row.getChildCount() then
            selectedItem = row.getChild(selectedIndex)

            ' Get the original file item and route to appropriate handler
            if selectedItem.originalFileItem <> invalid then
                fileItem = selectedItem.originalFileItem
                fileType = ""
                if selectedItem.fileType <> invalid
                    fileType = selectedItem.fileType
                end if

                print "[SeedrHomeScene] Handling "; fileType; " file from DetailScreen: "; selectedItem.title

                ' Route to appropriate handler based on file type
                if fileType = "video"
                    playVideoFile(fileItem)
                else if fileType = "audio"
                    playAudioFile(fileItem)
                else if fileType = "image"
                    showImageFile(fileItem)
                else
                    showFileInfo(fileItem)
                end if

                ' Hide DetailScreen after starting action
                m.detailScreen.visible = false
            end if
        end if
    end if
end sub

' Handle DetailScreen visibility changes
sub onDetailScreenVisibilityChanged()
    print "[SeedrHomeScene] DetailScreen visibility changed to: "; m.detailScreen.visible

    if m.detailScreen <> invalid and m.detailScreen.visible = false then
        print "[SeedrHomeScene] DetailScreen closed, returning focus to list"

        ' Return focus to the row list
        m.row_list.setFocus(true)
        print "[SeedrHomeScene] Focus returned to row list"
    end if
end sub


' Initialize DetailScreen integration (call this from init)
sub initDetailScreenIntegration()
    print "[SeedrHomeScene] Initializing DetailScreen integration"

    ' Initialize DetailScreen reference
    m.detailScreen = invalid
end sub

' Initialize Screen Manager
sub initScreenManager()
    print "[SeedrHomeScene] Initializing Screen Manager"

    ' Create screen manager
    m.screenManager = CreateObject("roSGNode", "ScreenManager")
    m.top.appendChild(m.screenManager)

    print "[SeedrHomeScene] Screen Manager initialized"
end sub

' ********** FOLDER DETAIL SCREEN LOGIC - NEW **********

' Determine if folder contents should show DetailScreen
function shouldShowFolderDetailScreen(folderData as object) as boolean
    ' Show DetailScreen if folder contains media files (videos, images, audio)
    if folderData.files <> invalid and folderData.files.count() > 0
        for each file in folderData.files
            if isVideoFile(file.name) or isImageFile(file.name) or isAudioFile(file.name)
                print "[SeedrHomeScene] Folder contains media files, showing DetailScreen"
                return true
            end if
        end for
    end if

    ' For folders with only documents or subfolders, use traditional view
    print "[SeedrHomeScene] Folder contains no media files, using traditional view"
    return false
end function

' Show DetailScreen for folder contents
sub showFolderDetailScreen(folderData as object)
    print "[SeedrHomeScene] Showing FolderDetailsScreen for folder contents"

    ' Prepare folder data for the grid screen
    folderDataForGrid = {
        title: "Folder Contents",
        itemCount: 0,
        files: []
    }

    ' Convert folder data to format expected by FolderDetailsScreen
    if folderData.files <> invalid and folderData.files.count() > 0
        for each file in folderData.files
            if isVideoFile(file.name) or isImageFile(file.name) or isAudioFile(file.name)
                fileItem = {
                    title: file.name,
                    fileType: getFileType(file.name),
                    fileId: file.id.ToStr(),
                    fileData: file,
                    size: file.size,
                    fileSize: file.size
                }

                ' Set poster URL
                posterUrl = getImagePreviewUrl(file)
                if posterUrl <> ""
                    fileItem.hdPosterUrl = posterUrl
                    fileItem.HDPosterUrl = posterUrl
                else
                    ' Set default icon based on file type
                    if isVideoFile(file.name)
                        fileItem.hdPosterUrl = "pkg:/images/icon_focus_hd.png"
                    else if isAudioFile(file.name)
                        fileItem.hdPosterUrl = "pkg:/images/audio5.png"
                    else if isImageFile(file.name)
                        fileItem.hdPosterUrl = "pkg:/images/icon_focus_hd.png"
                    end if
                    fileItem.HDPosterUrl = fileItem.hdPosterUrl
                end if

                ' Set description
                if fileItem.fileType = "video"
                    fileItem.description = "Video file ready to play."
                else if fileItem.fileType = "audio"
                    fileItem.description = "Audio file ready to play."
                else if fileItem.fileType = "image"
                    fileItem.description = "Image file ready to view."
                end if

                folderDataForGrid.files.Push(fileItem)
            end if
        end for

        folderDataForGrid.itemCount = folderDataForGrid.files.count()
    end if

    if folderDataForGrid.files.count() > 0
        ' Signal parent scene to show FolderDetailsScreen
        parentNode = m.top.getParent()
        sceneFound = false
        maxLevels = 5
        currentLevel = 0

        while parentNode <> invalid and currentLevel < maxLevels
            if parentNode.subType() = "Scene" or parentNode.subType() = "HeroMainScene"
                sceneFound = true
                exit while
            end if
            parentNode = parentNode.getParent()
            currentLevel = currentLevel + 1
        end while

        if sceneFound and parentNode <> invalid then
            parentNode.showFolderDetails = folderDataForGrid
            print "[SeedrHomeScene] Signaled scene to show FolderDetailsScreen with "; folderDataForGrid.files.count(); " items"
        else
            print "[SeedrHomeScene] ERROR: Could not find parent scene for FolderDetailsScreen"
            displayFolderContents(folderData)
        end if
    else
        print "[SeedrHomeScene] No media files for FolderDetailsScreen, falling back to traditional view"
        displayFolderContents(folderData)
    end if
end sub

' Create content node from folder data
function createFolderContentNode(folderData as object) as object
    print "[SeedrHomeScene] Creating folder content node"

    folderContent = CreateObject("roSGNode", "ContentNode")

    if folderData.files <> invalid and folderData.files.count() > 0
        for each file in folderData.files
            ' Only add media files to DetailScreen content
            if isVideoFile(file.name) or isImageFile(file.name) or isAudioFile(file.name)
                contentItem = CreateObject("roSGNode", "ContentNode")
                contentItem.title = file.name

                ' Set background image URL using presentation URLs
                backgroundUrl = getFileBackgroundUrl(file)
                if backgroundUrl <> ""
                    contentItem.hdPosterUrl = backgroundUrl
                    contentItem.HDPosterUrl = backgroundUrl
                end if

                ' Store original file data for actions
                contentItem.addFields({
                    "originalFileItem": createFileItemFromData(file),
                    "fileType": getFileType(file.name),
                    "fileSize": file.size,
                    "url": file.url
                })

                ' Add description based on file type
                contentItem.description = getFileDescription(file)

                folderContent.appendChild(contentItem)
                print "[SeedrHomeScene] Added media file: "; file.name
            end if
        end for
    end if

    print "[SeedrHomeScene] Created folder content with "; folderContent.getChildCount(); " items"
    return folderContent
end function

' Get background URL for file using presentation URLs
function getFileBackgroundUrl(fileData as object) as string
    if fileData.presentation_urls <> invalid and type(fileData.presentation_urls) = "roAssociativeArray"
        if fileData.presentation_urls.image <> invalid then
            imageUrls = fileData.presentation_urls.image
            if type(imageUrls) = "roAssociativeArray" then
                ' Try to get highest quality image available
                if imageUrls["720"] <> invalid then
                    return imageUrls["720"]
                else if imageUrls["220"] <> invalid then
                    return imageUrls["220"]
                else if imageUrls["64"] <> invalid then
                    return imageUrls["64"]
                end if
            end if
        end if
    end if

    ' Fallback to thumb if available
    if fileData.thumb <> invalid then
        return fileData.thumb
    end if

    return ""
end function

' Create file item object from API data
function createFileItemFromData(fileData as object) as object
    fileItem = {
        title: fileData.name,
        url: fileData.url,
        fileId: fileData.id.toStr(),
        size: fileData.size,
        fileData: fileData
    }

    ' Add description if available
    if fileData.description <> invalid
        fileItem.description = fileData.description
    end if

    return fileItem
end function

' Get file type string
function getFileType(fileName as string) as string
    fileName = lcase(fileName)
    if isVideoFile(fileName) then return "video"
    if isImageFile(fileName) then return "image"
    if isAudioFile(fileName) then return "audio"
    if isDocumentFile(fileName) then return "document"
    return "other"
end function

' Get file description
function getFileDescription(fileData as object) as string
    fileType = getFileType(fileData.name)

    if fileType = "video"
        return "Video file"
    else if fileType = "image"
        return "Image file"
    else if fileType = "audio"
        return "Audio file"
    else if fileType = "document"
        return "Document file"
    else
        return "File"
    end if
end function

' Set up audio observers when visible
sub onVisibleForAudioObserver()
    if m.top.visible then
        audioPlayer = getAudioPlayer()
        if audioPlayer <> invalid then
            print "[SeedrHomeScene] Setting up audio state observers"
            audioPlayer.observeField("isGloballyPlaying", "onGlobalAudioStateChanged")
            audioPlayer.observeField("currentTrackInfo", "onCurrentTrackChanged")
            ' Update now playing display immediately
            updateNowPlayingDisplay()
        else
            print "[SeedrHomeScene] Audio player not available for observer setup"
        end if
    end if
end sub

' Handle global audio state changes
sub onGlobalAudioStateChanged()
    print "[SeedrHomeScene] Global audio state changed"
    updateNowPlayingDisplay()
end sub

' Handle current track changes
sub onCurrentTrackChanged()
    print "[SeedrHomeScene] Current track changed"
    updateNowPlayingDisplay()
end sub

' Timer handler to periodically check now playing status
sub onNowPlayingTimer()
    updateNowPlayingDisplay()
end sub

' Update the Now Playing tile display
sub updateNowPlayingDisplay()
    audioPlayer = getAudioPlayer()

    if audioPlayer <> invalid then
        isPlaying = audioPlayer.isGloballyPlaying
        trackInfo = audioPlayer.currentTrackInfo

        if trackInfo <> invalid then
            ' Show the now playing tile when there's track info (playing OR paused)
            m.nowPlayingTile.visible = true

            ' Update title (truncate if too long)
            title = trackInfo.title
            if title <> invalid then
                if Len(title) > 35 then
                    title = Left(title, 32) + "..."
                end if
                m.nowPlayingTitle.text = title
            else
                m.nowPlayingTitle.text = "Unknown Track"
            end if

            ' Update info line with track position and controls
            infoText = ""
            if trackInfo.currentIndex <> invalid and trackInfo.totalTracks <> invalid then
                infoText = "Track " + Str(trackInfo.currentIndex + 1) + " of " + Str(trackInfo.totalTracks)
            end if

            ' Add playback status - show PAUSED or PLAYING
            if trackInfo.isPaused = true then
                infoText = infoText + " • PAUSED"
            else if isPlaying then
                infoText = infoText + " • PLAYING"
            else
                infoText = infoText + " • STOPPED"
            end if

            ' Add control hints
            infoText = infoText + " • Next/Prev: #/*"

            m.nowPlayingInfo.text = infoText

            ' Only log when track changes, not every update
            if m.lastLoggedTrack <> title then
                print "[SeedrHomeScene] Now Playing: "; title
                m.lastLoggedTrack = title
            end if
        else
            ' Hide the now playing tile only when there's no track info at all
            if m.nowPlayingTile.visible = true then
                m.nowPlayingTile.visible = false
                print "[SeedrHomeScene] Now Playing tile hidden - no track info"
            end if
        end if
    else
        ' Hide the now playing tile if no audio player
        if m.nowPlayingTile <> invalid then
            m.nowPlayingTile.visible = false
        end if
    end if
end sub

' Helper function to safely send global audio commands
function sendGlobalAudioCommand(command as string) as boolean
    audioPlayer = getAudioPlayer()
    if audioPlayer <> invalid then
        print "[SeedrHomeScene] Sending global audio command: "; command
        audioPlayer.globalAudioCommand = command
        return true
    else
        print "[SeedrHomeScene] ERROR: Audio player not available for command: "; command
    end if
    return false
end function

' Helper function to safely get audio player reference
function getAudioPlayer() as object
    parentNode = m.top.getParent()

    if parentNode <> invalid then
        ' Try direct access first
        audioPlayer = parentNode.seedrAudioPlayer
        if audioPlayer <> invalid then
            return audioPlayer
        end if

        ' Try to find it by ID in parent
        audioPlayerById = parentNode.findNode("seedrAudioPlayer")
        if audioPlayerById <> invalid then
            return audioPlayerById
        end if

        ' Try to find it in the contentGroup (sibling components)
        contentGroup = parentNode.findNode("contentGroup")
        if contentGroup <> invalid then
            audioPlayerInContentGroup = contentGroup.findNode("seedrAudioPlayer")
            if audioPlayerInContentGroup <> invalid then
                return audioPlayerInContentGroup
            end if
        end if
    end if

    return invalid
end function

' Load subscription data from Seedr API
sub loadSubscriptionData()
    print "[SeedrHomeScene] Loading subscription data..."
    
    ' Get auth credentials
    credentials = loadCredentials()
    
    if credentials = invalid or credentials.access_token = "" then
        print "[SeedrHomeScene] No credentials found for subscription data"
        displayDefaultSubscriptionInfo("Not logged in")
        return
    end if
    
    print "[SeedrHomeScene] Access token found, sending request..."
    
    ' Use the existing ApiTask to fetch user data
    m.apiTask.request = {
        method: "get_user"
        accessToken: credentials.accessToken
    }
    m.apiTask.control = "RUN"
    
    print "[SeedrHomeScene] Subscription data request sent via ApiTask"
end sub

' Display subscription information from API response
sub displaySubscriptionInfo(json as object)
    print "[SeedrHomeScene] displaySubscriptionInfo called"
    
    if json = invalid then
        print "[SeedrHomeScene] ERROR: JSON is invalid"
        displayDefaultSubscriptionInfo("Invalid response")
        return
    end if
    
    print "[SeedrHomeScene] JSON keys: "; json.keys()
    
    ' Display email
    if json.profile <> invalid and json.profile.email <> invalid then
        if m.subUserEmail <> invalid then 
            m.subUserEmail.text = "Account: " + json.profile.email
            print "[SeedrHomeScene] Set email: " + json.profile.email
        end if
    end if
    
    ' Display premium status
    isPremium = false
    if json.account <> invalid and json.account.is_premium <> invalid then
        isPremium = json.account.is_premium
        premiumText = "false"
        if isPremium then premiumText = "true"
        print "[SeedrHomeScene] Premium status: " + premiumText
    end if
    
    if isPremium then
        if m.subPremiumStatusLabel <> invalid then m.subPremiumStatusLabel.text = "Premium"
        if m.subPremiumBadge <> invalid then m.subPremiumBadge.color = "0x1DB954FF"
        print "[SeedrHomeScene] Set premium badge to green"
    else
        if m.subPremiumStatusLabel <> invalid then m.subPremiumStatusLabel.text = "Free"
        if m.subPremiumBadge <> invalid then m.subPremiumBadge.color = "0x888888FF"
        print "[SeedrHomeScene] Set premium badge to gray"
    end if
    
    ' Display storage info
    if json.account <> invalid and json.account.storage <> invalid then
        storage = json.account.storage
        
        print "[SeedrHomeScene] Storage used: " + str(storage.used)
        print "[SeedrHomeScene] Storage limit: " + str(storage.limit)
        
        usedGB = formatBytesToGB(storage.used)
        limitGB = formatBytesToGB(storage.limit)
        
        if m.subStorageUsed <> invalid then m.subStorageUsed.text = "Used: " + usedGB
        if m.subStorageLimit <> invalid then m.subStorageLimit.text = "Total: " + limitGB
        
        print "[SeedrHomeScene] Formatted storage: " + usedGB + " / " + limitGB
        
        ' Calculate and display percentage - Force float division
        if storage.limit > 0 then
            ' Convert to float by multiplying by 1.0 to prevent integer division
            usedFloat = storage.used * 1.0
            limitFloat = storage.limit * 1.0
            percentage = usedFloat / limitFloat
            percentageInt = int(percentage * 100)
            
            print "[SeedrHomeScene] DEBUG CALCULATION:"
            print "[SeedrHomeScene]   Used (raw): " + str(storage.used)
            print "[SeedrHomeScene]   Limit (raw): " + str(storage.limit)
            print "[SeedrHomeScene]   Used (float): " + str(usedFloat)
            print "[SeedrHomeScene]   Limit (float): " + str(limitFloat)
            print "[SeedrHomeScene]   Percentage (float): " + str(percentage)
            print "[SeedrHomeScene]   Percentage (int): " + str(percentageInt) + "%"
            
            ' Update percentage label
            if m.subStoragePercentage <> invalid then 
                m.subStoragePercentage.text = "(" + str(percentageInt) + "%)"
                
                ' Color code the percentage
                if percentage > 0.9 then
                    m.subStoragePercentage.color = "0xFF0000FF" ' Red
                else if percentage > 0.7 then
                    m.subStoragePercentage.color = "0xFFA500FF" ' Orange
                else
                    m.subStoragePercentage.color = "0x1DB954FF" ' Green
                end if
            end if
            
            ' Update progress bar (930px wide) - Scale up small percentages for visibility
            if m.subStorageBarFill <> invalid then
                ' For small percentages (< 10%), scale them up so they're visible
                ' This makes 5% show as ~10% on screen (more visible)
                visualPercentage = percentage
                if percentage < 0.10 and percentage > 0 then
                    ' Scale up: 5% becomes 10%, 1% becomes 5%, etc
                    visualPercentage = percentage * 2
                    if visualPercentage > 0.15 then visualPercentage = 0.15 ' Cap at 15%
                end if
                
                barWidth = int(930 * visualPercentage)
                if barWidth > 930 then barWidth = 930
                if barWidth < 50 and percentage > 0 then barWidth = 50 ' Minimum 50px for any usage (very visible!)
                m.subStorageBarFill.width = barWidth
                
                print "[SeedrHomeScene] ========================================="
                print "[SeedrHomeScene] STORAGE BAR UPDATE:"
                print "[SeedrHomeScene] Real percentage: " + str(percentage) + " (" + str(percentageInt) + "%)"
                print "[SeedrHomeScene] Visual percentage: " + str(visualPercentage) + " (scaled for visibility)"
                print "[SeedrHomeScene] Bar width set to: " + str(barWidth) + "px out of 930px"
                print "[SeedrHomeScene] Used: " + str(storage.used) + " bytes"
                print "[SeedrHomeScene] Limit: " + str(storage.limit) + " bytes"
                print "[SeedrHomeScene] ========================================="
                
                ' Change bar color based on REAL usage (not visual)
                if percentage > 0.9 then
                    m.subStorageBarFill.color = "0xFF0000FF" ' Red
                else if percentage > 0.7 then
                    m.subStorageBarFill.color = "0xFFA500FF" ' Orange
                else
                    m.subStorageBarFill.color = "0x1DB954FF" ' Green
                end if
            end if
        end if
    end if
    
    ' Display features
    if json.account <> invalid and json.account.features <> invalid then
        features = json.account.features
        
        if features.max_torrents <> invalid and m.subMaxTorrents <> invalid then
            m.subMaxTorrents.text = "Max Torrents: " + str(features.max_torrents)
            print "[SeedrHomeScene] Max torrents: " + str(features.max_torrents)
        end if
        
        if features.active_torrents <> invalid and m.subActiveTorrents <> invalid then
            m.subActiveTorrents.text = "Active: " + str(features.active_torrents)
            print "[SeedrHomeScene] Active torrents: " + str(features.active_torrents)
        end if
        
        if features.concurrent_downloads <> invalid and m.subConcurrentDownloads <> invalid then
            ' Handle both string ("unlimited") and numeric values
            if type(features.concurrent_downloads) = "roString" or type(features.concurrent_downloads) = "String" then
                downloadsText = features.concurrent_downloads
            else
                downloadsText = str(features.concurrent_downloads)
            end if
            m.subConcurrentDownloads.text = "Concurrent Downloads: " + downloadsText
            print "[SeedrHomeScene] Concurrent downloads: " + downloadsText
        end if
    end if
    
    print "[SeedrHomeScene] ✅ Subscription info displayed successfully"
end sub

' Display default subscription info (when not logged in or error)
sub displayDefaultSubscriptionInfo(message as string)
    if m.subUserEmail <> invalid then m.subUserEmail.text = message
    if m.subPremiumStatusLabel <> invalid then m.subPremiumStatusLabel.text = "Free"
    if m.subPremiumBadge <> invalid then m.subPremiumBadge.color = "0x888888FF"
    if m.subStorageUsed <> invalid then m.subStorageUsed.text = "Used: 0 GB"
    if m.subStorageLimit <> invalid then m.subStorageLimit.text = "Total: 0 GB"
    if m.subStoragePercentage <> invalid then m.subStoragePercentage.text = "(0%)"
    if m.subStorageBarFill <> invalid then m.subStorageBarFill.width = 0
    if m.subMaxTorrents <> invalid then m.subMaxTorrents.text = "Max Torrents: 0"
    if m.subActiveTorrents <> invalid then m.subActiveTorrents.text = "Active: 0"
    if m.subConcurrentDownloads <> invalid then m.subConcurrentDownloads.text = "Concurrent Downloads: unlimited"
end sub

' Format bytes to GB string
function formatBytesToGB(bytes as longinteger) as string
    if bytes < 1024 then
        return str(bytes) + " B"
    else if bytes < 1048576 then ' 1024 * 1024
        return str(int(bytes / 1024)) + " KB"
    else if bytes < 1073741824 then ' 1024 * 1024 * 1024
        mb = bytes / 1048576
        return str(int(mb * 100) / 100) + " MB"
    else
        gb = bytes / 1073741824
        return str(int(gb * 100) / 100) + " GB"
    end if
end function

' Handle logout
sub handleLogout()
    print "[SeedrHomeScene] Logging out..."
    
    ' Show confirmation dialog
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Logout"
    dialog.message = ["Are you sure you want to logout?"]
    dialog.buttons = ["Yes", "Cancel"]
    dialog.observeField("buttonSelected", "onLogoutConfirm")
    
    ' Store dialog reference
    m.logoutDialog = dialog
    
    ' Show dialog
    m.top.getScene().dialog = dialog
end sub

' Handle logout confirmation
sub onLogoutConfirm(event as object)
    dialog = event.getRoSGNode()
    buttonIndex = dialog.buttonSelected
    
    ' Close dialog
    m.top.getScene().dialog = invalid
    
    if buttonIndex = 0 then ' Yes button
        print "[SeedrHomeScene] User confirmed logout - clearing credentials"
        
        ' Clear credentials (global function from source/auth.brs)
        clearCredentials()
        
        ' Show success message
        successDialog = CreateObject("roSGNode", "StandardMessageDialog")
        successDialog.title = "Logged Out"
        successDialog.message = ["You have been logged out successfully."]
        successDialog.buttons = ["OK"]
        successDialog.observeField("buttonSelected", "onLogoutComplete")
        m.top.getScene().dialog = successDialog
    else
        print "[SeedrHomeScene] Logout cancelled"
    end if
end sub

' Handle logout completion - restart app or show auth screen
sub onLogoutComplete()
    ' Close dialog
    m.top.getScene().dialog = invalid
    
    print "[SeedrHomeScene] Logout complete - signaling auth screen"
    
    ' Signal parent scene to show auth screen
    scene = m.top.getScene()
    if scene <> invalid then
        scene.showAuthScreen = true
    end if
end sub
