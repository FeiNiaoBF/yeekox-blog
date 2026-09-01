param (
    [Parameter(Mandatory=$true)]
    [string]$global,
    [Parameter(Mandatory=$false)]
    [string]$category = "",
    [Parameter(Mandatory=$false)]
    [string]$file = ""
)

$languages = @("zh-cn", "en", "ja")
$basePath = ".\"
$hugoBasePath = Resolve-Path $basePath -ErrorAction Stop
$errorCount = 0

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
    # 根据新架构生成文件后缀名的路径，并用 ${} 保护变量名
    $filePath = if ([string]::IsNullOrEmpty($category)) {
        if ([string]::IsNullOrEmpty($file)) {
            "content\${global}\_index.${lang}.md"   # 仅 global 参数 (例如: content\blog\_index.zh-cn.md)
        } else {
            "content\${global}\${file}.${lang}.md"  # global + file 参数 (例如: content\blog\my-post.zh-cn.md)
        }
    } else {
        if ([string]::IsNullOrEmpty($file)) {
            "content\${global}\${category}\_index.${lang}.md"  # global + category 参数
        } else {
            "content\${global}\${category}\${file}.${lang}.md" # 所有参数组合
        }
    }

    Write-Host "Creating $filePath..."
    try {
        # 检查文件是否存在
        if (Test-Path $filePath) {
            throw "File already exists"
        }

        # 创建父目录（如果需要）
        $parentDir = Split-Path $filePath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir | Out-Null
        }

        # 调用 Hugo 命令
        & hugo new $filePath
        if ($LASTEXITCODE -ne 0) {
            throw "Hugo command failed with exit code $LASTEXITCODE"
        }
    } catch {
        $errorCount++
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# 根据错误计数显示最终结果
if ($errorCount -gt 0) {
    Write-Host "`nOperation completed with $errorCount error(s)." -ForegroundColor Yellow
} else {
    Write-Host "`nAll files created successfully!" -ForegroundColor Green
}
