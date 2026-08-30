param(
  [string]$RulesRepository = (Join-Path $PSScriptRoot '..\15_ComicReader_Rules')
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $RulesRepository 'catalog\catalog.zh-Hans.json'
$target = Join-Path $PSScriptRoot '..\entry\src\main\resources\rawfile\catalog\catalog.zh-Hans.json'
if (-not (Test-Path -LiteralPath $source)) { throw "找不到目录: $source" }

$catalog = Get-Content -LiteralPath $source -Raw -Encoding UTF8 | ConvertFrom-Json
$items = @($catalog.categories.PSObject.Properties.Value | ForEach-Object { $_.items })
foreach ($item in $items) {
  foreach ($sourceItem in @($item.sources)) {
    $manifestCount = if ($null -eq $sourceItem.chapters) { 0 } else { @($sourceItem.chapters).Count }
    if ($manifestCount -ne [int]$item.verifiedChapterCount) {
      throw "章节清单不完整: $($item.title) $manifestCount/$($item.verifiedChapterCount)"
    }
  }
}

Copy-Item -LiteralPath $source -Destination $target -Force
Write-Host "已同步 $($items.Count) 本、版本 $($catalog.version) -> $target"
