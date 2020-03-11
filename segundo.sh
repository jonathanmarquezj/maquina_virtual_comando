#! /usr/bin/env bash

#LLAMAMOS A LAS FUNCIONES QUE ESTAN EN OTRO ARCHIVO
. funciones.sh

#PARA SABER DONDE CREAR LA CARPETAS NECESARIAS
usuario=$(whoami)

function menu {
	clear
	#MENSAJE DE EJECUCION
        figlet MENU 2

	virsh list --all

	#SI TIENE MAQUINAS EN AUTOEJECUCION LA MOSTRAMOS PARA QUE EL USUARIO ESTA INFORMADO
        if [[ -d "/etc/libvirt/qemu/autostart/" && `ls /etc/libvirt/qemu/autostart/ | cut -d '.' -f 1` != "" ]]
        then
                echo ">----- TIENES MAQUINAS CON AUTOEJECUCION -----<"
                ls /etc/libvirt/qemu/autostart/ | cut -d '.' -f 1
        fi

        echo "--------------------------------"
        echo "1: Crear clon de maquina."
        echo "2: Guardar estado actual de la maquina."
        echo "3: Recuperar maquina por el estado."
        echo "4: Eliminar una maquina."
        echo "5: Crear maquina."
	echo "6: Crear maquina sabores."
        echo "0: Salir."

        read -p "--> " seleccion_menu

        echo "--------------------------------"

        case $seleccion_menu in
                #SALIR
                0)
                        figlet "Adios : )"
                        exit 0
                ;;
		#CREAR CLON DE MAQUINA
		1)
			echo "/////////////////////////////////////////"
                        echo "        CREAR CLON DE MAQUINA"
                        echo "/////////////////////////////////////////"

			#LISTAMOS TODAS LAS MAQUINAS QUE TENEMOS
                        virsh list --all

			read -p "¿Que maquina quieres clonar? " nombre_maquina_para_clonar
			#MIRAR SI EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina_para_clonar
			read -p "¿Que nombre tendra la nueva maquina? " nombre_maquina_nueva
			ruta="$carpeta_principal/maquinas/"

			#COMPROBAR CAMPOS VACIO
                        comprobar_campos_vacios "$nombre_maquina_nueva" "$ruta"

			echo "----- REALIZANDO OPERACION, ESPERE... -----"

			contenedor=$(virt-clone -o $nombre_maquina_para_clonar -n $nombre_maquina_nueva -f $ruta$nombre_maquina_nueva.qcow2)

			#COMPROBAMOS SI LA MAQUINA SE A CLONADO CORRECTAMENTE
                        comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_para_clonar se a clonado [\x1b[1;32m OK\x1b[0m ]"
		;;
		#GUARDAR ESTADO ACTUAL DE LA MAQUINA
		2)
			echo "/////////////////////////////////////////"
                        echo "   GUARDAR ESTADO ACTUAL DE LA MAQUINA"
                        echo "/////////////////////////////////////////"

			#LISTAMOS TODAS LAS MAQUINAS QUE TENEMOS
                        virsh list --all

			read -p "¿Que maquina quieres guardar el estado? " nombre_maquina_estado
			#MIRAR SI EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina_estado

			#RUTA DONDE SE GUARDARAN LOS ESTADOS
			ruta="$carpeta_principal/estados/"
			fecha=$(date +%Y%m%d)

			contenedor=$(virsh save $nombre_maquina_estado $ruta$nombre_maquina_estado-$fecha.state)

			#COMPROBAMOS SI LA MAQUINA SE A CLONADO CORRECTAMENTE
                        comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_estado se a guardado el estado [\x1b[1;32m OK\x1b[0m ]"
		;;
		#RECUPERAR MAQUINA POR EL ESTADO
		3)
			echo "/////////////////////////////////////////"
                        echo "     RECUPERAR MAQUINA POR EL ESTADO"
                        echo "/////////////////////////////////////////"

			#PONEMOS LA RUTA OBASOLUTA DEL ARCHIVO
			read -p "Ruta absoluta del archivo del estado: [$carpeta_principal/estados/] " estado_ruta
			#EN CASO DE QUE NO PONGA NADA, PONEMOS LA DE POR DEFECTO
			if [[ -z $estado_ruta ]]
			then
				estado_ruta="$carpeta_principal/estados/"
			fi

			echo "---- Archivos que contiene la ruta: $estado_ruta ----"
			ls $estado_ruta
			read -p "Nombre del archivo para relizar la recuperacion: " estado_nombre
			#COMPROBAR SI EXISTE EL ARCHIVO
                        comprobar_archivo "$estado_ruta$estado_archivo"

			contenedor=$(virsh restore $estado_ruta$estado_nombre)

			#COMPROBAMOS SI LA MAQUINA SE A CLONADO CORRECTAMENTE
                        comprobar_ejecucion $? " - La maquina virtual a regresa al estado que solicito [\x1b[1;32m OK\x1b[0m ]"
		;;
		#ELIMINAR UNA MAQUINA
		4)
			echo "/////////////////////////////////////////"
                        echo "         ELIMINAR UNA MAQUINA"
                        echo "/////////////////////////////////////////"

			#LISTAMOS TODAS LAS MAQUINAS QUE TENEMOS
                        virsh list --all

			read -p "Nombre de la maquina para eliminar: " nombre_maquina_eliminar

			#MIRAR SI EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina_eliminar

			read -p "PELIGRO: Estas seguro de querer eliminar la maquina $nombre_maquina_eliminar, una vez eliminada no podra recuperarla. [y / N] " aviso_eliminar

			if [[ $aviso_eliminar == "Y" || $aviso_eliminar == "y" ]]
			then
				#APAGA LA MAQUINA SI ESTA ENCENDIDA
				if [[ `virsh domstate $nombre_maquina_eliminar` != "shut off" ]]
				then
					contenedor=$(virsh destroy $nombre_maquina_eliminar)
				fi

				#ELIMINAMOS LA MAQUINA Y POR ULTIMO ELIMINAMOS EL VOLUMEN DE LA MAQUINA
				contenedor=$(virsh undefine $nombre_maquina_eliminar; rm -f $carpeta_principal/maquinas/$nombre_maquina_eliminar.*)
				#COMPROBAMOS SI LA MAQUINA SE A CLONADO CORRECTAMENTE
	                        comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_eliminar a sido eliminada [\x1b[1;32m OK\x1b[0m ]"
			else
				read -p "Operacion no realizada, pulsa cualquier tecla para regresar al menu."
				clear
				menu
			fi
		;;
		#CREAR MAQUINA
		5)
			echo "/////////////////////////////////////////"
                        echo "             CREAR MAQUINA"
                        echo "/////////////////////////////////////////"

			read -p "Nombre de la maquina: " nombre_maquina
			read -p "RAM en MB: [EJ: 512] " ram_maquina
			ruta_disco_maquina="$carpeta_principal/maquinas/"

			read -p "Tamaño del disco duro en GB: [EJ: 1] " size_disco_maquina
			read -p "Numero de CPU de la maquina: [EJ: 1] " cpu_maquina

			echo "----- ISO GUARDADAS EN LA CARPETA $carpeta_principal/iso/ -----"
			ls $carpeta_principal/iso/
			echo "---------------------------------------------------------------"
			echo "NOTA: Puede poner el nombre de la iso si esta en el listado, en caso contrario tendra que poner la ruta"

			read -p "Ruta y nombre de la ISO para la instalacion: [EJ: $carpeta_principal/iso/debian.iso] " ruta_iso_maquina

			#MIRAR SI CONTIENE LA BARRA (/) EN CASO NEGATIVO QUE COJA LA RUTA POR DEFECTO
			if [[ ! $ruta_iso_maquina =~ '/' ]]
			then
				ruta_iso_maquina=$carpeta_principal/iso/$ruta_iso_maquina
			fi
			#COMPROBAR SI EXISTE EL ARCHIVO
                        comprobar_archivo $ruta_iso_maquina
			read -p "Tipo de SO: [EJ: Linux] " tipo_so_maquina

			#LISTAMOS LAS INTERFACES QUE TENEMOS
			virsh net-list
			read -p "Interfaz de red: [EJ: network:defaul] " red_maquina

			#COMPROBAR CAMPOS VACIO
                        comprobar_campos_vacios "$nombre_maquina" "$ram_maquina" "$ruta_disco_maquina" "$size_disco_maquina" "$cpu_maquina" "$ruta_iso_maquina" "$tipo_so_maquina" "$red_maquina"

			contenedor=$(virt-install --name $nombre_maquina --memory $ram_maquina --disk path=$ruta_disco_maquina$nombre_maquina.qcow2,size=$size_disco_maquina --vcpus=$cpu_maquina -c $ruta_iso_maquina --vnc --os-type $tipo_so_maquina --network $red_maquina --noautoconsole --hvm --keymap es)
			resul=$?

			read -p "¿Quieres conectarte a la maquina creada? [Y/n]" conectarse
			if [[ $conectarse != "n" && $conectarse != "N" ]]
			then
				#USAMOS screen PARA QUE NO NOS QUITE EL TERMINAL
	                        contenedor=$(screen -d -m virt-viewer $nombre_maquina)
			fi

			#COMPROBAMOS SI LA MAQUINA SE A CLONADO CORRECTAMENTE
                        comprobar_ejecucion $resul " - La maquina virtual $nombre_maquina a sido creada [\x1b[1;32m OK\x1b[0m ]"
		;;
		#CREAR MAQUINA SABORES
		6)
			read -p "¿Que SO quieres crear, linux o windows? [l / w] " tipo_maquina

			echo "<----- SO DISPONIBLES ------->"

			if [[ $tipo_maquina == 'linux' || $tipo_maquina == 'Linux' || $tipo_maquina == 'L' || $tipo_maquina == 'l' ]]
			then
				#EN CASO DE QUERER INSTALAR UN SO LINUX
				ls $carpeta_principal/maquinas_predefinidas/linux/
				echo " -- NOTA: Si en el nombre tiene una M al final, significa que es sin entorno grafico. --"

				read -p "¿Que SO quieres crear? " so
                       		#COMPROBAR SI EXISTE EL ARCHIVO
                       		comprobar_archivo $carpeta_principal/maquinas_predefinidas/linux/$so

                	        read -p "Nombre del SO: " nombreSO

        	                #COMPROBAR CAMPOS VACIO
	                        comprobar_campos_vacios "$nombreSO"

				#PARA CREAR SO DE TIPO LINUX
                                echo "      ------------------------------"
                                echo "      |  DISCO  |   RAM   |   CPU  |"
                                echo "      ------------------------------"
                                echo "1 --> |  5GB    |   512   |    1   |"
                                echo "      ------------------------------"
                                echo "2 --> |  10GB   |   1GB   |    1   |"
                                echo "      ------------------------------"
                                echo "3 --> |  15GB   |   2GB   |    2   |"
                                echo "      ------------------------------"

                                read -p "¿Que sabor? " sabor

                                case $sabor in
                                        1)
                                                ram=524288
                                                cpu=1
                                                contenedor=$(qemu-img create -f qcow2 $carpeta_principal/maquinas/$nombreSO.qcow2 5G)
                                        ;;
					2)
						ram=1048576
                                                cpu=1
                                                contenedor=$(qemu-img create -f qcow2 $carpeta_principal/maquinas/$nombreSO.qcow2 10G)
					;;
                                        3)
                                                ram=2097152
                                                cpu=2
                                                contenedor=$(qemu-img create -f qcow2 $carpeta_principal/maquinas/$nombreSO.qcow2 15G)
                                        ;;
					*)
						menu
					;;
                                esac

				#CREAMOS EL XML PARA IMPORTARLA A VIRECH
				echo "CREANDO XML"
	                        crear_archivo_xml $nombreSO $ram $cpu "$carpeta_principal/maquinas/$nombreSO.qcow2"

				echo "COPIANDO DATOS EL SO AL DISCO"
				#PASAMOS A COPIAR LOS DATOS DEL DISCO DURO MODELO
				sudo virt-resize $carpeta_principal/maquinas_predefinidas/linux/$so $carpeta_principal/maquinas/$nombreSO.qcow2 --expand /dev/sda1
			else
				#EN CASO DE QUERER INSTALAR SO WINDOWS
				ls $carpeta_principal/maquinas_predefinidas/windows/

				read -p "¿Que SO quieres crear? " so
                                #COMPROBAR SI EXISTE EL ARCHIVO
                                comprobar_archivo $ruta_iso_maquina

                                read -p "Nomobre del SO: " nombreSO

                                #COMPROBAR CAMPOS VACIO
                                comprobar_campos_vacios "$nombreSO"



			fi

			echo "INICIANDO IMPORTACION"
			#EMPEZAMOS CON LA IMPORTACION DE LA MAQUINA
			virsh define $carpeta_principal/maquinas_predefinidas/archivoInstalacion.xml

			resul=$?

			echo "ELIMINADO XML"
			#BORRAMOS EL ARCHIVO DE CONFIGURACION
			rm $carpeta_principal/maquinas_predefinidas/archivoInstalacion.xml

			#COMPROBAMOS SI LA MAQUINA SE A CLONADO CORRECTAMENTE
                        comprobar_ejecucion $resul " - La maquina virtual $nombreSO a sido creada [\x1b[1;32m OK\x1b[0m ]"

		;;
		*)
			echo "/////////////////////////////////////////"
                        echo "                  ERROR"
                        echo "/////////////////////////////////////////"

                        echo -e "\x1b[1;31m LO SIENTO PERO ESA PETICION NO ES RECONOCIDA. \x1b[0m"
                        read -p "Pulse un boton para regresar al menu"
                        menu
		;;
	esac
}

#EJECUTAMOS EL MENU
comprobar_carpetas_requeridas
menu


