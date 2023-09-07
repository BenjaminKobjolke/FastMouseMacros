#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
CoordMode, Mouse, Window

DELAY_TIME = 100
SetTimer, WatchKeys, %DELAY_TIME%

if (!a_iscompiled) {
	Menu, tray, icon, icon.ico,0,1
}

!+F1::
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
            IfNotExist, recordings\%ActiveWindowTitle%
                FileCreateDir, recordings\%ActiveWindowTitle%
            FileAppend, % "Active Window: " ActiveWindowTitle "`n", % "recordings\" ActiveWindowTitle "\" RecordingName ".txt"
            FileAppend, % "Start Time: " StartTime "`n", % "recordings\" ActiveWindowTitle "\" RecordingName ".txt"
            Loop % Actions.Length()
                FileAppend, % Actions[A_Index] "`n", % "recordings\" ActiveWindowTitle "\" RecordingName ".txt"
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

!+F2::
    WinGetTitle, ActiveWindowTitle, A
    FileNames := []
    FilePaths := {}

    ; Loop through all subfolders in the recordings directory
    Loop, %A_ScriptDir%\recordings\*, 2D
    {
        ; Check if the folder name exists within the current window title
        If InStr(ActiveWindowTitle, A_LoopFileName)
        {
            ; If match is found, loop through the files in that folder
            Loop, Files, %A_ScriptDir%\recordings\%A_LoopFileName%\*.txt
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

        InputBox, SelectedFileIndex, Select Recording, Choose a recording to execute:`n`n%FileListStr%

        If (SelectedFileIndex) {
            SelectedFile := FilePaths[SelectedFileIndex]
            RunRecording(ActiveWindowTitle, SelectedFile)
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

RunRecording(ActiveWindowTitle, filePath) {
    ;filePath = %A_ScriptDir%\recordings\%ActiveWindowTitle%\%RecordingName%
    ;M sgBox, %filePath%
    FileRead, RecordingContent, %filePath%

    Loop, Parse, RecordingContent, `n
    {
        IfInString, A_LoopField, Active Window
        {
            ActiveWindowInfo := StrSplit(A_LoopField, ": ")
            ActiveWindowTitle := ActiveWindowInfo[2]
            ActiveWindowTitle := RegExReplace(ActiveWindowTitle, "\v\s?", "")
            IfWinExist, %ActiveWindowTitle%
                WinActivate
            else
                MsgBox, 16, Error, Window >%ActiveWindowTitle%< not found.
        }
        IfInString, A_LoopField, MouseMove
        {
            MouseMoveInfo := StrSplit(A_LoopField, A_Space)
            MouseMove, % MouseMoveInfo[2], % MouseMoveInfo[3], 1, 
        }
        IfInString, A_LoopField, MouseDownLeft
        {
            Click, down
        }
        IfInString, A_LoopField, MouseDownRight
        {
            Click, right, down
        }
        IfInString, A_LoopField, MouseUpLeft
        {
            Click, up
        }
        IfInString, A_LoopField, MouseUpRight
        {
            Click, right, up
        }
        ;Sleep, %DELAY_TIME%
    }
}
