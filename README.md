# docker-image-nginx-end

---

默认后端服务专用`nginx`配置.

## 1.0

### 使用`nginx1.3`

### 优化`fastcgi_buffers`.

```
fastcgi_buffers 8 512k;
fastcgi_buffer_size 512k;
fastcgi_busy_buffers_size 1024k;
fastcgi_temp_file_write_size 1024k;
```

* `fastcgi_buffers`: 指定本地需要用多少和多大的缓冲区来缓冲FastCGI的应答请求.如果一个PHP脚本所产生的页面大小为256KB, 那么会为其分配4个64KB的缓冲区来缓存. 如果页面大小大于256KB, 那么大于256KB的部分会缓存到`fastcgi_temp`指定的路径中.但是这并不是好方法,因为内存中的数据处理速度要快于硬盘.一般这个值应该为站点中PHP脚本所产生的页面大小的中间值,如果站点大部分脚本所产生的页面大小为256KB,那么可以把这个值设置为“16 16k”,“4 64k"等.

* `fastcgi_buffer_size`: 用于指定读取FastCGI应答第一部分需要用多大的缓冲区.可以设置为fastcgi_buffers选项指定的缓冲区大小. 指定将用多大的缓冲区来读取`fastcgi`进程到来应答头.
* `fastcgi_busy_buffers_size`: 的默认值是fastcgi_buffers的两倍.
* `fastcgi_temp_file_write_size`: 示在写入缓存文件时使用多大的数据块,默认值是fastcgi_buffers的两倍

### 为接口输出添加`gzip`压缩.

### 优化nginx配置文件.`nginx.conf`

#### `worker_processes`

调整为`4`.

		worker_processes  4;

#### `worker_rlimit_nofile`

指定进程可以打开的最大描述符, 这里在 docker 内部 ulimit -n 是 1048576,这个是docker启动设定的默认值.
我用的 65535 是操作系统的默认值.

		worker_rlimit_nofile 65535;
		
#### `worker_connections`

调整为`10240`.

这里在生产环境把并发值增高.

#### ab 压力测试

单纯静态文件,不链接phpfpm进行压力测试.这个是在4核环境下进行的测试.


		ab -n 20000 -c 5000

我们统一的请求次数`10000`,每次并发`3000`个进行测试.		
* Concurrency Level: 并发数
* Time taken for tests: 压力测试消耗的总时间
* Complete requests: 压力测试的总次数
* Failed requests: 失败的请求数
* Requests per second: 平均每秒的请求数
* Time per request: 所有并发用户(这里是5000)都请求一次的平均时间
* Time per request(mean, across all concurrent requests): 单个用户请求一次的平均时间
* Transfer rate: 传输速率,单位:KB/s

		
##### 更新前 4核服务器 普通云盘
	
		Concurrency Level:      5000
		Time taken for tests:   6.540 seconds
		Complete requests:      20000
		Failed requests:        731
		   (Connect: 0, Receive: 0, Length: 731, Exceptions: 0)
		Write errors:           0
		Total transferred:      4489677 bytes
		HTML transferred:       77076 bytes
		Requests per second:    3058.05 [#/sec] (mean)
		Time per request:       1635.029 [ms] (mean)
		Time per request:       0.327 [ms] (mean, across all concurrent requests)
		Transfer rate:          670.39 [Kbytes/sec] received

吞吐率(Requests per second): 3058.05
失败的请求数: 731

##### 更新后 4核服务器 普通云盘

		Concurrency Level:      5000
		Time taken for tests:   5.388 seconds
		Complete requests:      20000
		Failed requests:        0
		Write errors:           0
		Total transferred:      4660000 bytes
		HTML transferred:       80000 bytes
		Requests per second:    3711.67 [#/sec] (mean)
		Time per request:       1347.102 [ms] (mean)
		Time per request:       0.269 [ms] (mean, across all concurrent requests)
		Transfer rate:          844.55 [Kbytes/sec] received
		
吞吐率(Requests per second):3711.67
失败的请求数: 0

##### 更新前 2核服务器 高效云盘

		Concurrency Level:      5000
		Time taken for tests:   6.270 seconds
		Complete requests:      20000
		Failed requests:        892
		   (Connect: 0, Receive: 0, Length: 822, Exceptions: 70)
		Write errors:           0
		Total transferred:      4468707 bytes
		HTML transferred:       76716 bytes
		Requests per second:    3189.73 [#/sec] (mean)
		Time per request:       1567.529 [ms] (mean)
		Time per request:       0.314 [ms] (mean, across all concurrent requests)
		Transfer rate:          696.00 [Kbytes/sec] received
		
吞吐率(Requests per second):3189.73
失败的请求数: 892

##### 更新后 2核服务器 高效云盘

		Concurrency Level:      5000
		Time taken for tests:   5.667 seconds
		Complete requests:      20000
		Failed requests:        0
		Write errors:           0
		Total transferred:      4660000 bytes
		HTML transferred:       80000 bytes
		Requests per second:    3529.20 [#/sec] (mean)
		Time per request:       1416.750 [ms] (mean)
		Time per request:       0.283 [ms] (mean, across all concurrent requests)
		Transfer rate:          803.03 [Kbytes/sec] received
		
吞吐率(Requests per second):3529.20
失败的请求数: 0

### 添加安全策略:

1. 忽略`favicon.ico`
2. 禁止显示nginx版本信息在`nginx.conf`中`server_tokens off;`
3. 修改`client_max_body_size`,因为只在后端做接口传输数据.缩小和`php`限制一样`5MB`
4. 设定`root`为`/var/www/html/public`,并且对应访问`php`路径也为`/var/www/html/public`,`public`是框架统一对外的公共访问目录.

```shell
# 忽略favicon.ico, 不记录日志 
location = /favicon.ico {
    log_not_found off;
    access_log off;
}
```

### 修改日志格式

日志添加`$http_x_request_id`头.

```
log_format  main   '[$http_x_request_id]:$remote_addr|$remote_user|$time_local|$request|'
                        '$status|$body_bytes_sent|$http_referer|'
                        '$http_user_agent|$http_x_forwarded_for|$request_time|$upstream_response_time|$upstream_addr|$upstream_connect_time|$upstream_status';
```                       

* `$http_x_request_id`: 接收到的`HTTP_X_REQUEST_ID`.
* `$remote_addr`: 客户端`ip`.
* `$remote_user`: 记录客户端用户名称.已经经过Auth Basic Module验证的用户名.**不记录**
* `$time_local`: 通用日志格式下的本地时间.
* `$request`: 记录请求的URL和HTTP协议
* `$status`: 记录请求状态.
* `$body_bytes_sent`: 发送给客户端的字节数, 不包括响应头的大小.
* `$http_referer`: 记录从哪个页面链接访问过来的.
* `$http_user_agent`: 记录客户端浏览器相关信息.
* `$http_x_forwarded_for`: 请求中的X-Forwarded-For信息.
* `$request_time`: 指的就是从接受用户请求的第一个字节到发送完响应数据的时间,即包括接收请求数据时间,程序响应时间,输出,响应数据时间,单位为秒,精度毫秒.
* `$upstream_response_time`: 从Nginx向后端,建立连接开始到接受完数据然后关闭连接为止的时间.
* `$upstream_addr`: 表示处理请求的upstream中的服务器地址.
* `$upstream_connect_time`: 记录与后端服务实例建立链接时花费的时间.
* `$upstream_status`: 表示upstream服务器的应对状态.

    
### 在响应头中添加`X-REQUEST-ID`

`php`中会呈现为`HTTP_X_REQUEST_ID`

在`default.conf`中添加响应头的返回.

`add_header     X-REQUEST-ID $http_x_request_id;`

测试命令:

```
curl -X GET -H "X-Request-ID:bbb" 127.0.0.1/users
```

## 还未做完

### 时区修改

```
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```

### fastCGI参数优化

* `fastcgi_connect_timeout`: 指定连接到后端FastCGI的超时时间.
* `fastcgi_send_timeout`: 指定向FastCGI传送请求的超时时间.
* `fastcgi_read_timeout`: 指定接收FastCGI应答的超时时间.这个值是已经完成两次握手后接收FastCGI应答的超时时间

配套需要调整`phpfpm`中`ini`文件的`max_execution_time`.和`www.conf`中的`request_terminate_timeout`. 并且确认之间的关系影响.