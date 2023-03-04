Param (
    [Parameter (Mandatory = $true)] [String] $rgName = "FdlSM_PruebaLabs",
    [Parameter (Mandatory = $true)] [String] $vmName = "HyperV02",
    [Parameter (Mandatory = $true)] [String] $startStopAction = "Start"
)

function doUntilCondition {
    param(
        [Parameter(Mandatory = $true, Position = 0)] [String]$rg,  
        [Parameter(Mandatory = $true, Position = 1)] [String]$vm,
        [Parameter(Mandatory = $true, Position = 2)] [String]$powerState
    )

    # Inicializo el estado de aprovisionamiento.
    $lastProvisioningState = ""

    # Tomo el estado de aprovisionamiento de la VM.
    $provisioningState = (Get-AzVM -resourcegroupname $rg -name $vm -Status).Statuses[1].Code
    
    # Determino la condición de salida del bucle infinito.
    $condition = ($provisioningState -eq $powerState)
    
    # Iteramos hasta que la VM esté en ejecución.
    while (!$condition) {
        if ($lastProvisioningState -ne $provisioningState) {
            write-host $vm "en el grupo de recursos" $rg "tiene el estado" $provisioningState "(Esperando a que cambie el estado)"
        }
        $lastProvisioningState = $provisioningState
 
        # Esperamos para actualizar.
        Start-Sleep -Seconds 5

        # Actualizamos estado.
        $provisioningState = (Get-AzVM -resourcegroupname $rg -name $vm -Status).Statuses[1].Code
 
        # Actualizamos condición de salida del bucle.
        $condition = ($provisioningState -eq $powerState)
    }

    # La VM ha alcanzado el estado deseado.
    Write-Output $vm "en el grupo de recursos" $rg "tiene el estado" $provisioningState -ForegroundColor Green
}


# Programa principal.

Write-Output "Conectando a Azure mediante el comando Connect-AzAccount -Identity"

Connect-AzAccount -Identity 

Write-Output "Conectado por medio de la identidad administrada de la cuenta de automatización."

# Compruebo si la VM existe.
Get-AzVM -ResourceGroupName $rgName -Name $vmName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent) {
    Write-Output "No se ha encontrado la VM" $vmName "en el grupo de recursos" $rgName ". Finalizando script"
    
    # Esperamos unos segundos para que terminen de llegar los eventos asíncronos antes de...
    Start-Sleep -Seconds 10

    # Lanzar una excepción para que finalice el script.
    throw "VM no encontrada"
}


if ($startStopAction -eq "Start") {
    Write-Output "Iniciando la VM $vmName del grupo de recursos $rgName"

    # Inicio la VM y no espero.
    Start-AzVM -ResourceGroupName $rgName -Name $vmName -noWait

    # Espero hasta que la VM se haya iniciado.
    doUntilCondition -rg $rgName -vm $vmName -powerState "PowerState/running"
}
elseif ($startStopAction -eq "Stop") {
    Write-Output "Deteniendo la VM $vmName del grupo de recursos $rgName"

    $ProgressPreference = "SilentlyContinue"

    # Detengo la VM y no espero. 
    # Importante poner "Force" porque el script falla esperando la confirmación del usuario al no poder leer la entrada estándar.
    Stop-AzVM -ResourceGroupName $rgName -Name $vmName -noWait -Force

    # Espero hasta que la VM se haya detenido.
    doUntilCondition -rg $rgName -vm $vmName -powerState "PowerState/deallocated"
}
else {
    # La acción es incorrecta.
    Write-Output "La acción" $startStopAction "no se puede procesar."
}