﻿#ifndef _RABBIT_CONFIG
#define _RABBIT_CONFIG
/*
 *doc related: /resource_gather/rabbitmq/doc/数据协议.xlsx (汇总的详细的说明文档)
 *rabbit-c interface is not thread-safe, just take care.
 */
//internal.configs
#define RMQ_ITEMS     32    //rmq_exchange_queues配置项{exchange,qname1,...}对应的数组最大size
#define RMQ_ITEM_SIZE 48   //rmq_exchange_queues配置项{exchange,qname1,...}对应的item size
#define FRAME_MAX     131072 
#define QUEUE_ITEM_BODY_SIZE  4096 //队列条目的body最大size
#define FRAME_WAIT_TIMEOUT    3   //获取队列条目超时时间
#define PRIORITY_MAX  10   //定义优先级范围(0到PRIORITY_MAX)，数字越大优先级越高.
#define RECONNECT_TIME_SECEND  (3*3)   //按照keepalived.conf上TCP_CHECK的配置，connect_timeout*nb_get_retry为重连时间

#ifdef WIN32
#define RECONNECT_TIME  (1000*RECONNECT_TIME_SECEND)  
const char *log_path   = "log\\rabbitmq.log"; 
#else
#define RECONNECT_TIME  RECONNECT_TIME_SECEND 
const char *log_path   = "log/rabbitmq.log"; //独立的rabbitmq-c接口日志，可以通过rmq_log_set_handler使用自定义日志接口.
#endif
//end.


//external.configs
//const char *rmq_hostname = "10.20.37.80";//
const char *rmq_hostname = "queue.25pp.local";
//const char *rmq_hostname = "192.168.12.200";//
const int   rmq_port     = 5672;
//const char *rmq_username = "guest";
//const char *rmq_passwd   = "guest";
const char *rmq_username = "teiron";
const char *rmq_passwd   = "teiron";
const int  rmq_heartbeat = 60;//Detecting Dead TCP Connections

//按照rabbitmq协议，当发送到队列，先根据约定的exchange进行路由，再根据topic的匹配规则路由到最终的queue,
//topic相当于queue感兴趣的专题属性，进行绑定后一旦属性匹配上，就能进入当前队列.
const char* g_ex_app_collect   = "app_collect";
const char* g_q_app_buy        = "app_update";
const char* g_q_app_buy_retry  = "app_update_retry";
const char* g_q_ge_down_single = "ges_down";
const char* g_q_jb_down        = "jb_down";
const char* g_q_ge_rawpkg      = "ge_rawpkg";
const char* g_q_gem_buy        = "gem_buy";
const char* g_q_jb_crack       = "jb_crack";
const char* g_q_jb_blktest     = "jb_blktest";
const char* g_q_ge_down_multi  = "gem_down";
const char* g_q_video_collect  = "video_collect";
const char* g_q_oss_upload     = "oss_upload";
const char* g_q_ge_down_multi_retry  = "gem_down_retry";
const char* g_q_app_change_status       = "app_change_status";
const char* g_q_prebuild_packet       = "test_gem_packet";

const char rmq_exchange_queues[][RMQ_ITEMS][RMQ_ITEM_SIZE] = { 
			{"app_collect", 
	"app_update", 
	"app_update_retry", 
	"collect_details",
	"ges_down", 
	"gem_down", 
	"gem_down_retry",
	"jb_down", 
	"ge_rawpkg", 
	"gem_buy", 
	"jb_crack", 
	"jb_blktest", 
	"price_change", 
	"app_change_status", 
	"video_collect", 
	"oss_upload",
	"test_gem_packet",
			"gem_test"},
			{"testexchange", "testq1", "testq2"},
};
const char rmq_topics[][RMQ_ITEMS][RMQ_ITEM_SIZE] = { 
	//{qname, topic1, topic2 ...}
	{"app_update",     "app_update"},    //app购买下载
	{"app_update_retry","app_update_retry"},    //app购买下载
	{"collect_details","collect_details"},    //采详情
	{"ges_down",       "ges_down"},      //正版单账号购买
	{"gem_down",       "gem_down"},      //正版多账号购买
	{"gem_down_retry", "gem_down_retry"},//正版多账号购买 - 重试，避开优先级限制
	{"jb_down",        "jb_down"},       //越狱购买
	{"ge_rawpkg",      "ge_rawpkg"},     //正版多账号 仅传一个raw包
	{"gem_buy",        "gem_buy"},       //正版多账号 组购买签名文件并上传包
	{"jb_crack",       "jb_crack"},      //越狱破解
	{"jb_blktest",     "jb_blktest"},    //越狱闪退测试
	{"price_change",   "price_change"},  //采集发现价格变化  
	{"app_change_status",   "app_change_status"},  //采集发现上架状态变化
	{"video_collect",  "video_collect"},  //video采集
	{"oss_upload",     "oss_upload"}, 
	{"test_gem_packet",     "test_gem_packet"}, 
			{"gem_test", "gem_test"},
			{"testq1", "testq1.#"},          //test queue
			{"testq2", "#.testq2"},          //test queue
};
//end.




#endif
