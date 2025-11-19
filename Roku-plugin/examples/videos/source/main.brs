
sub Main(args as Object) as void
    ShowChannelRSGScreen(args)
end sub

sub ShowChannelRSGScreen(args as Object)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.SetMessagePort(m.port)
    scene = screen.CreateScene("BaseScene")
    screen.Show() 
    scene.inputArgs = args
    inputObject=createobject("roInput")
    inputObject.setmessageport(m.port)

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        ?"msgTyp="msgType
        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        else if msgType = "roInputEvent"
            inputData = msg.getInfo()
            if inputData.DoesExist("mediatype") and inputData.DoesExist("contentid")
                deeplink = {
                    contentId: inputData.contentid
                    mediaType: inputData.mediatype
                }
                scene.launchArgs = deeplink
            end if
        end if
    end while
end sub
