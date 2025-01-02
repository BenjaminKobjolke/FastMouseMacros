; Global variables for keyboard recording
global RecordKeyboard := false
global PrevKeyStates := {}

; Release all keys that were pressed during recording
ReleaseAllKeys() {
    for key, isDown in PrevKeyStates {
        if (isDown) {
            ; Convert to uppercase only for special keys
            if (StrLen(key) > 1) {
                StringUpper, key, key
            }
            if (Recording) {
                Actions.Push("KeyUp " key)
            }
            Send {%key% up}
        }
    }
    ; Special handling for common modifier keys that might be stuck
    Send {Shift up}{Ctrl up}{Alt up}{LWin up}{RWin up}
    Send {LShift up}{RShift up}{LCtrl up}{RCtrl up}{LAlt up}{RAlt up}
    PrevKeyStates := {}
    Sleep, %DELAY_TIME%  ; Add a small delay after releasing all keys
}

^+F8::
    RecordKeyboard := !RecordKeyboard
    if (RecordKeyboard) {
        ToolTip, Keyboard recording enabled
    } else {
        ToolTip, Keyboard recording disabled
        PrevKeyStates := {} ; Clear previous key states when disabled
    }
    SetTimer, RemoveToolTip, -1000  ; Negative value ensures the timer only runs once
return

; Handle keyboard events during recording
HandleKeyboardRecording() {
    if (RecordKeyboard) {
        Loop, 256 {
            key := GetKeyName(Format("vk{:x}", A_Index))
            if (key != "") {
                isKeyDown := GetKeyState(key, "P")
                ; Check if key state changed
                if (!PrevKeyStates.HasKey(key)) {
                    PrevKeyStates[key] := false
                }
                if (isKeyDown != PrevKeyStates[key]) {
                    ; Convert to uppercase only for special keys, not letters
                    if (StrLen(key) > 1) {
                        StringUpper, key, key
                    }
                    if (isKeyDown) {
                        Actions.Push("KeyDown " key)
                    } else {
                        Actions.Push("KeyUp " key)
                    }
                    PrevKeyStates[key] := isKeyDown
                }
            }
        }
    }
}

; Handle keyboard commands during playback
HandleKeyboardCommand(CurrentLine, reverse) {
    if (InStr(CurrentLine, "KeyDown ")) {
        key := SubStr(CurrentLine, 9)
        if (reverse) {
            Send {%key% up}
        } else {
            Send {%key% down}
        }
        Sleep, %DELAY_TIME% ; Add delay after keystroke
        return true
    }
    if (InStr(CurrentLine, "KeyUp ")) {
        key := SubStr(CurrentLine, 7)
        if (reverse) {
            Send {%key% down}
        } else {
            Send {%key% up}
        }
        Sleep, %DELAY_TIME% ; Add delay after keystroke
        return true
    }
    return false
}
