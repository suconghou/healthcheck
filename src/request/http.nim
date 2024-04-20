import strutils, httpClient

proc req(kv: openArray[tuple[key: string, val: string]], ua: string = "", refer: string = ""): HttpHeaders =
    var headers = newHttpHeaders(kv)
    if not ua.isEmptyOrWhitespace:
        headers.add("User-Agent", ua)
    if not refer.isEmptyOrWhitespace:
        headers.add("Referer", refer)
    return headers

proc get*(url: string, timeout: int, ua: string = "", refer: string = ""): (HttpCode, string) =
    let client = newHttpClient(timeout = timeout)
    let resp = client.request(url, headers = req([], ua, refer))
    return (resp.code, resp.body)

proc post(url: string, timeout: int, body: string, ua: string = "", refer: string = ""): bool =
    let client = newHttpClient(timeout = timeout)
    let resp = client.request(url, HttpPost, body, headers = req({"Content-Type": "application/json"}, ua, refer))
    if resp.code == Http200 or resp.code == Http204:
        return true
    return false

proc report*(url: string, body: string, ua: string = "", refer: string = ""): bool =
    try:
        return post(url, timeout = 5000, body, ua, refer)
    except Exception:
        return false

proc notify*(body: string, tokens: openArray[string], timeout = 5000): seq[bool] =
    var res: seq[bool]
    for token in tokens:
        let url = "https://oapi.dingtalk.com/robot/send?access_token="&token
        let r = post(url, timeout, body)
        res.add(r)
    return res
