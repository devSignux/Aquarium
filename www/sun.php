<?php
//       date_default_timezone_set('Europe/Berlin');
	date_default_timezone_set('GMT-1');
	$now = time();
	$gmt_offset = 1;   // Unterschied von GMT zur eigenen Zeitzone in Stunden.
	$zenith = 90+50/60;

	$sunset = date_sunset($now, SUNFUNCS_RET_TIMESTAMP, 51.345131, 12.381670, $zenith, $gmt_offset);
	$sunrise = date_sunrise($now, SUNFUNCS_RET_TIMESTAMP, 51.345131, 12.381670, $zenith, $gmt_offset);

	echo "sunrise=".date("H:i",$sunrise).";";
	echo "sunset=".date("H:i",$sunset);
?>
