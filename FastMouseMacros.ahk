#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
CoordMode, Mouse, Window

; Global configuration
global DELAY_TIME := 10  ; Delay between actions

; Include required modules
#include %A_ScriptDir%\github_modules\AutoHotkey-JSON\JSON.ahk
#include %A_ScriptDir%\lib\ComputerInfos.ahk
resolution := getScreenDimensions()
global recordingsDir := A_ScriptDir "\recordings"

; Include functionality modules
#include %A_ScriptDir%\lib\keyboard.ahk
#include %A_ScriptDir%\lib\mouse.ahk
#include %A_ScriptDir%\lib\recording.ahk
#include %A_ScriptDir%\lib\playback.ahk
#include %A_ScriptDir%\lib\darkGui.ahk

; Set up tray icon
if (!a_iscompiled) {
    Menu, tray, icon, icon.ico,0,1
}

; Tooltip removal timer
RemoveToolTip:
    ToolTip
    SetTimer, RemoveToolTip, Off
return
