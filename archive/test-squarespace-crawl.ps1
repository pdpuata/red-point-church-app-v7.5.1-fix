$startUrl = "https://www.redpointchurch.com/sermons"

$visited = @{}
$queue = New-Object System.Collections.Queue
$queue.Enqueue($startUrl)

$sermons = @()

while ($queue.Count -gt 0) {
    $url = $queue.Dequeue()

    if ($visited.ContainsKey($url)) {
        continue
    }

    $visited[$url] = $true

    Write-Host "`nFETCH: $url"

    try {
        $page = Invoke-WebRequest $url
    }
    catch {
        Write-Host "  FAILED"
        continue
    }

    # Find genuine Squarespace audio players
    $playerRegex =
        'data-title=["'']([^"'']+)["'']([\s\S]*?)(?=data-title=["'']|$)'

    foreach ($match in [regex]::Matches($page.Content, $playerRegex, "IgnoreCase")) {

        $title = $match.Groups[1].Value.Trim()
        $block = $match.Groups[2].Value

        $downloadMatch = [regex]::Match(
            $block,
            '<a\b(?=[^>]*\bclass=["''][^"'']*\bdownload\b[^"'']*["''])(?=[^>]*\bhref=["'']([^"'']+\.(?:mp3|m4a|wav)(?:\?[^"'']*)?)["''])[^>]*>',
            "IgnoreCase"
        )

        if ($downloadMatch.Success) {

            $audioUrl = $downloadMatch.Groups[1].Value

            $authorMatch = [regex]::Match(
                $block,
                'data-author=["'']([^"'']*)["'']',
                "IgnoreCase"
            )

            $author = $null

            if ($authorMatch.Success) {
                $author = $authorMatch.Groups[1].Value.Trim()
            }

            $sermons += [PSCustomObject]@{
                Title = $title
                Author = $author
                AudioUrl = $audioUrl
                SourcePage = $url
            }
        }
    }

    # Follow links to other sermon/archive pages
    foreach ($link in $page.Links) {

        if (-not $link.Href) {
            continue
        }

        if ($link.Href -match '^/pinetown-sermons/') {

            $absolute = "https://www.redpointchurch.com" + $link.Href

            if (-not $visited.ContainsKey($absolute)) {
                $queue.Enqueue($absolute)
            }
        }
    }
}

Write-Host "`n=============================="
Write-Host "CRAWL COMPLETE"
Write-Host "Pages visited: $($visited.Count)"
Write-Host "Audio records found: $($sermons.Count)"
Write-Host "Unique audio URLs: $(($sermons.AudioUrl | Sort-Object -Unique).Count)"
Write-Host "==============================`n"

$sermons |
Sort-Object Title |
Format-Table Title, Author, SourcePage -AutoSize
