# AIER Alert System - AWS Setup Script for Windows
# This script configures AWS CLI access for team members

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "AIER Alert System - AWS Configuration Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
$awsInstalled = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsInstalled) {
    Write-Host "ERROR: AWS CLI is not installed" -ForegroundColor Red
    Write-Host "Please install from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
}

Write-Host "AWS CLI found: " -NoNewline
aws --version
Write-Host ""

# Prompt for AWS credentials
Write-Host "Please enter your AWS credentials:" -ForegroundColor Yellow
Write-Host "(These will be provided by your team lead)" -ForegroundColor Yellow
Write-Host ""

$AccessKeyId = Read-Host "AWS Access Key ID"
$SecretAccessKey = Read-Host "AWS Secret Access Key" -AsSecureString
$SecretAccessKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretAccessKey)
)

$Region = Read-Host "Default AWS Region [us-east-1]"
if ([string]::IsNullOrWhiteSpace($Region)) {
    $Region = "us-east-1"
}

Write-Host ""

# Configure AWS CLI
Write-Host "Configuring AWS CLI..." -ForegroundColor Yellow
aws configure set aws_access_key_id $AccessKeyId --profile paid
aws configure set aws_secret_access_key $SecretAccessKeyPlain --profile paid
aws configure set region $Region --profile paid
aws configure set output json --profile paid

# Test AWS connection
Write-Host ""
Write-Host "Testing AWS connectivity..." -ForegroundColor Yellow
$env:AWS_PROFILE = "paid"

try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: AWS connection established" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your AWS Identity:" -ForegroundColor Cyan
        Write-Host $identity
    } else {
        throw "Connection failed"
    }
} catch {
    Write-Host "ERROR: Failed to connect to AWS" -ForegroundColor Red
    Write-Host "Please verify your credentials and try again"
    exit 1
}

# Create helper script for future sessions
$profileScript = @"
# AIER AWS Profile Helper
# Run this script to activate AIER AWS profile
`$env:AWS_PROFILE = "paid"
Write-Host "AWS Profile set to: paid" -ForegroundColor Green
"@

$profileScript | Out-File -FilePath "$HOME\aier-aws-profile.ps1" -Encoding UTF8
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To use AIER AWS profile in future PowerShell sessions, run:" -ForegroundColor Yellow
Write-Host "  . $HOME\aier-aws-profile.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Or add this to your PowerShell profile:" -ForegroundColor Yellow
Write-Host "  `$env:AWS_PROFILE = 'paid'" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Download Kaggle dataset: python scripts/download-dataset.py"
Write-Host "  2. Deploy infrastructure: cd terraform; terraform apply"
Write-Host "  3. Start development servers"
Write-Host ""

# Clear sensitive variables
$SecretAccessKeyPlain = $null
