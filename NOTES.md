# Notes on the BMS

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



