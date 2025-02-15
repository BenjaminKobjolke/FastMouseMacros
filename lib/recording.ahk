; Global variables for recording state
global Recording := false
global Actions := []
global StartTime := 0
global RecordingProcessName := ""
global RecordingScreenDimensions := ""
global RecordingWindowDimensions := ""

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
        RecordingScreenDimensions := getScreenDimensions()
        RecordingWindowDimensions := getActiveWindowDimensions()
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
            StorageType := ShowDarkMsgBox("Storage Type", "Store recording based on:`nWindow Title = Yes`nProcess Name = No", "YesNoCancel")
            if (StorageType = "No") {
                ; Process name based
                CustomProcessName := ShowDarkInputBox("Specify Process Name", "Modify the process name if required:", RecordingProcessName)
                if (!CustomProcessName)  ; If user cancels
                    return
                ProcessName := Trim(CustomProcessName)
                ActiveWindowTitle := ProcessName
                recordingPath := recordingsDir "\process_" ProcessName
            }
            else if (StorageType = "Yes") {
                ; Window title based (original behavior)
                WinGetTitle, DefaultWindowTitle, A
                CustomWindowTitle := ShowDarkInputBox("Specify Window Title", "Modify the window title if required:", DefaultWindowTitle)
                if (!CustomWindowTitle)  ; If user cancels
                    return
                ActiveWindowTitle := Trim(CustomWindowTitle)
                recordingPath := recordingsDir "\title_" ActiveWindowTitle
            }
            else  ; Cancel
                return


            RecordingName := ShowDarkInputBox("Save Recording", "Enter a name for the recording (illegal characters will be removed):")
            if (!RecordingName)  ; If user cancels
                return
                
            if (!RecordingName) {
                ToolTip, Recording canceled.
                Sleep, 1000
                ToolTip
                return
            }
            ; Remove illegal characters from filename
            RecordingName := RegExReplace(RecordingName, "[\\/:*?""<>|]", "_")
            
            ; Create directories if they don't exist
            try {
                IfNotExist, %recordingsDir%
                    FileCreateDir, %recordingsDir%
                IfNotExist, %recordingPath%
                    FileCreateDir, %recordingPath%
            } catch {
                RetryResult := ShowDarkMsgBox("Error", "Failed to create directory: " recordingPath "`n`nWould you like to try again?", "RetryCancel")
                if (RetryResult = "Retry")
                    continue
                else
                    return
            }
            
            ; Full path to the recording file
            filePath := recordingPath "\" RecordingName ".json"
            
            ; Try to save the recording
            try {
                ; Create recording data structure
                recordingData := Object()
                recordingData["version"] := "1.0"
                recordingData["metadata"] := Object()
                recordingData["metadata"]["storageType"] := InStr(recordingPath, "\process_") ? "process" : "title"
                recordingData["metadata"]["targetName"] := ActiveWindowTitle
                recordingData["metadata"]["screen"] := RecordingScreenDimensions
                recordingData["metadata"]["window"] := RecordingWindowDimensions
                recordingData["metadata"]["createdAt"] := A_Now
                recordingData["metadata"]["lastModified"] := A_Now

                ; Clean up the recording by removing trailing KeyDown events
                lastKeyUpIndex := 0
                Loop % Actions.Length() {
                    if (InStr(Actions[A_Index], "KeyUp ")) {
                        lastKeyUpIndex := A_Index
                    }
                }

                ; Process actions into structured format
                recordingData["recording"] := Object()
                recordingData["recording"]["actions"] := []
                Loop % (lastKeyUpIndex ? lastKeyUpIndex : Actions.Length()) {
                    action := Actions[A_Index]
                    actionParts := StrSplit(action, A_Space)
                    actionObj := Object()
                    actionObj["type"] := actionParts[1]
                    if (actionParts.Length() > 1)
                        actionObj["data"] := actionParts[2]
                    if (actionParts.Length() > 2)
                        actionObj["data"] .= " " actionParts[3]
                    actionObj["timestamp"] := A_Index * DELAY_TIME
                    recordingData["recording"]["actions"].Push(actionObj)
                }

                ; Save as JSON
                jsonText := JSON.Dump(recordingData, "", 2)  ; Pretty print with 2 spaces
                FileAppend, %jsonText%, %filePath%
                ToolTip, Recording saved as %RecordingName%.json
                Sleep, 1000
                ToolTip
                break  ; Exit loop on successful save
            } catch e {
                try {
                    FileDelete, %filePath%  ; Clean up partial file
                } catch {}
                RetryResult := ShowDarkMsgBox("Error", "Failed to save recording: " e "`n`nWould you like to try again?", "RetryCancel")
                if (RetryResult = "Retry")
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
