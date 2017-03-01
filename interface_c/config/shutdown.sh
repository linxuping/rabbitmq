echo `date`"shutdown" >> /home/install/keepalived-1.2.17/keepalived_shutdown.log
service keepalived stop
sleep 4
service keepalived start
