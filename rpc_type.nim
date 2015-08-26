import tables

type 
  State* = enum
    Correct
    ErrorMethodNotRegistered
    ErrorParam
    ErrorExecution
