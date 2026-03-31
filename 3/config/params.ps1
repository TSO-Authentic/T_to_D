New-Item -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "DepartmentCode" -Value "210"
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "CustomerCode" -Value "116477"
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "Password" -Value "dirbitest"
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "ExpectedText1" -Value "Rich Client Test Menu !!"
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "ExpectedText2" -Value "ó]óÕÅ@Sub Menu"
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "ExpectedText3" -Value "óaÇËéëéYâÊñ ï\é¶"
Set-ItemProperty -Path "HKCU:\Software\UAT_HealthCheck_Automation" -Name "AuthPageURL" -Value "http://172.16.112.142:9801/webbroker3/rc/test_client/LoginAuthCodeConfirmInput.jsp"