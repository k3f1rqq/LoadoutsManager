; --- Init --- ;

#Include "Gdip_All.ahk"

pToken := Gdip_Startup()

if !pToken
{
    MsgBox("GDI+ failed")
    ExitApp()
}

global SettingsFolder := A_ScriptDir "\loadouts_d2"
global SettingsFile := SettingsFolder "\settings.ini"
global BackupFile := SettingsFolder "\settings_backup.ini"
if !DirExist(SettingsFolder)
    DirCreate(SettingsFolder)

global ResourceFolder := A_Temp "\LoadoutsManager"

; --- OnMessages --- ;

OnMessage(0x200, WM_MOUSEMOVE)

OnMessage(0x201, WM_LBUTTONDOWN)

OnMessage(0x20, WM_SETCURSOR)

OnMessage(0x104, WM_SYSKEYDOWN)

OnMessage(0x105, WM_SYSKEYUP)

OnMessage(0x100, WM_KEYDOWN)

OnMessage(0x101, WM_KEYUP)

; --- Variables --- ;

global WIDTH := 510
global HEIGHT := 770

global RegisteredOpenMenuHotkey := ""

global UI := {
    alpha:255,
    targetAlpha:255,
    fade:false,
    closing:false,
    mouseX:450,
    mouseY:300,
    time:0,
    visible:true,
    dragging:false
}

global Overlay := {
    visible:false,
    x:105,
    y:220,
    w:300,
    h:350,

    saveButton:{
        x:115,
        y:520,
        w:280,
        h:40,
        text:"SAVE",
        textOffsetY:-10,
        style:"green",
        hover:false,
        hoverAnim:0,
        pulse:0,
        pulseSpeed:0.08,
        pulseAmount:0
    },

    selected:[],
    gearMenuOpen:false,
    gearOptions:["Helmet","Arms","Chest","Legs","Class Item"],
    gearHover:false,
    gearHoverAnim:0,
    gearOptionHover:0,
    gearHoverNotified:false
}

global LoadoutSlots := Map()

global HotkeyState := {
    ctrl:false,
    shift:false,
    alt:false,
    modifiers:[]
}

global State := {
    class: "hunter",
    profile: "3074"
}

global Settings := []

global Profiles := Map()

; --- Settings Schema --- ;

global SettingsSchema := {
    CurrentPresetUI:{
        section:"Global",
        scope:"global",
        type:"string",
        default:"hunter"
    },
    OpenMenuHotkeyUI:{
        section:"Global",
        scope:"global",
        type:"hotkey",
        default:"None"
    },
    UL3074HotkeyUI:{
        section:"Global",
        scope:"global",
        type:"hotkey",
        default:"None"
    },
    DL3074HotkeyUI:{
        section:"Global",
        scope:"global",
        type:"hotkey",
        default:"None"
    },
    UL27kHotkeyUI:{
        section:"Global",
        scope:"global",
        type:"hotkey",
        default:"None"
    },

    swapCountUI:{
        section:"Profile",
        scope:"profile",
        type:"number",
        default:20
    },
    untickDelayUI:{
        section:"Profile",
        scope:"profile",
        type:"number",
        default:550
    },
    loadoutDelayUI:{
        section:"Profile",
        scope:"profile",
        type:"number",
        default:40
    },
    finalLoadoutUI:{
        section:"Profile",
        scope:"profile",
        type:"number",
        default:1
    },
    advancedDelayUI:{
        section:"Profile",
        scope:"profile",
        type:"toggle",
        default:true
    },
    closeInventoryUI:{
        section:"Profile",
        scope:"profile",
        type:"toggle",
        default:true
    },
    dl3074UI:{
        section:"Profile",
        scope:"profile",
        type:"toggle",
        default:false
    },
    swapTimerUI:{
        section:"Profile",
        scope:"profile",
        type:"toggle",
        default:true
    },
    selectedLoadoutsUI:{
        section:"Profile",
        scope:"profile",
        type:"loadoutList",
        default:[]
    },
    SelectedGearUI:{
        section:"Profile",
        scope:"profile",
        type:"string",
        default:"Helmet"
    },

    SwapHotkey:{
        section:"SwapHotkeys",
        scope:"swaphotkeys",
        type:"hotkey",
        default:"None"
    }

}

global GlobalSettings := CreateGlobalSettings()

global SwapHotkeys := CreateSwapHotkeys()

for _, className in ["hunter", "warlock", "titan"]
{
    Profiles[className] := Map()

    for _, profileName in ["3074", "27k", "noport"]
    {
        Profiles[className][profileName] := CreateProfile()
    }
}

; --- Buttons --- ;

global Buttons := Map()

Buttons["save"] := {

    x:14,
    y:705,

    w:482,
    h:50,

    text:"SAVE",

    style:"green",

    color:0xFF315A3A,

    hover:false,
    hoverAnim:0,

    pulse:0,
    pulseSpeed:0.08,
    pulseAmount:0,

    visible:true
}


Buttons["close"] := {

    x:470,
    y:20,

    w:20,
    h:20,

    text:"",

    style:"close",

    hover:false,

    hoverAnim:0,

    visible:true
}

; --- Panels --- ;

global Panels := Map()

Panels["classes"] := {
    x:10,
    y:53,
    w:490,
    h:100,
}

Panels["categories"] := {
    x:10,
    y:200,
    w:490,
    h:60,
}

Panels["settingsSwapHotkey"] := {
    x:15,
    y:280,
    w:235,
    h:50,
}

Panels["settingsSwapCount"] := {
    x:15,
    y:335,
    w:235,
    h:50,
}

Panels["settingsUntickDelay"] := {
    x:15,
    y:390,
    w:235,
    h:50,
}

Panels["settingsLoadoutDelay"] := {
    x:15,
    y:445,
    w:235,
    h:50,
}

Panels["settingsFinalLoadout"] := {
    x:15,
    y:500,
    w:235,
    h:50,
}

Panels["settingsAdvancedLoadoutDelay"] := {
    x:260,
    y:280,
    w:235,
    h:50,
}

Panels["settingsCloseInventory"] := {
    x:260,
    y:335,
    w:235,
    h:50,
}

Panels["settings3074DL"] := {
    x:260,
    y:390,
    w:235,
    h:50,
}

Panels["settingsSwapTimer"] := {
    x:260,
    y:445,
    w:235,
    h:50,
}

Panels["settingsLoadoutsSelecter"] := {
    x:260,
    y:500,
    w:235,
    h:50,
}


Panels["OpenMenuhotkeys"] := {
    x:15,
    y:570,
    w:235,
    h:50,
}

Panels["3074ULhotkeys"] := {
    x:15,
    y:630,
    w:235,
    h:50,
}

Panels["3074DLhotkeys"] := {
    x:260,
    y:570,
    w:235,
    h:50,
}

Panels["27kULhotkeys"] := {
    x:260,
    y:630,
    w:235,
    h:50,
}

; --- Presets --- ;

global Presets := Map()

PresetPath := ResourceFolder "\"

Presets["hunter"] := {

    x:65,
    y:63,

    size:60,

    text:"HUNTER",

    image:PresetPath "hunter.png",

    hover:false,
    hoverAnim:0,

    selected:true,
    selectedAnim:0
}

Presets["warlock"] := {

    x:225,
    y:63,

    size:60,

    text:"WARLOCK",

    image:PresetPath "warlock.png",

    hover:false,
    hoverAnim:0,

    selected:false,
    selectedAnim:0
}

Presets["titan"] := {

    x:385,
    y:63,

    size:60,

    text:"TITAN",

    image:PresetPath "titan.png",

    hover:false,
    hoverAnim:0,

    selected:false,
    selectedAnim:0
}

; --- Profiles --- ;

global ProfilesUI := Map()

ProfilesUI["3074"] := {
    x:20,
    y:210,
    w:150,
    h:42,

    text:"3074",

    hover:false,
    hoverAnim:0,

    selected:true,
    selectedAnim:1
}

ProfilesUI["27k"] := {
    x:180,
    y:210,
    w:150,
    h:42,

    text:"27k",

    hover:false,
    hoverAnim:0,

    selected:false,
    selectedAnim:0
}

ProfilesUI["noport"] := {
    x:340,
    y:210,
    w:150,
    h:42,

    text:"No Port",

    hover:false,
    hoverAnim:0,

    selected:false,
    selectedAnim:0
}

; --- Settings Layout --- ;

global SettingLayout := [

    {
        key:"swapHotkey",
        text:"Swap Hotkey",
        type:"hotkey",

        x:145,
        y:285,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"swapCountUI",
        text:"Swap Count",
        type:"number",

        min:1,
        max:999,

        x:145,
        y:340,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"untickDelayUI",
        text:"Untick Delay",
        type:"number",

        min:0,
        max:9999,

        x:145,
        y:395,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"loadoutDelayUI",
        text:"Loadout Delay",
        type:"number",

        min:0,
        max:999,

        x:145,
        y:450,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"finalLoadoutUI",
        text:"Final Loadout",
        type:"number",

        min:1,
        max:20,

        x:145,
        y:505,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },


    {
        key:"advancedDelayUI",
        text:"Advanced Loadout`nDelay",
        type:"toggle",

        x:390,
        y:285,
        w:100,
        h:40,

        fontSize:12,
        textOffsetY:-5,

        ButtonTextY:11,
        labelPosition:"left"
    },

    {
        key:"closeInventoryUI",
        text:"Close Inventory",
        type:"toggle",

        x:390,
        y:340,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"dl3074UI",
        text:"3074 DL",
        type:"toggle",

        x:390,
        y:395,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"swapTimerUI",
        text:"Swap Counter",
        type:"toggle",

        x:390,
        y:450,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },


    {
        key:"selectedLoadoutsUI",
        text:"Loadouts",
        type:"loadoutList",

        x:390,
        y:505,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },


    {
        key:"OpenMenuHotkeyUI",
        text:"Open Menu",
        type:"hotkey",

        x:145,
        y:575,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"UL3074HotkeyUI",
        text:"3074 UL",
        type:"hotkey",

        x:145,
        y:635,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"DL3074HotkeyUI",
        text:"3074 DL",
        type:"hotkey",

        x:390,
        y:575,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },

    {
        key:"UL27kHotkeyUI",
        text:"27k UL",
        type:"hotkey",

        x:390,
        y:635,
        w:100,
        h:40,

        ButtonTextY:11,

        labelPosition:"left"
    },
]

; --- Logic Functions --- ;

LoadCurrentLoadoutsUI()
{
    global Profiles, State, LoadoutSlots, SettingsFile

    for _, slot in LoadoutSlots
    {
        slot.selected := false
        slot.selectedAnim := 0
    }
    
    selected := Profiles[State.class][State.profile].selectedLoadoutsUI
    
    for _, id in selected
    {
        if LoadoutSlots.Has(id)
            LoadoutSlots[id].selected := true
    }
}

SaveCurrentLoadouts()
{
    global Profiles, State, LoadoutSlots

    selected := []

    for id, slot in LoadoutSlots
    {
        if slot.selected
            selected.Push(id)
    }
    
    Profiles[State.class][State.profile].selectedLoadoutsUI := selected

    SaveSettings(true)
}

LoadCurrentProfile()
{
    global Profiles, State, Settings, GlobalSettings, SwapHotkeys

    profile := Profiles[State.class][State.profile]

    for _, setting in Settings
    {

        if setting.key = "swapHotkey"
        {
            setting.value := SwapHotkeys[State.profile]
            continue
        }

        if GlobalSettings.HasOwnProp(setting.key)
        {
            setting.value := GlobalSettings.%setting.key%
            continue
        }

        if profile.HasOwnProp(setting.key)
        {
            setting.value := profile.%setting.key%
        }
    }
}

SaveCurrentProfile()
{
    global Profiles, State, Settings, GlobalSettings, SwapHotkeys

    profile := Profiles[State.class][State.profile]

    for _, setting in Settings
    {

        if setting.key = "swapHotkey"
        {
            SwapHotkeys[State.profile] := setting.value
            continue
        }

        if GlobalSettings.HasOwnProp(setting.key)
        {
            GlobalSettings.%setting.key% := setting.value
            continue
        }

        if profile.HasOwnProp(setting.key)
        {
            profile.%setting.key% := setting.value
        }
    }
}

ArrayToString(arr)
{
    result := ""

    for index, value in arr
    {
        if index > 1
            result .= ","

        result .= value
    }

    return result
}

StringToArray(text)
{
    result := []

    if text = ""
        return result

    for _, value in StrSplit(text,",")
    {
        result.Push(
            Integer(value)
        )
    }

    return result
}

SyncUIState()
{
    global State, Presets, ProfilesUI, GlobalSettings

    for name,preset in Presets
        preset.selected := false

    if Presets.Has(State.class)
        Presets[State.class].selected := true

    for name,profile in ProfilesUI
        profile.selected := false

    if ProfilesUI.Has(State.profile)
        ProfilesUI[State.profile].selected := true
}

SaveSettings(saveSelectedLoadouts := false)
{
    global SettingsSchema
    global GlobalSettings
    global Profiles
    global SwapHotkeys
    global SettingsFile

    for key, schema in SettingsSchema.OwnProps()
    {
        switch schema.scope
        {
            case "global":
            {
                value := GlobalSettings.%key%

                if Type(value) = "Array"
                    value := ArrayToString(value)

                if schema.type = "toggle"
                    value := value ? 1 : 0

                IniWrite(
                    value,
                    SettingsFile,
                    schema.section,
                    key
                )
            }

            case "swaphotkeys":
            {
                for profileName, value in SwapHotkeys
                {
                    IniWrite(
                        value,
                        SettingsFile,
                        schema.section,
                        profileName
                    )
                }
            }
        }
    }
    for className, classProfiles in Profiles
    {
        for profileName, profile in classProfiles
        {
            section := className "_" profileName

            for key, schema in SettingsSchema.OwnProps()
            {
                if schema.scope != "profile"
                    continue

                if key = "selectedLoadoutsUI" && !saveSelectedLoadouts
                    continue

                value := profile.%key%

                if Type(value) = "Array"
                    value := ArrayToString(value)

                if schema.type = "toggle"
                    value := value ? 1 : 0

                IniWrite(
                    value,
                    SettingsFile,
                    section,
                    key
                )
            }
        }
    }
}

CreateSettingsBackup()
{
    global SettingsFile, BackupFile

    if FileExist(SettingsFile)
    {
        FileCopy(
            SettingsFile,
            BackupFile,
            true
        )
    }
}

RestoreSettingsBackup()
{
    global SettingsFile, BackupFile

    if !FileExist(BackupFile)
        return

    FileCopy(
        BackupFile,
        SettingsFile,
        true
    )

    FileDelete(BackupFile)
}

DeleteSettingsBackup()
{
    global BackupFile
    if FileExist(BackupFile)
        FileDelete(BackupFile)
}

LoadSettingsUI()
{
    global SettingsSchema
    global GlobalSettings
    global Profiles
    global SwapHotkeys
    global SettingsFile

    for key, schema in SettingsSchema.OwnProps()
    {
        switch schema.scope
        {
            case "global":
            {
                defaultValue := schema.default

                if Type(defaultValue) = "Array"
                    defaultValue := ""

                value := IniRead(
                    SettingsFile,
                    schema.section,
                    key,
                    defaultValue
                )

                switch schema.type
                {
                    case "number":
                        value := Integer(value)

                    case "toggle":
                        value := (value = "1")

                    case "loadoutList":
                        value := StringToArray(value)

                    case "hotkey":
                        if value = ""
                            value := "None"
                }

                GlobalSettings.%key% := value
            }

            case "swaphotkeys":
            {
                for profileName, _ in SwapHotkeys
                {
                    SwapHotkeys[profileName] := IniRead(
                        SettingsFile,
                        schema.section,
                        profileName,
                        schema.default
                    )
                }
            }
        }
    }

    for className, classProfiles in Profiles
    {
        for profileName, profile in classProfiles
        {
            section := className "_" profileName

            for key, schema in SettingsSchema.OwnProps()
            {
                if schema.scope != "profile"
                    continue

                defaultValue := schema.default

                if Type(defaultValue) = "Array"
                    defaultValue := ""

                value := IniRead(
                    SettingsFile,
                    section,
                    key,
                    defaultValue
                )

                switch schema.type
                {
                    case "number":
                        value := Integer(value)

                    case "toggle":
                        value := (value = "1")

                    case "loadoutList":
                        value := StringToArray(value)
                }

                profile.%key% := value
            }
        }
    }
}

CancelMenu()
{
    RestoreSettingsBackup()

    LoadSettingsUI()

    State.class := GlobalSettings.CurrentPresetUI

    LoadCurrentProfile()
    LoadCurrentLoadoutsUI()

    SyncUIState()

    HideMenu()
}

HandleHotkeyInput(setting, vk, lParam := 0)
{
    global

    ctrl := HotkeyState.ctrl
    shift := HotkeyState.shift
    alt := HotkeyState.alt

    ; Bit 24 of lParam is the extended-key flag. The numpad nav keys
    ; (sent when NumLock is off) share their VK with the main-keyboard
    ; ones and are distinguished only by this flag being absent.
    extended := (lParam >> 24) & 1

    key := VKToEnglish(vk, extended)

    if (key == "")
        return

    result := ""

    if ctrl
        result .= "Ctrl + "

    if alt
        result .= "Alt + "

    if shift
        result .= "Shift + "

    result .= key

    setting.value := result

    FinishHotkeyEdit(setting)

    SaveCurrentProfile()
    SaveSettings()
}

VKToEnglish(vk, extended := 1)
{
    ; With NumLock off the numpad sends these VKs without the extended
    ; flag, while the dedicated nav cluster always sets it.
    static numpadNav := Map(
        12,"NumpadClear",
        13,"NumpadEnter",
        33,"NumpadPgUp",
        34,"NumpadPgDn",
        35,"NumpadEnd",
        36,"NumpadHome",
        37,"NumpadLeft",
        38,"NumpadUp",
        39,"NumpadRight",
        40,"NumpadDown",
        45,"NumpadIns",
        46,"NumpadDel",
    )

    if !extended && numpadNav.Has(vk)
        return numpadNav[vk]

    static keys := Map(

        ; Letters
        65,"A",
        66,"B",
        67,"C",
        68,"D",
        69,"E",
        70,"F",
        71,"G",
        72,"H",
        73,"I",
        74,"J",
        75,"K",
        76,"L",
        77,"M",
        78,"N",
        79,"O",
        80,"P",
        81,"Q",
        82,"R",
        83,"S",
        84,"T",
        85,"U",
        86,"V",
        87,"W",
        88,"X",
        89,"Y",
        90,"Z",


        ; Numbers
        48,"0",
        49,"1",
        50,"2",
        51,"3",
        52,"4",
        53,"5",
        54,"6",
        55,"7",
        56,"8",
        57,"9",


        ; Function keys
        112,"F1",
        113,"F2",
        114,"F3",
        115,"F4",
        116,"F5",
        117,"F6",
        118,"F7",
        119,"F8",
        120,"F9",
        121,"F10",
        122,"F11",
        123,"F12",
        124,"F13",
        125,"F14",
        126,"F15",
        127,"F16",
        128,"F17",
        129,"F18",
        130,"F19",
        131,"F20",
        132,"F21",
        133,"F22",
        134,"F23",
        135,"F24",


        ; Main keyboard symbols
        186,";",
        187,"=",
        188,",",
        189,"-",
        190,".",
        191,"/",
        192,"~",

        219,"[",
        220,"\",
        221,"]",
        222,"'",


        ; Control keys
        8,"Backspace",
        9,"Tab",
        13,"Enter",
        20,"CapsLock",
        27,"Escape",
        32,"Space",
        46,"Delete",


        ; Navigation
        33,"PgUp",
        34,"PgDn",
        35,"End",
        36,"Home",
        37,"Left",
        38,"Up",
        39,"Right",
        40,"Down",


        ; Insert / system
        45,"Insert",
        44,"PrintScreen",
        145,"ScrollLock",
        19,"Pause",


        ; Windows / menu
        91,"LWin",
        92,"RWin",
        93,"AppsKey",


        ; Numpad
        96,"Numpad0",
        97,"Numpad1",
        98,"Numpad2",
        99,"Numpad3",
        100,"Numpad4",
        101,"Numpad5",
        102,"Numpad6",
        103,"Numpad7",
        104,"Numpad8",
        105,"Numpad9",

        106,"NumpadMult",
        107,"NumpadAdd",
        109,"NumpadSub",
        110,"NumpadDot",
        111,"NumpadDiv",


        ; Lock keys
        144,"NumLock",
    )


    return keys.Has(vk)
        ? keys[vk]
        : ""
}

SetCursor(type)
{
    cursor :=
    type = "hand"
    ?
    32649 ; IDC_HAND
    :
    32512 ; IDC_ARROW


    hCursor :=
    DllCall(
        "LoadCursor",
        "ptr",
        0,
        "ptr",
        cursor,
        "ptr"
    )


    DllCall(
        "SetCursor",
        "ptr",
        hCursor
    )
}

GetKeyNameFromVK(vk)
{
    sc := DllCall(
        "MapVirtualKey",
        "UInt",
        vk,
        "UInt",
        0
    )

    name := GetKeyName(
        Format("sc{:03X}", sc)
    )

    return name
}

OnExit(*)
{
    global

    if hbm
        DllCall(
            "DeleteObject",
            "ptr",
            hbm
        )

    if hdc
        DeleteDC(
            hdc
        )

    if Bitmap
        Gdip_DisposeImage(
            Bitmap
        )

    if G
        Gdip_DeleteGraphics(
            G
        )

    for _,img in Images
    {
        if img
            Gdip_DisposeImage(img)
    }
    Gdip_Shutdown(
        pToken
    )
}

GuiClose(*)
{
    RestoreSettingsBackup()
    CancelMenu()
}

HideMenu()
{
    global UI

    if !UI.visible
        return

    UI.visible := false
    UI.fade := false
    UI.closing := false

    MainGui.Hide()
    SetTimer(
        Render,
        0
    )
}

OpenMenuGUI(*)
{
    global

    CreateSettingsBackup()

    LoadSettingsUI()

    State.class := GlobalSettings.CurrentPresetUI

    LoadCurrentProfile()
    LoadCurrentLoadoutsUI()

    SyncUIState()

    UI.visible := true
    UI.closing := false

    UI.alpha := 255
    UI.targetAlpha := 255
    UI.fade := false

    PrepareTransparentFrame()
    MainGui.Show()

    SetTimer(
        Render,
        1
    )
}

FinishAllSettingsEdit()
{
    global Settings

    for _,setting in Settings
    {
        if setting.editing
            FinishSettingEdit(setting)

        if setting.listening
            FinishHotkeyEdit(setting)
    }
}

RemoveModifierPlus(text)
{
    pos := InStr(text, " +",, -1)

    if pos
        return SubStr(text,1,pos-1)

    return text
}

FinishHotkeyEdit(setting)
{
    global HotkeyState

    if setting.listening
    {
        setting.listening := false
        setting.oldValue := ""

        HotkeyState.ctrl := false
        HotkeyState.shift := false
        HotkeyState.alt := false
    }
}

FinishSettingEdit(setting)
{
    if !setting.editing
        return

    if RegExMatch(setting.editValue,"^\d{1,3}$")
    {
        value := Integer(setting.editValue)

        if value >= setting.min && value <= setting.max
        {
            setting.value := value

            SaveCurrentProfile()
            SaveSettings()
        }
        else
        {
            setting.value := setting.oldValue
        }
    }
    else
    {
        setting.value := setting.oldValue
    }

    setting.editing := false
    setting.editValue := ""
    setting.oldValue := ""
}

UpdateModifierPreview(setting)
{
    global HotkeyState

    result := ""

    if HotkeyState.ctrl
        result .= "Ctrl + "

    if HotkeyState.alt
        result .= "Alt + "

    if HotkeyState.shift
        result .= "Shift + "

    setting.value := result
}

BuildSettings()
{
    global Settings, SettingLayout

    Settings := []

    for _, info in SettingLayout
    {
        Settings.Push({

            key:info.key,
            text:info.text,
            type:info.type,
            fontSize: info.HasOwnProp("fontSize") ? info.fontSize : 14,
            textOffsetY: info.HasOwnProp("textOffsetY") ? info.textOffsetY : 0,

            value:
            (
                info.type="toggle"
                ? false
                : info.type="number"
                ? 0
                : info.type="hotkey"
                ? "None"
                : []
            ),

            min:info.HasOwnProp("min") ? info.min : 0,
            max:info.HasOwnProp("max") ? info.max : 1,

            editing:false,
            editValue:"",

            listening:false,
            oldValue:"",

            activeAnim:0,

            x:info.x,
            y:info.y,

            labelPosition:
            info.HasOwnProp("labelPosition")
            ? info.labelPosition
            : "left",

            w:info.w,
            h:info.h,

            ButtonTextY:
            info.HasOwnProp("ButtonTextY")
            ? info.ButtonTextY
            : 11,

            hover:false,
            hoverAnim:0
        })

    }
}

ClearHoverStates()
{
    global Buttons, Presets, ProfilesUI, Settings, Panels

    for _,button in Buttons
    {
        button.hover := false
        button.hoverAnim := 0
    }

    for _,preset in Presets
    {
        preset.hover := false
        preset.hoverAnim := 0
    }

    for _,profile in ProfilesUI
    {
        profile.hover := false
        profile.hoverAnim := 0
    }

    for _,setting in Settings
    {
        setting.hover := false
        setting.hoverAnim := 0
    }

    for _,panel in Panels
    {
        panel.hover := false
        panel.hoverAnim := 0
    }
}

BuildLoadoutSlots()
{
    global LoadoutSlots, Overlay

    LoadoutSlots := Map()

    size := 42
    gap := 15

    startX := Overlay.x + 25
    startY := Overlay.y + 15


    Loop 20
    {
        index := A_Index

        col := Mod(index-1, 4)
        row := Floor((index-1)/4)

        LoadoutSlots[index] := {

            id:index,

            x:startX + col*(size+gap+12),
            y:startY + row*(size+gap),

            w:size,
            h:size,

            selected:false,
            selectedAnim:0,

            hover:false,
            hoverAnim:0
        }
    }
}

CreateGlobalSettings()
{
    global SettingsSchema

    settings := {}

    for key, schema in SettingsSchema.OwnProps()
    {
        if !schema.HasOwnProp("scope")
            continue

        if schema.scope != "global"
            continue

        if Type(schema.default) = "Array"
        {
            settings.%key% := []
        }
        else
        {
            settings.%key% := schema.default
        }
    }

    return settings
}

CreateSwapHotkeys()
{
    global SettingsSchema

    hotkeys := Map()

    defaultValue := "None"

    for key, schema in SettingsSchema.OwnProps()
    {
        if schema.scope = "swaphotkeys"
        {
            defaultValue := schema.default
            break
        }
    }

    for _, profileName in ["3074", "27k", "noport"]
        hotkeys[profileName] := defaultValue

    return hotkeys
}

CreateProfile()
{
    global SettingsSchema

    profile := {}

    for key, data in SettingsSchema.OwnProps()
    {
        if data.scope != "profile"
            continue


        if Type(data.default) = "Array"
        {
            profile.%key% := []
        }
        else
        {
            profile.%key% := data.default
        }
    }

    return profile
}

UpdateHoverState()
{
    global UI, Settings, Buttons, Presets, ProfilesUI, hwnd

    MouseGetPos(
        &mx,
        &my,
        &win
    )

    if win != hwnd
    {
        for _,button in Buttons
            button.hover := false

        for _,setting in Settings
            setting.hover := false

        for _,preset in Presets
            preset.hover := false

        for _,profile in ProfilesUI
            profile.hover := false

        return
    }
}

CheckFirstRun()
{
    RegisterOpenMenuHotkey()
}

RegisterOpenMenuHotkey()
{
    global GlobalSettings, RegisteredOpenMenuHotkey

    if RegisteredOpenMenuHotkey
    {
        oldKey := RegisteredOpenMenuHotkey
        if (SubStr(oldKey, 1, 2) = "~*")
            plainKey := SubStr(oldKey, 3)
        else
            plainKey := oldKey

        Hotkey(oldKey,, "Delete")
        Hotkey(plainKey,, "Delete")
        Hotkey("~*" plainKey,, "Delete")

        RegisteredOpenMenuHotkey := ""
    }

    rawKey := Trim(GlobalSettings.OpenMenuHotkeyUI)
    if (rawKey = "" || rawKey = "None")
        return

    openKey := NormalizeHotkeyString(rawKey, false)
    openKey := RegExReplace(openKey, "[^\x20-\x7E]", "")
    if (openKey = "")
        return

    key := "~*" openKey
    success := Hotkey(key, OpenMenuGUI, "On")
    if (success)
        RegisteredOpenMenuHotkey := key
}

NormalizeHotkeyString(text, addTildeStar := false)
{
    text := Trim(text)

    if (text = "" || text = "None")
        return ""

    text := RegExReplace(text, "\s*\+\s*", "+")
    text := RegExReplace(text, "^\+|\+$", "")
    text := RegExReplace(text, "\++", "+")

    parts := StrSplit(text, "+")
    modifiers := ""
    key := ""

    for _, part in parts
    {
        part := Trim(part)
        if (part = "")
            continue

        switch part
        {
            case "Ctrl":
                modifiers .= "^"
            case "Alt":
                modifiers .= "!"
            case "Shift":
                modifiers .= "+"
            case "Win", "LWin", "RWin":
                modifiers .= "#"
            case "AppsKey", "Space", "Tab", "Enter", "Escape", "Delete", "Backspace", "Home", "End", "PgUp", "PageUp", "PgDn", "PageDown", "Left", "Right", "Up", "Down":
                key := part
            default:
                if (key = "")
                    key := part
        }
    }

    if (key = "")
        return ""

    if !RegExMatch(key, "^[0-9]+$")
        key := StrUpper(key)

    result := modifiers . key

    if (addTildeStar && !RegExMatch(result, "^(~|\*)"))
        result := "~*" . result

    return result
}

; --- Render Functions --- ;

Render()
{
    global

    if !UI.visible
        return
    UpdateHoverState()
    if UI.fade
    {
        UI.alpha += (UI.targetAlpha - UI.alpha) * 0.7

        if UI.closing
        {
            if UI.alpha <= 3
            {
                UI.alpha := 0

                UI.fade := false
                UI.visible := false
                UI.closing := false

                MainGui.Hide()

                SetTimer(
                    Render,
                    0
                )

                return
            }
        }
        else
        {
            if UI.alpha >= 252
            {
                UI.alpha := 255
                UI.fade := false
            }
        }
    }

    if UI.dragging
        return

    if !WinActive(
        "ahk_id " hwnd
    )
        return
    
    UI.time += 0.008

    Draw()

    newHbm :=
        Gdip_CreateHBITMAPFromBitmap(Bitmap)

    oldHbm :=
        SelectObject(
            hdc,
            newHbm
        )

    if oldHbm
        DllCall(
            "DeleteObject",
            "ptr",
            oldHbm
        )

    hbm :=
        newHbm

    UpdateLayeredWindow(
        hwnd,
        hdc,
        ,
        ,
        WIDTH,
        HEIGHT,
        UI.alpha
    )
}

DrawHoverFrame(x,y,w,h,a)
{
    global G

    offset :=
        7 - (a * 3)

    alpha :=
        Round(
            255*(a**2)
        )

    if alpha <= 0
        return

    color := 0xFFFFFF

    pen :=
    Gdip_CreatePen(
        (alpha<<24)|color,
        1
    )

    Gdip_DrawRectangle(
        G,
        pen,

        x-offset,
        y-offset,

        w+(offset*2),
        h+(offset*2)
    )

    Gdip_DeletePen(pen)
}

DrawSettingHoverFrame(x,y,w,h,a)
{
    global G

    offset :=
        7 - (a * 3)

    alpha :=
        Round(255*(a**2))

    if alpha <= 0
        return

    pen :=
    Gdip_CreatePen(
        (alpha<<24)|0xFFFFFF,
        1
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x-offset,
        y-offset,
        w+(offset*2),
        h+(offset*2)
    )

    Gdip_DeletePen(pen)
}

DrawPresetHoverFrame(x,y,size,a)
{
    global G

    offset :=
        8 - (a * 3)

    alpha :=
        Round(255*(a**2))

    color :=
        (alpha << 24)
        | 0xFFFFFF

    pen :=
    Gdip_CreatePen(
        color,
        1
    )

    Gdip_DrawLine(
        G,
        pen,
        x+size/2,
        y-offset,
        x+size+offset,
        y+size/2
    )

    Gdip_DrawLine(
        G,
        pen,
        x+size+offset,
        y+size/2,
        x+size/2,
        y+size+offset
    )

    Gdip_DrawLine(
        G,
        pen,
        x+size/2,
        y+size+offset,
        x-offset,
        y+size/2
    )

    Gdip_DrawLine(
        G,
        pen,
        x-offset,
        y+size/2,
        x+size/2,
        y-offset
    )

    Gdip_DeletePen(
        pen
    )
}

DrawBackground()
{
    global

    bg :=
    Gdip_CreateLineBrush(
        0,
        0,
        WIDTH,
        HEIGHT,
        0xFF70676C,
        0xFF444952,
        1
    )

    Gdip_FillRectangle(
        G,
        bg,
        0,
        0,
        WIDTH,
        HEIGHT
    )

    Gdip_DeleteBrush(bg)

    cx :=
        WIDTH/2 +
        Sin(UI.time*0.08)*18

    cy :=
        HEIGHT/2 +
        Cos(UI.time*0.06)*14

    DrawSoftCircle(
        cx,
        cy,
        700,
        10
    )

    DrawSoftCircle(
        cx-80,
        cy+40,
        500,
        7
    )
}

DrawSoftCircle(x,y,size,alpha)
{
    global G

    Loop 12
    {
        i := A_Index

        currentSize :=
            size + i*45

        currentAlpha :=
            alpha - i*0.8

        if currentAlpha <= 0
            continue

        color :=
            (Round(currentAlpha)<<24)
            | 0x7998B6

        brush :=
            Gdip_BrushCreateSolid(
                color
            )

        Gdip_FillEllipse(
            G,
            brush,
            x-currentSize/2,
            y-currentSize/2,
            currentSize,
            currentSize
        )

        Gdip_DeleteBrush(
            brush
        )
    }
}

DrawAnimatedBorder()
{
    global

    outer :=
    Gdip_CreatePen(
        0xFFE0B85C,
        4
    )

    Gdip_DrawRectangle(
        G,
        outer,
        3,
        3,
        WIDTH-6,
        HEIGHT-6
    )

    Gdip_DeletePen(
        outer
    )

    inner :=
    Gdip_CreatePen(
        0xFFF0D58A,
        0
    )

    Gdip_DrawRectangle(
        G,
        inner,
        6,
        6,
        WIDTH-12,
        HEIGHT-12
    )

    Gdip_DeletePen(
        inner
    )
}

Draw()
{
    global

    Gdip_GraphicsClear(
        G,
        0x00000000
    )

    DrawBackground()

    DrawSectionTitles()

    DrawPanels()

    DrawAnimatedBorder()

    DrawPresets()

    DrawProfiles()

    DrawSettings()

    DrawButtons()

    if Overlay.visible
    {
        DrawLoadoutOverlay()
    }
}

DrawLoadoutOverlay()
{
    global G, Overlay

    dark :=
    Gdip_BrushCreateSolid(
        0xAA000000
    )

    Gdip_FillRectangle(
        G,
        dark,
        0,
        0,
        WIDTH,
        HEIGHT
    )

    Gdip_DeleteBrush(dark)

    x := Overlay.x
    y := Overlay.y

    bg :=
    Gdip_CreateLineBrush(
        x,
        y,
        x+Overlay.w,
        y+Overlay.h,
        0xFF70676C,
        0xFF444952,
        1
    )

    Gdip_FillRectangle(
        G,
        bg,
        x,
        y,
        Overlay.w,
        Overlay.h
    )

    Gdip_DeleteBrush(bg)

    DrawSoftCircle(
        x+150,
        y+150,
        350,
        8
    )

    DrawOverlayFrame(
        x,
        y,
        Overlay.w,
        Overlay.h
    )
    gearBtnW := 120
    gearBtnH := 34
    gearBtnX := x + 20
    gearBtnY := y + Overlay.h - gearBtnH - 16

    currentGear := "Helmet"
    if Profiles.Has(State.class)
        if Profiles[State.class].Has(State.profile)
            if Profiles[State.class][State.profile].HasOwnProp("SelectedGearUI")
                currentGear := Profiles[State.class][State.profile].SelectedGearUI

    if Overlay.gearHover
    {
        Overlay.gearHoverAnim += (1-Overlay.gearHoverAnim)*0.45
    }
    else
    {
        Overlay.gearHoverAnim += (0-Overlay.gearHoverAnim)*0.45
    }

    bgColor := Overlay.gearHover ? 0x401E2028 : 0x30181822
    gearBg := Gdip_BrushCreateSolid(bgColor)
    Gdip_FillRectangle(G, gearBg, gearBtnX, gearBtnY, gearBtnW, gearBtnH)
    Gdip_DeleteBrush(gearBg)

    pen := Gdip_CreatePen(0xFFFFFFFF, Overlay.gearHover ? 2 : 1)
    Gdip_DrawRectangle(G, pen, gearBtnX, gearBtnY, gearBtnW, gearBtnH)
    Gdip_DeletePen(pen)

    Gdip_TextToGraphics(
        G,
        currentGear,
        "x" gearBtnX " y" (gearBtnY+7) " w" gearBtnW " h28 s18 Bold cFFE8EDF5 Center"
    )

    Gdip_TextToGraphics(
        G,
        "▾",
        "x" (gearBtnX+gearBtnW-18) " y" (gearBtnY+9) " w16 h28 Center s18 cFFE8EDF5"
    )

    if Overlay.gearHoverAnim > 0.01
        DrawHoverFrame(gearBtnX, gearBtnY, gearBtnW, gearBtnH, Overlay.gearHoverAnim)

    for _,slot in LoadoutSlots
    {
        slot.hover :=
        (
            UI.mouseX > slot.x &&
            UI.mouseX < slot.x + slot.w &&
            UI.mouseY > slot.y &&
            UI.mouseY < slot.y + slot.h
        )
    }

    btn := Overlay.saveButton

    btn.hover :=
    (
        UI.mouseX > btn.x &&
        UI.mouseX < btn.x + btn.w &&
        UI.mouseY > btn.y &&
        UI.mouseY < btn.y + btn.h
    )

    if Overlay.gearMenuOpen
    {
        menuX := gearBtnX
        menuY := gearBtnY + gearBtnH + 6
        optH := 34

        count := 0
        for _,_ in Overlay.gearOptions
            count++

        menuH := optH * count

        bg2 := Gdip_CreateLineBrush(menuX, menuY, menuX+gearBtnW, menuY+menuH, 0xFF70676C, 0xFF444952, 1)
        Gdip_FillRectangle(G, bg2, menuX, menuY, gearBtnW, menuH)
        Gdip_DeleteBrush(bg2)

        pen2 := Gdip_CreatePen(0xFFFFFFFF, 1)
        Gdip_DrawRectangle(G, pen2, menuX, menuY, gearBtnW, menuH)
        Gdip_DeletePen(pen2)

        sepPen := Gdip_CreatePen(0xFFFFFFFF, 1)
        for index, opt in Overlay.gearOptions
        {
            yopt := menuY + (index-1)*optH
            textColor := index = Overlay.gearOptionHover ? "cFFE0B85C" : "cFFE8EDF5"
            Gdip_TextToGraphics(G, opt, "x" menuX " y" (yopt+6) " w" gearBtnW " h" optH " s18 Bold " textColor " Center")
            if index < count
                Gdip_DrawLine(G, sepPen, menuX, yopt+optH, menuX+gearBtnW, yopt+optH)
        }
        Gdip_DeletePen(sepPen)
    }
    DrawLoadoutSlots()

    Overlay.saveButton.w := 120
    Overlay.saveButton.h := 34
    Overlay.saveButton.x := x + Overlay.w - Overlay.saveButton.w - 20
    Overlay.saveButton.y := y + Overlay.h - Overlay.saveButton.h - 16

    DrawButton(Overlay.saveButton)
}

DrawLoadoutSlots()
{
    global G, LoadoutSlots

    for _,slot in LoadoutSlots
    {
        x := slot.x
        y := slot.y

        if slot.hover
            slot.hoverAnim += (1-slot.hoverAnim)*0.45
        else
            slot.hoverAnim += (0-slot.hoverAnim)*0.45

        if slot.selected
            slot.selectedAnim += (1-slot.selectedAnim)*0.2
        else
            slot.selectedAnim += (0-slot.selectedAnim)*0.2

        if slot.selected
        {
            bgColor := 0x553B6FA8
        }
        else
        {
            bgColor := 0x35182030
        }

        brush :=
        Gdip_BrushCreateSolid(
            bgColor
        )

        Gdip_FillRectangle(
            G,
            brush,
            x,
            y,
            slot.w,
            slot.h
        )

        Gdip_DeleteBrush(brush)

        borderColor :=
        slot.selected
        ?
        0xFFE0B85C
        :
        0xFFD7DDE8

        borderSize :=
        slot.selected || slot.hover
        ?
        2
        :
        1

        pen :=
        Gdip_CreatePen(
            borderColor,
            borderSize
        )

        Gdip_DrawRectangle(
            G,
            pen,
            x,
            y,
            slot.w,
            slot.h
        )

        Gdip_DeletePen(pen)

        if slot.hoverAnim > 0.01
        {
            DrawSettingHoverFrame(
                x,
                y,
                slot.w,
                slot.h,
                slot.hoverAnim
            )
        }

        Gdip_TextToGraphics(
            G,
            String(slot.id),
            "x"
            x
            " y"
            y+13
            " w"
            slot.w
            " h25 Center s16 Bold cFFFFFFFF"
        )
    }
}

DrawOverlayFrame(x,y,w,h)
{
    global G

    pen :=
    Gdip_CreatePen(
        0xFFE0B85C,
        3
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        w,
        h
    )

    Gdip_DeletePen(pen)

    inner :=
    Gdip_CreatePen(
        0xFFF0D58A,
        1
    )

    Gdip_DrawRectangle(
        G,
        inner,
        x+3,
        y+3,
        w-6,
        h-6
    )

    Gdip_DeletePen(inner)
}

DrawSectionTitles()
{
    global G

    Gdip_TextToGraphics(
        G,
        "P  R  E  S  E  T  S",
        "x10 y37 w490 h25 Left s16 Bold cFFE8EDF5"
    )

    Gdip_TextToGraphics(
        G,
        "S  E  T  T  I  N  G  S",
        "x10 y183 w490 h25 Left s16 Bold cFFE8EDF5"
    )
}

DrawPanels()
{
    global Panels

    for _, panel in Panels
    {
        DrawPanel(panel)
    }
}

DrawPanel(panel)
{
    global G, UI

    x := Round(panel.x)
    y := Round(panel.y)

    w := panel.w
    h := panel.h

    brush := Gdip_BrushCreateSolid(0x00101822)

    Gdip_FillRectangle(
        G,
        brush,
        x,
        y,
        w,
        h
    )

    Gdip_DeleteBrush(brush)

    DrawPanelFrame(x,y,w,h)
}

DrawPanelFrame(x, y, w, h)
{
    Gdip_SetSmoothingMode(G, 3)
    corner := 1

    DrawFadeLine(
        x+corner,
        y,
        w-corner*2,
        "H"
    )

    DrawFadeLine(
        x+corner,
        y+h,
        w-corner*2,
        "H"
    )

    Gdip_SetSmoothingMode(G, 4)
}

DrawFadeLine(x, y, length, mode)
{
    global G

    fade := Round(length * 0.25)
    solid := length - fade * 2

    if mode = "H"
    {
        brush1 :=
        Gdip_CreateLineBrush(
            x,
            y,
            x+fade,
            y,
            0x00999EA6,
            0x55999EA6,
            1
        )

        pen1 :=
        Gdip_CreatePenFromBrush(
            brush1,
            1
        )

        Gdip_DrawLine(
            G,
            pen1,
            x,
            y,
            x+fade,
            y
        )

        Gdip_DeletePen(pen1)
        Gdip_DeleteBrush(brush1)

        pen :=
        Gdip_CreatePen(
            0x55999EA6,
            1
        )

        Gdip_DrawLine(
            G,
            pen,
            x+fade,
            y,
            x+fade+solid,
            y
        )

        Gdip_DeletePen(pen)

        brush2 :=
        Gdip_CreateLineBrush(
            x+fade+solid,
            y,
            x+length,
            y,
            0x55999EA6,
            0x00999EA6,
            1
        )

        pen2 :=
        Gdip_CreatePenFromBrush(
            brush2,
            1
        )

        Gdip_DrawLine(
            G,
            pen2,
            x+fade+solid,
            y,
            x+length,
            y
        )

        Gdip_DeletePen(pen2)
        Gdip_DeleteBrush(brush2)

    }
    else
    {
        brush1 :=
        Gdip_CreateLineBrush(
            x,
            y,
            x,
            y+fade,
            0x00999EA6,
            0x55999EA6,
            1
        )

        pen1 :=
        Gdip_CreatePenFromBrush(
            brush1,
            1
        )

        Gdip_DrawLine(
            G,
            pen1,
            x,
            y,
            x,
            y+fade
        )

        Gdip_DeletePen(pen1)
        Gdip_DeleteBrush(brush1)

        pen :=
        Gdip_CreatePen(
            0x55999EA6,
            1
        )

        Gdip_DrawLine(
            G,
            pen,
            x,
            y+fade,
            x,
            y+fade+solid
        )

        Gdip_DeletePen(pen)

        brush2 :=
        Gdip_CreateLineBrush(
            x,
            y+fade+solid,
            x,
            y+length,
            0x55999EA6,
            0x00999EA6,
            1
        )

        pen2 :=
        Gdip_CreatePenFromBrush(
            brush2,
            1
        )

        Gdip_DrawLine(
            G,
            pen2,
            x,
            y+fade+solid,
            x,
            y+length
        )

        Gdip_DeletePen(pen2)
        Gdip_DeleteBrush(brush2)
    }
}

DrawHotkeySetting(setting)
{
    global G

    x := setting.x
    y := setting.y

    if setting.hover
    {
        setting.hoverAnim +=
            (1-setting.hoverAnim)*0.25
    }
    else
    {
        setting.hoverAnim +=
            (0-setting.hoverAnim)*0.45
    }

    if setting.labelPosition = "top"
    {
        Gdip_TextToGraphics(
            G,
            setting.text,
            "x" x
            " y" y-20
            " w" setting.w
            " h25 Center s14 Bold cFFE8EDF5"
        )
    }
    else
    {
        Gdip_TextToGraphics(
            G,
            setting.text,
            "x" x-120
            " y" y+13
            " w400 h25 s14 Bold cFFE8EDF5"
        )
    }

    if setting.listening
    {
        setting.activeAnim +=
            (1-setting.activeAnim)*0.15
    }
    else
    {
        setting.activeAnim +=
            (0-setting.activeAnim)*0.15
    }

    bgColor :=
    (
    setting.listening
    ? 0x553B6FA8
    : 0x35182030
    )

    bg :=
    Gdip_BrushCreateSolid(
        bgColor
    )

    Gdip_FillRectangle(
        G,
        bg,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeleteBrush(bg)

    pen :=
    Gdip_CreatePen(
        setting.listening || setting.hover
        ? 0xFFFFFFFF
        : 0xFFD7DDE8,

        setting.listening || setting.hover
        ? 2
        : 1
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeletePen(pen)

    if setting.hoverAnim > 0.01
    {
        DrawSettingHoverFrame(
            x,
            y,
            setting.w,
            setting.h,
            setting.hoverAnim
        )
    }

    display := setting.value

    fontSize := 16

    if StrLen(display) > 12
        fontSize := 14

    if StrLen(display) > 16
        fontSize := 12

    if StrLen(display) > 20
        fontSize := 10

    Gdip_TextToGraphics(
        G,
        display,
        "x"
        x
        " y"
        y + setting.ButtonTextY
        " w"
        setting.w
        " h35 Center s"
        fontSize
        " Bold cFFFFFFFF"
    )
}

DrawLoadoutListSetting(setting)
{
    global G

    x := setting.x
    y := setting.y

    if setting.hover
        setting.hoverAnim += (1-setting.hoverAnim)*0.25
    else
        setting.hoverAnim += (0-setting.hoverAnim)*0.45

    Gdip_TextToGraphics(
        G,
        setting.text,
        "x" x-120
        " y" y+13
        " w400 h25 s14 Bold cFFE8EDF5"
    )

    bg := Gdip_BrushCreateSolid(0x35182030)

    Gdip_FillRectangle(
        G,
        bg,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeleteBrush(bg)

    pen := Gdip_CreatePen(
        0xFFFFFFFF,
        setting.hover ? 2 : 1
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeletePen(pen)

    if setting.hoverAnim > 0.01
    {
        DrawSettingHoverFrame(
            x,
            y,
            setting.w,
            setting.h,
            setting.hoverAnim
        )
    }

    Gdip_TextToGraphics(
        G,
        "Select",
        "x" x
        " y" y+13
        " w" setting.w
        " h30 Center s16 Bold cFFE8EDF5"
    )
}

DrawToggleSetting(setting)
{
    global G

    x := setting.x
    y := setting.y

    if setting.hover
        setting.hoverAnim += (1-setting.hoverAnim)*0.25
    else
        setting.hoverAnim += (0-setting.hoverAnim)*0.45

    Gdip_TextToGraphics(
        G,
        setting.text,
        "x" x-120
        " y" y+13+setting.textOffsetY
        " w400 h25 s" setting.fontSize " Bold cFFE8EDF5"
    )

    bgColor := 0x35182030

    bg :=
    Gdip_BrushCreateSolid(
        bgColor
    )

    Gdip_FillRectangle(
        G,
        bg,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeleteBrush(bg)

    pen :=
    Gdip_CreatePen(
        setting.hover
        ? 0xFFFFFFFF
        : 0xFFFFFFFF,

        setting.hover
        ? 2
        : 1
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeletePen(pen)

    if setting.hoverAnim > 0.01
    {
        DrawSettingHoverFrame(
            x,
            y,
            setting.w,
            setting.h,
            setting.hoverAnim
        )
    }

    Gdip_TextToGraphics(
        G,
        "◀",
        "x" x+5
        " y" y+13
        " w25 h30 Center s15 Bold cFFFFFFFF"
    )

    Gdip_TextToGraphics(
        G,
        "▶",
        "x" x+setting.w-30
        " y" y+13
        " w25 h30 Center s15 Bold cFFFFFFFF"
    )

    stateText :=
    setting.value
    ?
    "ON"
    :
    "OFF"

    Gdip_TextToGraphics(
        G,
        stateText,
        "x" x+30
        " y" y+13
        " w"
        setting.w-60
        " h30 Center s16 Bold cFFE8EDF5"
    )
}

DrawSettings()
{
    global Settings

    for _, setting in Settings
    {
        switch setting.type
        {
            case "number":
                DrawNumberSetting(setting)

            case "toggle":
                DrawToggleSetting(setting)

            case "hotkey":
                DrawHotkeySetting(setting)

            case "loadoutList":
                DrawLoadoutListSetting(setting)
        }
    }
}

DrawPresets()
{
    global G, UI


    for name,preset in Presets
    {
        DrawPreset(
            name,
            preset
        )
    }
}

DrawNumberSetting(setting)
{
    global G, UI

    if setting.hover
        setting.hoverAnim += (1 - setting.hoverAnim) * 0.25
    else
        setting.hoverAnim += (0 - setting.hoverAnim) * 0.45

    x := setting.x
    y := setting.y

    if setting.activeAnim = "unset"
        setting.activeAnim := 0

    if setting.editing
        setting.activeAnim += (1-setting.activeAnim)*0.15
    else
        setting.activeAnim += (0-setting.activeAnim)*0.15

    Gdip_TextToGraphics(
        G,
        setting.text,
        "x" x-120 " y" y+13 " w400 h25 s14 Bold cFFE8EDF5"
    )

    bgColor :=
    (
    setting.editing
    ? 0x553B6FA8
    : (setting.hover
    ? 0x35182030
    : 0x35182030)
    )

    bg :=
    Gdip_BrushCreateSolid(
        bgColor
    )

    Gdip_FillRectangle(
        G,
        bg,
        x,
        y,
        setting.w,
        setting.h
    )

    Gdip_DeleteBrush(bg)

    borderWidth :=
    (
    setting.editing
    ? 2
    : setting.hover
    ? 2
    : 1
    )

    borderColor :=
    (
    setting.editing
    ? 0xFFFFFFFF
    : 0xFFFFFFFF
    )

    pen :=
    Gdip_CreatePen(
        borderColor,
        borderWidth
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        setting.w,
        setting.h
    )

    if setting.hoverAnim > 0.01
    {
        DrawHoverFrame(
            x,
            y,
            setting.w,
            setting.h,
            setting.hoverAnim
        )
    }

    if setting.hover
    {
        DrawSettingHoverFrame(
            x,
            y,
            setting.w,
            setting.h,
            setting.hoverAnim
        )
    }

    Gdip_DeletePen(pen)

    if setting.editing
    {
        cursor :=
            Mod(
                Floor(UI.time*4),
                2
            )
            ?
            "|"
            :
            ""

        displayValue :=
            String(setting.editValue . cursor)
    }
    else
    {
        displayValue :=
            String(setting.value)
    }

    Gdip_TextToGraphics(
        G,
        displayValue,
        "x" x
        " y" y + setting.ButtonTextY
        " w" setting.w
        " h35 Center s16 Bold cFFFFFFFF"
    )
}

DrawProfiles()
{
    global ProfilesUI

    for _, profile in ProfilesUI
        DrawProfileButton(profile)
}

DrawProfileButton(profile)
{
    global G

    x := profile.x
    y := profile.y

    if profile.hover
        profile.hoverAnim += (1-profile.hoverAnim)*0.25
    else
        profile.hoverAnim += (0-profile.hoverAnim)*0.45

    if profile.selected
        profile.selectedAnim += (1-profile.selectedAnim)*0.15
    else
        profile.selectedAnim += (0-profile.selectedAnim)*0.15

    bgColor :=
    (
    profile.selected
    ? 0x553B6FA8
    : 0x35182030
    )

    brush :=
    Gdip_BrushCreateSolid(
        bgColor
    )

    Gdip_FillRectangle(
        G,
        brush,
        x,
        y,
        profile.w,
        profile.h
    )

    Gdip_DeleteBrush(brush)

    borderAlpha :=
        Round(
            0x80 +
            (0x70 * profile.selectedAnim)
        )
    if borderAlpha > 255
        borderAlpha := 255

    pen :=
    Gdip_CreatePen(
        (borderAlpha<<24)|0xFFFFFFFF,
        profile.selected || profile.hover ? 2 : 1
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        profile.w,
        profile.h
    )

    Gdip_DeletePen(pen)

    if profile.hoverAnim > 0.01
        DrawSettingHoverFrame(
            x,
            y,
            profile.w,
            profile.h,
            profile.hoverAnim
        )

    Gdip_TextToGraphics(
        G,
        profile.text,
        "x" x
        " y" y+13
        " w" profile.w
        " h25 Center s14 Bold cFFFFFFFF"
    )
}

DrawButtons()
{
    global Buttons

    for name,button in Buttons
    {
        DrawButton(button)
    }
}

DrawCloseButton(button,x,y)
{
    global G

    color :=
    button.hover
    ?
    0xFFE6C978
    :
    0xFFB8B8B8

    pen :=
    Gdip_CreatePen(
        color,
        2
    )

    Gdip_DrawLine(
        G,
        pen,
        x,
        y,
        x+20,
        y+20
    )

    Gdip_DrawLine(
        G,
        pen,
        x+20,
        y,
        x,
        y+20
    )

    Gdip_DeletePen(pen)
}

DrawPreset(name, preset)
{
    global G, Images, UI

    x := preset.x
    y := preset.y
    size := preset.size

    if preset.hover
    {
        preset.hoverAnim +=
            (1-preset.hoverAnim)*0.25
    }
    else
    {
        preset.hoverAnim +=
            (0-preset.hoverAnim)*0.45
    }

    if preset.selected
    {
        preset.selectedAnim +=
            (1-preset.selectedAnim)*0.25
    }
    else
    {
        preset.selectedAnim +=
            (0-preset.selectedAnim)*0.45
    }

    if Images.Has(name)
    {
        Gdip_DrawImage(
            G,
            Images[name],
            x,
            y,
            size,
            size
        )
    }

    DrawPresetFrame(
        x,
        y,
        size,
        0xFFFFFFFF,
        1
    )

    if preset.hoverAnim > 0.01
    {
        DrawPresetHoverFrame(
            x,
            y,
            size,
            preset.hoverAnim
        )
    }

    textColor :=
    preset.selected
    ?
    "FFE0B85C"
    :
    "FFE8EDF5"

    Gdip_TextToGraphics(
        G,
        preset.text,
        "x"
        x-20
        " y"
        y+size+10
        " w"
        size+40
        " h25 Center s14 Bold c"
        textColor
    )
}

DrawPresetFrame(x,y,size,color,width)
{
    global G

    pen :=
    Gdip_CreatePen(
        color,
        width
    )

    Gdip_DrawLine(
        G,
        pen,
        x+size/2,
        y,
        x+size,
        y+size/2
    )

    Gdip_DrawLine(
        G,
        pen,
        x+size,
        y+size/2,
        x+size/2,
        y+size
    )

    Gdip_DrawLine(
        G,
        pen,
        x+size/2,
        y+size,
        x,
        y+size/2
    )

    Gdip_DrawLine(
        G,
        pen,
        x,
        y+size/2,
        x+size/2,
        y
    )

    Gdip_DeletePen(pen)
}

DrawButton(button)
{
    global G, UI

    x:=button.x
    y:=button.y

    if button.style = "close"
    {
        DrawCloseButton(button,x,y)
        return
    }

    if button.hover
    {
        button.hoverAnim +=
            (1-button.hoverAnim)*0.25
    }
    else
    {
        button.hoverAnim +=
            (0-button.hoverAnim)*0.45
    }

    glow :=
        Round(button.hoverAnim*40)

    if button.style = "green"
    {
        pulseAlpha :=
            Round(button.pulseAmount)


        bgColor :=
            ((40+pulseAlpha)<<24)
            | 0x4D9C5D
    }
    else
    {
        bgColor := 0x35101822
    }

    bg :=
    Gdip_BrushCreateSolid(
        bgColor
    )

    Gdip_FillRectangle(
        G,
        bg,
        x,
        y,
        button.w,
        button.h
    )

    Gdip_DeleteBrush(bg)

    borderColor := 0xFFFFFFFF

    pen :=
    Gdip_CreatePen(
        borderColor,
        button.hover ? 2 : 1
    )

    Gdip_DrawRectangle(
        G,
        pen,
        x,
        y,
        button.w,
        button.h
    )
    if button.hoverAnim > 0.01
    {
        DrawHoverFrame(
            x,
            y,
            button.w,
            button.h,
            button.hoverAnim
        )
    }

    if button.style = "green"
    {
        button.pulse += button.pulseSpeed

        pulse :=
            (Sin(button.pulse)+1)/2


        button.pulseAmount :=
            pulse*20
    }

    Gdip_DeletePen(pen)
    
    if button.style = "close"
    {
        color :=
        button.hover
        ?
        0xFFE6C978
        :
        0xFFB8B8B8

        pen :=
        Gdip_CreatePen(
            color,
            2
        )

        Gdip_DrawLine(
            G,
            pen,
            x,
            y,
            x+20,
            y+20
        )

        Gdip_DrawLine(
            G,
            pen,
            x+20,
            y,
            x,
            y+20
        )

        Gdip_DeletePen(pen)

        return
    }

    if button.text
    {
        textOffset := button.HasOwnProp("textOffsetY")
        ? button.textOffsetY
        : 0

        textWidth := button.w

        Gdip_TextToGraphics(
            G,
            button.text,
            "x"
            x
            " y"
            y+17+textOffset
            " w"
            textWidth
            " h30 Center s18 Bold cFFE8EDF5"
        )
    }
}

PrepareTransparentFrame()
{
    global

    oldAlpha := UI.alpha

    Draw()

    newHbm :=
        Gdip_CreateHBITMAPFromBitmap(Bitmap)

    oldHbm :=
        SelectObject(
            hdc,
            newHbm
        )

    if oldHbm
        DllCall(
            "DeleteObject",
            "ptr",
            oldHbm
        )

    hbm := newHbm

    UpdateLayeredWindow(
        hwnd,
        hdc,
        ,
        ,
        WIDTH,
        HEIGHT,
        oldAlpha
    )

    UI.alpha := oldAlpha
}

; --- Input Functions --- ;

WM_SETCURSOR(wParam, lParam, msg, hwnd)
{
    global Buttons, Presets, ProfilesUI, UI

    if !UI.visible
        return
    if hwnd != MainGui.Hwnd
        return
    if Overlay.visible
    {
        gearBtnW := 120
        gearBtnH := 34
        gearBtnX := Overlay.x + 20
        gearBtnY := Overlay.y + Overlay.h - gearBtnH - 16

        menuX := gearBtnX
        menuY := gearBtnY + gearBtnH + 6
        optH := 34
        count := 0
        for _,_ in Overlay.gearOptions
            count++
        menuH := optH * count

        if (
            UI.mouseX > gearBtnX &&
            UI.mouseX < gearBtnX + gearBtnW &&
            UI.mouseY > gearBtnY &&
            UI.mouseY < gearBtnY + gearBtnH
        )
        {
            SetCursor("hand")
            return true
        }

        if Overlay.gearMenuOpen &&
           UI.mouseX > menuX &&
           UI.mouseX < menuX + gearBtnW &&
           UI.mouseY > menuY &&
           UI.mouseY < menuY + menuH
        {
            SetCursor("hand")
            return true
        }

        for _,slot in LoadoutSlots
        {
            if (
                UI.mouseX > slot.x &&
                UI.mouseX < slot.x + slot.w &&
                UI.mouseY > slot.y &&
                UI.mouseY < slot.y + slot.h
            )
            {
                SetCursor("hand")
                return true
            }
        }
        btn := Overlay.saveButton

        if (
            UI.mouseX > btn.x &&
            UI.mouseX < btn.x + btn.w &&
            UI.mouseY > btn.y &&
            UI.mouseY < btn.y + btn.h
        )
        {
            SetCursor("hand")
            return true
        }

        SetCursor("arrow")
        return true
    }

    hovered := false

    for name,button in Buttons
    {
        bx := button.x
        by := button.y

        if (
            UI.mouseX > bx &&
            UI.mouseX < bx + button.w &&
            UI.mouseY > by &&
            UI.mouseY < by + button.h
        )
        {
            hovered := true
            break
        }
    }

    if !hovered
    {
        for name,preset in Presets
        {
            x := preset.x
            y := preset.y

            if (
                UI.mouseX > x &&
                UI.mouseX < x+preset.size &&
                UI.mouseY > y &&
                UI.mouseY < y+preset.size
            )
            {
                hovered := true
                break
            }
        }
    }

    if !hovered
    {
        for _, profile in ProfilesUI
        {
            x := profile.x
            y := profile.y

            if (
                UI.mouseX > x &&
                UI.mouseX < x + profile.w &&
                UI.mouseY > y &&
                UI.mouseY < y + profile.h
            )
            {
                hovered := true
                break
            }
        }
    }

    if !hovered
    {
        for name,setting in Settings
        {
            x := setting.x
            y := setting.y

            if (
                UI.mouseX > x &&
                UI.mouseX < x+setting.w &&
                UI.mouseY > y &&
                UI.mouseY < y+setting.h
            )
            {
                hovered := true
                break
            }
        }
    }

    if hovered
    {
        SetCursor("hand")
        return true
    }

    SetCursor("arrow")
    return true
}

WM_KEYUP(wParam,lParam,msg,hwnd)
{
    global Settings, HotkeyState

    for _,setting in Settings
    {
        if !setting.listening
            continue

        if wParam = 0x11 ; Ctrl
        {
            HotkeyState.ctrl := false

            if InStr(setting.value, "Ctrl +")
            {
                setting.value := RemoveModifierPlus(setting.value)
                FinishHotkeyEdit(setting)
            }

            return
        }

        if wParam = 0x10 ; Shift
        {
            HotkeyState.shift := false

            if InStr(setting.value, "Shift +")
            {
                setting.value := RemoveModifierPlus(setting.value)
                FinishHotkeyEdit(setting)
            }

            return
        }

        if wParam = 0x12 ; Alt
        {
            HotkeyState.alt := false

            if InStr(setting.value, "Alt +")
            {
                setting.value := RemoveModifierPlus(setting.value)
                FinishHotkeyEdit(setting)
            }

            return
        }
    }
}

WM_KEYDOWN(wParam,lParam,msg,hwnd)
{
    global Settings, HotkeyState

    for _,setting in Settings
    {
        if !setting.listening
            continue

        if wParam = 27 ; ESC
        {
            setting.value := "None"
            FinishHotkeyEdit(setting)

            SaveCurrentProfile()
            SaveSettings()

            return
        }

        if wParam = 0x12 ; Alt
        {
            HotkeyState.alt := true
            UpdateModifierPreview(setting)
            return
        }
        
        if wParam = 0x11 ; Ctrl
        {
            HotkeyState.ctrl := true
            UpdateModifierPreview(setting)
            return
        }

        if wParam = 0x10 ; Shift
        {
            HotkeyState.shift := true
            UpdateModifierPreview(setting)
            return
        }

        HandleHotkeyInput(setting, wParam, lParam)
        return
    }

    for name,setting in Settings
    {
        if !setting.editing
            continue

        key := VKToEnglish(wParam)

        if wParam = 13 ; Enter
        {
            if RegExMatch(setting.editValue,"^\d{1,3}$")
            {
                value := Integer(setting.editValue)

                if value >= 1 && value <= 999
                    setting.value := value
            }

           FinishSettingEdit(setting)
           return
        }

        if wParam = 27 ; Escape
        {
            FinishSettingEdit(setting)
            return
        }

        if wParam = 8 ; Backspace
        {
            setting.editValue :=
                SubStr(
                    setting.editValue,
                    1,
                    -1
                )

            return
        }

        if RegExMatch(key,"^\d$")
        {
            if StrLen(setting.editValue)<3
                setting.editValue .= key
        }
    }
}

WM_MOUSEMOVE(wParam,lParam,msg,hwnd)
{
    global UI, Buttons, Presets, ProfilesUI, Settings, Panels

    UI.mouseX := lParam & 0xFFFF
    UI.mouseY := (lParam >> 16) & 0xFFFF

    if Overlay.visible
    {
        gearBtnW := 120
        gearBtnH := 34
        gearBtnX := Overlay.x + 20
        gearBtnY := Overlay.y + Overlay.h - gearBtnH - 16

        Overlay.gearHover :=
        (
            UI.mouseX > gearBtnX &&
            UI.mouseX < gearBtnX + gearBtnW &&
            UI.mouseY > gearBtnY &&
            UI.mouseY < gearBtnY + gearBtnH
        )

        Overlay.gearOptionHover := 0
        if Overlay.gearMenuOpen
        {
            menuX := gearBtnX
            menuY := gearBtnY + gearBtnH + 6
            optH := 34
            count := 0
            for _,_ in Overlay.gearOptions
                count++
            for index, _ in Overlay.gearOptions
            {
                yopt := menuY + (index-1)*optH
                if (
                    UI.mouseX > menuX &&
                    UI.mouseX < menuX + gearBtnW &&
                    UI.mouseY > yopt &&
                    UI.mouseY < yopt + optH
                )
                {
                    Overlay.gearOptionHover := index
                    break
                }
            }
        }

        for _,slot in LoadoutSlots
        {
            slot.hover :=
            (
                UI.mouseX > slot.x &&
                UI.mouseX < slot.x + slot.w &&
                UI.mouseY > slot.y &&
                UI.mouseY < slot.y + slot.h
            )
        }
        btn := Overlay.saveButton

        btn.hover :=
        (
            UI.mouseX > btn.x &&
            UI.mouseX < btn.x + btn.w &&
            UI.mouseY > btn.y &&
            UI.mouseY < btn.y + btn.h
        )
        return
    }
    for name,button in Buttons
    {
        bx := button.x
        by := button.y

        button.hover :=
        (
        UI.mouseX > bx &&
        UI.mouseX < bx + button.w &&
        UI.mouseY > by &&
        UI.mouseY < by + button.h
        )
    }
    for name,setting in Settings
    {
        sx := setting.x
        sy := setting.y

        setting.hover :=
        (
            UI.mouseX > sx &&
            UI.mouseX < sx + setting.w &&
            UI.mouseY > sy &&
            UI.mouseY < sy + setting.h
        )
    }
    for name,preset in Presets
    {
        x :=
        preset.x

        y :=
        preset.y

        preset.hover :=
        (
            UI.mouseX > x &&
            UI.mouseX < x+preset.size &&
            UI.mouseY > y &&
            UI.mouseY < y+preset.size
        )
    }
    for _, profile in ProfilesUI
    {
        px := profile.x
        py := profile.y
        profile.hover :=
        (
            UI.mouseX > px &&
            UI.mouseX < px + profile.w &&
            UI.mouseY > py &&
            UI.mouseY < py + profile.h
        )
    }
    for _, panel in Panels
    {
        px := panel.x
        py := panel.y

        panel.hover :=
        (
            UI.mouseX > px &&
            UI.mouseX < px + panel.w &&
            UI.mouseY > py &&
            UI.mouseY < py + panel.h
        )
    }
    hovered := false
    for name,button in Buttons
    {
        if button.hover
        {
            hovered := true
            break
        }
    }
    if !hovered
    {
        for name,preset in Presets
        {
            if preset.hover
            {
                hovered := true
                break
            }
        }
    }
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global MainGui, UI

    x := lParam & 0xFFFF
    y := (lParam >> 16) & 0xFFFF

    mouseX := x
    mouseY := y
    if y < 60
    {
        UI.dragging := true

        PostMessage(
            0xA1,
            2,
            0,
            ,
            "ahk_id " MainGui.Hwnd
        )

        KeyWait("LButton")

        UI.dragging := false
    }
    if Overlay.visible
    {
        insideOverlay := x > Overlay.x && x < Overlay.x + Overlay.w && y > Overlay.y && y < Overlay.y + Overlay.h
        insideMenu := false

        if Overlay.gearMenuOpen
        {
            gearBtnW := 120
            gearBtnH := 34
            gearBtnX := Overlay.x + 20
            gearBtnY := Overlay.y + Overlay.h - gearBtnH - 16
            menuX := gearBtnX
            menuY := gearBtnY + gearBtnH + 6
            optH := 34
            count := 0
            for _,_ in Overlay.gearOptions
                count++

            if x > menuX && x < menuX + gearBtnW && y > menuY && y < menuY + optH * count
                insideMenu := true
        }

        if !(insideOverlay || insideMenu)
        {
            Overlay.visible := false
            return
        }

    }
    if Overlay.visible
    {
        gearBtnW := 120
        gearBtnH := 34
        gearBtnX := Overlay.x + 20
        gearBtnY := Overlay.y + Overlay.h - gearBtnH - 16

        if (
            x > gearBtnX &&
            x < gearBtnX + gearBtnW &&
            y > gearBtnY &&
            y < gearBtnY + gearBtnH
        )
        {
            Overlay.gearMenuOpen := !Overlay.gearMenuOpen
            return
        }
        if Overlay.gearMenuOpen
        {
            menuX := gearBtnX
            menuY := gearBtnY + gearBtnH + 6
            optH := 34
            for index, opt in Overlay.gearOptions
            {
                yopt := menuY + (index-1)*optH
                if (
                    x > menuX &&
                    x < menuX + gearBtnW &&
                    y > yopt &&
                    y < yopt + optH
                )
                {
                    Profiles[State.class][State.profile].SelectedGearUI := opt
                    SaveSettings()
                    Overlay.gearMenuOpen := false
                    return
                }
            }
            count := 0
            for _,_ in Overlay.gearOptions
                count++

            if (
                x > menuX &&
                x < menuX + gearBtnW &&
                y > menuY &&
                y < menuY + optH * count
            )
            {
                return
            }
            Overlay.gearMenuOpen := false
        }
        for _,slot in LoadoutSlots
        {
            if (
                x > slot.x &&
                x < slot.x + slot.w &&
                y > slot.y &&
                y < slot.y + slot.h
            )
            {

                if slot.selected
                {
                    slot.selected := false
                }
                else
                {
                    slot.selected := true
                }
                
                SaveCurrentLoadouts()

                return
            }
        }
        btn := Overlay.saveButton

        if (
            x > btn.x &&
            x < btn.x + btn.w &&
            y > btn.y &&
            y < btn.y + btn.h
        )
        {
            Overlay.visible := false
            return
        }
        return
    }
    for name,preset in Presets
    {
        px := preset.x
        py := preset.y

        if (
            x > px &&
            x < px+preset.size &&
            y > py &&
            y < py+preset.size
        )
        {
            FinishAllSettingsEdit()
            SaveCurrentProfile()
            for _,p in Presets
                p.selected := false

            preset.selected := true

            State.class := name

            GlobalSettings.CurrentPresetUI := name
            SaveSettings()

            LoadCurrentProfile()
            LoadCurrentLoadoutsUI()
            LoadSettingsUI()

            return
        }
    }

    for name, profile in ProfilesUI
    {
        px := profile.x
        py := profile.y

        if (
            mouseX > px &&
            mouseX < px + profile.w &&
            mouseY > py &&
            mouseY < py + profile.h
        )
        {
            FinishAllSettingsEdit()
            SaveCurrentProfile()
            for _, p in ProfilesUI
                p.selected := false

            profile.selected := true

            State.profile := name



            LoadCurrentProfile()
            LoadCurrentLoadoutsUI()
            LoadSettingsUI()

            return
        }
    }

    for name,button in Buttons
    {
        bx := button.x
        by := button.y

        if (
            x > bx &&
            x < bx + button.w &&
            y > by &&
            y < by + button.h
        )
        {
            if name = "close"
            {
                CancelMenu()
                Reload()
                return
            }

            if name = "save"
            {
                FinishAllSettingsEdit()

                SaveCurrentProfile()

                GlobalSettings.CurrentPresetUI := State.class

                SaveSettings()

                DeleteSettingsBackup()

                Reload()

                return
            }
        }
    }
    for name,setting in Settings
    {
        x := setting.x
        y := setting.y

        if (
            mouseX > x &&
            mouseX < x+setting.w &&
            mouseY > y &&
            mouseY < y+setting.h
        )
        {
            if setting.editing
            {
                return
            }

            FinishAllSettingsEdit()

            if setting.type = "hotkey"
            {
                setting.listening := true
                setting.oldValue := setting.value
                return
            }

            if setting.type = "toggle"
            {
                setting.value := !setting.value

                SaveCurrentProfile()
                SaveSettings()

                return
            }
            if setting.type = "loadoutList"
            {
                Overlay.visible := true

                ClearHoverStates()
                BuildLoadoutSlots()
                LoadCurrentLoadoutsUI()

                return
            }

            setting.oldValue := setting.value
            setting.editing := true
            setting.editValue := ""

            return
        }
    }
}

WM_SYSKEYDOWN(wParam,lParam,msg,hwnd)
{
    if wParam = 0x12 ; ALT
    {
        WM_KEYDOWN(wParam,lParam,msg,hwnd)
        return 0
    }

    return WM_KEYDOWN(wParam,lParam,msg,hwnd)
}

WM_SYSKEYUP(wParam,lParam,msg,hwnd)
{
    if wParam = 0x12 ; ALT
    {
        WM_KEYUP(wParam,lParam,msg,hwnd)
        return 0
    }

    return WM_KEYUP(wParam,lParam,msg,hwnd)
}

; --- GUI start --- ;

BuildSettings()

LoadSettingsUI()

State.class := GlobalSettings.CurrentPresetUI

LoadCurrentProfile()

LoadCurrentLoadoutsUI()

SyncUIState()

SaveSettings()

#Include "Loadouts Manager Updater.ahk"

CheckForUpdates()

MainGui := Gui("-Caption +E0x80000", "Loadouts Manager")

MainGui.OnEvent(
    "Close",
    GuiClose
)

x := (A_ScreenWidth - WIDTH) // 2

y := (A_ScreenHeight - HEIGHT) // 2

openOnStart := (Trim(GlobalSettings.OpenMenuHotkeyUI) = "" || Trim(GlobalSettings.OpenMenuHotkeyUI) = "None")
if openOnStart
{
    CreateSettingsBackup()

    MainGui.Show(
        "x" x " y" y " w" WIDTH " h" HEIGHT
    )
}
else
{
    MainGui.Show(
        "Hide x" x " y" y " w" WIDTH " h" HEIGHT
    )
}

DllCall(
    "SetWindowLong",
    "ptr",
    MainGui.Hwnd,
    "int",
    -20,
    "uint",
    DllCall(
        "GetWindowLong",
        "ptr",
        MainGui.Hwnd,
        "int",
        -20
    ) | 0x00040000
)

global hwnd := MainGui.Hwnd

CheckFirstRun()

; --- Buffer --- ;

global Bitmap :=
Gdip_CreateBitmap(
    WIDTH,
    HEIGHT
)

global Images := Map()


for name,preset in Presets
{
    if FileExist(preset.image)
    {
        original :=
            Gdip_CreateBitmapFromFile(
                preset.image
            )


        resized :=
            Gdip_CreateBitmap(
                preset.size,
                preset.size
            )


        gTemp :=
            Gdip_GraphicsFromImage(
                resized
            )


        Gdip_SetInterpolationMode(
            gTemp,
            7
        )


        Gdip_DrawImage(
            gTemp,
            original,
            0,
            0,
            preset.size,
            preset.size
        )


        Gdip_DeleteGraphics(
            gTemp
        )


        Gdip_DisposeImage(
            original
        )


        Images[name] := resized
    }
}

global G :=
Gdip_GraphicsFromImage(
    Bitmap
)

Gdip_SetSmoothingMode(
    G,
    4
)

global hdc :=
CreateCompatibleDC()

global hbm := 0

SetTimer(
    Render,
    1
)
