#!/usr/local/bin/python
# -*- coding: utf-8 -*-  
import os
import sys
import time
import ppsms

while True:
	ts = time.localtime()
	if ts[3]==9 and ts[4]==1 and ts[5]<5:
		ppsms.request_sms("12341234123","19 run OK !")#, r[0].delivery_tag
	time.sleep(5)

