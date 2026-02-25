@{
    Params = @(
        @{
            MacroPath =  "stopping_server.ttl"
            CheckString = "The checkString has been successfully matched."
            SucceedMsg = "Successfully executed command for Stopping AP server."
            FailedMsg = "Failed to execute Stopping AP server macro."
            SucceedMsg_Check_Log = "'JBossインスタンスは停止中です。' was displayed in the output."
            FailedMsg_Check_Log = "'JBossインスタンスは停止中です。' was not displayed in the output."
            FileName = "APサーバの停止"
            MailMessage = "JBossインスタンスは起動中です。"
            UseSJIS = $false
        },
        @{
            MacroPath =  "sql_execution.ttl"
            CheckString = "mpds_status is zero."
            SucceedMsg = "Successfully executed command for SQL execution."
            FailedMsg = "Failed to execute command for SQL execution."
            SucceedMsg_Check_Log = "'mpds_status is zero.'"
            FailedMsg_Check_Log = "mpds_status isn't zero."
            FileName = "MPDSステータスの初期化"
            MailMessage = "mpds_statusがゼロではございません。"
            UseSJIS = $true
        },
        @{
            MacroPath =  "starting_server.ttl"
            CheckString = "The checkString has been successfully matched."
            SucceedMsg = "Successfully executed command for Starting AP server."
            FailedMsg = "Failed to execute Starting AP server macro."
            SucceedMsg_Check_Log = "'JBossインスタンスは起動中です。' was displayed in the output."
            FailedMsg_Check_Log = "'JBossインスタンスは起動中です。' was not displayed in the output."
            FileName = "APサーバの起動"
            MailMessage = "JBossインスタンスは停止中です。"
            UseSJIS = $false
        }
    )
}