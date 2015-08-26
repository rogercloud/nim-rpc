import net, asyncdispatch, msgpack, tables
import rpc_type

type
  RpcClient* = ref RpcClientObj
  RpcClientObj* = object
    socket: Socket
    address: string
    port: Port

proc newRpcClient*(address: string, port: Port): RpcClient =
  new(result)
  result.socket = newSocket()
  result.address = address
  result.port = port

proc sendLine(client: Socket, msg: string) =
  client.send(msg & "\c\L")

proc sendLine(client: RpcClient, msg: string) =
  client.socket.sendLine(msg)

proc recvLine(client: RpcClient): TaintedString =
  result = TaintedString""
  client.socket.readLine(result)

# 'cause nim bug when combining async and generic (issue #2377) 
# only sync call is provided
proc call* [T, U](client: RpcClient, name: string, param: T, ret: var U): State =
  client.socket.connect(client.address, client.port)
  client.sendLine(pack(name))
  client.sendLine(pack(param))
  echo("send command: " & name)

  var state: State
  unpack(client.recvLine(), state)
  echo("state: " & $state)
  
  if state != Correct:
    raise newException(IOError, $state)

  var error: int
  unpack(client.recvLine(), error)
  unpack(client.recvLine(), ret)
  client.socket.close()
