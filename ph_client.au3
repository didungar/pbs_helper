#include <ScreenCapture.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>

; Associer la touche F1 pour lancer la capture
HotKeySet("{F1}", "PrendreCapture")

While 1
    Sleep(100)
WEnd

Func PrendreCapture()
    ; Générer un nom unique
    Local $sFile = @ScriptDir & "\capture_" & _NowDate() & "_" & _NowTime(5) & ".png"
    $sFile = StringReplace($sFile, "/", "-")
    $sFile = StringReplace($sFile, ":", "-")

    ; Capture de l’écran
    _ScreenCapture_Capture($sFile)

    ; Envoi au serveur
    EnvoyerFichier($sFile)
EndFunc

Func EnvoyerFichier($sFile)
    TCPStartup()
    Local $iPort = 8010
    Local $sIP = "192.168.1.50" ; IP du serveur
    Local $hSocket = TCPConnect($sIP, $iPort)

    If @error Or $hSocket = -1 Then
        MsgBox($MB_ICONERROR, "Erreur", "Impossible de se connecter au serveur " & $sIP & ":" & $iPort)
        TCPShutdown()
        Return
    EndIf

    ; Envoi du nom de fichier
    Local $sFileName = StringTrimLeft($sFile, StringLen(@ScriptDir) + 1)
    TCPSend($hSocket, $sFileName)

    ; Attendre confirmation
    Local $sAck = TCPRecv($hSocket, 2)
    If $sAck <> "OK" Then
        MsgBox($MB_ICONERROR, "Erreur", "Serveur n'a pas accepté le fichier")
        TCPCloseSocket($hSocket)
        TCPShutdown()
        Return
    EndIf

    ; Envoi du contenu du fichier
    Local $hFile = FileOpen($sFile, 16) ; binaire
    Local $sData
    While 1
        $sData = FileRead($hFile, 4096)
        If @error Or $sData = "" Then ExitLoop
        TCPSend($hSocket, $sData)
    WEnd
    FileClose($hFile)

    ; Fermeture
    TCPCloseSocket($hSocket)
    TCPShutdown()

    MsgBox($MB_ICONINFORMATION, "Client", "Capture envoyée au serveur " & $sIP)
EndFunc
