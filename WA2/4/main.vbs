Set objIE = CreateObject("InternetExplorer.Application")
Set shell = CreateObject("WScript.Shell")

Dim scriptPath    
scriptPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))     
shell.Run "powershell -ExecutionPolicy Bypass -File """ & scriptPath & "config\params.ps1""", 0, True  

ACCOUNT_NO = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\AccountNo")
LOGIN_PASSWORD = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\LoginPassword")
TRADING_PASSWORD = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\TradingPassword")

STOCK_CODE_1 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\StockCode_1")
NUM_OF_SHARES_1 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\NumberOfShares_1")
EXEC_COND_1 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ExecutionCondtion_1")
CH_EXEC_COND_1 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ChildExecutionCondtion_1")

STOCK_CODE_2 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\StockCode_2")
NUM_OF_SHARES_2 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\NumberOfShares_2")
EXEC_COND_2 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ExecutionCondtion_2")
CH_EXEC_COND_2 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ChildExecutionCondtion_2")

WEB_PAGE_URL = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\WebPageURL")


objIE.Visible = True
objIE.Silent = True

Const ERROR_SUCCESS = 0
Const CLIENT_ERROR = 1
Dim errorCode, errorMessage

errorCode = ERROR_SUCCESS
errorMessage = ""

Main()
CleanupAndReportError()

' Main Function:
' Controls the entire automation process for web-based order entry.
' Steps: Navigates to login, performs login, places purchase and new orders, and checks for errors after each major step.
Function Main()
	objIE.Navigate WEB_PAGE_URL
	Refresh
	BypassSSLWarning
	CheckLoginPageAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function
	LoginCredentials ACCOUNT_NO, LOGIN_PASSWORD
	objIE.Document.getElementsByName("exec")(0).Click
	Refresh
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function

	'------------------------------Purchase-Order-------------------------------
	FindAndClickLink objIE, "button_equity", "child"
	FindAndClickLink objIE, "slm_order_buy_eq", "child"
	objIE.document.getElementById("UseIFD").Click
	Refresh
	FindInputAndFillData objIE, "name", "eq_pdcd", "text", STOCK_CODE_1
	FindAndClickLink objIE, "時価更新", "parent"
	Refresh
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function

	FindInputAndFillData objIE, "id", "idNormal_radio2", "radio", ""
	FindInputAndFillData objIE, "name", "eq_odqt", "text", NUM_OF_SHARES_1
	FindInputAndFillData objIE, "name", "eq_lpr_ifd", "text", EXEC_COND_1
	FindInputAndFillData objIE, "id", "eq_ecop_ifd_c1", "checkbox", ""
	FindInputAndFillData objIE, "name", "eq_sodcpr_ifd_c", "text", CH_EXEC_COND_1
	objIE.document.getElementById("btnA_order_confirm").Click
	Refresh
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function
	FindInputAndFillData objIE, "name", "aa_pw", "password", TRADING_PASSWORD
	FindAndClickLink objIE, "btnA_order", "child"
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function

	'------------------------------New-Order-------------------------------
	FindAndClickLink objIE, "menu_margin", "child"
	FindAndClickLink objIE, "slm_order_initial", "child"
	objIE.document.getElementById("UseIFD").Click
	Refresh
	FindInputAndFillData objIE, "name", "mr_pdcd", "text", STOCK_CODE_2
	FindAndClickLink objIE, "時価更新", "parent"
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function
	Refresh
	FindInputAndFillData objIE, "id", "idradio1-0", "radio", ""
	FindInputAndFillData objIE, "name", "mr_odqt", "text", NUM_OF_SHARES_2
	FindInputAndFillData objIE, "name", "mr_lpr_ifd", "text", EXEC_COND_2
	FindInputAndFillData objIE, "id", "mr_ecop_ifd_c1", "checkbox", ""
	FindInputAndFillData objIE, "name", "mr_sodcpr_ifd_c", "text", CH_EXEC_COND_2
	objIE.document.getElementById("confirm_button").Click
	Refresh
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function
	FindInputAndFillData objIE, "name", "aa_pw", "password", TRADING_PASSWORD
	CheckErrorAndCleanup
	If errorCode <> ERROR_SUCCESS Then Exit Function
	FindAndClickLink objIE, "btnA_order", "child"
End Function

' Checks if SSL warning page is displayed and automatically bypasses it by clicking the appropriate link
Function BypassSSLWarning()
    If Not objIE.Document Is Nothing Then
        ' Check if the SSL warning page is displayed
        If InStr(objIE.Document.body.innerHTML, "このサイトは安全ではありません") > 0 Then
            ' Find and click the link to bypass the warning
            For Each link In objIE.Document.Links
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

' LoginCredentials Function:
' Fills in the username and password fields on the login page using the provided credentials.
' Iterates through all input elements and sets values for account and password fields.
Function LoginCredentials(username, password)
	For Each element In objIE.Document.getElementsByTagName("input")
		If element.Name = "aa_accdcd" Then
			element.Value = username
		End If
		If element.Name = "lg_pw" Then
			element.Value = password
		End If
	Next
End Function

' Refresh Function:
' Waits for the Internet Explorer page to finish loading.
' Includes a 20-second timeout to prevent infinite waiting if the page fails to load.
Function Refresh
    Dim startTime
    startTime = Timer
    Do While objIE.Busy Or objIE.ReadyState <> 4
        WScript.Sleep 100
        If Timer - startTime > 20 Then
			errorCode = CLIENT_ERROR
			errorMessage = "Page load timeout: The operation took too long to complete."
			Exit Function
		End If
    Loop
End Function

' FindAndClickLink Function:
' Finds an anchor (<a>) element containing an image with a specific name or alt attribute, then clicks it.
' Used to automate navigation and button clicks on the web page.
Function FindAndClickLink(browser, targetImgName, tagLevel)
	Dim links, link, img
	Set links = browser.document.getElementsByTagName("a")
	For Each link In links
		If link.Children.Length > 0 Then
			Set img = link.getElementsByTagName("img")
			If img.Length > 0 Then
				If img(0).Name = targetImgName Or img(0).alt = targetImgName Then
					If tagLevel = "child" Then
						ClickEvent img(0), link
					Else
						ClickEvent link, link
					End If
					Exit For
				End If
			End If
		End If
	Next
	Refresh
End Function

' FindInputAndFillData Function:
' Locates an input element by name or ID and fills it with the specified value.
' Handles text, password, radio, and checkbox input types.
' Triggers click events for radio and checkbox types as needed.
Function FindInputAndFillData(browser, targetInputSelectorType, targetInputSelectorValue, targetInputType, targetInputData)
	Dim inputElement
	Select Case targetInputSelectorType
		Case "name"
			Set inputElement = browser.Document.getElementsByName(targetInputSelectorValue)(0)
		Case "id"
			Set inputElement = browser.Document.getElementById(targetInputSelectorValue)
		Case Else
			MsgBox "Unknown selection"
	End Select
	If Not inputElement Is Nothing Then
		Select Case targetInputType
			Case "text", "password"
				inputElement.Value = targetInputData
			Case "radio"
				inputElement.Checked = True
				ClickEvent inputElement, inputElement
			Case "checkbox"
				If Not inputElement Is Nothing Then
					If Not inputElement.Checked Then
						inputElement.Checked = True
						ClickEvent inputElement, inputElement
					End If
				End If
			Case Else
				MsgBox "Unknown selection"
		End Select
	End If
	Set inputElement = Nothing
End Function

' ClickEvent Function:
' Triggers a click event on the specified element.
' Uses FireEvent if an onclick handler exists, otherwise uses the default Click method.
Function ClickEvent(target, element)
	If Not IsNull(element.onclick) Then
		target.FireEvent "onclick"
	Else
		target.Click
	End If
End Function

' CheckLoginPageAndCleanup Function:
' Verifies that the login page loaded correctly by checking for the presence of the account input field.
' If not found, sets an error and cleans up the IE instance.
Function CheckLoginPageAndCleanup()
    On Error Resume Next
    Dim loginFieldExists
    loginFieldExists = False
    If Not objIE.Document Is Nothing Then
        If Not objIE.Document.getElementsByName("aa_accdcd") Is Nothing Then
            If objIE.Document.getElementsByName("aa_accdcd").Length > 0 Then
                loginFieldExists = True
            End If
        End If
    End If
    If Not loginFieldExists Then
        errorCode = CLIENT_ERROR
		errorMessage = "ターゲットのウェブページにアクセスできません: ログインページが正しく読み込まれませんでした。"
        If Not objIE Is Nothing Then
            objIE.Quit
            Set objIE = Nothing
        End If
        Exit Function
    End If
    On Error GoTo 0
End Function

' CheckErrorAndCleanup Function:
' Checks the page for error messages in the element with ID "error_display".
' If an error is found, sets the error code/message and cleans up the IE instance.
Function CheckErrorAndCleanup()
    On Error Resume Next
    Dim errorDisplay,IsSuccessful
	IsSuccessful = True
    Set errorDisplay = objIE.Document.getElementById("error_display")
    If Not errorDisplay Is Nothing Then
        If Trim(errorDisplay.innerText) <> "" Then
			IsSuccessful = False
            errorCode = CLIENT_ERROR
            errorMessage = errorDisplay.innerText
        End If
	End If
	If Not IsSuccessful Then
        If Not objIE Is Nothing Then
            objIE.Quit
            Set objIE = Nothing
        End If
        Exit Function
    End If
    On Error GoTo 0
End Function

' CleanupAndReportError Function:
' If an error occurred, writes the error message to a temporary file.
' Always ensures the IE instance is closed and exits the script with the appropriate error code.
Function CleanupAndReportError()
    If errorCode <> ERROR_SUCCESS Then
        Dim fso, errorFile
        Set fso = CreateObject("Scripting.FileSystemObject")
        Set errorFile = fso.CreateTextFile(fso.GetParentFolderName(WScript.ScriptFullName) & "\vbscript_error.tmp", True)
        errorFile.WriteLine errorMessage
        errorFile.Close
        Set errorFile = Nothing
        Set fso = Nothing
    End If
    If Not objIE Is Nothing Then
        objIE.Quit
        Set objIE = Nothing
    End If
    WScript.Quit errorCode
End Function