#Get public and private function definition files.
    $Public  = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue 
    $Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue 

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname): $_"
        }
    }
    
#Create / Read config
    #handle PS2
    if(-not $PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }

    if(-not (Test-Path -Path "$PSScriptRoot\PSRabbitMq.xml" -ErrorAction SilentlyContinue))
    {
        Try
        {
            Write-Warning "Did not find config file $PSScriptRoot\PSRabbitMq.xml, attempting to create"
            [pscustomobject]@{
                ComputerName = $null
            } | Export-Clixml -Path "$PSScriptRoot\PSRabbitMq.xml" -Force -ErrorAction Stop
        }
        Catch
        {
            Write-Warning "Failed to create config file $PSScriptRoot\PSRabbitMq.xml: $_"
        }
    }
    
#Initialize the config variable.  I know, I know...
    Try
    {
        #Import the config
        $RabbitMqConfig = $null
        $RabbitMqConfig = Get-RabbitMqConfig -Source PSRabbitMq.xml -ErrorAction Stop | Select -Property ComputerName
    }
    Catch
    {   
        Write-Warning "Error importing PSRabbitMq config: $_"
    }

# Modules
Export-ModuleMember -Function $($Public | Select -ExpandProperty BaseName) -Alias *