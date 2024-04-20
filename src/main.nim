
import json, httpcore, strutils
import request/http
import utils/util

proc check(cfg: Config, status: string): bool =
    var body: string;
    var passed: bool;
    try:
        let (code, str) = get(cfg.url, int(cfg.timeout), cfg.info.node, cfg.info.name)
        body = str
        passed = code == Http200
        if passed:
            if cfg.match != "":
                passed = body.contains(cfg.match)
                return passed
            return true
        return false

    except Exception:
        echo "check ", cfg.url, " error ", getCurrentExceptionMsg()
        return false
    finally:
        try:
            # nim中，finally里return能覆写try里的return，因此我们下面不要return
            if not cfg.report.isEmptyOrWhitespace:
                var data = if not body.isEmptyOrWhitespace:
                    try: parseJson(body) except Exception: %*{}
                else: %*{}
                var s: int
                if passed:
                    s = case status:
                    of "0": 2
                    of "1": 2
                    of "2": 2
                    of "3": 4
                    of "4": 4
                    else: 6
                else:
                    s = case status:
                    of "0": 1
                    of "1": 1
                    of "2": 3
                    of "3": 3
                    of "4": 3
                    else: 5
                data.add("status", %s)
                data.add("name", %cfg.name)
                data.add("ua", %cfg.info.node)
                data.add("refer", %cfg.info.name)
                discard report(cfg.report, $data, cfg.info.node, cfg.info.name)
        except Exception:
            discard

proc send(title: string, cfg: Config) =
    try:
        let r = notify(buildText(title, cfg.info), cfg.tokens)
        echo title, r
    except Exception:
        echo "send ", title, " error ", getCurrentExceptionMsg()


# 第一次检查，就是成功的
proc onFirstCheckOk(cfg: Config): int =
    put(cfg.file, "2")
    send("["&cfg.name&"]已启动,运行正常", cfg)
    return 0

# 第一次检查,未能校验成功，可能还未完成启动
proc onFirstCheckStarting(cfg: Config): int =
    put(cfg.file, "1")
    send("["&cfg.name&"]正在启动", cfg)
    return 10

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
    let status = read(cfg.file)
    let cs = check(cfg, status)
    if cs:
        case status
        of "0": return onFirstCheckOk(cfg)
        of "1": return onStartUpOk(cfg)
        of "2": return onStartWorkOk(cfg)
        of "3": return onRecoverOk(cfg)
        of "4": return onFinalOk(cfg)
        else: return 15
    else:
        case status
        of "0": return onFirstCheckStarting(cfg)
        of "1": return onStillStarting(cfg)
        of "2": return onErrorOccured(cfg)
        of "3": return onAlreadyDead(cfg)
        of "4": return onFinalDead(cfg)
        else: return 20

quit(main())


