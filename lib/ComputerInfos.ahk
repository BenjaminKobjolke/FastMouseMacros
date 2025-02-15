getActiveProcessName() {
    WinGet, ProcessName, ProcessName, A
    ; Strip .exe extension if it exists
    if (SubStr(ProcessName, -3) = ".exe") {
        ProcessName := SubStr(ProcessName, 1, StrLen(ProcessName)-4)
    }
    return ProcessName
}

getDislplayResolutionString() {
        ; Get screen width
    SysGet, ScreenWidth, 0
    ; Get screen height
    SysGet, ScreenHeight, 1

    ; Display the resolution in a message box
    ;M sgBox, The current screen resolution is %ScreenWidth% x %ScreenHeight%.
    returnString := ScreenWidth . "x" . ScreenHeight

    return returnString
}
