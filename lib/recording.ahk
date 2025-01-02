; Global variables for recording state
global Recording := false
global Actions := []
global StartTime := 0

^+F9::
    if (!Recording) {
        PrevRButtonDown := false
        PrevLButtonDown := false 
        ; Wait for hotkey to be released before starting recording
        KeyWait, SHIFT
        KeyWait, CONTROL
        KeyWait, F9
        
        Recording := true
        Actions := []
        StartTime := A_TickCount
        SetTimer, WatchKeys, %DELAY_TIME%
        ToolTip, Recording started. Press Ctrl+Shift+F9 to stop and save.
    } else {
        SetTimer, WatchKeys, Off
        Recording := false
        
        ; Wait for hotkey to be released before stopping
        KeyWait, SHIFT
        KeyWait, CONTROL
        KeyWait, F9
        
        ReleaseAllKeys()  ; Release any keys that might still be held down
        ToolTip,
        ; Keep trying to save until success or user cancels
        Loop {
            ; Specify window title after stopping the recording
            WinGetTitle, DefaultWindowTitle, A
            InputBox, CustomWindowTitle, Specify Window Title, Modify the window title if required:, , , , , , , , %DefaultWindowTitle%
            if (ErrorLevel)  ; If user cancels the InputBox
                return
            ActiveWindowTitle := Trim(CustomWindowTitle)

            InputBox, RecordingName, Save Recording, Enter a name for the recording (illegal characters will be removed):
            if (ErrorLevel)  ; If user cancels the InputBox
                return
                
            if (!RecordingName) {
                ToolTip, Recording canceled.
                Sleep, 1000
                ToolTip
                return
            }
            ; Remove illegal characters from filename
            RecordingName := RegExReplace(RecordingName, "[\\/:*?""<>|]", "_")
            
            ; Create directory if it doesn't exist
            recordingPath := recordingsDir "\" ActiveWindowTitle
            try {
                IfNotExist, %recordingPath%
                    FileCreateDir, %recordingPath%
            } catch {
                MsgBox, 5, Error, Failed to create directory: %recordingPath%`n`nWould you like to try again?
                IfMsgBox Retry
                    continue
                else
                    return
            }
            
            ; Full path to the recording file
            filePath := recordingPath "\" RecordingName ".txt"
            
            ; Try to save the recording
            try {
                FileAppend, % "Active Window: " ActiveWindowTitle "`n", %filePath%
                if ErrorLevel {
                    throw "Failed to write header"
                }
                FileAppend, % "Start Time: " StartTime "`n", %filePath%
                if ErrorLevel {
                    throw "Failed to write start time"
                }
                ; Clean up the recording by removing trailing KeyDown events
                lastKeyUpIndex := 0
                Loop % Actions.Length() {
                    if (InStr(Actions[A_Index], "KeyUp ")) {
                        lastKeyUpIndex := A_Index
                    }
                }

                ; Save only actions up to the last KeyUp event
                Loop % (lastKeyUpIndex ? lastKeyUpIndex : Actions.Length()) {
                    FileAppend, % Actions[A_Index] "`n", %filePath%
                    if ErrorLevel {
                        throw "Failed to write action at index " A_Index
                    }
                }
                ToolTip, Recording saved as %RecordingName%.txt
                Sleep, 1000
                ToolTip
                break  ; Exit loop on successful save
            } catch e {
                try {
                    FileDelete, %filePath%  ; Clean up partial file
                } catch {}
                MsgBox, 5, Error, Failed to save recording: %e%`n`nWould you like to try again?
                IfMsgBox Retry
                    continue
                else
                    return
            }
        }
        ; Clear states after recording
        PrevKeyStates := {}
    }
return

WatchKeys:
    if (Recording) {
        HandleMouseRecording()
        HandleKeyboardRecording()
    }
return
