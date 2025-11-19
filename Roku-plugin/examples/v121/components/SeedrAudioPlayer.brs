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

    m.timer.observeField("fire", "onTimerFire")

    m.top.observeField("itemContent", "onItemContent")
    m.top.observeField("focusedChild", "onFocus")
    m.top.observeField("onBackPressed", "onBackPressedChanged")
    m.top.observeField("playNextFile", "onPlayNextFile")
    m.top.observeField("setCurrentFolderFiles", "onSetCurrentFolderFiles")
    m.top.observeField("globalAudioCommand", "onGlobalAudioCommand")

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

' Play file at specific index
sub playFileAtIndex(index as integer)
    print "[SeedrAudioPlayer] playFileAtIndex() called with index: "; index
    print "[SeedrAudioPlayer] Folder files count: "; m.currentFolderFiles.Count()

    if m.currentFolderFiles.Count() > 0 and index >= 0 and index < m.currentFolderFiles.Count() then
        fileItem = m.currentFolderFiles[index]
        if fileItem <> invalid then
            print "[SeedrAudioPlayer] Playing file at index "; index; ": "; fileItem.title
            print "[SeedrAudioPlayer] File ID: "; fileItem.fileId

            ' Find HeroMainScene (grandparent) instead of direct parent (Group)
            parentNode = m.top.getParent()
            heroMainScene = invalid

            if parentNode <> invalid then
                ' Check if parent is HeroMainScene
                if parentNode.subtype() = "HeroMainScene" then
                    heroMainScene = parentNode
                else
                    ' Try grandparent
                    grandParent = parentNode.getParent()
                    if grandParent <> invalid and grandParent.subtype() = "HeroMainScene" then
                        heroMainScene = grandParent
                    end if
                end if
            end if

            if heroMainScene <> invalid then
                print "[SeedrAudioPlayer] Found HeroMainScene, signaling background playback"
                heroMainScene.playVideo = {
                    fileId: fileItem.fileId,
                    title: fileItem.title,
                    fileData: fileItem.fileData,
                    isAudio: true,
                    isBackgroundPlayback: true ' Flag to indicate this is background track change
                }
                print "[SeedrAudioPlayer] Signaled HeroMainScene to play next file in background"
            else
                print "[SeedrAudioPlayer] ERROR: Could not find HeroMainScene to signal playback"
            end if
        else
            print "[SeedrAudioPlayer] ERROR: File item at index "; index; " is invalid"
        end if
    else
        print "[SeedrAudioPlayer] ERROR: Invalid index or no files. Index: "; index; ", Count: "; m.currentFolderFiles.Count()
    end if
end sub

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

    else if m.audio.state = "stopped" or m.audio.state = "paused"
        print "[SeedrAudioPlayer] Audio is stopped/paused"
        m.itemPlayStatePoster.uri = "pkg:/images/button_play.png"
        m.top.isGloballyPlaying = false

        ' Update current track info
        if m.top.currentTrackInfo <> invalid then
            m.top.currentTrackInfo.isPlaying = false
            m.top.currentTrackInfo.isPaused = (m.audio.state = "paused")
        end if

    else if m.audio.state = "finished"
        print "[SeedrAudioPlayer] Audio playback finished"
        m.top.isGloballyPlaying = false

        if m.replay = true
            m.audio.control = "play"
        else
            ' Auto-play next track if not in repeat mode
            print "[SeedrAudioPlayer] Attempting auto-next. Current index: "; m.currentFileIndex; " Total files: "; m.currentFolderFiles.Count()
            playNextFile()
        end if
        m.itemPlayStatePoster.uri = "pkg:/images/button_play.png"

    else if m.audio.state = "error"
        print "[SeedrAudioPlayer] Audio playback error: "; m.audio.errorMsg
        m.itemAuthor.text = m.audio.errorMsg
        m.itemAlbumInfo.text = m.audio.errorMsg
        m.top.isGloballyPlaying = false

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
