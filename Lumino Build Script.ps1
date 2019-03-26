# Lumino PC Build Setup Script
# Run this script after Windows 10 has been installed.

# Select the Practice you are setting up

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Lumino Practice'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select a Lumino Practice:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

[void] $listBox.Items.Add('LCP - Courtenay Place')
[void] $listBox.Items.Add('LGH - George Hunt')
[void] $listBox.Items.Add('LJV - Johnsonville')
[void] $listBox.Items.Add('LLD - Levin')
[void] $listBox.Items.Add('LAD - Lower Hutt Absolute')
[void] $listBox.Items.Add('LLH - Lower Hutt Raffles & Henderson')
[void] $listBox.Items.Add('LMD - Miramar')
[void] $listBox.Items.Add('LPS - Panama Street')
[void] $listBox.Items.Add('LOD - Otaki')
[void] $listBox.Items.Add('LSD - Silverstream')
[void] $listBox.Items.Add('LSV - Stokes Valley')
[void] $listBox.Items.Add('LTT - The Terrace')
[void] $listBox.Items.Add('LWD - Waikanae')

$form.Controls.Add($listBox)
$form.Topmost = $true
$result = $form.ShowDialog()


if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    # PracticeID will be the 3 digit site code selected above
    $PracticeID = $listBox.SelectedItem.Substring(0,3)
    $PracticeID
}

if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
{
# Terminates script if Cancel is chosen
exit
}

# Input New PC Name and Rename Computer
Add-Type -AssemblyName Microsoft.VisualBasic
$Computer = [Microsoft.VisualBasic.Interaction]::InputBox('Enter the new Computer name:', 'Computer Rename', "$PracticeID-")
Rename-Computer -NewName $Computer


# Configure the PC

# Set Time Zone
Start-Service W32Time
Set-TimeZone -name "New Zealand Standard Time"
W32tm /resync /force

# Start Windows Updates
Start-Service wuauserv
wuauclt.exe /detectnow
wuauclt.exe /updatenow


# Disable Sleep
powercfg -change -standby-timeout-ac 0
powercfg -change -standby-timeout-dc 0
powercfg -change -monitor-timeout-ac 60
powercfg -change -monitor-timeout-dc 60


# Disable Windows Defender
reg import Registry\Disable-Defender.reg

# Restores Windows Photo Viewer for all users, still need to set photo file associations.
reg import Registry\Restore_Windows_Photo_Viewer_ALL_USERS.reg

# Disable P2P Update downlods outside of local network
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f


# Disable Remote Assistance
REG add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f
netsh advfirewall firewall set rule group="Remote Assistance" new enable=no

# Enable Remote Desktop
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
netsh advfirewall firewall set rule group="remote desktop" new enable=yes

# Install Telnet
dism /online /Enable-Feature /FeatureName:TelnetClient


# Disable Services
Set-Service -Name WMPNetworkSvc -DisplayName 'Windows Media Player Network Sharing Service' -StartupType Disabled
Set-Service -Name icssvc -DisplayName 'Windows Mobile Hotspot Service' -StartupType Disabled
Set-Service -Name BTAGService -Displayname 'Bluetooth Support Service' -StartupType Disabled
Set-Service -Name bthserv -Displayname 'Bluetooth Audio Gateway Service' -StartupType Disabled



# Disable Scheduled Tasks
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Uploader" /Disable
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyMonitor" /Disable
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyMonitorToastTask" /Disable
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyRefreshTask" /Disable


# Install the required Applications
start-process -wait -filepath "Applications\Foxit\FoxitReader93_enu_Setup.msi" -argumentlist "TRANSFORMS=FoxitReader93_enu_Setup_FCT.mst AUTO_UPDATE=2 /quiet"
start-process -wait -filepath "Applications\Chrome\GoogleChromeStandaloneEnterprise64.msi"


# Install LANcare Agent + Lumino Head Office Agent
switch ($PracticeID) {
LCP {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Courtenay.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\CourtenayPlace-123WindowsAgentSetup.exe" -argumentlist "-ai"
}
LGH {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-GeorgeHunt.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\GeorgeHunt-211WindowsAgentSetup.exe" -argumentlist "-ai"
}
LJV {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Johnsonville.MSI /quiet /norestart"
#start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\JVILLEWindowsAgentSetup.exe" -argumentlist "-ai"
}
LLD {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Levin.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Levin-141WindowsAgentSetup.exe" -argumentlist "-ai"
}
LAD {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Absolute.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Absolute-184WindowsAgentSetup.exe" -argumentlist "-ai"
}
LLH {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Raffles.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Raffles_110WindowsAgentSetup.exe" -argumentlist "-ai"
}
LMD {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Miramar.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Miramar-185WindowsAgentSetup.exe" -argumentlist "-ai"
}
LPS {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Panama.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Panama-157WindowsAgentSetup.exe" -argumentlist "-ai"
}
LOD {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Otaki.MSI /quiet /norestart"
#start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\OTAKIWindowsAgentSetup.exe" -argumentlist "-ai"
}
LSD {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Silverstream.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Silverstream-107WindowsAgentSetup.exe" -argumentlist "-ai"
}
LSV {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Terrace.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Stokes-120WindowsAgentSetup.exe" -argumentlist "-ai"
}
LTT {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Stokes.MSI /quiet /norestart"
start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\Terrace-115WindowsAgentSetup.exe" -argumentlist "-ai"
}
LWD {
start-process msiexec -wait -argumentlist "/I Applications\LANcare_Agent\Labtech-Waikanae.MSI /quiet /norestart"
#start-process -wait -filepath "Applications\LuminoHeadOffice_Agent\WAIKANAEWindowsAgentSetup.exe" -argumentlist "-ai"
}
default {
#Nothing else should apply if no correct match
}
}




[System.Windows.MessageBox]::Show('The workstation configuration script is complete. Next please reboot the computer and then run the Debloater script')

shutdown -f -r -t 00