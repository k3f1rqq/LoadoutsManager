#Requires AutoHotkey v2.0

global APP_VERSION := "1.0.2"

global GITHUB_OWNER := "k3f1rqq"
global GITHUB_REPO := "LoadoutsManager"

global GITHUB_API := Format(
    "https://api.github.com/repos/{1}/{2}/releases/latest",
    GITHUB_OWNER,
    GITHUB_REPO
)

global UPDATE_FILE := A_ScriptDir "\LoadoutsManager_update.exe"


CheckForUpdates()
{
    global APP_VERSION, GITHUB_API

    try
    {
        json := HttpGet(GITHUB_API)

        latestVersion := JsonValue(json, "tag_name")

        if (latestVersion = "")
        {
            MsgBox("Failed to get latest version.")
            return
        }


        if (CompareVersions(latestVersion, APP_VERSION) > 0)
        {
            downloadUrl := GetExeDownloadURL(json)

            if (downloadUrl = "")
            {
                MsgBox("Update file not found.")
                return
            }


            result := MsgBox(
                "A new update is available.`n`n"
                "Current version: " APP_VERSION "`n"
                "New version: " latestVersion "`n`n"
                "Do you want to download it?",
                "Loadouts Manager Update",
                "YesNo"
            )


            if (result = "Yes")
            {
                DownloadUpdate(downloadUrl)
            }
        }
    }
    catch Error as e
    {
        MsgBox(
            "Update check failed:`n`n" e.Message,
            "Updater Error"
        )
    }
}



DownloadUpdate(url)
{
    global UPDATE_FILE

    try
    {
        if FileExist(UPDATE_FILE)
            FileDelete(UPDATE_FILE)


        Download(url, UPDATE_FILE)


        if !FileExist(UPDATE_FILE)
            throw Error("Download failed.")


        size := FileGetSize(UPDATE_FILE)


        if (size < 500000)
            throw Error("Downloaded file is too small. Possible error.")

        RestartWithUpdate()
    }
    catch Error as e
    {
        MsgBox(
            "Download failed:`n`n"
            e.Message,
            "Updater Error"
        )
    }
}

RestartWithUpdate()
{
    global UPDATE_FILE

    currentExe := A_ScriptFullPath
    cmdFile := A_ScriptDir "\update.cmd"

    lines := [
        "@echo off",
        "timeout /t 1 /nobreak > nul",
        'del /f /q "' currentExe '"',
        'move /y "' UPDATE_FILE '" "' currentExe '"',
        'start "" "' currentExe '"',
        'del "%~f0"'
    ]


    cmd := ""

    for index, line in lines
    {
        cmd .= line

        if (index < lines.Length)
            cmd .= "`n"
    }


    if FileExist(cmdFile)
        FileDelete(cmdFile)


    FileAppend(cmd, cmdFile, "UTF-8")

    Run(cmdFile, , "Hide")

    ExitApp()
}

GetExeDownloadURL(json)
{

    regex :=
    '"browser_download_url"\s*:\s*"([^"]+\.exe)"'

    if RegExMatch(json, regex, &match)
        return match[1]

    return ""
}



HttpGet(url)
{
    http := ComObject("WinHttp.WinHttpRequest.5.1")

    http.Open("GET", url, false)

    http.SetRequestHeader(
        "User-Agent",
        "LoadoutsManager-Updater"
    )

    http.Send()

    if (http.Status != 200)
        throw Error("HTTP " http.Status)

    return http.ResponseText
}



JsonValue(json, key)
{
    regex := '"' key '"\s*:\s*"([^"]*)"'

    if RegExMatch(json, regex, &match)
        return match[1]

    return ""
}



CompareVersions(v1, v2)
{
    a := StrSplit(v1, ".")
    b := StrSplit(v2, ".")

    Loop 3
    {
        if (Integer(a[A_Index]) > Integer(b[A_Index]))
            return 1

        if (Integer(a[A_Index]) < Integer(b[A_Index]))
            return -1
    }

    return 0
}