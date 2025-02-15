; Global variable to store last selected recording
global LastSelectedIndex := ""

^+F10::
    WinGetTitle, ActiveWindowTitle, A
    FileNames := []
    FilePaths := {}

    ; Get current process name
    ProcessName := getActiveProcessName()

    ; Loop through all subfolders in the recordings directory
    Loop, %recordingsDir%\*, 2D
    {
        folderName := A_LoopFileName
        isProcessBased := InStr(folderName, "process_") = 1
        isTitleBased := InStr(folderName, "title_") = 1

        if (isProcessBased) {
            ; For process-based folders, compare with current process
            folderProcessName := SubStr(folderName, 9) ; Remove "process_" prefix
            if (folderProcessName = ProcessName) {
                Loop, Files, %recordingsDir%\%folderName%\*.txt
                {
                    FileRead, FileContent, %A_LoopFileLongPath%
                    FileNames.Push("[Process] " A_LoopFileName)  ; Add prefix for clarity
                    FilePaths.Push(A_LoopFileFullPath)
                }
            }
        }
        else if (isTitleBased) {
            ; For title-based folders, compare with current window title
            folderTitle := SubStr(folderName, 7) ; Remove "title_" prefix
            if InStr(ActiveWindowTitle, folderTitle)
            {
                Loop, Files, %recordingsDir%\%folderName%\*.txt
                {
                    FileRead, FileContent, %A_LoopFileLongPath%
                    FileNames.Push("[Title] " A_LoopFileName)  ; Add prefix for clarity
                    FilePaths.Push(A_LoopFileFullPath)
                }
            }
        }
    }

    If (FilePaths.Length() > 0) {
        FileIndex := 1
        FileListStr := ""
        Loop % FileNames.Length()
            FileListStr .= FileIndex++ ". " FileNames[A_Index] "`n"

        InputBox, SelectedFileIndex, Select Recording , Choose a recording to execute:`n`n%FileListStr%, , , 500, , , , , %LastSelectedIndex%

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
    } else {
        MsgBox, No recordings found for this window.`nWindow Title: %ActiveWindowTitle%`nProcess Name: %ProcessName%
    }
    SetTimer, RemoveToolTip, -1000  ; Ensure tooltip is cleared
return

RunRecording(filePath, reverse := false) {
    ; save current mouse position
    leftMouseDown := 0
    rightMouseDown := 0
    MouseGetPos, xpos, ypos 
    FileRead, RecordingContent, %filePath%

    ; Split the content into an array based on new lines
    LinesArray := StrSplit(RecordingContent, "`n", "`r")

    ; Get the active window info and storage type from the recording
    ActiveWindowInfo := LinesArray[1]
    ActiveWindowInfo := StrSplit(ActiveWindowInfo, ": ")
    ActiveWindowTitle := ActiveWindowInfo[2]
    ActiveWindowTitle := RegExReplace(ActiveWindowTitle, "\v\s?", "")

    StorageTypeInfo := LinesArray[2]
    StorageTypeInfo := StrSplit(StorageTypeInfo, ": ")
    StorageType := StorageTypeInfo[2]

    if (StorageType = "process") {
        ; For process-based recordings, activate by process name
        ; Strip .exe extension if it exists in the stored process name
        ProcessToFind := ActiveWindowTitle
        if (SubStr(ProcessToFind, -3) = ".exe") {
            ProcessToFind := SubStr(ProcessToFind, 1, StrLen(ProcessToFind)-4)
        }
        WinGet, WindowId,, ahk_exe %ProcessToFind%.exe
        if WindowId {
            WinActivate, ahk_id %WindowId%
        } else {
            MsgBox, 16, Error, Process >%ActiveWindowTitle%< not found.
            return
        }
    } else {
        ; For title-based recordings, activate by window title
        IfWinExist, %ActiveWindowTitle%
            WinActivate
        else {
            MsgBox, 16, Error, Window >%ActiveWindowTitle%< not found.
            return
        }
    }

    ; Loop over each line starting from the second line
    if (reverse = true)  ; Loop in reverse
    {
        Loop, % LinesArray.MaxIndex()
        {
            CurrentIndex := LinesArray.MaxIndex() - A_Index + 1
            CurrentLine := LinesArray[CurrentIndex]
            if (!HandleKeyboardCommand(CurrentLine, reverse)) {
                returnValue := HandleMouseCommand(CurrentLine, reverse)
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
    else  ; Loop in normal order
    {
        Loop, % LinesArray.MaxIndex()
        {
            CurrentLine := LinesArray[A_Index]
            if (!HandleKeyboardCommand(CurrentLine, reverse)) {
                returnValue := HandleMouseCommand(CurrentLine, reverse)
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
