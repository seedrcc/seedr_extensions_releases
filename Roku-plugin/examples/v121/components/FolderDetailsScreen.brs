' ********** Folder Details Screen with Grid Layout **********

sub Init()
    print "[FolderDetailsScreen] ==================== INITIALIZING ===================="
    print "[FolderDetailsScreen] Starting FolderDetailsScreen initialization..."

    ' Get UI elements (based on videos Grid)
    m.rowList = m.top.FindNode("rowList")
    m.descriptionLabel = m.top.FindNode("descriptionLabel")
    m.poster = m.top.FindNode("poster")
    m.fileTypeLabel = m.top.FindNode("fileTypeLabel")
    m.folderInfoLabel = m.top.FindNode("folderInfoLabel")
    m.fileSizeLabel = m.top.FindNode("fileSizeLabel")
    m.titleLabel = m.top.FindNode("titleLabel")

    ' Background elements for dynamic effect
    m.backgroundPoster = m.top.findNode("backgroundPoster")
    m.backgroundPosterSecondary = m.top.findNode("backgroundPosterSecondary")

    ' Set up observers
    m.top.ObserveField("visible", "OnVisibleChange")
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
    m.rowList.ObserveField("rowItemSelected", "OnItemSelected")
    m.top.ObserveField("folderData", "OnFolderDataChanged")

    ' Initialize state
    m.isTransitioning = false
    m.currentItem = invalid

    ' Set initial focus
    m.rowList.SetFocus(true)

    print "[FolderDetailsScreen] Initialization complete"
    print "[FolderDetailsScreen] ============================================================="
end sub

sub OnVisibleChange()
    print "[FolderDetailsScreen] ==================== VISIBILITY CHANGED ===================="
    print "[FolderDetailsScreen] 🔄 FOLDER DETAILS SCREEN VISIBILITY CHANGED"
    print "[FolderDetailsScreen] Current time: "; CreateObject("roDateTime").AsSeconds()
    print "[FolderDetailsScreen] Visibility changed to: "; m.top.visible

    if m.top.visible = true
        print "[FolderDetailsScreen] 🟢 Screen became VISIBLE - setting focus to grid"
        m.rowList.SetFocus(true)
    else
        print "[FolderDetailsScreen] 🔴 Screen became HIDDEN"
    end if
    print "[FolderDetailsScreen] ============================================================="
end sub

sub OnFolderDataChanged()
    print "[FolderDetailsScreen] ==================== FOLDER DATA CHANGED ===================="
    folderData = m.top.folderData
    if folderData <> invalid
        print "[FolderDetailsScreen] Setting up folder: "; folderData.title

        ' Create content for the grid
        createFolderContent(folderData)

        ' Set folder info
        if folderData.itemCount <> invalid
            m.folderInfoLabel.text = folderData.itemCount.toStr() + " items"
        end if
    end if
    print "[FolderDetailsScreen] ============================================================="
end sub

sub createFolderContent(folderData as object)
    print "[FolderDetailsScreen] Creating folder content for grid display"

    if folderData.files = invalid or folderData.files.count() = 0
        print "[FolderDetailsScreen] No files to display"
        return
    end if

    ' Create main content node
    contentNode = CreateObject("roSGNode", "ContentNode")

    ' Create a single row for all files
    rowNode = contentNode.createChild("ContentNode")
    rowNode.title = "Files"

    ' Add each file as an item in the row
    for each file in folderData.files
        if file.fileType = "video" or file.fileType = "audio" or file.fileType = "image"
            fileNode = rowNode.createChild("ContentNode")
            fileNode.title = file.title
            ' Set standard ContentNode fields
            fileNode.hdPosterUrl = file.hdPosterUrl
            fileNode.HDPosterUrl = file.HDPosterUrl
            fileNode.description = file.description

            ' Add custom fields using addFields() method to avoid warnings
            fileNode.addFields({
                "fileType": file.fileType,
                "fileId": file.fileId,
                "size": file.size,
                "fileSize": file.fileSize,
                "fileData": file
            })

            ' Add file type info
            if file.fileType = "video"
                fileNode.addFields({ "quality": "VIDEO" })
            else if file.fileType = "audio"
                fileNode.addFields({ "quality": "AUDIO" })
            else if file.fileType = "image"
                fileNode.addFields({ "quality": "IMAGE" })
            else
                fileNode.addFields({ "quality": "FILE" })
            end if

            print "[FolderDetailsScreen] Added file: "; file.title; " ("; file.fileType; ")"
        end if
    end for

    ' Set content to rowList
    m.top.content = contentNode

    print "[FolderDetailsScreen] Folder content created with "; rowNode.getChildCount(); " items"
end sub

sub OnItemFocused()
    print "[FolderDetailsScreen] ==================== ITEM FOCUSED ===================="
    focusedIndex = m.rowList.rowItemFocused

    if focusedIndex <> invalid and focusedIndex.count() >= 2
        print "[FolderDetailsScreen] Item focused: ["; focusedIndex[0]; ", "; focusedIndex[1]; "]"

        ' Get the focused item
        row = m.rowList.content.GetChild(focusedIndex[0])
        item = row.GetChild(focusedIndex[1])

        if item <> invalid
            m.currentItem = item

            ' Update display info (based on videos Grid)
            m.poster.uri = item.hdPosterUrl
            m.descriptionLabel.text = getItemDescription(item)
            m.titleLabel.text = item.title
            m.fileTypeLabel.text = item.quality

            ' Update file size
            if item.fileSize <> invalid and item.fileSize > 0
                m.fileSizeLabel.text = formatFileSize(item.fileSize)
            else if item.size <> invalid and item.size > 0
                m.fileSizeLabel.text = formatFileSize(item.size)
            else
                m.fileSizeLabel.text = ""
            end if

            ' Update background
            updateBackgroundWithTransition()

            print "[FolderDetailsScreen] Updated display for: "; item.title
        end if
    end if
    print "[FolderDetailsScreen] ============================================================="
end sub

sub OnItemSelected()
    print "[FolderDetailsScreen] ==================== ITEM SELECTED ===================="
    selectedIndex = m.rowList.rowItemSelected

    if selectedIndex <> invalid and selectedIndex.count() >= 2
        print "[FolderDetailsScreen] Item selected: ["; selectedIndex[0]; ", "; selectedIndex[1]; "]"

        ' Get the selected item
        row = m.rowList.content.GetChild(selectedIndex[0])
        item = row.GetChild(selectedIndex[1])

        if item <> invalid
            print "[FolderDetailsScreen] Selected item: "; item.title; " ("; item.fileType; ")"

            ' Handle different file types
            if item.fileType = "video" or item.fileType = "audio"
                print "[FolderDetailsScreen] Playing media file: "; item.title

                ' Set selected item and trigger play
                m.top.selectedItem = item
                m.top.playPressed = true

            else if item.fileType = "image"
                print "[FolderDetailsScreen] Viewing image file: "; item.title
                ' TODO: Implement image viewing

            else
                print "[FolderDetailsScreen] Opening file: "; item.title
                ' TODO: Implement file opening
            end if
        end if
    end if
    print "[FolderDetailsScreen] ============================================================="
end sub

function getItemDescription(item as object) as string
    if item.description <> invalid and item.description <> ""
        return item.description
    else
        ' Generate description based on file type
        fileType = ""
        if item.fileType <> invalid
            fileType = item.fileType
        end if

        if fileType = "video"
            return "Video file ready to play. Select to start playback."
        else if fileType = "audio"
            return "Audio file ready to play. Select to start playback."
        else if fileType = "image"
            return "Image file ready to view. Select to open."
        else
            return "File ready to open. Select to view contents."
        end if
    end if
end function

function formatFileSize(sizeInBytes as longinteger) as string
    if sizeInBytes > 1073741824 ' > 1GB
        sizeGB = sizeInBytes / 1073741824.0
        return formatFloat(sizeGB, 1) + " GB"
    else if sizeInBytes > 1048576 ' > 1MB
        sizeMB = sizeInBytes / 1048576
        return int(sizeMB).toStr() + " MB"
    else if sizeInBytes > 1024 ' > 1KB
        sizeKB = sizeInBytes / 1024
        return int(sizeKB).toStr() + " KB"
    else
        return sizeInBytes.toStr() + " B"
    end if
end function

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
        print "[FolderDetailsScreen] Transitioning background to: "; newBackgroundUri
        performBackgroundTransition(newBackgroundUri)
    end if
end sub

' Perform smooth background transition
sub performBackgroundTransition(newUri as string)
    if m.backgroundPoster = invalid or m.backgroundPosterSecondary = invalid then return

    m.isTransitioning = true

    ' Set new image to secondary poster
    m.backgroundPosterSecondary.uri = newUri

    ' Create fade transition
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
        print "[FolderDetailsScreen] Background transition complete"
    end if
end sub

' Handle key events
function onKeyEvent(key as string, press as boolean) as boolean
    handled = false

    if press
        if key = "back"
            print "[FolderDetailsScreen] ==================== BACK KEY PRESSED ===================="
            print "[FolderDetailsScreen] 🔴 BACK BUTTON CLICKED FROM FOLDER DETAILS SCREEN"
            print "[FolderDetailsScreen] Current visibility before back: "; m.top.visible
            print "[FolderDetailsScreen] Current time: "; CreateObject("roDateTime").AsSeconds()
            print "[FolderDetailsScreen] Starting back navigation process..."

            ' Direct navigation back to parent scene
            parentNode = m.top.getParent()
            sceneFound = false
            maxLevels = 5
            currentLevel = 0
            print "[FolderDetailsScreen] Searching for parent scene..."

            while parentNode <> invalid and currentLevel < maxLevels
                print "[FolderDetailsScreen] Level "; currentLevel; ": "; parentNode.subType()
                if parentNode.subType() = "Scene" or parentNode.subType() = "HeroMainScene"
                    sceneFound = true
                    print "[FolderDetailsScreen] Found parent scene: "; parentNode.subType()
                    exit while
                end if
                parentNode = parentNode.getParent()
                currentLevel = currentLevel + 1
            end while

            if sceneFound and parentNode <> invalid then
                print "[FolderDetailsScreen] SUCCESS: Found parent scene, proceeding with back navigation"
                print "[FolderDetailsScreen] Parent scene type: "; parentNode.subType()

                ' Set flag to prevent auto-restoration in SeedrHomeScene
                print "[FolderDetailsScreen] Accessing SeedrHomeScene from HeroMainScene..."
                seedrHomeScene = parentNode.findNode("seedrHomeScene")
                if seedrHomeScene <> invalid then
                    print "[FolderDetailsScreen] Found SeedrHomeScene, setting skipAutoRestore flag"
                    print "[FolderDetailsScreen] SeedrHomeScene skipAutoRestore BEFORE: "; seedrHomeScene.skipAutoRestore
                    seedrHomeScene.skipAutoRestore = true
                    print "[FolderDetailsScreen] SeedrHomeScene skipAutoRestore AFTER: "; seedrHomeScene.skipAutoRestore
                    print "[FolderDetailsScreen] SeedrHomeScene current visibility: "; seedrHomeScene.visible
                else
                    print "[FolderDetailsScreen] WARNING: Could not find SeedrHomeScene node"
                end if

                ' Hide this screen first
                print "[FolderDetailsScreen] Hiding FolderDetailsScreen..."
                m.top.visible = false
                print "[FolderDetailsScreen] FolderDetailsScreen visibility set to: "; m.top.visible

                ' Show home scene directly and clear folder state
                if seedrHomeScene <> invalid then
                    print "[FolderDetailsScreen] Showing SeedrHomeScene and clearing folder state..."

                    ' IMPORTANT: Clear current folder ID to prevent re-navigation
                    seedrHomeScene.currentFolderId = ""
                    print "[FolderDetailsScreen] Cleared currentFolderId to prevent folder reload"

                    seedrHomeScene.visible = true
                    seedrHomeScene.setFocus(true)
                    print "[FolderDetailsScreen] SeedrHomeScene visibility set to: "; seedrHomeScene.visible
                else
                    print "[FolderDetailsScreen] ERROR: SeedrHomeScene not found for showing"
                end if

                print "[FolderDetailsScreen] Back navigation completed successfully"
            else
                print "[FolderDetailsScreen] ERROR: Could not find parent scene, using fallback"
                m.top.visible = false
                print "[FolderDetailsScreen] Fallback: Set visibility to false"
            end if

            print "[FolderDetailsScreen] ============================================================="
            handled = true

        else if key = "OK"
            print "[FolderDetailsScreen] OK key pressed - attempting to play selected item"

            ' Get the currently focused item from the RowList
            focusedItem = getCurrentlyFocusedItem()
            if focusedItem <> invalid
                print "[FolderDetailsScreen] Playing item: "; focusedItem.title
                print "[FolderDetailsScreen] Item type: "; focusedItem.fileType

                ' Direct playback integration
                if focusedItem.fileType = "video" then
                    print "[FolderDetailsScreen] Starting video playback"
                    playVideoFile(focusedItem)
                    handled = true
                else if focusedItem.fileType = "audio" then
                    print "[FolderDetailsScreen] Starting audio playback"
                    playAudioFile(focusedItem)
                    handled = true
                else
                    print "[FolderDetailsScreen] File type not supported for playback: "; focusedItem.fileType
                end if
            else
                print "[FolderDetailsScreen] ERROR: No focused item found for playback"
            end if
        end if
    end if

    return handled
end function

' Get the currently focused item from the RowList
function getCurrentlyFocusedItem() as object
    if m.rowList <> invalid and m.rowList.content <> invalid
        ' Get the focused row and item indices
        focusedRow = 0 ' We only have one row in our grid
        focusedItemIndex = m.rowList.itemFocused[1]

        print "[FolderDetailsScreen] Getting focused item - Row: "; focusedRow; ", Item: "; focusedItemIndex

        ' Get the row content
        rowContent = m.rowList.content.getChild(focusedRow)
        if rowContent <> invalid and focusedItemIndex >= 0 and focusedItemIndex < rowContent.getChildCount()
            focusedItem = rowContent.getChild(focusedItemIndex)
            print "[FolderDetailsScreen] Found focused item: "; focusedItem.title
            print "[FolderDetailsScreen] Item keys: "; focusedItem.keys()

            ' Get the file data from our stored folder data
            if m.folderData <> invalid and m.folderData.files <> invalid and focusedItemIndex < m.folderData.files.count()
                fileData = m.folderData.files[focusedItemIndex]
                print "[FolderDetailsScreen] Using stored file data: "; fileData.title

                ' Return the complete file data
                return fileData
            else
                print "[FolderDetailsScreen] ERROR: Could not find file data for index: "; focusedItemIndex
            end if
        else
            print "[FolderDetailsScreen] ERROR: Invalid row content or item index"
        end if
    else
        print "[FolderDetailsScreen] ERROR: RowList or content is invalid"
    end if

    return invalid
end function

' Play video file directly
sub playVideoFile(fileItem as object)
    print "[FolderDetailsScreen] Playing video: "; fileItem.title

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
        print "[FolderDetailsScreen] ==================== VIDEO PLAYBACK ===================="
        print "[FolderDetailsScreen] Parent scene found: "; parentNode.subType()
        print "[FolderDetailsScreen] Current FolderDetailsScreen visibility: "; m.top.visible

        ' Ensure all screens are properly hidden first
        print "[FolderDetailsScreen] STEP 1: Hiding FolderDetailsScreen (this screen)"
        m.top.visible = false
        print "[FolderDetailsScreen] FolderDetailsScreen visibility set to: "; m.top.visible

        if parentNode.folderDetailsScreen <> invalid then
            print "[FolderDetailsScreen] STEP 2: Hiding parent's FolderDetailsScreen reference"
            parentNode.folderDetailsScreen.visible = false
            print "[FolderDetailsScreen] Parent FolderDetailsScreen visibility set to: "; parentNode.folderDetailsScreen.visible
        else
            print "[FolderDetailsScreen] WARNING: Parent FolderDetailsScreen reference not found"
        end if

        ' Hide SeedrHomeScene to prevent overlay
        seedrHomeScene = parentNode.findNode("seedrHomeScene")
        if seedrHomeScene <> invalid then
            print "[FolderDetailsScreen] STEP 3: Hiding SeedrHomeScene to prevent overlay"
            seedrHomeScene.visible = false
            print "[FolderDetailsScreen] SeedrHomeScene visibility set to: "; seedrHomeScene.visible
        else
            print "[FolderDetailsScreen] WARNING: SeedrHomeScene not found in parent"
        end if

        ' Signal video playback
        print "[FolderDetailsScreen] STEP 4: Signaling video playback to parent scene"
        parentNode.playVideo = {
            fileId: fileItem.fileId,
            title: fileItem.title,
            fileData: fileItem.fileData,
            isAudio: false
        }
        print "[FolderDetailsScreen] Video playback signal sent for: "; fileItem.title
        print "[FolderDetailsScreen] FileId: "; fileItem.fileId
        print "[FolderDetailsScreen] ============================================================="
    else
        print "[FolderDetailsScreen] ERROR: Could not find parent scene for video playback"
    end if
end sub

' Play audio file directly
sub playAudioFile(fileItem as object)
    print "[FolderDetailsScreen] Playing audio: "; fileItem.title

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
        print "[FolderDetailsScreen] Hiding FolderDetailsScreen and starting audio playback"

        ' Ensure all screens are properly hidden first
        m.top.visible = false
        if parentNode.folderDetailsScreen <> invalid then
            parentNode.folderDetailsScreen.visible = false
        end if

        ' Signal audio playback with folder data for playlist
        parentNode.playVideo = {
            fileId: fileItem.fileId,
            title: fileItem.title,
            fileData: fileItem.fileData,
            isAudio: true,
            folderData: m.folderData, ' Pass folder data for playlist setup
            currentFileItem: fileItem ' Pass current file for index calculation
        }
        print "[FolderDetailsScreen] Signaled audio playback for: "; fileItem.title
        print "[FolderDetailsScreen] Folder data passed to HeroMainScene for playlist setup"
    else
        print "[FolderDetailsScreen] ERROR: Could not find parent scene for audio playback"
    end if
end sub


' Set up audio playlist for auto-next functionality
sub setupAudioPlaylist(currentFileItem as object, parentNode as object)
    print "[FolderDetailsScreen] ===== SETTING UP AUDIO PLAYLIST ====="
    print "[FolderDetailsScreen] Current file: "; currentFileItem.title

    ' Get all audio files from current folder data
    audioFiles = []
    if m.folderData <> invalid and m.folderData.files <> invalid then
        print "[FolderDetailsScreen] Total files in folder: "; m.folderData.files.count()
        for each file in m.folderData.files
            if file <> invalid and file.title <> invalid then
                if isAudioFile(file.title) then
                    audioFiles.Push(file)
                    print "[FolderDetailsScreen] Added to playlist: "; file.title
                end if
            end if
        end for
    else
        print "[FolderDetailsScreen] ERROR: No folder data available for playlist"
    end if

    ' Find current file index in playlist
    currentIndex = 0
    for i = 0 to audioFiles.Count() - 1
        if audioFiles[i].fileId = currentFileItem.fileId then
            currentIndex = i
            exit for
        end if
    end for

    print "[FolderDetailsScreen] Playlist created: "; audioFiles.Count(); " files, current index: "; currentIndex

    ' Send playlist to audio player
    if parentNode <> invalid then
        audioPlayer = parentNode.findNode("seedrAudioPlayer")
        if audioPlayer <> invalid then
            audioPlayer.setCurrentFolderFiles = {
                files: audioFiles,
                currentIndex: currentIndex,
                folderId: m.folderData.id
            }
            print "[FolderDetailsScreen] SUCCESS: Successfully sent playlist to audio player"
        else
            print "[FolderDetailsScreen] ERROR: seedrAudioPlayer not found"
        end if
    else
        print "[FolderDetailsScreen] ERROR: parentNode is invalid"
    end if
    print "[FolderDetailsScreen] ========================================="
end sub

' Helper function to check if file is audio
function isAudioFile(filename as string) as boolean
    if filename = invalid then return false

    lowerName = LCase(filename)
    audioExtensions = [".mp3", ".flac", ".wav", ".m4a", ".aac", ".ogg", ".wma"]

    for each ext in audioExtensions
        if lowerName.EndsWith(ext) then
            return true
        end if
    end for

    return false
end function

' Helper function to format float values
function formatFloat(value as float, decimals as integer) as string
    multiplier = 10 ^ decimals
    rounded = int(value * multiplier + 0.5)
    result = (rounded / multiplier).toStr()
    return result
end function
