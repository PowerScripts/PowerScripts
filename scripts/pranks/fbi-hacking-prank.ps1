Clear-Host
$H = $host.ui.RawUI
$H.BackgroundColor = 'Black'
$H.ForegroundColor = 'Green'
Clear-Host

# 1. ECRAN DE LOGIN INTERACTIF FBI
Write-Host "==========================================================================" -ForegroundColor Red
Write-Host "   [!] FBI / NATIONAL CYBER SYSTEM - CLASSIFIED TERMINAL ACCESS [!]" -ForegroundColor Red
Write-Host "==========================================================================" -ForegroundColor Red
Write-Host "`n[+] CONNECTED TO NODE: WASHINGTON_DC_SECURE_GATEWAY_09" -ForegroundColor DarkGreen
Write-Host "[!] AUTHENTICATION REQUIRED FOR OPERATOR LEVEL 5" -ForegroundColor Yellow

Write-Host "`nUSERNAME: " -NoNewline -ForegroundColor Green
Write-Host "AGENT_SPECIAL_OPS" -ForegroundColor Yellow

Write-Host "ENTER ENCRYPTION KEY: " -NoNewline -ForegroundColor Green

# Lecture touche par touche avec bips et cache *
$pass = ""
while ($true) {
    $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if ($key.VirtualKeyCode -eq 13) { break } # Validation par Entrée
    if ($key.VirtualKeyCode -eq 8) {          # Gestion Retour arrière
        if ($pass.Length -gt 0) {
            $pass = $pass.Substring(0, $pass.Length - 1)
            Write-Host "`b `b" -NoNewline
        }
    } else {
        $pass += $key.Character
        Write-Host "*" -NoNewline -ForegroundColor Red
        [console]::beep(1200, 30) # Bip sonore tactique à chaque touche
    }
}

# 2. ACCÈS ACCORDÉ & Lancement du spectacle
Write-Host "`n`n[+] VERIFYING SECURITY CREDENTIALS..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 800
[console]::beep(2000, 200)
Write-Host "[!] ACCESS GRANTED. WELCOME AGENT." -ForegroundColor Green
Start-Sleep -Seconds 1

# Progression de la brèche avec son
1..100 | ForEach-Object {
    Write-Progress -Activity "FBI DATABASE INFILTRATION" -Status "EXFILTRATING CLASSIFIED FILES: $_%" -PercentComplete $_
    Start-Sleep -Milliseconds 25
}

# Pop-up de 4 fenêtres d'Alerte Rouge
1..4 | ForEach-Object {
    Start-Process powershell -ArgumentList '-NoExit -Command "Write-Host ''[!] FBI CRITICAL ALERT: UNAUTHORIZED DATA DRAIN'' -ForegroundColor Red; while($true){ Write-Host ''0x994F ACCESS_OVERRIDE - EXFILTRATING LOCAL DISK C:\'' -ForegroundColor DarkRed; Start-Sleep -Milliseconds 60 }"'
    [console]::beep(1500, 100)
    Start-Sleep -Milliseconds 200
}

# Pop-up de 3 fenêtres d'Injection Bleues
1..3 | ForEach-Object {
    Start-Process powershell -ArgumentList '-NoExit -Command "Write-Host ''[+] DELTA EXECUTOR DLL HOOK ATTACHED'' -ForegroundColor Cyan; while($true){ Write-Host ''[KERNEL_MEM_DUMP] DUMPING SYSTEM RAM SECTORS...'' -ForegroundColor Yellow; Start-Sleep -Milliseconds 100 }"'
    [console]::beep(800, 100)
    Start-Sleep -Milliseconds 200
}

# Bip strident final d'alerte
1..3 | ForEach-Object { [console]::beep(2500, 150); Start-Sleep -Milliseconds 50 }

# Matrix verte permanente
while($true){
    $l=""
    1..$H.WindowSize.Width | ForEach-Object {
        if((Get-Random -Max 4) -eq 0){ $l += [char](Get-Random -Min 33 -Max 126) } else { $l += " " }
    }
    Write-Host $l -ForegroundColor Green
    Start-Sleep -Milliseconds 10
}
