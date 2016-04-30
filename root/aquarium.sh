allStatus=/tmp/sispmctl.status
sis=/usr/bin/sispmctl
MinTemp=19
MaxTemp=23
sunInfo=/tmp/sun.info

if [ ! -f $sunInfo ] ; then
	/root/createSunInfo.sh
fi
SunCommand=`cat $sunInfo`

if [ ! -f $allStatus ] ; then
	/usr/bin/sispmctl -g all > $allStatus
fi

# aktuelles Datum einlesen
Date=`/bin/date +"%d.%m.%Y %H:%M"`
CurrentHour=`echo $Date | cut -f1 -d":" | cut -f2 -d" "`
CurrentMinute=`echo $Date | cut -f2 -d":"`

AufgangStunde=`echo $SunCommand | cut -f1 -d";" | cut -f2 -d"=" | cut -f1 -d":" | sed -e 's/^0*//'`
AufgangMinute=`echo $SunCommand | cut -f1 -d";" | cut -f2 -d"=" | cut -f2 -d":" | sed -e 's/^0*//'`
UntergangStunde=`echo $SunCommand | cut -f2 -d";" | cut -f2 -d"=" | cut -f1 -d":" | sed -e 's/^0*//'`
UntergangMinute=`echo $SunCommand | cut -f2 -d";" | cut -f2 -d"=" | cut -f2 -d":" | sed -e 's/^0*//'`

###########################################################################################
# bestimmen ob Nacht ist
###########################################################################################

#echo "CH:$CurrentHour,CM:$CurrentMinute,US:$UntergangStunde,UM:$UntergangMinute,AS:$AufgangStunde,AM:$AufgangMinute"
if ( ( [ $CurrentHour -gt $UntergangStunde ] || ( [ $CurrentHour -eq $UntergangStunde ] && [ $CurrentMinute -gt $UntergangMinute ] ) ) || ( [ $CurrentHour -lt $AufgangStunde ] || ( [ $CurrentHour -eq $AufgangStunde ] && [ $CurrentMinute -lt $AufgangMinute ] ) ) ) ; then
	Nacht=true
else
	Nacht=false
fi

PowerFilter=`cat $allStatus | grep "outlet 1" | awk '{print $5}'`
PowerHeizung=`cat $allStatus | grep "outlet 2" | awk '{print $5}'`
PowerLight=`cat $allStatus | grep "outlet 3" | awk '{print $5}'`
PowerLed=`cat $allStatus | grep "outlet 4" | awk '{print $5}'`

###########################################################################################
# Heizung aktivieren:
# - wenn Temperatur < sollTemp
#   und ( Nacht aus oder temperatur < MinTemp )
#   und tempRaum < MaxTemp
#   und tempBalkon < 18 
# Heizung deaktivieren:
# - wenn keine Nacht 
#   und Temperatur > $MaxTemp Grad ist
#   oder
# - wenn Nacht an und Temperatur > $MinTemp Grad ist
# - wenn tempRaum grosser als temp ist
# - wenn $tempBalkon > 20 Grad ist
###########################################################################################

# aktuelle Temperatur einlesen
tempAquarium=`cat /sys/devices/w1_bus_master1/10-00080224de58/w1_slave | grep t= | cut -f2 -d=`
temp=`expr $tempAquarium / 1000`

tempRaum=`cat /sys/devices/w1_bus_master1/10-0008028a9d94/w1_slave | grep t= | cut -f2 -d=`
tempRaum=`expr $tempRaum / 1000`

tempBalkon=`cat /sys/devices/w1_bus_master1/10-000802ab2561/w1_slave | grep t= | cut -f2 -d=`
tempBalkon=`expr $tempBalkon / 1000`

RAD=$(echo "scale=10; a(1)/45" | bc -l)
Winkel=`echo "($CurrentHour*60+$CurrentMinute)*0.125" | bc -l`
sollTemp=`echo "($MinTemp+(($MaxTemp-$MinTemp)*s($Winkel*$RAD)))*1000" | bc -l | cut -f1 -d"."`

echo "Winkel=$Winkel sollTemp=$sollTemp tempAquarium=$tempAquarium"

if [ $tempAquarium -gt 0 ] ; then
#	echo "1"
	if [ "$PowerHeizung" = "off" ] && ( [ $tempAquarium -lt $sollTemp ] && ( [ "$Nacht" = "false" ] || [ $temp -lt $MinTemp ] ) ) && [ $tempRaum -lt $MaxTemp ] && [ $tempBalkon -lt 18 ] ; then
		$sis -q -o 2
		PowerHeizung=on
#		echo "1.1"
	else 
#		echo "1.2"
		if [ "$PowerHeizung" = "on" ] && ( ( [ "$Nacht" = "false" ] && [ $tempAquarium -gt $sollTemp ] ) || ( [ "$Nacht" = "true" ] && [ $temp -gt $MinTemp ] ) || ( [ $tempRaum -gt $MaxTemp ] && [ $temp -lt $tempRaum ] ) || [ $tempBalkon -gt 18 ] ) ; then
			$sis -q -f 2
			PowerHeizung=off
#			echo "1.2.1"
		fi
	fi
fi

##########################################################################################
# Filter aktivieren:
# - wenn Heizung an und Nacht an
# oder
# - wenn Nacht aus und sp?ter als 7Uhr und fr?her als 22Uhr
# Filter deaktivieren:
# - wenn Heisung aus und Nacht an
# oder
# - wenn Nacht aus und spaeter als 22Uhr und fueher als 7Uhr 
##########################################################################################

if [ "$PowerFilter" = "off" ] && ( ( [ "$PowerHeizung" = "on" ] && [ "$Nacht" = "true" ] ) || ( [ "$Nacht" = "false" ] && [ $CurrentHour -gt 6 ] && [ $CurrentHour -lt 22 ] ) ) ; then
	$sis -q -o 1
else
	if [ "$PowerFilter" = "on" ] && ( ( [ "$PowerHeizung" = "off" ] && [ "$Nacht" = "true" ] ) || ( [ "$Nacht" = "false" ] && ( [ $CurrentHour -gt 21 ] || [ $CurrentHour -lt 7 ] ) ) ) ; then
		$sis -q -f 1
	fi
fi

helligkeit=0
if [ $CurrentHour -gt 9 ] && [ $CurrentHour -lt 14 ] ; then
	webcamFile=/tmp/lastWebcam.jpg
	/usr/bin/fswebcam $webcamFile --no-banner -r 800x600 -q > /dev/null 2>&1
	cropFile=/tmp/cropWebcam.jpg
	
	if [ -f $webcamFile ] ; then
		/usr/bin/jpegtran -crop 180x60+280+150 -grayscale -outfile $cropFile $webcamFile
		rm $webcamFile
		helligkeit=`ls -l $cropFile | awk '{print $5}'`
		rm $cropFile
	fi
fi
echo $helligkeit > /tmp/helligkeit.log

#########################################################################################
# Licht zwischen 10 und 14 uhr aktivieren
#########################################################################################
if [ "$PowerLight" = "off" ] && [ $CurrentHour -gt 9 ] && [ $CurrentHour -lt 14 ] ; then
	$sis -q -o 3
else
	if [ "$PowerLight" = "on" ] && ( [ $CurrentHour -lt 10 ] || [ $CurrentHour -gt 13 ] ) ; then
		$sis -q -f 3
	fi
fi 

########################################################################################
# aktuellen status der Stromanschluesse ablegen
########################################################################################
/usr/bin/sispmctl -g all > $allStatus

#debug=true

if [ $debug ]; then
	echo "Datum: $Date"
	echo "Stunde: $CurrentHour"
	echo "Minute: $CurrentMinute"
	echo "AufStunde: $AufgangStunde"
	echo "AufMinute: $AufgangMinute"
	echo "UnStunde: $UntergangStunde"
	echo "UnMinute: $UntergangMinute"
	echo "tempAquarium: $tempAquarium"
	echo "temp: $temp"
	echo "tempRaum: $tempRaum"
	echo "tempBalkon: $tempBalkon"
	echo "RAD: $RAD"
	echo "Winkel: $Winkel"
	echo "sollTemp: $sollTemp"
	echo "Filter: $PowerFilter"
	echo "Heizung: $PowerHeizung"
	echo "Licht: $PowerLight"
	echo "LED: $PowerLed"
	echo "Nach: $Nacht"
	echo "Helligkeit: $helligkeit"
fi
