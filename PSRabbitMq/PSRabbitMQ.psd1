@{
# Script module or binary module file associated with this manifest
ModuleToProcess = 'PSRabbitMQ.psm1'

# Version number of this module.
ModuleVersion = '0.3.0'

# ID used to uniquely identify this module
GUID = '41d4d893-5070-44f2-9cf7-9d80020603b1'

# Author of this module
Author = 'CD, Warren Frame'

# Company or vendor of this module
# CompanyName = ''

# Description of the functionality provided by this module
Description = 'Send and receive messages using a RabbitMQ server'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = '3'
# The administration functions require v3, not the messaging functions

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64, IA64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('lib\RabbitMQ.Client.dll')

# Script files (.ps1) that are run in the caller's environment prior to importing this module
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
# CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in ModuleToProcess
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
         Tags = @('PSModule', 'Rabbit', 'RabbitMQ', 'Message', 'Messaging', 'Queue', 'AMQP' )

        # A URL to the license for this module.
         LicenseUri = 'https://github.com/RamblingCookieMonster/PSRabbitMq/blob/master/LICENSE'

        # A URL to the main website for this project.
         ProjectUri = 'https://github.com/RamblingCookieMonster/PSRabbitMq'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        #ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# The default noun prefix to add to all exported functions.
# DefaultCommandPrefix = ''

}