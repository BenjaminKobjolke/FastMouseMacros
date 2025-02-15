global IntentionalClose := false

ShowRecordingSelector(FileListStr, LastSelectedIndex) {
    global SelectedIndex, IntentionalClose  ; Make variables accessible to the label handlers
    IntentionalClose := false

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

    ; Start focus check timer
    SetTimer, CheckFocus, 300

    ; Wait for GUI to close
    WinWaitClose, Select Recording
    
    ; Stop timer when window closes
    SetTimer, CheckFocus, Off
    return SelectedIndex
}

; Timer label to check focus
CheckFocus:
    if !WinActive("Select Recording") {
        SetTimer, CheckFocus, Off  ; Stop the timer
        if (!IntentionalClose) {  ; Only clear if not intentionally closed
            Gui, SelectRecording:Destroy
            global SelectedIndex := ""
        }
    }
return

; Handle Enter key
~Enter::
    if WinActive("Select Recording") {
        IntentionalClose := true
        Gui, SelectRecording:Submit  ; Save the input from the user to each control's associated variable
        Gui, SelectRecording:Destroy
    }
return

; Handle Escape key
~Escape::
    if WinActive("Select Recording") {
        IntentionalClose := true
        Gui, SelectRecording:Destroy
        SelectedIndex := ""
    }
return
