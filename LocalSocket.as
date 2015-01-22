package  
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	public class LocalSocket extends EventDispatcher
	{
		public static const LOCAL_SOCKET_CONNECTED:String = "localSocketConnected";
		
		public var timeout:uint = 10000;
		
		private var _localConnection:LocalConnection;
		private var _connectionName:String;
		private var _destinationConnectionName:String;
		
		// Listen related
		private var _onClientConnectedCallback:Function;
		
		// Connect related
		private var _connectTimestamp:int;
		private var _connectTimer:Timer;
		private var _connectDestination:String;
		
		public function LocalSocket() 
		{
			_localConnection = new LocalConnection();
			_localConnection.client = new Object();
		}
		
		public function connect( connectionName:String ):void
		{
			this.generateRandomConnectionName();
			_localConnection.client["handshakeAccepted"] = this.handshakeAccepted;
			_localConnection.addEventListener( StatusEvent.STATUS, this.handshakeRequestStatus, false, 0, true );
			
			_connectDestination = connectionName;
			_connectTimestamp = getTimer();
			_connectTimer = new Timer( 1000, 1 );
			_connectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, this.attemptConnection, false, 0, true );
			this.attemptConnection();
		}
		
		public function listen( connectionName:String, onClientConnected:Function ):void
		{
			_onClientConnectedCallback = onClientConnected;
			_localConnection.client["handshakeRequested"] = this.handshakeRequested;
			_localConnection.connect( connectionName );
		}
		
		public function send( functionName:String, ...args ):void
		{
			args.unshift( functionName );
			args.unshift( _destinationConnectionName );
			
			_localConnection.send.apply( _localConnection, args );
		}
		
		public function addHandler( functionName:String, callback:Function ):void
		{
			_localConnection.client[functionName] = callback;
		}
		
		private function handshakeRequested( replyConnectionName:String ):void
		{
			var newSocket:LocalSocket = new LocalSocket();
			newSocket.generateRandomConnectionName();
			newSocket._destinationConnectionName = replyConnectionName;
			
			_localConnection.send( replyConnectionName, "handshakeAccepted", newSocket._connectionName );
			
			_onClientConnectedCallback( newSocket );
		}
		
		private function handshakeAccepted( replyConnectionName:String ):void
		{
			_destinationConnectionName = replyConnectionName;
			dispatchEvent( new Event( LOCAL_SOCKET_CONNECTED ) );
		}
		
		private function handshakeRequestStatus( event:StatusEvent ):void
		{
			if( event.level == "error" )
			{
				if( ( getTimer() - _connectTimestamp ) < timeout )
				{
					_connectTimer.start();
				}
				else
				{
					trace( "connection timed out" );
				}
			}
		}
		
		private function attemptConnection( event:TimerEvent = null ):void
		{
			// Have to double check connection wasnt successful, as LocalConnection StatusEvents
			// can return false negatives sometimes
			if( _destinationConnectionName == null )
			{
				_localConnection.send( _connectDestination, "handshakeRequested", _connectionName );
			}
		}
		
		private function generateRandomConnectionName():void
		{
			do
			{
				var success:Boolean = true;
				
				_connectionName = String( Math.random() );
				try
				{
					_localConnection.connect( _connectionName );
				}
				catch( e:ArgumentError )
				{
					// Very unlikely that this will ever trigger
					success = false;
				}
			}
			while( success == false )
		}
	}
}