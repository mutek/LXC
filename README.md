# LXC
stuff related to LXC

* il costruttore si preoccupa di costruire LXC a partire dai sorgenti
* richiede un sistema bootstrap
* il sistema di bootstrap potrebbe essere un container momentaneo fornito dalla macchina host

prima ipotesi:

Costruttore lavora in ambiente Ubuntu

questo permette di autoconfigurare la rete con gli autoscript di Canonical e concentrarsi sul container

seconda ipotesi

Costruttore lavora in Debian generico

un init script si preoccupa di svolgere tutte le valutazioni di merito riguardo la rete, il bridge, il packet filter, ... ed esegue azioni conseguenti


