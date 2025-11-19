sub InitScreenStack()
    m.screenStack = []
end sub

sub ShowScreen(node as Object)
    prev = m.screenStack.Peek() 
    if prev <> invalid
        prev.visible = false 
    end if
    m.top.AppendChild(node) 
    node.visible = true
    node.SetFocus(true)
    m.screenStack.Push(node)
end sub

sub CloseScreen(node as Object)
    if node = invalid OR (m.screenStack.Peek() <> invalid AND m.screenStack.Peek().IsSameNode(node))
        last = m.screenStack.Pop()
        last.visible = false
        m.top.RemoveChild(last) 
        prev = m.screenStack.Peek()
        if prev <> invalid
            prev.visible = true
            prev.SetFocus(true)
        end if
    end if
end sub

sub AddScreen (node as Object)
    m.top.AppendChild(node)
    m.screenStack.Push(node)
end sub

sub ClearScreen ()
if m.screenStack.Count() > 1
    while m.screenStack.Count() > 1
        last = m.screenStack.Pop()
        if last.visible = true
            last.visible = false
        end if
        m.top.RemoveChild(last)
end while
else
    m.screenStack.Peek().visible = false
    end if
end sub

function IsScreenAvailable(node as Object) as Boolean
    for each screen in m.screenstack
        result = screen.IsSameNode(node)
        if result = true
            return true
        end if
    end for
    return false
    end function
    