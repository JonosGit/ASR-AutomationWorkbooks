param(
[object] $RecoveryPlanContext
)
$connection = Get-AutomationConnection -Name AzureRunAsConnection

Connect-AzAccount -ServicePrincipal `
    -Tenant $connection.TenantID `
    -ApplicationId $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint
# Connect-AzAccount

$SubscriptionName = "Sundt Azure Dev/Test"
Set-AzContext -Subscription $SubscriptionName
$RecoveryPlanContextObj = $RecoveryPlanContext
$VMinfo = $RecoveryPlanContextObj.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
$vmMap = $RecoveryPlanContextObj.VmMap
    foreach($VMID in $VMinfo)
    {
        $VM = $vmMap.$VMID                
            if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) {
            #this check is to ensure that we skip when some data is not available else it will fail
    Write-output "Resource group name ", $VM.ResourceGroupName
    $script:SourceResourceGroupName = $VM.ResourceGroupname
    Write-output "VMname ", $VM.RoleName
    $script:VMName = $VM.RoleName
            }
        }


Try
{
$sblock1 = @"
$command1 = powershell.exe 'NetSh Advfirewall set allprofiles state off'
$testchannel = powershell.exe 'Test-ComputerSecureChannel'
$fixchannel = powershell.exe 'Test-ComputerSecureChannel -Repair'

if($testchannel -Eq "True")
    { Write-Host "Secure Channel Ok"}
    if($testchannel -Eq "False")
        { $fixchannel }

$command1
"@

Set-Content -Path .\DriveCommand.ps1 -Value $sblock1
Invoke-AzVMRunCommand -ResourceGroupName $script:SourceResourceGroupName -Name $script:VMName -CommandId 'RunPowerShellScript' -ScriptPath .\DriveCommand.ps1
Remove-Item .\DriveCommand.ps1
}
Catch
{
Write-Host -foregroundcolor Yellow `
"Exception Encountered"; `
$ErrorMessage = $_.Exception.Message
$LogOut  = 'Error '+$ErrorMessage
Write-Output -InputObject $LogOut
break
}

$completion = "Operations completed for VM $script:VMName." 

Write-Output -InputObject $completion