import tables

type 
  State* = enum ## Remote proc call state
    Correct ## OK state
    ErrorMethodNotRegistered ## Request proc is not registered
    ErrorParam # Param type error, cannot be unpacked to registered type
    ErrorRet# Ret type error, cannot be unpacked to required type
    ErrorExecution # Any expection raised during remote proc execution
