Dim IE, shell, doc, iframeElement, iframeContent, domText, htmlClip
Dim scriptPath

' Don't create IE immediately - let FindAndClickButton handle it
Set IE = Nothing
scriptPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))  
Set shell = CreateObject("WScript.Shell")
shell.run "powershell -ExecutionPolicy Bypass -File """ & scriptPath & "..\config\params.ps1""", 0, True

DEPARTMENT_CODE = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\DepartmentCode")
CUSTOMER_CODE = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\CustomerCode")
PASSWORD = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\Password")
EXPECTED_TEXT_1 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ExpectedText1")
EXPECTED_TEXT_2 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ExpectedText2")
EXPECTED_TEXT_3 = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\ExpectedText3")

Main()

Set iframeElement = Nothing
Set IE = Nothing
Set doc = Nothing
Set shell = Nothing

' Main
' Navigates to the login page, performs login using credentials from the registry, accesses the iframe to retrieve session keys,
' checks for expected text at each navigation step, clicks through the workflow, verifies session consistency, and closes the browser.
Function Main()
	FindAndClickButton
	Refresh
	BypassSSLWarning
	LoginCredentials DEPARTMENT_CODE, CUSTOMER_CODE, PASSWORD
	InsertWolfSessionKey
	Refresh
	PageChecker "font", EXPECTED_TEXT_1
	ClickEvent "　　06　　"
	PageChecker "font", EXPECTED_TEXT_2
	ClickEvent "　　01　　"
	PageChecker "font", EXPECTED_TEXT_3
	ClickEvent "　　実行　　"
	SessionChecker
	BrowserClose
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

' LoginCredentials
' Waits for the login page to load, verifies the page header, fills in department, customer, and password fields, and clicks the login button.
' If the page or header is not as expected, sets an error message and closes the browser.
Function LoginCredentials(deptCode, custCode, password)
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
                If InStr(header(0).innerText, "≪LOGIN－Rich Client≫") > 0 Then
					doc.getElementsByName("aa_bcd")(0).Value = deptCode
                    doc.getElementsByName("aa_accd")(0).Value = custCode
					doc.getElementsByName("atcd")(0).Value = ReadResultCountFromLog()
					ClickEvent "　ログイン　"
                Else
                    errorMsg = "ログインページのヘッダーが見つかりません。"
                    CreateObject("WScript.Shell").Environment("User")("ERROR_MSG") = errorMsg
                    BrowserClose
                    WScript.Quit(1)
                End If

            Else
                errorMsg = "ページヘッダーが不正です。"
                CreateObject("WScript.Shell").Environment("User")("ERROR_MSG") = errorMsg
                BrowserClose
                WScript.Quit(1)
            End If
        Else
            errorMsg = "リクエストされたウェブページが見つかりませんでした。"
			CreateObject("WScript.Shell").Environment("User")("ERROR_MSG") = errorMsg
			BrowserClose
			WScript.Quit(1)
        End If
    End If
End Function

' FindAndClickButton
' Searches for an existing Internet Explorer window with the target URL, makes it visible and active, then clicks the login screen button.
' Times out after 30 seconds if no matching window is found.
Function FindAndClickButton() 
	Dim objShell, allWindows, startTime, foundWindow, timeoutSeconds, targetURL, window
	
	' Get target URL from registry
	targetURL = shell.RegRead("HKEY_CURRENT_USER\Software\UAT_HealthCheck_Automation\AuthPageURL")
	timeoutSeconds = 30 ' Set timeout to 30 seconds
	
	Set objShell = CreateObject("Shell.Application")
	Set allWindows = objShell.Windows()
	startTime = Timer()
	foundWindow = False
	
	' Search all windows for IE with matching URL
	Do While (Timer() - startTime) < timeoutSeconds And Not foundWindow
		For Each window in allWindows
			' Check if it's an IE window
			If InStr(1, window.FullName, "iexplore.exe", vbTextCompare) > 0 Then
				' Check if it has the URL you want
				If InStr(1, window.LocationURL, targetURL, vbTextCompare) > 0 Then
					window.Visible = True
					window.Document.parentWindow.focus()
					Set IE = window ' Use the existing IE window
					Set doc = IE.Document ' Set global doc variable
					IE.FullScreen = True
					foundWindow = True
					Exit For
				End If
			End If
		Next
		If Not foundWindow Then WScript.Sleep 500
	Loop
	' Wait a moment for the page to be ready
	WScript.Sleep 1000
	
	ClickEvent "　ログイン画面へ　"
End Function

' GetTrimmedValue
' Extracts and returns the substring before the first '=' character in the provided text string.
Function GetTrimmedValue(text)
    Dim eqPos
    eqPos = InStr(text, "=")
    If eqPos > 0 Then
        GetTrimmedValue = Left(text, eqPos - 1)
    Else
        GetTrimmedValue = text
    End If
End Function

' InsertWolfSessionKey
' Retrieves DOM session key via developer tools, populates session key form fields, and submits the admin login form.
Function InsertWolfSessionKey() 

	domText = GetDOMViaDevTool("Login")
	modifiedText = GetTrimmedValue(domText)

	doc.getElementsByName("wolfConcatSessionKey")(0).Value = domText
	doc.getElementsByName("wolfSessionKey")(0).Value = modifiedText
	
	IE.Document.parentWindow.execScript "document.adminLoginForm.target=''; document.adminLoginForm.action='menu/Menu.jsp'; document.adminLoginForm.submit();", "JavaScript"
End Function

' GetDOMViaDevTool
' Uses Internet Explorer developer tools to search for and extract DOM content based on screen name.
' Returns the clipboard content after copying the found DOM element.
Function GetDOMViaDevTool(screenName)

    Dim enterkeyCount, downkeyCount

    If screenName = "Login" Then
        enterkeyCount = 3
        downkeyCount = 1
    ElseIf screenName = "Complete" Then
        enterkeyCount = 1
        downkeyCount = 2
    End If

    PrepareDevToolFocus
    Call SendRepeatKey(shell, "{ESC}", 3, 500) 
    Call SendRepeatKey(shell, "^f", 3, 500)
    Call SendRepeatKey(shell, "{ENTER}", 1, 500)
    Call SendRepeatKey(shell, "^a", 1, 500)
    Call SendRepeatKey(shell, "{BACKSPACE}", 1, 700)
    Call SendSearchKeyword(shell, screenName)
    Call SendRepeatKey(shell, "{ENTER}", enterkeyCount, 500)
    Call SendRepeatKey(shell, "{TAB}", 3, 500)
    Call SendRepeatKey(shell, "{DOWN}", downkeyCount, 500)
    Call SendRepeatKey(shell, "{ENTER}", 1, 500)
    Call SendRepeatKey(shell, "^c", 1, 500)
    Call SendRepeatKey(shell, "{F12}", 1, 1200)
    GetDOMViaDevTool = GetClipboardHtmlText()
    Set shell = Nothing
    
End Function


' SessionChecker
' Validates session consistency by comparing original DOM text with current session output.
' Exits the script if session data doesn't match or is empty.
Function SessionChecker()
    
	Dim elements, element, outputSession

    Set elements = doc.getElementsByTagName("font")
    If Not elements Is Nothing And elements.Length > 0 Then
        For Each element In elements
            If Not element Is Nothing Then
                If InStr(element.innerText, "セッションが切れました。") > 0 Then
                    BrowserClose
                    WScript.Quit(3)
                End If
            End If
        Next
    End If

    outputSession = GetDOMViaDevTool("Complete")

    If domText <> outputSession or domText = "" Then
        BrowserClose
		WScript.Quit(3)
    End If

	IE.FullScreen = False
End Function

' PrepareDevToolFocus
' Activates Internet Explorer window and opens developer tools, then switches to the Elements tab.
Function PrepareDevToolFocus()

    Set shell = CreateObject("WScript.Shell")
    shell.AppActivate "Internet Explorer"
    WScript.Sleep 500

    shell.SendKeys "{F12}"
    WScript.Sleep 2000

    shell.SendKeys "^1"
    WScript.Sleep 2000

End Function

' GetClipboardHtmlText
' Retrieves text content from the Windows clipboard using an HTML file object.
Function GetClipboardHtmlText()

    Set htmlClip = CreateObject("htmlFile")
    GetClipboardHtmlText = htmlClip.ParentWindow.ClipboardData.GetData("Text")

End Function

' SendRepeatKey
' Sends a specified key or key combination repeatedly with delays between each press.
Function SendRepeatKey(shell, key, count, delay)
    Dim i
    For i = 1 To count
        shell.SendKeys key
        WScript.Sleep delay
    Next
End Function

' SendSearchKeyword
' Sends the search keyword for the specified screen name to the active window using SendKeys.
Function SendSearchKeyword(shell, screenName)
    Dim loginStr, completeStr, searchStr

    loginStr = "wolfsessionkey"
    completeStr = "wolfSessionKey"

    If screenName = "Login" Then
        searchStr = loginStr
    ElseIf screenName = "Complete" Then
        searchStr = completeStr
    End If

    Dim char
    For i = 1 To Len(searchStr)
        char = Mid(searchStr, i, 1)
        Call SendRepeatKey(shell, char, 1, 450)
    Next
    Set searchStr = Nothing
End Function

' ExtractCharacter
' Extracts and returns the substring before the first '==' in the provided session key string.
Function ExtractCharacter(data)
	Dim startPos
	startPos = InStr(data, "==")
	If startPos > 0 Then
		ExtractCharacter = Trim(Left(data, startPos - 1))
	Else
		ExtractCharacter = ""
	End If
End Function

' ReadResultCountFromLog
' Reads the log.txt file and extracts the value after "Result count is "
' Returns the extracted value or empty string if not found
Function ReadResultCountFromLog()
	Dim fso, logFile, line, resultValue, searchText
	Dim logFilePath
	
	' Set the path to the log.txt file (same directory as this script)
	logFilePath = Left(scriptPath, InStrRev(scriptPath, "\", Len(scriptPath) - 1)) & "bat\log.txt"
	searchText = "Result count is "
	resultValue = ""
	
	Set fso = CreateObject("Scripting.FileSystemObject")
	
	' Check if log file exists
	If fso.FileExists(logFilePath) Then
		Set logFile = fso.OpenTextFile(logFilePath, 1) ' 1 = ForReading
		
		' Read through each line in the file
		Do While Not logFile.AtEndOfStream
			line = logFile.ReadLine()
			
			' Check if the line contains "Result count is "
			If InStr(line, searchText) > 0 Then
				' Extract the value after "Result count is "
				resultValue = Trim(Mid(line, InStr(line, searchText) + Len(searchText)))
				Exit Do
			End If
		Loop
		
		logFile.Close
	End If
	
	Set logFile = Nothing
	Set fso = Nothing
	
	ReadResultCountFromLog = resultValue
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

' Refresh
' Waits in a loop until the Internet Explorer browser is no longer busy and the page is fully loaded (ReadyState = 4).
Function Refresh()
	Do While IE.ReadyState <> 4 Or IE.Busy
		WScript.Sleep 100
	Loop
End Function

' ErrorMessage
' Searches the provided HTML content for an error message, extracts the message text, sets it in the user environment variable,
' closes the browser, and exits the script with an error code.
Function ErrorMessage(content)
	Dim tempContent, firstCutStart, firstCutEnd, messageLength, errorStatrPos, errorMsg

	errorStatrPos = InStr(content, "errmsg")
	If errorStatrPos > 0 Then
		tempContent = Mid(content, errorStatrPos)
		firstCutStart = InStr(firstCutStart, tempContent, ">") + 1
			firstCutEnd = InStr(firstCutStart, tempContent, "<")
			If firstCutEnd > 0 Then
				messageLength = firstCutEnd - firstCutStart
				errorMsg = Mid(tempContent, firstCutStart, messageLength)
			End If
		CreateObject("WScript.Shell").Environment("User")("ERROR_MSG") = errorMsg
		BrowserClose
		WScript.Quit(1)
	End If
End Function

' PageChecker
' Checks all elements of the specified tag name for a match with the expected text.
' If the expected text is not found, closes the browser and exits with an error code.
Function PageChecker(tagName, expectedText)
	Dim elements, element
	Set elements = doc.getElementsByTagName(tagName)
	If Not elements(0) Is Nothing Then
		For Each element In elements
			If element.innerText = expectedText Then
				Exit Function
			End If
		Next
	End If

	BrowserClose
	WScript.Quit(2)
End Function

' BrowserClose
' Closes the Internet Explorer browser and releases the IE and doc objects to free resources.
Function BrowserClose()
	IE.Quit
	set IE = Nothing
	set doc = Nothing
End Function