#!/usr/local/bin/python
# -*- coding: utf-8 -*-  
import os
import sys
import commands
import json
import time
import pika
import threading
import ppsms
import yaml
g_config = yaml.load(file("rmq_monitor.yaml"))

class RMQ_Manager:
	def __init__(self):
		self.initconn()
	def initconn(self):
		credentials = pika.PlainCredentials('tei', 'tei')
		connection = pika.BlockingConnection(pika.ConnectionParameters(host='local.rabbitmq', credentials=credentials))
		self.channel = connection.channel() 
		self.declare()
	def declare(self):
		self.channel.exchange_declare(exchange='monitor',type='topic')
		self.channel.queue_declare(queue='alarm_sms', durable=True, exclusive=False, auto_delete=False, arguments={"x-max-priority":10})
		self.channel.queue_bind(exchange='monitor', queue='alarm_sms', routing_key="alarm_sms")
	def send(self, msg):
		self.channel.basic_publish(exchange='monitor',routing_key='alarm_sms',body=msg,
			properties=pika.BasicProperties(
			delivery_mode=2,priority=5, # make message persistent
		))
	def dispatch(self):
		pass
 

class Alarm_SMS(RMQ_Manager):
	def __init__(self):
		RMQ_Manager.__init__(self)
	def dispatch(self):
		queues_old = []
		qobjs = {}
		while 1: #blocked reactor
			global g_config
			g_config = yaml.load(file("rmq_monitor.yaml"))
			for que in g_config["queues"]:
				if que not in queues_old:
					rgchecker = RMQ_GET_Checker(que)
					rgchecker.start()
					qobjs[que] = rgchecker
			for que in queues_old:
				if que not in g_config["queues"] and que in qobjs:
					qobjs[que].stop()

			try:
				self.declare()
				r = self.channel.basic_get(queue="alarm_sms", no_ack=False) #0
				if r[0] != None:
					self.channel.basic_nack(delivery_tag=r[0].delivery_tag, multiple=False, requeue=False)
					print "send sms:  ",r[-1]#, r[0].delivery_tag
					for pnum in g_config["phones"]:
						ppsms.request_sms(pnum,r[-1])#, r[0].delivery_tag
			except:
				os.system("echo \"%s, reconn\" >> /tmp/monitor.log"%( str(sys.exc_info()) ) )
				self.initconn()
			queues_old = g_config["queues"]
			time.sleep(5)
g_rmq_mgr = Alarm_SMS()


class RMQ_GET_Checker(threading.Thread):
	def __init__(self, queue):
		threading.Thread.__init__(self)
		self.m_queue = queue
		self.m_del_get = 0
		self.m_url_queue_info = r"curl -i -u guest:guest http://local.rabbitmq:5673/api/queues/%2f/"+queue
		self.thread_stop = False
	def run(self):
		print "%s start."%self.m_queue
		last_failed = False
		while 1:
				#print "new start.%s "%self.m_queue
				if self.thread_stop:
					print "%s stop."%self.m_queue
					break
				is_get = False
				qlen = 0
				for i in range(int(g_config["tseg"]/g_config["tavg"])):
						if self.thread_stop:
							is_get = True
							break
						try:
								status,output = commands.getstatusoutput(self.m_url_queue_info)
								if status != 0:
									ts = time.localtime()
									logstr = "[%d%d%d_%d:%d:%d] status:%d output:%s"%(ts[0],ts[1],ts[2],ts[3],ts[4],ts[5],status,output)
									os.system("echo \"%s\" >> /tmp/monitor.log"%(logstr) )
									continue
								data = '{'+output.split("{",1)[1]
								jobj = json.loads(data)
								del_get = jobj['message_stats']['deliver_get']
								qlen = jobj['messages']
								#if 0!=self.m_del_get and qlen!=0 and self.m_del_get!=del_get:
								if self.m_del_get!=del_get:
									is_get = True
									#print "[%s]%d %d -> %d"%(self.m_queue, qlen, self.m_del_get,del_get)
									self.m_del_get = del_get
									if last_failed:
										last_failed = False
										smsstr = "队列%s(len:%d)现在正常运行.[109]"%(self.m_queue,qlen)
										g_rmq_mgr.send(smsstr)
									break
								self.m_del_get = del_get
						except:
								print sys.exc_info()
						time.sleep(g_config["tavg"])
				if 0!=qlen and not is_get and not last_failed:
					ts = time.localtime()
					log_header = "[%d-%d-%d %d:%d:%d]"%(ts[0],ts[1],ts[2],ts[3],ts[4],ts[5])
					smsstr = "队列%s(len:%d)已经有%dmin没有数据被取出处理.[109]"%(self.m_queue,qlen,int(g_config["tseg"]/60))
					print smsstr
					g_rmq_mgr.send(smsstr)
					last_failed = True
					pass #sms send.
				for i in range( int(g_config["tsleep"]/2) ):
					if self.thread_stop:
						break
					time.sleep(2)
	def stop(self):  
		self.thread_stop = True 

'''
for queue in g_config["queues"]:
	#print "init queue checker: %s "%queue
	rgchecker = RMQ_GET_Checker(queue)
	rgchecker.start()
'''
g_rmq_mgr.dispatch()

