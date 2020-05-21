# websocket-client
![Delphi Supported Versions](https://img.shields.io/badge/Delphi%20Supported%20Versions-10.1%20and%20ever-blue.svg)
![Platforms](https://img.shields.io/badge/Supported%20platforms-Win32%20and%20Win64-red.svg)

This is a client for websocket connection in Delphi.

## Prerequisites
 * `[Optional]` For ease I recommend using the Boss for installation
   * [**Boss**](https://github.com/HashLoad/boss) - Dependency Manager for Delphi

## Installation using Boss (dependency manager for Delphi applications)
```
boss install github.com/mateusvicente100/websocket-client
```   

## Manual Installation
Add the following folder to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
../websocket-client/src
```

## Getting Started
You need to use WebSocket.Server
```pascal
uses WebSocket.Client;
```

Create an instance of TWebSocketClient and assign the propertys and events listeners
```pascal
procedure Start;
var
  LWebSocket: TWebSocketClient;
begin
  LWebSocket := TWebSocketClient.New('ws://localhost:8080');
  LWebSocket.AddEventListener(TEventType.MESSAGE,
    procedure(const AText: string)
    begin
      Log(AText);
    end);
  LWebSocket.Connect;
  LWebSocket.Send('Hello Server');
end;
```

## Samples
Check out our sample project for the Delphi client websokect connection. If you have any questions or suggestion, please contact, make your pull request or create an issue.

## Delphi Client
![sample-client](samples/images/sample-client.png)