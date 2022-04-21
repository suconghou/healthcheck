
import request/http
import utils/util


proc check(cfg: Config): bool =
    try:
        return get(cfg.url, int(cfg.timeout), cfg.match)
    except:
        echo "check ", cfg.url, " error ", getCurrentExceptionMsg()
        return false

proc send(title: string, cfg: Config) =
    try:
        let r = notify(buildText(title), tokens(cfg.tokens))
        echo title, r
    except:
        echo "send ", title, " error ", getCurrentExceptionMsg()


# 第一次检查,可能就是成功的,发送消息不一样
proc onStartUp(cfg: Config, cs: bool): int =
    if cs:
        put(cfg.file,"2")
        send("[" & cfg.name & "]已启动,运行正常", cfg)
    else:
        put(cfg.file, "1")
        send("[" & cfg.name & "]正在启动", cfg)
    return if cs: 0 else: 10


# 程序自启动以来首次健康检查通过,发送通知,并置状态为2
proc onStartUpOk(cfg: Config): int =
    put(cfg.file, "2")
    send("["&cfg.name&"]已启动完毕,运行正常", cfg)
    return 0

# 程序自第一次健康以来,一直检查都工作良好,无需操作
proc onStartWorkOk(cfg: Config): int =
    return 0

# 程序自第一次健康以来,有发生过失败,但现在恢复了,置为4
proc onRecoverOk(cfg: Config): int =
    put(cfg.file, "4")
    send("["&cfg.name&"]已经恢复,运行正常", cfg)
    return 0

# 程序自第一次健康以来,多次失败和恢复,之前就恢复了,现在也是可用状态
proc onFinalOk(cfg: Config): int =
    return 0

# 程序自启动以来,还未成功,无需操作,继续等待
proc onStillStarting(cfg: Config): int =
    return 11

# 程序自启动以来,之前成功的,但现在失败了,置为3,并发送报警
proc onErrorOccured(cfg: Config): int =
    put(cfg.file, "3")
    send("["&cfg.name&"]出现异常,无法访问", cfg)
    return 12

# 程序自上次失败后,还未恢复,要发送报警
proc onAlreadyDead(cfg: Config): int =
    send("["&cfg.name&"]出现异常,仍未恢复", cfg)
    return 13

# 程序失败后后来恢复了,但现在又失败了,置为3,发送不稳定报警
proc onFinalDead(cfg: Config): int =
    put(cfg.file, "3")
    send("["&cfg.name&"]无法访问,很不稳定", cfg)
    return 14


proc main(): int =
    let cfg = cmd()
    let cs = check(cfg)
    let status = read(cfg.file)
    if status == "":
        return onStartUp(cfg, cs)
    if cs:
        case status
        of "1": return onStartUpOk(cfg)
        of "2": return onStartWorkOk(cfg)
        of "3": return onRecoverOk(cfg)
        of "4": return onFinalOk(cfg)
    else:
        case status
        of "1": return onStillStarting(cfg)
        of "2": return onErrorOccured(cfg)
        of "3": return onAlreadyDead(cfg)
        of "4": return onFinalDead(cfg)
    return 20

try:
    var r = main()
    quit(r)
except:
    echo getCurrentExceptionMsg()


