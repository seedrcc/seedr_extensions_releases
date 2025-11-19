' ********** Video Progress Tracking System **********

' Save video progress to registry
sub saveVideoProgress(fileId as string, progressPercent as float)
    if fileId <> invalid and fileId <> "" then
        registry = CreateObject("roRegistry")
        section = registry.GetSection("VideoProgress")
        section.Write(fileId, progressPercent.ToStr())
        section.Flush()
        print "Saved video progress for", fileId, ":", progressPercent, "%"
    end if
end sub

' Load video progress from registry
function loadVideoProgress(fileId as string) as float
    if fileId <> invalid and fileId <> "" then
        registry = CreateObject("roRegistry")
        section = registry.GetSection("VideoProgress")
        progressStr = section.Read(fileId)
        if progressStr <> invalid and progressStr <> "" then
            progress = progressStr.ToFloat()
            print "Loaded video progress for", fileId, ":", progress, "%"
            return progress
        end if
    end if
    return 0.0
end function

' Clear video progress (when video is completed or reset)
sub clearVideoProgress(fileId as string)
    if fileId <> invalid and fileId <> "" then
        registry = CreateObject("roRegistry")
        section = registry.GetSection("VideoProgress")
        section.Delete(fileId)
        section.Flush()
        print "Cleared video progress for", fileId
    end if
end sub

' Update progress during video playback
sub updateVideoProgress(fileId as string, position as float, duration as float)
    if duration > 0 then
        progressPercent = (position / duration) * 100.0

        ' Only save if progress is meaningful (between 1% and 95%)
        if progressPercent >= 1.0 and progressPercent <= 95.0 then
            saveVideoProgress(fileId, progressPercent)
        else if progressPercent > 95.0 then
            ' Video is essentially complete, clear progress
            clearVideoProgress(fileId)
        end if
    end if
end sub

' Get all video progress entries (for debugging or cleanup)
function getAllVideoProgress() as object
    registry = CreateObject("roRegistry")
    section = registry.GetSection("VideoProgress")
    return section.ReadMulti()
end function
