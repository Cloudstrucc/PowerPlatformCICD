param ($SourceURL, $TargetURL, $ClientID, $ClientSecret, $TenantID, $PortalSourceRootDirectory, $PortalName, $DeploymentProfile)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

## Starting in Windows 10, version 1607, MAX_PATH limitations have been removed from common Win32 
## file and directory functions. However, you must opt-in to the new behavior by setting the following REGISTRY KEY
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
-Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$targetNugetExe = ".\nuget.exe"
Remove-Item .\CLI -Force -Recurse -ErrorAction Ignore
Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
Set-Alias nuget $targetNugetExe -Scope Global -Verbose
##
##Download & Install PowerApps CLI 
##
./nuget install Microsoft.PowerApps.CLI -Version '1.12.2' -O .
cd ./Microsoft.PowerApps.CLI.1.12.2
cd tools
##
##Download Portal 
##

$portalPath = $Env:BUILD_SOURCESDIRECTORY+'\'+$PortalSourceRootDirectory+'\'
.\pac.exe auth create --url $SourceURL --applicationId $ClientID --tenant $TenantID --clientSecret $ClientSecret
$portalQuery = .\pac.exe paportal list
$portal = $portalQuery[5].substring(12,36)
##.\pac.exe paportal download -id $portal -p . -o true
##.\pac.exe paportal download -id $portal -p $portalPath -o true

##
##Upload Portal to Target Dataverse Environment
##

## Copy downloaded portal to artefact staging directory
$portalArtefactPath = $Env:BUILD_SOURCESDIRECTORY+'\'
$deploymentProfilesPath = $portalArtefactPath+$PortalSourceRootDirectory+'\Deployment-Profiles\'
$downloadedPortalPath = $portalPath + $PortalName
Copy-Item -Path $downloadedPortalPath -Destination $portalArtefactPath -Recurse -Force
Copy-Item -Path $deploymentProfilesPath -Destination $downloadedPortalPath -Recurse -Force

.\pac.exe auth create --url $TargetURL --applicationId $ClientID --tenant $TenantID --clientSecret $ClientSecret
$portalQuery = .\pac.exe paportal list
$portal = $portalQuery[5].substring(12,36)
.\pac.exe paportal upload -p $downloadedPortalPath --deploymentProfile $DeploymentProfile

cd ..\..\
Remove-Item Microsoft.PowerApps.CLI.1.12.2 -Force -Recurse -ErrorAction Ignore
Remove-Item nuget.exe -Recurse