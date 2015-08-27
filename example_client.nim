import rpc_client, rpc_type, net, asyncdispatch

proc main =
  var client = newRpcClient("127.0.0.1", Port(4343)) # client send request to 127.0.0.1:4343
  var ret: int
  var state = client.call("add", (1, 2), ret) # client remote call add
  
  if state == Correct:
    echo($state) # output: Correct
    echo($ret) # output: 3
  else:
    echo($state)

if isMainModule == true:
  main()
