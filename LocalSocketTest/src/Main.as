package 
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Main extends Sprite 
	{
		private var _listen:LocalSocket;
		private var _server:LocalSocket;
		private var _client:LocalSocket;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			_listen = new LocalSocket();
			_listen.listen( "myconn", this.onClientConnected );
			
			_client = new LocalSocket();
			_client.addEventListener( LocalSocket.LOCAL_SOCKET_CONNECTED, this.clientSocketConnected );
			_client.addHandler( "foo", this.foo );
			_client.connect( "myconn" );
		}
		
		private function onClientConnected( newSocket:LocalSocket ):void
		{
			_server = newSocket;
			_server.addHandler( "bar", this.bar );
		}
		
		private function clientSocketConnected( event:Event ):void
		{
			_client.send( "bar", "client sending data to server" );
		}
		
		// Client function
		private function foo( data:String ):void
		{
			trace( "foo called with data:", data );
		}
		
		// Server function
		private function bar( data:String ):void
		{
			trace( "bar called with data:", data );
			
			_server.send( "foo", "server replying to client" );
		}
	}
	
}