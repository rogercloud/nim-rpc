# nim-rpc
[![Build Status](https://travis-ci.org/rogercloud/nim-rpc.svg?branch=master)](https://travis-ci.org/rogercloud/nim-rpc)

RPC implementation for Nim based on [msgpack4nim](https://github.com/jangko/msgpack4nim) created by @jangko.

## Example

### RPC Server
    
```nimrod
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
var server = newRpcServer("127.0.0.1", Port(4343)) # server listen to 127.0.0.1:4343
server.register("add", remoteAdd) # register remoteAdd to RPC server binding name "add"
asyncCheck server.run() # run RPC server
runForever()
```

### RPC Client

```nimrod
import nimrpc/rpc_client, nimrpc/rpc_type, net, asyncdispatch

proc main =
  var client = newRpcClient("127.0.0.1", Port(4343)) # client send request to 127.0.0.1:4343
  var ret: int
  var state = client.call("add", (1, 2), ret) # client remote call add
  
  # Check remote call state first, only process ret value when state == Correct
  if state == Correct:
    echo($state) # output: Correct
    echo($ret) # output: 3
  else:
    echo($state)

if isMainModule == true:
  main()
 ```

### RPC Async Client
Due to nim compiler [bug](https://github.com/nim-lang/Nim/issues/2377), async client is not supported currently. It will be added in later version once the bug gets fixed.
