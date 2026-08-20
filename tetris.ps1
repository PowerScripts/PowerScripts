$H = $host.ui.RawUI
$H.WindowTitle = "PowerShell Tetris"
$H.BackgroundColor = "Black"
$H.ForegroundColor = "White"
Clear-Host
[Console]::CursorVisible = $false

$W = 10
$H_board = 20

$shapes = @(
    @(@(0,1),(1,1),(2,1),(3,1)), # I
    @(@(0,0),(0,1),(1,1),(2,1)), # J
    @(@(2,0),(0,1),(1,1),(2,1)), # L
    @(@(1,0),(2,0),(1,1),(2,1)), # O
    @(@(1,0),(2,0),(0,1),(1,1)), # S
    @(@(1,0),(0,1),(1,1),(2,1)), # T
    @(@(0,0),(1,0),(1,1),(2,1))  # Z
)
$colors = @("Cyan", "Blue", "DarkYellow", "Yellow", "Green", "Magenta", "Red")

$grid = New-Object 'object[,]' $H_board, $W
for ($r=0; $r -lt $H_board; $r++) {
    for ($c=0; $c -lt $W; $c++) { $grid[$r,$c] = $null }
}

$score = 0
$linesCleared = 0

function Draw-Board {
    [Console]::SetCursorPosition(0,0)
    Write-Host "=== POWERSHELL TETRIS ===" -ForegroundColor Yellow
    Write-Host "Score: $score | Lignes: $linesCleared    " -ForegroundColor Cyan
    Write-Host "+--------------------+" -ForegroundColor Gray

    for ($r=0; $r -lt $H_board; $r++) {
        Write-Host "|" -NoNewline -ForegroundColor Gray
        for ($c=0; $c -lt $W; $c++) {
            $drawn = $false
            for ($i=0; $i -lt 4; $i++) {
                $px = $pX + $curShape[$i][0]
                $py = $pY + $curShape[$i][1]
                if ($px -eq $c -and $py -eq $r) {
                    Write-Host "[]" -NoNewline -ForegroundColor $curColor
                    $drawn = $true
                    break
                }
            }
            if (-not $drawn) {
                if ($grid[$r,$c] -ne $null) {
                    Write-Host "[]" -NoNewline -ForegroundColor $grid[$r,$c]
                } else {
                    Write-Host "  " -NoNewline
                }
            }
        }
        Write-Host "|" -ForegroundColor Gray
    }
    Write-Host "+--------------------+" -ForegroundColor Gray
    Write-Host "[Fleches] Bouger  [Espace] Tourner" -ForegroundColor DarkGray
    Write-Host "[Q] Quitter                      " -ForegroundColor DarkGray
}

function Test-Collision ($nx, $ny, $shape) {
    for ($i=0; $i -lt 4; $i++) {
        $x = $nx + $shape[$i][0]
        $y = $ny + $shape[$i][1]
        if ($x -lt 0 -or $x -ge $W -or $y -ge $H_board) { return $true }
        if ($y -ge 0 -and $grid[$y,$x] -ne $null) { return $true }
    }
    return $false
}

function New-Piece {
    $script:idx = Get-Random -Min 0 -Max 7
    $script:curShape = $shapes[$idx]
    $script:curColor = $colors[$idx]
    $script:pX = [math]::Floor($W / 2) - 1
    $script:pY = 0
    if (Test-Collision $pX $pY $curShape) {
        $script:gameOver = $true
    }
}

function Rotate-Piece {
    $newShape = @()
    for ($i=0; $i -lt 4; $i++) {
        $rx = -$curShape[$i][1]
        $ry = $curShape[$i][0]
        $newShape += ,@($rx, $ry)
    }
    $minX = ($newShape | ForEach-Object { $_[0] } | Measure-Object -Minimum).Minimum
    $minY = ($newShape | ForEach-Object { $_[1] } | Measure-Object -Minimum).Minimum
    for ($i=0; $i -lt 4; $i++) {
        $newShape[$i][0] -= $minX
        $newShape[$i][1] -= $minY
    }
    if (-not (Test-Collision $pX $pY $newShape)) {
        $script:curShape = $newShape
    }
}

function Lock-Piece {
    for ($i=0; $i -lt 4; $i++) {
        $x = $pX + $curShape[$i][0]
        $y = $pY + $curShape[$i][1]
        if ($y -ge 0) { $grid[$y,$x] = $curColor }
    }
    for ($r=$H_board-1; $r -ge 0; $r--) {
        $full = $true
        for ($c=0; $c -lt $W; $c++) {
            if ($grid[$r,$c] -eq $null) { $full = $false; break }
        }
        if ($full) {
            $script:score += 100
            $script:linesCleared++
            for ($down=$r; $down -gt 0; $down--) {
                for ($c=0; $c -lt $W; $c++) {
                    $grid[$down,$c] = $grid[$down-1,$c]
                }
            }
            for ($c=0; $c -lt $W; $c++) { $grid[0,$c] = $null }
            $r++
        }
    }
    New-Piece
}

$gameOver = $false
New-Piece
Clear-Host

$lastTick = [Environment]::TickCount

while (-not $gameOver) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "LeftArrow"  { if (-not (Test-Collision ($pX - 1) $pY $curShape)) { $pX-- } }
            "RightArrow" { if (-not (Test-Collision ($pX + 1) $pY $curShape)) { $pX++ } }
            "DownArrow"  { if (-not (Test-Collision $pX ($pY + 1) $curShape)) { $pY++ } }
            "Spacebar"   { Rotate-Piece }
            "Q"          { $gameOver = $true }
        }
    }

    if (([Environment]::TickCount - $lastTick) -gt 350) {
        if (-not (Test-Collision $pX ($pY + 1) $curShape)) {
            $pY++
        } else {
            Lock-Piece
        }
        $lastTick = [Environment]::TickCount
    }

    Draw-Board
    Start-Sleep -Milliseconds 30
}

[Console]::CursorVisible = $true
Clear-Host
Write-Host "   GAME OVER!" -ForegroundColor Red
Write-Host "   Score final: $score" -ForegroundColor Yellow
Write-Host "   Lignes: $linesCleared`n" -ForegroundColor Cyan
