import parseopt, strutils, os, json, times

type Info* = object
    name: string
    time: string



type Config* = object
    name*: string
    url*: string
    timeout*: uint
    match*: string
    file*: string
    tokens*: seq[string]

proc read*(path: string): string =
    let exist = existsFile(path)
    var status = ""
    if exist:
        status = readFile(path)
    return status


proc put*(file: string, text: string) =
    writeFile(file, text)



proc cmd*(): Config =
    var cfg = Config(name: "", url: "", timeout: 8000, match: "",
            file: "/dev/shm/status", tokens: @[])
    for kind, key, val in getopt():
        case kind
        of cmdArgument:
            cfg.tokens.add(key)
        of cmdLongOption, cmdShortOption:
            case key
            of "name", "n": cfg.name = val
            of "url", "u": cfg.url = val
            of "timeout", "t": cfg.timeout = parseUint(val)
            of "match", "m": cfg.match = val
            of "file", "f": cfg.file = val
        of cmdEnd: assert(false) # cannot happen
    return cfg

proc getinfo*(): Info =
    let name = try: readFile("/etc/hostname") except: "unknow"
    let time = now().format("yyyy-MM-dd HH:mm:ss")
    return Info(name: name, time: time)

proc buildText*(title: string): string =
    let info = getinfo()
    let text = [
        title,
        "容器ID:"&info.name,
        "时间:"&info.time,
    ].join("\r\n\r\n")
    let body = %*{
        "msgtype": "markdown",
        "markdown": {
            "title": title,
            "text": text
        }
    }
    return $body


proc tokens*(alias: openArray[string]): seq[string] =
    var tokens: seq[string]
    for t in alias:
        case t
        of "fed": tokens.add("5cd837267e6f4cb2c1b00de6bd73dbc24ea0adb9594f1c4ee312d4569b707959")
        of "bed": tokens.add("1754eecae9b5bc277dcf4c436e248a1fdab3208d37dcfb70a07520a7d06fffd2")
        of "qa": tokens.add("6feb38605b9a5c885c3350ddf87e7405b5912c482f81c34dd2a424c49c010063")
        else: tokens.add(t)
    return tokens

