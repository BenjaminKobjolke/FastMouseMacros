# FastMouseMacros

A tool for recording and playing back mouse and keyboard actions on Windows.

## Requirements

1. Windows operating system
2. AutoHotkey v1.1 installed (download from [autohotkey.com](https://www.autohotkey.com/))

## Installation

1. Install AutoHotkey v1.1 if you haven't already
2. Download or clone this repository
3. Double-click `FastMouseMacros.ahk` to start the tool
4. The tool will run in the background with an icon in the system tray

## Workflow

1. Recording:

   - Press Ctrl+Shift+F9 to start recording
   - Perform the actions you want to record (mouse movements, clicks, keyboard inputs)
   - Press Ctrl+Shift+F9 again to stop recording
   - Choose storage type:
     - Window Title: Recording will be matched to windows with similar titles
     - Process Name: Recording will be matched to any window of the same application
   - Enter a name for your recording

2. Playback:

   - Go to the window where you want to play the recording
   - Press Ctrl+Shift+F10 to show available recordings
   - Enter the number of the recording you want to play
   - Add 'r' after the number for reverse playback (e.g., "1r")
   - Press Ctrl+Shift+F10 again during playback to stop

3. Keyboard-only Recording:
   - Use Ctrl+Shift+F8 to toggle keyboard recording mode
   - Useful when you only want to record keyboard inputs

## Hotkeys

- `Ctrl+Shift+F8`: Toggle keyboard recording mode

  - When enabled, records all keyboard inputs
  - When disabled, stops recording keyboard inputs

- `Ctrl+Shift+F9`: Start/Stop recording mouse and keyboard actions

  - When started, records all mouse movements, clicks, and keyboard inputs
  - When stopped, prompts for:
    1. Specify or modify the window title
    2. Enter a name for the recording
  - Recordings are saved based on screen resolution and window title

- `Ctrl+Shift+F10`: Play back a recorded macro
  - Shows a list of available recordings for the current window
  - Add 'r' after the number (e.g., "1r") to play the recording in reverse
  - Automatically matches recordings to the current window title
