import parseopt, strutils, os, json, times

type Info* = object
    name: string
    time: string
    node: string



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
    let node = getEnv("NODENAME")
    return Info(name: name, time: time,node: node)

proc buildText*(title: string): string =
    let info = getinfo()
    let text = [
        title,
        "容器ID: "&info.name,
        "节点: "&info.node,
        "时间: "&info.time,
    ].join("\r\n\r\n")
    let body = %*{
        "msgtype": "markdown",
        "markdown": {
            "title": title,
            "text": text
        }
    }
    return $body

