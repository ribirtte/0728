param(
  [int]$Port = 8787
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $root 'index.html'
$envCandidates = @(
  (Join-Path $root 'lotto.env'),
  (Join-Path $root 'lotto.env.txt')
)
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)

function Import-EnvFile {
  param([string[]]$Paths)

  $result = @{}

  foreach ($path in $Paths) {
    if (-not (Test-Path $path)) { continue }

    $pendingKey = $null
    foreach ($rawLine in Get-Content -LiteralPath $path -Encoding UTF8) {
      $line = $rawLine.Trim()
      if (-not $line) { continue }
      if ($line.StartsWith('#')) { continue }

      if ($pendingKey) {
        $result[$pendingKey] = $line
        $pendingKey = $null
        continue
      }

      if ($line -match '^\s*([^:=]+)\s*[:=]\s*(.*?)\s*$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
          $pendingKey = $key
        } else {
          $result[$key] = $value.Trim('"').Trim("'")
        }
        continue
      }

      $pendingKey = $line
    }
  }

  return $result
}

$envFile = Import-EnvFile -Paths $envCandidates
$openAiKey = $envFile['OPENAI_API_KEY']
if (-not $openAiKey) { $openAiKey = $envFile['openai_api_key'] }
if (-not $openAiKey) { $openAiKey = $envFile['open api key'] }
$defaultModel = $envFile['OPENAI_MODEL']
if (-not $defaultModel) { $defaultModel = 'gpt-5.4-mini' }

function Get-ZodiacSign {
  param([datetime]$Date)

  $value = ($Date.Month * 100) + $Date.Day
  $signs = @(
    @{ key = 'capricorn'; start = 1222; end = 119; lucky = @(4, 8, 14, 22, 31, 45) },
    @{ key = 'aquarius'; start = 120; end = 218; lucky = @(3, 7, 16, 21, 29, 41) },
    @{ key = 'pisces'; start = 219; end = 320; lucky = @(2, 6, 12, 18, 27, 39) },
    @{ key = 'aries'; start = 321; end = 419; lucky = @(1, 9, 15, 23, 30, 44) },
    @{ key = 'taurus'; start = 420; end = 520; lucky = @(5, 10, 17, 24, 33, 42) },
    @{ key = 'gemini'; start = 521; end = 620; lucky = @(6, 11, 19, 25, 34, 43) },
    @{ key = 'cancer'; start = 621; end = 722; lucky = @(2, 13, 20, 28, 35, 40) },
    @{ key = 'leo'; start = 723; end = 822; lucky = @(8, 14, 18, 26, 32, 45) },
    @{ key = 'virgo'; start = 823; end = 922; lucky = @(3, 12, 16, 24, 37, 41) },
    @{ key = 'libra'; start = 923; end = 1022; lucky = @(7, 10, 19, 29, 36, 44) },
    @{ key = 'scorpio'; start = 1023; end = 1122; lucky = @(1, 8, 15, 22, 30, 39) },
    @{ key = 'sagittarius'; start = 1123; end = 1221; lucky = @(4, 9, 18, 27, 33, 42) }
  )

  foreach ($sign in $signs) {
    if ($sign.start -le $sign.end) {
      if ($value -ge $sign.start -and $value -le $sign.end) { return $sign }
    } else {
      if ($value -ge $sign.start -or $value -le $sign.end) { return $sign }
    }
  }

  return $signs[0]
}

function Get-LuckyNumbers {
  param([datetime]$Date, $Sign)

  function Normalize-LuckyNumber {
    param([int]$Value)
    if ($Value -lt 1) { return ((($Value % 45) + 45) % 45) + 1 }
    if ($Value -gt 45) { return (($Value - 1) % 45) + 1 }
    return $Value
  }

  $month = $Date.Month
  $day = $Date.Day
  $year = $Date.Year
  $yearSum = ($year.ToString().ToCharArray() | ForEach-Object { [int]::Parse($_) } | Measure-Object -Sum).Sum
  $yearMod = [int]($year % 45)
  if ($yearMod -eq 0) { $yearMod = 45 }

  $candidate1 = [int]((($month * $day) % 45) + 1)
  $candidate2 = [int]((($month + $day + $yearSum) % 45) + 1)
  $candidate3 = [int]$Sign.lucky[(($month + $day) % $Sign.lucky.Count)]
  $candidate4 = [int]$Sign.lucky[(($month * 2 + $day) % $Sign.lucky.Count)]
  $candidate5 = [int]$yearMod
  $candidate6 = [int](((((($month + $yearSum) * $day) % 45)) + 1))

  $base = @($candidate1, $candidate2, $candidate3, $candidate4, $candidate5, $candidate6)

  $numbers = [System.Collections.Generic.List[int]]::new()
  foreach ($n in $base) {
    $value = Normalize-LuckyNumber -Value ([int]$n)
    if (-not $numbers.Contains($value)) { [void]$numbers.Add($value) }
  }

  while ($numbers.Count -lt 6) {
    $sum = 0
    foreach ($n in $numbers) { $sum += $n }
    $next = (($sum + $yearSum) % 45) + 1
    if ($numbers.Contains($next)) {
      $next = ((($next + 7) % 45) + 1)
    }
    if (-not $numbers.Contains($next)) { [void]$numbers.Add($next) }
  }

  return ($numbers | Sort-Object)
}

function Invoke-OpenAIReply {
  param(
    [string]$Model,
    [hashtable]$Profile,
    [string]$Question
  )

  if ([string]::IsNullOrWhiteSpace($openAiKey)) {
    return 'OpenAI API key is missing from lotto.env. Showing local analysis only.'
  }

  $body = @{
    model = $Model
    instructions = @'
You are a Korean-language zodiac recommendation chatbot.
Be concise and friendly.
Explain the chosen lucky numbers in a natural way.
Avoid mystical overclaiming.
Format:
1. Zodiac name
2. Lucky numbers
3. Reason in 2-4 sentences
4. One short closing line
'@
    input = @(
      "Birthdate: $($Profile.birthDate)"
      "Zodiac key: $($Profile.signKey)"
      "Lucky numbers: $($Profile.numbers -join ', ')"
      "User question: $Question"
    ) -join "`n"
    reasoning = @{ effort = 'low' }
    text = @{ verbosity = 'medium' }
    store = $false
  } | ConvertTo-Json -Depth 8

  try {
    $response = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/responses' -Headers @{
      Authorization = "Bearer $openAiKey"
    } -ContentType 'application/json' -Body $body -TimeoutSec 120

    if ($response.output_text) { return [string]$response.output_text }

    if ($response.output) {
      $parts = New-Object System.Collections.Generic.List[string]
      foreach ($item in $response.output) {
        if ($item.type -eq 'message' -and $item.content) {
          foreach ($content in $item.content) {
            if ($content.text) { [void]$parts.Add($content.text) }
          }
        }
      }
      if ($parts.Count -gt 0) { return ($parts -join "`n") }
    }

    return 'OpenAI response could not be read.'
  }
  catch {
    $zodiacNameMap = @{
      'capricorn' = 'Capricorn'
      'aquarius' = 'Aquarius'
      'pisces' = 'Pisces'
      'aries' = 'Aries'
      'taurus' = 'Taurus'
      'gemini' = 'Gemini'
      'cancer' = 'Cancer'
      'leo' = 'Leo'
      'virgo' = 'Virgo'
      'libra' = 'Libra'
      'scorpio' = 'Scorpio'
      'sagittarius' = 'Sagittarius'
    }

    $zodiacName = $zodiacNameMap[$Profile.signKey]
    if (-not $zodiacName) { $zodiacName = $Profile.signKey }

    return @"
$zodiacName
Lucky numbers: $($Profile.numbers -join ', ')
The numbers were derived from the birthdate pattern and the zodiac's recurring lucky set, then deduplicated and sorted for readability.
OpenAI was not reachable from this local server, so I returned a safe local explanation instead.
"@
  }
}

function Send-Response {
  param(
    $Stream,
    [int]$StatusCode,
    [string]$ContentType,
    [string]$Body
  )

  $statusText = switch ($StatusCode) {
    200 { 'OK' }
    400 { 'Bad Request' }
    404 { 'Not Found' }
    500 { 'Internal Server Error' }
    default { 'OK' }
  }

  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
  $headers = @(
    "HTTP/1.1 $StatusCode $statusText",
    "Content-Type: $ContentType",
    "Content-Length: $($bytes.Length)",
    "Connection: close",
    "Access-Control-Allow-Origin: *",
    "Access-Control-Allow-Methods: GET, POST, OPTIONS",
    "Access-Control-Allow-Headers: Content-Type",
    "",
    ""
  ) -join "`r`n"

  $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($headers)
  $Stream.Write($headerBytes, 0, $headerBytes.Length)
  $Stream.Write($bytes, 0, $bytes.Length)
}

function Get-ConstellationSvg {
  param([string]$Key, [string]$Color)
  switch ($Key) {
    'aries' { $points = @(@(30,95),@(60,55),@(110,42),@(160,60),@(185,94)) }
    'taurus' { $points = @(@(22,90),@(56,50),@(98,36),@(138,48),@(176,88),@(120,112)) }
    'gemini' { $points = @(@(40,24),@(40,106),@(76,42),@(76,88),@(116,28),@(116,102),@(160,44),@(160,90)) }
    'cancer' { $points = @(@(30,78),@(60,48),@(96,64),@(132,34),@(160,74),@(184,54)) }
    'leo' { $points = @(@(24,88),@(58,54),@(96,68),@(126,32),@(160,40),@(184,82)) }
    'virgo' { $points = @(@(22,30),@(52,60),@(78,34),@(106,78),@(132,44),@(166,98),@(184,58)) }
    'libra' { $points = @(@(28,76),@(62,44),@(96,74),@(132,44),@(170,76)) }
    'scorpio' { $points = @(@(24,52),@(52,32),@(86,52),@(116,24),@(142,54),@(172,82)) }
    'sagittarius' { $points = @(@(26,98),@(52,68),@(80,90),@(104,54),@(132,72),@(160,36),@(186,62)) }
    'capricorn' { $points = @(@(26,76),@(58,42),@(90,72),@(118,40),@(150,80),@(182,54)) }
    'aquarius' { $points = @(@(22,38),@(54,54),@(86,34),@(118,52),@(148,30),@(180,46),@(60,92),@(156,90)) }
    'pisces' { $points = @(@(30,42),@(56,26),@(82,58),@(106,34),@(130,74),@(160,50),@(184,82)) }
  }

  $path = ($points | ForEach-Object { "$($_[0]),$($_[1])" }) -join ' '
  $circles = ($points | ForEach-Object { "<circle cx=""$($_[0])"" cy=""$($_[1])"" r=""3.8"" fill=""$Color"" />" }) -join ''
  return @"
<svg viewBox="0 0 200 120" role="img" aria-label="constellation">
  <rect x="0" y="0" width="200" height="120" rx="4" fill="#eef4ff" />
  <polyline points="$path" fill="none" stroke="$Color" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" />
  $circles
</svg>
"@
}

function Get-HiggsfieldCredentials {
  param([object]$Payload)

  $apiKey = $null
  $apiSecret = $null

  if ($Payload -and $Payload.PSObject.Properties['higgsfieldApiKey'] -and -not [string]::IsNullOrWhiteSpace([string]$Payload.higgsfieldApiKey)) {
    $apiKey = [string]$Payload.higgsfieldApiKey
  } elseif ($env:HIGGSFIELD_API_KEY) {
    $apiKey = $env:HIGGSFIELD_API_KEY
  }

  if ($Payload -and $Payload.PSObject.Properties['higgsfieldApiSecret'] -and -not [string]::IsNullOrWhiteSpace([string]$Payload.higgsfieldApiSecret)) {
    $apiSecret = [string]$Payload.higgsfieldApiSecret
  } elseif ($env:HIGGSFIELD_API_SECRET) {
    $apiSecret = $env:HIGGSFIELD_API_SECRET
  }

  return @{
    apiKey = $apiKey
    apiSecret = $apiSecret
  }
}

function Get-FirstImageUrl {
  param([object]$Value)

  if ($null -eq $Value) { return $null }
  if ($Value -is [string] -and $Value -match '^https?://') { return $Value }

  $directKeys = @('url', 'image_url', 'imageUrl', 'resultImageUrl', 'result_image_url', 'output_url', 'outputUrl')
  foreach ($key in $directKeys) {
    if ($Value.PSObject -and $Value.PSObject.Properties[$key]) {
      $candidate = [string]$Value.$key
      if (-not [string]::IsNullOrWhiteSpace($candidate) -and $candidate -match '^https?://') {
        return $candidate
      }
    }
  }

  if ($Value -is [System.Array]) {
    foreach ($item in $Value) {
      $url = Get-FirstImageUrl -Value $item
      if ($url) { return $url }
    }
  }

  if ($Value.PSObject) {
    foreach ($prop in $Value.PSObject.Properties) {
      if ($prop.Value -is [System.Array] -or $prop.Value -is [pscustomobject]) {
        $url = Get-FirstImageUrl -Value $prop.Value
        if ($url) { return $url }
      }
    }
  }

  return $null
}

function Get-HiggsfieldStatus {
  param([object]$Value)
  if ($null -eq $Value) { return '' }
  foreach ($key in @('status', 'state', 'phase')) {
    if ($Value.PSObject -and $Value.PSObject.Properties[$key]) {
      $status = [string]$Value.$key
      if (-not [string]::IsNullOrWhiteSpace($status)) {
        return $status.ToLowerInvariant()
      }
    }
  }
  return ''
}

function Invoke-HiggsfieldCard {
  param(
    [object]$Payload,
    [hashtable]$Profile
  )

  $creds = Get-HiggsfieldCredentials -Payload $Payload
  if ([string]::IsNullOrWhiteSpace($creds.apiKey) -or [string]::IsNullOrWhiteSpace($creds.apiSecret)) {
    return @{
      skipped = $true
      status = 'missing_credentials'
      imageUrl = $null
    }
  }

  $question = ''
  if ($Payload -and $Payload.PSObject.Properties['question']) {
    $question = [string]$Payload.question
  }

  $name = ''
  if ($Payload -and $Payload.PSObject.Properties['name']) {
    $name = [string]$Payload.name
  }

  $namePart = if ([string]::IsNullOrWhiteSpace($name)) { 'for the user' } else { "for $name" }

  $promptParts = @(
    "Create a premium vertical zodiac card $namePart."
    'Follow the Soul 2 editorial style with premium fashion-card energy.'
    'Use a creamy ivory, gold, and warm amber palette with a polished casino-luxury feel.'
    "Theme the artwork around the zodiac sign $($Profile.signName) and a refined constellation motif."
    'Center a cute but elegant mascot-like emblem inspired by the zodiac, with glossy highlights and soft depth.'
    'Make it look like a collectible fortune card, clean composition, subtle sparkles, circular halo framing, and editorial lighting.'
    'Portrait orientation, high detail, no watermark, no extra logos, no UI mockup, no collage.'
    'Avoid long readable text inside the image; keep the design visually strong on its own.'
    "Birthdate: $($Profile.birthDate). Lucky numbers: $($Profile.numbers -join ', ')."
    ("The user question is: $question." )
  )

  $body = @{
    prompt = ($promptParts -join ' ')
    num_images = 1
    resolution = '2K'
    aspect_ratio = '4:5'
  } | ConvertTo-Json -Depth 8

  $headers = @{
    Authorization = "Key $($creds.apiKey):$($creds.apiSecret)"
    Accept = 'application/json'
    'Content-Type' = 'application/json'
  }

  $submit = Invoke-RestMethod -Method Post -Uri 'https://platform.higgsfield.ai/higgsfield-ai/soul/standard' -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 120
  $requestId = $submit.request_id
  $statusUrl = if ($submit.status_url) { [string]$submit.status_url } else { "https://platform.higgsfield.ai/requests/$requestId/status" }
  $current = $submit
  $status = Get-HiggsfieldStatus -Value $current
  if ([string]::IsNullOrWhiteSpace($status)) { $status = 'queued' }
  $imageUrl = Get-FirstImageUrl -Value $current

  $deadline = (Get-Date).AddSeconds(25)
  while (-not $imageUrl -and $status -notin @('failed', 'nsfw', 'canceled') -and (Get-Date) -lt $deadline -and $statusUrl) {
    Start-Sleep -Seconds 2
    $current = Invoke-RestMethod -Method Get -Uri $statusUrl -Headers $headers -TimeoutSec 120
    $status = Get-HiggsfieldStatus -Value $current
    if ([string]::IsNullOrWhiteSpace($status)) { $status = 'queued' }
    $imageUrl = Get-FirstImageUrl -Value $current
  }

  return @{
    skipped = $false
    requestId = $requestId
    statusUrl = $statusUrl
    status = $status
    imageUrl = $imageUrl
    raw = $current
  }
}

if (-not (Test-Path $indexPath)) {
  throw "index.html not found at $indexPath"
}

$listener.Start()
Write-Host "Server running at http://localhost:$Port/"

try {
  while ($listener.Server.IsBound) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $buffer = New-Object byte[] 65536
      $ms = New-Object System.IO.MemoryStream

      do {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        if ($read -gt 0) { $ms.Write($buffer, 0, $read) }
      } while ($stream.DataAvailable)

      $raw = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
      $ms.Dispose()

      $parts = $raw -split "`r`n`r`n", 2
      $headerText = $parts[0]
      $bodyText = if ($parts.Count -gt 1) { $parts[1] } else { '' }
      $headerLines = $headerText -split "`r`n"
      $requestLine = $headerLines[0]
      $requestParts = $requestLine -split ' '
      $method = $requestParts[0]
      $path = $requestParts[1]

      $headers = @{}
      for ($i = 1; $i -lt $headerLines.Count; $i++) {
        $line = $headerLines[$i]
        $idx = $line.IndexOf(':')
        if ($idx -gt 0) {
          $name = $line.Substring(0, $idx).Trim().ToLowerInvariant()
          $value = $line.Substring($idx + 1).Trim()
          $headers[$name] = $value
        }
      }

      $contentLength = 0
      if ($headers.ContainsKey('content-length')) {
        [int]::TryParse($headers['content-length'], [ref]$contentLength) | Out-Null
      }

      while ($bodyText.Length -lt $contentLength) {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        if ($read -le 0) { break }
        $bodyText += [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read)
      }

      if ($method -eq 'OPTIONS') {
        Send-Response -Stream $stream -StatusCode 204 -ContentType 'text/plain; charset=utf-8' -Body ''
        continue
      }

      if ($method -eq 'GET' -and ($path -eq '/' -or $path -eq '/index.html')) {
        $html = Get-Content -LiteralPath $indexPath -Raw
        Send-Response -Stream $stream -StatusCode 200 -ContentType 'text/html; charset=utf-8' -Body $html
        continue
      }

      if ($method -eq 'POST' -and $path -eq '/api/analyze') {
        $payload = $bodyText | ConvertFrom-Json
        if (-not $payload.birthDate) {
          Send-Response -Stream $stream -StatusCode 400 -ContentType 'application/json; charset=utf-8' -Body (@{ error = 'birthDate is required' } | ConvertTo-Json)
          continue
        }

        $date = [datetime]::Parse($payload.birthDate)
        $sign = Get-ZodiacSign -Date $date
        $numbers = Get-LuckyNumbers -Date $date -Sign $sign
        $model = if ($payload.model) { [string]$payload.model } else { $defaultModel }

        $profileForPrompt = @{
          birthDate = $payload.birthDate
          signKey = $sign.key
          signName = $sign.name
          numbers = @($numbers)
        }

        $higgsfield = $null
        try {
          $higgsfield = Invoke-HiggsfieldCard -Payload $payload -Profile $profileForPrompt
        } catch {
          $higgsfield = @{
            skipped = $false
            requestId = $null
            statusUrl = $null
            status = 'failed'
            imageUrl = $null
            error = $_.Exception.Message
          }
        }
        $explanation = Invoke-OpenAIReply -Model $model -Profile $profileForPrompt -Question ([string]$payload.question)

        $response = @{
          profile = @{
            birthDate = $payload.birthDate
            signKey = $sign.key
            numbers = @($numbers)
            constellationSvg = (Get-ConstellationSvg -Key $sign.key -Color '#3d4f97')
            higgsfieldStatus = $higgsfield.status
            higgsfieldRequestId = $higgsfield.requestId
            cardImageUrl = $higgsfield.imageUrl
            cardImageError = if ($higgsfield.error) { $higgsfield.error } else { $null }
          }
          explanation = $explanation
        } | ConvertTo-Json -Depth 8

        Send-Response -Stream $stream -StatusCode 200 -ContentType 'application/json; charset=utf-8' -Body $response
        continue
      }

      Send-Response -Stream $stream -StatusCode 404 -ContentType 'application/json; charset=utf-8' -Body '{"error":"Not found"}'
    }
    catch {
      $body = (@{ error = $_.Exception.Message } | ConvertTo-Json)
      try {
        Send-Response -Stream $stream -StatusCode 500 -ContentType 'application/json; charset=utf-8' -Body $body
      } catch {
      }
    }
    finally {
      if ($stream) { $stream.Close() }
      $client.Close()
    }
  }
}
finally {
  $listener.Stop()
}
