sub init()
    print "SeedrAudioPlayer " ; "init()"

    m.timer = m.top.findNode("timer")
    m.backgroundPoster = m.top.findNode("backgroundPoster")
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemAuthor = m.top.findNode("itemAuthor")
    m.itemAlbumInfo = m.top.findNode("itemAlbumInfo")
    m.itemSongName = m.top.findNode("itemSongName")
    m.itemAuthorGroup = m.top.findNode("itemAuthorGroup")
    m.itemAlbumInfoGroup = m.top.findNode("itemAlbumInfoGroup")
    m.itemSongGroup = m.top.findNode("itemSongGroup")
    m.itemCurPosition = m.top.findNode("itemCurPosition")
    m.itemLenght = m.top.findNode("itemLenght")
    m.audio = m.top.findNode("audio")
    m.itemFramePoster = m.top.findNode("itemFramePoster")

    m.itemPlayStatePoster = m.top.findNode("itemPlayStatePoster")
    m.itemRepeat = m.top.findNode("itemRepeat")

    m.progressBar = m.top.findNode("progressBar")

    m.authorAnimation = m.top.FindNode("authorAnimation")
    m.albumAnimation = m.top.FindNode("albumAnimation")
    m.songAnimation = m.top.FindNode("songAnimation")

    ' Create interpolators programmatically to avoid timing issues
    createInterpolators()

    ' Note: ProgressBar styling is handled in XML, not via BrightScript fields
    ' The following fields don't exist on ProgressBar component:
    ' - progressBarBckgColor
    ' - progressBarBckgWidth
    ' - progressBarBckgHeight
    ' - progressBarColor
    ' - progressBarHeight
    ' ProgressBar styling should be done in the XML component definition

    m.replay = false
    m.currentFileIndex = 0
    m.currentFolderFiles = []
    m.currentFolderId = ""
    m.accessToken = ""
    m.pendingFileItem = invalid
    m.pendingFileIndex = -1
    m.wasPlaying = false

    ' Create StreamUrlTask for fetching stream URLs
    m.streamUrlTask = CreateObject("roSGNode", "StreamUrlTask")
    m.streamUrlTask.observeField("streamUrl", "onStreamUrlReceived")
    m.streamUrlTask.observeField("error", "onStreamUrlError")
    print "[SeedrAudioPlayer] StreamUrlTask created for independent track switching"

    ' Create timer for delayed auto-next (3 second gap between tracks)
    m.autoNextTimer = CreateObject("roSGNode", "Timer")
    m.autoNextTimer.duration = 3.0
    m.autoNextTimer.repeat = false
    m.autoNextTimer.observeField("fire", "onAutoNextTimerFire")
    print "[SeedrAudioPlayer] Auto-next timer created (3 second delay)"

    m.timer.observeField("fire", "onTimerFire")

    m.top.observeField("itemContent", "onItemContent")
    m.top.observeField("focusedChild", "onFocus")
    m.top.observeField("onBackPressed", "onBackPressedChanged")
    m.top.observeField("playNextFile", "onPlayNextFile")
    m.top.observeField("setCurrentFolderFiles", "onSetCurrentFolderFiles")
    m.top.observeField("globalAudioCommand", "onGlobalAudioCommand")
    m.top.observeField("accessToken", "onAccessTokenChanged")

    m.itemAuthorGroup.observeField("translation", "onAuthorRender")
    m.itemAlbumInfoGroup.observeField("translation", "onAlbumRender")
    m.itemSongGroup.observeField("translation", "onSongNameRender")

    m.audio.observeField("state", "onPlayerState")
    m.audio.observeField("position", "onPlayerPosition")

    ' Progress bar initialization removed to avoid field errors
end sub

sub createInterpolators()
    print "[SeedrAudioPlayer] Creating interpolators..."

    ' Check if animation nodes exist before creating interpolators
    if m.authorAnimation = invalid then
        print "[SeedrAudioPlayer] ERROR: authorAnimation not found"
        return
    end if

    if m.albumAnimation = invalid then
        print "[SeedrAudioPlayer] ERROR: albumAnimation not found"
        return
    end if

    if m.songAnimation = invalid then
        print "[SeedrAudioPlayer] ERROR: songAnimation not found"
        return
    end if

    ' Create author interpolator
    m.itemAuthorInterp = CreateObject("roSGNode", "Vector2DFieldInterpolator")
    m.itemAuthorInterp.key = [0.0, 2.0]
    m.itemAuthorInterp.keyValue = [[5, 0], [-2000, 0]]
    m.itemAuthorInterp.fieldToInterp = "itemAuthorGroup.translation"
    m.authorAnimation.appendChild(m.itemAuthorInterp)
    print "[SeedrAudioPlayer] Author interpolator created"

    ' Create album interpolator
    m.itemAlbumInfoInterp = CreateObject("roSGNode", "Vector2DFieldInterpolator")
    m.itemAlbumInfoInterp.key = [0.0, 2.0]
    m.itemAlbumInfoInterp.keyValue = [[5, 0], [-2000, 0]]
    m.itemAlbumInfoInterp.fieldToInterp = "itemAlbumInfoGroup.translation"
    m.albumAnimation.appendChild(m.itemAlbumInfoInterp)
    print "[SeedrAudioPlayer] Album interpolator created"

    ' Create song interpolator
    m.itemSongNameInterp = CreateObject("roSGNode", "Vector2DFieldInterpolator")
    m.itemSongNameInterp.key = [0.0, 2.0]
    m.itemSongNameInterp.keyValue = [[5, 0], [-2000, 0]]
    m.itemSongNameInterp.fieldToInterp = "itemSongGroup.translation"
    m.songAnimation.appendChild(m.itemSongNameInterp)
    print "[SeedrAudioPlayer] Song interpolator created"

    print "[SeedrAudioPlayer] All interpolators created successfully"
end sub

sub onDestroy()
    print "SeedrAudioPlayer onDestroy() - cleaning up"
    ' Don't stop audio when component is destroyed - let it continue playing
end sub

sub onBackPressedChanged()
    if m.top.onBackPressed then
        print "SeedrAudioPlayer onBackPressed changed to true"
        ' Don't stop audio when navigating back - let it continue playing
        ' Reset the field to false after handling
        m.top.onBackPressed = false
    end if
end sub

sub onPlayNextFile()
    nextFileData = m.top.playNextFile
    if nextFileData <> invalid then
        print "[SeedrAudioPlayer] Received playNextFile request: "; nextFileData.fileName
        ' Signal the parent to handle the file playback
        m.top.getParent().playNextFile = nextFileData
    end if
end sub

sub onSetCurrentFolderFiles()
    print "[SeedrAudioPlayer] onSetCurrentFolderFiles() called"
    folderData = m.top.setCurrentFolderFiles
    if folderData <> invalid then
        print "[SeedrAudioPlayer] Folder data received - files count: "; folderData.files.Count()
        print "[SeedrAudioPlayer] Folder data - current index: "; folderData.currentIndex
        print "[SeedrAudioPlayer] Folder data - folder ID: "; folderData.folderId

        m.currentFolderFiles = folderData.files
        m.currentFileIndex = folderData.currentIndex
        m.currentFolderId = folderData.folderId

        print "[SeedrAudioPlayer] Successfully set folder files: "; m.currentFolderFiles.Count(); " files, current index: "; m.currentFileIndex

        ' List all files in the playlist for debugging
        for i = 0 to m.currentFolderFiles.Count() - 1
            if m.currentFolderFiles[i] <> invalid then
                print "[SeedrAudioPlayer] Playlist["; i; "]: "; m.currentFolderFiles[i].title
            end if
        end for
    else
        print "[SeedrAudioPlayer] ERROR: folderData is invalid"
    end if
end sub

' Handle access token changes
sub onAccessTokenChanged()
    m.accessToken = m.top.accessToken
    if m.accessToken <> invalid and m.accessToken <> "" then
        print "[SeedrAudioPlayer] Access token received and stored - ready for independent track switching"
    else
        print "[SeedrAudioPlayer] WARNING: Access token is empty or invalid"
    end if
end sub

' Handle global audio commands from other screens
sub onGlobalAudioCommand()
    command = m.top.globalAudioCommand
    if command <> invalid and command <> "" then
        print "[SeedrAudioPlayer] Received global audio command: "; command

        if command = "play_pause" then
            if m.audio.state = "playing"
                print "[SeedrAudioPlayer] Global command: Pausing audio"
                m.audio.control = "pause"
            else if m.audio.state = "paused"
                print "[SeedrAudioPlayer] Global command: Resuming audio"
                m.audio.control = "resume"
            else if m.audio.state = "stopped" or m.audio.state = "finished"
                print "[SeedrAudioPlayer] Global command: Starting audio playback"
                m.audio.control = "play"
            end if

        else if command = "next"
            print "[SeedrAudioPlayer] Global command: Next track"
            playNextFile()

        else if command = "previous"
            print "[SeedrAudioPlayer] Global command: Previous track"
            playPreviousFile()

        else if command = "stop"
            print "[SeedrAudioPlayer] Global command: Stop audio"
            m.audio.control = "stop"
        end if

        ' Clear the command after processing
        m.top.globalAudioCommand = ""
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "SeedrAudioPlayer " ; "onKeyEvent()"

    handled = false
    if press

        if (key = "back")
            print "SeedrAudioPlayer back button pressed"
            m.top.onBackPressed = true
            handled = true
        else if (key = "fastforward")
            if m.itemLive <> "true"
                if m.audio.position < m.audio.duration
                    m.audio.seek = m.audio.position + divider(m.audio.duration)
                else
                    m.audio.control = "stop"
                end if
            end if
        else if (key = "rewind")
            if m.itemLive <> "true"
                m.audio.seek = m.audio.position - divider(m.audio.duration)
            end if
        else if (key = "left")
            if m.itemLive <> "true"
                ' Seek backward 10 seconds
                newPosition = m.audio.position - 10
                if newPosition < 0 then newPosition = 0
                m.audio.seek = newPosition
                print "SeedrAudioPlayer seeked backward 10 seconds"
            end if
        else if (key = "right")
            if m.itemLive <> "true"
                ' Seek forward 10 seconds
                newPosition = m.audio.position + 10
                if newPosition > m.audio.duration then newPosition = m.audio.duration
                m.audio.seek = newPosition
                print "SeedrAudioPlayer seeked forward 10 seconds"
            end if
        else if (key = "play")
            print "[SeedrAudioPlayer] Play/Pause key pressed, current state: "; m.audio.state
            if m.audio.state = "playing"
                print "[SeedrAudioPlayer] Pausing audio"
                m.audio.control = "pause"
            else if m.audio.state = "paused"
                print "[SeedrAudioPlayer] Resuming audio"
                m.audio.control = "resume"
            else if m.audio.state = "stopped" or m.audio.state = "finished"
                print "[SeedrAudioPlayer] Starting audio playback"
                m.audio.control = "play"
            end if
            handled = true

        else if (key = "fastforward")
            ' Play next file in folder
            playNextFile()
            handled = true

        else if (key = "rewind")
            ' Play previous file in folder
            playPreviousFile()
            handled = true

        else if (key = "OK")
            print "[SeedrAudioPlayer] OK button pressed - Play/Pause toggle"
            ' Use OK button as play/pause toggle
            if m.audio.state = "playing"
                print "[SeedrAudioPlayer] OK: Pausing audio"
                m.audio.control = "pause"
            else if m.audio.state = "paused"
                print "[SeedrAudioPlayer] OK: Resuming audio"
                m.audio.control = "resume"
            else if m.audio.state = "stopped" or m.audio.state = "finished"
                print "[SeedrAudioPlayer] OK: Starting audio playback"
                m.audio.control = "play"
            end if
            handled = true

        else if (key = "*")
            print "[SeedrAudioPlayer] * key pressed - Previous track"
            playPreviousFile()
            handled = true

        else if (key = "#")
            print "[SeedrAudioPlayer] # key pressed - Next track"
            playNextFile()
            handled = true
        end if
    end if
    return handled
end function


sub onAuthorRender()

    if m.itemAuthorGroup.renderTracking = "none"
        m.authorAnimation.control = "start"
    end if

end sub

sub onAlbumRender()

    if m.itemAlbumInfoGroup.renderTracking = "none"
        m.albumAnimation.control = "start"
    end if

end sub

sub onSongNameRender()

    if m.itemSongGroup.renderTracking = "none"
        m.songAnimation.control = "start"
    end if

end sub

sub onItemContent()
    print "SeedrAudioPlayer " ; "onItemContent()"

    itemcontent = m.top.itemContent

    m.itemAuthor.text = itemcontent.actors
    m.itemAlbumInfo.text = itemcontent.album
    m.itemSongName.text = itemcontent.title
    m.itemPoster.uri = itemcontent.HDPosterUrl
    m.itemLive = itemcontent.Rating

    if m.itemLive = "true"
        m.itemRepeat.visible = false
    else
        m.itemRepeat.visible = true
    end if

    stopingLblAnimation()
    resetLblTranslation()

    ' Create proper audio content for the audio node
    audioContent = CreateObject("roSGNode", "ContentNode")
    audioContent.url = itemcontent.url
    audioContent.streamFormat = itemcontent.streamFormat
    audioContent.title = itemcontent.title

    print "[SeedrAudioPlayer] Audio content details:"
    print "[SeedrAudioPlayer] - URL: "; audioContent.url
    print "[SeedrAudioPlayer] - Stream Format: "; audioContent.streamFormat
    print "[SeedrAudioPlayer] - Title: "; audioContent.title

    ' Load new content and start playing immediately
    m.audio.content = audioContent
    m.audio.control = "play"
    print "SeedrAudioPlayer started playing new content: " + itemcontent.title

    m.timer.control = "start"

end sub

' Set the current folder files for next/previous navigation
sub setCurrentFolderFiles(folderFiles as object, currentIndex as integer, folderId as string)
    m.currentFolderFiles = folderFiles
    m.currentFileIndex = currentIndex
    m.currentFolderId = folderId
    print "[SeedrAudioPlayer] Set folder files: "; folderFiles.Count(); " files, current index: "; currentIndex
end sub

' Play next file in folder
sub playNextFile()
    print "[SeedrAudioPlayer] playNextFile() called"
    print "[SeedrAudioPlayer] Current folder files count: "; m.currentFolderFiles.Count()
    print "[SeedrAudioPlayer] Current file index: "; m.currentFileIndex
    print "[SeedrAudioPlayer] Max index: "; (m.currentFolderFiles.Count() - 1)

    if m.currentFolderFiles.Count() > 0 and m.currentFileIndex < m.currentFolderFiles.Count() - 1 then
        m.currentFileIndex = m.currentFileIndex + 1
        print "[SeedrAudioPlayer] Moving to next track, new index: "; m.currentFileIndex
        playFileAtIndex(m.currentFileIndex)
    else
        print "[SeedrAudioPlayer] No next file available - reached end of playlist or no files"
    end if
end sub

' Play previous file in folder
sub playPreviousFile()
    if m.currentFolderFiles.Count() > 0 and m.currentFileIndex > 0 then
        m.currentFileIndex = m.currentFileIndex - 1
        playFileAtIndex(m.currentFileIndex)
    else
        print "[SeedrAudioPlayer] No previous file available"
    end if
end sub

' Play file at specific index - REWRITTEN for independent operation
sub playFileAtIndex(index as integer)
    print "[SeedrAudioPlayer] ========== PLAY FILE AT INDEX =========="
    print "[SeedrAudioPlayer] playFileAtIndex() called with index: "; index
    print "[SeedrAudioPlayer] Folder files count: "; m.currentFolderFiles.Count()

    ' Validate index
    if m.currentFolderFiles.Count() = 0 or index < 0 or index >= m.currentFolderFiles.Count() then
        print "[SeedrAudioPlayer] ERROR: Invalid index or no files. Index: "; index; ", Count: "; m.currentFolderFiles.Count()
        return
    end if

    ' Validate access token
    if m.accessToken = invalid or m.accessToken = "" then
        print "[SeedrAudioPlayer] ERROR: No access token available - cannot fetch stream URL"
        m.itemAuthor.text = "Error: No access token"
        m.itemAlbumInfo.text = "Cannot switch tracks"
        return
    end if

    ' Get file item from playlist
    fileItem = m.currentFolderFiles[index]
    if fileItem = invalid then
        print "[SeedrAudioPlayer] ERROR: File item at index "; index; " is invalid"
        return
    end if

    print "[SeedrAudioPlayer] ✅ Switching to track: "; fileItem.title
    print "[SeedrAudioPlayer] ✅ File ID: "; fileItem.fileId
    print "[SeedrAudioPlayer] ✅ STAYING ON AUDIO PLAYER SCREEN"

    ' Store pending file info for when stream URL arrives
    m.pendingFileItem = fileItem
    m.pendingFileIndex = index

    ' Show loading state in UI
    m.itemAuthor.text = "Loading next track..."
    m.itemAlbumInfo.text = "Please wait..."

    ' Request stream URL using StreamUrlTask
    if m.streamUrlTask <> invalid then
        ' Ensure fileId is string to avoid scientific notation
        fileIdStr = ""
        if Type(fileItem.fileId) = "roString" or Type(fileItem.fileId) = "String" then
            fileIdStr = fileItem.fileId
        else
            fileIdStr = fileItem.fileId.ToStr()
        end if

        m.streamUrlTask.fileId = fileIdStr
        m.streamUrlTask.accessToken = m.accessToken
        m.streamUrlTask.isAudio = true
        m.streamUrlTask.control = "RUN"

        print "[SeedrAudioPlayer] Stream URL request sent for file ID: "; fileIdStr
        print "[SeedrAudioPlayer] Waiting for stream URL response..."
    else
        print "[SeedrAudioPlayer] ERROR: StreamUrlTask is invalid"
        m.itemAuthor.text = "Error: StreamUrlTask failed"
        m.itemAlbumInfo.text = "Cannot switch tracks"
    end if
    print "[SeedrAudioPlayer] ========================================"
end sub

' Handle stream URL response - NEW FUNCTION
sub onStreamUrlReceived()
    print "[SeedrAudioPlayer] ========== STREAM URL RECEIVED =========="
    streamUrl = m.streamUrlTask.streamUrl
    print "[SeedrAudioPlayer] Stream URL received: "; Left(streamUrl, 60); "..."

    if streamUrl = invalid or streamUrl = "" then
        print "[SeedrAudioPlayer] ERROR: Invalid stream URL"
        m.itemAuthor.text = "Error: Invalid stream URL"
        m.itemAlbumInfo.text = "Cannot play track"
        return
    end if

    if m.pendingFileItem = invalid then
        print "[SeedrAudioPlayer] ERROR: No pending file item"
        return
    end if

    ' Update current file index
    m.currentFileIndex = m.pendingFileIndex

    ' Detect stream format from filename
    streamFormat = detectStreamFormat(m.pendingFileItem.title)

    ' Create new audio content
    audioContent = CreateObject("roSGNode", "ContentNode")
    audioContent.url = streamUrl
    audioContent.title = m.pendingFileItem.title
    audioContent.streamFormat = streamFormat

    print "[SeedrAudioPlayer] ✅ Starting playback of: "; m.pendingFileItem.title
    print "[SeedrAudioPlayer] ✅ Stream format: "; streamFormat
    print "[SeedrAudioPlayer] ✅ Track "; (m.currentFileIndex + 1); " of "; m.currentFolderFiles.Count()

    ' Stop current playback completely and clear content
    m.audio.control = "stop"
    m.audio.content = invalid
    print "[SeedrAudioPlayer] Stopped and cleared previous track"

    ' Load new content
    m.audio.content = audioContent
    print "[SeedrAudioPlayer] New content loaded"

    ' Set loop to false
    m.audio.loop = false

    ' Start playback
    m.audio.control = "play"

    print "[SeedrAudioPlayer] ▶️ PLAY COMMAND SENT - Audio should start automatically now"

    ' Update UI with new track info
    m.itemSongName.text = m.pendingFileItem.title
    m.itemAuthor.text = "" ' Reset to empty (or extract from metadata if available)
    m.itemAlbumInfo.text = "" ' Reset to empty (or extract from metadata if available)

    ' Reset label animations for new track
    stopingLblAnimation()
    resetLblTranslation()

    ' Update current track info for global access
    m.top.currentTrackInfo = {
        title: m.pendingFileItem.title
        artist: ""
        album: ""
        isPlaying: true
        isPaused: false
        currentIndex: m.currentFileIndex
        totalTracks: m.currentFolderFiles.Count()
    }

    ' Clear pending item
    m.pendingFileItem = invalid

    print "[SeedrAudioPlayer] ✅✅✅ TRACK SWITCHED SUCCESSFULLY - STILL ON AUDIO PLAYER SCREEN ✅✅✅"
    print "[SeedrAudioPlayer] ========================================"
end sub

' Handle stream URL errors - NEW FUNCTION
sub onStreamUrlError()
    print "[SeedrAudioPlayer] ========== STREAM URL ERROR =========="
    errorMsg = m.streamUrlTask.error
    if errorMsg = invalid or errorMsg = "" then
        errorMsg = "Unknown error"
    end if
    print "[SeedrAudioPlayer] Stream URL error: "; errorMsg

    ' Show error in UI
    m.itemAuthor.text = "Error loading track"
    m.itemAlbumInfo.text = errorMsg

    ' Clear pending item
    m.pendingFileItem = invalid

    print "[SeedrAudioPlayer] ========================================"
end sub

' Helper function to detect stream format from filename - NEW FUNCTION
function detectStreamFormat(fileName as string) as string
    if fileName = invalid or fileName = "" then
        print "[SeedrAudioPlayer] No filename provided, defaulting to mp3"
        return "mp3"
    end if

    lowerFileName = LCase(fileName)

    if InStr(1, lowerFileName, ".flac") > 0 then
        print "[SeedrAudioPlayer] Detected FLAC format"
        return "flac"
    else if InStr(1, lowerFileName, ".mp3") > 0 then
        print "[SeedrAudioPlayer] Detected MP3 format"
        return "mp3"
    else if InStr(1, lowerFileName, ".wav") > 0 then
        print "[SeedrAudioPlayer] Detected WAV format"
        return "wav"
    else if InStr(1, lowerFileName, ".aac") > 0 then
        print "[SeedrAudioPlayer] Detected AAC format"
        return "aac"
    else if InStr(1, lowerFileName, ".m4a") > 0 then
        print "[SeedrAudioPlayer] Detected M4A format"
        return "aac"
    else if InStr(1, lowerFileName, ".ogg") > 0 then
        print "[SeedrAudioPlayer] Detected OGG format"
        return "ogg"
    else
        print "[SeedrAudioPlayer] Unknown format, defaulting to mp3"
        return "mp3"
    end if
end function

sub onTimerFire()
    if m.itemAuthorGroup.renderTracking = "partial"
        m.authorAnimation.control = "start"
    end if

    if m.itemAlbumInfoGroup.renderTracking = "partial"
        m.albumAnimation.control = "start"
    end if

    if m.itemSongGroup.renderTracking = "partial"
        m.songAnimation.control = "start"
    end if

end sub

' Auto-next timer fired - play next track
sub onAutoNextTimerFire()
    print "[SeedrAudioPlayer] ⏱️ 3-second delay complete - Playing next track now"

    ' Stop the timer
    if m.autoNextTimer <> invalid then
        m.autoNextTimer.control = "stop"
    end if

    ' Play next file
    playNextFile()
end sub

sub resetLblTranslation()
    print "SeedrAudioPlayer " ; "resetLblTranslation()"
    m.itemAuthorGroup.translation = [0, 0]
    m.itemAlbumInfoGroup.translation = [0, 0]
    m.itemSongGroup.translation = [0, 0]

end sub

sub stopingLblAnimation()
    print "SeedrAudioPlayer " ; "stopingLblAnimation()"
    m.authorAnimation.control = "stop"
    m.albumAnimation.control = "stop"
    m.songAnimation.control = "stop"

end sub

sub onPlayerState()
    print "[SeedrAudioPlayer] Audio state changed to: "; m.audio.state

    if m.audio.state = "playing"
        print "[SeedrAudioPlayer] Audio is now playing"
        m.itemPlayStatePoster.uri = "pkg:/images/button_pause.png"
        m.top.isGloballyPlaying = true

        ' Store that we started playing (for detecting natural end)
        m.wasPlaying = true

        ' Update current track info for global access
        m.top.currentTrackInfo = {
            title: m.itemSongName.text
            artist: m.itemAuthor.text
            album: m.itemAlbumInfo.text
            isPlaying: true
            isPaused: false
            currentIndex: m.currentFileIndex
            totalTracks: m.currentFolderFiles.Count()
        }

    else if m.audio.state = "stopped"
        print "[SeedrAudioPlayer] Audio is stopped"

        ' Check if this is a natural end of track (position near duration)
        ' or a manual stop (position far from duration)
        isNaturalEnd = false
        if m.audio.duration > 0 and m.audio.position > 0 and m.wasPlaying = true then
            ' If we're within 3 seconds of the end, consider it a natural end
            timeRemaining = m.audio.duration - m.audio.position
            print "[SeedrAudioPlayer] Track stopped - Position: "; m.audio.position; " Duration: "; m.audio.duration; " Remaining: "; timeRemaining

            if timeRemaining <= 3 or m.audio.position >= m.audio.duration then
                isNaturalEnd = true
                print "[SeedrAudioPlayer] ✅ DETECTED NATURAL END OF TRACK - Auto-playing next"
            end if
        end if

        if isNaturalEnd then
            ' Treat as track finished - auto-play next with 3 second delay
            m.top.isGloballyPlaying = false

            if m.replay = true then
                print "[SeedrAudioPlayer] Replay mode - restarting current track"
                m.audio.control = "play"
            else
                ' Auto-play next track after 3 second delay
                print "[SeedrAudioPlayer] ⏱️ Track ended naturally - Starting 3 second delay before next track"
                print "[SeedrAudioPlayer] Current index: "; m.currentFileIndex; " Total files: "; m.currentFolderFiles.Count()

                ' Show "Next track in 3 seconds..." message
                m.itemAuthor.text = "Next track in 3 seconds..."
                m.itemAlbumInfo.text = ""

                ' Start 3 second timer
                if m.autoNextTimer <> invalid then
                    m.autoNextTimer.control = "start"
                    print "[SeedrAudioPlayer] ⏱️ 3-second timer started"
                else
                    ' Fallback if timer invalid - play immediately
                    print "[SeedrAudioPlayer] WARNING: Timer invalid, playing next immediately"
                    playNextFile()
                end if
            end if
            m.itemPlayStatePoster.uri = "pkg:/images/button_play.png"
        else
            ' Manual stop - just update UI
            print "[SeedrAudioPlayer] Manual stop detected"
            m.itemPlayStatePoster.uri = "pkg:/images/button_play.png"
            m.top.isGloballyPlaying = false

            ' Update current track info
            if m.top.currentTrackInfo <> invalid then
                m.top.currentTrackInfo.isPlaying = false
                m.top.currentTrackInfo.isPaused = false
            end if
        end if

        ' Reset playing flag
        m.wasPlaying = false

    else if m.audio.state = "paused"
        print "[SeedrAudioPlayer] Audio is paused"
        m.itemPlayStatePoster.uri = "pkg:/images/button_play.png"
        m.top.isGloballyPlaying = false

        ' Update current track info
        if m.top.currentTrackInfo <> invalid then
            m.top.currentTrackInfo.isPlaying = false
            m.top.currentTrackInfo.isPaused = true
        end if

    else if m.audio.state = "finished"
        print "[SeedrAudioPlayer] Audio playback finished (finished state)"
        m.top.isGloballyPlaying = false

        if m.replay = true
            print "[SeedrAudioPlayer] Replay mode - restarting current track"
            m.audio.control = "play"
        else
            ' Auto-play next track after 3 second delay
            print "[SeedrAudioPlayer] ⏱️ Track finished - Starting 3 second delay before next track"
            print "[SeedrAudioPlayer] Current index: "; m.currentFileIndex; " Total files: "; m.currentFolderFiles.Count()

            ' Show "Next track in 3 seconds..." message
            m.itemAuthor.text = "Next track in 3 seconds..."
            m.itemAlbumInfo.text = ""

            ' Start 3 second timer
            if m.autoNextTimer <> invalid then
                m.autoNextTimer.control = "start"
                print "[SeedrAudioPlayer] ⏱️ 3-second timer started"
            else
                ' Fallback if timer invalid - play immediately
                print "[SeedrAudioPlayer] WARNING: Timer invalid, playing next immediately"
                playNextFile()
            end if
        end if
        m.itemPlayStatePoster.uri = "pkg:/images/button_play.png"
        m.wasPlaying = false

    else if m.audio.state = "error"
        print "[SeedrAudioPlayer] Audio playback error: "; m.audio.errorMsg
        m.itemAuthor.text = m.audio.errorMsg
        m.itemAlbumInfo.text = m.audio.errorMsg
        m.top.isGloballyPlaying = false
        m.wasPlaying = false

    else if m.audio.state = "buffering"
        print "[SeedrAudioPlayer] Audio is buffering"
    else
        print "[SeedrAudioPlayer] Unknown audio state: "; m.audio.state
    end if

end sub

sub onPlayerPosition()
    if m.itemLive <> "true"

        m.itemLenght.text = calulateMinDuration(m.audio.duration)
        m.itemCurPosition.text = calulatePositionMin(m.audio.position)
        m.itemCurPosition.visible = true

        if m.audio.duration > 0 then
            ' Progress bar updates removed to avoid field errors
            ' ProgressBar nodes don't support dynamic progress updates in this version
        else
            ' No progress bar update needed
        end if
    else
        m.itemCurPosition.visible = false
        m.itemLenght.text = "LIVE"
    end if

end sub

sub onFocus()

    if m.top.hasFocus()
        m.backgroundPoster.blendColor = "0xd7d7d7"
        m.itemFramePoster.visible = "true"
    else
        m.backgroundPoster.blendColor = "0xFFFFFFFF"
        m.itemFramePoster.visible = "false"
    end if

end sub

function calulateMinDuration(duration)
    seconds = duration mod 60
    minutes = int(duration / 60)

    durationString = Str(minutes) + ":" + Str(seconds)

    return durationString

end function

function calulatePositionMin(position)
    seconds = position mod 60
    minutes = int(position / 60)

    positionString = Str(minutes) + ":" + Str(seconds)

    return positionString
end function

function divider(duration)
    percent = (duration / 100) * 5

    return percent
end function
