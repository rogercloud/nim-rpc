import asyncnet, asyncdispatch, msgpack, tables
import rpc_type

type
  CallHookResponse = tuple[s: string, e: string, v: string]
  CallHook = proc(param: string): CallHookResponse
  RpcServer* = ref RpcServerObj ## Rpc server ref type
  RpcServerObj* = object ## Rpc server obj type
    procStore: TableRef[string, CallHook]
    address: string
    port: Port
    

proc newRpcServer*(address: string, port: Port): RpcServer =
  ## Create a rpc server instance listening to address:port.
  ## Warning: create doesn't mean run, please call *run* if 
  ## you want to run the server

  new(result)
  result.procStore = newTable[string, CallHook]()
  result.address = address
  result.port = port


proc registerProc(rpc: var RpcServer, procName: string, hook: CallHook) =
  rpc.procStore[procName] = hook


proc hasRegistered(rpc: RpcServer, name: string): bool =
  result = rpc.procStore.hasKey(name)


proc packError(err: State): CallHookResponse
proc register*[T, U](rpc: var RpcServer, name: string, p: (proc(param: T, ret: var U): int)) =
  ## Register a function to the server, which is invoked remotely.
  ##
  ## rpc: Rpc server
  ## name: Name to be registered for the proc, *not* required to be the same as proc's real name
  ## p: Proc to be registered. Two params are required: first for param, second for return val.
  ##    Return value must be int usually used as error code 

  proc hook(hookParam: string): CallHookResponse =
    var 
      paramVal: T
      retVal: U
    try:
      hookParam.unpack(paramVal)
    except:
      return packError(ErrorParam)
    var error = p(paramVal, retVal)
    echo("ret value: " & $retVal & ", error: " & $error)
    return (pack(Correct), pack(error), pack(retVal))
  registerProc(rpc, name, hook)


proc call(rpc: RpcServer, name:string, param: string): CallHookResponse =
  try:
    result = rpc.procStore[name](param)
  except:
    result = packError(ErrorExecution)


proc sendLine(client: AsyncSocket, msg: string) {.async.}=
  await client.send(msg & "\c\L")


proc response(client: AsyncSocket, rsp: CallHookResponse) {.async.} =
  await client.sendLine(rsp.s)
  await client.sendLine(rsp.e)
  await client.sendLine(rsp.v)


proc packError(err: State): CallHookResponse =
  return (pack(err), "", "")


proc reportError(client: AsyncSocket, err: State) {.async.}=
  await client.response(packError(err))


proc processClient(rpc: RpcServer, client: AsyncSocket) {.async.} =
  while true:
    let command = await client.recvLine()
    if command == "":
      echo("User close connection")
      return

    var unpackedCommand: string 
    unpack(command, unpackedCommand)
    if not rpc.hasRegistered(unpackedCommand):
      await client.reportError(ErrorMethodNotRegistered)

    echo("Process command: " & unpackedCommand)
    let param = await client.recvLine()
    await client.response(rpc.call(unpackedCommand, param))


proc run*(rpc: RpcServer) {.async.} =
  ## Run rpc server, you should register all the procs before run the server

  var server = newAsyncSocket()
  server.bindAddr(rpc.port, rpc.address)
  server.listen()
  while true:
    let client = await server.accept()
    asyncCheck rpc.processClient(client)
