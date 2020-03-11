#! /usr/bin/env bash
#CREAMOS LAS CARPETAS SI NO ESTAN CREADAS

function comprobar_carpetas_requeridas {
	usuario=$(whoami)
	carpeta_principal="/home/$usuario/virsh"

	if [[ ! -d $carpeta_principal ]]
	then
	        echo -e "\x1b[1;31m ERROR: \x1b[0m NO EXISTEN LAS CARPETAS PARA QUE EL PROGRAMA FUNCIONE CORRECTAMENTE."
		echo " - Se crearan las carpetas /home/$usuario/virsh/{maquinas,estados,volumenes,iso,maquinas_predefinidas/{linux,windows}}"

	        read -p "¿DESEA CREARLAS? [Y / n] " permiso
	        if [[ $permiso == "n" || $permiso == "N" ]]
	        then
	                echo -e "\x1b[1;31m LO SIENTO PERO EL PROGRAMA NO FUNCIONARA SIN LAS CARPETAS CORRESPONDIENTES. \x1b[0m"
	                read -p "Pulse intro para salir"
	                exit 0
	        fi

	        mkdir -p $carpeta_principal/{maquinas,estados,volumenes,iso,maquinas_predefinidas}
	fi
}

function comprobar_maquinas_encendidas {
        if [[ `virsh list | wc -l` -eq 3 ]]
        then
                echo -e "\x1b[1;31m ERROR: Lo siento pero no tienes maquinas encendidas. \x1b[0m"
                read -p "Pulse un boton para regresar al menu"
                menu
        fi
}

function comprobar_maquinas_apagadas {
        if [[ `virsh list --inactive | wc -l` -eq 3 ]]
        then
                echo -e "\x1b[1;31m ERROR: Lo siento pero no tienes maquinas apagadas. \x1b[0m"
                read -p "Pulse un boton para regresar al menu"
                menu
        fi
}

function comprobar_ejecucion {
	#METODO DE EJECUCION
	#comprobar_ejecucion $? "mensaje para mostrar"
        #COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
        if [[ $1 -eq 0 ]]
        then
                echo -e $2
                read -p "Pulse un boton para regresar al menu"
                menu
        else
                echo -e "\x1b[1;31m ERROR: Al ejecutar la orden. \x1b[0m"
        fi
}

function existe_maquina {
	#METODO DE EJECUCION
	#existe_maquina "nombre de la maquina"
	#MIRA EN EL LISTADO LAS MAQUINAS PARA COPROBAR QUE EXISTE
	existe="false"

	for i in $(virsh list --all | cut -d ' ' -f 6-15 -s | sed -e 's/^[ \t]*//; s/[ \t]*$//; /^$/d'); do
		if [[ $i == $1 ]]
		then
			existe="true"
		fi
	done

	if [[ $existe == false ]]
	then
		echo -e "\x1b[1;31m ERROR: El nombre de la maquina no coinciden con las existentes. \x1b[0m"
		read -p "Pulse un boton para regresar al menu"
		menu
	fi
}

function comprobar_campos_vacios {
	#METODOS DE EJECUCION
	#comprobar_campos_vacios "$valor1" "$valor2"  ...
        total_campos_pasados=$#
        total_campos_llenos=0

        for i in $*; do
                ((total_campos_llenos++))
        done

        if [[ $total_campos_llenos -ne $total_campos_pasados ]]
        then
                echo -e "\x1b[1;31m ERROR: No complementaste todos los campos. \x1b[0m"
                read -p "Pulse un boton para regresar al menu"
                menu
        fi
}

function comprobar_ruta {
	#METODO DE EJECUCION
	#ruta=$(comprobar_ruta $ruta)
        ruta=$1

        while [[ ! -d $ruta || $ruta == "" ]]
        do
                read -p "ERROR: La ruta no existe vuelva a ingresar la ruta: " ruta
        done

	#QUE TERMINE CON '/' LAS RUTAS
	if [[ $ruta != */ ]]
        then
        	ruta=$ruta'/'
        fi

        echo $ruta
}

function comprobar_archivo {
	#METODO DE EJECUCION
	#comprobar_archivo $archivo
        if [[ ! -f $1 ]]
	then
                echo -e "\x1b[1;31m EL ARCHIVO NO EXISTE. \x1b[0m"
                read -p "Pulse un boton para regresar al menu"
        	menu
	fi
}

function crear_archivo_xml {
	#CREA EL ARCHIVO XML PARA LA IMPORTACION
	#METEDO DE EJECUCION
	#crear_archivo_xml maquina1 512 1 /home/usuario/virsh/maquinas_predefinidas/maquina1.qcow2
	nombre=$1
	uuid=$(uuidgen)
	ram=$2
	cpu=$3
	qcow2Ruta=$4
	mac=$(echo "02:"`openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//'`)

	echo -e "
<domain type='kvm'>
  <name>$nombre</name>
  <uuid>$uuid</uuid>
  <memory unit='KiB'>$ram</memory>
  <currentMemory unit='KiB'>$ram</currentMemory>
  <vcpu placement='static'>$cpu</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-bionic'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='custom' match='exact' check='partial'>
    <model fallback='allow'>Broadwell-IBRS</model>
  </cpu>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/kvm-spice</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$qcow2Ruta'/>
      <target dev='hda' bus='sata'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hdb' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='1'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='network'>
      <mac address='$mac'/>
      <source network='default'/>
      <model type='rtl8139'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes' keymap='es'>
      <listen type='address'/>
    </graphics>
    <video>
      <model type='cirrus' vram='16384' heads='1' primary='yes'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </memballoon>
  </devices>
</domain>" >> $carpeta_principal/maquinas_predefinidas/archivoInstalacion.xml

}

