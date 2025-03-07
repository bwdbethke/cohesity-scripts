[CmdletBinding()]
param (
    [Parameter()][string]$vip='helios.cohesity.com',
    [Parameter()][string]$username='helios',
    [Parameter()][string]$startDate = '',
    [Parameter()][string]$endDate = '',
    [Parameter()][switch]$thisCalendarMonth,
    [Parameter()][switch]$lastCalendarMonth,
    [Parameter()][int]$days = 31,
    [Parameter()][array]$excludeString,
    [Parameter()][string]$excludeList
)

# gather list from command line params and file
function gatherList($Param=$null, $FilePath=$null, $Required=$True, $Name='items'){
    $items = @()
    if($Param){
        $Param | ForEach-Object {$items += $_}
    }
    if($FilePath){
        if(Test-Path -Path $FilePath -PathType Leaf){
            Get-Content $FilePath | ForEach-Object {$items += [string]$_}
        }else{
            Write-Host "Text file $FilePath not found!" -ForegroundColor Yellow
            exit
        }
    }
    if($Required -eq $True -and $items.Count -eq 0){
        Write-Host "No $Name specified" -ForegroundColor Yellow
        exit
    }
    return ($items | Sort-Object -Unique)
}

$excludeStrings = @(gatherList -Param $excludeString -FilePath $excludeList -Name 'excludeStrings' -Required $false)

$filePrefix = "heliosFailureReport"
$title = "Helios Failure Report"
$reportNumber = 900

$headings = "Cluster Name
Group Name
Source
Object
Environment
Policy
Last Failure
Failed Backups
Strikes
Last Error" -split "`n"

### source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

### authenticate
apiauth -vip $vip -username $username -domain 'local' -helios

### determine start and end dates
$today = Get-Date

if($startDate -ne '' -and $endDate -ne ''){
    $uStart = dateToUsecs $startDate
    $uEnd = dateToUsecs $endDate
}elseif ($thisCalendarMonth) {
    $uStart = dateToUsecs ($today.Date.AddDays(-($today.day-1)))
    $uEnd = dateToUsecs ($today)
}elseif ($lastCalendarMonth) {
    $uStart = dateToUsecs ($today.Date.AddDays(-($today.day-1)).AddMonths(-1))
    $uEnd = dateToUsecs ($today.Date.AddDays(-($today.day-1)).AddSeconds(-1))
}else{
    $uStart = timeAgo $days 'days'
    $uEnd = dateToUsecs ($today)
}

$start = (usecsToDate $uStart).ToString('yyyy-MM-dd')
$end = (usecsToDate $uEnd).ToString('yyyy-MM-dd')

# build 180 day time ranges
$ranges = @()
$gotAllRanges = $False
$thisUend = $uEnd
$thisUstart = $uStart
while($gotAllRanges -eq $False){
    if(($thisUend - $uStart) -gt 15552000000000){
        $thisUstart = $thisUend - 15552000000000
        $ranges = @($ranges + @{'start' = $thisUstart; 'end' = $thisUend})
        $thisUend = $thisUstart - 1
    }else{
        $ranges = @($ranges + @{'start' = $uStart; 'end' = $thisUend})
        $gotAllRanges = $True
    }
}

$dateString = (get-date).ToString('yyyy-MM-dd')

$csvHeadings = $headings -join ','
$tsvHeadings = $headings -join "`t"
$htmlHeadings = $htmlHeadings = ($headings | ForEach-Object {"<th>$_</th>"}) -join "`n"

# TSV output
$tsvFileName = "$($filePrefix)_$($start)_$($end).txt"
$tsvHeadings | Out-File -FilePath $tsvFileName

# CSV output
$csvFileName = "$($filePrefix)_$($start)_$($end).csv"
$csvHeadings | Out-File -FilePath $csvFileName

# HTML output
$htmlFileName = "$($filePrefix)_$($start)_$($end).html"

$trColors = @('#FFFFFF;', '#F1F1F1;')

$Global:html = '<html>
<head>
    <style>
        p {
            color: #555555;
            font-family:Arial, Helvetica, sans-serif;
        }
        span {
            color: #555555;
            font-family:Arial, Helvetica, sans-serif;
        }
        

        table {
            font-family: Arial, Helvetica, sans-serif;
            color: #333333;
            font-size: 0.75em;
            border-collapse: collapse;
            width: 100%;
        }

        tr {
            border: 1px solid #F8F8F8;
            background-color: #F8F8F8;
        }

        td {
            width: 25ch;
            max-width: 250px;
            text-align: left;
            padding: 10px;
            word-wrap:break-word;
            white-space:normal;
        }

        td.nowrap {
            width: 25ch;
            max-width: 250px;
            text-align: left;
            padding: 10px;
            padding-right: 15px;
            word-wrap:break-word;
            white-space:nowrap;
        }

        th {
            width: 25ch;
            max-width: 250px;
            text-align: left;
            padding: 6px;
            white-space: nowrap;
        }
    </style>
</head>
<body>
    
    <div style="margin:15px;">
            <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAALQAAAAaCAYAAAA
            e23asAAAACXBIWXMAABcRAAAXEQHKJvM/AAABmWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAA
            AAPD94cGFja2V0IGJlZ2luPSfvu78nIGlkPSdXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQnP
            z4KPHg6eG1wbWV0YSB4bWxuczp4PSdhZG9iZTpuczptZXRhLycgeDp4bXB0az0nSW1hZ2U6
            OkV4aWZUb29sIDExLjcwJz4KPHJkZjpSREYgeG1sbnM6cmRmPSdodHRwOi8vd3d3LnczLm9
            yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjJz4KCiA8cmRmOkRlc2NyaXB0aW9uIHJkZj
            phYm91dD0nJwogIHhtbG5zOnBob3Rvc2hvcD0naHR0cDovL25zLmFkb2JlLmNvbS9waG90b
            3Nob3AvMS4wLyc+CiAgPHBob3Rvc2hvcDpDb2xvck1vZGU+MzwvcGhvdG9zaG9wOkNvbG9y
            TW9kZT4KIDwvcmRmOkRlc2NyaXB0aW9uPgo8L3JkZjpSREY+CjwveDp4bXBtZXRhPgo8P3h
            wYWNrZXQgZW5kPSdyJz8+enmf4AAAAIB6VFh0UmF3IHByb2ZpbGUgdHlwZSBpcHRjAAB4nG
            WNMQqAMAxF95zCI7RJ/GlnJzcHb6AtCILi/QfbDnXwBz7h8eDTvKzTcD9XPs5EQwsCSVDWq
            LvTcj0S/ObYx/KOysbwSNDOEjsIMgJGE0RTi1TQVpAhdy3/tc8yqV5bq630An5xJATDlSTX
            AAAMJ0lEQVR42uWce5RVVR3HP/fOmWEYHJlQTC1AxJBViqiIj9QyEs1Kl5qSj3ysMovV09I
            SNTHNpJWZlWbmo8zUfIGImiQ+Mh0fmYDvIMWREOQ1As6MM2fu7Y/vb8/d58y9d865MyODfd
            c6i7nn7LN/+/Hbv/chQwxBEPg/twE+CRwKTARGAFsAGaAVWAY0ArOBh4ANAGEYUg4xGlsC+
            wCTgd2BDwN1QA5YCywGHgMeBF62+2VpBEGwPXC89QPwX+DmMAxbSIggCEYAXwQG260m4JYw
            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" style="width:180px">
        <p style="margin-top: 15px; margin-bottom: 15px;">
            <span style="font-size:1.3em;">'

$Global:html += $title
$Global:html += '</span>
<span style="font-size:1em; text-align: right; padding-right: 2px; float: right;">'
$Global:html += "$start to $end"

$Global:html += '</span>
</p>
<table>
<tr style="background-color: #F1F1F1;">'
$Global:html += $htmlHeadings
$Global:html += '</tr>'

$stats = @{}

Write-Host "Retrieving report data..."

foreach($range in $ranges){

    # report parameters
    $reportParams = @{
        "filters"  = @(
            @{
                "attribute"             = "date";
                "filterType"            = "TimeRange";
                "timeRangeFilterParams" = @{
                    "lowerBound" = $range.start;
                    "upperBound" = $range.end
                }
            }
        );
        "sort"     = $null;
        "timezone" = "America/New_York";
        "limit"    = @{
            "size" = 10000
        }
    }

    $preview = api post -reportingV2 "components/$reportNumber/preview" $reportParams

    $clusters = $preview.component.data.system | Sort-Object -Unique
    
    foreach($cluster in $clusters){
        foreach($i in $preview.component.data | Where-Object system -eq $cluster | Sort-Object -Property objectName){
            $clusterName = $i.system.ToUpper()
            $jobName = $i.groupName
            $sourceName = $i.sourceName
            $objectName = $i.objectName
            if($i.PSObject.Properties['environment'] -and $i.environment.length -gt 0){
                $environment = $i.environment.subString(1)
                $uniqueKey = "{0}:{1}:{2}:{3}" -f $clusterName, $sourceName, $objectName, $environment
                $policy = $i.policyName
                $lastFailure = (usecsToDate $i.lastFailedRunUsecs).ToSTring('yyyy-MM-dd hh:mm')
                $failedBackups = $i.failedBackups
                $strikes = $i.strikeCount
                $lastError = $i.lastFailedRunErrorMsg.replace("`n", "/").replace("`t", "/")
                if($lastError.length -gt 301){
                    $lastError = $lastError.subString(0,300)
                }
                if($uniqueKey -notin $stats.Keys){
                    $stats[$uniqueKey] = @{
                        'clusterName' = $clusterName;
                        'sourceName' = $sourceName;
                        'objectName' = $objectName;
                        'jobName' = $jobName;
                        'environment' = $environment;
                        'policy' = $policy;
                        'lastFailure' = $lastFailure;
                        'failedBackups' = $failedBackups;
                        'strikes' = $strikes;
                        'lastError' = $lastError
                    }
                }else{
                    $stats[$uniqueKey].failedBackups += $failedBackups
                }
            }
        }
    }
}

foreach($uniqueKey in $stats.Keys | Sort-Object){

    $clusterName = $stats[$uniqueKey].clusterName
    $sourceName = $stats[$uniqueKey].sourceName
    $objectName = $stats[$uniqueKey].objectName
    $jobName = $stats[$uniqueKey].jobName
    $environment = $stats[$uniqueKey].environment
    $policy = $stats[$uniqueKey].policy
    $lastFailure = $stats[$uniqueKey].lastFailure
    $failedBackups = $stats[$uniqueKey].failedBackups
    $strikes = $stats[$uniqueKey].strikes
    $lastError = $stats[$uniqueKey].lastError
    $includeItem = $True
    foreach($thisExcludeString in $excludeStrings){
        if($lastError -match $thisExcludeString){
            $includeItem = $false
        }
    }
    if($includeItem -eq $True){
        """{0}"",""{1}"",""{2}"",""{3}"",""{4}"",""{5}"",""{6}"",""{7}"",""{8}"",""{9}""" -f $clusterName, $jobName, $sourceName, $objectName, $environment, $policy, $lastFailure, $failedBackups, $strikes, $lastError | Out-File -FilePath $csvFileName -Append
        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}" -f $clusterName, $jobName, $sourceName, $objectName, $environment, $policy, $lastFailure, $failedBackups, $strikes, $lastError | Out-File -FilePath $tsvFileName -Append
        $Global:html += '<tr>
            <td class="nowrap">{0}</td>
            <td>{1}</td>
            <td>{2}</td>
            <td>{3}</td>
            <td>{4}</td>
            <td>{5}</td>
            <td class="nowrap">{6}</td>
            <td>{7}</td>
            <td>{8}</td>
            <td>{9}</td>
            </tr>' -f $clusterName, $jobName, $sourceName, $objectName, $environment, $policy, $lastFailure, $failedBackups, $strikes, $lastError
    }
}

$Global:html += "</table>                
</div>
</body>
</html>"

$Global:html | Out-File -FilePath $htmlFileName

Write-Host "`nOutput saved to`n    CSV: $csvFileName`n   HTML: $htmlFileName`n    TSV: $tsvFileName`n"
