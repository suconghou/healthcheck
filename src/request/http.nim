import strutils
import httpClient

proc get*(url: string, timeout: int, str: string): bool =
    let client = newHttpClient(timeout = timeout)
    let resp = client.request(url)
    if resp.code == Http200:
        if str != "":
            return resp.body.contains(str)
        return true
    return false

proc post(url: string, timeout: int, body: string): bool =
    let headers = newHttpHeaders({"Content-Type": "application/json"})
    let client = newHttpClient(timeout = timeout)
    let resp = client.request(url, HttpPost, body, headers)
    if resp.code == Http200 or resp.code == Http204:
        return true
    return false

proc notify*(body: string, tokens: openArray[string], timeout = 5000): seq[bool] =
    var res: seq[bool]
    for token in tokens:
        let url = "https://oapi.dingtalk.com/robot/send?access_token="&token
        let r = post(url, timeout, body)
        res.add(r)
    return res
