$script                     = $MyInvocation.MyCommand.Definition
$packageName                = 'Office2019ProPlus'
$configFile                 = Join-Path $(Split-Path -parent $script) 'configuration.xml'
$configFile64               = Join-Path $(Split-Path -parent $script) 'configuration64.xml'
$bitCheck                   = Get-ProcessorBits
$forceX86                   = $env:chocolateyForceX86
$configurationFile          = if ($BitCheck -eq 32 -Or $forceX86) { $configFile } else { $configFile64 }
$officetempfolder           = Join-Path $env:Temp 'chocolatey\Office2019ProPlus'

$pp = Get-PackageParameters
$configPath = $pp["ConfigPath"]
$language = $pp["Language"]

if ($configPath)
{
    Write-Output "Custom config specified: $configPath"
    $configurationFile = $configPath
}
elseif ($language)
{
    Write-Output "Language specified: $language"
    
    $file = $configFile
    $x = [xml] (Get-Content $file)
    $nodes = $x.SelectNodes("/Configuration/Add/Product/Language")
    foreach($node in $nodes) {
        $node.SetAttribute("ID", $language)
    }
    $x.Save($file)
    
    $file = $configFile64
    $x = [xml] (Get-Content $file)
    $nodes = $x.SelectNodes("/Configuration/Add/Product/Language")
    foreach($node in $nodes) {
        $node.SetAttribute("ID", $language)
    }
    $x.Save($file)
}
else
{
    Write-Output 'No custom configuration specified.'
    Write-Output 'No language specified. Defaulting to OS language.'
}

$packageArgs                = @{
    packageName             = 'Office2019DeploymentTool'
    fileType                = 'exe'
    url                     = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17328-20162.exe'
    checksum                = 'e26cf4852eaa2226bfd41ed5207192146b276da6129843daaf750d571c59428f'
    checksumType            = 'sha256'
    softwareName            = 'Microsoft Office 2019 ProPlus*'
    silentArgs              = "/extract:`"$officetempfolder`" /log:`"$officetempfolder\OfficeInstall.log`" /quiet /norestart"
    validExitCodes          = @(
        0, # success
        3010, # success, restart required
        2147781575, # pending restart required
        2147205120  # pending restart required for setup update
    )
}

# Download and install the deployment tool
Install-ChocolateyPackage @packageArgs

# Run the actual Office setup
$packageArgs['file'] = "$officetempfolder\Setup.exe"
$packageArgs['packageName'] = $packageName
$packageArgs['silentArgs'] = "/configure $configurationFile"
Install-ChocolateyInstallPackage @packageArgs

if (Test-Path "$officetempfolder") {
    Remove-Item -Recurse "$officetempfolder"
}
