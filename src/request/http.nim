import strutils, httpclient, asyncdispatch

proc req(kv: openArray[tuple[key: string, val: string]], refer: string = ""): HttpHeaders =
    var headers = newHttpHeaders(kv)
    if not refer.isEmptyOrWhitespace:
        headers.add("Referer", refer)
    return headers

proc get*(url: string, timeout: int, ua: string = "", refer: string = ""): (HttpCode, string) =
    let client = newAsyncHttpClient(userAgent = ua, headers = req([], refer))
    try:
        let fut = client.request(url, HttpGet)
        if not waitFor(fut.withTimeout(timeout)):
            raise newException(IOError, "request timeout: " & url)
        let resp = waitFor fut
        return (resp.code, waitFor resp.body)
    finally:
        client.close()

proc post(url: string, timeout: int, body: string, ua: string = "", refer: string = ""): bool =
    let client = newAsyncHttpClient(userAgent = ua, headers = req({"Content-Type": "application/json"}, refer))
    try:
        let fut = client.request(url, HttpPost, body)
        if not waitFor(fut.withTimeout(timeout)):
            return false
        let resp = waitFor fut
        return resp.code == Http200 or resp.code == Http204
    finally:
        client.close()

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
