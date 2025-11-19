' ********** Screen Stack Management System **********
' Based on videos example ManageScreens.brs

sub init()
    print "[ScreenManager] Initializing screen stack management"
    initScreenStack()
end sub

' Initialize the screen stack
sub initScreenStack()
    m.screenStack = []
    m.top.screenCount = 0
    print "[ScreenManager] Screen stack initialized"
end sub

' Show a new screen (pushes to stack)
sub showScreen(node as object)
    print "[ScreenManager] Showing screen: "; node.subType()

    ' Hide previous screen
    prev = m.screenStack.peek()
    if prev <> invalid
        prev.visible = false
        print "[ScreenManager] Hiding previous screen: "; prev.subType()
    end if

    ' Add new screen
    m.top.appendChild(node)
    node.visible = true
    node.setFocus(true)
    m.screenStack.push(node)

    ' Update screen count
    m.top.screenCount = m.screenStack.count()
    m.top.currentScreen = node

    print "[ScreenManager] Screen stack count: "; m.screenStack.count()
end sub

' Close current screen (pops from stack)
sub closeScreen(node as object)
    print "[ScreenManager] Closing screen"

    ' Close specific screen or current screen
    if node = invalid or (m.screenStack.peek() <> invalid and m.screenStack.peek().isSameNode(node))
        last = m.screenStack.pop()
        if last <> invalid
            last.visible = false
            m.top.removeChild(last)
            print "[ScreenManager] Removed screen: "; last.subType()
        end if

        ' Show previous screen
        prev = m.screenStack.peek()
        if prev <> invalid
            prev.visible = true
            prev.setFocus(true)
            m.top.currentScreen = prev
            print "[ScreenManager] Restored previous screen: "; prev.subType()
        end if

        ' Update screen count
        m.top.screenCount = m.screenStack.count()
    end if
end sub

' Add screen without hiding previous (for overlays)
sub addScreen(node as object)
    print "[ScreenManager] Adding overlay screen: "; node.subType()
    m.top.appendChild(node)
    m.screenStack.push(node)
    m.top.screenCount = m.screenStack.count()
end sub

' Clear all screens except the first one
sub clearScreens()
    print "[ScreenManager] Clearing screens"

    if m.screenStack.count() > 1
        while m.screenStack.count() > 1
            last = m.screenStack.pop()
            if last <> invalid
                if last.visible = true
                    last.visible = false
                end if
                m.top.removeChild(last)
            end if
        end while
    else
        ' Hide the only screen
        if m.screenStack.count() = 1
            m.screenStack.peek().visible = false
        end if
    end if

    m.top.screenCount = m.screenStack.count()
end sub

' Check if a screen is in the stack
function isScreenAvailable(node as object) as boolean
    for each screen in m.screenStack
        result = screen.isSameNode(node)
        if result = true
            return true
        end if
    end for
    return false
end function

' Get current screen
function getCurrentScreen() as object
    return m.screenStack.peek()
end function

' Get screen count
function getScreenCount() as integer
    return m.screenStack.count()
end function
