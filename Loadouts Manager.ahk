
; --- Start-up Checks --- ;

#Requires AutoHotkey v2.0

global ResourceFolder := A_Temp "\LoadoutsManager"

DirCreate(ResourceFolder)

FileInstall("loadouts\hunter.png", ResourceFolder "\hunter.png", 1)
FileInstall("loadouts\warlock.png", ResourceFolder "\warlock.png", 1)
FileInstall("loadouts\titan.png", ResourceFolder "\titan.png", 1)

advanced_copy_check := "Global\loadouts_D2"

DllCall("CreateMutex", "Ptr", 0, "Int", 0, "Str", advanced_copy_check, "Ptr")

if (A_LastError == 183)
{
    ExitApp
}

if !A_IsAdmin
{
    Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp
}


#Include "Loadouts Manager UI.ahk"

aspect := A_ScreenWidth / A_ScreenHeight
if (Abs(aspect - 16/9) > 0.01) {
    MsgBox("The macro does not support resolutions other than 16:9.")
    ExitApp
}

; --- Start-up Checks --- ;

; --- Start-up Variables --- ;

global SwapSettings := Map()
global Loadouts := Map()

global SettingsFile := A_ScriptDir "\loadouts_d2\settings.ini"

LoadSettings()

ScaleX := A_ScreenWidth / 1920
ScaleY := A_ScreenHeight / 1080

global QPF := 0
DllCall("QueryPerformanceFrequency", "Int64*", &QPF)

#HotIf WinActive("ahk_exe destiny2.exe")

if SwapHotkeys["27k"] != "None"
    hotkey(
        SwapHotkeys["27k"],
        (*) => Swaps("27k")
    )

if SwapHotkeys["3074"] != "None"
    hotkey(
        SwapHotkeys["3074"],
        (*) => Swaps("3074")
    )

if SwapHotkeys["noport"] != "None"
    hotkey(
        SwapHotkeys["noport"],
        (*) => Swaps("noport")
    ) 

WatchLast := ""
Watching := false
LoadoutMenuStateCheck := 0
oldXSwap := 0
ForcedNormalDelay := 0

GearPositions := Map(
    "Helmet",    {x:1413, y:269},
    "Arms",      {x:1413, y:388},
    "Chest",     {x:1413, y:510},
    "Legs",      {x:1413, y:628},
    "Class Item",{x:1413, y:769}
)

LoadoutPositions := [
    {x:110,y:380,test:220},
    {x:210,y:380,test:320},
    {x:310,y:380,Test:420},
    {x:410,y:380,Test:520},
    {x:110,y:480,test:220},
    {x:210,y:480,test:320},
    {x:310,y:480,Test:420},
    {x:410,y:480,Test:520},
    {x:110,y:580,test:220},
    {x:210,y:580,test:320},
    {x:310,y:580,Test:420},
    {x:410,y:580,Test:520},
    {x:110,y:680,test:220},
    {x:210,y:680,test:320},
    {x:310,y:680,Test:420},
    {x:410,y:680,Test:520},
    {x:110,y:780,test:220},
    {x:210,y:780,test:320},
    {x:310,y:780,Test:420},
    {x:410,y:780,Test:520}
]

#SingleInstance Force

A_WorkingDir := A_ScriptDir

CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

SendMode("Input")

SetKeyDelay(-1)
SetMouseDelay(-1)
SetDefaultMouseSpeed(0)
SetWinDelay(-1)
SetControlDelay(-1)

; --- Start-up Variables --- ;

; --- Functions --- ;

LoadSettings()
{
    LoadGlobalSettings()
    LoadSwapHotkeys()
    LoadCurrentLoadouts()
}

LoadGlobalSettings()
{
    global Settings, SettingsFile

    SwapSettings["CurrentPreset"] :=
        IniRead(SettingsFile, "Global", "CurrentPresetUI", "hunter")

    SwapSettings["DL3074Hotkey"] :=
        IniRead(SettingsFile, "Global", "DL3074HotkeyUI", "None")

    SwapSettings["OpenMenuHotkey"] :=
        IniRead(SettingsFile, "Global", "OpenMenuHotkeyUI", "None")

    SwapSettings["UL27kHotkey"] :=
        IniRead(SettingsFile, "Global", "UL27kHotkeyUI", "None")

    SwapSettings["UL3074Hotkey"] :=
        IniRead(SettingsFile, "Global", "UL3074HotkeyUI", "None")
}

LoadSwapHotkeys()
{
    global SwapHotkeys, SettingsFile

    SwapHotkeys["27k"] :=
        IniRead(SettingsFile, "SwapHotkeys", "27k", "None")

    SwapHotkeys["3074"] :=
        IniRead(SettingsFile, "SwapHotkeys", "3074", "None")

    SwapHotkeys["noport"] :=
        IniRead(SettingsFile, "SwapHotkeys", "noport", "None")
}

LoadCurrentLoadouts()
{
    global Settings, Loadouts

    preset := SwapSettings["CurrentPreset"]

    for mode in ["27k", "3074", "noport"]
    {
        section := preset "_" mode

        Loadouts[mode] :=
            LoadLoadout(section)
    }
}

LoadLoadout(section)
{
    global SettingsFile


    return Map(

        "swapCount",
        Integer(
            IniRead(SettingsFile, section, "swapCountUI", 20)
        ),


        "untickDelay",
        Integer(
            IniRead(SettingsFile, section, "untickDelayUI", 550)
        ),


        "loadoutDelay",
        Integer(
            IniRead(SettingsFile, section, "loadoutDelayUI", 40)
        ),


        "finalLoadout",
        Integer(
            IniRead(SettingsFile, section, "finalLoadoutUI", 1)
        ),


        "advancedDelay",
        Integer(
            IniRead(SettingsFile, section, "advancedDelayUI", 1)
        ),


        "closeInventory",
        Integer(
            IniRead(SettingsFile, section, "closeInventoryUI", 1)
        ),


        "dl3074",
        Integer(
            IniRead(SettingsFile, section, "dl3074UI", 0)
        ),


        "swapTimer",
        Integer(
            IniRead(SettingsFile, section, "swapTimerUI", 1)
        ),


        "SelectedGear",
        IniRead(SettingsFile, section, "SelectedGearUI", "Helmet"),


        "selectedLoadouts",
        OptimizeLoadouts(
            IniRead(SettingsFile, section, "selectedLoadoutsUI", ""),
            Integer(
                IniRead(SettingsFile, section, "finalLoadoutUI", 1)
            )
        )
    )
}

OptimizeLoadouts(value, finalLoadout)
{
    if (Trim(value) = "")
        return []

    loadouts := []

    for item in StrSplit(value, ",")
    {
        item := Trim(item)

        if item != ""
            loadouts.Push(Integer(item))
    }

    if loadouts.Length = 0
        return []

    ordered := []

    hasFinal := false

    for item in loadouts
    {
        if item = finalLoadout
        {
            hasFinal := true
            break
        }
    }

    if hasFinal
    {
        ordered.Push(finalLoadout)

        for item in loadouts
        {
            if item != finalLoadout
                ordered.Push(item)
        }
    }
    else
    {
        ordered := loadouts.Clone()
    }

    result := [ordered[1]]

    remaining := []

    Loop ordered.Length - 1
        remaining.Push(ordered[A_Index + 1])

    current := result[1]

    while remaining.Length
    {
        currentColumn := Mod(current - 1, 4) + 1

        bestIndex := 1
        bestScore := -999999

        for index, item in remaining
        {
            itemColumn := Mod(item - 1, 4) + 1

            score := 0

            if itemColumn != currentColumn
                score += 100

            score += Abs(itemColumn - currentColumn)

            if score > bestScore
            {
                bestScore := score
                bestIndex := index
            }
        }

        current := remaining.RemoveAt(bestIndex)

        result.Push(current)
    }

    return result
}

PreciseSleep(ms)
{
    global QPF, Watching, ScaleX, ScaleY, gear

    start := 0
    now := 0
    lastWatch := 0

    DllCall("QueryPerformanceCounter", "Int64*", &start)

    target := start + (ms / 1000) * QPF

    while (now < target)
    {
        DllCall("QueryPerformanceCounter", "Int64*", &now)

        remaining := (target - now) / QPF * 1000

        if (remaining > 18)
        {
            Sleep(1)
            continue
        }

        if (Watching && now - lastWatch > QPF / 5)
        {
            lastWatch := now

            WatchPixel(
                Round(gear.x * ScaleX),
                Round(gear.y * ScaleY)
            )
        }
    }

    return ((now - start) / QPF * 1000)
}

LoadoutSwap(x, y, load_test_x) {
    global ScaleX, ScaleY, LoadoutMenuStateCheck, oldXSwap, ForcedNormalDelay

    WatchLast := PixelGetColor(
                        Round(gear.x * ScaleX),
                        Round(gear.y * ScaleY),
                    )

    if (loadout["swapTimer"] && !((WatchChanges > loadout["swapCount"]|| start + Timeout <= A_TickCount)))
        if WatchChanges > 0
            ToolTip(WatchChanges . "/" . loadout["swapCount"] . ",`n" . SwapTime . "s", 73 * ScaleX, 820 * ScaleY, 1)
        if WatchChanges <= 0
            ToolTip("0/" . loadout["swapCount"] . ",`n" . SwapTime . "s", 73 * ScaleX, 820 * ScaleY, 1)

    MouseMove(
        Round(x * ScaleX), 
        Round(y * ScaleY)
        )
    if x != oldXSwap{
        oldXSwap := x
        ForcedNormalDelay := 0
    }
    else
    {
        ForcedNormalDelay := 1
    }
    if (loadout["advancedDelay"] && ForcedNormalDelay == 0){
    PreciseSleep(15)
    exit := false
    loop 2
    {
        for y in [740, 350, 430, 470]
        {
            color := PixelGetColor(
                Round(load_test_x * ScaleX),
                Round(y * ScaleY)
            )

            if RegExMatch(color, "F.F.F.")
            {
                Send "{LButton down}"
                PreciseSleep(5)
                Send "{LButton up}"
                exit := true
                break
            }
        }
        if exit
            break
    }
    Click()
    }
    else
    {
        PreciseSleep(loadout["loadoutDelay"]/2)
        Send "{LButton down}"
        PreciseSleep(loadout["loadoutDelay"]/2)
        Send "{LButton up}"
    }
}

WatchPixel(x, y)
{
    global WatchLast
    global WatchChanges
    global SwapTime
    global start_swap_click

    c := PixelGetColor(
                        x,
                        y,
                    )

    if (c != WatchLast)
    {
        WatchChanges++
        WatchLast := c
    }
    if (start_swap_click == 0){
        start_swap_click := A_TickCount
    }
    SwapTime := Round(((A_TickCount - start_swap_click + 360)/1000),2)

}

SendModified(key)
{
    modifiers := ""

    alt := false
    ctrl := false
    shift := false
    win := false

    key := StrReplace(key, " ", "")

    if InStr(key, "Alt+")
    {
        modifiers .= "{LAlt down}"
        key := StrReplace(key, "Alt+")
        alt := true
    }

    if InStr(key, "Ctrl+")
    {
        modifiers .= "{LCtrl down}"
        key := StrReplace(key, "Ctrl+")
        ctrl := true
    }

    if InStr(key, "Shift+")
    {
        modifiers .= "{LShift down}"
        key := StrReplace(key, "Shift+")
        shift := true
    }

    if InStr(key, "Win+")
    {
        modifiers .= "{LWin down}"
        key := StrReplace(key, "Win+")
        win := true
    }


    if RegExMatch(
        key,
        "i)^(LButton|MButton|RButton|XButton1|XButton2|WheelDown|WheelUp|WheelLeft|WheelRight|CapsLock|Space|Tab|Enter|Return|Backspace|BS|Delete|Del|Insert|Ins|Home|End|PgUp|PgDn|Up|Down|Left|Right|ScrollLock|PrintScreen|Pause|Break|Escape|Esc|NumLock|Numpad\d|NumpadDot|NumpadEnter|NumpadMult|NumpadDiv|NumpadAdd|NumpadSub|F\d+)$"
    )
    {
        keyPresses := "{" key " down}{" key " up}"
    }
    else
    {
        keyPresses := ""

        for _, char in StrSplit(key)
            keyPresses .= "{" char " down}"

        for _, char in StrSplit(key)
            keyPresses .= "{" char " up}"
    }


    Send(modifiers keyPresses)


    if alt
        Send("{LAlt up}")

    if ctrl
        Send("{LCtrl up}")

    if shift
        Send("{LShift up}")

    if win
        Send("{LWin up}")
}

CheckInventory()
{

    global Watching, invLeave
    Watching := false
    invLeave := 0

    Loop 10
    {
        invscreencolor := PixelGetColor(
            Round(960 * ScaleX),
            Round(1035 * ScaleY)
        )

        invscreencolor2 := PixelGetColor(
            Round(960 * ScaleX),
            Round(1014 * ScaleY)
        )

        loadoutColor := PixelGetColor(
            Round(77 * ScaleX),
            Round(104 * ScaleY)
        )

        if (
            !RegExMatch(invscreencolor, "0xE.E.E.")
            && !RegExMatch(invscreencolor2, "0xE.E.E.")
            && !RegExMatch(loadoutColor, "0xE.E.E.")
            && !RegExMatch(loadoutColor, "0xD.D.D.")
            && !RegExMatch(invscreencolor, "0xD.D.D.")
            && !RegExMatch(invscreencolor2, "0xD.D.D.")
        )
        {
            return True
        }
    }
    else
    {
        return False
    }
}

InventoryAction(State)
{
        global LoadoutMenuStateCheck, ScaleX, ScaleY
        if (State == "Fresh")
        {
            send "{F1}"
            send "{rbutton up}"
            PreciseSleep(700)
            Loop 40
            {
                MouseMove(Round(50 * ScaleX), Round(A_ScreenHeight / 2), 0)
                Send "{Left}"
                Send "{LButton}"

                PreciseSleep(1)

                loadoutColor := PixelGetColor(
                    Round(77 * ScaleX),
                    Round(104 * ScaleY)
                )

                if (RegExMatch(loadoutColor, "0xE.E.E.") || RegExMatch(loadoutColor, "0xD.D.D."))
                {
                    LoadoutMenuStateCheck := 1
                    break
                }
                else
                {
                    LoadoutMenuStateCheck := 0
                }
            }
        } 
        else if (State == "Inventory")
        {
            Send "{Left}"
            MouseMove(Round(50 * ScaleX), Round(A_ScreenHeight / 2), 0)
            PreciseSleep(100)
        }
}

WaitForLoadoutScreen()
{
    global LoadoutMenuStateCheck, ScaleX, ScaleY

    start2  := A_TickCount
    
    Loop
    {
        loadoutColor := PixelGetColor(
            Round(77 * ScaleX),
            Round(104 * ScaleY)
        )

        if (
            (RegExMatch(loadoutColor, "0xE.E.E.") 
            || RegExMatch(loadoutColor, "0xD.D.D.")
            || LoadoutMenuStateCheck
            || A_TickCount >= start2 + 1500)
        )
            return True
    }
    return False
}

; --- Functions --- ;

; --- Main Script --- ;

Swaps(mode)
{

global SwapTime := Round(0.16 ,2)
global start_swap_click := 0
global WatchChanges := -1
global Watching := false

global LoadoutMenuStateCheck, oldXSwap

global loadout := Loadouts[mode]

global gear := GearPositions[loadout["SelectedGear"]]

global Timeout := loadout["swapCount"] * 500

FL := loadout["finalLoadout"]

if loadout["selectedLoadouts"].Length = 0
{
    return
}

if (mode != "noport")    
{
SendModified(SwapSettings["UL" mode "Hotkey"])
}

if (loadout["dl3074"] && SwapSettings["DL3074Hotkey"] != "None")
{
    PreciseSleep(100)
    SendModified(SwapSettings["DL3074Hotkey"])
}

if CheckInventory(){
    InventoryAction("Fresh")  
}
else
{
    InventoryAction("Inventory")
}

WaitForLoadoutScreen()

PreciseSleep(50)

global start := A_TickCount
Loop
{
    for index, l in loadout["selectedLoadouts"]
    {
        LoadoutInfo := LoadoutPositions[l]

        if (l != FL || loadout["swapCount"] - 4 >= WatchChanges)
        {
            LoadoutSwap(LoadoutInfo.x, LoadoutInfo.y, LoadoutInfo.Test)
        }
    }

    if (start + 200 <= A_TickCount)
    {
        global Watching := true
    }

    if (WatchChanges >= loadout["swapCount"]|| start + Timeout <= A_TickCount)
    {
        break
    }
}
global Watching := false
LoadoutInfo := LoadoutPositions[FL]
WatchChanges++
LoadoutSwap(LoadoutInfo.x, LoadoutInfo.y, LoadoutInfo.Test)
ToolTip("")
delays := [70, 70, 10, 10]
for index, d in delays {
    PreciseSleep(d)
    send "{LButton}"
}

global start3 := A_TickCount + loadout["untickDelay"]

if loadout["closeInventory"]
    send "{F1}"

Loop
{
    PreciseSleep(1)

    if (start3 <= A_TickCount)
    {
        break
    }
}

if (mode != "noport")
{
SendModified(SwapSettings["UL" mode "Hotkey"])
}
if (loadout["dl3074"] && SwapSettings["DL3074Hotkey"] != "None")
{
    PreciseSleep(100)
    SendModified(SwapSettings["DL3074Hotkey"])
}
oldXSwap := 0
global Watching := false
}
; --- Main Script --- ;
