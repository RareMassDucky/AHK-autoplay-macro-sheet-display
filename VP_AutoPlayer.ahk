; Music Sheet Autoplayer (AutoHotkey v1)
; - Editable sheet textbox (paste/type your own sheets)
; - Always on top GUI
; - Play / Stop toggles hotkeys so you can play while the GUI is NOT focused
; - Hotkeys: -  =  [  ] trigger the next note
; - Supports bracket groups like [as] (sends "as" as raw text)
; - No regex; robust manual parsing
; Save this file as ANSI or UTF-8 WITHOUT BOM

#SingleInstance Force
#Persistent
#NoEnv

; ----------------------------
; STATE
; ----------------------------
PianoMusic := ""            ; raw sheet text (display)
PianoMusicCompact := ""     ; compact representation used for parsing
CurrentPos := 1             ; index into PianoMusicCompact (1-based)
KeyDelay := 80              ; ms delay between sends
isPlaying := false

; ----------------------------
; GUI
; ----------------------------
Gui, +AlwaysOnTop +Resize +ToolWindow
Gui, Font, s10, Arial

Gui, Add, Text,, ============ Virtual Piano Autoplayer ============
Gui, Add, Text,, -----------------------------------------------PASTE SHEETS HERE------------------------------------------------
Gui, Add, Edit, r10 w600 vPianoMusic gSheetChanged,    ; editable by user
Gui, Add, Text,, ------------------------------------------------------------Progress------------------------------------------------------------
Gui, Add, Edit, ReadOnly r3 w600 vNextNotes

; Buttons row (aligned)
Gui, Add, Button, x10 y+6 w100 h28 gTogglePlayStop vTogglePlayStopButton, Play
Gui, Add, Button, x+8 yp w100 h28 gClearText, Clear
Gui, Add, Button, x+8 yp w120 h28 gLoadSheet, Load Sheet

Gui, Add, Text, x10 y+8 w600, Keybinds: - (Minus), = (Equals), [ (Left Bracket), ] (Right Bracket)
Gui, Add, Text, x10 y+4 w600, Click Play to enable hotkeys. Press the keybinds to play the next note.

Gui, Show, w640 h420, Music Sheet Autoplayer
Return

; ----------------------------
; GUI CALLBACKS
; ----------------------------
TogglePlayStop:
    isPlaying := !isPlaying
    if (isPlaying)
    {
        GuiControl,, TogglePlayStopButton, Stop
        Suspend, Off            ; enable hotkeys
        Gosub, LoadSheet        ; ensure compact representation exists
    }
    else
    {
        GuiControl,, TogglePlayStopButton, Play
        Suspend, On             ; disable hotkeys
        CurrentPos := 1
        GuiControl,, NextNotes
    }
Return

ClearText:
    GuiControl,, PianoMusic, 
    PianoMusic := ""
    PianoMusicCompact := ""
    CurrentPos := 1
    GuiControl,, NextNotes
Return

LoadSheet:
    Gui, Submit, NoHide
    ; Build compact representation: remove spaces/newlines outside brackets
    DisplayMusic := PianoMusic
    Compact := ""
    inBracket := false
    Loop, Parse, DisplayMusic
    {
        ch := A_LoopField
        if (ch = "[")
        {
            inBracket := true
            Compact := Compact . ch
            continue
        }
        else if (ch = "]")
        {
            inBracket := false
            Compact := Compact . ch
            continue
        }
        if (inBracket)
        {
            Compact := Compact . ch
        }
        else
        {
            if (ch != " " && ch != "`n" && ch != "`r" && ch != "/")
                Compact := Compact . ch
        }
    }
    PianoMusicCompact := Compact
    CurrentPos := 1
    Gosub, UpdatePreview
Return

SheetChanged:
    Gui, Submit, NoHide
    CurrentPos := 1
    Gosub, UpdatePreview
Return

GuiClose:
    ExitApp
Return

; ----------------------------
; Hotkeys (work even when GUI not focused)
; ----------------------------
Suspend, On    ; start suspended until Play is pressed

-::    ; Minus key
    KeyPressStartTime := A_TickCount
    Gosub, PlayNextNote
    KeyPressStartTime := 0
Return

=::    ; Equals key
    KeyPressStartTime := A_TickCount
    Gosub, PlayNextNote
    KeyPressStartTime := 0
Return

[::    ; Left bracket
    KeyPressStartTime := A_TickCount
    Gosub, PlayNextNote
    KeyPressStartTime := 0
Return

]::    ; Right bracket
    KeyPressStartTime := A_TickCount
    Gosub, PlayNextNote
    KeyPressStartTime := 0
Return

; ----------------------------
; Playback logic (manual parsing, no regex)
; ----------------------------
PlayNextNote:
    Gui, Submit, NoHide

    ; If compact not built yet, build it now
    if (PianoMusicCompact = "" && PianoMusic != "")
        Gosub, LoadSheet

    if (PianoMusicCompact = "" || CurrentPos > StrLen(PianoMusicCompact))
    {
        ; nothing to play or reached end
        CurrentPos := 1
        GuiControl,, NextNotes
        return
    }

    ; Manual parse at CurrentPos:
    pos := CurrentPos
    ch := SubStr(PianoMusicCompact, pos, 1)
    token := ""
    if (ch = "[")
    {
        ; find closing bracket
        endPos := 0
        ; search for closing bracket manually
        idx := pos + 1
        while idx <= StrLen(PianoMusicCompact)
        {
            if SubStr(PianoMusicCompact, idx, 1) = "]"
            {
                endPos := idx
                break
            }
            idx++
        }
        if (endPos = 0)
        {
            ; malformed, treat '[' as single char
            token := "["
            CurrentPos := CurrentPos + 1
        }
        else
        {
            token := SubStr(PianoMusicCompact, pos, endPos - pos + 1)
            CurrentPos := endPos + 1
        }
    }
    else
    {
        token := SubStr(PianoMusicCompact, pos, 1)
        CurrentPos := CurrentPos + 1
    }

    ; Prepare send string: remove brackets and commas if present
    sendKeys := token
    if (SubStr(token,1,1) = "[")
    {
        sendKeys := SubStr(token, 2, StrLen(token)-2) ; remove [ ]
        StringReplace, sendKeys, sendKeys, `,, , All
    }
    sendKeys := Trim(sendKeys)

    ; Send the keys as raw input
    if (sendKeys != "")
        SendInput, {Raw}%sendKeys%

    ; Update preview
    Gosub, UpdatePreview

    Sleep, KeyDelay
Return

UpdatePreview:
    Gui, Submit, NoHide
    DisplayMusic := PianoMusic
    if (DisplayMusic = "")
    {
        GuiControl,, NextNotes, 
        return
    }

    ; Simple preview: show next ~120 characters from the original display text.
    if (PianoMusicCompact = "")
        Gosub, LoadSheet

    compactIndex := CurrentPos
    if (compactIndex < 1)
        compactIndex := 1

    ; Map compact index to display index by scanning
    count := 0
    displayStart := 1
    inBracket := false
    Loop, Parse, DisplayMusic
    {
        ch := A_LoopField
        if (ch = "[")
        {
            inBracket := true
            count := count + 1
            if (count >= compactIndex)
            {
                displayStart := A_Index
                break
            }
            continue
        }
        else if (ch = "]")
        {
            inBracket := false
            count := count + 1
            if (count >= compactIndex)
            {
                displayStart := A_Index
                break
            }
            continue
        }
        if (inBracket)
        {
            count := count + 1
            if (count >= compactIndex)
            {
                displayStart := A_Index
                break
            }
        }
        else
        {
            if (ch != " " && ch != "`n" && ch != "`r" && ch != "/")
            {
                count := count + 1
                if (count >= compactIndex)
                {
                    displayStart := A_Index
                    break
                }
            }
        }
    }

    previewLen := 120
    preview := SubStr(DisplayMusic, displayStart, previewLen)
    StringReplace, preview, preview, `r`n, %A_Space%, All
    StringReplace, preview, preview, `n, %A_Space%, All
    StringReplace, preview, preview, `r, %A_Space%, All

    GuiControl,, NextNotes, %preview%
Return

; ----------------------------
; End
; ----------------------------
