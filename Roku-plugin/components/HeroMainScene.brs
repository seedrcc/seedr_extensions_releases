' ********** Seedr for Roku - Hero Main Scene Logic **********

sub init()
    ' Initialize global subscription state first
    initGlobalSubscriptionState()

    ' Get references to UI components
    m.authScreen = m.top.findNode("authScreen")
    m.deviceAuthScreen = m.top.findNode("deviceAuthScreen")
    m.seedrHomeScene = m.top.findNode("seedrHomeScene")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.audioPlayer = m.top.findNode("audioPlayer")
    m.seedrAudioPlayer = m.top.findNode("seedrAudioPlayer")
    m.folderDetailsScreen = m.top.findNode("folderDetailsScreen")
    m.loadingIndicator = m.top.findNode("loadingIndicator")
    m.errorDialog = m.top.findNode("errorDialog")
    m.warningDialog = m.top.findNode("warningDialog")
    m.background = m.top.findNode("background")
    m.fadeIn = m.top.findNode("fadeIn")
    m.fadeOut = m.top.findNode("fadeOut")

    ' Get references to Roku Pay components
    m.purchaseHandler = m.top.findNode("purchaseHandler")
    m.subscriptionScreen = m.top.findNode("subscriptionScreen")

    ' Set up dynamic screen sizing
    setupScreenSize()

    ' Set up observers
    print "[HeroMainScene] Setting up observers..."
    m.top.observeField("authComplete", "onAuthComplete")
    m.top.observeField("playVideo", "onPlayVideo")
    m.top.observeField("playNextFile", "onPlayNextFile")
    m.top.observeField("content", "onChangeContent")
    m.top.observeField("navigateToFolder", "onNavigateToFolder")
    m.top.observeField("rowItemSelected", "onRowItemSelected")
    m.top.observeField("showFolderDetails", "onShowFolderDetails")
    m.top.observeField("showImageViewer", "onShowImageViewer")
    m.top.observeField("showDocumentViewer", "onShowDocumentViewer")

    ' Create stream URL task
    m.streamUrlTask = CreateObject("roSGNode", "StreamUrlTask")
    m.streamUrlTask.observeField("streamUrl", "onStreamUrlReceived")
    m.streamUrlTask.observeField("error", "onStreamUrlError")

    ' Set up player observers
    m.audioPlayer.observeField("onBackPressed", "onAudioPlayerBack")
    m.seedrAudioPlayer.observeField("onBackPressed", "onSeedrAudioPlayerBack")
    m.seedrAudioPlayer.observeField("isGloballyPlaying", "onGlobalAudioStateChanged")
    m.seedrAudioPlayer.observeField("currentTrackInfo", "onCurrentTrackChanged")

    ' Set up FolderDetailsScreen observers - DISABLED visibility observer to prevent conflicts
    ' m.folderDetailsScreen.observeField("visible", "onFolderDetailsVisibilityChanged")
    m.folderDetailsScreen.observeField("playPressed", "onFolderDetailsPlayPressed")

    ' Set up viewer observers
    m.imageViewer = m.top.findNode("imageViewer")
    m.documentViewer = m.top.findNode("documentViewer")
    m.imageViewer.observeField("onBackPressed", "onImageViewerBack")
    m.documentViewer.observeField("onBackPressed", "onDocumentViewerBack")

    ' Set up AuthScreen and DeviceAuthScreen observers
    m.authScreen.observeField("showDeviceAuth", "onShowDeviceAuth")
    m.deviceAuthScreen.observeField("authComplete", "onDeviceAuthComplete")
    m.deviceAuthScreen.observeField("backPressed", "onDeviceAuthBack")

    ' Set up Purchase Handler observers
    m.purchaseHandler.observeField("catalogReady", "onCatalogReady")
    m.purchaseHandler.observeField("purchasesReady", "onPurchasesReady")
    m.purchaseHandler.observeField("subscriptionStatus", "onSubscriptionStatusChanged")
    m.purchaseHandler.observeField("orderComplete", "onOrderComplete")
    m.purchaseHandler.observeField("error", "onPurchaseError")

    ' Set up Subscription Screen observers
    m.subscriptionScreen.observeField("productSelected", "onProductSelected")
    m.subscriptionScreen.observeField("backPressed", "onSubscriptionScreenBack")

    ' Set up showSubscriptionScreen observer
    m.top.observeField("showSubscriptionScreen", "onShowSubscriptionScreen")
    
    ' Set up showAuthScreen observer (for logout)
    m.top.observeField("showAuthScreen", "onShowAuthScreenRequest")

    print "[HeroMainScene] Observers set up complete"

    ' Set up error dialog
    errorOkButton = m.errorDialog.findNode("errorOkButton")
    if errorOkButton <> invalid then
        errorOkButton.observeField("buttonSelected", "onErrorOkPressed")
    end if

    ' Set up error dialog key handling
    m.errorDialog.observeField("focusedChild", "onErrorDialogFocus")

    ' Set focus to scene
    m.top.setFocus(true)

    ' Check authentication status
    checkAuthStatus()

    ' Initialize Roku Pay system
    print "[HeroMainScene] Initializing Roku Pay system..."
    m.purchaseHandler.initPurchaseSystem = true
end sub

sub setupScreenSize()
    ' Get screen resolution
    deviceInfo = CreateObject("roDeviceInfo")
    screenSize = deviceInfo.GetDisplaySize()
    m.screenWidth = screenSize.w
    m.screenHeight = screenSize.h

    print "[HeroMainScene] Detected screen size: "; m.screenWidth; "x"; m.screenHeight

    ' Update background size
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight

    ' Content group uses full screen
    m.top.findNode("contentGroup").translation = [0, 0]

    ' Update loading indicator size
    ' LoadingIndicator dimensions handled by component itself

    ' Update error dialog position (center of screen)
    dialogWidth = 1000
    dialogHeight = 400
    ' Ensure dialog fits on screen
    if dialogWidth > m.screenWidth - 40 then
        dialogWidth = m.screenWidth - 40
    end if
    if dialogHeight > m.screenHeight - 40 then
        dialogHeight = m.screenHeight - 40
    end if

    m.errorDialog.translation = [(m.screenWidth - dialogWidth) / 2, (m.screenHeight - dialogHeight) / 2]

    ' Update dialog size
    errorRect = m.errorDialog.findNode("Rectangle")
    if errorRect <> invalid then
        errorRect.width = dialogWidth
        errorRect.height = dialogHeight
    end if

    ' Store screen dimensions for child components
    m.top.screenWidth = m.screenWidth
    m.top.screenHeight = m.screenHeight

    print "[HeroMainScene] Set screen dimensions on interface: "; m.top.screenWidth; "x"; m.top.screenHeight
end sub

sub checkAuthStatus()
    print "[HeroMainScene] Checking authentication status..."
    if hasValidToken() then
        print "[HeroMainScene] Valid token found, showing hero screen"
        ' Already authenticated, show hero grid
        showSeedrHomeScene()
    else
        print "[HeroMainScene] No valid token, showing auth screen"
        ' Show authentication screen
        showAuthScreen()
    end if
end sub

sub showAuthScreen()
    print "[HeroMainScene] Showing AuthScreen..."
    m.authScreen.visible = true
    m.seedrHomeScene.visible = false
    m.videoPlayer.visible = false
    m.deviceAuthScreen.visible = false
    print "[HeroMainScene] AuthScreen visibility set to: "; m.authScreen.visible

    ' Set focus to AuthScreen with a small delay to ensure it's ready
    m.authFocusTimer = CreateObject("roSGNode", "Timer")
    m.authFocusTimer.duration = 0.2
    m.authFocusTimer.observeField("fire", "setAuthScreenFocus")
    m.authFocusTimer.control = "start"
end sub

sub setAuthScreenFocus()
    print "[HeroMainScene] Setting AuthScreen focus..."
    m.authScreen.setFocus(true)
    print "[HeroMainScene] AuthScreen focus set to: true"
end sub

sub showSeedrHomeScene()
    print "[HeroMainScene] Showing SeedrHomeScene..."
    m.authScreen.visible = false
    m.seedrHomeScene.visible = true
    m.videoPlayer.visible = false

    print "[HeroMainScene] SeedrHomeScene visibility set to: "; m.seedrHomeScene.visible
end sub

' Content handling is now done by HeroScreen directly

sub playVideo(fileContent as object)
    print "[HeroMainScene] Playing video: "; fileContent.title

    ' Load credentials
    credentials = loadCredentials()
    if credentials = invalid then
        showError("Authentication required")
        return
    end if

    ' Get video stream URL
    streamUrl = getVideoStreamUrlMain(fileContent.fileId, credentials.accessToken)

    if streamUrl <> "" then
        ' Signal to show video player
        m.top.playVideo = {
            url: streamUrl,
            title: fileContent.title
        }
    else
        showError("Could not get video stream URL")
    end if
end sub

sub showImage(fileContent as object)
    ' For now, just show file info
    showFileInfo(fileContent)
end sub

sub showFileInfo(fileContent as object)
    message = "File: " + fileContent.title + chr(10)
    if fileContent.fileData <> invalid then
        if fileContent.fileData.size <> invalid then
            message += "Size: " + formatFileSize(fileContent.fileData.size) + chr(10)
        end if
        if fileContent.fileData.mime_type <> invalid then
            message += "Type: " + fileContent.fileData.mime_type
        end if
    end if
    showError(message) ' Reusing error dialog for info
end sub

sub onAuthComplete()
    print "[HeroMainScene] onAuthComplete called!"
    print "[HeroMainScene] m.top.authComplete = "; m.top.authComplete
    print "[HeroMainScene] Field type: "; type(m.top.authComplete)

    if m.top.authComplete = true then
        print "[HeroMainScene] Authentication confirmed successful, showing hero screen"
        showSeedrHomeScene()
    else
        print "[HeroMainScene] authComplete is not true, value: "; m.top.authComplete
    end if
end sub

sub onPlayVideo()
    print "[HeroMainScene] ==================== ON PLAY VIDEO ===================="
    playVideoData = m.top.playVideo
    if playVideoData <> invalid then
        print "[HeroMainScene] Received play video request: "; playVideoData.title
        print "[HeroMainScene] Video data - FileId: "; playVideoData.fileId
        print "[HeroMainScene] Video data - IsAudio: "; playVideoData.isAudio

        ' IMMEDIATELY hide FolderDetailsScreen to prevent overlay
        print "[HeroMainScene] CRITICAL: Hiding FolderDetailsScreen before any processing"
        if m.folderDetailsScreen <> invalid then
            m.folderDetailsScreen.visible = false
            print "[HeroMainScene] FolderDetailsScreen visibility set to: "; m.folderDetailsScreen.visible
        end if

        ' Store video data for later use
        m.pendingVideoData = playVideoData

        ' Track source screen for proper back navigation
        ' Check if this is from a specific folder (FolderDetailsScreen) or root folder (SeedrHomeScene)
        ' Root folder files don't have folderData.files[].title, they have folderData.files[].name
        if playVideoData.folderData <> invalid then
            ' Check if files have .title property (FolderDetailsScreen format) or .name property (root folder format)
            isRootFolder = false
            if playVideoData.folderData.files <> invalid and playVideoData.folderData.files.Count() > 0 then
                firstFile = playVideoData.folderData.files[0]
                if firstFile <> invalid and firstFile.title = invalid and firstFile.name <> invalid then
                    isRootFolder = true
                end if
            end if

            if isRootFolder then
                m.audioPlaybackSource = "SeedrHomeScene"
            else
                m.audioPlaybackSource = "FolderDetailsScreen"
            end if
        else
            ' No folder data - assume root folder
            m.audioPlaybackSource = "SeedrHomeScene"
        end if

        ' Check if we have a fileId (new format) or url (old format)
        if playVideoData.fileId <> invalid then
            ' New format - get stream URL using Task
            print "[HeroMainScene] Getting stream URL for fileId: "; playVideoData.fileId

            ' Load credentials
            credentials = loadCredentials()
            if credentials <> invalid and credentials.accessToken <> invalid then
                ' Set up task parameters - ensure fileId is string to avoid scientific notation
                if Type(playVideoData.fileId) = "roString" then
                    m.streamUrlTask.fileId = playVideoData.fileId
                else
                    m.streamUrlTask.fileId = playVideoData.fileId.ToStr()
                end if
                m.streamUrlTask.accessToken = credentials.accessToken
                m.streamUrlTask.isAudio = (playVideoData.isAudio = true)

                ' Start the task
                m.streamUrlTask.control = "RUN"
                print "[HeroMainScene] Started stream URL task"
            else
                print "[HeroMainScene] ERROR: No valid credentials"
                showError("Authentication required")
            end if
        else if playVideoData.url <> invalid then
            ' Old format - direct URL
            print "[HeroMainScene] Using direct URL: "; playVideoData.url

            ' Hide other screens and show video player
            m.authScreen.visible = false
            m.seedrHomeScene.visible = false
            m.videoPlayer.visible = true

            ' Pass video data to player
            m.videoPlayer.playVideo = playVideoData
        else
            print "[HeroMainScene] ERROR: No fileId or url provided"
            showError("Invalid video data")
        end if
    end if
end sub

sub onPlayNextFile()
    nextFileData = m.top.playNextFile
    if nextFileData <> invalid then
        print "[HeroMainScene] Received playNextFile request: "; nextFileData.fileName

        ' Store video data for later use
        m.pendingVideoData = nextFileData

        ' Check if we have a fileId (new format) or url (old format)
        if nextFileData.fileId <> invalid then
            ' New format - get stream URL using Task
            print "[HeroMainScene] Getting stream URL for fileId: "; nextFileData.fileId

            ' Load credentials
            credentials = loadCredentials()
            if credentials <> invalid and credentials.accessToken <> invalid then
                ' Set up task parameters - ensure fileId is string to avoid scientific notation
                if Type(nextFileData.fileId) = "roString" then
                    m.streamUrlTask.fileId = nextFileData.fileId
                else
                    m.streamUrlTask.fileId = nextFileData.fileId.ToStr()
                end if
                m.streamUrlTask.accessToken = credentials.accessToken
                m.streamUrlTask.isAudio = (nextFileData.isAudio = true)

                ' Start the task
                m.streamUrlTask.control = "RUN"
                print "[HeroMainScene] Started stream URL task for next file"
            else
                print "[HeroMainScene] ERROR: No valid credentials for next file"
                showError("Authentication required")
            end if
        else
            print "[HeroMainScene] ERROR: No fileId provided for next file"
            showError("Invalid file data")
        end if
    end if
end sub

sub onStreamUrlReceived()
    streamUrl = m.streamUrlTask.streamUrl
    print "[HeroMainScene] Stream URL observer fired, URL: "; streamUrl

    if streamUrl <> invalid and streamUrl <> "" then
        print "[HeroMainScene] Received stream URL: "; streamUrl

        if m.pendingVideoData <> invalid then
            ' Check if this is background playback (track change) or initial playback
            isBackgroundPlayback = (m.pendingVideoData.isBackgroundPlayback = true)

            if isBackgroundPlayback then
                print "[HeroMainScene] BACKGROUND PLAYBACK - Keeping current screen visible"
                ' Only hide FolderDetailsScreen if it's visible, but keep other screens as they are
                if m.folderDetailsScreen <> invalid and m.folderDetailsScreen.visible = true then
                    m.folderDetailsScreen.visible = false
                    print "[HeroMainScene] Hidden FolderDetailsScreen for background playback"
                end if
            else
                print "[HeroMainScene] INITIAL PLAYBACK - Hiding all screens for playback"
                ' Hide other screens INCLUDING FolderDetailsScreen (original behavior)
                m.authScreen.visible = false
                m.seedrHomeScene.visible = false
                m.videoPlayer.visible = false
                m.audioPlayer.visible = false
                m.folderDetailsScreen.visible = false

                print "[HeroMainScene] All screens hidden for playback:"
                print "[HeroMainScene] - folderDetailsScreen: "; m.folderDetailsScreen.visible
                print "[HeroMainScene] - seedrHomeScene: "; m.seedrHomeScene.visible
                print "[HeroMainScene] - videoPlayer: "; m.videoPlayer.visible
            end if

            ' Check if this is audio or video
            if m.pendingVideoData.isAudio = true then
                ' For background playback, keep audio player off-screen; for initial playback, show it
                if isBackgroundPlayback then
                    ' Completely hide audio player for background playback
                    m.seedrAudioPlayer.visible = false
                    print "[HeroMainScene] Audio player completely hidden for background playback"
                else
                    ' Show Seedr audio player for initial audio playback
                    m.seedrAudioPlayer.visible = true
                    m.seedrAudioPlayer.translation = [340, 60] ' Ensure proper position
                    print "[HeroMainScene] Audio player shown for initial playback"
                end if

                ' Create content structure for SeedrAudioPlayer (matches example format)
                audioContent = CreateObject("roSGNode", "ContentNode")
                audioContent.title = m.pendingVideoData.title
                audioContent.actors = "" ' Artist - empty to remove "Seedr" text
                audioContent.album = "" ' Album - empty to remove "My Files" text
                audioContent.HDPosterUrl = "pkg:/images/audio5.png" ' Use clean audio icon instead of "no content"
                audioContent.Rating = "false" ' Not a live stream
                audioContent.url = streamUrl ' Stream URL

                ' Detect file format from filename extension
                fileName = m.pendingVideoData.title
                if fileName <> invalid then
                    print "[HeroMainScene] Checking file format for: "; fileName

                    ' Check file extension using InStr (case-insensitive)
                    if InStr(1, fileName, ".flac") > 0 then
                        audioContent.streamFormat = "flac"
                        print "[HeroMainScene] Detected FLAC format for: "; fileName
                    else if InStr(1, fileName, ".mp3") > 0 then
                        audioContent.streamFormat = "mp3"
                        print "[HeroMainScene] Detected MP3 format for: "; fileName
                    else if InStr(1, fileName, ".wav") > 0 then
                        audioContent.streamFormat = "wav"
                        print "[HeroMainScene] Detected WAV format for: "; fileName
                    else if InStr(1, fileName, ".aac") > 0 then
                        audioContent.streamFormat = "aac"
                        print "[HeroMainScene] Detected AAC format for: "; fileName
                    else
                        audioContent.streamFormat = "mp3" ' Default fallback
                        print "[HeroMainScene] Using default MP3 format for: "; fileName
                    end if
                else
                    audioContent.streamFormat = "mp3" ' Default fallback
                    print "[HeroMainScene] No filename, using default MP3 format"
                end if

                ' Set up SeedrAudioPlayer with content
                m.seedrAudioPlayer.itemContent = audioContent
                m.seedrAudioPlayer.audioControl = "play"

                ' Only set focus for initial playback, not background track changes
                if not isBackgroundPlayback then
                    m.seedrAudioPlayer.setFocus(true)
                end if

                ' Set up playlist data for next/previous functionality
                setupAudioPlaylist()

                print "[HeroMainScene] Audio player set up with playlist functionality"

                print "[HeroMainScene] Started SeedrAudioPlayer playback: "; m.pendingVideoData.title
            else
                ' Stop any currently playing audio before showing video
                if m.seedrAudioPlayer <> invalid then
                    m.seedrAudioPlayer.audioControl = "stop"
                    m.seedrAudioPlayer.visible = false
                    print "[HeroMainScene] Stopped audio playback for video"
                end if

                ' Hide other screens
                m.authScreen.visible = false
                m.seedrHomeScene.visible = false
                m.audioPlayer.visible = false

                ' Show video player
                m.videoPlayer.visible = true
                m.videoPlayer.setFocus(true)

                ' Pass stream URL to video player
                m.videoPlayer.playVideo = {
                    url: streamUrl,
                    title: m.pendingVideoData.title
                }

                print "[HeroMainScene] Started video playback: "; m.pendingVideoData.title
            end if
        else
            print "[HeroMainScene] ERROR: No pending video data"
        end if
    else
        print "[HeroMainScene] Stream URL not ready yet, waiting..."
        ' Don't show error dialog immediately, wait for task to complete
    end if
end sub

sub onStreamUrlError()
    errorMsg = m.streamUrlTask.error
    print "[HeroMainScene] Stream URL error: "; errorMsg
    showError("Stream error: " + errorMsg)
end sub

sub onAudioPlayerBack()
    print "[HeroMainScene] Audio player back pressed"
    ' Hide audio player and show hero screen
    m.audioPlayer.visible = false
    m.seedrHomeScene.visible = true
    m.seedrHomeScene.setFocus(true)
end sub

sub setupAudioPlaylist()
    print "[HeroMainScene] ===== SETTING UP AUDIO PLAYLIST ====="

    if m.pendingVideoData <> invalid and m.pendingVideoData.folderData <> invalid then
        folderData = m.pendingVideoData.folderData
        currentFileItem = m.pendingVideoData.currentFileItem

        print "[HeroMainScene] Folder data available - building playlist"
        print "[HeroMainScene] Total files in folder: "; folderData.files.count()

        ' Get all audio files from folder data
        audioFiles = []
        for i = 0 to folderData.files.count() - 1
            file = folderData.files[i]
            if file <> invalid then
                fileName = invalid
                if file.title <> invalid then
                    fileName = file.title
                else if file.name <> invalid then
                    fileName = file.name
                end if

                if fileName <> invalid and isAudioFile(fileName) then
                    ' Transform file to match expected format for SeedrAudioPlayer
                    ' Safely convert fileId to string - check multiple possible property names
                    fileIdStr = ""
                    fileIdValue = invalid

                    ' Try different property names for the file ID
                    if file.id <> invalid then
                        fileIdValue = file.id
                    else if file.file_id <> invalid then
                        fileIdValue = file.file_id
                    else if file.fileId <> invalid then
                        fileIdValue = file.fileId
                    else if file.folder_file_id <> invalid then
                        fileIdValue = file.folder_file_id
                    end if

                    if fileIdValue <> invalid then
                        fileIdType = Type(fileIdValue)
                        if fileIdType = "roString" or fileIdType = "String" then
                            fileIdStr = fileIdValue
                        else if fileIdType = "roInt" or fileIdType = "roInteger" or fileIdType = "Integer" then
                            fileIdStr = fileIdValue.ToStr()
                        else if fileIdType = "LongInteger" or fileIdType = "roLongInteger" then
                            fileIdStr = fileIdValue.ToStr()
                        else
                            ' Fallback for unknown types
                            fileIdStr = Str(fileIdValue).Trim()
                        end if
                        print "[HeroMainScene] Added to playlist: "; fileName; " (ID: "; fileIdStr; ")"
                    else
                        print "[HeroMainScene] ERROR: No file ID found for: "; fileName
                        ' Debug: print all properties of the file object
                        if i = 0 then ' Only log first file to avoid spam
                            print "[HeroMainScene] DEBUG: File object keys for first file:"
                            for each key in file
                                print "[HeroMainScene]   - "; key; " = "; file[key]
                            end for
                        end if
                    end if

                    ' Only add if we got a valid fileId
                    if fileIdStr <> "" then
                        audioFileItem = {
                            title: fileName,
                            fileId: fileIdStr,
                            fileData: file
                        }
                        audioFiles.Push(audioFileItem)
                    end if
                end if
            end if
        end for

        ' Find current file index in playlist
        currentIndex = 0
        if currentFileItem <> invalid then
            for i = 0 to audioFiles.Count() - 1
                if audioFiles[i].fileId = currentFileItem.fileId then
                    currentIndex = i
                    exit for
                end if
            end for
        end if

        print "[HeroMainScene] Playlist created: "; audioFiles.Count(); " files, current index: "; currentIndex

        ' Debug: Show first 3 files in playlist
        if audioFiles.Count() > 0 then
            print "[HeroMainScene] First files in playlist:"
            for i = 0 to 2
                if i < audioFiles.Count() then
                    print "[HeroMainScene] ["; i; "] "; audioFiles[i].title; " ID: "; audioFiles[i].fileId
                end if
            end for
        end if

        ' Send playlist to audio player
        if m.seedrAudioPlayer <> invalid then
            m.seedrAudioPlayer.setCurrentFolderFiles = {
                files: audioFiles,
                currentIndex: currentIndex,
                folderId: folderData.id
            }

            ' Pass access token for independent track switching
            credentials = loadCredentials()
            if credentials <> invalid and credentials.accessToken <> invalid then
                m.seedrAudioPlayer.accessToken = credentials.accessToken
                print "[HeroMainScene] SUCCESS: Sent playlist AND access token to audio player"
            else
                print "[HeroMainScene] WARNING: Could not send access token - track switching may fail"
            end if

            print "[HeroMainScene] Audio player now has full playlist control"
        else
            print "[HeroMainScene] ERROR: seedrAudioPlayer is invalid"
        end if
    else
        print "[HeroMainScene] ERROR: No folder data available for playlist setup"
    end if
    print "[HeroMainScene] ========================================="
end sub


sub onSeedrAudioPlayerBack()
    print "[HeroMainScene] ==================== AUDIO PLAYER BACK ===================="
    print "[HeroMainScene] SeedrAudioPlayer back pressed - implementing reverse navigation"
    print "[HeroMainScene] Audio playback source: "; m.audioPlaybackSource

    ' Hide audio player
    m.seedrAudioPlayer.visible = false

    ' SMART NAVIGATION: Return to the screen where audio was started
    if m.audioPlaybackSource = "FolderDetailsScreen" and m.folderDetailsScreen <> invalid then
        print "[HeroMainScene] Returning to FolderDetailsScreen (audio started from folder)"

        ' Hide home scene
        m.seedrHomeScene.visible = false

        ' Show FolderDetailsScreen
        m.folderDetailsScreen.visible = true
        m.folderDetailsScreen.setFocus(true)
        print "[HeroMainScene] FolderDetailsScreen restored and focused"
    else
        print "[HeroMainScene] Returning to SeedrHomeScene (audio started from root folder)"
        ' Return to home scene
        m.seedrHomeScene.visible = true
        m.seedrHomeScene.setFocus(true)
        m.top.setFocus(true)
        print "[HeroMainScene] Returned to SeedrHomeScene"
    end if
    print "[HeroMainScene] ============================================================="
end sub

' Handle Image Viewer back button
sub onImageViewerBack()
    print "[HeroMainScene] Image viewer back pressed"

    ' Hide image viewer
    m.imageViewer.visible = false

    ' Return to previous screen based on where image was opened from
    if m.imageViewerSource = "FolderDetailsScreen" and m.folderDetailsScreen <> invalid then
        m.folderDetailsScreen.visible = true
        m.folderDetailsScreen.setFocus(true)
        print "[HeroMainScene] Returned to FolderDetailsScreen"
    else
        m.seedrHomeScene.visible = true
        m.seedrHomeScene.setFocus(true)
        print "[HeroMainScene] Returned to SeedrHomeScene"
    end if
end sub

' Handle Document Viewer back button
sub onDocumentViewerBack()
    print "[HeroMainScene] Document viewer back pressed"

    ' Hide document viewer
    m.documentViewer.visible = false

    ' Return to previous screen based on where document was opened from
    if m.documentViewerSource = "FolderDetailsScreen" and m.folderDetailsScreen <> invalid then
        m.folderDetailsScreen.visible = true
        m.folderDetailsScreen.setFocus(true)
        print "[HeroMainScene] Returned to FolderDetailsScreen"
    else
        m.seedrHomeScene.visible = true
        m.seedrHomeScene.setFocus(true)
        print "[HeroMainScene] Returned to SeedrHomeScene"
    end if
end sub

' Show Image Viewer
sub showImageViewer(imageData as object, source as string)
    print "[HeroMainScene] Showing image viewer for: "; imageData.title

    ' Hide all other screens
    m.authScreen.visible = false
    m.seedrHomeScene.visible = false
    m.videoPlayer.visible = false
    m.audioPlayer.visible = false
    m.seedrAudioPlayer.visible = false
    m.folderDetailsScreen.visible = false
    m.documentViewer.visible = false

    ' Track source for back navigation
    m.imageViewerSource = source

    ' Show and set up image viewer
    m.imageViewer.visible = true
    m.imageViewer.imageData = imageData
    m.top.setFocus(true) ' Set focus to parent scene for key handling

    print "[HeroMainScene] Image viewer shown"
end sub

' Show Document Viewer
sub showDocumentViewer(documentData as object, source as string)
    print "[HeroMainScene] Showing document viewer for: "; documentData.title

    ' Hide all other screens
    m.authScreen.visible = false
    m.seedrHomeScene.visible = false
    m.videoPlayer.visible = false
    m.audioPlayer.visible = false
    m.seedrAudioPlayer.visible = false
    m.folderDetailsScreen.visible = false
    m.imageViewer.visible = false

    ' Track source for back navigation
    m.documentViewerSource = source

    ' Show and set up document viewer
    m.documentViewer.visible = true
    m.documentViewer.documentData = documentData
    m.top.setFocus(true) ' Set focus to parent scene for key handling

    print "[HeroMainScene] Document viewer shown"
end sub

' Handle FolderDetailsScreen display request
sub onShowFolderDetails()
    folderData = m.top.showFolderDetails
    if folderData <> invalid then
        print "[HeroMainScene] ==================== SHOW FOLDER DETAILS ===================="
        print "[HeroMainScene] 🟡 NAVIGATING TO FOLDER DETAILS SCREEN"
        print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()
        print "[HeroMainScene] Showing FolderDetailsScreen for: "; folderData.title

        ' Hide other screens
        m.authScreen.visible = false
        m.seedrHomeScene.visible = false
        m.videoPlayer.visible = false
        m.audioPlayer.visible = false
        m.seedrAudioPlayer.visible = false

        ' Show and set up FolderDetailsScreen
        m.folderDetailsScreen.folderData = folderData
        m.folderDetailsScreen.visible = true
        m.folderDetailsScreen.setFocus(true)

        print "[HeroMainScene] FolderDetailsScreen shown"
    end if
end sub

' Handle Image Viewer display request
sub onShowImageViewer()
    viewerData = m.top.showImageViewer
    if viewerData <> invalid then
        print "[HeroMainScene] Showing image viewer for: "; viewerData.imageData.title
        showImageViewer(viewerData.imageData, viewerData.source)
    end if
end sub

' Handle Document Viewer display request
sub onShowDocumentViewer()
    viewerData = m.top.showDocumentViewer
    if viewerData <> invalid then
        print "[HeroMainScene] Showing document viewer for: "; viewerData.documentData.title
        showDocumentViewer(viewerData.documentData, viewerData.source)
    end if
end sub

' Handle FolderDetailsScreen visibility changes
sub onFolderDetailsVisibilityChanged()
    print "[HeroMainScene] FolderDetailsScreen visibility changed to: "; m.folderDetailsScreen.visible

    if m.folderDetailsScreen <> invalid and m.folderDetailsScreen.visible = false then
        print "[HeroMainScene] FolderDetailsScreen closed, returning to home immediately"

        ' Hide all other screens immediately
        m.folderDetailsScreen.visible = false
        m.videoPlayer.visible = false
        m.audioPlayer.visible = false
        m.seedrAudioPlayer.visible = false

        ' Show and focus home scene
        m.seedrHomeScene.visible = true
        m.seedrHomeScene.setFocus(true)

        print "[HeroMainScene] Returned to SeedrHomeScene"
    end if
end sub

' Handle play button from FolderDetailsScreen
sub onFolderDetailsPlayPressed()
    if m.folderDetailsScreen <> invalid and m.folderDetailsScreen.selectedItem <> invalid then
        selectedItem = m.folderDetailsScreen.selectedItem
        print "[HeroMainScene] ==================== FOLDER DETAILS PLAY PRESSED ===================="
        print "[HeroMainScene] STARTING VIDEO/AUDIO PLAYBACK FROM FOLDER DETAILS"
        print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()
        print "[HeroMainScene] FolderDetailsScreen play pressed for: "; selectedItem.title

        ' Route to appropriate play handler based on file type
        if selectedItem.fileType = "video" then
            print "[HeroMainScene] Playing video from FolderDetailsScreen"

            ' Hide FolderDetailsScreen first
            m.folderDetailsScreen.visible = false

            ' Use existing video playback logic
            m.top.playVideo = {
                fileId: selectedItem.fileId,
                title: selectedItem.title,
                fileData: selectedItem.fileData,
                isAudio: false
            }

        else if selectedItem.fileType = "audio" then
            print "[HeroMainScene] Playing audio from FolderDetailsScreen"

            ' Hide FolderDetailsScreen first
            m.folderDetailsScreen.visible = false

            ' Get folder data from FolderDetailsScreen for playlist
            folderData = invalid
            if m.folderDetailsScreen.folderData <> invalid then
                folderData = m.folderDetailsScreen.folderData
                print "[HeroMainScene] Got folder data with "; folderData.files.count(); " files"
            else
                print "[HeroMainScene] WARNING: No folder data available from FolderDetailsScreen"
            end if

            ' Use existing audio playback logic with folder data for playlist
            m.top.playVideo = {
                fileId: selectedItem.fileId,
                title: selectedItem.title,
                fileData: selectedItem.fileData,
                isAudio: true,
                folderData: folderData,
                currentFileItem: selectedItem
            }
        end if
    end if
end sub

sub onNavigateToFolder()
    navigationData = m.top.navigateToFolder
    if navigationData <> invalid then
        print "[HeroMainScene] Navigating to folder: "; navigationData.folderName; " (ID: "; navigationData.folderId; ")"

        ' Tell hero screen to navigate to the folder
        ' Navigation handled internally by SeedrHomeScene
    end if
end sub

sub onErrorOkPressed()
    ' Hide error dialog
    m.errorDialog.visible = false

    ' Return focus to appropriate screen
    if m.seedrHomeScene.visible then
        m.seedrHomeScene.setFocus(true)
    else if m.authScreen.visible then
        m.authScreen.setFocus(true)
    end if
end sub

sub onErrorDialogFocus()
    ' When error dialog gets focus, make sure it can handle keys
    if m.errorDialog.visible then
        m.errorDialog.setFocus(true)
    end if
end sub

sub showError(message as string)
    m.errorDialog.findNode("errorMessage").text = message
    m.errorDialog.visible = true
    m.errorDialog.setFocus(true)
    print "[HeroMainScene] Error dialog shown: "; message
end sub

' Key handling
function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        ' Handle viewer key events first
        if m.imageViewer <> invalid and m.imageViewer.visible then
            if key = "back" then
                print "[HeroMainScene] Back pressed in image viewer"
                onImageViewerBack()
                return true
            else if key = "OK" then
                ' Toggle info overlay - call function on the viewer
                print "[HeroMainScene] OK pressed in image viewer - toggling info"
                ' For now, just handle back - OK toggle can be added later
                return true
            end if
        else if m.documentViewer <> invalid and m.documentViewer.visible then
            if key = "back" then
                print "[HeroMainScene] Back pressed in document viewer"
                onDocumentViewerBack()
                return true
            else if key = "OK" then
                print "[HeroMainScene] OK pressed in document viewer - showing download dialog"
                ' For now, just handle back - OK for download can be added later
                return true
            end if
        else if key = "back" then
            if m.errorDialog.visible then
                print "[HeroMainScene] Back button pressed, closing error dialog"
                m.errorDialog.visible = false
                ' Return focus to home scene
                if m.seedrHomeScene.visible then
                    m.seedrHomeScene.setFocus(true)
                end if
                return true
            else if m.warningDialog.visible then
                m.warningDialog.visible = false
                if m.seedrHomeScene.visible then
                    m.seedrHomeScene.setFocus(true)
                end if
                return true
            else if m.videoPlayer.visible then
                ' Stop video and return to hero screen
                m.videoPlayer.findNode("videoNode").control = "stop"
                m.videoPlayer.visible = false
                showSeedrHomeScene()
                return true
            else if m.seedrHomeScene.visible then
                ' Let the home scene handle its own back navigation
                ' Don't handle it here to avoid conflicts
                return false
            end if
        else if key = "OK" then
            if m.warningDialog.visible then
                m.warningDialog.visible = false
                if m.seedrHomeScene.visible then
                    m.seedrHomeScene.setFocus(true)
                end if
                return true
            end if
        else if key = "home" then
            ' GLOBAL HOME BUTTON - Navigate to root folder from any screen
            print "[HeroMainScene] ==================== GLOBAL HOME BUTTON ===================="
            print "[HeroMainScene] 🌐 GLOBAL HOME BUTTON PRESSED FROM ROKU REMOTE"
            print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()

            ' Log current screen states BEFORE hiding
            print "[HeroMainScene] BEFORE - Screen visibility states:"
            print "[HeroMainScene] BEFORE - authScreen.visible: "; m.authScreen.visible
            print "[HeroMainScene] BEFORE - seedrHomeScene.visible: "; m.seedrHomeScene.visible
            print "[HeroMainScene] BEFORE - videoPlayer.visible: "; m.videoPlayer.visible
            print "[HeroMainScene] BEFORE - audioPlayer.visible: "; m.audioPlayer.visible
            print "[HeroMainScene] BEFORE - seedrAudioPlayer.visible: "; m.seedrAudioPlayer.visible
            print "[HeroMainScene] BEFORE - folderDetailsScreen.visible: "; m.folderDetailsScreen.visible

            ' Hide all screens except home scene
            print "[HeroMainScene] 🔄 Hiding all other screens..."
            m.authScreen.visible = false
            m.deviceAuthScreen.visible = false
            m.videoPlayer.visible = false
            m.audioPlayer.visible = false
            m.seedrAudioPlayer.visible = false
            m.folderDetailsScreen.visible = false

            ' Show and focus home scene
            print "[HeroMainScene] 🟢 Showing and focusing SeedrHomeScene..."
            m.seedrHomeScene.visible = true
            m.seedrHomeScene.setFocus(true)

            ' Log screen states AFTER changes
            print "[HeroMainScene] AFTER - Screen visibility states:"
            print "[HeroMainScene] AFTER - seedrHomeScene.visible: "; m.seedrHomeScene.visible
            print "[HeroMainScene] AFTER - folderDetailsScreen.visible: "; m.folderDetailsScreen.visible
            print "[HeroMainScene] AFTER - videoPlayer.visible: "; m.videoPlayer.visible

            ' Trigger root folder load via interface field
            print "[HeroMainScene] 🚀 Triggering root folder load via interface field..."
            print "[SeedrHomeScene] BEFORE trigger - loadRootFolder field: "; m.seedrHomeScene.loadRootFolder
            m.seedrHomeScene.loadRootFolder = true
            print "[HeroMainScene] AFTER trigger - loadRootFolder field: "; m.seedrHomeScene.loadRootFolder

            print "[HeroMainScene] Global Home navigation completed"
            print "[HeroMainScene] ============================================================="
            return true

            ' Global audio controls - work from any screen
        else if key = "*" then
            print "[HeroMainScene] * key pressed - Global audio previous"
            if m.seedrAudioPlayer <> invalid and m.seedrAudioPlayer.isGloballyPlaying then
                m.seedrAudioPlayer.globalAudioCommand = "previous"
                return true
            end if

        else if key = "#" then
            print "[HeroMainScene] # key pressed - Global audio next"
            if m.seedrAudioPlayer <> invalid and m.seedrAudioPlayer.isGloballyPlaying then
                m.seedrAudioPlayer.globalAudioCommand = "next"
                return true
            end if

        else if key = "play" then
            print "[HeroMainScene] Play key pressed - Global audio play/pause"
            if m.seedrAudioPlayer <> invalid then
                m.seedrAudioPlayer.globalAudioCommand = "play_pause"
                return true
            end if

        else if key = "options" then
            if m.warningDialog.visible then
                m.warningDialog.visible = false
                if m.seedrHomeScene.visible then
                    m.seedrHomeScene.setFocus(true)
                end if
                return true
            end if
        end if
    end if
    return false
end function

' Handle showing device auth screen
sub onShowDeviceAuth()
    print "[HeroMainScene] ==================== SHOW DEVICE AUTH ===================="
    print "[HeroMainScene] Sign In button pressed, showing DeviceAuthScreen"
    print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()

    ' Hide main auth screen and show device auth screen
    m.authScreen.visible = false
    m.deviceAuthScreen.visible = true
    m.deviceAuthScreen.setFocus(true)

    print "[HeroMainScene] DeviceAuthScreen shown and focused"
    print "[HeroMainScene] ============================================================="
end sub

' Handle device auth completion
sub onDeviceAuthComplete()
    print "[HeroMainScene] ==================== DEVICE AUTH COMPLETE ===================="
    print "[HeroMainScene] Device authorization completed successfully"
    print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()

    ' Hide device auth screen and show home scene
    m.deviceAuthScreen.visible = false
    m.authScreen.visible = false
    m.seedrHomeScene.visible = true
    m.seedrHomeScene.setFocus(true)

    print "[HeroMainScene] Showing SeedrHomeScene after successful auth"
    print "[HeroMainScene] ============================================================="
end sub

' Handle back button from device auth screen
sub onDeviceAuthBack()
    print "[HeroMainScene] ==================== DEVICE AUTH BACK ===================="
    print "[HeroMainScene] Back button pressed in DeviceAuthScreen"
    print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()

    ' Hide device auth screen and show main auth screen
    m.deviceAuthScreen.visible = false
    m.authScreen.visible = true
    m.authScreen.setFocus(true)

    print "[HeroMainScene] Returned to main AuthScreen"
    print "[HeroMainScene] ============================================================="
end sub

' ********** Roku Pay Event Handlers **********

' Handle catalog ready event
sub onCatalogReady()
    print "[HeroMainScene] Product catalog is ready"
    catalogReady = m.purchaseHandler.catalogReady

    if catalogReady then
        print "[HeroMainScene] ✓ Catalog loaded successfully"

        ' Update subscription screen with catalog data
        if m.subscriptionScreen <> invalid then
            m.subscriptionScreen.catalogData = m.purchaseHandler.catalogData
        end if
    end if
end sub

' Handle purchases ready event
sub onPurchasesReady()
    print "[HeroMainScene] User purchases are ready"
    purchasesReady = m.purchaseHandler.purchasesReady

    if purchasesReady then
        print "[HeroMainScene] ✓ Purchases loaded successfully"

        ' Update subscription screen with purchases data
        if m.subscriptionScreen <> invalid then
            m.subscriptionScreen.purchasesData = m.purchaseHandler.purchasesData
        end if
    end if
end sub

' Handle subscription status changes
sub onSubscriptionStatusChanged()
    print "[HeroMainScene] Subscription status changed"
    status = m.purchaseHandler.subscriptionStatus

    if status <> invalid then
        print "[HeroMainScene] New subscription status:"
        print "  Tier: " + status.tier

        ' Convert boolean to string for display
        activeStr = "false"
        if status.isActive = true then activeStr = "true"
        print "  Active: " + activeStr

        premiumStr = "false"
        if status.isPremium = true then premiumStr = "true"
        print "  Premium: " + premiumStr

        ' Log full status for debugging
        logSubscriptionStatus()

        ' Update subscription screen with current subscription
        if m.subscriptionScreen <> invalid then
            m.subscriptionScreen.currentSubscription = status
        end if

        ' Notify SeedrHomeScene if visible (to update UI)
        if m.seedrHomeScene <> invalid and m.seedrHomeScene.visible then
            ' Could trigger refresh of premium content, etc.
            print "[HeroMainScene] Notifying SeedrHomeScene of subscription change"
        end if
    end if
end sub

' Handle order complete event
sub onOrderComplete()
    print "[HeroMainScene] Order completed"
    orderResult = m.purchaseHandler.orderComplete

    if orderResult <> invalid then
        if orderResult.success then
            ' Purchase successful!
            print "[HeroMainScene] ✓✓✓ Purchase successful! ✓✓✓"

            ' Hide subscription screen
            m.subscriptionScreen.visible = false
            m.top.setFocus(true)

            ' Show success message
            showDialog("Purchase Complete", "Thank you for subscribing! Your premium features are now active.", "success")

            ' Refresh the subscription status
            m.purchaseHandler.getPurchases = true

        else if orderResult.cancelled then
            ' User cancelled
            print "[HeroMainScene] Purchase cancelled by user"
            showDialog("Purchase Cancelled", "Your purchase was cancelled. You can subscribe anytime from the menu.", "info")

        else
            ' Purchase failed
            print "[HeroMainScene] ✗ Purchase failed: " + orderResult.error
            showDialog("Purchase Failed", orderResult.error, "error")
        end if
    end if
end sub

' Handle purchase errors
sub onPurchaseError()
    errorMsg = m.purchaseHandler.error
    print "[HeroMainScene] Purchase error: " + errorMsg
    showDialog("Purchase Error", errorMsg, "error")
end sub

' Handle show subscription screen request
sub onShowSubscriptionScreen()
    print "[HeroMainScene] Show subscription screen requested"

    ' Hide all other screens
    hideAllScreens()

    ' Update subscription screen data
    m.subscriptionScreen.catalogData = m.purchaseHandler.catalogData
    m.subscriptionScreen.purchasesData = m.purchaseHandler.purchasesData

    if m.global <> invalid and m.global.subscriptionStatus <> invalid then
        m.subscriptionScreen.currentSubscription = m.global.subscriptionStatus
    end if

    ' Show subscription screen
    m.subscriptionScreen.visible = true
    m.subscriptionScreen.setFocus(true)
end sub

' Handle request to show auth screen (triggered by logout)
sub onShowAuthScreenRequest()
    print "[HeroMainScene] ==================== SHOW AUTH SCREEN REQUEST ===================="
    print "[HeroMainScene] Auth screen requested (likely from logout)"
    print "[HeroMainScene] Current time: "; CreateObject("roDateTime").AsSeconds()
    
    ' Hide all screens
    hideAllScreens()
    
    ' Show auth screen
    showAuthScreen()
    
    print "[HeroMainScene] Auth screen shown - user can re-authenticate"
    print "[HeroMainScene] ============================================================="
end sub

' Handle product selection from subscription screen
sub onProductSelected()
    productId = m.subscriptionScreen.productSelected

    if productId <> invalid and productId <> "" then
        print "[HeroMainScene] Product selected for purchase: " + productId

        ' Initiate purchase through purchase handler
        m.purchaseHandler.orderProduct = productId
    end if
end sub

' Handle back button from subscription screen
sub onSubscriptionScreenBack()
    print "[HeroMainScene] Back pressed on subscription screen"
    m.subscriptionScreen.visible = false
    m.top.setFocus(true)

    ' Return to previous screen (typically SeedrHomeScene)
    if m.seedrHomeScene <> invalid then
        m.seedrHomeScene.visible = true
        m.seedrHomeScene.setFocus(true)
    end if
end sub

' Helper function to show a dialog with custom styling
sub showDialog(title as string, message as string, dialogType as string)
    ' For now, use the existing error dialog
    ' In a full implementation, create a custom dialog component

    if m.errorDialog <> invalid then
        titleNode = m.errorDialog.findNode("errorTitle")
        messageNode = m.errorDialog.findNode("errorMessage")

        if titleNode <> invalid then titleNode.text = title
        if messageNode <> invalid then messageNode.text = message

        ' Show dialog
        m.errorDialog.visible = true
        m.errorDialog.setFocus(true)
    end if
end sub

' Helper function to hide all screens
sub hideAllScreens()
    if m.seedrHomeScene <> invalid then m.seedrHomeScene.visible = false
    if m.videoPlayer <> invalid then m.videoPlayer.visible = false
    if m.audioPlayer <> invalid then m.audioPlayer.visible = false
    if m.folderDetailsScreen <> invalid then m.folderDetailsScreen.visible = false
    if m.imageViewer <> invalid then m.imageViewer.visible = false
    if m.documentViewer <> invalid then m.documentViewer.visible = false
    if m.subscriptionScreen <> invalid then m.subscriptionScreen.visible = false
end sub

' Handle global audio state changes
sub onGlobalAudioStateChanged()
    isPlaying = m.seedrAudioPlayer.isGloballyPlaying
    print "[HeroMainScene] Global audio state changed - Playing: "; isPlaying
    ' Could update UI elements to show global audio status
end sub

' Handle current track changes
sub onCurrentTrackChanged()
    trackInfo = m.seedrAudioPlayer.currentTrackInfo
    if trackInfo <> invalid then
        print "[HeroMainScene] Current track changed: "; trackInfo.title
        ' Could update UI to show current track info
    end if
end sub

' Helper function to log screen visibility changes with timestamps
sub logScreenVisibility(screenName as string, visible as boolean)
    if visible then
        print "[HeroMainScene] 🟢 SHOWING: "; screenName; " at "; CreateObject("roDateTime").AsSeconds()
    else
        print "[HeroMainScene] 🔴 HIDING: "; screenName; " at "; CreateObject("roDateTime").AsSeconds()
    end if
end sub

