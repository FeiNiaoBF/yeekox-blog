# Use: .\script\new-hugo-post.ps1 -global "blog" -category "bit-note"

param (
    [Parameter(Mandatory=$true)]
    [string]$global,
    [Parameter(Mandatory=$false)]
    [string]$category = ""
)

$languages = @("english", "chinese", "japan")
$basePath = ".\"
$hugoBasePath = Resolve-Path $basePath -ErrorAction Stop

# 切换到 Hugo 项目根目录
try {
    Set-Location $hugoBasePath
    Write-Host "Switched to directory: $hugoBasePath"
} catch {
    Write-Host "Error: Failed to switch to $hugoBasePath. Please check the path." -ForegroundColor Red
    exit 1
}

# 检查是否在正确的 Hugo 项目根目录
if (-not (Test-Path "hugo.yaml") -and -not (Test-Path "hugo.toml") -and -not (Test-Path "hugo.json")) {
    Write-Host "Error: This does not appear to be a Hugo project root directory (no hugo.yaml/toml/json found)." -ForegroundColor Red
    exit 1
}

# 动态构建文件路径并创建文件
foreach ($lang in $languages) {
    if ([string]::IsNullOrEmpty($category)) {
        $filePath = "content\$lang\$global\_index.md"
    } else {
        $filePath = "content\$lang\$global\$category\_index.md"
    }
    Write-Host "Creating $filePath..."
    try {
        # 使用 Start-Process 或 & 调用 hugo，避免参数混淆
        & hugo new $filePath
        if ($LASTEXITCODE -ne 0) {
            throw "Hugo command failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "Error: Failed to create $filePath. Details: $_" -ForegroundColor Red
    }
}

Write-Host "All files created successfully!" -ForegroundColor Green
