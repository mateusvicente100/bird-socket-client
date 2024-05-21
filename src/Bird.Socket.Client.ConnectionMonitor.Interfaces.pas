unit Bird.Socket.Client.ConnectionMonitor.Interfaces;

interface

type

  /// <summary>
  /// Interface representing the connection monitor parameters.
  /// </summary>
  IBirdSocketClientConnectionMonitorParams = interface
    ['{CDEF540C-E21C-46B6-8551-894CF00661ED}']
    /// <summary>
    /// Sets the active status of the connection monitor.
    /// </summary>
    /// <param name="AValue">Boolean value indicating if the monitor should be active.</param>
    /// <returns>The updated connection monitor parameters interface.</returns>
    function Active(const AValue: Boolean): IBirdSocketClientConnectionMonitorParams;

    /// <summary>
    /// Sets the interval for the connection check.
    /// </summary>
    /// <param name="AValue">Interval value in milliseconds.</param>
    /// <returns>The updated connection monitor parameters interface.</returns>
    function Interval(const AValue: Integer): IBirdSocketClientConnectionMonitorParams;
  end;

  /// <summary>
  /// Interface representing the connection monitor.
  /// </summary>
  IBirdSocketClientConnectionMonitor = interface
    ['{933093C3-20AB-4A31-8DA0-31F60EC57189}']
    /// <summary>
    /// Sets up auto-reconnect parameters for the connection monitor.
    /// </summary>
    /// <returns>The connection monitor parameters interface.</returns>
    function AutoReconnect: IBirdSocketClientConnectionMonitorParams;
  end;

implementation

end.
