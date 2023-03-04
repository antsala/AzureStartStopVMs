# AzureStartStopVMs
Configuración de la automatización para programar el inicio y el apagado de VMs.

## 1. Configuración de VSC para trabajar con Azure Automation.

Como podrás ver, trabajar con un script de PowerShell directamente en la página web de Azure, editándolo desde el Runbook es impracticable, entre otras cosas porque no ofrece intelliSense. Por lo tanto usaremos VSC e nstalaremos el plugin de Automatización. 

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

Para ello creamos en azure un grupo de recursos en la subscripción ***Ecosistema de aprendizaje***, con la siguiente configuración.

![auto-start-stop-vm-rg](./img/202303042041.png)

## 3. Creación de la cuenta de automatización.

Procedemos a crear una ***cuenta de automatización*** (Automation Accounts) de Azure en el grupo de recursos anterior, configurándola de la siguiente la pestaña ***Basics***.

![auto-act-1](./img/202303042045.png)

Hacemos clic para acceder a la pestaña ***Advanced***, donde debemos indicar la identidad con la que se presentará esta cuenta de automatización. Como las identidades tipo ***Run As Account*** ya no se pueden usar en Azure, debemos elegir una identidad ***Asignada por el sistema*** (System Assigned)

![auto-act-2](./img/202303042048.png)

Avanzamos hasta ***Networking***, donde elegimos ***Public Access***, ya que no hay integración con la red on-prem.

![auto-act-3](./img/202303042050.png)

Hacemos clic en el botón ***Review + Create***. Cuando la verificación haya sido correcta, hacemos clic en ***Create*** y esperamos a que se cree la cuenta de automatización y accedemos al recurso.

## 4. erificar la conexión de VSC con la cuenta de automatización recién creada.

Volvemos a VSC. En el menú lateral izquierdo, hacemos clic en el icono de Azure. También se puede conseguir con ***SHIFT+ALT+A***

![Azure](./img/202303042054.png)

En la sección ***Azure Automation*** desplegamos la subscripción ***Ecosistema de apredizaje***, y en ella la cuenta de automatización recién creada. Podremos ver los componentes de dicha cuenta de automatización.

![VSC](./img/202303042058.png)

A partir de ahora podemos crear los componentes desde VSC o desde la Interfaz de Azure.

# 5. Creación del runbook

Creamos un runbook para iniciar/detener las VMs. Para ello, desde la interfaz de Azure, y dentro de la cuenta de automatización, hacemos clic en el botón ***Create a runbook***.

![Create RB](./img/202303042100.png)













