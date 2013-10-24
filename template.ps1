<#
   Copyright 2013 Regan Daniel Laitila

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
#>

#SCRIPT
$script             = [hashtable] @{}
$script.arguments   = [array] $args #script arguments in a helpful array
$script.name        = [string] $myInvocation.MyCommand.Name #Gets the name of the script being invoked
$script.path        = [string] $myInvocation.MyCommand.Definition -replace $script.name, "" #obtains the script root path (Ex: C:\scripts\)
$script.startTime   = [DateTime] (Get-Date) #script start time

#LOGGING
$log            = [hashtable] @{}
$log.enabled    = [bool] $true #whether to actualy do any logging to file
$log.Path       = [string] "$($script.path)\" #root path to the log filename
$log.fileName   = [string] ($script.name -replace ".ps1",".log") #filename of the log, defaults to the scriptname with the extension replaced.
$log.output     = [bool] $True #Output to console
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function main
{
    #DO THINGS HERE
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function log([string]$pText)
{    
    $tmpTs = Get-Date
    if($log.enabled)
    {        
        if( !(Test-Path $log.path) ){ New-Item $log.path -type directory | Out-Null }        
        if( !($log.path -match "\\$") ){ $log.path += "\" }
        $logFile = $log.Path + $log.fileName        
        if(!(Test-Path $logFile)) 
        {
            #log file does not exist, lets create it.
            $tmpVar = New-Item $logFile -type file 
            Add-Content $logFile $tmpTs"|LOG : New Log File Created"            
        }
        Add-Content $logFile $tmpTs'|'$pText""
    }    
    if($log.output) { Write-Host $pText }    
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function halt([string]$pReason)
{
    log("$($script.name) Halted. Reason: $pReason")
    exit
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function RunAndWait([string] $command, [string] $arguments)
{
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo.FileName = $command
    $proc.StartInfo.Arguments = $arguments
    $proc.Start()
    $proc.WaitForExit()
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function Get-FileMd5Hash($filePath)
{
    $filePath
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($filePath)))
    return $hash
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function Unzip-File($pZipFile)
{
    $shell_app=new-object -com shell.application
    $filename = $pZipFile
    $zip_file = $shell_app.namespace((Get-Location).Path + "\$filename")
    $destination = $shell_app.namespace((Get-Location).Path)
    $destination.Copyhere($zip_file.items())
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function ConvertFrom-Json
{    
    <#
    .SYNOPSIS
    Converts a JSON string into a PowerShell hashtable using the .NET System.Web.Script.Serialization.JavaScriptSerializer
    .PARAMETER json
    The string of JSON to deserialize
    #>
    param(
    [string] $json
    )
    # load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $deserializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $dict = $deserializer.DeserializeObject($json)
    return $dict
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::: 
function ConvertTo-Json
{
    <#
    .SYNOPSIS
    Converts a PowerShell hashtable into a JSON string using the .NET System.Web.Script.Serialization.JavaScriptSerializer
    .PARAMETER dict
    The object to serialize into JSON.
    #>
    
    param(
    [Object] $dict
    )
    # load the required dll
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $serializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $json = $serializer.DeserializeObject($dict)
    return $json
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function Send-EmailMessage
{
    param
    (
        [array]$to,
        [string]$from,
        [string]$subject,
        [string]$message,
        [boolean]$smtpauth,
        [string]$smtpserver,
        [string]$smtpuser,
        [string]$smtppass        
    )
    
    $msg = New-Object Net.Mail.MailMessage    
    $to | ForEach-Object{
        $msg.To.Add($_)
    }    
    $msg.From = $from
    $msg.Subject = $subject
    $msg.Body = $message
    
    $smtp = new-object Net.Mail.SmtpClient($smtpserver)
    
    if( $smtpauth )
    {
        $networkCredential = new-object System.Net.networkCredential        
        $networkCredential.username = $smtpuser
        $networkCredential.password = $smtppass
        $smtp.Credentials = $networkCredential
    }
    
    $smtp.Send($msg)
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function Run-BatchCmd
{
    Param([string]$COMMAND)
    
    log("Invoking Command: $COMMAND")
    cmd /c $COMMAND
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
function Get-OSBitLevel
{
    if( [IntPtr]::size -eq 8 ){ return 64 }
    if( [IntPtr]::size -eq 4 ){ return 32 }
}
#::::::::::::::::::::::::::::::::::::::::::::::::::::
main