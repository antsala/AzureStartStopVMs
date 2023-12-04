# AzureStartStopVMs
Configuración de la automatización para programar el inicio y el apagado de VMs.

`Nota: Si estás buscando el inicio/apagado de un grupo de VMs, mira el apartado 10.`

Contenidos.

1. [Configuración de VSC para trabajar con Azure Automation](https://github.com/antsala/AzureStartStopVMs#1-configuraci%C3%B3n-de-vsc-para-trabajar-con-azure-automation)
2. [Creación del grupo de recursos](https://github.com/antsala/AzureStartStopVMs#2-creaci%C3%B3n-del-grupo-de-recursos)
3. [Creación de la cuenta de automatización y asignación de rol](https://github.com/antsala/AzureStartStopVMs#3-creaci%C3%B3n-de-la-cuenta-de-automatizaci%C3%B3n-y-asignaci%C3%B3n-de-rol)
4. [Verificar la conexión de VSC con la cuenta de automatización recién creada](https://github.com/antsala/AzureStartStopVMs#4-verificar-la-conexi%C3%B3n-de-vsc-con-la-cuenta-de-automatizaci%C3%B3n-reci%C3%A9n-creada)
5. [Creación del runbook](https://github.com/antsala/AzureStartStopVMs#5-creaci%C3%B3n-del-runbook)
6. [Edición del código fuente del runbook desde VSC](https://github.com/antsala/AzureStartStopVMs#6-edici%C3%B3n-del-c%C3%B3digo-fuente-del-runbook-desde-vsc)
7. [Ejecución manual del runbook](https://github.com/antsala/AzureStartStopVMs#7-ejecuci%C3%B3n-manual-del-runbook)
8. [Crear planificación de encendido/apagado de la VM](https://github.com/antsala/AzureStartStopVMs#8-crear-planificaci%C3%B3n-de-encendidoapagado-de-la-vm)
9. [Crear alertas de Azure Monitor para verificar inicio/apagado](https://github.com/antsala/AzureStartStopVMs#9-crear-alertas-de-azure-monitor-para-verificar-inicioapagado)
10. [Runbook para iniciar/detener todas las VMs de un RG](https://github.com/antsala/AzureStartStopVMs#10-runbook-para-iniciardetener-todas-las-vms-de-un-rg)






## 1. Configuración de VSC para trabajar con Azure Automation.

Como podrás ver, trabajar con un script de PowerShell directamente en la página web de Azure, editándolo desde el Runbook es impracticable, entre otras cosas porque no ofrece intelliSense. Por lo tanto usaremos VSC e instalaremos el plugin de Automatización. 

En el panel izquierdo de VSC, seleccionamos las extensiones (podemos usar la combinacion ***CTRL+SHIFT+X***)

En el cuadro de búsqueda escribimos...
```
Azure automation
```

El la imagen puedes ver como aparece la extensión.

![Azure Automation](./img/202303042034.png)

Procedemos a su instalación haciendo clic en el botón ***Install*** de la extensión.

Usaremos VSC en breve.

## 2. Creación del grupo de recursos.

Creamos un grupo de recursos para mantener juntos todos los recursos relacionados con la automatización, que son los siguientes:

* Cuenta de automatización.
* Runbook

Para ello creamos en Azure un grupo de recursos en la subscripción ***Ecosistema de aprendizaje***, con la siguiente configuración.

![auto-start-stop-vm-rg](./img/202303042041.png)

## 3. Creación de la cuenta de automatización y asignación de rol.

Procedemos a crear una ***cuenta de automatización*** (Automation Accounts) de Azure en el grupo de recursos anterior, configurándola de la siguiente manera, en la pestaña ***Basics*** debemos poner...

![auto-act-1](./img/202303042045.png)

Hacemos clic para acceder a la pestaña ***Advanced***, donde debemos indicar la identidad con la que se presentará esta cuenta de automatización. Como las identidades tipo ***Run As Account*** ya no se pueden usar en Azure, debemos elegir una identidad ***Asignada por el sistema*** (System Assigned)

![auto-act-2](./img/202303042048.png)

Avanzamos hasta ***Networking***, donde elegimos ***Public Access***, ya que no hay integración con la red on-prem.

![auto-act-3](./img/202303042050.png)

Hacemos clic en el botón ***Review + Create***. Cuando la verificación haya sido correcta, hacemos clic en ***Create*** y esperamos a que se cree la cuenta de automatización y accedemos al recurso.

Ahora necesitamos asignar permisos,  en un ámbito de Azure, a la identidad administrada que ha creado la cuenta de automatización. Esto se hace por medio de la opción ***Identity*** del grupo ***Account Settings***, tal y como se muestra en la imagen.

![Identity](./img/202303051105.png)

Hacemos clic en el botón ***Azure Role Assignments***.

![Assigments](./img/202303051107.png)

Con la suscripción ***Ecosistema de aprendizaje*** seleccionada, hacemos clic en ***Add role Assignment***.

![Add role Assigment](./img/202303051109.png)

Asignamos el rol ***Contributor*** en el ámbito de la suscripción ***Ecosistema de aprendizaje***, y hacemos clic en el botón ***Save***.

![role](./img/202303051111.png)

A partir de ahora, la identidad administrada asociada a esta cuenta de automatización tendrá el rol de contribuidor en la suscripción, por lo que será capaz de iniciar y detener VMs.


## 4. Verificar la conexión de VSC con la cuenta de automatización recién creada.

Volvemos a VSC. En el menú lateral izquierdo, hacemos clic en el icono de Azure. También se puede conseguir con ***SHIFT+ALT+A***.

![Azure](./img/202303042054.png)

En la sección ***Azure Automation***, desplegamos la subscripción ***Ecosistema de apredizaje***, y en ella, la cuenta de automatización recién creada. Podremos ver los componentes de dicha cuenta de automatización.

![VSC](./img/202303042058.png)

A partir de ahora podemos crear los componentes desde VSC o desde la Interfaz de Azure.


## 5. Creación del runbook.

Creamos un runbook para iniciar/detener las VMs. Para ello, desde la interfaz de Azure, y dentro de la cuenta de automatización, hacemos clic en el botón ***Create a runbook***.

![Create RB-1](./img/202303042100.png)

El runbook lo configuramos de la siguiente forma...

![Create RB-2](./img/202303042108.png)

Hacemos clic en el botón ***Create*** y esperamos a que termine su creación.

Aparecerá el editor del runbook, con una interfaz muy pobre, así que vamos a programarlo desde VSC.

## 6. Edición del código fuente del runbook desde VSC.

De vuelta en VSC, en el panel izquierdo debemos ver ya el runbook creado desde la interfaz gráfica de Azure.

![VSC](./img/202303042112.png)

Esto permitirá usar toda la potencia de este editor. El contenido del runbook es el siguiente...
```
Param (
    [Parameter (Mandatory = $true)] [String] $vmName = "HyperV02",
    [Parameter (Mandatory = $true)] [String] $rgName = "FdlSM_PruebaLabs",
    [Parameter (Mandatory = $true)] [String] $startStopAction = "Start"
)

function doUntilCondition {
    param(
        [Parameter(Mandatory = $true, Position = 0)] [String]$vm,
        [Parameter(Mandatory = $true, Position = 1)] [String]$rg,  
        [Parameter(Mandatory = $true, Position = 2)] [String]$powerState
    )

    # Inicializo el estado de aprovisionamiento.
    $lastProvisioningState = ""

    # Tomo el estado de aprovisionamiento de la VM.
    $provisioningState = (Get-AzVM -name $vm -resourcegroupname $rg -Status).Statuses[1].Code
    
    # Determino la condición de salida del bucle infinito.
    $condition = ($provisioningState -eq $powerState)
    
    # Iteramos hasta que la VM esté en ejecución.
    while (!$condition) {
        if ($lastProvisioningState -ne $provisioningState) {
            write-host "$vm en el grupo de recursos $rg tiene el estado $provisioningState (Esperando a que cambie el estado)"
        }
        $lastProvisioningState = $provisioningState
 
        # Esperamos para actualizar.
        Start-Sleep -Seconds 5

        # Actualizamos estado.
        $provisioningState = (Get-AzVM -name $vm -resourcegroupname $rg -Status).Statuses[1].Code
 
        # Actualizamos condición de salida del bucle.
        $condition = ($provisioningState -eq $powerState)
    }

    # La VM ha alcanzado el estado deseado.
    Write-Output "$vm en el grupo de recursos $rg tiene el estado $provisioningState" -ForegroundColor Green
}


# Programa principal.

Write-Output "Conectando a Azure mediante el comando Connect-AzAccount -Identity"

Connect-AzAccount -Identity 

Write-Output "Conectado por medio de la identidad administrada de la cuenta de automatización."

# Compruebo si la VM existe.
Get-AzVM -Name $vmName -ResourceGroupName $rgName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent) {
    Write-Output "No se ha encontrado la VM $vmName en el grupo de recursos $rgName. Finalizando script"
    
    # Esperamos unos segundos para que terminen de llegar los eventos asíncronos antes de...
    Start-Sleep -Seconds 10

    # Lanzar una excepción para que finalice el script.
    throw "VM no encontrada"
}


if ($startStopAction -eq "Start") {
    Write-Output "Iniciando la VM $vmName del grupo de recursos $rgName"

    # Inicio la VM y no espero.
    Start-AzVM -Name $vmName -ResourceGroupName $rgName -noWait

    # Espero hasta que la VM se haya iniciado.
    doUntilCondition -vm $vmName -rg $rgName -powerState "PowerState/running"
}
elseif ($startStopAction -eq "Stop") {
    Write-Output "Deteniendo la VM $vmName del grupo de recursos $rgName"

    $ProgressPreference = "SilentlyContinue"

    # Detengo la VM y no espero. 
    # Importante poner "Force" porque el script falla esperando la confirmación del usuario al no poder leer la entrada estándar.
    Stop-AzVM -Name $vmName -ResourceGroupName $rgName -noWait -Force

    # Espero hasta que la VM se haya detenido.
    doUntilCondition -vm $vmName -rg $rgName -powerState "PowerState/deallocated"
}
else {
    # La acción es incorrecta.
    Write-Output "La acción" $startStopAction "no se puede procesar."
}
```

Copialo y pégalo en VSC. A continuación lo guardamos con ***CTRL+S***.

El runbook lo tenemos en local. Para subirlo a Azure hay que publicarlo. Para ello, hacemos clic ***con el botón derecho***, en el nombre del runbook que tenemos en el panel izquierdo. Aparecerá un menú contextual en el que debemos seleccionar la opción ***Publish Runbook***.

VSC pedirá permiso para la publicación. Hacemos clic en ***Yes***

![Yes](./img/202303042122.png)

Cuando se haya subido, VSC mostrará un mensaje en la parte inferior derecha de su ventana.

![OK](./img/202303042124.png)

Es el momento de comprobar el resultado en la web de Azure. Hacemos clic en en link del runbook...

![RB link](./img/202303042127.png)

Aquí veremos dos botones. El botón ***View*** permitirá en forma de solo lectura el código del runbook, mientras que ***Edit*** permitirá editarlo. Esto último no lo recomendamos y aconsejamos hacerlo en VSC, para posteriormente publicarlo.

![view/edit](./img/202303042129.png)

## 7. Ejecución manual del runbook.

Para ejecutarlo hacemos clic en el botón ***Start***.

Como el runbook tiene parámetros, habrá que rellerarlos. Todos los campos son obligatorios. 

* ***VMNAME***: Es el nombre de la VM.
* ***RGNAME***: Es el nombre del grupo de recursos que tiene la VM.
* ***STARTSTOPACTION***: Debe ser ***Start*** o ***Stop***. No se admite ningún otro valor.

![Parámetros](./img/202303051120.png)

A modo de ejemplo iniciamos con el parámetro ***Start*** la VM ***HyperV02*** ubicada en el grupo de recursos ***FdlSM_PruebaLabs***. Hacemos clic el el botón ***OK***.

![Start](./img/202303051121.png)

Se creará un trabajo para ejecutar el script de PowerShell del runbook, tal y como puede apreciarse en la siguiente imagen.
(Nota: Observa que en la pestaña ***input*** se muestran los parámetros de entrada al script.)

![Job Input](./img/202303051122.png)

El resto de pestañas (***Output***, ***Errors***, ***Warnings***, ***All Logs***, ***Exception***), destacamos las dos siguientes:

* ***Errors***: Mostrará si el script tiene errores y se usa en la fase de depuración.
* ***All Logs***: Visualiza la salida estándar de la ejecución del script. Es importante observar que los resultados obtenidos pueden no verse en el orden correcto, ya que la ejecución es asíncrona, y unos resultados pueden venir antes que otros.

Si seleccionamos la pestaña ***All Logs*** podremos ver todo lo que hace el script. Es muy importante observar que no produce errores ni avisos.

![All logs](./img/202303051124.png)

Pasado un rato, comprobamos que la VM se ha iniciado correctamente.

![Running](./img/202303051126.png)

Para apagar la VM, procedemos a ejecutar el runbook, pasando el parámetro ***Stop***. Procedemos a apagarla.

![Stop](./img/202303051158.png)

## 8. Crear planificación de encendido/apagado de la VM.

La planificación (schedule) nos permite ejecutar un runbook en el momento que deseemos (con la periodicidad deseada.) Para crear una entramos en la planificación de la cuentas de automatización (en este caso ***auto-start-stop-vm-act***) y hacemos clic en ***Schedules***, en la sección ***Shared Resources***. Posteriormente clic en  ***Add a schedule***.

![Schedule](./img/202303051315.png)

A modo de ejemplo, supongamos que un curso de SAP se debe iniciar (START) todos los días desde el 6/3/2023 hasta el 10/3/2023, a las 9:00. Teniendo en cuenta la recomendación de Azure de iniciar 5 minutos antes, podría ser así.

![Schedule 6 al 10](./img/202303051319.png)

Hacemos clic en el botón ***Create***. Se creará la plafinicación, pero no estará asociada aún a ningun runbook. Esto se puede ver haciendo clic en la planificación recién creada.

![No runbook](./img/202303051324.png)

Para asignarle un runbook hacemos clic en ***Runbooks***, en la sección ***Process Automation***.

![Runbooks](./img/202303051327.png)

Elegimos el runbook apropiado, en este caso ***auto-start-stop-vm-rb***.

![Runbook auto-start-stop-vm-rb](./img/202303051329.png)

Y le asignamos la planificación por medio de ***Link to schedule***.

![Link to Schedule](./img/202303051330.png)

Ahora debemos hacer dos cosas; En ***Schedule*** seleccionar la planificación que hemos creado antes y, en ***Parameters and run Settings*** proporcionar los parámetros para que se ejecute el runbook.

![Config](./img/202303051332.png)

Elegimos ***Curso SAP-START-Semana 6 al 10 Marzo***.

![Semana 6 al 10](./img/202303051334.png)

De vuelta a la planificación del runbook, hacemos clic en ***Parameters and run Settings*** y lo configuramos así.
(Nota: Asegurar que se pone ***Start***)

![Parámetros](./img/202303051336.png)

Hacemos clic en ***OK*** dos veces.

Volviendo a las planificaciones de la cuenta de automatización, podremos ver ya que la planificación está asociada al runbook correcto.

![Comprobación](./img/202303051339.png)

***Nota Importante***: Habrá que crear una programación similar para detener las máquinas virtuales, para ello repetimos el procedimiento usando ***Stop*** como parámetro del runbook, el resultado sería este.

![Schedules](./img/202303051352.png)

## 9. Crear alertas de Azure Monitor para verificar inicio/apagado.

Como detalle, configuraremos alertas para confirmar la automatización. En primer lugar vamos a crear un grupo de acción en el que indicaremos cómo enviar la alerta. Para ello buscamos el recurso ***Alerts*** en Azure. A continuación seleccionamos ***Action groups***.

![Action Groups](./img/202303051401.png)

Hacemos clic en ***Create***.

![Create](./img/202303051407.png)

Configuramos la pestaña ***Basics*** de la siguiente forma y hacemos clicn en ***Next***.

![Basics](./img/202303051409.png)

En ***Notifications*** elegimos la forma deseada. 

![Basics](./img/202303051412.png)

Avanzamos hacia ***Actions***, donde no configuramos nada. Hacemos clic en ***Review + Create*** y posteriormente en ***Create***.

En ***Action groups*** podremos ver el grupo de acción recién creado.

![action groups](./img/202303051417.png)

Es el momento de crear las reglas de alertas. Para ello, en las alertas, elegimos ***Alerts rules***.

![Alert rules](./img/202303051418.png)

clic en ***Create***.

![Create](./img/202303051421.png)

En la sección ***Scope*** establecemos el ámbito para el que se dispararán las alertas. Elegimos la subscripción ***Ecosistema de aprendizaje*** y refinamos el ámbito para emitir alertas solo de ***Virtual Machines***. Hacemos clic en ***Apply***.

![Create](./img/202303051424.png)

Clic en Siguiente.

En la pestaña de condiciones debemos elegir las señales que dispararán las alertas. Hacemos clic en ***Add condition***. En ***Select a signal*** filtramos por ***start*** y hacemos clic en ***Start Virtual Machine (Microsoft.Compute/virtualMachines)***.

![start](./img/202303051427.png)

En la página ***Create an alert rule***, configuramos ***Alert logic*** de forma que se emitan alertas de inicio de VM (Estado) cuyo inicio haya sido provocado por la cuenta de automatización ***auto-start-stop-vm-act***.

![Alert logic](./img/202303051639.png)

Avanzamos a ***Actions*** y hacemos clic en ***Select action groups***.

![Select action group](./img/202303051437.png)

Elegimos el grupo de acción que creamos anteriormente y hacemos clic en ***Select***.

![Select action group 2](./img/202303051439.png)

Avanzamos a ***Details***. Lo configuramos así.

![Details](./img/202303051441.png)

Clic en ***Review + Create*** y luego en ***Create***.

Aparecerá la alerta en la lista de alertas de Azure.

![Alerts](./img/202303051444.png)

Para terminar, creamos otra alerta que avise cuando la máquina virtual se ha detenido (con desasignación). La señal que debemos configurar es ***Deallocate Virtual Machine (Microsoft.Compute/virtualMachines)***. 

![Deallocate](./img/202303051446.png)

El resultado se puede ver en la siguiente imagen, donde aparecen las dos alertas configuradas.

![Alerts](./img/202303051450.png)


## 10. Runbook para iniciar/detener todas las VMs de un RG.

He desarrollado un nuevo runbook que inicia/detiene todas las VMs de un grupo de recursos. Se utiliza para complementar el despliegue automatizado de laboratorios en el Bastión de Azure. El runbook se llama `auto-start-stop-rg-vms-rb` y su código es el siguiente.

```
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

            Write-Host "El estado de la VM '$($vm.Name)' es '$provisioningState'. Esperando que alcance estado '$powerState'." 
            
            if ($provisioningState -ne $powerState) {
                # Basta que una sola VM no haya alcanzado el estado de aprovisionamiento esperado, seguimos.
                $seguir = $true
            }
        }

        Write-Host

        # Esperamos para actualizar.
        Start-Sleep -Seconds 15
    } while ($seguir)

    # Objetivo conseguido
    Write-Output "Todas las VMs en el grupo de recursos $rg han llegado al estado $powerState" 
}


# Programa principal.

Connect-AzAccount -Identity 
Write-Host "Conectado por medio de la identidad administrada de la cuenta de automatización."

# Cargo en una lista las VMs presentes en el grupo de recursos.
$vms = Get-AzVM -ResourceGroupName $rgName -ErrorVariable notPresent -ErrorAction SilentlyContinue


if ($notPresent) {
    Write-Host "No hay máquinas virtuales en el grupo de recursos '$rgName'. Finalizando script"
    
    # Esperamos unos segundos para que terminen de llegar los eventos asíncronos antes de...
    Start-Sleep -Seconds 10

    # Lanzar una excepción para que finalice el script.
    throw "VM no encontrada"
}

# Mostrar información sobre cada VM en la lista
foreach ($vm in $vms) {
    Write-Host "Encontrada VM: $($vm.Name)" 
}

if ($startStopAction -eq "Start") {
    Write-Host "Iniciando las VMs del grupo de recursos '$rgName'" 

    foreach ($vm in $vms) {
        # Inicio la VM y no espero.
        Start-AzVM -Name $($vm.Name) -ResourceGroupName $rgName -noWait
    }

    # Espero hasta que las VMs se hayan iniciado.
    doUntilCondition -rg $rgName -powerState "PowerState/running"
}
elseif ($startStopAction -eq "Stop") {
    Write-Host "Deteniendo las VMs del grupo de recursos '$rgName'" 

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
    Write-Host "La acción" $startStopAction "no se puede procesar." 
}
```