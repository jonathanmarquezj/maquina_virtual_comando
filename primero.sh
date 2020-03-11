#! /usr/bin/env bash
#PAQUETES REQUERIDOS
#  -figlet
#  -screen

#LLAMAMOS A LAS FUNCIONES QUE ESTAN EN OTRO ARCHIVO
. funciones.sh

function menu {
	clear
	#MENSAJE DE EJECUCION
	figlet MENU 1

	virsh list --all

	#SI TIENE MAQUINAS EN AUTOEJECUCION LA MOSTRAMOS PARA QUE EL USUARIO ESTA INFORMADO
	if [[ -d "/etc/libvirt/qemu/autostart/" && `ls /etc/libvirt/qemu/autostart/ | cut -d '.' -f 1` != "" ]]
	then
		echo ">----- TIENES MAQUINAS CON AUTOEJECUCION -----<"
		ls /etc/libvirt/qemu/autostart/ | cut -d '.' -f 1
	fi

	echo "--------------------------------"
	echo "1: Listar las maquinas / volumenes."
	echo ""
	echo "2: Encender maquina virtual."
	echo "3: Apagar maquina."
	echo "4: Reiniciar maquina."
	echo "5: Suspender o Despertar maquina."
	echo "6: Autoencender maquinas."
	echo ""
	echo "7: Añadir volumen."
	echo "8: Quitar volumen asociado."
	echo ""
	echo "9: Conectarse a la maquina."
	echo "10: Instantanea."
	echo ""
	echo "0: Salir."
	echo ""

	read -p "--> " seleccion_menu

	echo "--------------------------------"

	case $seleccion_menu in
        	#SALIR
		0)
			figlet "Adios : )"
			exit 0
		;;
		#LISTAR MAQUINAS / VOLUMENES
		1)
			#LISTAMOS TODAS LAS MAQUINAS QUE TENEMOS
			virsh list --all

			read -p "Nombre de la maquina para ver los volumenes: " nombre_maquina_volumen_actual
			#MIRAR SI EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina_volumen_actual

			virsh domblklist $nombre_maquina_volumen_actual

			read -p "Pulsa un boton para regresar al menu"
			menu
        	;;
		#INICIAR MAQUINA VIRTUAL
		2)
			echo "/////////////////////////////////////////"
			echo "        INICIAR MAQUINA VIRTUAL"
			echo "/////////////////////////////////////////"

			#COMPROBAR SI TENEMOS ALGUNA MAQUINA APAGADA PARA ENCENDER
			comprobar_maquinas_apagadas
			#LISTAMOS LAS MAQUINAS
			virsh list --inactive
			read -p "¿Que maquina virtual quieres iniciar? " nombre_maquina_virtual

			#MIRAR SI EXISTE LA MAQUINA
			existe_maquina $nombre_maquina_virtual

			#INICIAMOS LA MAQUINA VIRTUAL
			contenedor=$(virsh start $nombre_maquina_virtual)

			#COMPROBAMOS SI LA MAQUINA SE A INICIADO CORRECTAMENTE
			comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se a iniciado correctamente [\x1b[1;32m OK\x1b[0m ]"
		;;
		#APAGAR MAQUINA VIRTUAL
		3)
			echo "/////////////////////////////////////////"
                        echo "        APAGAR MAQUINA VIRTUAL"
                        echo "/////////////////////////////////////////"

			#COMPROBAMOS SI TENEMOS MAQUINAS ENCENDIDAS PARA APAGAR
			comprobar_maquinas_encendidas
			#LISTAMOS LAS MAQUINAS
			virsh list

			#PEDIMOS LOS PARAMETROS NECESARIOS
			read -p "¿Que maquina quieres apagar? " nombre_maquina_virtual

			#MIRAR SI EXISTE LA MAQUINA
			existe_maquina $nombre_maquina_virtual

			read -p "¿En que modo quieres apagarla, normal o bruta? [N / b] " modo_apagado

			if [[ $modo_apagado == "b" || $modo_apagado == "B" ]]
			then
				contenedor=$(virsh destroy $nombre_maquina_virtual)
				#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
				comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se a apagado bruscamente [\x1b[1;32m OK\x1b[0m ]"
			else
				contenedor=$(virsh shutdown $nombre_maquina_virtual)
				#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
				comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se a apagado [\x1b[1;32m OK\x1b[0m ]"
			fi
		;;
		#REINICIAR MAQUINA
		4)
			echo "/////////////////////////////////////////"
                        echo "        REINICIAR MAQUINA VIRTUAL"
                        echo "/////////////////////////////////////////"

			#COMPROBAR DE QUE TENEMOS MAQUINAS ENCENDIDAS PARA REINICIAR
			comprobar_maquinas_encendidas
			#LISTAMOS LAS MAQUINAS
			virsh list

			read -p "¿Que maquina quieres reiniciar? " nombre_maquina_virtual

			#MIRAR SI EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina_virtual

			contenedor=$(virsh reboot $nombre_maquina_virtual)

			#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
			comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se a reiniciado correctamente [\x1b[1;32m OK\x1b[0m ]"
		;;
		#SUSPENDER O DESPERTAR MAQUINA
		5)
			echo "/////////////////////////////////////////"
                        echo "        SUSPENDER/DESPERTAR MAQUINA"
                        echo "/////////////////////////////////////////"

			#COMPROBAR DE QUE TENEMOS MAQUINAS ENCENDIDAS PARA SUSPENDER O DESPERTAR
                        comprobar_maquinas_encendidas
			#LISTAMOS LAS MAQUINAS
			virsh list

			#PEDIMOS LOS PARAMETROS NECESARIOS
			read -p "¿Que maquina quieres suspender o despertar? " nombre_maquina_virtual

			#MIRAR SI EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina_virtual

			read -p "¿Suspender o Despertar? [S / d] " tipo

			#EJECUTAMOS LA ORDEN
			if [[ $tipo == "D" || $tipo == "d" ]]
			then
				#SI INTENTO DESPERTAR UNA MAQUINA DESPITA DA ERROR, POR ESO ESTE IF
				if [[ `virsh domstate $nombre_maquina_virtual` == "running" ]]
				then
					echo -e " - La maquina virtual $nombre_maquina_virtual se a despertado [\x1b[1;32m OK\x1b[0m ]"
					read -p "Pulse intro para regresar al menu"
					menu
				else
					contenedor=$(virsh resume $nombre_maquina_virtual)
        	                        #COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
	                                comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se a despertado [\x1b[1;32m OK\x1b[0m ]"
				fi
			else
				contenedor=$(virsh suspend $nombre_maquina_virtual)
				#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
				comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se a suspendido [\x1b[1;32m OK\x1b[0m ]"
			fi
		;;
		#INICIAR MAQUINA CUANDO INICIE EL SERVIDOR
		6)
			echo "/////////////////////////////////////////"
                        echo " INICIAR MAQUINA CUANDO INICIE EL SERVIDOR"
                        echo "/////////////////////////////////////////"

			#LISTAMOS LAS MAQUINAS
			virsh list --all

			modo="N"
			#MIRAMOS SI EXISTEN MAQUINAS CON AUTOARRANQUE
			if [[ `ls /etc/libvirt/qemu/autostart/ | cut -d '.' -f 1` != "" ]]
			then
				read -p "¿Quieres quitar el autoencender de alguna maquina? [y / N] " modo
			fi

			if [[ $modo == "Y" || $modo == "y" ]]
			then
				read -p "¿Que maquina quieres quitarle el inicio automatico? " nombre_maquina_virtual

				#COMPROBAR QUE EXISTE LA MAQUINA
				existe_maquina $nombre_maquina_virtual

				contenido=$(virsh autostart $nombre_maquina_virtual --disable)

				echo "NOTA: Si no se quita el autoejecucion de la maquina tendras que eliminar el archivo correspondiente en el directorio /etc/libvirt/qemu/autostart/"
				#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
				comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual ya no se iniciara automaticamente [\x1b[1;32m OK\x1b[0m ]"
			else
				read -p "¿Que maquina quieres iniciar automaticamente? " nombre_maquina_virtual

				#COMPROBAR QUE EXISTE LA MAQUINA
                                existe_maquina $nombre_maquina_virtual

                	        contenido=$(virsh autostart $nombre_maquina_virtual)

        	                #COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
	                        comprobar_ejecucion $? " - La maquina virtual $nombre_maquina_virtual se iniciara automaticamente [\x1b[1;32m OK\x1b[0m ]"
			fi
		;;
		#AÑADIR VOLUMEN
		7)
			echo "/////////////////////////////////////////"
                        echo "              AÑADIR VOLUMEN"
                        echo "/////////////////////////////////////////"

			#POR SI QUEREMOS CREAR UN VOLUMEN
			read -p "¿Quieres crear un volumen? [y / N] " crear_volumen

			if [[ $crear_volumen == "y" || $crear_volumen == "Y" ]]
			then
				read -p "Nombre del volumen: " nombre_volumen
				ruta_volumen="$carpeta_principal/volumenes/"
				echo "- El volumen se guardara en la ruta $carpeta_principal/volumenes/"
				read -p "Tamaño del volumen en GB: [2G] " size_volumen
				#SI NO PUSO EL TAMAÑO LE PONEMOS EL DE POR DEFECTO
				if [[ -z $size_volumen ]]
				then
					size_volumen="2G"
				fi

				#COMPROBAR CAMPOS VACIO
				comprobar_campos_vacios "$nombre_volumen"

				contenedor=$(qemu-img create -f qcow2 $ruta_volumen$nombre_volumen $size_volumen)
				echo "Volumen creado."
			fi

			#LISTAMOS LAS MAQUINAS
                        virsh list --all

			read -p "¿A que maquina quieres añadirle el volumen? " nombre_maquina

			#COMPROBAR QUE EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina

			#EN EL CASO DE QUE SI CREAMOS UN VOLUMEN ANTERIORMENTE QUE NOS DIGA SI QUEREMOS ASOCIARLO
			if [[ $crear_volumen == "y" || $crear_volumen == "Y" ]]
			then
				read -p "¿Quieres añadirle el volumen creado anteriormente? [y / N] " volumen_anterior_anadir

				if [[ $volumen_anterior_anadir == "Y" || $volumen_anterior_anadir == "y" ]]
				then
					#LISTAMOS LOS VOLUMENES ASOCIADOS A LA MAQUINA
                        		virsh domblklist $nombre_maquina
					echo "EL TARGET NO PUEDE ESTAR EN EL LISTADO"
					read -p "Target: [EJ: vdb] " etiqueta

					#COMPROBAR CAMPOS VACIO
                                	comprobar_campos_vacios "$etiqueta"

					contenedor=$(virsh attach-disk $nombre_maquina $ruta_volumen$nombre_volumen $etiqueta --cache none)
					#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
                        		comprobar_ejecucion $? " - Volumen $nombre_volumen asociado a la maquina $nombre_maquina [\x1b[1;32m OK\x1b[0m ]"
				fi
			fi

			read -p "Ruta del volumen para asociar: [$carpeta_principal/volumenes/] " ruta_volumen
                        #MIRAMOS SI INTRODUJO LA RUTA, EN CASO DE NO INTRODUCIRLA LE PONEMOS LA DE POR DEFECTO
			if [[ -z $ruta_volumem ]]
			then
				ruta_volumen="$carpeta_principal/volumenes/"
			fi

			#MIRAMOS SI LA RUTA EXISTE
                        ruta_volumen=$(comprobar_ruta $ruta_volumen)

			#LISTAMOS LOSS ARCHIVOS DE LA RUTA PUESTA ANTERIORMENTE, PARA QUE SEA MAS FACIL PONERLE EL NOMBRE
			echo "---- Archivos que contiene la ruta: $ruta_volumen ----"
			ls $ruta_volumen
			read -p "Nombre del volumen: " nombre_volumen
			#MIRAMOS SI EXISTE EL ARCHIVO VOLUMEN
			comprobar_archivo "$ruta_volumen$nombre_volumen"

			#LISTAMOS LOS VOLUMENES ASOCIADOS A LA MAQUINA
                        virsh domblklist $nombre_maquina
                        echo "NOTA: EL TARGET NO PUEDE ESTAR EN EL LISTADO"
			read -p "Target: [EJ: vdb] " etiqueta

			#COMPROBAR CAMPOS VACIO
                        comprobar_campos_vacios "$etiqueta"

			contenedor=$(virsh attach-disk $nombre_maquina $ruta_volumen$nombre_volumen $etiqueta --cache none)
			#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
			comprobar_ejecucion $? " - Volumen $nombre_volumen asociado a la maquina $nombre_maquina [\x1b[1;32m OK\x1b[0m ]"
		;;
		#QUITAR VOLUMEN ASOCIADO
		8)
			echo "/////////////////////////////////////////"
                        echo "        QUITAR VOLUMEN ASOCIADA"
                        echo "/////////////////////////////////////////"

			#LISTAMOS LAS MAQUINAS
                        virsh list --all

			read -p "Nombre de la maquina para quitarle el volumen: " nombre_maquina

			#COMPROBAR QUE EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina

			#LISTAMOS LOS VOLUMENES ASOCIADOS A LA MAQUINA
			virsh domblklist $nombre_maquina
			echo "NOTA: EL TARGET TIENE QUE ESTAR EN EL LISTADO"
			read -p "Target: [EJ: vdb] " etiqueta

			#COMPROBAR CAMPOS VACIO
                        comprobar_campos_vacios "$etiqueta"

			contenedor=$(virsh detach-disk $nombre_maquina $etiqueta)

			#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
                        comprobar_ejecucion $? " - Volumen con la etiqueta $etiqueta desasociado de la maquina $nombre_maquina [\x1b[1;32m OK\x1b[0m ]"
		;;
		#CONECTARSE A LA MAQUINA
		9)
			echo "/////////////////////////////////////////"
                        echo "        CONECTARSE A LA MAQUINA"
                        echo "/////////////////////////////////////////"

			#COMPROBAR DE QUE TENEMOS MAQUINAS ENCENDIDAS PARA SUSPENDER O DESPERTAR
                        comprobar_maquinas_encendidas
			#LISTAMOS LAS MAQUINAS
                        virsh list

			read -p "¿Que maquina quieres conectarte? " nombre_maquina

			#COMPROBAR QUE EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina

			#USAMOS screen PARA QUE NO NOS QUITE EL TERMINAL
			contenedor=$(screen -d -m virt-viewer $nombre_maquina)

			#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
                        comprobar_ejecucion $? " - Conexion a $nombre_maquina establecida [\x1b[1;32m OK\x1b[0m ]"
		;;
		#INSTANTANEA
		10)
			echo "/////////////////////////////////////////"
                        echo "                INSTANTANEA"
                        echo "/////////////////////////////////////////"
			echo ""
			echo " 1: Crear una instantanea."
			echo " 2: Recuperar una instantanea."
			echo " 3: Eliminar una instantanea"
			echo " 4: Informacion de una instantanea"

			read -p "---> " realizar

			#LISTAMOS LAS MAQUINAS
			virsh list --all

			read -p "¿Que maquina? " nombre_maquina
			#COMPROBAR QUE EXISTE LA MAQUINA
                        existe_maquina $nombre_maquina

			#LISTAMOS LAS INSTANTANEAS DE LA MAQUINA
                        virsh snapshot-list $nombre_maquina

			case $realizar in
				#CREAR UNA INSTANTANEA
				1)
					read -p "Titulo de la instantanea: " titulo_instantanea
					#COMPROBAR CAMPOS VACIO
                        		comprobar_campos_vacios "$titulo_instantanea"
					read -p "Descripcion: " descripcion_instantanea

					contenedor=$(virsh snapshot-create-as --domain $nombre_maquina --name $titulo_instantanea --description "$descripcion_instantanea")
					#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
                        		comprobar_ejecucion $? " - La instantanea de la maquina $nombre_maquina se creo con exito [\x1b[1;32m OK\x1b[0m ]"
				;;
				#RECUPERAR UNA INSTANTANEA
				2)
					read -p "Titulo de la instantanea para recuperar: " titulo_instantanea_recuperar
					contenedor=$(virsh snapshot-revert $nombre_maquina $titulo_instantanea_recuperar)

					#COMPROBAMOS SI SE A EJECUTADO EL COMANDO CORRECTAMENTE
                                	comprobar_ejecucion $? " - La maquina $nombre_maquina se recupero con exito [\x1b[1;32m OK\x1b[0m ]"
				;;
				#ELIMINAR UNA INSTANTANEA
				3)
					read -p "Titulo de la instantanea que quieres eliminar: " titulo_instantanea_eliminar

					read -p "¿Seguro que quieres eliminar la instantanea?: [Y / n]" aviso
					if [[ $aviso == "n" || $aviso == "N" ]]
					then
						echo -e "\x1b[1;31m INSTANTANEA NO ELIMINADA. \x1b[0m"
                        			read -p "Pulse un boton para regresar al menu"
                        			menu
					fi

					contenedor=$(virsh snapshot-delete --domain $nombre_maquina --snapshotname $titulo_instantanea_eliminar)
					comprobar_ejecucion $? " - La instantanea $titulo_instantanea_eliminar se elimino correctamente [\x1b[1;32m OK\x1b[0m ]"
				;;
				#INFORMACION DE UNA INSTANTANEA
				4)
					read -p "Titulo de la instantanea: " titulo_instantanea_info

					virsh snapshot-info --domain $nombre_maquina --snapshotname $titulo_instantanea_info
					read -p "Pulse un boton para regresar al menu"
                                        menu
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

#LLAMAMOS A LA FUNCION MENU
comprobar_carpetas_requeridas
menu





