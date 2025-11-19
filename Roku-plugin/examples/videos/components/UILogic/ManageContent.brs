
sub RunContentTask()
    m.contentTask = CreateObject("roSGNode", "Loader") 
    m.contentTask.ObserveField("content", "OnMainContentLoaded")
    m.contentTask.control = "run" 
    m.screenLoader.visible = true
    m.Grid.visible = false
end sub

sub OnMainContentLoaded() 
    m.Grid.SetFocus(true)
    m.Grid.visible = true
    m.screenLoader.visible = false 
    m.Grid.content = m.contentTask.content 
    args = m.top.inputArgs
    if args <> invalid and ValidateDeepLink(args)
        DeepLink(m.contentTask.content, args.mediaType, args.contentId)
    end if
end sub
