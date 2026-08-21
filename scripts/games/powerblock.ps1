# --- CONFIGURATION INITIALE ---
$Host.UI.RawUI.CursorSize = 0
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Width = 10
$Height = 20
if ($PSScriptRoot) {
    $HighScoreFile = Join-Path -Path $PSScriptRoot -ChildPath "powerblock_highscore.txt"
} else {
    $HighScoreFile = Join-Path -Path $env:USERPROFILE -ChildPath "powerblock_highscore.txt"
}
# Chargement du meilleur score
$HighestScore = 0
if (Test-Path $HighScoreFile) {
    $HighestScore = [int](Get-Content $HighScoreFile -ErrorAction SilentlyContinue)
}

$Shapes = @(
    @(@(1,1,1,1)),                        # I
    @(@(1,1), @(1,1)),                    # O
    @(@(0,1,0), @(1,1,1)),                # T
    @(@(0,1,1), @(1,1,0)),                # S
    @(@(1,1,0), @(0,1,1)),                # Z
    @(@(1,0,0), @(1,1,1)),                # J
    @(@(0,0,1), @(1,1,1))                 # L
)

$Colors = @(
    [ConsoleColor]::Cyan,
    [ConsoleColor]::Yellow,
    [ConsoleColor]::Magenta,
    [ConsoleColor]::Green,
    [ConsoleColor]::Red,
    [ConsoleColor]::Blue,
    [ConsoleColor]::DarkYellow
)

# --- MUSIQUE EN ARRIÈRE-PLAN (ORIGINAL POWERBLOCK THEME) ---
function Start-PowerBlockMusic {
    Stop-PowerBlockMusic
    $script:MusicJob = Start-Job -ScriptBlock {
        # Fréquences des notes (Hz)
        $C4=261; $D4=294; $E4=330; $F4=349; $G4=392; $A4=440; $B4=494
        $C5=523; $D5=587; $E5=659; $F5=698; $G5=784; $A5=880
        
        # Mélodie dynamique originale (Note, DuréeMs)
        $notes = @(
            # Partie A
            @($E5,200), @($B4,100), @($C5,100), @($D5,200), @($E5,100), @($C5,100),
            @($A4,200), @($G4,100), @($A4,100), @($C5,200), @($E5,200),
            @($D5,200), @($C5,100), @($B4,100), @($C5,200), @($D5,200),
            @($E5,300), @($C5,100), @($A4,400),
            
            # Partie B
            @($G5,200), @($E5,100), @($F5,100), @($G5,200), @($A5,200),
            @($F5,200), @($D5,100), @($E5,100), @($F5,200), @($G5,200),
            @($E5,200), @($C5,100), @($D5,100), @($E5,200), @($F5,100), @($E5,100),
            @($D5,200), @($B4,200), @($C5,400)
        )

        while ($true) {
            foreach ($n in $notes) {
                [Console]::Beep($n[0], $n[1])
                Start-Sleep -Milliseconds 15
            }
        }
    }
}

function Stop-PowerBlockMusic {
    if ($script:MusicJob) {
        Stop-Job $script:MusicJob -ErrorAction SilentlyContinue
        Remove-Job $script:MusicJob -ErrorAction SilentlyContinue
    }
}

# --- MENU D'ACCUEIL ---
function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "   PPPP   EEEEE  WW   WW  EEEEE  RRRR   " -ForegroundColor Cyan
    Write-Host "   P   P  E      WW   WW  E      R   R  " -ForegroundColor Cyan
    Write-Host "   PPPP   EEE    WW W WW  EEE    RRRR   " -ForegroundColor Yellow
    Write-Host "   P      E      WWWWWWW  E      R  R   " -ForegroundColor Yellow
    Write-Host "   P      EEEEE   W   W   EEEEE  R   R  " -ForegroundColor Green
    Write-Host "  --------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   BBBB   L      OOOO   CCC   K   K     " -ForegroundColor Green
    Write-Host "   B   B  L     O    O C   C  K  K      " -ForegroundColor Magenta
    Write-Host "   BBBB   L     O    O C      KK        " -ForegroundColor Magenta
    Write-Host "   B   B  L     O    O C   C  K  K      " -ForegroundColor Red
    Write-Host "   BBBB   LLLLL  OOOO   CCC   K   K     " -ForegroundColor Red
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "          HIGHEST SCORE : $HighestScore" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "             [1] PLAY GAME" -ForegroundColor Green
    Write-Host "             [Q] QUIT" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  --------------------------------------------" -ForegroundColor DarkGray

    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'D1' -or $key.Key -eq 'NumPad1' -or $key.Key -eq 'Enter') { return $true }
            if ($key.Key -eq 'Q') { return $false }
        }
        Start-Sleep -Milliseconds 50
    }
}

# --- FONCTIONS DU JEU ---
function New-Piece {
    $idx = Get-Random -Minimum 0 -Maximum $Shapes.Count
    return @{
        Shape = $Shapes[$idx]
        Color = $Colors[$idx]
        X     = [math]::Floor(($Width - $Shapes[$idx][0].Count) / 2)
        Y     = 0
    }
}

function Test-Collision ($piece, $offsetX, $offsetY, $shape = $piece.Shape) {
    $h = $shape.Count
    $w = $shape[0].Count
    for ($r = 0; $r -lt $h; $r++) {
        for ($c = 0; $c -lt $w; $c++) {
            if ($shape[$r][$c] -ne 0) {
                $newX = $piece.X + $c + $offsetX
                $newY = $piece.Y + $r + $offsetY
                if ($newX -lt 0 -or $newX -ge $Width -or $newY -ge $Height) { return $true }
                if ($newY -ge 0 -and $Board[$newY, $newX] -ne 0) { return $true }
            }
        }
    }
    return $false
}

function Rotate-Shape ($shape) {
    $h = $shape.Count
    $w = $shape[0].Count
    $rotated = @()
    for ($c = 0; $c -lt $w; $c++) {
        $row = @()
        for ($r = $h - 1; $r -ge 0; $r--) {
            $row += $shape[$r][$c]
        }
        $rotated += ,$row
    }
    return $rotated
}

function Lock-Piece ($piece) {
    $h = $piece.Shape.Count
    $w = $piece.Shape[0].Count
    for ($r = 0; $r -lt $h; $r++) {
        for ($c = 0; $c -lt $w; $c++) {
            if ($piece.Shape[$r][$c] -ne 0) {
                $py = $piece.Y + $r
                $px = $piece.X + $c
                if ($py -ge 0) {
                    $Board[$py, $px] = [array]::IndexOf($Colors, $piece.Color) + 1
                }
            }
        }
    }
}

function Clear-Lines {
    $linesCleared = 0
    for ($r = $Height - 1; $r -ge 0; $r--) {
        $full = $true
        for ($c = 0; $c -lt $Width; $c++) {
            if ([int]$Board[$r, $c] -eq 0) { $full = $false; break }
        }
        if ($full) {
            $linesCleared++
            for ($downR = $r; $downR -gt 0; $downR--) {
                $prevR = [int]$downR - 1
                for ($c = 0; $c -lt $Width; $c++) {
                    $Board[$downR, $c] = [int]$Board[$prevR, $c]
                }
            }
            for ($c = 0; $c -lt $Width; $c++) { $Board[0, $c] = 0 }
            $r++ # Re-vérifier la ligne qui vient de descendre
        }
    }
    if ($linesCleared -gt 0) {
        $script:LinesTotal += $linesCleared
        $script:Score += ($linesCleared * 100) * $linesCleared * $Level
        $script:Level = [math]::Floor($Score / 1000) + 1
        if ($script:Score -gt $script:HighestScore) {
            $script:HighestScore = $script:Score
            $script:HighestScore | Out-File -FilePath $HighScoreFile -Force
        }
    }
}

function Get-GhostY ($piece) {
    $offsetY = 0
    while (-not (Test-Collision $piece 0 ($offsetY + 1))) {
        $offsetY++
    }
    return $piece.Y + $offsetY
}

function Draw-Game ($currentPiece, $nextPiece) {
    [Console]::SetCursorPosition(0, 0)
    Write-Host "================ POWERBLOCK ================" -ForegroundColor Cyan
    Write-Host ("Score : {0,-7} Best : {1,-7} Niveau : {2}" -f $Score, $HighestScore, $Level) -ForegroundColor Yellow
    Write-Host ""

    $ghostY = Get-GhostY $currentPiece

    Write-Host "+$('-' * ($Width * 2))+" -NoNewline -ForegroundColor Gray
    Write-Host "   +-------------+" -ForegroundColor DarkGray

    for ($r = 0; $r -lt $Height; $r++) {
        Write-Host "|" -NoNewline -ForegroundColor Gray

        for ($c = 0; $c -lt $Width; $c++) {
            $cellValue = $Board[$r, $c]

            $pr = $r - $currentPiece.Y
            $pc = $c - $currentPiece.X
            $isCurrent = $false
            if ($pr -ge 0 -and $pr -lt $currentPiece.Shape.Count -and $pc -ge 0 -and $pc -lt $currentPiece.Shape[0].Count) {
                if ($currentPiece.Shape[$pr][$pc] -ne 0) { $isCurrent = $true }
            }

            $gr = $r - $ghostY
            $isGhost = $false
            if ($gr -ge 0 -and $gr -lt $currentPiece.Shape.Count -and $pc -ge 0 -and $pc -lt $currentPiece.Shape[0].Count) {
                if ($currentPiece.Shape[$gr][$pc] -ne 0) { $isGhost = $true }
            }

            if ($isCurrent) {
                Write-Host "[]" -NoNewline -ForegroundColor $currentPiece.Color
            } elseif ($cellValue -gt 0) {
                Write-Host "[]" -NoNewline -ForegroundColor $Colors[$cellValue - 1]
            } elseif ($isGhost) {
                Write-Host "::" -NoNewline -ForegroundColor DarkGray
            } else {
                Write-Host "  " -NoNewline
            }
        }
        Write-Host "|" -NoNewline -ForegroundColor Gray

        if ($r -eq 0) {
            Write-Host "   | SUIVANTE    |" -ForegroundColor DarkGray
        } elseif ($r -ge 1 -and $r -le 2) {
            $nr = $r - 1
            Write-Host "   | " -NoNewline -ForegroundColor DarkGray
            if ($nr -lt $nextPiece.Shape.Count) {
                for ($nc = 0; $nc -lt 4; $nc++) {
                    if ($nc -lt $nextPiece.Shape[$nr].Count -and $nextPiece.Shape[$nr][$nc] -ne 0) {
                        Write-Host "[]" -NoNewline -ForegroundColor $nextPiece.Color
                    } else {
                        Write-Host "  " -NoNewline
                    }
                }
            } else {
                Write-Host "        " -NoNewline
            }
            Write-Host " |" -ForegroundColor DarkGray
        } elseif ($r -eq 3) {
            Write-Host "   +-------------+" -ForegroundColor DarkGray
        } else {
            Write-Host ""
        }
    }
    
    Write-Host "+$('-' * ($Width * 2))+" -ForegroundColor Gray
    Write-Host "`nCommandes :" -ForegroundColor White
    Write-Host "  [Fleches] Deplacer / Tourner   [Espace] Drop Instant" -ForegroundColor DarkGray
    Write-Host "  [Q] Quitter" -ForegroundColor DarkGray
}

# --- DÉROULEMENT DU JEU ---
if (-not (Show-MainMenu)) { exit }

Start-PowerBlockMusic

Clear-Host
$Board = New-Object 'int[,]' $Height, $Width
$Score = 0
$Level = 1
$LinesTotal = 0
$GameOver = $false

$CurrentPiece = New-Piece
$NextPiece    = New-Piece
$lastDrop     = [DateTime]::Now

try {
    while (-not $GameOver) {
        $dropIntervalMs = [math]::Max(80, 400 - (($Level - 1) * 35))

        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'LeftArrow' {
                    if (-not (Test-Collision $CurrentPiece -1 0)) { $CurrentPiece.X-- }
                }
                'RightArrow' {
                    if (-not (Test-Collision $CurrentPiece 1 0)) { $CurrentPiece.X++ }
                }
                'DownArrow' {
                    if (-not (Test-Collision $CurrentPiece 0 1)) { $CurrentPiece.Y++ }
                }
                'UpArrow' {
                    $rotated = Rotate-Shape $CurrentPiece.Shape
                    if (-not (Test-Collision $CurrentPiece 0 0 $rotated)) {
                        $CurrentPiece.Shape = $rotated
                    }
                }
                'Spacebar' {
                    $CurrentPiece.Y = Get-GhostY $CurrentPiece
                    Lock-Piece $CurrentPiece
                    Clear-Lines
                    $CurrentPiece = $NextPiece
                    $NextPiece    = New-Piece
                    if (Test-Collision $CurrentPiece 0 0) { $GameOver = $true }
                }
                'Q' { $GameOver = $true }
            }
        }

        if (([DateTime]::Now - $lastDrop).TotalMilliseconds -gt $dropIntervalMs) {
            if (-not (Test-Collision $CurrentPiece 0 1)) {
                $CurrentPiece.Y++
            } else {
                Lock-Piece $CurrentPiece
                Clear-Lines
                $CurrentPiece = $NextPiece
                $NextPiece    = New-Piece
                if (Test-Collision $CurrentPiece 0 0) {
                    $GameOver = $true
                }
            }
            $lastDrop = [DateTime]::Now
        }

        Draw-Game $CurrentPiece $NextPiece
        Start-Sleep -Milliseconds 25
    }
} finally {
    Stop-PowerBlockMusic
}

[Console]::SetCursorPosition(0, $Height + 9)
Write-Host "`n==========================================" -ForegroundColor Red
Write-Host "     GAME OVER - Score Final : $Score" -ForegroundColor Red
Write-Host "     HIGHEST SCORE         : $HighestScore" -ForegroundColor Yellow
Write-Host "==========================================`n" -ForegroundColor Red
