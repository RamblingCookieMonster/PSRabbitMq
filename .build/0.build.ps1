# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module PSDepend -Force

Invoke-PSDepend .\.build\1.depend.psd1 -Force
Set-BuildEnvironment

Invoke-psake .\.build\2.psake.ps1

exit ( [int]( -not $psake.build_success ) )