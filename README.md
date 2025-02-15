# MouseMacros

A tool for recording and playing back mouse and keyboard actions.

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
