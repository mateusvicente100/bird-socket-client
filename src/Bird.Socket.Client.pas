unit Bird.Socket.Client;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  System.Math,
  System.Threading,
  System.DateUtils,
  IdURI,
  IdGlobal,
  IdTCPClient,
  IdSSLOpenSSL,
  IdCoderMIME,
  IdHashSHA,
  Bird.Socket.Client.Types,
  System.Generics.Collections,
  System.JSON;

type
  TOperationCode = Bird.Socket.Client.Types.TOperationCode;

  TEventType = Bird.Socket.Client.Types.TEventType;

  TBirdSocketClient = class(TIdTCPClient)
  private
    FInternalLock: TCriticalSection;
    FHeader: TDictionary<string, string>;
    FURL: string;
    FSecWebSocketAcceptExpectedResponse: string;
    FHeartBeatInterval: Cardinal;
    FAutoCreateHandler: Boolean;
    FUpgraded: Boolean;
    FClosingEventLocalHandshake: Boolean;
    FOnMessage: TEventListener;
    FOnOpen: TEventListener;
    FOnClose: TNotifyEvent;
    FOnError: TEventListenerError;
    FOnHeartBeatTimer: TNotifyEvent;
    FOnUpgrade: TNotifyEvent;
    FSubProtocol: string;
    FTaskReadFromWebSocket, FTaskHeartBeat: ITask;
    function GenerateWebSocketKey: string;
    function IsValidWebSocket: Boolean;
    function IsValidHeaders(const AHeaders: TStrings): Boolean;
    function EncodeFrame(const AMessage: RawByteString; const AOperationCode: TOperationCode = TOperationCode.TEXT_FRAME): TIdBytes;
    function GetBit(const AValue: Cardinal; const AByte: Byte): Boolean;
    function SetBit(const AValue: Cardinal; const AByte: Byte): Cardinal;
    function ClearBit(const AValue: Cardinal; const AByte: Byte): Cardinal;
    procedure SetSecWebSocketAcceptExpectedResponse(const AValue: string);
    procedure ReadFromWebSocket; virtual;
    procedure SendCloseHandshake;
    procedure HandleException(const AException: Exception);
    procedure StartHeartBeat;
    procedure Close;
    constructor Create(const AURL: string); reintroduce;
  protected
    property OnMessage: TEventListener read FOnMessage write FOnMessage;
    property OnOpen: TEventListener read FOnOpen write FOnOpen;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnError: TEventListenerError read FOnError write FOnError;
    property OnHeartBeatTimer: TNotifyEvent read FOnHeartBeatTimer write FOnHeartBeatTimer;
    property OnUpgrade: TNotifyEvent read FOnUpgrade write FOnUpgrade;
  public
    class function New(const AURL: string): TBirdSocketClient;
    property HeartBeatInterval: Cardinal read FHeartBeatInterval write FHeartBeatInterval;
    property AutoCreateHandler: Boolean read FAutoCreateHandler write FAutoCreateHandler;
    function Connected: Boolean; override;
    procedure Connect; override;
    procedure SetHeader(const key:string; const value:string);
    procedure AddEventListener(const AEventType: TEventType; const AEvent: TEventListener); overload;
    procedure AddEventListener(const AEventType: TEventType; const AEvent: TEventListenerError); overload;
    procedure AddEventListener(const AEventType: TEventType; const AEvent: TNotifyEvent); overload;
    procedure SetSubProtocol(const AValue: string);
    procedure Send(const AMessage: string); overload;
    procedure Send(const AMessage: RawByteString); overload;
    procedure Send(const AJSONObject: TJSONObject; const AOwns: Boolean = True); overload;
    destructor Destroy; override;
  end;

implementation


procedure TBirdSocketClient.SetHeader(const key:string; const value:string);
begin
  FHeader.AddOrSetValue(key, value);
end;

procedure TBirdSocketClient.AddEventListener(const AEventType: TEventType; const AEvent: TNotifyEvent);
begin
  case AEventType of
    TEventType.Close:
      begin
        if Assigned(FOnClose) then
          raise Exception.Create('The close event listener is already assigned!');
        FOnClose := AEvent;
      end;
    TEventType.UPGRADE:
      begin
        if Assigned(FOnUpgrade) then
          raise Exception.Create('The upgrade event listener is already assigned!');
        FOnUpgrade := AEvent;
      end;
    TEventType.HEART_BEAT_TIMER:
      begin
        if Assigned(FOnHeartBeatTimer) then
          raise Exception.Create('The heart beat timer event listener is already assigned!');
        FOnHeartBeatTimer := AEvent;
      end;
  else
    raise Exception.Create('This is not an valid event!');
  end;
end;

procedure TBirdSocketClient.AddEventListener(const AEventType: TEventType; const AEvent: TEventListenerError);
begin
  if (AEventType <> TEventType.ERROR) then
    raise Exception.Create('This is not an valid event!');
  if Assigned(FOnError) then
    raise Exception.Create('The error event listener is already assigned!');
  FOnError := AEvent;
end;

procedure TBirdSocketClient.AddEventListener(const AEventType: TEventType; const AEvent: TEventListener);
begin
  case AEventType of
    TEventType.OPEN:
      begin
        if Assigned(FOnOpen) then
          raise Exception.Create('The open event listener is already assigned!');
        FOnOpen := AEvent;
      end;
    TEventType.MESSAGE:
      begin
        if Assigned(FOnMessage) then
          raise Exception.Create('The message event listener is already assigned!');
        FOnMessage := AEvent;
      end;
  else
    raise Exception.Create('This is not an valid event!');
  end;
end;

function TBirdSocketClient.ClearBit(const AValue: Cardinal; const AByte: Byte): Cardinal;
begin
  Result := AValue and not (1 shl AByte);
end;

procedure TBirdSocketClient.Close;
begin
  if not Connected then
    Exit;
  FInternalLock.Enter;
  try
    SendCloseHandshake;
    if Assigned(FIOHandler) then
    begin
      FIOHandler.InputBuffer.Clear;
      FIOHandler.CloseGracefully;
    end;
    Disconnect;
    if Assigned(FOnClose) then
      FOnClose(Self);
  finally
    FInternalLock.Leave;
  end;
end;

procedure TBirdSocketClient.Connect;
var
  LURI: TIdURI;
  LSecure: Boolean;
  LPair: string;
begin
  if Connected then
    raise Exception.Create('The websocket is already connected!');
  LURI := TIdURI.Create(FURL);
  try
    FClosingEventLocalHandshake := False;
    FHost := LURI.Host;
    if LURI.Protocol.Contains('wss') then
      LURI.Protocol := ReplaceOnlyFirst(LURI.Protocol.ToLower, 'wss', 'https')
    else
      LURI.Protocol := ReplaceOnlyFirst(LURI.Protocol.ToLower, 'ws', 'http');
    if LURI.Path.Trim.IsEmpty then
      LURI.Path := '/';
    LSecure := LURI.Protocol.ToLower.Equals('https');
    FPort := StrToIntDef(LURI.Port, 0);
    if (FPort = 0) then
      FPort := IfThen(LSecure, 443, 80);
    if LSecure and (not Assigned(FIOHandler)) then
    begin
      if FAutoCreateHandler then
      begin
        SetIOHandler(TIdSSLIOHandlerSocketOpenSSL.Create(Self));
        TIdSSLIOHandlerSocketOpenSSL(FIOHandler).SSLOptions.Mode := TIdSSLMode.sslmClient;
        TIdSSLIOHandlerSocketOpenSSL(FIOHandler).SSLOptions.SSLVersions := [TIdSSLVersion.sslvTLSv1, TIdSSLVersion.sslvTLSv1_1, TIdSSLVersion.sslvTLSv1_2];
        TIdSSLIOHandlerSocketOpenSSL(FIOHandler).SSLOptions.Method := sslvTLSv1_2;
        TIdSSLIOHandlerSocketOpenSSL(FIOHandler).PassThrough := False;
      end
      else
        raise Exception.Create('To use a secure connection you need to assign a TIdSSLIOHandlerSocketOpenSSL descendant');
    end;
    inherited Connect;
    if not LURI.Port.IsEmpty then
      LURI.Host := LURI.Host + ':' + LURI.Port;
    if (LURI.Params <> '') then
      FSocket.WriteLn(Format('GET %s HTTP/1.1', [LURI.Path + LURI.Document + '?' + LURI.Params]))
    else
      FSocket.WriteLn(Format('GET %s HTTP/1.1', [LURI.Path + LURI.Document]));
    FSocket.WriteLn(Format('Host: %s', [LURI.Host]));
    for LPair in FHeader.Keys do
      FSocket.WriteLn(Format('%s: %s', [LPair, FHeader.Items[LPair]]));
    FSocket.WriteLn('Connection: keep-alive, Upgrade');
    FSocket.WriteLn('Upgrade: WebSocket');
    FSocket.WriteLn('Sec-WebSocket-Version: 13');
    FSocket.WriteLn(Format('Sec-WebSocket-Key: %s', [GenerateWebSocketKey]));
    if not FSubProtocol.Trim.IsEmpty then
      FSocket.WriteLn(Format('Sec-WebSocket-Protocol: %s', [FSubProtocol]));
    FSocket.WriteLn(EmptyStr);
    ReadFromWebSocket;
    StartHeartBeat;
  finally
    LURI.Free;
  end;
end;

function TBirdSocketClient.Connected: Boolean;
begin
  try
    Result := inherited Connected;
  except
    Result := False;
  end;
end;

constructor TBirdSocketClient.Create(const AURL: string);
begin
  inherited Create(nil);
  FInternalLock := TCriticalSection.Create;
  FAutoCreateHandler := True;
  FHeartBeatInterval := 30000;
  FURL := AURL;
  FSubProtocol := EmptyStr;
  FHeader := TDictionary<string, string>.Create;
  Randomize;
end;

destructor TBirdSocketClient.Destroy;
var
  taskArray: array of ITask;
begin
  if FTaskReadFromWebSocket <> nil then
    taskArray := taskArray + [FTaskReadFromWebSocket];
  if FTaskHeartBeat <> nil then
    taskArray := taskArray + [FTaskHeartBeat];
  if Length(taskArray) > 0 then
    TTask.WaitForAll(taskArray);
  FTaskReadFromWebSocket := nil;
  FTaskHeartBeat := nil;
  SetLength(taskArray, 0);
  if FAutoCreateHandler and Assigned(FIOHandler) then
    FIOHandler.Free;
  FInternalLock.Free;
  inherited;
end;

function TBirdSocketClient.EncodeFrame(const AMessage: RawByteString; const AOperationCode: TOperationCode): TIdBytes;
var
  LFin, LMask: Cardinal;
  LMaskingKey: array[0..3] of Cardinal;
  LExtendedPayloads: array[0..3] of Cardinal;
  LBuffer: TIdBytes;
  I: Integer;
  LXorOne, LXorTwo: Char;
  LExtendedPayloadLength: Integer;
  LMessage: RawByteString;
begin
  LFin := 0;
  if AOperationCode <> TOperationCode.BINARY_FRAME then
  begin
    LMessage := UTF8Encode(AMessage);
  end
  else
  begin
    LMessage := AMessage;
  end;
  LFin := SetBit(LFin, 7) or AOperationCode.ToByte;
  LMask := SetBit(0, 7);
  LExtendedPayloadLength := 0;
  if (Length(LMessage) <= 125) then
    LMask := LMask + Cardinal(Length(LMessage))
  else if (Length(LMessage).ToSingle < IntPower(2, 16)) then
  begin
    LMask := LMask + 126;
    LExtendedPayloadLength := 2;
    LExtendedPayloads[1] := Byte(Length(LMessage));
    LExtendedPayloads[0] := Byte(Length(LMessage) shr 8);
  end
  else
  begin
    LMask := LMask + 127;
    LExtendedPayloadLength := 4;
    LExtendedPayloads[3] := Byte(Length(LMessage));
    LExtendedPayloads[2] := Byte(Length(LMessage) shr 8);
    LExtendedPayloads[1] := Byte(Length(LMessage) shr 16);
    LExtendedPayloads[0] := Byte(Length(LMessage) shr 32);
  end;
  LMaskingKey[0] := Random(255);
  LMaskingKey[1] := Random(255);
  LMaskingKey[2] := Random(255);
  LMaskingKey[3] := Random(255);
  SetLength(LBuffer, 1 + 1 + LExtendedPayloadLength + 4 + Length(LMessage));
  LBuffer[0] := LFin;
  LBuffer[1] := LMask;
  for I := 0 to Pred(LExtendedPayloadLength) do
    LBuffer[1 + 1 + I] := LExtendedPayloads[I];
  for I := 0 to 3 do
    LBuffer[1 + 1 + LExtendedPayloadLength + I] := LMaskingKey[I];
  for I := 0 to Pred(Length(LMessage)) do
  begin
{$IF DEFINED(iOS) or DEFINED(ANDROID)}
    LXorOne := Char(LMessage[I]);
{$ELSE}
    LXorOne := Char(LMessage[Succ(I)]);
{$ENDIF}
    LXorTwo := Chr(LMaskingKey[((I) mod 4)]);
    LXorTwo := Chr(ord(LXorOne) xor ord(LXorTwo));
    LBuffer[1 + 1 + LExtendedPayloadLength + 4 + I] := ord(LXorTwo);
  end;
  Result := LBuffer;
end;

function TBirdSocketClient.GenerateWebSocketKey: string;
var
  LBytes: TIdBytes;
  I: Integer;
begin
  SetLength(LBytes, 16);
  for I := Low(LBytes) to High(LBytes) do
    LBytes[I] := Byte(Random(255));
  Result := TIdEncoderMIME.EncodeBytes(LBytes);
  SetSecWebSocketAcceptExpectedResponse(Result + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11');
end;

function TBirdSocketClient.GetBit(const AValue: Cardinal; const AByte: Byte): Boolean;
begin
  Result := (AValue and (1 shl AByte)) <> 0;
end;

procedure TBirdSocketClient.HandleException(const AException: Exception);
var
  LForceDisconnect: Boolean;
begin
  LForceDisconnect := true;
  if Assigned(FOnError) then
    FOnError(AException, LForceDisconnect);
  if LForceDisconnect then
    Self.Close;
end;

function TBirdSocketClient.IsValidHeaders(const AHeaders: TStrings): Boolean;
begin
  Result := False;
  AHeaders.NameValueSeparator := ':';
  if (AHeaders.Count = 0) then
    Exit;
  if (not AHeaders[0].Contains('HTTP/1.1 101')) and (AHeaders[0].Contains('HTTP/1.1')) then
    raise Exception.Create(AHeaders[0].Substring(9));
  if AHeaders.Values['Connection'].Trim.ToLower.contains('upgrade') and AHeaders.Values['Upgrade'].Trim.ToLower.Equals('websocket') then
  begin
    if AHeaders.Values['Sec-WebSocket-Accept'].Trim.Equals(FSecWebSocketAcceptExpectedResponse) then
      Exit(True);
    if AHeaders.Values['Sec-WebSocket-Accept'].Trim.IsEmpty then
      Exit(True);
    raise Exception.Create('Unexpected return key on Sec-WebSocket-Accept in handshake!');
  end;
end;

function TBirdSocketClient.IsValidWebSocket: Boolean;
var
  LSpool: string;
  LByte: Byte;
  LHeaders: TStringlist;
begin
  LSpool := EmptyStr;
  LHeaders := TStringlist.Create;
  try
    try
      FUpgraded := False;
      while Connected and not FUpgraded do
      begin
        LByte := FSocket.ReadByte;
        LSpool := LSpool + Chr(LByte);
        if (not FUpgraded) and (LByte = ord(#13)) then
        begin
          if (LSpool = #10#13) then
          begin
            if not IsValidHeaders(LHeaders) then
              raise Exception.Create('URL is not from an valid websocket server, not a valid response header found');
            FUpgraded := True;
            LSpool := EmptyStr;
          end
          else
          begin
            if Assigned(FOnOpen) then
              FOnOpen(LSpool);
            LHeaders.Add(LSpool.Trim);
            LSpool := EmptyStr;
          end;
        end;
      end;
      Result := True;
    except
      on E: Exception do
      begin
        HandleException(E);
        Result := False;
      end;
    end;
  finally
    LHeaders.Free;
  end;
end;

class function TBirdSocketClient.New(const AURL: string): TBirdSocketClient;
begin
  Result := TBirdSocketClient.Create(AURL);
end;

procedure TBirdSocketClient.ReadFromWebSocket;
var
  LOperationCode: Byte;
  LSpool: TIdBytes;
  RawStr: RawByteString;
begin
  if not IsValidWebSocket then
    Exit;
  if not Connected then
    Exit;
  FTaskReadFromWebSocket := TTask.Run(
    procedure
    var
      LByte: Byte;
      LPosition: Integer;
      LLinFrame, LMasked: Boolean;
      LSize: Int64;
    begin
      SetLength(LSpool, 0);
      LPosition := 0;
      LSize := 0;
      LOperationCode := 0;
      LLinFrame := False;
      try
        while Connected do
        begin
          LByte := FSocket.ReadByte;
          if FUpgraded and (LPosition = 0) and GetBit(LByte, 7) then
          begin
            LOperationCode := ClearBit(LByte, 7);
            // check range
            if (LOperationCode >= 3) and (LOperationCode <= 7) then
            begin
              HandleException(Exception.Create('reserved non-control frames'));
              Continue;
            end
            else if (LOperationCode > 11) then
            begin
              HandleException(Exception.Create('reserved control frames'));
              Continue;
            end;
            LLinFrame := True;
            Inc(LPosition);
          end
          else if FUpgraded and (LPosition = 1) then
          begin
            LMasked := GetBit(LByte, 7);
            LSize := LByte;
            if LMasked then
              LSize := LByte - SetBit(0, 7);
            if (LSize = 0) then
              LPosition := 0
            else if (LSize = 126) then
              LSize := FSocket.ReadUInt16
            else if LSize = 127 then
              LSize := FSocket.ReadUInt64;
            Inc(LPosition);
          end
          else if LLinFrame then
          begin
            LSpool := LSpool + [LByte];
            if (FUpgraded and (Length(LSpool) = LSize)) then
            begin
              LPosition := 0;
              LLinFrame := False;
              try
                // ping and pong
                if (LOperationCode = TOperationCode.PING.ToByte) or (LOperationCode = TOperationCode.PONG.ToByte) then
                begin
                  try
                    FInternalLock.Enter;
                    // or not response is fine
                    FSocket.Write(EncodeFrame(IndyTextEncoding_UTF8.GetString(LSpool), TOperationCode.PONG));
                  finally
                    FInternalLock.Leave;
                  end;
                end
                // close
                else if (LOperationCode = TOperationCode.CONNECTION_CLOSE.ToByte) then
                begin
                  if not FClosingEventLocalHandshake then
                    Self.Close;
                  Break
                end
                else
                begin
                  if FUpgraded then
                  begin
                    // data too long problem fixed
                    // check binary frame
                    if LOperationCode = TOperationCode.BINARY_FRAME.ToByte then
                    begin
                      SetString(RawStr, PAnsiChar(@LSpool[0]), Length(LSpool));
                      FOnMessage(RawStr);
                    end
                    // check text frame
                    else if LOperationCode = TOperationCode.TEXT_FRAME.ToByte then
                    begin
                      FOnMessage(IndyTextEncoding_UTF8.GetString(LSpool));
                    end;
                  end;
                end;
              finally
                SetLength(RawStr, 0);
                SetLength(LSpool, 0);
              end;
            end;
          end;
        end;
      except
        on E: Exception do
          HandleException(E);
      end;
    end);
  if ((not Connected) or (not FUpgraded)) and (not ((LOperationCode = TOperationCode.CONNECTION_CLOSE.ToByte) or FClosingEventLocalHandshake)) then
    raise Exception.Create('Websocket not connected or timeout ' + QuotedStr(IndyTextEncoding_UTF8.GetString(LSpool)))
  else if Assigned(OnUpgrade) then
    OnUpgrade(Self);
end;

procedure TBirdSocketClient.Send(const AMessage: string);
begin
  try
    FInternalLock.Enter;
    FSocket.Write(EncodeFrame(AMessage));
  finally
    FInternalLock.Leave;
  end;
end;

procedure TBirdSocketClient.Send(const AMessage: RawByteString);
begin
  try
    FInternalLock.Enter;
    FSocket.Write(EncodeFrame(AMessage, TOperationCode.BINARY_FRAME));
  finally
    FInternalLock.Leave;
  end;
end;

procedure TBirdSocketClient.Send(const AJSONObject: TJSONObject; const AOwns: Boolean);
begin
  try
    Send(AJSONObject.ToString);
  finally
    if AOwns then
      AJSONObject.Free;
  end;
end;

procedure TBirdSocketClient.SendCloseHandshake;
begin
  FClosingEventLocalHandshake := True;
  FSocket.Write(EncodeFrame(EmptyStr, TOperationCode.CONNECTION_CLOSE));
  TThread.Sleep(200);
end;

procedure TBirdSocketClient.SetSecWebSocketAcceptExpectedResponse(const AValue: string);
var
  LHash: TIdHashSHA1;
begin
  LHash := TIdHashSHA1.Create;
  try
    FSecWebSocketAcceptExpectedResponse := TIdEncoderMIME.EncodeBytes(LHash.HashString(AValue));
  finally
    LHash.Free;
  end;
end;

procedure TBirdSocketClient.SetSubProtocol(const AValue: string);
begin
  FSubProtocol := AValue;
end;

procedure TBirdSocketClient.StartHeartBeat;
var
  LDateLastNotify: TDateTime;
begin
  FTaskHeartBeat := TTask.Run(
    procedure
    begin
      LDateLastNotify := Now;
      try
        while (Connected) and (HeartBeatInterval > 0) do
        begin
          if (MilliSecondsBetween(LDateLastNotify, Now) >= Floor(Self.HeartBeatInterval)) then
          begin
            if Assigned(OnHeartBeatTimer) then
              OnHeartBeatTimer(Self);
            LDateLastNotify := Now;
          end;
          TThread.Sleep(500);
        end;
      except
        on E: Exception do
          HandleException(E);
      end;
    end);
end;

function TBirdSocketClient.SetBit(const AValue: Cardinal; const AByte: Byte): Cardinal;
begin
  Result := AValue or (1 shl AByte);
end;

end.

