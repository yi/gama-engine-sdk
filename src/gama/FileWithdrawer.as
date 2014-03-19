package gama
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	internal class FileWithdrawer extends URLStream
	{

//		private static  const REUSABLE_BA:ByteArray = new ByteArray ;

		public function FileWithdrawer()
		{
			super();
			req = new URLRequest ;
		}

		private var _wuid:String;

		private var jobStartAt:uint ;

		/**
		 * 复用的请求
		 */
		private var req:URLRequest;

		/**
		 * 当前是否可用
		 */
		internal function get isAvailable():Boolean
		{
			// trace("[FileWithdrawer.isAvailable] _wuid:"+ _wuid);
			return _wuid == null;
		}

		internal function withdraw(wuid:String):void
		{
			_wuid = wuid;
			jobStartAt = getTimer();
			toggleListening(true);
			req.url = FileHelper.generateFileCacheUrl(wuid);
			// trace("[FileWithdrawer.withdraw] wuid:"+wuid+" url:"+req.url);
			load(req);
		}

		private function handleComplete(event:Event):void
		{
			// trace("[FileWithdrawer.handleComplete] event:"+event);

			toggleListening(false);

			var result:ByteArray = new ByteArray;
			readBytes(result);

			var byteLength:uint = result.length;

			if(connected) close(); /* stream 不能提前关闭，关闭了，就读不出 read bytes了 */
			var wuid:String = _wuid;
			_wuid = null;
			FileWithdrawerManager.resultFromWroker(null, wuid, result, getTimer() - jobStartAt, byteLength);
		}

		private function handleError(event:ErrorEvent):void
		{
			trace("[FileWithdrawer.handleError] event:"+event);
			toggleListening(false);
			if(connected) close();
			var wuid:String = _wuid;
			_wuid = null;
			FileHelper.deleteFileCache(wuid);
			FileWithdrawerManager.resultFromWroker(event, wuid, null);
		}


		private function toggleListening(value:Boolean):void
		{
			// trace("[FileWithdrawer.toggleListening] value:"+value);
			if(value)
			{
				// addEventListener(Event.COMPLETE, handleComplete);
				addEventListener(Event.COMPLETE, handleComplete)
				addEventListener(IOErrorEvent.IO_ERROR, handleError);
			}
			else
			{
				removeEventListener(Event.COMPLETE, handleComplete)
				removeEventListener(IOErrorEvent.IO_ERROR, handleError);
			}
		}
	}
}


