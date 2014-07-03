
Select-AzureSubscription 'KimberlyClarkNABIPOC';

$storageAccountName = "kcnabi"
$storageAccountKey = Get-AzureStorageKey $storageAccountName | %{ $_.Primary }
$containerName = "geotarget"

$context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey;


##attempt to delete any blobs that already exist
##pig job won't compile if blobs exist in the output blob space
try{
Get-AzureStorageBlob -Context $context -Container $containerName -Blob 'storelist/*' | ForEach-Object {Remove-AzureStorageBlob -Context $context -Blob $_.Name -Container $containerName -ErrorAction SilentlyContinue}
Remove-AzureStorageBlob -Context $context -Container $containerName -Blob 'storelist'-ErrorAction SilentlyContinue
}

catch{}

##set up the Pig Job for sumbission to the HDInsight Cluster

$PigScript = Get-Content C:\pig\StoreAttributes.pig -Raw
$HDIClusterName = 'kcnabi-poc'

$pigJobDefinition = New-AzureHDInsightPigJobDefinition -Query $PigScript 

Write-Host "Starting Pig job..." -ForegroundColor Green -BackgroundColor Black
$pigJob = Start-AzureHDInsightJob -Cluster $HDIClusterName -JobDefinition $pigJobDefinition 

Write-Host "Waiting for Pig job to complete..." -ForegroundColor Green -BackgroundColor Black
Wait-AzureHDInsightJob -job $pigJob -WaitTimeoutInSeconds 3600

Write-Host "Dipslaying error output..." -ForegroundColor Green -BackgroundColor Black
Get-AzureHDInsightJobOutput -Cluster $HDIClusterName -JobId $pigJob.JobId -StandardError

Write-Host "Displaying standard output..." -ForegroundColor Green -BackgroundColor Black
Get-AzureHDInsightJobOutput -Cluster $HDIClusterName -JobId $pigJob.JobId -StandardOutput



