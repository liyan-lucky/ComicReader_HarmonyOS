param(
  [string]$RulesRepository = (Join-Path $PSScriptRoot '..\15_ComicReader_Rules')
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $RulesRepository 'rules\index.zh-Hans.json'
$target = Join-Path $PSScriptRoot '..\entry\src\main\ets\common\GeneratedSourceRules.ets'

if (-not (Test-Path -LiteralPath $source)) {
  throw "找不到规则索引: $source"
}

$index = Get-Content -LiteralPath $source -Raw -Encoding UTF8 | ConvertFrom-Json
$runtimeRules = @($index.rules) | ForEach-Object {
  $rule = [ordered]@{
    id = $_.id
    name = $_.name
    description = $_.description
    homepage = $_.homepage
    searchUrl = $_.searchUrl
    searchMethod = $_.searchMethod
    searchItemRegex = $_.searchItemRegex
    searchTitleGroups = @($_.searchTitleGroups)
    searchUrlGroups = @($_.searchUrlGroups)
    searchCoverGroups = @($_.searchCoverGroups)
    searchResultIsChapter = [bool]$_.searchResultIsChapter
    searchFilterByKeyword = [bool]$_.searchFilterByKeyword
    detailChapterRegex = $_.detailChapterRegex
    detailChapterTitleGroups = @($_.detailChapterTitleGroups)
    detailChapterUrlGroups = @($_.detailChapterUrlGroups)
    detailChapterFilter = [bool]$_.detailChapterFilter
    readerImageRegex = $_.readerImageRegex
    readerImageGroups = @($_.readerImageGroups)
    userAgent = $_.userAgent
    referer = $_.referer
    domainApplicabilityList = @($_.domainApplicabilityList)
  }
  if ($null -ne $_.readerNextPageRegex) { $rule.readerNextPageRegex = [string]$_.readerNextPageRegex }
  if ($null -ne $_.readerNextPageUrlGroups) { $rule.readerNextPageUrlGroups = @($_.readerNextPageUrlGroups) }
  if ($null -ne $_.maxReaderPages) { $rule.maxReaderPages = [int]$_.maxReaderPages }
  if ($null -ne $_.license) { $rule.license = [string]$_.license }
  if ($null -ne $_.sourceType) { $rule.sourceType = [string]$_.sourceType }
  $rule
}
$rulesJson = $runtimeRules | ConvertTo-Json -Depth 10
$header = @"
import { ComicSourceRule } from '../model/ComicModels';

/**
 * 自动生成文件：请不要手工修改。
 * 来源：15_ComicReader_Rules/rules/index.zh-Hans.json
 * 仅同步已经过规则仓库回放审计的按域名公开网页规则。
 */
export const GENERATED_SOURCES: ComicSourceRule[] = $rulesJson;
"@

[System.IO.File]::WriteAllText($target, $header, [System.Text.UTF8Encoding]::new($false))
Write-Host "已同步 $(@($index.rules).Count) 条已验证规则 -> $target"
