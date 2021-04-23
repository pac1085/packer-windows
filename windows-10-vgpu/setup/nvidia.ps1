$ErrorActionPreference = "Stop"

$webserver = "192.168.51.55"
$url = "http://" + $webserver
$7za = "7za.exe"
$installer = "452.96_grid_win10_server2016_server2019_64bit_international.exe"
$7zaArgs = "x C:\$installer -oC:\NVIDIA\"
$licenseServer = "192.168.51.55"
$licenseServerPort = "7070"
$listConfig = "/s /v `"/qn REBOOT=ReallySuppress`""

# Verify connectivity
$connTestResult = Test-NetConnection -Computername $webserver -Port 80
if ($connTestResult.TcpTestSucceeded){
  # Get 7za to extract the installer
  Invoke-WebRequest -Uri ($url + "/downloads/packer/" + $7za) -OutFile C:\$7za
  
  # Get NVIDIA Driver package
  Invoke-WebRequest -Uri ($url + "/downloads/packer/" + $installer) -OutFile C:\$installer

  # Unblock files
  Unblock-File C:\$7za -Confirm:$false
  Unblock-File C:\$installer -Confirm:$false

  # Extract and install GRID Driver
  Try 
  {
	Start-Process C:\$7za -ArgumentList $7zaArgs -PassThru -wait
	Start-Process C:\NVIDIA\setup.exe -ArgumentList $listConfig -PassThru -Wait
	New-ItemProperty -path "HKLM:\Software\NVIDIA Corporation\Global\GridLicensing" -name "ServerAddress" -value "$licenseServer" -propertytype string -force
	New-ItemProperty -path "HKLM:\Software\NVIDIA Corporation\Global\GridLicensing" -name "ServerPort" -value "$licenseServerPort" -propertytype string -force
  }
  Catch
  {
    Write-Error "Failed to install the NVIDIA GRID Drivers"
    Write-Error $_.Exception
    Exit -1 
  }

  # Cleanup on aisle 4...
  Remove-Item C:\$installer -Confirm:$false
  Remove-Item C:\$7za -Confirm:$false
  Remove-Item C:\NVIDIA -Confirm:$false -recurse
}