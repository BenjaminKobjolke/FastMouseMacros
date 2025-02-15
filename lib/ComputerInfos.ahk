getActiveProcessName() {
    WinGet, ProcessName, ProcessName, A
    ; Strip .exe extension if it exists
    if (SubStr(ProcessName, -3) = ".exe") {
        ProcessName := SubStr(ProcessName, 1, StrLen(ProcessName)-4)
    }
    return ProcessName
}

getScreenDimensions() {
    SysGet, ScreenWidth, 0
    SysGet, ScreenHeight, 1
    return {"width": ScreenWidth, "height": ScreenHeight}
}

getActiveWindowDimensions() {
    WinGetPos,,, width, height, A
    return {"width": width, "height": height}
}
