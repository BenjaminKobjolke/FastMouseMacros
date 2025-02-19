; Global variables for recording state
global Recording := false
global Actions := []
global StartTime := 0
global RecordingProcessName := ""
global RecordingScreenDimensions := ""
global RecordingWindowDimensions := ""
global RecordingMode := ""
global RelativeStartX := ""
global RelativeStartY := ""
global WaitingForSpaceKey := false
global SpacePhase := 0

^+F9::
    if (!Recording) {
        PrevRButtonDown := false
        PrevLButtonDown := false 
        ; Wait for hotkey to be released before starting recording
        KeyWait, SHIFT
        KeyWait, CONTROL
        KeyWait, F9
        
        ; Show recording mode selector
        RecordingMode := ShowRecordingModeSelector()
        if (!RecordingMode) {
            ToolTip, Recording canceled.
            Sleep, 1000
            ToolTip
            return
        }
            
        Recording := true
        Actions := []
        StartTime := A_TickCount
        SpacePhase := 0  ; Reset phase when starting new recording
        
        if (RecordingMode = 2) { ; Relative Mouse Drag Recording
            WaitingForSpaceKey := true
            ToolTip, Press SPACE to set start position
        } else {
            RecordingProcessName := getActiveProcessName()
            RecordingScreenDimensions := getScreenDimensions()
            RecordingWindowDimensions := getActiveWindowDimensions()
            SetTimer, WatchKeys, %DELAY_TIME%
            ToolTip, Recording started. Press Ctrl+Shift+F9 to stop and save.
        }
    } else {
        SetTimer, WatchKeys, Off
        Recording := false
        WaitingForSpaceKey := false
        SpacePhase := 0
        
        ; Wait for hotkey to be released before stopping
        KeyWait, SHIFT
        KeyWait, CONTROL
        KeyWait, F9
        
        ReleaseAllKeys()  ; Release any keys that might still be held down
        ToolTip,
        
        ; Trigger the save dialog
        Gosub, SaveRecording
    }
return

WatchKeys:
    if (Recording) {
        if (!WaitingForSpaceKey) {
            HandleMouseRecording()
            HandleKeyboardRecording()
        }
    }
return

#If WaitingForSpaceKey  ; Context-sensitive hotkey - only active when waiting for space
Space::  ; Handle space key press globally
    if (SpacePhase = 0) {
        ; First space press - capture start position and window info
        CoordMode, Mouse, Screen  ; Switch to screen coordinates
        MouseGetPos, RelativeStartX, RelativeStartY
        RecordingProcessName := getActiveProcessName()
        RecordingScreenDimensions := getScreenDimensions()
        RecordingWindowDimensions := getActiveWindowDimensions()
        
        SpacePhase := 1
        ToolTip, Start position: %RelativeStartX%`,%RelativeStartY% - Move to end position and press SPACE
        return
    }
    
    ; Second space press
    WaitingForSpaceKey := false
    SpacePhase := 0  ; Reset for next recording
    CoordMode, Mouse, Screen  ; Switch to screen coordinates
    MouseGetPos, endX, endY
    ; Store absolute end position
    Actions.Push("MouseDrag Left " endX " " endY)
    
    ; Stop recording
    Recording := false
    SetTimer, WatchKeys, Off
    ToolTip, End position: %endX%`,%endY% - Recording completed
    Sleep, 2000  ; Show coordinates for 2 seconds
    
    ; Trigger the save dialog
    Gosub, SaveRecording
return
#If

; Save recording to file
SaveRecording:
    if (!Actions.Length()) {
        ToolTip, No actions recorded.
        Sleep, 1000
        ToolTip
        return
    }
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

    ; Create directories if they don't exist
    try {
        IfNotExist, %recordingsDir%
            FileCreateDir, %recordingsDir%
        IfNotExist, %recordingPath%
            FileCreateDir, %recordingPath%
    } catch {
        ShowDarkMsgBox("Error", "Failed to create directory: " recordingPath)
        return
    }

    ; Keep trying to save until success or user cancels
    Loop {
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
        
        ; Full path to the recording file
        filePath := recordingPath "\" RecordingName ".json"
        
        ; Check if file already exists
        if FileExist(filePath) {
            overwrite := ShowDarkMsgBox("File Exists", "File already exists. Do you want to overwrite it?", "YesNoCancel")
            if (overwrite = "No") {
                continue  ; Let user enter a new filename
            }
            ; Delete existing file before saving
            try {
                FileDelete, %filePath%
            } catch e {
                ShowDarkMsgBox("Error", "Failed to delete existing file: " e)
                continue
            }
        }
        
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
            recordingData["metadata"]["recordingMode"] := RecordingMode = 2 ? "relative" : "regular"

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
                if (actionParts.Length() > 2) {
                    ; For MouseDrag, combine all coordinates into data
                    if (actionParts[1] = "MouseDrag") {
                        actionObj["data"] := actionParts[2] " " actionParts[3] " " actionParts[4]
                    } else {
                        actionObj["data"] .= " " actionParts[3]
                    }
                }
                actionObj["timestamp"] := A_Index * DELAY_TIME
                recordingData["recording"]["actions"].Push(actionObj)
            }

            ; Save as JSON
            jsonText := JSON.Dump(recordingData, "", 2)  ; Pretty print with 2 spaces
            file := FileOpen(filePath, "w")  ; Open in write mode (creates new file)
            file.Write(jsonText)
            file.Close()
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
    WaitingForSpaceKey := false
    SpacePhase := 0
return
