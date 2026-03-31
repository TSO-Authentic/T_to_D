@{
    Params = @(
        @{
            MacroPath = "wb_server_check.ttl"
            FileName = "PR起動確認（株）"
            CheckString = "The checkString has been successfully matched."
            SucceedMsg = "JBossインスタンスは起動中です。"
            FailedMessage = "'JBossインスタンスは起動中です。' was not displayed in the output."
            MailMessage = "JBossインスタンスは停止中です。"
            UseSJIS = $false
        },
        @{
            MacroPath = "rch_server_check.ttl"
            FileName = "PR起動確認（リッチ）"
            CheckString = "The checkString has been successfully matched."
            SucceedMsg = "JBossインスタンスは起動中です。"
            FailedMessage = "'JBossインスタンスは起動中です。' was not displayed in the output."
            MailMessage = "JBossインスタンスは停止中です。"
            UseSJIS = $false
        },
        @{
            MacroPath = "rule_engine_check.ttl"
            FileName = "ルールエンジン起動確認（株）"
            CheckString = "Rule Engine is already running."
            SucceedMsg = "Rule Engine is already running."
            FailedMessage = "Rule Engine is stopped."
            MailMessage = "Rule Engine is stopped."
            UseSJIS = $false
        },
        @{
            MacroPath = "ap_server_check.ttl"
            FileName = "AP起動確認（株）"
            CheckString = "The checkString has been successfully matched."
            SucceedMsg = "JBossインスタンスは起動中です。"
            FailedMessage = "'JBossインスタンスは起動中です。' was not displayed in the output."
            MailMessage = "JBossインスタンスは停止中です。"
            UseSJIS = $false
        },
        @{
            MacroPath = "tool_check.ttl"
            FileName = "約定ツール起動確認（株）"
            CheckString = "JST Process is running."
            SucceedMsg = "JST Process is running."
            FailedMessage = "JST Process is stopped."
            MailMessage = "JST Process is stopped."
            UseSJIS = $false
        },
        @{
            MacroPath = "rich_push_check.ttl"
            FileName = "リッチプッシュ起動確認（株）"
            CheckString = "Rich Push is running."
            SucceedMsg = "Rich Push is running."
            FailedMessage = "Rich Push is stopped."
            MailMessage = "Rich Push is stopped."
            UseSJIS = $false
        },
        @{
            MacroPath = "date_check.ttl"
            FileName = "日付確認（株）"
            CheckString = "20241007"
            SucceedMsg = ""
            FailedMessage = "The return date is {value}. The expected date is : {CheckString}."
            MailMessage = "返却日が正しくございません。期待される日付は: 「{CheckString}」でございます。"
            UseSJIS = $true
        }
    )
}