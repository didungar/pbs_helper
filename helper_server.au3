#include <MsgBoxConstants.au3>
#include <Inet.au3>

TCPStartup()

; Démarrage du serveur sur IP 192.168.1.50 et port 8010
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
        ; Lecture du nom de fichier envoyé par le client
        Local $sFileName = TCPRecv($hClient, 512)
        If @error Then ContinueLoop

        $sFileName = StringStripWS($sFileName, 3)
        TCPSend($hClient, "OK") ; confirmation au client

        ; Enregistrer dans le dossier du serveur
        Local $sPath = @ScriptDir & "\" & $sFileName
        Local $hFile = FileOpen($sPath, 18) ; mode binaire

        ; Réception des données
        While 1
            Local $sData = TCPRecv($hClient, 4096, 1)
            If @error Or $sData = "" Then ExitLoop
            FileWrite($hFile, $sData)
        WEnd

        FileClose($hFile)
        TCPCloseSocket($hClient)
        MsgBox($MB_ICONINFORMATION, "Serveur", "Fichier reçu : " & $sPath)
    EndIf
    Sleep(100)
WEnd

TCPShutdown()
