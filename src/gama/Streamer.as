package gama
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	internal class Streamer extends URLStream
	{

		/**
		 * streamer worker 的总数
		 */
		static private var _numOfWorkers:uint = Environment.IS_ARM_CPU ? 2 : 4 ;

		/**
		 * worker列表
		 */
		static private const workers:Vector.<Streamer> = new Vector.<Streamer>(_numOfWorkers, true) ;


		/**
		 * 素材文件的扩展名
		 */
		private static var ASSET_FILE_EXT:String = Environment.ASSET_FILE_EXT;

		/**
		 * 素材文件的扩展名
		 */
		private static var PREINSTALL_ASSET_PROTOCOL:String = "app:/data/";

		/**
		 * 实例数量的计数器
		 */
		private static  var count:uint ;

		/**
		 * 构造函数
		 */
		public function Streamer()
		{
			super();
			_id = count++;
			req = new URLRequest ;
		}

		/**
		 * 实例的编号
		 */
		private var _id:uint ;

		/**
		 * 当前正在处理的 wuid
		 */
		private var _wuid:String ;

		/**
		 * 加载超时的 timeout interval
		 */
		private var intervalTimeout:uint ;

		/**
		 * 复用的请求
		 */
		private var req:URLRequest;

		private var startAt:uint;


		/**
		 * 是否是以 app 模式运行的
		 */
		static private const IS_RUN_AS_APP:Boolean = Environment.IS_RUN_AS_APP ;


		/**
		 * 随安装一起到来的素材文件
		 */
		static internal const ASSET_WUIDS_WITH_INSTALLATION:Object = {} ;

		/**
		 * 分配任务
		 * @param wuid
		 * @return 如果成功分配了任务，那么返回 true, 否则返回 false
		 */
		static internal function assignTask(wuid:String):Boolean
		{
			// trace("[Streamer.assignTask] wuid:"+wuid);

			for each (var worker:Streamer in workers)
			{
				if(worker.isAvailable)
				{
					if(IS_RUN_AS_APP && (wuid in ASSET_WUIDS_WITH_INSTALLATION))
					{
						trace("****[StreamerManager.checkWorker] 从预装目录缓存命中, wuid:"+wuid);
						worker.fetch(wuid, null, true);
					}
					else
					{
						worker.fetch(wuid);
					}

					return true;
				}
			}

			return false;
		}


		/**
		 * 读取远程数据流
		 * @param wuid
		 * @param queryString get url后的query部分
		 * @param fromPreinstalledAssets  如果为 true 的话，采用 app:// 协议从本机预装的素材中读取
		 */
		private function fetch(wuid:String, queryString:* = null, fromPreinstalledAssets:Boolean = false):void
		{
			// trace("[Streamer("+_id+").fetch] wuid:"+wuid+"; queryString:"+queryString);
			if(!isAvailable)
			{
				// throw(new VerifyError);
				trace("ERROR [Streamer("+_id+").fetch] not available");
				return;
			}

			_wuid = wuid;


			if(fromPreinstalledAssets)
			{
				req.url = PREINSTALL_ASSET_PROTOCOL+wuid+ASSET_FILE_EXT;
				// trace("****[Streamer.fetch] 从预装素材中读取:"+req.url);
			}
			else
			{
				if(queryString == null)
				{
					req.url = Environment.getAssetURL(wuid);
				}
				else
				{
					req.url = Environment.getAssetURL(wuid) + Environment.$QUESTION_MARK + queryString;
				}
			}

			Environment.log(Environment.$TRACE_MSG_DOWNLOADING + req.url);

			listenToStreamEvent(true);

			intervalTimeout = setTimeout(timeout, Environment.REMOTE_FETCHING_TIMEOUT);

			// trace("[Streamer.fetch] url:"+req.url);

			try
			{
				startAt = getTimer();
				load(req);
			}
			catch(e:Error)
			{
				Environment.REUSABLE_ERROR_EVENT.text = e.message;
				handleError(Environment.REUSABLE_ERROR_EVENT);
			}
		}

		/**
		 * 当前是否可用
		 */
		public function get isAvailable():Boolean
		{
			return _wuid == null;
		}

		/**
		 * 取消当前的加载
		 */
		public function stopConnection():void
		{
			// trace("[Streamer.stop] ");
			if(isAvailable) return;

			try
			{
				close();
			}
			catch(e:Error)
			{
				// do nothing
			}

			handleError(Environment.REUSABLE_ERROR_EVENT);
		}

		/**
		 * 清楚加载超时判定
		 */
		private function clearFetchTimeout():void
		{
			if(intervalTimeout > 0)clearTimeout(intervalTimeout);
			intervalTimeout = 0;
		}

		/**
		 * 成功读取流
		 * @param event
		 */
		private function handleComplete(event:Event):void
		{
			// trace("[Streamer("+_id+").handleComplete] wuid:"+_wuid);

			clearFetchTimeout();
			listenToStreamEvent(false);

			var tempWuid:String = _wuid;
			_wuid = null;

			var ba:ByteArray = new ByteArray;
			readBytes(ba);
			if(connected)close();
			AssetsManager.whenStreamArrive(null, tempWuid, ba);
		}


		/**
		 * 结束所有当前任务
		 */
		static internal function terminate():void
		{
			// trace("[StreamerManager.terminate] ");
			for each (var worker:Streamer in workers)
			{
				worker.stopConnection();
			}
		}

		/**
		 * 无法读取流
		 * @param event
		 */
		private function handleError(event:ErrorEvent):void
		{
			// trace("[Streamer("+_id+").handleError] wuid:"+_wuid);

			clearFetchTimeout();
			listenToStreamEvent(false);

			var tempWuid:String = _wuid;
			_wuid = null;
			if(connected)close();

			AssetsManager.whenStreamArrive(event, tempWuid, null);
		}




		/**
		 * 监听或不监听数据流的事件
		 * @param value true 开始监听数据流的事件， false 停止监听
		 */
		private function listenToStreamEvent(value:Boolean):void
		{
			// trace("[Streamer.listenToStreamEvent] value:"+value);
			if(value)
			{
				addEventListener(Event.COMPLETE, handleComplete);
				addEventListener(IOErrorEvent.IO_ERROR, handleError);
				addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleError);
			}
			else
			{
				removeEventListener(Event.COMPLETE, handleComplete);
				removeEventListener(IOErrorEvent.IO_ERROR, handleError);
				removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleError);
			}
		}

		/**
		 * 加载超时
		 */
		private function timeout():void
		{
			// trace("[Streamer.timeout] ");
			Environment.REUSABLE_ERROR_EVENT.text = Environment.$TIMEOUT;
			handleError(Environment.REUSABLE_ERROR_EVENT);
		}

		/* static init */
		{
			while(_numOfWorkers > 0)
			{
				workers[_numOfWorkers - 1] = new Streamer;
				--_numOfWorkers;
			}
		}

	}
}