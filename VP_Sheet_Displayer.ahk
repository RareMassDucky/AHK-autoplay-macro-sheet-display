#SingleInstance Force
#Persistent
SetBatchLines, -1

; ---------------- GUI ----------------
Gui, +AlwaysOnTop
Gui, Font, s10

Gui, Add, Text,, Current Segment:

; Previous (slightly bigger gray)
Gui, Font, s12 cGray
Gui, Add, Text, vPrevBox w250 h30 Center

; Current (BIG, now RED)
Gui, Font, s40 cRed
Gui, Add, Text, vPreviewBox w250 h80 Center

; Next (slightly bigger gray)
Gui, Font, s12 cGray
Gui, Add, Text, vNextBox w250 h30 Center

; Reset font for rest
Gui, Font, s10 cBlack
Gui, Add, Button, gToggleFollow vFollowBtn w250, Toggle Follow

Gui, Add, Edit, vMainText w400 h300 x270 y0 gTextChanged

Gui, Show,, Key Follower
return

; ---------------- VARIABLES ----------------
FollowMode := false
CurrentIndex := 1
ParsedKeys := []

; ---------------- PARSE TEXT (SAFE) ----------------
ParseKeys() {
    global ParsedKeys, MainText

    ParsedKeys := []
    Clean := RegExReplace(MainText, "`r|`n| ")

    pos := 1
    while (pos <= StrLen(Clean)) {
        if RegExMatch(Clean, "\[[^\]]*]|.", m, pos) {
            ParsedKeys.Push(m)
            pos += StrLen(m)
        } else {
            pos++
        }
    }
}

; ---------------- UPDATE PREVIEW ----------------
UpdatePreview() {
    global ParsedKeys, CurrentIndex

    max := ParsedKeys.MaxIndex()
    if (max < 1) {
        GuiControl,, PreviewBox,
        GuiControl,, PrevBox,
        GuiControl,, NextBox,
        return
    }

    if (CurrentIndex > max)
        CurrentIndex := 1

    curr := ParsedKeys[CurrentIndex]

    ; Previous 4
    p1 := (CurrentIndex > 1)  ? ParsedKeys[CurrentIndex - 1] : ""
    p2 := (CurrentIndex > 2)  ? ParsedKeys[CurrentIndex - 2] : ""
    p3 := (CurrentIndex > 3)  ? ParsedKeys[CurrentIndex - 3] : ""
    p4 := (CurrentIndex > 4)  ? ParsedKeys[CurrentIndex - 4] : ""

    prevLine := p4 " " p3 " " p2 " " p1

    ; Next 4
    n1 := (CurrentIndex < max)        ? ParsedKeys[CurrentIndex + 1] : ""
    n2 := (CurrentIndex + 1 < max)    ? ParsedKeys[CurrentIndex + 2] : ""
    n3 := (CurrentIndex + 2 < max)    ? ParsedKeys[CurrentIndex + 3] : ""
    n4 := (CurrentIndex + 3 < max)    ? ParsedKeys[CurrentIndex + 4] : ""

    nextLine := n1 " " n2 " " n3 " " n4

    ; Update GUI
    GuiControl,, PrevBox, % prevLine
    GuiControl,, PreviewBox, % curr
    GuiControl,, NextBox, % nextLine
}

; ---------------- GUI EVENTS ----------------
TextChanged:
    Gui, Submit, NoHide
    CurrentIndex := 1
    ParseKeys()
    UpdatePreview()
return

ToggleFollow:
    FollowMode := !FollowMode
    GuiControl,, FollowBtn, % FollowMode ? "Following: ON" : "Toggle Follow"
return

; ---------------- KEY LISTENER ----------------
~*a::CheckKey("a")
~*b::CheckKey("b")
~*c::CheckKey("c")
~*d::CheckKey("d")
~*e::CheckKey("e")
~*f::CheckKey("f")
~*g::CheckKey("g")
~*h::CheckKey("h")
~*i::CheckKey("i")
~*j::CheckKey("j")
~*k::CheckKey("k")
~*l::CheckKey("l")
~*m::CheckKey("m")
~*n::CheckKey("n")
~*o::CheckKey("o")
~*p::CheckKey("p")
~*q::CheckKey("q")
~*r::CheckKey("r")
~*s::CheckKey("s")
~*t::CheckKey("t")
~*u::CheckKey("u")
~*v::CheckKey("v")
~*w::CheckKey("w")
~*x::CheckKey("x")
~*y::CheckKey("y")
~*z::CheckKey("z")
~*1::CheckKey("1")
~*2::CheckKey("2")
~*3::CheckKey("3")
~*4::CheckKey("4")
~*5::CheckKey("5")
~*6::CheckKey("6")
~*7::CheckKey("7")
~*8::CheckKey("8")
~*9::CheckKey("9")
~*0::CheckKey("0")
~*Space::CheckKey(" ")

; extra Virtual Piano black-key symbols
~*!::CheckKey("!")
~*$::CheckKey("$")
~*(::CheckKey("(")

; ---------------- FIXED SPECIAL KEYS ----------------
; @  (Shift+2 on most layouts)
~*+2::CheckKey("@")

; ^  (Shift+6)
~*+6::CheckKey("^")

; *  (Shift+8)
~*+8::CheckKey("*")

; %  (Shift+5)
~*+5::CheckKey("%")

; $  (Shift+4)
~*+4::CheckKey("$")

; ---------------- CHECK KEY LOGIC ----------------
CheckKey(key) {
    global FollowMode, ParsedKeys, CurrentIndex

    if (!FollowMode)
        return

    if (CurrentIndex > ParsedKeys.MaxIndex())
        return

    expected := ParsedKeys[CurrentIndex]

    ; Combo?
    if (SubStr(expected, 1, 1) = "[" && SubStr(expected, 0) = "]") {
        combo := Trim(expected, "[]")
        keys := StrSplit(combo)

        for each, k in keys {
            if !GetKeyState(k, "P")
                return
        }
    } else {
        if (key != expected)
            return
    }

    CurrentIndex++
    UpdatePreview()
}