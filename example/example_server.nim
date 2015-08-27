import nimrpc/rpc_server, nimrpc/rpc_type, asyncnet, asyncdispatch, msgpack

# Define your remote proc
# Remote porc must have two params, first is input, second is output (so it's var param).
# Return value must be an int as error code, for example, 0 for success, -1 for error.
proc remoteAdd(param: tuple[v1: int, v2: int], ret: var int): int =
  ret = param.v1 + param.v2
  result = 0

# Create the server
# Currently procs must be resgistered before rpc server starts running.
# Running time proc register will be added in later version
var server = newRpcServer("127.0.0.1", Port(4343)) # send request to 127.0.0.1:4343
server.register("add", remoteAdd) # register remoteAdd to RPC server binding name "add"
asyncCheck server.run() # run RPC server
runForever()
