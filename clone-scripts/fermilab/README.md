# Fermilab clone scripts

These clone scripts deploy:

* Connected (FUEL)
* Disconnected (FUEL)
* Decay (FUEL)
* I2 Wall (FUEL)
* Coulomb Gauge fixing (FUEL)
* Coulomb Gauge fixing (ESW hacked GLU, ds only)

On an ensemble by ensemble basis. This includes the (in some cases hacked) parse scripts, as well as the measurement lua files, and the submit scripts.

I suggest setting the following permissions for these files:
* Directories: chmod 775, chmod g+s
* Files: chmod 775 for parse.\* scripts, 664 otherwise. 

The Connected, disconnected, decay, and coulomb lua files were written by me. The I2 wall scripts were written by Andrew Gasbarro. The submit scripts are based on scripts by Oliver Witzel.

These scripts come without guarantee, promise, or sanity (for the time being). Please contact Evan Weinberg (evansweinberg@gmail.com) with any questions.

