unit Bird.Socket.Client.Types;

interface

uses
  System.SysUtils;

type
  TEventListener = reference to procedure(const AText: string);
  TEventListenerError = reference to procedure(const AException: Exception; var AForceDisconnect: Boolean);

{$SCOPEDENUMS ON}
  TOperationCode = (CONTINUE, TEXT_FRAME, BINARY_FRAME, CONNECTION_CLOSE, PING, PONG);
  TEventType = (OPEN, &MESSAGE, ERROR, CLOSE, UPGRADE, HEART_BEAT_TIMER);
{$SCOPEDENUMS OFF}

  TOperationCodeHelper = record helper for TOperationCode
    function ToByte: Byte;
  end;

implementation

function TOperationCodeHelper.ToByte: Byte;
begin
  case Self of
    TOperationCode.CONTINUE:
      Result := $0;
    TOperationCode.TEXT_FRAME:
      Result := $1;
    TOperationCode.BINARY_FRAME:
      Result := $2;
    TOperationCode.CONNECTION_CLOSE:
      Result := $8;
    TOperationCode.PING:
      Result := $9;
    TOperationCode.PONG:
      Result := $A;
    else
      Result := $0;
  end;
end;

end.
