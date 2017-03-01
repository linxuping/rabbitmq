#!/usr/bin/env python
# -*- coding: utf-8 -*-
# utf-8 中文编码
import httplib
import json
import hashlib
import time
import sys
import logging
import os

reload(sys)  
sys.setdefaultencoding('utf8') 

#日志
logfile = os.path.join(os.path.dirname(__file__),"sms.log")
logformat='%(asctime)s - %(levelname)s: %(message)s'
logging.basicConfig(filename = os.path.join(os.getcwd(),logfile),level=logging.DEBUG, filemode = 'a', format = logformat)
#logging.basicConfig(level=logging.DEBUG)
#错误代码
error_code={"9999":"unknown error","10001":"system error","10005":"sigin error","10020":"jk don't exist","20001":"parameter error","20003":"user does't exist"}
#重试
def conn_try_again(tries=3,delay=30, logger=None):
    def deco_retry(function):
        def f_retry(*args, **kwargs):
            mtries, mdelay = tries, delay
            while mtries >= 1:
                try:
                    msg = function(*args, **kwargs)
                    res=(True,msg)
                    return msg
                except Exception as msg:
                    res=(False,str(msg))
                    time.sleep(mdelay)
                    mtries-=1
                finally:
                    if logger:
                        logging.info(msg)
                    else:
                        print msg
            return str(res)        
        return f_retry
    return deco_retry
            
@conn_try_again(tries=2,delay=5,logger=logging)
def request_sms(mb,content):
    httpClient = None
    try:
        req_data={"phone": mb,"msg": content}
        sign=hashlib.md5("sendMessagemsg=%(msg)sphone=%(phone)syunwei6594949494guygugUYYT154" % req_data).hexdigest()
        params =dict(service= "sendMessage",
            caller="yunwei",
            version= "1.0",
            data=req_data,
            sign=sign)
        jsdata=json.dumps(params,ensure_ascii=False,indent=2)
        headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "text/json","charset":"UTF-8"}   
        httpClient = httplib.HTTPSConnection("openapi.p.com", 443, timeout=30)
        httpClient.request("POST", "/misc/run", jsdata, headers)
        response = httpClient.getresponse()
        if response.status == 200:
            result=json.loads(response.read())
            if result.get("msg")=="ok" and result.get("error_code")=="0":
                return "sendSMS success"
            else:    
                err= error_code[result.get("error_code","9999")]
                raise Exception(err)
        else:
            err= "connect error"
            raise Exception(err)
    except Exception, e:
        raise Exception(str(e))
    finally:
        if httpClient:
            httpClient.close()
    
if __name__=="__main__":
    phonenum=sys.argv[1]
    msg=sys.argv[2]
    tes=request_sms(phonenum,msg)
    print sys.argv,tes

