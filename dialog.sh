#!/bin/bash

############################################################################################
############################################################################################
#######################################   Диалог  ##########################################
############################################################################################
############################################################################################

echo "     "
echo "           Для дальнейшей работы нужно установить пакет dialog"
echo "           Для установки пакета нужен доступ в интернет"
echo "     "
#sleep 3s
#apt -y install dialog
echo "     "
dpkg -l > /tmp/dpkgl
    if grep whiptail /tmp/dpkgl
        then
            echo "Пакет Dialog установлен. Продолжение..."
        else
            echo "Пакет Dialod не установлен. Проверьте подключение к интернету и ошибки установок. Выход"
#            sleep 2s
#            exit
    fi

#sleep 3s
#Основной диалог
    if (whiptail --title "Настройка Proxmox VE 5.x" --yesno "Это скрипт послеустановочной донастройки Proxmox 5.0 \n
        Скрипт автоматически настроит конфигурацию системы. \n
        ВНИМАНИЕ! Для установки пакетов нужно подключение к интернету! \n
        ВНИМАНИЕ! Первоочередно, скрипт расчитан на настройку свежеустановленной Proxmox VE 5.0! \n
        Вы уверены что хотите продолжить?" 40 80)
        then
            echo "Переход к настройке системе."
        else
            echo "Выход."
            exit
    fi


MAINCONFIG=$(whiptail --title "Конфигурация Proxmox VE 5.x" --checklist \
"Выберите необходимые действия (минимальные включены по умолчанию)" 20 80 11 \
"1" "Добавление и обновление репозиторий" OFF \
"2" "Установка обязательных пакетов" OFF \
"3" "Установка обновлений (dist-upgrade)" OFF \
"4" "Настройка SWAPPINESS" OFF \
"5" "Настройка хранилища данных виртуальных машин" OFF \
"6" "Настройка GRUB для именования сетевых интерфейсов по старинке" OFF \
"7" "Автонастройка и переименование сетевых интерфейсов" OFF \
"8" "Установка Zabbix и мод-скриптов" OFF \
"9" "Установка FTP-сервера и хранилища" OFF \
"10" "Правка интерфейса" OFF \
"11" "Установка оболочки и окружения" OFF 3>&1 1>&2 2>&3)
exitstatus=$?

    if [ $exitstatus = 0 ];
        then
            echo $MAINCONFIG > /tmp/configpxmx.tmp
        else
            echo "Вы выбрали отмену."
    fi


    if echo $MAINCONFIG | grep -w 10
        then
            XORGCONFIG=$(whiptail --title "Конфигурация оболчки Proxmox VE 5.x" --checklist \
            "Выберите необходимые действия" 15 60 6 \
            "1" "Установка XFCE" OFF \
            "2" "Установка LXDE" OFF \
            "3" "Установка MATE" OFF \
            "4" "Настройка RDESKTOP" ON 3>&1 1>&2 2>&3)
            exitstatus=$?
                if [ $exitstatus = 0 ];
                    then
                        echo $XORGCONFIG > /tmp/configpxmx_X.tmp
                    else
                        echo "Вы выбрали отмену."
                fi


    fi
#################################  УДАЛИТЬ строку ниже, нужна только для наглядности
cat /tmp/configpxmx.tmp



############################################################################################
############################################################################################
##################################     ФУНКЦИИ    ##########################################
############################################################################################
############################################################################################

function repo # №1.  Добавление и обновление репозиторий
    {
        cat /dev/null > /etc/apt/sources.list.d/pve-enterprise.list
        echo "deb [arch=amd64] http://download.proxmox.com/debian/pve stretch pve-no-subscription" >> /etc/apt/sources.list
        apt update
    }


function packages # №2. Установка пакетов
    {
        apt -y install mc sudo parted screen ethtool itop htop smartmontools lm-sensors net-tools
    }


function upgrade # №3. Обновление системы
    {
        apt -y dist-upgrade
    }

function swappinnes #4. Настройка SWAPPINESS
    {
    memtotal=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')        #Значение общей памяти системы
    sys_swap=$(grep vm.swappiness /etc/sysctl.conf | awk '{print $3}')      #Значение срабатывания SWAP в sysctl
    smallmem=4194304                                                        #Маленькая память равна 4 Гб
    mediummem=8388608                                                       #Средняя память равно 8 Гб
    bigmem=16777216                                                         #Большая память равна 16 Гб

function swappinnes_check
        {
        #Проверка и исправление параметра swappiness
        #Если ОЗУ системы меньше 4 Гб, и если значение vm.swap в sysctl не равно 60, то исправляет значение на 60 и применяет его.
        if (($memtotal <= $smallmem))
            then
                if [ $sys_swap -ne 60 ]
                    then
                        sed '/swappiness/d' '/etc/sysctl.conf' > /tmp/sysctl.conf
                        cp /tmp/sysctl.conf /etc/sysctl.conf
                        echo "vm.swappiness = 60" >> /etc/sysctl.conf
                        sysctl -p
                fi
        fi


        #Если ОЗУ системы больше 4 Гб и меньше или равно 8 Гб, и если значение vm.swap в sysctl не равно 40, то исправляет значение на 40 и применяет его.
        if (($memtotal > $smallmem)) && (($memtotal <= $mediummem))
            then
                if [ $sys_swap -ne 40 ]
                    then
                        sed '/swappiness/d' '/etc/sysctl.conf' > /tmp/sysctl.conf
                        cp /tmp/sysctl.conf /etc/sysctl.conf
                        echo "vm.swappiness = 40" >> /etc/sysctl.conf
                        sysctl -p
                fi
        fi


        #Если ОЗУ системы больше 8 Гб и меньше или равно 16 Гб, и если значение vm.swap в sysctl не равно 15, то то исправляет значение на 15 и применяет его.
        if (($memtotal > $mediummem)) && (($memtotal <= $bigmem))
            then
                if [ $sys_swap -ne 15 ]
                    then
                        sed '/swappiness/d' '/etc/sysctl.conf' > /tmp/sysctl.conf
                        cp /tmp/sysctl.conf /etc/sysctl.conf
                        echo "vm.swappiness = 15" >> /etc/sysctl.conf
                        sysctl -p
                fi
        fi


        #Если ОЗУ системы больше 16 Гб и если значение vm.swap в sysctl не равно 10, то исправляет значение на 10 и применяет его.
        if (($memtotal > $bigmem))
            then
                if [ $sys_swap -ne 10 ]
                    then
                        sed '/swappiness/d' '/etc/sysctl.conf' > /tmp/sysctl.conf
                        cp /tmp/sysctl.conf /etc/sysctl.conf
                        echo "vm.swappiness = 10" >> /etc/sysctl.conf
                        sysctl -p
                fi
        fi

        }


function swappinnes_config
        {

        # Конфигурирование swappiness
        #Настройка swappiness, если sysctl еще не растроен, для памяти меньше или равной 4Гб
        if (($memtotal <= $smallmem))
            then
                echo "vm.swappiness = 60" >> /etc/sysctl.conf
                sysctl -p
        fi

        #Настройка swappiness, если sysctl еще не растроен, для памяти больше 4Гб и меньше 8Гб
        if (($memtotal > $smallmem)) && (($memtotal <= $mediummem))
            then
                echo "vm.swappiness = 40" >> /etc/sysctl.conf
                sysctl -p
        fi

        #Настройка swappiness, если sysctl еще не растроен, для памяти больше 8Гб и меньше 16Гб
        if (($memtotal > $mediummem)) && (($memtotal <= $bigmem))
            then
                echo "vm.swappiness = 15" >> /etc/sysctl.conf
                sysctl -p
        fi

        #Настройка swappiness, если sysctl еще не растроен, для памяти больше 16Гб
        if (($memtotal > $bigmem))
            then
                echo "vm.swappiness = 10" >> /etc/sysctl.conf
                sysctl -p
        fi

        }



        # Проверка есть ли строка со значением vm.swappiness в syscrl.conf
        if grep vm.swappiness /etc/sysctl.conf > /dev/nul
            then swappinnes_check                            #Если есть то проверяем как настроен параметр swappiness, переход в функцию
            else swappinnes_config                           #Иначе (если нету) то сразу настраиваем, переход в функцию
        fi


    }


function data_storage # №5. Настройка хранилища
    {

STORCONFIG=$(whiptail --title "Настройка хранилища виртуальных машин" --checklist \
            "Выберите необходимые действия" 15 60 6 \
            "1" "Удалить созданный по умолчанию LVM-Thin раздел для данных и настроить новый" OFF \
            "2" "Расширить имеющийся LVM-Thin раздел" OFF \
            "3" "Оставить без измений. Или нажмите 'Отмена'" OFF 3>&1 1>&2 2>&3)
            exitstatus=$?
                if [ $exitstatus = 0 ];
                    then
                        echo $STORCONFIG > /tmp/configpxmx_5.tmp
                    else
                        echo "Вы выбрали отмену blablala."
                fi


if echo $STORCONFIG | grep 1
    then
LVM_date=$(lvdisplay | grep data -A10 | grep time | cut -d "," -f3)
LVM_size=$(lvdisplay | grep data -A10 | grep "LV Size" | awk '{print $ 3}')
        if (whiptail --title "Удаление LVM-Thin и настройка нового раздела VZ" --yesno "Вы точно хотите удалить LVM раздел /dev/pve/data \n
Раздел создан $LVM_date \n
И имеет размер $LVM_size Гб \n
Перед удалением, раздел будет отмонтирован из хранилища Proxmox"  20 60)
            then
                cp /tmp/FPPIC/storage.cgf /etc/pve/storage.cgf
                lvremove -y /dev/pve/data
                echo "asdasd"
            else
                echo "Отмена. и Блаблабал"
        fi
fi

    }





############################################################################################
############################################################################################
##############################     Основной скрипт    ######################################
############################################################################################
############################################################################################








################ Добавление и обновление репозиторий
if echo $MAINCONFIG | grep -w 1
    then
cat /dev/null > /etc/apt/sources.list.d/pve-enterprise.list
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve stretch pve-no-subscription" >> /etc/apt/sources.list
apt update
fi

################ Установка пакетов
if echo $MAINCONFIG | grep -w 2
    then
apt -y install mc sudo parted screen ethtool itop htop smartmontools lm-sensors net-tools
fi

################ Обновление системы

if echo $MAINCONFIG | grep -w 3
    then
apt -y dist-upgrade
fi

################ Настройка swappiness

if echo $MAINCONFIG | grep -w 4
    then echo 0
fi

################ Настройка swappiness

if echo $MAINCONFIG | grep -w 5
    then data_storage
fi
