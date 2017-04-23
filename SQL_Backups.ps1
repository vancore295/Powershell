
#### Globals
$AllDatabaseNames = @()

### Configure Settings

$subscriptionId = "subscriptionId"

$container_download = "mam"
$container_keep = "websitebackups"

$azureAccountName = "name@company.com"
$azurePassword = ConvertTo-SecureString "Hello123!" -AsPlainText -Force

$delayTimeTillDownloads = 600

### Parameters
$destination_path = "C:\TestSQLBackups"
####### Login worker account
$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)

Login-AzureRmAccount -Credential $psCred
Set-AzureRmContext -SubscriptionId $subscriptionId

Get-AzureSqlDatabaseServer

####### Databse Server connection data
$SqlQuery = 
"SELECT name, database_id, create_date
FROM sys.databases
GO"

####### Connect to the Database server
function ConnectionToDataBase([string]$ServerName, [string]$UserId, [string]$Password) {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $ServerName; Integrated Security = False; User ID = $UserId; Password = $Password;"

    return $SqlConnection
}

####### Get names of the all databases on the server
function GetDatabaseNames($Server, $Query) {
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $Query
    $SqlCmd.Connection = $Server
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $Query
    $DataSet = New-Object System.Data.DataSet

    $Server.Open()
    $reader = $SqlCmd.ExecuteReader()
    $results = @()

    while ($reader.Read()) {
        $row = @{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {

            $row[$reader.GetName($i)] = $reader.GetValue($i)
            
            
        }
        $results += new-object psobject -property $row
    }

    $Server.Close();

    return $results
}

####### Generate a unique filename for the BACPAC
function CreateBackPacFileName([string]$DBName) {    
    if ($DBName -eq "master") {
        continue
    }
    $bacpacFilename = $DBName + "_Saved_" + (Get-Date).ToString("yyyy_MM_dd_HH_mm_ss") + ".bacpac"

    return $bacpacFilename
}

### RequestServerBackUp $DatabaseName $ResourceGroupName $ServerName $serverAdmin $serverPassword
### Load Backups
function RequestServerBackUp([string]$DatabaseName, [string]$ResourceGroupName, [string]$ServerName, [string]$serverAdmin, [string]$serverPassword, [string]$targetContainer, [string]$bacpacFilename) {
    $securePassword = ConvertTo-SecureString -String $serverPassword -AsPlainText -Force
    $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $serverAdmin, $securePassword

    # Generate a unique filename for the BACPAC
    #$bacpacFilename = $DatabaseName + "Saved" + (Get-Date).ToString("yyyyMMddHHmmss") + ".bacpac"

    ####### Storage account info for the BACPAC
    $BaseStorageUri = "https://blob.blob.core.windows.net/$targetContainer/"
    $BacpacUri = $BaseStorageUri + $bacpacFilename
    $StorageKeytype = "StorageAccessKey"
    $StorageKey = "storagekey"

    ####### Export to Download to Syntactx and Delete
    $exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $ResourceGroupName -ServerName $ServerName `
	   -DatabaseName $DatabaseName -StorageKeytype $StorageKeytype -StorageKey $StorageKey -StorageUri $BacpacUri `
	   -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password
    $exportRequest
}

function BackupDBServer([string]$SQLServer, [string]$uid, [string]$pwd, [string]$ResourceGroupName, [string]$ServerName, [string]$ServerAdmin, [string]$ServerPassword, [string]$container_keep) {
    $SQLServer = $SQLServer + ".database.windows.net"
    $Server = ConnectionToDataBase $SQLServer $uid $pwd
    $Server
    $DatabaseNames = GetDatabaseNames $Server $SqlQuery

    foreach ($DatabaseName in $DatabaseNames) {
        $fileName = CreateBackPacFileName $DatabaseName.name

        $global:AllDatabaseNames += @($fileName) 

        RequestServerBackUp $DatabaseName.name $ResourceGroupName $ServerName $ServerAdmin $ServerPassword $container_keep $fileName
    }
}

$Servers = @(
    [pscustomobject]@{ResourceGroupName = "Default-SQL-EastUS"; ServerName = "servername"; ServerAdmin = "serveradmin@example"; ServerPassword = "password"}
    [pscustomobject]@{ResourceGroupName = "Default-SQL-EastUS"; ServerName = "servername"; ServerAdmin = "serveradmin@example"; ServerPassword = "password"}
    [pscustomobject]@{ResourceGroupName = "Default-SQL-WestUS"; ServerName = "servername"; ServerAdmin = "serveradmin@example"; ServerPassword = "password"}
)
foreach($Server in $Servers)
{
    BackupDBServer $Server.ServerName $Server.ServerAdmin $Server.ServerPassword $Server.ResourceGroupName $Server.ServerName $Server.ServerAdmin $Server.ServerPassword $container_keep
}


$global:AllDatabaseNames | Out-File "C:\SQl_Backups\BackupNames.txt"


$global:AllDatabaseNames

Write-Host (Get-Date).ToString("HHmmss")

$dealy = "delay start time"
$dealy
Start-Sleep -s $delayTimeTillDownloads 
$sleepOver = "sleep over"
Write-Host (Get-Date).ToString("HHmmss")
$sleepOver
#### Download 

#$destination_path = 'C:\Users\dalperovich\Desktop\downLoadTest'
$destination_path = 'C:\SQl_Backups'
$connection_string = 'conectionstring'

$storage_account = New-AzureStorageContext -ConnectionString $connection_string

#$blobs = Get-AzureStorageBlob -Container $container_keep -Context $storage_account

foreach ($db in $global:AllDatabaseNames) {
    New-Item -ItemType Directory -Force -Path $destination_path

    Get-AzureStorageBlobContent `
        -Container $container_keep -Blob $db -Destination $destination_path `
        -Context $storage_account -Force

    #Remove-AzureStorageBlob -Blob $db -Container $container_download -Context $storage_account
    #Get-AzureStorageBlob -Blob $db -Container $container_download -Context $storage_account
}
