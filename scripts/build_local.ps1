$ErrorActionPreference = 'Continue'

$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$TEMP_DIR = if ($env:COMIC_READER_TEMP_DIR) { $env:COMIC_READER_TEMP_DIR } else { 'E:\Visual_Studio_Code\99_Temp' }
$DEVECO_SDK = 'C:\Program Files\Huawei\DevEco Studio\sdk'
$DEVECO_TOOLS = 'C:\Program Files\Huawei\DevEco Studio\tools'
$DEVECO_JBR = 'C:\Program Files\Huawei\DevEco Studio\jbr'

$env:DEVECO_SDK_HOME = $DEVECO_SDK
$env:HARMONYOS_SDK_ROOT = "$DEVECO_SDK\default"
$env:PATH = "$DEVECO_JBR\bin;$DEVECO_TOOLS\hvigor\bin;$env:PATH"

Write-Host "[本地构建] 项目目录: $ROOT_DIR"
Write-Host "[本地构建] 产物目录: $TEMP_DIR"

Set-Location $ROOT_DIR

node scripts/update_build_version.js --incremental --target local-build
if ($LASTEXITCODE -ne 0) { throw "版本号更新失败，退出码: $LASTEXITCODE" }

Write-Host "[本地构建] 直接调用hvigor构建HAP..." -ForegroundColor Cyan
$buildStartedAt = Get-Date
& node "$DEVECO_TOOLS\hvigor\bin\hvigorw.js" --stacktrace assembleHap
if ($LASTEXITCODE -ne 0) {
    Write-Host "[本地构建] 编译失败，不复制已有旧产物。" -ForegroundColor Red
    exit $LASTEXITCODE
}

if (!(Test-Path $TEMP_DIR)) { New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null }

$hapFiles = Get-ChildItem -Path $ROOT_DIR -Filter '*.hap' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $buildStartedAt.AddSeconds(-2) }
if ($hapFiles) {
    foreach ($hap in $hapFiles) {
        Copy-Item $hap.FullName -Destination $TEMP_DIR -Force
        $sizeKB = [math]::Round($hap.Length / 1KB, 1)
        Write-Host "[本地构建] 已复制: $($hap.Name) ($sizeKB KB) -> $TEMP_DIR" -ForegroundColor Green
    }
    Write-Host "[本地构建] 完成！" -ForegroundColor Green
} else {
    Write-Host "[本地构建] 未找到HAP文件" -ForegroundColor Red
    exit 1
}
