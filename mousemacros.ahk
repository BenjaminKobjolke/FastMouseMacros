#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
CoordMode, Mouse, Window

#include %A_ScriptDir%\lib\ComputerInfos.ahk
resolution := getDislplayResolutionString()

recordingsDir := A_ScriptDir "\recordings\" resolution

DELAY_TIME = 100
SetTimer, WatchKeys, %DELAY_TIME%

if (!a_iscompiled) {
	Menu, tray, icon, icon.ico,0,1
}


^+9::
    if (!Recording) {
        Recording := true
        Actions := []
        StartTime := A_TickCount
        ToolTip, Recording started. Press F1 again to stop recording and save.
    } else {
        Recording := false
        ToolTip,
        ; Specify window title after stopping the recording
        WinGetTitle, DefaultWindowTitle, A
        InputBox, CustomWindowTitle, Specify Window Title, Modify the window title if required:, , , , , , , , %DefaultWindowTitle%
        if (ErrorLevel)  ; If user cancels the InputBox
            return
        ActiveWindowTitle := Trim(CustomWindowTitle)

        InputBox, RecordingName, Save Recording, Enter a name for the recording:
        if (RecordingName) {
            FormatTime, RecordingTime,, yyyy-MM-dd_HH-mm-ss
            IfNotExist, %recordingsDir%\%ActiveWindowTitle%
                FileCreateDir, %recordingsDir%\%ActiveWindowTitle%
            FileAppend, % "Active Window: " ActiveWindowTitle "`n", % recordingsDir "\" ActiveWindowTitle "\" RecordingName ".txt"
            FileAppend, % "Start Time: " StartTime "`n", % recordingsDir "\" ActiveWindowTitle "\" RecordingName ".txt"
            Loop % Actions.Length()
                FileAppend, % Actions[A_Index] "`n", % recordingsDir "\" ActiveWindowTitle "\" RecordingName ".txt"
            ToolTip, Recording saved as %RecordingName%.txt
            Sleep, 1000
            ToolTip
        } else {
            ToolTip, Recording canceled.
            Sleep, 1000
            ToolTip
        }
    }
return

^+0::
    WinGetTitle, ActiveWindowTitle, A
    FileNames := []
    FilePaths := {}

    ; Loop through all subfolders in the recordings directory
    ;M sgBox, %recordingsDir%
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

            RunRecording(filePath, reverse)
        }
    } else {
        MsgBox, No recordings found for this window.
    }
return


WatchKeys:
    if (Recording) {
        MouseGetPos, mouseX, mouseY
        Actions.Push("MouseMove " mouseX " " mouseY)

        if GetKeyState("LButton", "P") {
            if (!PrevLButtonDown) {  ; Only push down action if it wasn't down before
                Actions.Push("MouseDownLeft")
                PrevLButtonDown := true
            }
        } else if (PrevLButtonDown) {  ; If it was down before but is up now
            Actions.Push("MouseUpLeft")
            PrevLButtonDown := false
        }

        if GetKeyState("RButton", "P") {
            if (!PrevRButtonDown) {
                Actions.Push("MouseDownRight")
                PrevRButtonDown := true
            }
        } else if (PrevRButtonDown) {
            Actions.Push("MouseUpRight")
            PrevRButtonDown := false
        }
    }
return

RunRecording(filePath, reverse := false) {
    ;filePath = %A_ScriptDir%\recordings\%ActiveWindowTitle%\%RecordingName%
    ;M sgBox, %filePath%
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
            returnValue := HandleCommand(CurrentLine, reverse)
            if returnValue = 1
                leftMouseDown := 1
            else if returnValue = 2
                rightMouseDown := 1
            else if returnValue = 3
                leftMouseDown := 0
            else if returnValue = 4
                rightMouseDown := 0
        }
    }
    else  ; Loop in normal order
    {
        Loop, % LinesArray.MaxIndex()
        {
            CurrentLine := LinesArray[A_Index]
            returnValue := HandleCommand(CurrentLine, reverse)
            if returnValue = 1
                leftMouseDown := 1
            else if returnValue = 2
                rightMouseDown := 1
            else if returnValue = 3
                leftMouseDown := 0
            else if returnValue = 4
                rightMouseDown := 0
        }
    }
    if leftMouseDown = 1
        Click, up
    if rightMouseDown = 1
        Click, right, up
    MouseMove, %xpos%, %ypos%
}

HandleCommand(CurrentLine, reverse := false) {
    returnValue := 0
    ; Do something with the current line
    IfInString, CurrentLine, MouseMove
    {
        MouseMoveInfo := StrSplit(CurrentLine, A_Space)
        MouseMove, % MouseMoveInfo[2], % MouseMoveInfo[3], 1, 
    }
    IfInString, CurrentLine, MouseDownLeft
    {
        if reverse = 1
        {
            returnValue := 1
            Click, up
        }
        else
        {
            returnValue := 3 
            Click, down
        }
        Sleep, 100
    }
    IfInString, CurrentLine, MouseDownRight
    {
        if reverse = 1
        {
            returnValue := 2
            Click, right, up
        }
        else
        {
            returnValue := 4
            Click, right, down
        }
        
        Sleep, 100
    }
    IfInString, CurrentLine, MouseUpLeft
    {
        if reverse = 1
        {
            returnValue := 1
            Click, down
        }
        else
        {
            returnValue := 3
            Click, up
        }
        Sleep, 100
    }
    IfInString, CurrentLine, MouseUpRight
    {
        if reverse = 1
        {
            returnValue := 2
            Click, right, down
        }
        else
        {
            returnValue := 4
            Click, right, up
        }
        Sleep, 100
    }
    return returnValue
    ;Sleep, %DELAY_TIME%    
}