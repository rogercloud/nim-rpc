import rpc_server, rpc_type, asyncnet, asyncdispatch, msgpack

type
  AddParam = object
    v1: int
    v2: int

proc addV2(param: AddParam, ret: var int): int =
  ret = param.v1 + param.v2
  result = 0

var server = newRpcServer("127.0.0.1", Port(4343))
server.register("add", addV2)
asyncCheck server.run()
runForever()
