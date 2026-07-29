#Requires -Version 7.0
<#
.SYNOPSIS
    Installs Neovim + LazyVim + dependencies on Windows, and clones your config repo.

.PARAMETER RepoUrl
    Git URL of your neovim config repo (e.g. https://github.com/sentonnes/neovim-setup.git).
    If omitted, only dependencies are installed — no config is cloned.

.PARAMETER Force
    Overwrite an existing $env:LOCALAPPDATA\nvim directory instead of backing it up.

.EXAMPLE
    .\setup.ps1 -RepoUrl https://github.com/sentonnes/neovim-setup.git
#>

param(
    [string]$RepoUrl,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [ok] $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  [skip] $msg" -ForegroundColor DarkGray }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
Write-Step "Checking prerequisites"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install 'App Installer' from the Microsoft Store first."
}
Write-Ok "winget found"

# ---------------------------------------------------------------------------
# Package list
# winget id | why it's needed
# ---------------------------------------------------------------------------
$packages = @(
    @{ Id = 'Neovim.Neovim';                 Name = 'Neovim' }
    @{ Id = 'Git.Git';                       Name = 'Git' }
    @{ Id = 'BurntSushi.ripgrep.MSVC';       Name = 'ripgrep (Telescope live grep)' }
    @{ Id = 'sharkdp.fd';                    Name = 'fd (Telescope find files)' }
    @{ Id = 'junegunn.fzf';                  Name = 'fzf (fallback fuzzy finder)' }
    @{ Id = 'OpenJS.NodeJS.LTS';             Name = 'Node.js (LSP servers, CopilotChat)' }
    @{ Id = 'zig.zig';                       Name = 'Zig (C compiler for treesitter parsers)' }
    @{ Id = 'gerardog.gsudo';                Name = 'gsudo (optional, elevation helper)'; Optional = $true }
)

Write-Step "Installing packages via winget"
foreach ($pkg in $packages) {
    $installed = winget list --id $pkg.Id --exact --accept-source-agreements 2>$null | Select-String $pkg.Id
    if ($installed) {
        Write-Skip "$($pkg.Name) already installed"
        continue
    }
    Write-Host "  installing $($pkg.Name)..."
    try {
        winget install --id $pkg.Id --exact --silent --accept-package-agreements --accept-source-agreements
        Write-Ok "$($pkg.Name) installed"
    } catch {
        if ($pkg.Optional) {
            Write-Host "  [warn] optional package $($pkg.Name) failed, continuing" -ForegroundColor Yellow
        } else {
            throw "Failed to install required package $($pkg.Name): $_"
        }
    }
}

# ---------------------------------------------------------------------------
# Nerd Font (LazyVim icons / statusline glyphs)
# ---------------------------------------------------------------------------
Write-Step "Installing Nerd Font (CascadiaCode NF)"
$fontInstalled = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter "*CaskaydiaCove*NF*" -ErrorAction SilentlyContinue
if ($fontInstalled) {
    Write-Skip "Nerd Font already present"
} else {
    winget install --id 'DEVCOM.JetBrainsMonoNerdFont' --exact --silent --accept-package-agreements --accept-source-agreements
    Write-Ok "Nerd Font installed — set it as your Windows Terminal profile font manually"
}

# ---------------------------------------------------------------------------
# Refresh PATH in this session so freshly-installed tools are visible
# ---------------------------------------------------------------------------
Write-Step "Refreshing PATH for this session"
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + `
            [System.Environment]::GetEnvironmentVariable('Path','User')

foreach ($cmd in @('nvim','git','rg','fd','node')) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Ok "$cmd on PATH"
    } else {
        Write-Host "  [warn] $cmd not on PATH yet — you may need to restart your terminal" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# Config repo
# ---------------------------------------------------------------------------
$nvimConfigPath = Join-Path $env:LOCALAPPDATA 'nvim'

if (-not $RepoUrl) {
    Write-Step "No -RepoUrl supplied — skipping config clone"
    Write-Host "Run again with -RepoUrl <git-url> to clone your LazyVim config."
} else {
    Write-Step "Setting up config at $nvimConfigPath"

    if (Test-Path $nvimConfigPath) {
        if ($Force) {
            Write-Host "  -Force set, removing existing config"
            Remove-Item $nvimConfigPath -Recurse -Force
        } else {
            $backupPath = "$nvimConfigPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Write-Host "  existing config found, backing up to $backupPath"
            Move-Item $nvimConfigPath $backupPath
            Write-Ok "backed up"
        }
    }

    # Also clear cache/state/data dirs so LazyVim does a clean plugin install
    foreach ($dir in @('nvim-data','nvim-state','nvim-cache')) {
        $p = Join-Path $env:LOCALAPPDATA $dir
        if (Test-Path $p) {
            Remove-Item $p -Recurse -Force
            Write-Ok "cleared $dir"
        }
    }

    git clone $RepoUrl $nvimConfigPath
    Write-Ok "config cloned"

    Write-Step "Bootstrapping plugins (headless, may take a minute)"
    nvim --headless "+Lazy! sync" +qa
    Write-Ok "plugins synced"
}

Write-Step "Done"
Write-Host "Open a new terminal and run 'nvim' to verify." -ForegroundColor Green
if (-not $RepoUrl) {
    Write-Host "Reminder: no config was cloned this run." -ForegroundColor Yellow
}
