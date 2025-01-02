^+F10::
    WinGetTitle, ActiveWindowTitle, A
    FileNames := []
    FilePaths := {}

    ; Loop through all subfolders in the recordings directory
    Loop, %recordingsDir%\*, 2D
    {
        ; Check if the folder name exists within the current window title
        If InStr(ActiveWindowTitle, A_LoopFileName)
        {
            ; If match is found, loop through the files in that folder
            Loop, Files, %recordingsDir%\%A_LoopFileName%\*.txt
            {
                FileRead, FileContent, %A_LoopFileLongPath%                
                FileNames.Push(A_LoopFileName)  ; This is for the UI
                FilePaths.Push(A_LoopFileFullPath)  ; This stores the full path for each filename
            }
        }
    }

    If (FilePaths.Length() > 0) {
        FileIndex := 1
        FileListStr := ""
        Loop % FileNames.Length()
            FileListStr .= FileIndex++ ". " FileNames[A_Index] "`n"

        InputBox, SelectedFileIndex, Select Recording , Choose a recording to execute:`n`n%FileListStr%, , , 500

        If (SelectedFileIndex) {
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
        MsgBox, No recordings found for this window.
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

    ; Get the first line of the array
    ActiveWindowInfo := LinesArray[1]
    ActiveWindowInfo := StrSplit(ActiveWindowInfo, ": ")
    ActiveWindowTitle := ActiveWindowInfo[2]
    ActiveWindowTitle := RegExReplace(ActiveWindowTitle, "\v\s?", "")
    IfWinExist, %ActiveWindowTitle%
        WinActivate
    else
        MsgBox, 16, Error, Window >%ActiveWindowTitle%< not found.

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
