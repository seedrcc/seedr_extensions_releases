' ********** AudioPlayer Component **********

sub init()
    print "[AUDIOPLAYER] AudioPlayer component initialized"

    ' Get references to UI elements
    m.background = m.top.findNode("background")
    m.trackTitleLabel = m.top.findNode("trackTitleLabel")
    m.artistLabel = m.top.findNode("artistLabel")
    m.albumLabel = m.top.findNode("albumLabel")
    m.albumArtPoster = m.top.findNode("albumArtPoster")
    m.musicIconGroup = m.top.findNode("musicIconGroup")
    m.progressFill = m.top.findNode("progressFill")
    m.progressTimeLabel = m.top.findNode("progressTimeLabel")
    m.playLabel = m.top.findNode("playLabel")
    m.timeLabel = m.top.findNode("timeLabel")

    ' Set up observers
    m.top.observeField("fileName", "onFileNameChanged")
    m.top.observeField("albumArt", "onAlbumArtChanged")
    m.top.observeField("artist", "onArtistChanged")
    m.top.observeField("album", "onAlbumChanged")
    m.top.observeField("isPlaying", "onPlayStateChanged")
    m.top.observeField("currentTime", "onTimeChanged")
    m.top.observeField("audioContent", "onAudioContentChanged")

    ' Create audio task for actual playback
    m.audioTask = CreateObject("roSGNode", "AudioTask")
    m.audioTask.observeField("isPlaying", "onAudioTaskPlayingChanged")
    m.audioTask.observeField("currentPosition", "onAudioTaskPositionChanged")
    m.audioTask.observeField("error", "onAudioTaskError")

    ' Start progress timer
    m.progressTimer = CreateObject("roTimespan")
    m.progressTimer.mark()
    m.startTime = CreateObject("roDateTime").AsSeconds()

    ' Set up key handling
    m.top.setFocus(true)

    ' Update current time display
    updateCurrentTime()

    ' Start update loop
    m.updateTimer = m.top.createChild("Timer")
    m.updateTimer.repeat = true
    m.updateTimer.duration = 1.0
    m.updateTimer.observeField("fire", "onUpdateTimer")
    m.updateTimer.control = "start"
end sub

sub onFileNameChanged()
    if m.trackTitleLabel <> invalid then
        m.trackTitleLabel.text = m.top.fileName
        print "[AUDIOPLAYER] Track title set to: " + m.top.fileName
    end if
end sub

sub onAlbumArtChanged()
    if m.top.albumArt <> invalid and m.top.albumArt <> "" then
        print "[AUDIOPLAYER] Setting album art: " + m.top.albumArt
        m.albumArtPoster.uri = m.top.albumArt
        m.albumArtPoster.visible = true
        m.musicIconGroup.visible = false
    else
        print "[AUDIOPLAYER] No album art, showing music icon"
        m.albumArtPoster.visible = false
        m.musicIconGroup.visible = true
    end if
end sub

sub onArtistChanged()
    if m.artistLabel <> invalid then
        m.artistLabel.text = m.top.artist
        print "[AUDIOPLAYER] Artist set to: " + m.top.artist
    end if
end sub

sub onAlbumChanged()
    if m.albumLabel <> invalid then
        m.albumLabel.text = m.top.album
        print "[AUDIOPLAYER] Album set to: " + m.top.album
    end if
end sub

sub onPlayStateChanged()
    if m.playLabel <> invalid then
        if m.top.isPlaying then
            m.playLabel.text = "⏸" ' Pause icon when playing
            print "[AUDIOPLAYER] Play state: Playing"
        else
            m.playLabel.text = "▶" ' Play icon when paused
            print "[AUDIOPLAYER] Play state: Paused"
        end if
    end if
end sub

sub onTimeChanged()
    updateProgressBar()
end sub

sub onAudioContentChanged()
    audioContent = m.top.audioContent
    if audioContent <> invalid and audioContent.url <> invalid then
        print "[AUDIOPLAYER] Starting audio playback: "; audioContent.url

        ' Set up audio task
        m.audioTask.audioUrl = audioContent.url
        m.audioTask.command = "play"
        m.audioTask.control = "RUN"

        print "[AUDIOPLAYER] Audio task started"
    end if
end sub

sub onAudioTaskPlayingChanged()
    ' Update UI based on audio task playing state
    m.top.isPlaying = m.audioTask.isPlaying
    print "[AUDIOPLAYER] Audio task playing state changed: "; m.audioTask.isPlaying
end sub

sub onAudioTaskPositionChanged()
    ' Update current time based on audio task position
    m.top.currentTime = m.audioTask.currentPosition
end sub

sub onAudioTaskError()
    errorMsg = m.audioTask.error
    if errorMsg <> invalid and errorMsg <> "" then
        print "[AUDIOPLAYER] Audio task error: "; errorMsg

        ' Update UI to show FLAC limitation message
        if errorMsg.InStr("FLAC") > 0 then
            if m.trackTitleLabel <> invalid then
                m.trackTitleLabel.text = "FLAC Format Not Supported"
            end if
            if m.artistLabel <> invalid then
                m.artistLabel.text = "This Roku device has limited FLAC codec support"
            end if
            if m.albumLabel <> invalid then
                m.albumLabel.text = "Stream URL is valid - Format compatibility issue"
            end if
        end if
    end if
end sub

sub onUpdateTimer()
    ' Update elapsed time
    currentTime = CreateObject("roDateTime").AsSeconds()
    elapsed = currentTime - m.startTime
    m.top.currentTime = elapsed

    ' Update current time display
    updateCurrentTime()
end sub

sub updateProgressBar()
    if m.progressFill <> invalid and m.progressTimeLabel <> invalid then
        elapsed = m.top.currentTime
        duration = m.top.duration

        ' Calculate progress percentage
        if duration > 0 then
            progressPercent = elapsed / duration
            if progressPercent > 1 then progressPercent = 1
        else
            progressPercent = 0
        end if

        ' Update progress bar width
        progressBarWidth = 1120
        fillWidth = progressBarWidth * progressPercent
        m.progressFill.width = fillWidth

        ' Format time strings
        elapsedMin = elapsed / 60
        elapsedSec = elapsed - (elapsedMin * 60)
        elapsedStr = formatTime(elapsedMin, elapsedSec)

        durationMin = duration / 60
        durationSec = duration - (durationMin * 60)
        durationStr = formatTime(durationMin, durationSec)

        ' Update time display
        m.progressTimeLabel.text = elapsedStr + " / " + durationStr
    end if
end sub

sub updateCurrentTime()
    if m.timeLabel <> invalid then
        now = CreateObject("roDateTime")
        hours = now.getHours()
        minutes = now.getMinutes()

        ' Format 12-hour time
        ampm = "AM"
        if hours >= 12 then
            ampm = "PM"
            if hours > 12 then hours = hours - 12
        end if
        if hours = 0 then hours = 12

        timeStr = Str(hours) + ":" + Right("0" + Str(minutes), 2) + " " + ampm
        m.timeLabel.text = timeStr
    end if
end sub

function formatTime(minutes as integer, seconds as integer) as string
    minStr = Right("0" + Str(minutes), 2)
    secStr = Right("0" + Str(seconds), 2)
    return minStr + ":" + secStr
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    print "[AUDIOPLAYER] Key pressed: " + key

    if key = "back" then
        print "[AUDIOPLAYER] Back button pressed"
        ' Stop audio playback
        if m.audioTask <> invalid then
            m.audioTask.command = "stop"
            print "[AUDIOPLAYER] Audio stop command sent"
        end if
        m.top.onBackPressed = true
        return true
    else if key = "play" then
        print "[AUDIOPLAYER] Play/Pause button pressed"
        if m.audioTask <> invalid then
            if m.top.isPlaying then
                m.audioTask.command = "pause"
                print "[AUDIOPLAYER] Audio pause command sent"
            else
                m.audioTask.command = "resume"
                print "[AUDIOPLAYER] Audio resume command sent"
            end if
        end if
        return true
    else if key = "left" then
        print "[AUDIOPLAYER] Seek backward"
        ' Seek backward 10 seconds
        newTime = m.top.currentTime - 10
        if newTime < 0 then newTime = 0
        m.top.currentTime = newTime
        m.startTime = CreateObject("roDateTime").AsSeconds() - newTime
        return true
    else if key = "right" then
        print "[AUDIOPLAYER] Seek forward"
        ' Seek forward 10 seconds
        newTime = m.top.currentTime + 10
        if newTime > m.top.duration then newTime = m.top.duration
        m.top.currentTime = newTime
        m.startTime = CreateObject("roDateTime").AsSeconds() - newTime
        return true
    end if

    return false
end function
