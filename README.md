# AzureStartStopVMs
Configuración de la automatización para programar el inicio y el apagado de VMs.

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

## 3. Creación de la cuenta de automatización.

Procedemos a crear una ***cuenta de automatización*** (Automation Accounts) de Azure en el grupo de recursos anterior, configurándola de la siguiente manera, en la pestaña ***Basics*** debemos poner...

![auto-act-1](./img/202303042045.png)

Hacemos clic para acceder a la pestaña ***Advanced***, donde debemos indicar la identidad con la que se presentará esta cuenta de automatización. Como las identidades tipo ***Run As Account*** ya no se pueden usar en Azure, debemos elegir una identidad ***Asignada por el sistema*** (System Assigned)

![auto-act-2](./img/202303042048.png)

Avanzamos hasta ***Networking***, donde elegimos ***Public Access***, ya que no hay integración con la red on-prem.

![auto-act-3](./img/202303042050.png)

Hacemos clic en el botón ***Review + Create***. Cuando la verificación haya sido correcta, hacemos clic en ***Create*** y esperamos a que se cree la cuenta de automatización y accedemos al recurso.

## 4. Verificar la conexión de VSC con la cuenta de automatización recién creada.

Volvemos a VSC. En el menú lateral izquierdo, hacemos clic en el icono de Azure. También se puede conseguir con ***SHIFT+ALT+A***.

![Azure](./img/202303042054.png)

En la sección ***Azure Automation***, desplegamos la subscripción ***Ecosistema de apredizaje***, y en ella, la cuenta de automatización recién creada. Podremos ver los componentes de dicha cuenta de automatización.

![VSC](./img/202303042058.png)

A partir de ahora podemos crear los componentes desde VSC o desde la Interfaz de Azure.

## 5. Creación del runbook

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

![Start](./img/202303042130.png)

Como el runbook tiene parámetros, habrá que rellerarlos. Todos los campos son obligatorios. 

* ***RGNAME*** Es el nombre del grupo de recursos que tiene la VM.
* ***VMNAME*** Es el nombre de la VM.
* ***STARTSTOPACTION*** Debe ser ***Start*** o ***Stop***. No se admite ningún otro valor.



![Parámetros](./img/202303042134.png)







