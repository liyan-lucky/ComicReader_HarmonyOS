param(
  [Parameter(Mandatory = $true)][ValidateSet('targets','install','start','click','input','key','swipe','dump','screenshot','wait-dump')][string]$Action,
  [string]$Target = '127.0.0.1:5555',
  [int]$X = 0,
  [int]$Y = 0,
  [int]$X2 = 0,
  [int]$Y2 = 0,
  [string]$Text = '',
  [int]$KeyId = 0,
  [string]$Name = 'vm-state',
  [int]$WaitSeconds = 0
)

$ErrorActionPreference = 'Stop'
$hdc = 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
$workspace = Split-Path -Parent $PSScriptRoot
$hap = Join-Path $workspace 'entry\build\default\outputs\default\entry-default-signed.hap'

switch ($Action) {
  'targets' { & $hdc list targets }
  'install' { & $hdc -t $Target install -r $hap }
  'start' { & $hdc -t $Target shell aa start -a EntryAbility -b com.nw.cleansite.novel.hm }
  'click' { & $hdc -t $Target shell uitest uiInput click $X $Y }
  'input' { & $hdc -t $Target shell uitest uiInput inputText $X $Y $Text }
  'key' { & $hdc -t $Target shell uitest uiInput keyEvent $KeyId }
  'swipe' { & $hdc -t $Target shell uitest uiInput swipe $X $Y $X2 $Y2 1200 }
  'dump' {
    $remote = "/data/local/tmp/$Name.json"
    $local = Join-Path $workspace "$Name.json"
    & $hdc -t $Target shell uitest dumpLayout -p $remote
    & $hdc -t $Target file recv $remote $local
  }
  'screenshot' {
    $remote = "/data/local/tmp/$Name.jpeg"
    $local = Join-Path $workspace "$Name.jpeg"
    & $hdc -t $Target shell snapshot_display -f $remote
    & $hdc -t $Target file recv $remote $local
  }
  'wait-dump' {
    if ($WaitSeconds -gt 0) { Start-Sleep -Seconds $WaitSeconds }
    $remote = "/data/local/tmp/$Name.json"
    $local = Join-Path $workspace "$Name.json"
    & $hdc -t $Target shell uitest dumpLayout -p $remote
    & $hdc -t $Target file recv $remote $local
  }
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
