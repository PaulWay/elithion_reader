# elithion_reader

A Perl program to log the output of the eLithion Lithiumate Lite
battery management system.

Written by Paul Wayper.

## The eLithion Lithiumate Lite

The [eLithion](http://elithion.com)
[Lithiumate Lite](http://elithion.com/lithiumate__lite.php)
is a full-featured digital battery management system for Lithium
batteries.  It monitors the voltage and other statistics on every cell
in the battery and controls the charging and discharging of the
battery to preserve and increase the battery life.  It also provides
a number of fairly simple outputs of battery status, from warnings for
over-charging and over-discharging to detecting other fault conditions.

It interfaces with a PC running Windows using eLithion's custom
software.

## What I'm trying to do

Unfortunately for me, I have several problems with monitoring the
Lithiumate Lite in its default setup.

1. The software only runs on Windows.  At the moment, with upgrades to
   .NET components, the software crashes immediately upon start-up with
   no way of recovering or diagnosing.  This makes getting any more
   information out of it difficult.

2. To monitor the battery you have to run the software on a machine
   directly connected to the BMS via USB cable.  In a car installation 
   this would be no problem.  On a motorbike, this would at the very 
   least require sticking the laptop in a backpack and tethering it and
   myself to the bike.

3. I run Linux for the most part.  I have to keep a separate laptop
   running an outdated version of Windows specifically for the eLithion
   software.  Now that doesn't work, and my desire to debug Windows
   problems is very low.

On the other hand, the USB connection to the Lithiumate Lite appears as
a standard RS-232 serial port.  Connecting a standard serial program
such as `minicom` gives the user a text-mode interface to the battery
management system.  This includes giving compact, machine readable 
outputs of various systems data.  With a compact machine such as the
Raspberry Pi running of a simple 12 volt to USB converter, it's possible
now to record the Lithiumate Lite's output in real time.

So my objectives are basically:

* Log the output of the BMS when it's powered up for charging or
  running.

* Store this data in convenient datestamped CSV files.

* When in range of my WiFi (i.e. it has an IP address), attempt to ssh
  to my home server and upload the files via `rsync`.

# References

## Serial communications with the Lithiumate Lite

eLithion Lithumate serial communications set-up documentation:

* http://lithiumate.elithion.com/php/install_serialcomm.php

Lithiumate serial status menu documentation:

* http://lithiumate.elithion.com/php/menu_status.php#Cells

* http://lithiumate.elithion.com/php/menu_setup.php#RS232_dump

Lithiumate RS-232 dump documentation:

* http://lithiumate.elithion.com/php/rs232_specs.php#RS232_dump
