; Global variables for recording state
global Recording := false
global Actions := []
global StartTime := 0
global RecordingProcessName := ""

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
        RecordingProcessName := getActiveProcessName()
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
            ; Ask user for storage preference
            MsgBox, 3, Storage Type, Store recording based on:`nYes = Window Title`nNo = Process Name
            IfMsgBox Yes
            {
                ; Window title based (original behavior)
                WinGetTitle, DefaultWindowTitle, A
                InputBox, CustomWindowTitle, Specify Window Title, Modify the window title if required:, , , , , , , , %DefaultWindowTitle%
                if (ErrorLevel)  ; If user cancels the InputBox
                    return
                ActiveWindowTitle := Trim(CustomWindowTitle)
                recordingPath := recordingsDir "\title_" ActiveWindowTitle
            }
            IfMsgBox No
            {
                ; Process name based
                InputBox, CustomProcessName, Specify Process Name, Modify the process name if required:, , , , , , , , %RecordingProcessName%
                if (ErrorLevel)  ; If user cancels the InputBox
                    return
                ProcessName := Trim(CustomProcessName)
                ActiveWindowTitle := ProcessName
                recordingPath := recordingsDir "\process_" ProcessName
            }
            IfMsgBox Cancel
                return

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
                ; Add storage type
                if (InStr(recordingPath, "\process_")) {
                    FileAppend, % "Storage Type: process`n", %filePath%
                } else {
                    FileAppend, % "Storage Type: title`n", %filePath%
                }
                if ErrorLevel {
                    throw "Failed to write storage type"
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
