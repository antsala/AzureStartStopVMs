Param (
    [Parameter (Mandatory = $true)] [String] $rgName,
    [Parameter (Mandatory = $true)] [String] $startStopAction = "Start"
)

function doUntilCondition {
    param(
        [Parameter(Mandatory = $true)] [String]$rg,  
        [Parameter(Mandatory = $true)] [String]$powerState
    )
    # Esta función espera a que todas las VMs del grupo de recursos alcancen el estado deseado.

    do {
        $seguir = $false

        foreach ($vm in $vms) {
            # Tomo el estado de aprovisionamiento de la VM.
            $provisioningState = (Get-AzVM -name $($vm.Name) -resourcegroupname $rg -Status).Statuses[1].Code

            if ($provisioningState -eq $powerState) {
                Write-Host "El estado de la VM '$($vm.Name)' es '$provisioningState'" -ForegroundColor Green
            }
            else {
                Write-Host "El estado de la VM '$($vm.Name)' es '$provisioningState'" -ForegroundColor Yellow
                # Basta que una sola VM no haya alcanzado el estado de aprovisionamiento esperado, seguimos.
                $seguir = $true
            }
        }

        Write-Host

        # Esperamos para actualizar.
        Start-Sleep -Seconds 15
    } while ($seguir)

    # Objetivo conseguido
    Write-Output "Todas las VMs en el grupo de recursos $rg han llegado al estado $powerState" -ForegroundColor Green
}


# Programa principal.

Connect-AzAccount -Identity 
Write-Host "Conectado por medio de la identidad administrada de la cuenta de automatización."

# Cargo en una lista las VMs presentes en el grupo de recursos.
$vms = Get-AzVM -ResourceGroupName $rgName -ErrorVariable notPresent -ErrorAction SilentlyContinue


if ($notPresent) {
    Write-Host "No hay máquinas virtuales en el grupo de recursos '$rgName'. Finalizando script" -ForegroundColor Red
    
    # Esperamos unos segundos para que terminen de llegar los eventos asíncronos antes de...
    Start-Sleep -Seconds 10

    # Lanzar una excepción para que finalice el script.
    throw "VM no encontrada"
}

# Mostrar información sobre cada VM en la lista
foreach ($vm in $vms) {
    Write-Host "Encontrada VM: $($vm.Name)" -ForegroundColor Green
}

if ($startStopAction -eq "Start") {
    Write-Host "Iniciando las VMs del grupo de recursos '$rgName'" -ForegroundColor Yellow

    foreach ($vm in $vms) {
        # Inicio la VM y no espero.
        Start-AzVM -Name $($vm.Name) -ResourceGroupName $rgName -noWait
    }

    # Espero hasta que las VMs se hayan iniciado.
    doUntilCondition -rg $rgName -powerState "PowerState/running"
}
elseif ($startStopAction -eq "Stop") {
    Write-Host "Deteniendo las VMs del grupo de recursos '$rgName'" -ForegroundColor Yellow

    foreach ($vm in $vms) {
        # Detengo la VM y no espero. 
        # Importante poner "Force" porque el script falla esperando la confirmación del usuario al no poder leer la entrada estándar.
        Stop-AzVM -Name $($vm.Name) -ResourceGroupName $rgName -noWait -Force
    }
        
    # Espero hasta que la VM se haya detenido.
    doUntilCondition -rg $rgName -powerState "PowerState/deallocated"
}
else {
    # La acción es incorrecta.
    Write-Host "La acción" $startStopAction "no se puede procesar." -ForegroundColor Red
}

