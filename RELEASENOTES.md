# Releasenotes

## v2.03.6
* Install stop script into `/usr/local/bin/`, so outside of Edomi location. With that change the script exists even after backup import from native Edomi installation, where that script does not exist.
* Update node exporter from 1.4.0 to 1.5.0

## v2.03.5
* Replace obsolete IP of Edomi update site with edomi.de
* Streamline version with Docker image

## v2.03.3
* Apply missing mariadb configuration entries

## v2.03.2
* Container basiert auf RockyLinux 8

## v2.03.1
* Löschen des Konfigurationseintrages global_serverIP am Ende der Template-Erstellung, damit die jeweils konfigurierte IP von Edomi beim Start automatisch ermittelt wird.

## v2.03
* Edomi 2.03
* Container basiert auf offiziellem Proxmox CentOS 7 Template
* PHP 7.4 mit den folgenden Paketen:
  *  php
  *  php-curl
  *  php-gd
  *  php-json
  *  php-mbstring
  *  php-mysql
  *  php-process
  *  php-snmp
  *  php-soap
  *  php-ssh2
  *  php-xml
  *  php-zip
* Es ist eine ganze Reihe zusätzlicher Pakete für Userland-LBS'e bereits vorab installiert. Namentlich für die folgenden Bausteine:
  * Die Telegram-Bausteine (19000303, 19000304, 19000645)
  * Philips HUE Bridge 19000195
  * Mailer-LBS (19000587)
  * Mosquitto- resp. MQTT-LBS (19001051-54, 19001198)
  * Alexa Control 19000809
* Achtung: Die Requirements für den MikroTik-LBS (19001059) sind nicht mehr enthalten, da sie das Image um über 600M aufblähen!
* ssh ist aktiviert, der Login mit dem beim Setup vergebenen root-Passwort funktioniert
* Shutdown auch via ProxMox möglich, implementiert nach diesem Script.

# Installation:
* Archiv aus der Release-Area herunterladen
* Auf ProxMox:
  * gewünschten Storage auswählen
  * auf Upload klicken
  * Content Container template einstellen
  * Archiv auswählen
  * hochladen
  * Neuen Container erstellen
  * Unprivileged ist ok
  * CPU, Memory, Disk, Netzwerk nach eigenen Bedürfnissen
  * Nach dem Anlegen des Containers unter Options den Console mode auf console bzw. /dev/console stellen
  * Ggf. muss die Zeitzone angepasst werden. Dazu auf die Konsole wechseln oder per ssh im Container einloggen und folgenden Befehl ausführen:
Code:
```timedatectl set-timezone Europe/Berlin```
Wird der Container nun gestartet, startet direkt auch Edomi und ist unter http://<ip>/admin zu erreichen.