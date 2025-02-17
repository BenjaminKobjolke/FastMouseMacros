; Global variable to store last selected recording
global LastSelectedIndex := ""

; Helper function to check if dimensions match
isDimensionsMatch(recordingData, currentScreen, currentWindow) {
    return (recordingData["metadata"]["screen"]["width"] = currentScreen["width"]
        && recordingData["metadata"]["screen"]["height"] = currentScreen["height"]
        && recordingData["metadata"]["window"]["width"] = currentWindow["width"]
        && recordingData["metadata"]["window"]["height"] = currentWindow["height"])
}

; Helper function to check if stop hotkey is pressed
isStopHotkeyPressed() {
    return (GetKeyState("Ctrl") && GetKeyState("Shift") && GetKeyState("F10"))
}

^+F10::
    WinGetTitle, ActiveWindowTitle, A
    FileNames := []
    FilePaths := {}
    SimilarRecordings := []

    ; Get current process name and dimensions
    ProcessName := getActiveProcessName()
    CurrentScreen := getScreenDimensions()
    CurrentWindow := getActiveWindowDimensions()

    ; Loop through all subfolders in the recordings directory
    Loop, %recordingsDir%\*, 2D
    {
        folderName := A_LoopFileName
        isProcessBased := InStr(folderName, "process_") = 1
        isTitleBased := InStr(folderName, "title_") = 1

        if (isProcessBased || isTitleBased) {
            ; Get the target name from folder
            targetName := isProcessBased 
                ? SubStr(folderName, 9)  ; Remove "process_" prefix
                : SubStr(folderName, 7)  ; Remove "title_" prefix

            ; Check if this folder matches current window
            isMatch := isProcessBased 
                ? (targetName = ProcessName)
                : InStr(ActiveWindowTitle, targetName)

            if (isMatch) {
                ; Check recordings in this folder
                Loop, Files, %recordingsDir%\%folderName%\*.json
                {
                    ; Load and parse JSON
                    FileRead, Content, %A_LoopFileFullPath%
                    try {
                        RecordingData := JSON.Load(Content)
                    } catch e {
                        ShowDarkMsgBox("Error", "Failed to parse recording: " e)
                        continue
                    }
                    
                    ; Check dimensions match
                    if (isDimensionsMatch(RecordingData, CurrentScreen, CurrentWindow)) {
                        ; Perfect match - add to main list
                        baseName := SubStr(A_LoopFileName, 1, StrLen(A_LoopFileName)-5)  ; Remove .json
                        FileNames.Push(baseName " [" RecordingData["metadata"]["storageType"] "]")
                        FilePaths.Push(A_LoopFileFullPath)
                    } else {
                        ; Similar recording with different dimensions - add to similar list
                        similarRec := Object()
                        similarRec["name"] := A_LoopFileName
                        similarRec["screen"] := RecordingData["metadata"]["screen"]
                        similarRec["window"] := RecordingData["metadata"]["window"]
                        similarRec["type"] := RecordingData["metadata"]["storageType"]
                        SimilarRecordings.Push(similarRec)
                    }
                }
            }
        }
    }

    ; Show matching recordings or similar recordings message
    If (FilePaths.Length() > 0) {
        FileIndex := 1
        FileListStr := ""
        Loop % FileNames.Length()
            FileListStr .= FileIndex++ ". " FileNames[A_Index] "`n"

        SelectedFileIndex := ShowRecordingSelector(FileListStr, LastSelectedIndex)

        If (SelectedFileIndex) {
            LastSelectedIndex := SelectedFileIndex  ; Store the selection for next time
            ; Assuming SelectedFileIndex contains something like "5r" or "7"
            if SelectedFileIndex contains r
            {
                StringReplace, digitPart, SelectedFileIndex, r, , All
                letterPart := "r"
            }
            else
            {
                digitPart := SelectedFileIndex
                letterPart := ""
            }

            if letterPart = r
                reverse := true
            else
                reverse := false

            filePath := FilePaths[digitPart]

            ToolTip, Playing recording...
            RunRecording(filePath, reverse)
            ReleaseAllKeys()  ; Release any held keys after playback
            ToolTip  ; Clear tooltip
        }
    } else if (SimilarRecordings.Length() > 0) {
        msg := "No recordings found matching current dimensions:`n"
            msg .= "Screen: " CurrentScreen["width"] "x" CurrentScreen["height"] "`n"
            msg .= "Window: " CurrentWindow["width"] "x" CurrentWindow["height"] "`n`n"
        msg .= "Similar recordings found with different dimensions:`n"
        for each, rec in SimilarRecordings {
            msg .= "`n" rec["name"] " [" rec["type"] "]`n"
            msg .= "- Screen: " rec["screen"]["width"] "x" rec["screen"]["height"] "`n"
            msg .= "- Window: " rec["window"]["width"] "x" rec["window"]["height"]
        }
        ShowDarkMsgBox("No Matching Recordings", msg)
    } else {
        msg := "No recordings found for this window.`n"
        msg .= "Window Title: " ActiveWindowTitle "`n"
        msg .= "Process Name: " ProcessName "`n"
        msg .= "Screen: " CurrentScreen["width"] "x" CurrentScreen["height"] "`n"
        msg .= "Window: " CurrentWindow["width"] "x" CurrentWindow["height"]
        ShowDarkMsgBox("No Recordings Found", msg)
    }
    SetTimer, RemoveToolTip, -1000  ; Ensure tooltip is cleared
return

RunRecording(filePath, reverse := false) {
    ; save current mouse position
    leftMouseDown := 0
    rightMouseDown := 0
    MouseGetPos, xpos, ypos 
    FileRead, Content, %filePath%

    ; Parse JSON content
    try {
        RecordingData := JSON.Load(Content)
    } catch e {
        ShowDarkMsgBox("Error", "Failed to parse recording file: " e)
        return
    }

    ; Activate target window
    if (RecordingData["metadata"]["storageType"] = "process") {
        targetExe := RecordingData["metadata"]["targetName"] ".exe"
        WinGet, WindowId,, ahk_exe %targetExe%
        if WindowId {
            WinActivate, ahk_id %WindowId%
        } else {
            ShowDarkMsgBox("Error", "Process >" RecordingData["metadata"]["targetName"] "< not found.")
            return
        }
    } else {
        targetTitle := RecordingData["metadata"]["targetName"]
        if WinExist(targetTitle) {
            WinActivate
        } else {
            ShowDarkMsgBox("Error", "Window >" targetTitle "< not found.")
            return
        }
    }

    ; Play actions
    actions := RecordingData["recording"]["actions"]
    if (reverse) {
        Loop % actions.Length() {
            ; Check if stop hotkey is pressed
            if (isStopHotkeyPressed()) {
                ReleaseAllKeys()
                ToolTip, Playback stopped
                SetTimer, RemoveToolTip, -1000
                return
            }

            index := actions.Length() - A_Index + 1
            action := actions[index]
            if (InStr(action["type"], "Key")) {
                if (!HandleKeyboardCommand(action["type"] " " action["data"], reverse)) {
                    returnValue := HandleMouseCommand(action["type"] " " action["data"], reverse)
                    if returnValue = 1
                        leftMouseDown := 1
                    else if returnValue = 2
                        rightMouseDown := 1
                    else if returnValue = 3
                        leftMouseDown := 0
                    else if returnValue = 4
                        rightMouseDown := 0
                }
            } else {
                returnValue := HandleMouseCommand(action["type"] " " action["data"], reverse)
                if returnValue = 1
                    leftMouseDown := 1
                else if returnValue = 2
                    rightMouseDown := 1
                else if returnValue = 3
                    leftMouseDown := 0
                else if returnValue = 4
                    rightMouseDown := 0
            }
            Sleep, %DELAY_TIME%
        }
    } else {
        Loop % actions.Length() {
            ; Check if stop hotkey is pressed
            if (isStopHotkeyPressed()) {
                ReleaseAllKeys()
                ToolTip, Playback stopped
                SetTimer, RemoveToolTip, -1000
                return
            }

            action := actions[A_Index]
            if (InStr(action["type"], "Key")) {
                if (!HandleKeyboardCommand(action["type"] " " action["data"], reverse)) {
                    returnValue := HandleMouseCommand(action["type"] " " action["data"], reverse)
                    if returnValue = 1
                        leftMouseDown := 1
                    else if returnValue = 2
                        rightMouseDown := 1
                    else if returnValue = 3
                        leftMouseDown := 0
                    else if returnValue = 4
                        rightMouseDown := 0
                }
            } else {
                returnValue := HandleMouseCommand(action["type"] " " action["data"], reverse)
                if returnValue = 1
                    leftMouseDown := 1
                else if returnValue = 2
                    rightMouseDown := 1
                else if returnValue = 3
                    leftMouseDown := 0
                else if returnValue = 4
                    rightMouseDown := 0
            }
            Sleep, %DELAY_TIME%
        }
    }
    if leftMouseDown = 1
        Click, up
    if rightMouseDown = 1
        Click, right, up
    MouseMove, %xpos%, %ypos%
    Sleep, %DELAY_TIME%  ; Add delay before releasing keys
    ReleaseAllKeys()  ; Ensure keys are released even if playback is interrupted
    Sleep, %DELAY_TIME%  ; Add delay after releasing keys
    ToolTip  ; Clear any tooltips
}
