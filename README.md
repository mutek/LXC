# LXC
stuff related to LXC

* il costruttore si preoccupa di costruire LXC a partire dai sorgenti
* richiede un sistema bootstrap
* il sistema di bootstrap potrebbe essere un container momentaneo fornito dalla macchina host


Costruttore lavora in Debian generico (testato wheezy,jessie)

un init script si preoccupa di svolgere tutte le valutazioni di merito riguardo la rete, il bridge, il packet filter, ... ed esegue azioni conseguenti


