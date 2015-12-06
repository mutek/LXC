#!/usr/bin/env sh
### BEGIN INIT INFO
# Provides:          avvia-seafile.sh
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs
# Default-Start:     1 2 3 4 5
# Default-Stop:
# Short-Description: Avvia Seafile Server
# Description:       Avvia Seafile Server
### END INIT INFO



start_seafile_server () {

sleep 15

/opt/SeafileServer4.4.6/seafile.sh start

sleep 10

/opt/SeafileServer4.4.6/seahub.sh start-fastcgi

}

stop_seafile_server () {

/opt/SeafileServer4.4.6/seafile.sh stop
sleep 5
/opt/SeafileServer4.4.6/seahub.sh stop
sleep 5

}



restart_seafile_server () {
    stop_seafile_server;
    sleep 5
    start_seafile_server;
}


case $1 in
    "start" )
        start_seafile_server;
        ;;
    "stop" )
        stop_seafile_server;
        ;;
    "restart" )
        restart_seafile_server;
esac

echo "Done."

