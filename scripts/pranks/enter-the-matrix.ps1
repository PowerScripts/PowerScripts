# EnterTheMatrix.ps1 - Simulation de la pluie de code Matrix
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host
[Console]::CursorVisible = $false

# Masquer la saisie système
$rawUI = $Host.UI.RawUI

try {
    # Caractères inspirés de Matrix (Katakana, chiffres et symboles)
    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZｦｱｳｴｵｶｷｹｺｻｼｽｾｿﾀﾂﾃﾅﾆﾇﾈﾊﾋﾎﾏﾐﾑﾒﾓﾔﾕﾗﾘﾜ"
    
    $width = [Console]::WindowWidth
    $height = [Console]::WindowHeight
    
    # Tableaux pour gérer la position et la longueur de chaque colonne
    $yPositions = New-Object int[] $width
    $lengths = New-Object int[] $width
    $speeds = New-Object int[] $width
    
    # Initialisation des colonnes
    $rand = New-Object Random
    for ($i = 0; $i -lt $width; $i++) {
        $yPositions[$i] = $rand.Next(-$height, 0)
        $lengths[$i] = $rand.Next(5, $height - 2)
        $speeds[$i] = $rand.Next(1, 3)
    }

    # Boucle infinie (Appuyez sur CTRL+C pour quitter)
    while ($true) {
        # Recalcul des dimensions au cas où la fenêtre change
        if ($width -ne [Console]::WindowWidth -or $height -ne [Console]::WindowHeight) {
            $width = [Console]::WindowWidth
            $height = [Console]::WindowHeight
            $yPositions = New-Object int[] $width
            $lengths = New-Object int[] $width
            $speeds = New-Object int[] $width
            for ($i = 0; $i -lt $width; $i++) {
                $yPositions[$i] = $rand.Next(-$height, 0)
                $lengths[$i] = $rand.Next(5, $height - 2)
                $speeds[$i] = $rand.Next(1, 3)
            }
            Clear-Host
        }

        for ($x = 0; $x -lt $width; $x += 2) {
            $y = $yPositions[$x]

            # Afficher la tête de la traînée en vert clair / blanc si possible
            if ($y -ge 0 -and $y -lt $height) {
                [Console]::SetCursorPosition($x, $y)
                [Console]::ForegroundColor = "White"
                [Console]::Write($chars[$rand.Next(0, $chars.Length)])
            }

            # Remplacer l'avant-dernier caractère en vert standard
            if (($y - 1) -ge 0 -and ($y - 1) -lt $height) {
                [Console]::SetCursorPosition($x, $y - 1)
                [Console]::ForegroundColor = "Green"
                [Console]::Write($chars[$rand.Next(0, $chars.Length)])
            }

            # Effacer la queue de la traînée
            $tailY = $y - $lengths[$x]
            if ($tailY -ge 0 -and $tailY -lt $height) {
                [Console]::SetCursorPosition($x, $tailY)
                [Console]::Write(" ")
            }

            # Faire avancer la colonne
            $yPositions[$x]++

            # Réinitialiser la colonne quand elle dépasse le bas
            if ($y - $lengths[$x] -ge $height) {
                $yPositions[$x] = 0
                $lengths[$x] = $rand.Next(5, $height - 2)
            }
        }

        # Petite pause pour limiter la charge CPU et régler la vitesse
        Start-Sleep -Milliseconds 30
    }
}
finally {
    # Restauration de la console en cas de fermeture / CTRL+C
    [Console]::ResetColor()
    [Console]::CursorVisible = $true
    Clear-Host
}
