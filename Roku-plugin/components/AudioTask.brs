' ********** Audio Task for Audio Playback **********

sub init()
    print "[AudioTask] Initializing..."
    m.top.functionName = "audioTaskLoop"
    m.audioPlayer = invalid
    m.port = CreateObject("roMessagePort")
end sub

sub audioTaskLoop()
    print "[AudioTask] Audio task loop started"
    m.startupTimeout = 0

    ' Main loop to handle audio commands
    while true
        msg = wait(100, m.port) ' Wait for messages

        ' Check for command changes
        if m.top.command <> invalid and m.top.command <> "" then
            handleCommand(m.top.command)
            m.top.command = "" ' Clear command after processing
            m.startupTimeout = 0 ' Reset timeout on new command
        end if

        ' Update position if audio is playing
        if m.audioPlayer <> invalid then
            updatePosition()

            ' Check for startup timeout (30 seconds)
            if m.top.isPlaying and m.startupTimeout < 300 then
                m.startupTimeout = m.startupTimeout + 1
            else if m.startupTimeout >= 300 then
                print "[AudioTask] Startup timeout reached - trying alternative approach"
                tryAlternativePlayback()
                m.startupTimeout = 0
            end if
        end if
    end while
end sub

sub handleCommand(command as string)
    print "[AudioTask] Handling command: "; command

    if command = "play" then
        playAudio()
    else if command = "pause" then
        pauseAudio()
    else if command = "resume" then
        resumeAudio()
    else if command = "stop" then
        stopAudio()
    else if command = "seek" then
        seekAudio()
    end if
end sub

sub playAudio()
    if m.top.audioUrl <> invalid and m.top.audioUrl <> "" then
        print "[AudioTask] Starting audio playback: "; m.top.audioUrl

        ' Create audio player if not exists
        if m.audioPlayer = invalid then
            m.audioPlayer = CreateObject("roAudioPlayer")
            m.audioPlayer.SetMessagePort(m.port)
            print "[AudioTask] Created new roAudioPlayer"
        end if

        ' Clear any existing content
        m.audioPlayer.ClearContent()
        print "[AudioTask] Cleared existing content"

        ' Create content item - ignore file extension, focus on stream content
        contentItem = CreateObject("roAssociativeArray")
        contentItem["url"] = m.top.audioUrl
        contentItem["title"] = "Audio Stream"

        ' Always try as MP3 format - this tricks Roku into attempting playback
        ' The actual codec detection happens at the stream level, not filename
        contentItem["streamFormat"] = "mp3"

        if m.top.audioUrl.InStr(".flac") > 0 then
            print "[AudioTask] FLAC file - forcing MP3 format hint to bypass Roku format filtering"
        else
            print "[AudioTask] Audio file - using MP3 format hint"
        end if

        print "[AudioTask] Created content item with URL: "; m.top.audioUrl

        ' Add content to player
        m.audioPlayer.AddContent(contentItem)
        m.audioPlayer.SetLoop(false)
        print "[AudioTask] Added content to player"

        ' Start playback
        if m.audioPlayer.Play() then
            m.top.isPlaying = true
            print "[AudioTask] Audio playback started successfully"
        else
            m.top.error = "Failed to start audio playback"
            print "[AudioTask] ERROR: Failed to start audio playback"
            print "[AudioTask] Attempting alternative approach..."

            ' Try alternative approach - maybe FLAC needs different handling
            tryAlternativePlayback()
        end if
    else
        m.top.error = "No audio URL provided"
        print "[AudioTask] ERROR: No audio URL provided"
    end if
end sub

sub tryAlternativePlayback()
    print "[AudioTask] Trying alternative audio playback approach..."
    print "[AudioTask] Forcing raw stream playback - ignoring all format hints"

    ' Try recreating the audio player completely
    m.audioPlayer = invalid
    m.audioPlayer = CreateObject("roAudioPlayer")
    m.audioPlayer.SetMessagePort(m.port)

    ' Try with absolutely no format specification - pure stream URL
    contentItem = CreateObject("roAssociativeArray")
    contentItem["url"] = m.top.audioUrl
    contentItem["title"] = "Raw Audio Stream"
    ' No streamFormat at all - let Roku's codec detection handle everything

    print "[AudioTask] Attempting raw stream playback with no format hints"
    m.audioPlayer.AddContent(contentItem)

    if m.audioPlayer.Play() then
        m.top.isPlaying = true
        print "[AudioTask] Raw stream playback started successfully!"
    else
        print "[AudioTask] Raw stream approach failed - trying one more approach"

        ' Last resort: try with different format hints
        m.audioPlayer = invalid
        m.audioPlayer = CreateObject("roAudioPlayer")
        m.audioPlayer.SetMessagePort(m.port)

        contentItem = CreateObject("roAssociativeArray")
        contentItem["url"] = m.top.audioUrl
        contentItem["title"] = "Audio Stream"
        contentItem["streamFormat"] = "wav" ' Try WAV format hint

        m.audioPlayer.AddContent(contentItem)

        if m.audioPlayer.Play() then
            m.top.isPlaying = true
            print "[AudioTask] WAV format hint worked!"
        else
            print "[AudioTask] All alternative approaches failed"
            m.top.error = "Stream format not supported"
            print "[AudioTask] ERROR: This audio stream cannot be played on this Roku device"
        end if
    end if
end sub

sub pauseAudio()
    if m.audioPlayer <> invalid then
        if m.audioPlayer.Pause() then
            m.top.isPlaying = false
            print "[AudioTask] Audio paused"
        else
            m.top.error = "Failed to pause audio"
            print "[AudioTask] ERROR: Failed to pause audio"
        end if
    end if
end sub

sub resumeAudio()
    if m.audioPlayer <> invalid then
        if m.audioPlayer.Resume() then
            m.top.isPlaying = true
            print "[AudioTask] Audio resumed"
        else
            m.top.error = "Failed to resume audio"
            print "[AudioTask] ERROR: Failed to resume audio"
        end if
    end if
end sub

sub stopAudio()
    if m.audioPlayer <> invalid then
        if m.audioPlayer.Stop() then
            m.top.isPlaying = false
            m.top.currentPosition = 0
            print "[AudioTask] Audio stopped"
        else
            m.top.error = "Failed to stop audio"
            print "[AudioTask] ERROR: Failed to stop audio"
        end if
    end if
end sub

sub seekAudio()
    if m.audioPlayer <> invalid and m.top.seekPosition >= 0 then
        ' Note: roAudioPlayer doesn't support seeking directly
        ' This is a placeholder for future enhancement
        print "[AudioTask] Seek requested to position: "; m.top.seekPosition
        m.top.currentPosition = m.top.seekPosition
    end if
end sub

sub updatePosition()
    ' Get current position from audio player
    ' Note: roAudioPlayer has limited position reporting
    ' This is a basic implementation
    if m.audioPlayer <> invalid and m.top.isPlaying then
        ' Increment position (rough estimate)
        m.top.currentPosition = m.top.currentPosition + 1

        ' Check for audio player messages
        msg = m.port.GetMessage()
        if msg <> invalid then
            msgType = type(msg)
            if msgType = "roAudioPlayerEvent" then
                if msg.isListItemSelected() then
                    print "[AudioTask] Audio item selected"
                else if msg.isStatusMessage() then
                    status = msg.getMessage()
                    print "[AudioTask] Audio status: "; status
                    if status = "startup progress" then
                        ' Still loading - this is normal for large files
                        print "[AudioTask] Audio still loading..."
                    else if status = "start of play" then
                        print "[AudioTask] Audio playback actually started!"
                        m.top.isPlaying = true
                    else if status = "Content contains no playable tracks." then
                        print "[AudioTask] FLAC format not supported - trying alternative approach"
                        m.top.error = "FLAC format not supported by Roku"
                        m.top.isPlaying = false
                        ' Try alternative approach immediately
                        tryAlternativePlayback()
                    else if status = "end of playlist" then
                        ' For FLAC files, "end of playlist" might happen immediately due to format issues
                        if m.top.audioUrl.InStr(".flac") > 0 then
                            print "[AudioTask] FLAC end of playlist - this might be a format compatibility issue"
                            print "[AudioTask] FLAC streams may not be fully supported on this Roku device"
                            m.top.error = "FLAC format has limited Roku support"
                        else
                            print "[AudioTask] Audio playback ended normally"
                        end if
                        m.top.isPlaying = false
                        m.top.currentPosition = 0
                    else if status = "failed" then
                        m.top.error = "Audio playback failed"
                        m.top.isPlaying = false
                        print "[AudioTask] ERROR: Audio playback failed"
                    end if
                else if msg.isStreamStarted() then
                    print "[AudioTask] Audio stream started successfully!"
                    m.top.isPlaying = true
                else if msg.isFullResult() then
                    print "[AudioTask] Audio full result received"
                else if msg.isPartialResult() then
                    print "[AudioTask] Audio partial result received"
                end if
            end if
        end if
    end if
end sub
