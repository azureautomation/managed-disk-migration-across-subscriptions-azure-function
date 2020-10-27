Function New-ManagedDiskMigration {
    <#
        .SYNOPSIS
        Function "New-ManagedDiskMigration" can be used to create managed disks based on an Azure Virtual Machine backed by managed disks.
        
        .DESCRIPTION   
        This function will create managed disks from an Azure Virtual Machine that's backed by managed disks.
        The source/atached managed disks will not be removed. This function should only be used to create new managed disks based on virtual machines using managed disks
        with the goal of moving or migrating the managed disks attached to a virtual machine to another resource group in the same or different subscription.
        All criteria of the managed disks will be retained, such as:
            -The operating system type (osdisk).
            -The location/region of the managed disk will be the same as the original managed disk location.
            -The SKU is retained from the SKU of the original/source managed disk.
            -The Size of the managed disk will be based on predefined ranges. (e.g. if the original disk size was 100Gb, the new managed disk size will default to 128GB).
            -Newly created managed disks from managed Osdisks naming will adopt a naming convention of: "VmName-osdisk"
            -Newly created managed disks from managed Datadisks naming will adopt a naming convention of: "VmName-datadisk01", "VmName-datadisk02", "VmName-datadisk03" etc...
        Important functional notes for conversion from managed to managed disks across different subscriptions (Also see function examples):
            -If the target subscription parameter is used, but the target subscription does not exist, the function will not continue and throw an error.
            -If the target subscription parameter is used along with the target resource group parameter but the target resource group does not exist, 
             the function will create a new resource group in the target subscription with the value of the target resource group parameter.
            -If only the target subscription parameter is used but NO target resource group parameter was provided, the function will create a new resource group
             in the target subscription with the same value of the source resource group parameter.
        
        .EXAMPLE
        New-ManagedDiskMigration -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName testvm1 -Verbose
                
        All managed disks attached on the VM specified (osdisk and/or datadisks) are migrated to new managed disks in the same resource group as that of the Vm.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.
        
        .EXAMPLE
        New-ManagedDiskMigration -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName testvm1 -TargetResourceGroupName newresourcegroup
                
        All managed disks attached on the VM specified (osdisk and/or datadisks) are migrated to new managed disks and placed in the specified target resource group within the same Subscription.
        If the optional parameter (-TargetResourceGroupName) in this example does not contain a valid target resource group, the function will create a new resource group with the name of the provided
        value for the target resource group and the disks will be created inside of the newly created resource group.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.

        .EXAMPLE
        New-ManagedDiskMigration -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName testvm1 -TargetSubscriptionId yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy -TargetResourceGroupName newrginnewsub -Verbose
                
        All managed disks attached on the VM specified (osdisk and/or datadisks) are migrated to new managed disks and placed in the specified target resource group within the specified target Subscription.
        If the target subscription parameter is used, but the target subscription does not exist, the function will not continue and throw an error.
        If the target subscription parameter is used along with the target resource group parameter but the target resource group does not exist, the function will create a new resource group in the 
        target subscription with the value of the parameter provided for the target resource group and the disks will be created inside of the newly created resource group in the target subscription.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.
        
        .EXAMPLE
        New-ManagedDiskMigration -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx -ResourceGroupName westeuvms -VmName testvm1 -TargetSubscriptionId yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy -Verbose
                
        All managed disks attached on the VM specified (osdisk and/or datadisks) are migrated to new managed disks and placed in a Target Resource Group named the same as the source resource group within the specified target Subscription.
        If the target subscription parameter is used, but the target subscription does not exist, the function will not continue and throw an error.
        If only the target subscription parameter is used but NO target resource group parameter was provided, the function will create a new resource group in the target subscription with the value of the source resource group.
        The Os Managed Disk is created in the standard format of "VmName-osdisk" and each Managed Data Disk (if any), will be named in the format "VmName-datadisk01", "VmName-datadisk02" etc.
        
        .EXAMPLE
        $SubId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        $RG = "MyEastUsVms"
        $NewRG = "MyManagedDisks"
        $Vms = "testvm1", "testvm2", "testvm3"
        Foreach ($Vm in $Vms) {
            New-ManagedDiskMigration -SubscriptionId $SubId -ResourceGroupName $RG -VmName $Vm -TargetResourceGroupName $NewRG
        }
     
        If any Vms in the array of Vms contain managed disks, copies of the managed disks will be created in the target resource group specified: "MyManagedDisks"
        
        .PARAMETER SubscriptionId
        Mandatory Parameter.
        Specify the SubscriptionId containing the source Resource Group and Virtual Machines with managed disk backed storage. <String>
    
        .PARAMETER ResourceGroupName
        Mandatory Parameter.
        Specify the source Resource Group containing the Virtual Machines with managed disk backed storage. <String>
    
        .PARAMETER VmName
        Mandatory Parameter.
        Specify the Virtual Machine names that uses managed disks. <String>

        .PARAMETER TargetSubscriptionId
        Optional Parameter.
        Specify the target Subscription ID where the new managed disks will be created. If this parameter is not specified, the source Subscription ID will be used. <String>
                
        .PARAMETER TargetResourceGroupName
        Optional Parameter.
        Specify the target Resource Group where the new managed disks will be created. If this parameter is not specified, the source Resource Group will be used. <String>
                
        .NOTES
        Author: Paperclips (Pwd9000@hotmail.co.uk)
        PSVersion: 5.1
        Date Created: 06/02/2019
        Updated: 
        Verbose output is displayed using verbose parameter. (-Verbose)
    #>
        
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$SubscriptionId,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$ResourceGroupName,
        
        [Parameter(Mandatory, ValueFromPipeline)]
        [String]$VmName,

        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [String]$TargetSubscriptionId = $SubscriptionId,
        
        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [String]$TargetResourceGroupName = $ResourceGroupName
    )
    
    #Test source subscription and set context.
    If (Get-AzureRmSubscription -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue) {
        $null = Set-AzureRmContext -Subscription $SubscriptionId
    }
    Else {
        Throw "The provided Subscription ID: [$SubscriptionId] could not be found or does not exist. Please provide a valid source Subscription ID."
    }

    #If target subscription provided, test target subscription. (if no target subscription is provided the target subscription will be set the same as the source subscription - See function parameters).
    If ($TargetSubscriptionId) {
        If (-not (Get-AzureRmSubscription -SubscriptionId $TargetSubscriptionId -ErrorAction SilentlyContinue)) {
            Throw "The provided target Subscription ID: [$TargetSubscriptionId] could not be found or does not exist. Please provide a valid target Subscription ID."
        }
    }

    #Test source resource group.
    If (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue) {

        #Test Vm and get Vm object and managed disks.
        If (Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName -ErrorAction SilentlyContinue) {
            $vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName
            $manOsDisk = Split-Path ($vm.StorageProfile.OsDisk.ManagedDisk.Id) -Leaf
            $dataDisks = $vm.StorageProfile.datadisks.name

            #Test if datadisk is managed or unmanaged, unmanaged will error, however valid managed data disks will be added to array if any.
            $mandataDisks = @()
            Foreach ($dataDisk in $dataDisks) {
                $mandataDisks += (Get-AzureRMDisk -ResourceGroupName $ResourceGroupName -DiskName $dataDisk -ErrorAction SilentlyContinue).Name
            }
        }
        Else {
            Throw "The provided Virtual Machine:[$VmName] could not be found or does not exist. Please provide a valid Virtual Machine."
        }
    }
    Else {
        Throw "The provided resource group:[$ResourceGroupName] could not be found or does not exist. Please provide a valid resource group."
    }

    #Get OS disk (VHD) object details and new disk params.
    If ($manOsDisk) {
        $manOsDiskObj = Get-AzureRMDisk -ResourceGroupName $ResourceGroupName -DiskName $manOsDisk
        $manOsSize = $manOsDiskObj.DiskSizeGB
        $manOsNewDiskName = ($vm.Name) + "-osdisk"
        
        #Resizing logic for new OS disk (Managed).
        $sizeRanges = (1..32) , (33..64) , (65..128) , (129..256) , (257..512) , (513..1024) , (1025..2048)
        Foreach ($sizeRange in $sizeRanges) { 
            If ($manOsSize -in $sizeRange) { 
                $newManOsSize = $sizeRange[-1]
            }    
        }

        #Source and target subscriptions the same.
        If ($SubscriptionId -match $TargetSubscriptionId) {

            #If supplied target resource group not found or not provided, create new resource group.
            If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                Write-Warning "The target resource group:[$TargetResourceGroupName] was not found. A new resource group:[$TargetResourceGroupName] will be created to store new managed disks."
                $null = New-AzureRmResourceGroup -Name $TargetResourceGroupName -Location $manOsDiskObj.Location
            }
            Write-Verbose "Creating Managed Os Disk:[$manOsNewDiskName] from managed os disk:[$manOsDisk]"
            Write-Verbose "Managed disk can be found in resource group:[$TargetResourceGroupName]"
            $osDiskConfig = New-AzureRmDiskConfig -SourceResourceId $manOsDiskObj.Id -OsType $manOsDiskObj.OsType -Location $manOsDiskObj.Location -SkuName $manOsDiskObj.sku.name -DiskSizeGB $newManOsSize -CreateOption Copy 
            $null = New-AzureRmDisk -Disk $osDiskConfig -ResourceGroupName $TargetResourceGroupName -DiskName $manOsNewDiskName    
        }

        #Source and target subscriptions do not match (Cross-subscription).
        Else {
            #Switch to target subscription (Test target subscription performed at beginning of function)
            $null = Set-AzureRmContext -Subscription $TargetSubscriptionId

            #Test target resource group in target subscription.
            #If no target resource group was provided a new resource group will be created in the target subscription with the same name as the source resource group (See function params).
            #Or if a target resource group was provided, but do not exist in the target subscription a new resource group will be created and named as per the provided target resource group parameter.
            If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                Write-Warning "The target resource group:[$TargetResourceGroupName] was not found in the target subscription. A new resource group:[$TargetResourceGroupName] will be created to store new managed disks."
                $null = New-AzureRmResourceGroup -Name $TargetResourceGroupName -Location $manOsDiskObj.Location
            }
            #Create new (copy) disk from source managed disk to target subscription and resource group.
            Write-Verbose "Creating Managed Os Disk:[$manOsNewDiskName] from managed os disk:[$manOsDisk]"
            Write-Verbose "Managed disk can be found in resource group:[$TargetResourceGroupName]"
            $osDiskConfig = New-AzureRmDiskConfig -SourceResourceId $manOsDiskObj.Id -OsType $manOsDiskObj.OsType -Location $manOsDiskObj.Location -SkuName $manOsDiskObj.sku.name -DiskSizeGB $newManOsSize -CreateOption Copy
            $null = New-AzureRmDisk -Disk $osDiskConfig -ResourceGroupName $TargetResourceGroupName -DiskName $manOsNewDiskName 

            #Switch back to the source subscription context.
            $null = Set-AzureRmContext -Subscription $SubscriptionId
        }
    }
        
    #Get data disks objects detail and new disks params.
    If ($mandataDisks) { 
        $dataDiskConfigs = @()
        Foreach ($i in 0..($mandataDisks.count - 1)) {
            $manDataDiskObj = Get-AzureRMDisk -ResourceGroupName $ResourceGroupName -DiskName $mandataDisks[$i]
            $manDataSize = $manDataDiskObj.DiskSizeGB
            $manDataNewDiskName = ($vm.Name) + "-datadisk0" + ($i + 1)
            
            $sizeRanges = (1..32) , (33..64) , (65..128) , (129..256) , (257..512) , (513..1024) , (1025..2048)
            Foreach ($sizeRange in $sizeRanges) { 
                If ($manDataSize -in $sizeRange) { 
                    $newDataDiskSize = $sizeRange[-1]
                }    
            }
            $dataDiskConfigs += [pscustomobject]@{ID = $manDataDiskObj.Id; SourceName = $mandataDisks[$i]; Location = $manDataDiskObj.Location; Sku = $manDataDiskObj.Sku.Name; Size = $newDataDiskSize; DiskName = $manDataNewDiskName} 
        }

        Foreach ($dataDiskConfig in $dataDiskConfigs) {
            If ($SubscriptionId -match $TargetSubscriptionId) {
                #If supplied target resource group not found or not provided, create new resource group.
                If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Warning "The target resource group:[$TargetResourceGroupName] was not found. A new resource group:[$TargetResourceGroupName] will be created to store new managed disks."
                    $null = New-AzureRmResourceGroup -Name $TargetResourceGroupName -Location $dataDiskConfig.Location
                }
                Write-Verbose "Creating Managed Data Disk:[$($dataDiskConfig.DiskName)] from managed data disk:[$($dataDiskConfig.SourceName)]"
                Write-Verbose "Managed disk can be found in Resource Group:[$TargetResourceGroupName]"
                $diskConfig = New-AzureRmDiskConfig -SourceResourceId ($dataDiskConfig.ID) -Location ($dataDiskConfig.Location) -SkuName ($dataDiskConfig.SKU) -DiskSizeGB ($dataDiskConfig.Size) -CreateOption Copy
                $null = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $TargetResourceGroupName -DiskName ($dataDiskConfig.DiskName)
            }
            Else {
                #Switch to target subscription (Test target subscription performed at beggining of function)
                $null = Set-AzureRmContext -Subscription $TargetSubscriptionId

                #Test target resource group in target subscription.
                #If no target resource group was provided a new resource group will be created in the target subscription with the same name as the source resource group (See function params).
                #Or if a target resource group was provided, but do not exist in the target subscription a new resource group will be created and named as per the provided target resource group parameter.
                If (-not (Get-AzureRmResourceGroup -Name $TargetResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Warning "The target resource group:[$TargetResourceGroupName] was not found in the target subscription. A new resource group:[$TargetResourceGroupName] will be created to store new managed disks."
                    $null = New-AzureRmResourceGroup -Name $targetResourceGroupName -Location ($dataDiskConfig.Location)
                }
                #Create new (copy) disk from source managed disk to target subscription and resource group.
                Write-Verbose "Creating Managed Data Disk:[$($dataDiskConfig.DiskName)] from managed disk:[$($mandataDisks[$i])]"
                Write-Verbose "Managed disk can be found in Resource Group:[$TargetResourceGroupName]"
                $diskConfig = New-AzureRmDiskConfig -SourceResourceId ($dataDiskConfig.ID) -Location ($dataDiskConfig.Location) -SkuName ($dataDiskConfig.SKU) -DiskSizeGB ($dataDiskConfig.Size) -CreateOption Copy
                $null = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $TargetResourceGroupName -DiskName ($dataDiskConfig.DiskName)

                #Switch back to the source subscription context.
                $null = Set-AzureRmContext -Subscription $SubscriptionId
            }
        }
    }
}