# Aquarium
Aquariumsteuerung mittels Onion Omega und USB-Steckdosenleiste

Zutaten:
- Onion Omega
- Onion Omega Expansion Dock
- USB-Netzteil 1,4A
- 4x Usb-Hub (passiv)
- GEMBIRD EG-PMS2 (http://www.gembird.com/item.aspx?id=7415) USB-Steckdosenleiste
- Aquarium Filter
- Aquarium Heizung
- Aquarium Licht
- 3 Temperatursensoren mit DS18s20 sensor (https://www.conrad.de/de/c-control-temperatursensor-ds18s20-passend-fuer-serie-c-control-198284.html) 
- Wiederstand 4kOhm
- Kabel
- Logitec c270 Webcam

Short Startup(unvollständig):

1. OpenWrt sourcen downloaden (git clone git://git.openwrt.org/openwrt.git)
2. .config laden (make menuconfig)
3. bauen (make)
4. image auf Omega laden
5. Omega starten
6. Configs einspielen
7. aquarium.sh nach /root kopieren
8. Neustarten und hoffen das alles geht...
 