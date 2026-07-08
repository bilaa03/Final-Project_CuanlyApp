Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd.exe /c node src/server.js", 0, false
