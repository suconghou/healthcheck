## 加强版健康检查

* 容器发生重启时获得通知
* 容器首次重启后运行正常后获得通知,发送当前时间,主机名
* 健康检查不通过时发出告警(从成功变成不成功)
* 内容匹配模式,匹配到关键字才算成功

`./main options args`

**options**

> name/n : 监控的名字
>
> url/u : 监控地址,必填带http/https
>
> timeout/t : 超时时间,必须是数字,默认 8000ms,
>
> match/m : 关键字匹配模式,默认200即为成功,指定关键字后,200并且匹配才为成功
>
> file/f : 状态记录文件,默认`/dev/shm/status`
>
> report/r : 统计上报地址，开启后，监控地址返回的json信息将上报到此地址
>


**args**

>
> 参数: 钉钉报警群

```
./main -n=我的程序 -u=http://127.0.0.1:8080 token1 token2 token3
```

`docker swarm`配置

```
healthcheck:
    test: "check -n=我的程序 -u=http://127.0.0.1:8080 token1 token2"
    interval: 15s
    timeout: 15s
    retries: 10
    start_period: 3s
```

注意docker设定的timeout必须比检查程序的timeout大

`interval`建议不要太小.

如果程序启动较慢,`start_period`应设置的更长


## 上报模式

借助于report模式，我们可以采集容器里的业务运行时统计，上报统一收集，同时容器状态一并上报。

report上报的超时时间为5秒，此上报产生的任何错误（超时，接口错误等）都被忽略，不影响健康检查结果

上报时会将基本信息和统计信息合并

```json
{
    "status":"容器状态，同下面的文件状态,但是为Int型",
    "name":"监控等名字，上面-n的参数值",
    "ua":"节点信息，提取自环境变量NODENAME",
    "refer":"容器ID，提取自文件/etc/hostname或HOSTNAME环境变量",
    // 业务返回的其他字段
}
```

上报时Header里还会附加
```
User-Agent: 上述ua字段值
Referer: 上述refer字段值
```

故业务返回字段不能与上述字段冲突
业务可以返回`status`,值用来关键字匹配，后续此字段被覆盖

```
文件状态:

1: 启动后,健康检查还未通过
2: 启动后,健康检查始终是通过状态
3: 启动后,健康检查有成功过,但现在失败了
4: 有成功过,有失败过,但现在是成功.

启动:
检测文件不存在,执行健康检查
如果通过,设置为2,发送通知(程序刚启动,已正常),执行健康检查退出码
如果不通过,设置为1,发送通知(程序正在启动),执行健康检查退出码

检测到文件存在,读取状态,执行健康检查
若检查通过
    当前读取的是1: 发送通知,程序已经启动并正常工作, 设置为2
    当前读取的是2: 无需操作(这是后续轮询一直正常)
    当前读取的是3: 设置为4,(之前失败了,现在成功了,无需发送通知)
    当前读取的是4: 无需操作(有失败后最终的稳定状态)

若检查不通过
    当前读取的是1: 无需操作, (程序启动需要比较久的时间,再等等)
    当前读取的是2: 之前成功,现在失败了,设置为3,并发送通知
    当前读取的是3: 之前是失败,现在检查还是失败,要发送通知
    当前读取的是4: 成功后又失败了,设置为3,发送不稳定通知
```

只有2和4是代表当前正常.(并且2代表程序很稳定)



## 退出状态码意义

> 0 一切正常
>
> 10 程序正在启动,还未就绪,当前检查不通过
>
> 11 程序还在启动,检查仍不通过
>
> 12 程序之前检查一直正常,但现在检查不通过了
>
> 13 程序自上次检查不通过后,现在仍不通过
>
> 14 程序之前失败过,又恢复了,但现在检查又失败了
>
> 15/20 程序逻辑错误
>

## 静态编译

包含 openssl 的静态编译

`apk add openssl-libs-static` 安装到的是openssl3,使用以下命令可以静态编译

使用`-ffunction-sections`体积能减小一点点

```
nim --mm:arc --threads:off -d:release -d:nimDisableCertificateValidation --passL:"-ffunction-sections -fdata-sections" --passL:"-Wl,--gc-sections" --dynlibOverrideAll -d:useOpenSsl3 --passL:-s --passL:-static --passL:-lssl --passL:-lcrypto -d:ssl --opt:size c main
```

