unit WebSocket.Client.Consts;

interface

uses WebSocket.Client.Types;

const
  TOpCodeByte: array[TOperationCode] of Byte = ($0, $1, $2, $8, $9, $A);

implementation

end.
