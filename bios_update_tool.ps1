#BIOS updater tool
#Created by Brooks Peppin
#Contributing content – https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/, https://deploymentramblings.wordpress.com/2011/08/17/dell-bios-updates-with-powershell/
#UPdated 6/27/16

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running “as Administrator”
if ($myWindowsPrincipal.IsInRole($adminRole))
{
# We are running “as Administrator” – so change the title and background color to indicate this
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + “(Elevated)”
#$Host.UI.RawUI.BackgroundColor = “DarkBlue”
clear-host
}
else
{
# We are not running “as Administrator” – so relaunch as administrator

# Create a new process object that starts PowerShell
$newProcess = new-object System.Diagnostics.ProcessStartInfo “PowerShell”;

# Specify the current script path and name as a parameter
$newProcess.Arguments = $myInvocation.MyCommand.Definition;

# Indicate that the process should be elevated
$newProcess.Verb = “runas”;

# Start the new process
[System.Diagnostics.Process]::Start($newProcess);

# Exit from the current, unelevated, process
exit
}

# Run your code that needs to be elevated here
#Write-Host -NoNewLine “Press any key to continue…”
#$null = $Host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”)
$Model = $((Get-WmiObject -Class Win32_ComputerSystem).Model).Trim()
$BIOSVersion = ((Get-WMIObject -Class Win32_BIOS).SMBIOSBIOSVersion)
Write-Host “Your current Model is: $Model” -ForegroundColor white
Write-Host “Your current BIOS version is: $BIOSVersion`n” -ForegroundColor White
Write-Host “Getting list of available $model BIOSes from downloads.dell.com…”
#$Model = “Precision Tower T5810″
$model_short = $model.split(” “)
$url = “http://downloads.dell.com/published/pages/”
$main_page = Invoke-WebRequest $url -UseBasicParsing
$path = @(($main_page.links | ?{ $_.outerHTML -match $model_short[$model_short.length – 1] }).href)
switch ($Model) {
“Precision Tower T5810” {
$url = $url + $path[1]
$model_page = Invoke-WebRequest $url -UseBasicParsing
$BIOSUpdateFile = @(($model_page.Links | ?{ $_.href -match $model_short[$model_short.length – 1] + “A” }).href)
}
“Precision 5510” {
$url = $url + $path[1]
$model_page = Invoke-WebRequest $url -UseBasicParsing
$BIOSUpdateFile = @(($model_page.Links | ?{ $_.href -match “Precision_5510” }).href)
}
default {
$url = $url + $path[0]
$model_page = Invoke-WebRequest $url -UseBasicParsing
$BIOSUpdateFile = @(($model_page.Links | ?{ $_.href -match $model_short[$model_short.length – 1] + “A” }).href)
}
}
#$BIOSUpdateFile
Try
{
Do
{

write-Host “Please select BIOS you would like to update to:” -ForegroundColor Yellow
for ($i = 0; $i -lt $BIOSUpdateFile.length; $i++)
{
write-host $i”:” $BIOSUpdateFile[$i].split(“/”)[3] -ForegroundColor Yellow
}
$var = read-host
Write-Host “You have entered: “$BIOSUpdateFile[$var].split(“/”)[3]”`nIs this correct? (y/n)” -foreground “yellow”
$BIOS = $BIOSUpdateFile[$var]
$confirmation = Read-Host
}
while ($confirmation -ne ‘y’)
$BIOS = $BIOSUpdateFile[$var].split(“/”)[3]
$BIOSUpdateFile = $BIOSUpdateFile[$var]
#echo “http://eus-repo.vmware.com/windows/BIOS/$model/$BIOS”
Write-Host “Downloading $BIOS to $env:temp” -ForegroundColor Yellow
If ((Test-Path $env:TEMP\$BIOS) -eq $true)
{
Write-Host “BIOS already downloaded. Skipping…” -ForegroundColor Yellow
}
else
{
#Write-Host “http://downloads.dell.com$BIOS”
#Write-Host “http://downloads.dell.com$BIOSUpdateFile”
Start-BitsTransfer “http://downloads.dell.com$BIOSUpdateFile” $env:TEMP\

}
$en = (Get-BitLockerVolume -MountPoint C:).ProtectionStatus
if ($en = “On”) { Write-Host “Bitlocker is enabled. Suspending to perform BIOS flash.” -ForegroundColor Yellow }
Suspend-BitLocker -MountPoint “C:” -RebootCount 1

#Invoke-Expression $env:TEMP\$BIOS ” /quiet”
$objStartInfo = New-Object System.Diagnostics.ProcessStartInfo
$objStartInfo.FileName = “$env:TEMP\$BIOS”
#$objStartInfo.Arguments = “-noreboot -nopause -forceit”
#$objStartInfo.CreateNoWindow = $true
[System.Diagnostics.Process]::Start($objStartInfo) | Out-Null
}
Catch
{
[Exception]
Write-Output “Failed: $_”
pause
}
