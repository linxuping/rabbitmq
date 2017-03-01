
function send_sms()
{
	cd /home/xp/monitor
	python ppsms.py "12341234123" $1
}

function try_start()
{
	path=$1
	process=$2
	ps auxf | grep "./"$process | grep -v grep
	if [ $? != 0 ] 
	then
		cd $path
		("./"$process 2>>/tmp/$process.err.log &)
	else
		#echo "process exist... ..."
		return
	fi
	sleep 2

	#check again.
	ps auxf | grep "./"$process | grep -v grep
	if [ $? != 0 ] 
	then
		send_sms $2"刚才挂了，重启无效，赶快去看下吧[19]"
	else
		send_sms $2"刚才挂了，已经被正常重启[19]"
	fi
}

try_start "/home/xp/monitor" "heartbeat.sh"
try_start "/home/xp/queue_server" "queue_server"
try_start "/home/xp/monitor/rmq_get" "rmq_get_monitor.sh"
try_start "/home/xp/monitor/rmq_publish" "rmq_monitor.sh"
try_start "/home/xp/videos_upload/ffmpeg/business" "videos_download1.sh"


#echo "finish. "


