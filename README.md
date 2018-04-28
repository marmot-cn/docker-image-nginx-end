# docker-image-nginx-end

---

## 简介

默认后端服务专用`nginx`配置. 主要核心针对接口输出, 需要接受前端`nginx`生成的`token`.

## 版本

* [1.0](./Docs/1.0.md)
	* [1.1](./Docs/1.1.md)(开发中...)

## 还未做完

### fastCGI参数优化

* `fastcgi_connect_timeout`: 指定连接到后端FastCGI的超时时间.
* `fastcgi_send_timeout`: 指定向FastCGI传送请求的超时时间.
* `fastcgi_read_timeout`: 指定接收FastCGI应答的超时时间.这个值是已经完成两次握手后接收FastCGI应答的超时时间

配套需要调整`phpfpm`中`ini`文件的`max_execution_time`.和`www.conf`中的`request_terminate_timeout`. 并且确认之间的关系影响.