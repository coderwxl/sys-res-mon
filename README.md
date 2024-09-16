# sys-res-mon
System resource monitoring
系统资源监控shell脚本，比zabbix更轻量级，不需要root即可运行：
	支持ubuntu和centos系统。
	支持企业微信告警，支持邮件告警。
	支持CPU使用率监控，精确到单核，并监控CPU使用率超过指定阈值的进程。
	支持内存与交换内存监控，并监控内存使用率超过指定阈值的进程。
	支持磁盘使用率监控，并自动过滤掉无效类型。
	支持Inode使用率监控。
	支持僵尸进程监控。
	支持报告系统重启及shutdown事件。
	支持所有进程打开的fd数量监控（此项需要root运行）。
