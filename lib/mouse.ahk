; Global variables for mouse tracking
global lastX := ""
global lastY := ""
global PrevRButtonDown := false
global PrevLButtonDown := false

; Handle mouse events during recording
HandleMouseRecording() {
    MouseGetPos, mouseX, mouseY

    If (mouseX != lastX or mouseY != lastY)
    {
        Actions.Push("MouseMove " mouseX " " mouseY)
        lastX := mouseX
        lastY := mouseY
    }
    if GetKeyState("LButton", "P") {
        if (!PrevLButtonDown) {  ; Only push down action if it wasn't down before
            Actions.Push("MouseDownLeft")
            PrevLButtonDown := true
        }
    } else if (PrevLButtonDown) {  ; If it was down before but is up now
        Actions.Push("MouseUpLeft")
        PrevLButtonDown := false
    }

    if GetKeyState("RButton", "P") {
        if (!PrevRButtonDown) {
            Actions.Push("MouseDownRight")
            PrevRButtonDown := true
        }
    } else if (PrevRButtonDown) {
        Actions.Push("MouseUpRight")
        PrevRButtonDown := false
    }
}

; Handle mouse commands during playback
HandleMouseCommand(CurrentLine, reverse) {
    returnValue := 0

    if (InStr(CurrentLine, "MouseDrag")) {
        parts := StrSplit(CurrentLine, A_Space)
        ; Format is: "MouseDrag Left targetX targetY"
        button := parts[2]    ; "Left"
        targetX := parts[3]   ; absolute target X
        targetY := parts[4]   ; absolute target Y
        
        ; Get current position for debugging
        CoordMode, Mouse, Screen  ; Switch to screen coordinates
        MouseGetPos, startX, startY
		Click, down
		Sleep, 300		
        MouseMove, %targetX%, %targetY%, 80
		Click, up
        CoordMode, Mouse, Window  ; Reset to default
        return returnValue
    }

    if (InStr(CurrentLine, "MouseMove")) {
        MouseMoveInfo := StrSplit(CurrentLine, A_Space)
        MouseMove, % MouseMoveInfo[2], % MouseMoveInfo[3], 1
        return returnValue
    }

    if (InStr(CurrentLine, "MouseDownLeft")) {
        if (reverse) {
            returnValue := 1
            Click, up
        } else {
            returnValue := 3 
            Click, down
        }
        Sleep, %DELAY_TIME%
        return returnValue
    }

    if (InStr(CurrentLine, "MouseDownRight")) {
        if (reverse) {
            returnValue := 2
            Click, right, up
        } else {
            returnValue := 4
            Click, right, down
        }
        Sleep, %DELAY_TIME%
        return returnValue
    }

    if (InStr(CurrentLine, "MouseUpLeft")) {
        if (reverse) {
            returnValue := 1
            Click, down
        } else {
            returnValue := 3
            Click, up
        }
        Sleep, %DELAY_TIME%
        return returnValue
    }

    if (InStr(CurrentLine, "MouseUpRight")) {
        if (reverse) {
            returnValue := 2
            Click, right, down
        } else {
            returnValue := 4
            Click, right, up
        }
        Sleep, %DELAY_TIME%
        return returnValue
    }

    return returnValue
}
