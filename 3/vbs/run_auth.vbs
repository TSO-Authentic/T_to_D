DIM IE, shell, doc, iframeELement, iframeContent, scriptPath

Set IE = CreateObject("InternetExplorer.Application")
IE.Visible = True
scriptPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))  
Set shell = CreateObject("WScript.Shell")
shell.run "powershell -ExecutionPolicy Bypass -File """ & scriptPath & "..\config\params.ps1""", 0, True

DEPARTMENT_CODE = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\DepartmentCode")
CUSTOMER_CODE = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\CustomerCode")
PASSWORD = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\Password")
AUTH_PAGE_URL = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\AuthPageURL")

Main()

' Main
' Navigates to the login page, performs login using credentials from the registry, accesses the iframe to retrieve session keys,
' checks for expected text at each navigation step, clicks through the workflow, verifies session consistency, and closes the browser.
Function Main()
    IE.Navigate AUTH_PAGE_URL
    Refresh
    BypassSSLWarning
    ClickAuthentication
End Function

Function ClickAuthentication() 

    Set doc = IE.Document
    Dim header, errorMsg
    If Not doc Is Nothing Then
        ' Wait for the page to load and check the title
        Dim waitCount
        waitCount = 0
        Do While doc.Title = "" And waitCount < 50
            WScript.Sleep 200
            waitCount = waitCount + 1
        Loop
        If doc.Title = "Rich Client" Then
            Set header = doc.getElementsByTagName("h3")
            If Not header Is Nothing And header.Length > 0 Then
                If InStr(header(0).innerText, "ログイン認証コード確認　入力") > 0 Then
                    doc.getElementsByName("aa_bcd")(0).Value = DEPARTMENT_CODE
                    doc.getElementsByName("aa_accd")(0).Value = CUSTOMER_CODE
                    doc.getElementsByName("pw")(0).Value = PASSWORD
                    ClickEvent "　認証　"
                    WScript.Sleep 1000
                End If
            End If
        End If
    End If
End Function

' Refresh
' Waits in a loop until the Internet Explorer browser is no longer busy and the page is fully loaded (ReadyState = 4).
Function Refresh()
	Do While IE.ReadyState <> 4 Or IE.Busy
		WScript.Sleep 100
	Loop
End Function

' ClickEvent
' Searches for an input element whose value matches the provided parameter, and clicks it if it is a submit button.
' Refreshes the page after the click to ensure the next step can proceed.
Function ClickEvent(param)
	Dim element
	For Each element In doc.getElementsByTagName("input")
		If element.Value = param Then
			If InStr(element.onclick, "submit") > 0 Or element.Type = "submit" Then
				element.Click
				Exit For
			End If
		End If
	Next
	Refresh
End Function

' Checks if SSL warning page is displayed and automatically bypasses it by clicking the appropriate link
Function BypassSSLWarning()
    If Not IE.Document Is Nothing Then
        ' Check if the SSL warning page is displayed
        If InStr(IE.Document.body.innerHTML, "このサイトは安全ではありません") > 0 Then
            ' Find and click the link to bypass the warning
            For Each link In IE.Document.Links
                If InStr(link.innerText, "Web ページに移動 (非推奨)") > 0 Then
                    link.Click
                    Exit For
                End If
            Next
            ' Wait for the page to load after clicking the link
            Refresh
        End If
    End If
End Function