import net, asyncdispatch, msgpack, tables
import rpc_type

type
  RpcClient* = ref RpcClientObj ## Rpc client ref type
  RpcClientObj* = object ## Rpc client obj type
    socket: Socket
    address: string
    port: Port

proc newRpcClient*(address: string, port: Port): RpcClient =
  ## Create a rpc client instance connecting to address:port.

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

proc call* [T, U](client: RpcClient, name: string, param: T, ret: var U): State =
  ## Sync style remote proc call
  ##
  ## client: Rpc client
  ## name: Remote proc registered name
  ## param: Remote proc param
  ## ret: Remote proc return value
  ## 
  ## return value: Remote call procedure state, *not* remote proc return value.
  ##               If everything is ok, return Correct. Other error state, please
  ##               refer to rpc_type module.
  ##
  ## Note:
  ## Because nim bug (gibhub issue #2377), only sync call is provided currently

  client.socket.connect(client.address, client.port)
  client.sendLine(pack(name))
  client.sendLine(pack(param))

  var state: State
  unpack(client.recvLine(), state)
  
  if state != Correct:
    return state

  var error: int
  try:
    unpack(client.recvLine(), error)
    unpack(client.recvLine(), ret)
  except:
    return ErrorRet

  client.socket.close()
