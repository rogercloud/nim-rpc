import rpc_client, rpc_type, net, asyncdispatch

proc main {.async.} =
  var client = newRpcClient("127.0.0.1", Port(4343))
  var ret: int
  var state = client.call("add", (1, 2), ret)

  echo($ret)
  echo($state)

if isMainModule == true:
  asyncCheck main()
