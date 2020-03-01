## 加强版健康检查

* 容器发生重启时获得通知
* 容器首次重启后运行正常后获得通知,发送当前时间,主机名
* 健康检查不通过时发出告警(从成功变成不成功)
* 内容匹配模式,匹配到关键字才算成功

参数

> name/n :
> url/u : 监控地址
> timeout/t : 超时时间
> match/m : 关键字匹配模式
> file/f : 状态记录文件
> 参数: 报警群

```
./main -n=我的程序 -u=http://127.0.0.1:8080 token1 token2 token3
```

```
文件状态:

1: 首次启动
2: 首次启动后,健康检查通过
3: 首次启动后,健康检查通过,但现在失败了
4: 有成功过,有失败过,但现在是成功.

启动:
检测文件不存在,发送通知(程序正在启动),并设置文件1,执行健康检查退出码
检测到文件存在,读取状态,执行健康检查
若检查通过
    当前读取的是1: 发送通知,程序已经启动并正常工作, 设置为2
    当前读取的是2: 无需操作(这是后续轮询一直正常)
    当前读取的是3: 设置为4,(之前失败了,现在成功了,无需发送通知)
    当前读取的是4: 无需操作(有失败后最终的稳定状态)

若检查不通过
    当前读取的是1: 无需操作, (程序启动需要比较久的时间,再等等)
    当前读取的是2: 之前成功,现在失败了,设置为3,并发送通知邮件
    当前读取的是3: 之前是失败,现在检查还是失败,要发送通知
    当前读取的是4: 成功后又失败了,设置为3,发送不稳定通知
```

只有2和4是代表当前正常.(并且2代表程序很稳定)



## 退出状态码意义

