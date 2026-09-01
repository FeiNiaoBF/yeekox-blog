param (
    # 相对 content/ 的文章目录路径，例如：posts/memova、posts/6s081/05-trap
    [Parameter(Mandatory = $true)]
    [string]$Path,

    # 生成系列入口（_index.{lang}.md）而不是文章（index.{lang}.md）
    [switch]$Index,

    # 语言列表，默认三语；只写中文可传 -Lang zh-cn
    [string]$Lang = "zh-cn,en,ja"
)

$ErrorActionPreference = "Stop"

# 校验：必须在 Hugo 项目根目录运行
if (-not (Test-Path "hugo.yaml") -and -not (Test-Path "hugo.toml") -and -not (Test-Path "hugo.json")) {
    Write-Host "Error: 当前目录不是 Hugo 项目根（找不到 hugo.yaml/toml/json）" -ForegroundColor Red
    exit 1
}

# 校验 Path 不能包含 .. 等越界
if ($Path -match "\.\." -or $Path -match "^/|:\\") {
    Write-Host "Error: 非法路径：$Path" -ForegroundColor Red
    exit 1
}

$baseName = if ($Index) { "_index" } else { "index" }
$errorCount = 0

foreach ($lang in ($Lang -split "," | ForEach-Object { $_.Trim() })) {
    if ([string]::IsNullOrEmpty($lang)) { continue }
    $relPath = "content/$Path/$baseName.$lang.md"

    if (Test-Path $relPath) {
        Write-Host "跳过（已存在）: $relPath" -ForegroundColor Yellow
        continue
    }

    # 创建父目录并调用 Hugo 生成（自动套用 archetypes 模板）
    # 系列入口用 --kind series 命中 archetypes/series.md
    $parent = Split-Path $relPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($Index) {
        & hugo new --kind series $relPath
    } else {
        & hugo new $relPath
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: hugo new 失败（exit $LASTEXITCODE）: $relPath" -ForegroundColor Red
        $errorCount++
    } else {
        Write-Host "已创建: $relPath" -ForegroundColor Green
    }
}

if ($errorCount -gt 0) {
    Write-Host "`n完成，但有 $errorCount 个错误。" -ForegroundColor Yellow
} else {
    Write-Host "`n全部创建成功！" -ForegroundColor Green
}
