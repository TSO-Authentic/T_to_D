@{
    Params = @(
        @{
            MacroPath = "eqtype_order_unit.ttl"
            FileName = "オープン状態の注文件数確認（株）"
            CheckString = "0"
            FailedMessage = "The return result count is {value}. The expected count is : {CheckString}."
            MailMessage = "返却結果の件数が正しくございません。期待される件数は: 「{CheckString}」 でございます。"
            UseSJIS = $true
        },
        @{
            MacroPath = "gen_rich_push_history.ttl"
            FileName = "GEN_RICH_PUSH_HISTORYエラー件数確認（株）"
            CheckString = "0"
            FailedMessage = "The return result count is {value}. The expected count is : {CheckString}."
            MailMessage = "返却結果の件数が正しくございません。期待される件数は: 「{CheckString}」 でございます。"
            UseSJIS = $true
        },
        @{
            MacroPath = "rich_push_history.ttl"
            FileName = " RICH_PUSH_HISTORYエラー件数確認（株） "
            CheckString = "0"
            FailedMessage = "The return result count is {value}. The expected count is : {CheckString}."
            MailMessage = "返却結果の件数が正しくございません。期待される件数は: 「{CheckString}」 でございます。"
            UseSJIS = $true
        }
    )
}