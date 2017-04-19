$EmailFrom = "from@email.com"
$EmailTo = "to@email.com"
$Subject = "Subject"
$Body = "body message"
$names = "Names.txt"
$logFile = "Log.txt"

$message = New-Object System.Net.Mail.MailMessage($EmailFrom, $EmailTo, $Subject, $Body)
$AttachmentFileNames = New-Object System.Net.Mail.Attachment($names, 'text/plain')
$AttachmentLogFile = New-Object System.Net.Mail.Attachment($logFile, 'text/plain')
$message.Attachments.Add($AttachmentFileNames)
$message.Attachments.Add($AttachmentLogFile)

$SMTPServer = "smtp.office365.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("from@email.com", "Backup123");
$SMTPClient.Send($message)