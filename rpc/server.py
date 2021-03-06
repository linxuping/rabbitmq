#!/usr/bin/env python
import os
import sys
import pika
import urllib2
import thread
import threading
import time

connection = pika.BlockingConnection(pika.ConnectionParameters(
        host='192.168.12.200'))
channel = connection.channel()
channel.queue_declare(queue='rpc_video_collect')

count = 0
def download_pkg(pkgurl):
    global count
    count = count + 1
    try:
      f = urllib2.urlopen(pkgurl)
      buf = f.read()
      f = open("gen_%d.ipa"%count, "wb+")
      f.write(buf)
      f.close()
    except:
      return sys.exc_info()
    return "ok"

def deco_m3ua(func):
    def _deco(ch, method, props, body):
        print "into _deco"
        #P34432555_default.m3u8 get child.m3ua
        func(ch, method, props, body)
    return _deco

@deco_m3ua
def on_request_thn(ch, method, props, body):
    if None == body:
        ch.basic_ack(delivery_tag = method.delivery_tag)
    _url = str(body)

    print(" [.] downloading(%s)" % _url)
    start = time.time()
    response = download_pkg(_url)
    for i in range(3):
        try:
            ch.basic_publish(exchange='',routing_key=props.reply_to,
                     properties=pika.BasicProperties(correlation_id = \
                                                         props.correlation_id),
                     body=str(response))
            break
        except:
            pass 
    ch.basic_ack(delivery_tag = method.delivery_tag)
    print(" [.] downloading(%s) %.03f fin." % (_url,time.time()-start))

def on_request(ch, method, props, body):
    thread.start_new_thread(on_request_thn, (ch, method, props, body))

'''thread mode.
channel.basic_qos(prefetch_count=2)
channel.basic_consume(on_request, queue='rpc_video_collect')
'''
channel.basic_qos(prefetch_count=1)
channel.basic_consume(on_request_thn, queue='rpc_video_collect')

print(" [x] Awaiting RPC requests")
while 1:
  try:
    channel.start_consuming()
  except:
    print sys.exc_info()

