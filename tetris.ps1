# --- CONFIGURATION ET INITIALISATION ---
$Host.UI.RawUI.CursorSize = 0
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Width = 10
$Height = 20
$Board = New-Object 'int[,]' $Height, $Width
$Score = 0
$GameOver = $false

# Définition des pièces (Tetrominos) et couleurs
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
                    # Stocke l'index de la couleur (+1)
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
            if ($Board[$r, $c] -eq 0) { $full = $false; break }
        }
        if ($full) {
            $linesCleared++
            for ($downR = $r; $downR -gt 0; $downR--) {
                for ($c = 0; $c -lt $Width; $c++) {
                    $Board[$downR, $c] = $Board[$downR - 1, $c]
                }
            }
            for ($c = 0; $c -lt $Width; $c++) { $Board[0, $c] = 0 }
            $r++ # Re-vérifier la même ligne après décalage
        }
    }
    if ($linesCleared -gt 0) {
        $script:Score += ($linesCleared * 100) * $linesCleared
    }
}

function Draw-Game ($currentPiece) {
    [Console]::SetCursorPosition(0, 0)
    Write-Host "=== TETRIS POWERSHELL ===" -ForegroundColor White
    Write-Host "Score : $Score`n" -ForegroundColor Yellow

    # Création du buffer visuel temporaire
    $display = New-Object 'int[,]' $Height, $Width
    for ($r=0; $r -lt $Height; $r++) {
        for ($c=0; $c -lt $Width; $c++) {
            $display[$r, $c] = $Board[$r, $c]
        }
    }

    # Superposer la pièce active sur le buffer
    $ph = $currentPiece.Shape.Count
    $pw = $currentPiece.Shape[0].Count
    $colorIdx = [array]::IndexOf($Colors, $currentPiece.Color) + 1
    for ($r = 0; $r -lt $ph; $r++) {
        for ($c = 0; $c -lt $pw; $c++) {
            if ($currentPiece.Shape[$r][$c] -ne 0) {
                $py = $currentPiece.Y + $r
                $px = $currentPiece.X + $c
                if ($py -ge 0 -and $py -lt $Height -and $px -ge 0 -and $px -lt $Width) {
                    $display[$py, $px] = $colorIdx
                }
            }
        }
    }

    # Rendu graphique
    Write-Host "+$('-' * ($Width * 2))+" -ForegroundColor Gray
    for ($r = 0; $r -lt $Height; $r++) {
        Write-Host "|" -NoNewline -ForegroundColor Gray
        for ($c = 0; $c -lt $Width; $c++) {
            $val = $display[$r, $c]
            if ($val -eq 0) {
                Write-Host "  " -NoNewline
            } else {
                $col = $Colors[$val - 1]
                Write-Host "[]" -NoNewline -ForegroundColor $col
            }
        }
        Write-Host "|" -ForegroundColor Gray
    }
    Write-Host "+$('-' * ($Width * 2))+" -ForegroundColor Gray
    Write-Host "`nContrôles : Flèches [Gauche/Droite], [Bas] Chute, [Haut] Rotation, [Q] Quitter" -ForegroundColor DarkGray
}

# --- BOUCLE PRINCIPALE ---
Clear-Host
$CurrentPiece = New-Piece
$lastDrop = [DateTime]::Now
$dropIntervalMs = 400

while (-not $GameOver) {
    # 1. Gestion des entrées clavier
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
            'Q' { $GameOver = $true }
        }
    }

    # 2. Gravité (Chute automatique)
    if (([DateTime]::Now - $lastDrop).TotalMilliseconds -gt $dropIntervalMs) {
        if (-not (Test-Collision $CurrentPiece 0 1)) {
            $CurrentPiece.Y++
        } else {
            Lock-Piece $CurrentPiece
            Clear-Lines
            $CurrentPiece = New-Piece
            if (Test-Collision $CurrentPiece 0 0) {
                $GameOver = $true
            }
        }
        $lastDrop = [DateTime]::Now
    }

    # 3. Rendu
    Draw-Game $CurrentPiece
    Start-Sleep -Milliseconds 30
}

# --- FIN DE PARTIE ---
[Console]::SetCursorPosition(0, $Height + 6)
Write-Host "`nGAME OVER! Score final : $Score" -ForegroundColor Red
