; Handle window activation change for all GUIs
OnMessage(0x06, "WM_ACTIVATE")

WM_ACTIVATE(wParam) {
    if (wParam = 0) {  ; Window is being deactivated
        if WinActive("Select Recording") {
            Gui, SelectRecording:Destroy
            global SelectedIndex := ""
        }
        else if WinActive("Input Required") {
            Gui, DarkInput:Destroy
            global InputResult := ""
        }
        else if WinActive("Storage Type") {
            Gui, DarkMsg:Destroy
            global MsgBoxResult := ""
        }
    }
}

ShowRecordingSelector(FileListStr, LastSelectedIndex) {
    global SelectedIndex  ; Make variable accessible to the label handlers

    ; Destroy any existing GUI
    Gui, SelectRecording:Destroy

    ; Create new GUI
    Gui, SelectRecording:New, +AlwaysOnTop -Caption +Owner
    Gui, SelectRecording:Color, 1E1E1E, 333333
    Gui, SelectRecording:Margin, 10, 10
    Gui, SelectRecording:Font, s16 cWhite, Segoe UI
    Gui, SelectRecording:Add, Text,, Select Recording:
    Gui, SelectRecording:Add, Edit, vSelectedIndex w80, %LastSelectedIndex%
    Gui, SelectRecording:Font, s14
    Gui, SelectRecording:Add, Text,, %FileListStr%
    Gui, SelectRecording:Show,, Select Recording

    ; Wait for GUI to close
    WinWaitClose, Select Recording
    return SelectedIndex
}

ShowDarkInputBox(title, prompt, default := "") {
    global InputResult

    ; Destroy any existing GUI
    Gui, DarkInput:Destroy
    InputResult := ""

    ; Create new GUI
    Gui, DarkInput:New, +AlwaysOnTop -Caption +Owner
    Gui, DarkInput:Color, 1E1E1E, 333333
    Gui, DarkInput:Margin, 10, 10
    Gui, DarkInput:Font, s14 cWhite, Segoe UI
    Gui, DarkInput:Add, Text,, %prompt%
    Gui, DarkInput:Add, Edit, vInputResult w300, %default%
    Gui, DarkInput:Show,, Input Required

    ; Wait for GUI to close
    WinWaitClose, Input Required
    return InputResult
}

ShowRecordingModeSelector() {
    global RecordingModeResult

    ; Destroy any existing GUI
    Gui, RecordingMode:Destroy
    RecordingModeResult := ""

    ; Create new GUI
    Gui, RecordingMode:New, +AlwaysOnTop -Caption +Owner
    Gui, RecordingMode:Color, 1E1E1E, 333333
    Gui, RecordingMode:Margin, 10, 10
    Gui, RecordingMode:Font, s14 cWhite, Segoe UI
    Gui, RecordingMode:Add, Text,, Select Recording Mode:
    Gui, RecordingMode:Add, Radio, vRecordingModeResult Checked, Regular Recording
    Gui, RecordingMode:Add, Radio,, Relative Mouse Drag Recording
    Gui, RecordingMode:Add, Button, x10 y+10 w80 gRecordingModeOK, OK

    Gui, RecordingMode:Show,, Recording Mode

    ; Wait for GUI to close
    WinWaitClose, Recording Mode
    return RecordingModeResult
}

ShowDarkMsgBox(title, text, buttons := "OK") {
    global MsgBoxResult

    ; Destroy any existing GUI
    Gui, DarkMsg:Destroy
    MsgBoxResult := ""

    ; Create new GUI
    Gui, DarkMsg:New, +AlwaysOnTop -Caption +Owner
    Gui, DarkMsg:Color, 1E1E1E, 333333
    Gui, DarkMsg:Margin, 10, 10
    Gui, DarkMsg:Font, s14 cWhite, Segoe UI
    Gui, DarkMsg:Add, Text,, %text%

    ; Add buttons based on type
    if (buttons = "YesNoCancel") {
        Gui, DarkMsg:Add, Button, x10 y+10 w80 gDarkMsgYes, Yes
        Gui, DarkMsg:Add, Button, x+10 w80 gDarkMsgNo, No
        Gui, DarkMsg:Add, Button, x+10 w80 gDarkMsgCancel, Cancel
    } else if (buttons = "RetryCancel") {
        Gui, DarkMsg:Add, Button, x10 y+10 w80 gDarkMsgRetry, Retry
        Gui, DarkMsg:Add, Button, x+10 w80 gDarkMsgCancel, Cancel
    } else {
        Gui, DarkMsg:Add, Button, x10 y+10 w80 gDarkMsgOK, OK
    }

    Gui, DarkMsg:Show,, %title%

    ; Wait for GUI to close
    WinWaitClose, % title
    return MsgBoxResult
}

; Button handlers for message box
DarkMsgYes:
    global MsgBoxResult := "Yes"
    Gui, DarkMsg:Destroy
return

DarkMsgNo:
    global MsgBoxResult := "No"
    Gui, DarkMsg:Destroy
return

DarkMsgCancel:
    global MsgBoxResult := "Cancel"
    Gui, DarkMsg:Destroy
return

DarkMsgRetry:
    global MsgBoxResult := "Retry"
    Gui, DarkMsg:Destroy
return

DarkMsgOK:
    global MsgBoxResult := "OK"
    Gui, DarkMsg:Destroy
return

; Handle Enter key for all GUIs
; Button handler for recording mode
RecordingModeOK:
    Gui, RecordingMode:Submit
    Gui, RecordingMode:Destroy
return

~Enter::
    if WinActive("Select Recording") {
        Gui, SelectRecording:Submit
        Gui, SelectRecording:Destroy
    }
    else if WinActive("Input Required") {
        Gui, DarkInput:Submit
        Gui, DarkInput:Destroy
    }
    else if WinActive("Storage Type") {
        WinGetTitle, CurrentTitle, A
        if (InStr(CurrentTitle, "Storage Type")) {
            ; For storage type dialog, don't auto-select Yes on Enter
            return
        }
        global MsgBoxResult := "Yes"  ; Default to Yes for other message boxes
        Gui, DarkMsg:Destroy
    }
    else if WinActive("Recording Mode") {
        Gui, RecordingMode:Submit
        Gui, RecordingMode:Destroy
    }
return

; Handle Escape key for all GUIs
~Escape::
    if WinActive("Select Recording") {
        Gui, SelectRecording:Destroy
        SelectedIndex := ""
    }
    else if WinActive("Input Required") {
        Gui, DarkInput:Destroy
        InputResult := ""
    }
    else if WinActive("Storage Type") {
        Gui, DarkMsg:Destroy
        MsgBoxResult := "Cancel"
    }
    else if WinActive("Recording Mode") {
        Gui, RecordingMode:Destroy
        RecordingModeResult := ""
    }
return
