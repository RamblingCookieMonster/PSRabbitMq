@{
    # Set up a mini virtual environment...
    PSDependOptions = @{
        Target = 'C:\PSDeployBuild'
        AddToPath = $True
        Parameters = @{
            Force = $True
            Import = $True
        }
    }

    psdeploy = 'latest'
    buildhelpers = 'latest'
    pester = '4.10.1' 
    psake = 'latest'
}
