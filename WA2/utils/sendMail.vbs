Dim bodyParameter
If WScript.Arguments.Count > 0 Then
    If WScript.Arguments(0) = "SUCCESS" Then
        Call successMail()
        WScript.Quit 0
    Else
        bodyParameter = WScript.Arguments(0) ' Get the first argument
        Call SendMail(bodyParameter)
    End If
Else
    WScript.Quit 1
End If

Function ReadConfigValue(section, key, filePath)
    Dim objFSO, objFile, objRegExp, matches, line, result
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set objFile = objFSO.OpenTextFile(filePath, 1)
    Set objRegExp = New RegExp
    objRegExp.IgnoreCase = True
    objRegExp.Global = False
    objRegExp.Pattern = "^\[" & section & "\]$"
    result = ""
    Do Until objFile.AtEndOfStream
        line = Trim(objFile.ReadLine)
        If objRegExp.Test(line) Then
            Do Until objFile.AtEndOfStream
                line = Trim(objFile.ReadLine)
                If Left(line, 1) = "[" Then Exit Do
                If InStr(1, line, key & "=", vbTextCompare) = 1 Then
                    result = Mid(line, Len(key) + 2)
                    Exit Do
                End If
            Loop
            Exit Do
        End If
    Loop
    objFile.Close
    Set objFile = Nothing
    Set objFSO = Nothing
    Set objRegExp = Nothing
    ReadConfigValue = result
End Function

Function SendMail(bodyParameter)
    On Error Resume Next ' Handle errors gracefully
    
    ' Ensure Outlook is running
    Dim wmi, processList, outlookRunning, shell, waitTime
    outlookRunning = False
    Set wmi = GetObject("winmgmts:\\.\root\cimv2")
    Set processList = wmi.ExecQuery("Select * from Win32_Process where Name = 'OUTLOOK.EXE'")
    If processList.Count > 0 Then
        outlookRunning = True
    End If
    If Not outlookRunning Then
        Set shell = CreateObject("WScript.Shell")
        shell.Run "outlook.exe", 1, False
        waitTime = 0
        ' Wait up to 15 seconds for Outlook to start
        Do While waitTime < 15
            Set processList = wmi.ExecQuery("Select * from Win32_Process where Name = 'OUTLOOK.EXE'")
            If processList.Count > 0 Then Exit Do
            WScript.Sleep 1000
            waitTime = waitTime + 1
        Loop
        Set shell = Nothing
    End If
    Set wmi = Nothing
    Set processList = Nothing

    ' Read email settings from config.ini
    Dim objFSO, objScriptFile, configPath, toAddress, subjectText, ccAddress, bccAddress
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set objScriptFile = objFSO.GetFile(WScript.ScriptFullName)
    configPath = objFSO.GetParentFolderName(objScriptFile) & "\mail_config.ini"
    Set objScriptFile = Nothing
    Set objFSO = Nothing

    toAddress = ReadConfigValue("EmailSettings", "ToAddress", configPath)
    subjectText = ReadConfigValue("EmailSettings", "Subject", configPath)
    ccAddress = ReadConfigValue("EmailSettings", "CC", configPath)
    bccAddress = ReadConfigValue("EmailSettings", "BCC", configPath)

    ' Create Outlook application and mail item
    Set Outlook = CreateObject("Outlook.Application")
    Set Mail = Outlook.CreateItem(0)
    Set ns = Outlook.GetNamespace("MAPI")
    Set recip = ns.CreateRecipient(toAddress)
    recip.Resolve

    Dim firstName 
    fistName = recip.Name
    firstName = Split(fistName, "/")(0)
    firstName = Split(firstName, " ")(0)
    firstName = firstName & " 様"

    ' Retrieve LOG_FILE_PATH from user environment
    Dim logFilePath
    logFilePath = CreateObject("WScript.Shell").Environment("Process")("LOG_FILE_PATH")
    If logFilePath = "" Then
        logFilePath = CreateObject("WScript.Shell").Environment("User")("LOG_FILE_PATH")
    End If

    ' Configure the email
    With Mail
        .To = toAddress
        If ccAddress <> "" Then .CC = ccAddress
        If bccAddress <> "" Then .BCC = bccAddress
        .Subject = subjectText
        .HTMLBody = "<html><body style='font-size:14px;'>" & _
                    "<span>" & firstName & "</span><br><br>" & _
                    "このメールは、作業の自動化_UATヘルスチェック プロセス中にエラーが発生したため自動送信されています。<br><br>" & _
                    "作業の自動化_UATヘルスチェック の処理中に、以下のエラーメッセージが発生いたしました。<br>" & _
                    "<br>--------------------------------------------------------------------------------------<br><br>" & _
                    "<span>" & bodyParameter & "</span>" & _
                    "<br>--------------------------------------------------------------------------------------<br><br>" & _
                    "ご確認のほど、よろしくお願い申し上げます。<br>" & _
                    "平素より格別のご支援、ご協力を賜り、誠にありがとうございます。" & _
                    "</body></html>"
        .Send
    End With

    ' Error logging if send fails
    If Err.Number <> 0 Then
        Dim fso, logFile, logPath
        logPath = objFSO.GetParentFolderName(WScript.ScriptFullName) & "\log\mail_error.log"
        Set fso = CreateObject("Scripting.FileSystemObject")
        Set logFile = fso.OpenTextFile(logPath, 8, True)
        logFile.WriteLine Now & ": Error " & Err.Number & " - " & Err.Description
        logFile.Close
        Set logFile = Nothing
        Set fso = Nothing
    End If

    ' Clean up objects
    Set Mail = Nothing
    Set Outlook = Nothing
    Set ns = Nothing
    Set recip = Nothing

    On Error GoTo 0 ' Reset error handling
End Function

Function successMail()
    '*************************************************************
    '* メールテンプレート
    '*************************************************************
    '*************************************
    '* 変数宣言
    '*************************************
    Dim outlook, item, mailBody, mailSubject, timeZone, mailTo, kaigyo

    '*************************************
    '* アドレス
    '*************************************
    ' 送信先：TO
    mailTo = "ls_plate_wb3@dir.co.jp;"

    '*************************************
    '* 初期処理
    '*************************************
    Set outlook = CreateObject("Outlook.Application")
    Set item = outlook.CreateItem(0)

    ' 改行コード
    kaigyo = vbCrLf

    '*************************************
    '* 時刻を取得する
    '*************************************
    timeZone = Right("0" & Hour(Now) - 1, 2)  & ":01-" & Right("0" & Hour(Now), 2) & ":00"

    '*************************************
    '* メール件名
    '* 以下の例では日時等も加工している.
    '*************************************
    mailSubject = "【SBNT】【RICH】ヘルスチェック結果" 
    mailSubject = mailSubject & "(" & Right("0" & Month(Date), 2) & Right("0" & Day(Date), 2) & ")"

    '*************************************
    '* メール本文
    '*************************************
    mailBody = "各位" & kaigyo
    mailBody = mailBody & "" & kaigyo
    mailBody = mailBody & "本日の掲題の注文確認が完了しましたのでご連絡します。" & kaigyo
    mailBody = mailBody & "" & kaigyo
    mailBody = mailBody & "以上" & kaigyo
    mailBody = mailBody & "" & kaigyo

    '*************************************
    '* メール内の設定
    '*************************************
    item.To = mailTo
    item.Subject = mailSubject
    item.Body = mailBody
    item.Send
    
    ' Add error handling like in SendMail function
    If Err.Number <> 0 Then
        Dim fso, logFile, logPath, objFSO
        Set objFSO = CreateObject("Scripting.FileSystemObject")
        logPath = objFSO.GetParentFolderName(WScript.ScriptFullName) & "\log\mail_error.log"
        Set fso = CreateObject("Scripting.FileSystemObject")
        Set logFile = fso.OpenTextFile(logPath, 8, True)
        logFile.WriteLine Now & ": Error " & Err.Number & " - " & Err.Description
        logFile.Close
        Set logFile = Nothing
        Set fso = Nothing
        Set objFSO = Nothing
    End If
    '*************************************
    '* 終了処理
    '*************************************
    Set item = Nothing
    Set outlook = Nothing
    
End Function