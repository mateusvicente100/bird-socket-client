{
  Class to monitor the connection status of a Bird Socket Client and attempt reconnection if the connection is lost.
}

unit Bird.Socket.Client.ConnectionMonitor;

interface

uses
  System.Classes,
  System.SysUtils;

type
  TBirdSocketClientConnectionMonitor = class(TThread)
  private
    /// <summary>
    /// Interval between connection status checks, in milliseconds.
    /// </summary>
    FInterval: Integer;
    /// <summary>
    /// Function to check the current connection status. Should return True if connected, False otherwise.
    /// </summary>
    FOnStatusCurrentConnection: TFunc<Boolean>;
    /// <summary>
    /// Procedure to attempt reconnection if the connection is lost.
    /// </summary>
    FOnReconnect: TProc;
    /// <summary>
    /// Indicates if the monitor is currently trying to reconnect.
    /// </summary>
    FTryingConnect: Boolean;
  protected
    /// <summary>
    /// Main execution method for the thread. Periodically checks the connection status and attempts reconnection if necessary.
    /// </summary>
    procedure Execute; override;
  public
    /// <summary>
    /// Creates an instance of the connection monitor thread.
    /// </summary>
    /// <param name="ACreatedSuspended">Indicates if the thread should be created in a suspended state.</param>
    /// <param name="AInterval">Interval between connection status checks, in milliseconds.</param>
    /// <param name="AOnStatusCurrentConnection">Function to check the current connection status.</param>
    /// <param name="AOnReconnect">Procedure to attempt reconnection if the connection is lost.</param>
    constructor Create(const ACreatedSuspended: Boolean; const AInterval: Integer;
      const AOnStatusCurrentConnection: TFunc<Boolean>; const AOnReconnect: TProc);
  end;

implementation

uses
  System.DateUtils;

{ TBirdSocketClientConnectionMonitor }

constructor TBirdSocketClientConnectionMonitor.Create(const ACreatedSuspended: Boolean; const AInterval: Integer;
  const AOnStatusCurrentConnection: TFunc<Boolean>; const AOnReconnect: TProc);
begin
  inherited Create(ACreatedSuspended);
  FInterval := AInterval;
  FOnStatusCurrentConnection := AOnStatusCurrentConnection;
  FOnReconnect := AOnReconnect;
  FTryingConnect := False;
  FreeOnTerminate := False;
end;

procedure TBirdSocketClientConnectionMonitor.Execute;
var
  LStatusConnection: Boolean;
  lStart: TDateTime;
begin

  while not terminated do
  begin
    lStart := Now;

    while (not terminated) and (MilliSecondsBetween(Now, lStart) < FInterval) do
      Sleep(100);

    if not Assigned(FOnStatusCurrentConnection) then
      raise Exception.Create('The connection status check event has not been set!');

    if not Assigned(FOnReconnect) then
      raise Exception.Create('The reconnect event has not been set!');

    LStatusConnection := FOnStatusCurrentConnection;

    if not terminated and not FTryingConnect and not LStatusConnection then
    begin
      FTryingConnect := True;
      try
        TThread.Synchronize(TThread.Current,
          procedure
          begin
            FOnReconnect;
          end);
      finally
        FTryingConnect := False;
      end;
    end;

  end;

end;

end.
