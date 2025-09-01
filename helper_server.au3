#include <MsgBoxConstants.au3>
#include <Inet.au3>
#include <GDIPlus.au3>
#include <Clipboard.au3>

TCPStartup()
_GDIPlus_Startup()

Local $iPort = 8010
Local $hListen = TCPListen("192.168.1.50", $iPort)

If @error Then
    MsgBox($MB_ICONERROR, "Erreur", "Impossible de démarrer le serveur sur le port " & $iPort)
    Exit
EndIf

MsgBox($MB_ICONINFORMATION, "Serveur", "Serveur en écoute sur 192.168.1.50:" & $iPort)

While 1
    Local $hClient = TCPAccept($hListen)
    If $hClient <> -1 Then
        ; --- Lecture du nom de fichier ---
        Local $sFileName = TCPRecv($hClient, 512)
        If @error Or $sFileName = "" Then
            TCPCloseSocket($hClient)
            ContinueLoop
        EndIf

        $sFileName = StringStripWS($sFileName, 3)
        TCPSend($hClient, "OK")

        ; Enregistrer dans un fichier
        Local $sPath = @ScriptDir & "\" & $sFileName
        Local $hFile = FileOpen($sPath, 18) ; binaire

        While 1
            Local $sData = TCPRecv($hClient, 4096, 1)
            If @error Or $sData = "" Then ExitLoop
            FileWrite($hFile, $sData)
        WEnd

        FileClose($hFile)
        TCPCloseSocket($hClient)

        ; ✅ Charger l’image et la mettre dans le presse-papier comme Bitmap
        Local $hBitmap = _GDIPlus_BitmapCreateFromFile($sPath)
        _ClipBoard_Open(0)
        _ClipBoard_Empty()
        _ClipBoard_SetDataEx($hBitmap, $CF_BITMAP)
        _ClipBoard_Close()

        MsgBox($MB_ICONINFORMATION, "Serveur", "Image reçue et placée dans le presse-papier : " & $sPath)

        ; Vérifier la fenêtre active
        Local $sTitle = WinGetTitle("[ACTIVE]")

        If StringInStr($sTitle, "ChatGPT") Then
            Send("^v")       ; Coller l’image
            Sleep(10000)     ; Attendre 10 secondes
            Send("{ENTER}")  ; Appuyer sur Entrée
        EndIf

        _GDIPlus_BitmapDispose($hBitmap)
    EndIf
    Sleep(100)
WEnd

_GDIPlus_Shutdown()
TCPShutdown()
