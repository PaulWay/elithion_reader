# Notes on the BMS

## Power

The Lithiumate Lite has two ways of being powered: either when being 
charged or when in use.  These two are mutually exclusive - so that the 
BMS can disable discharging (i.e moving the vehicle) when it's being 
charged, preventing you pulling the charger out of the ground.
Separate wires provide power when the ignition is turned on, which
informs the BMS that the vehicle is allowed to use but also disabling
the use of resistive balancing on the battery (to save traction power).

Because the BMS provides a serial port over USB, what this means is
that the serial port will disappear every time the BMS is turned off,
and reappear when the BMS gets power again.

## Serial communication

Once you've got a serial connection to the BMS, pressing enter or the
space bar will get you to the main menu.  From there you can use the
number keys to navigate the menus and see various outputs from the
BMS, as a handy replacement for the Windows console.  However, most of
these will revert to the main menu after a while.

However, hidden inside this is a second access method.  Pressing some
of the letter keys gets data from the BMS in a form easy to read by a
program:

* 'q' = ? (probably quick statistics)
* 'r' = probably the resistance measured across each cell.
* 's' = ? (probably detailed statistics)
* 't' = probably the temperatures of each cell board.
* 'v' = the voltages of each cell.
* 'x' = ?

Each of these outputs looks roughly like this:

`|q0505005D009CFD|`

My way of decoding this is:

* `|` - start delimiter.
* `q` - type of data.
* `05` - five values to follow.
* `05005D009C` - the five data values in hex formatn.
* `FD` - a checksum.
