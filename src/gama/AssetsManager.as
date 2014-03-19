package gama
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class AssetsManager
	{

		/**
		 * 已经接手的任务数量
		 */
		internal static  var acceptedRequestCount:uint = 0 ;

		/**
		 * 给 file helper 删除本地缓存的钩子
		 * 签名：deleteFileCache(wuid:String):void
		 */
		internal static var fileCacheDeleteCall:Function;


		/**
		 * 给 file cache 用来读取缓存的钩子
		 * 签名： withdraw(wuid:String, callback:Function):Boolean
		 */
		internal static var fileWithdrawCall:Function = null;

		/**
		 * key: asset id, value: callback
		 */
		private static  const ASSET_ID_TO_CALLBACK:Dictionary = new Dictionary ;

		/**
		 * 最小允许的 asset id 长度
		 */
		private static const MIN_WUID_LENGTH:uint = Environment.MIN_WUID_LENGTH;

		/**
		 * 下载队列
		 */
		private static  const QUEUE_FETCHING:Vector.<String> = new Vector.<String> ;

		/**
		 * 当前还在处理中的任务总数
		 * @return
		 */
		internal static  function get outstandingJobCount():uint
		{
			return QUEUE_FETCHING.length;
		}

		/**
		 * 重置计数器
		 */
		public static  function resetCounts():void
		{
			acceptedRequestCount = 0;
//			LoadJob.outstandingJobCount = 0;
		}

		/**
		 * 结束所有当前任务
		 */
		public static  function terminate(resetCount:Boolean = true):void
		{
			Streamer.terminate();
//			LoadJob.terminate();
//			LoadJob.clearBlackList();

			if(resetCount) resetCounts();
		}

		/**
		 * 清空黑名单
		 */
		internal static  function clearBlackList():void
		{
//			LoadJob.clearBlackList();
		}

		/**
		 * 下载，异步的方式获得一个WUID对应的原始byte array
		 * @param wuid 所下载的文件的WUID
		 * @param func 这个下载请求完成时的事件处理器, func 的签名是 (assetData:ByteArray, wuid:String)
		 */
		internal static function fetchBinay(wuid:String, func:Function = null):void
		{
			// trace("[AssetsManager.fetchBinay] wuid:"+wuid+"; func:"+func);

			if(wuid == null || wuid.length < MIN_WUID_LENGTH || func == null)
			{
				throw(new ArgumentError);
				return ;
			}

			acceptedRequestCount ++;

			if(~QUEUE_FETCHING.indexOf(wuid))
			{
				trace("[AssetsManager.fetchBinay] already in queue, request cancelled, wuid:"+wuid);
				return;
			}

			ASSET_ID_TO_CALLBACK[wuid] = func;
			QUEUE_FETCHING.push(wuid);

			Tick.ticker.addEventListener(Event.ENTER_FRAME, checkFetchingQueue);
		}

		/**
		 * 从 Streamer 获得获取远程二进制流的结果
		 * @param error
		 * @param data
		 * @param wuid
		 * @param writeToCache 如果为 true 那么写入本地缓存
		 */
		internal static  function whenStreamArrive(error:ErrorEvent, wuid:String, sourceBa:ByteArray,   writeToCache:Boolean = true):void
		{
			// trace("[LoadJob(" + _wuid + ").whenStreamArrive] writeToCache:"+writeToCache);

			if(error != null)
			{ 	/* output this error */
				trace(Environment.$TRACE_MSG_ASSET_FETCH_FAILED + wuid + error);
			}


			/* 根据任务所请求的数据类型进行解析 */
			var processor:Function = ASSET_ID_TO_CALLBACK[wuid];
			delete ASSET_ID_TO_CALLBACK[wuid];

			if(processor == null)
			{
				trace("ERROR [AssetsManager.whenStreamArrive] missing processor for wuid:"+wuid);
				return;
			}

			/* 向外部返回获取来的二进制流 */
			processor(error, wuid, sourceBa);
		}

		/**
		 * 开始任务
		 */
		private static function checkFetchingQueue(event:Event = null):void
		{
			// trace("[AssetsManager.checkFetchingQueue] event:"+event);
			if(event != null) Tick.ticker.removeEventListener(Event.ENTER_FRAME, checkFetchingQueue);

			if(QUEUE_FETCHING.length === 0) return; /* no outstanding job */

			var wuid:String = QUEUE_FETCHING.shift();
			if (fileWithdrawCall != null &&  fileWithdrawCall(wuid , whenStreamWithdrawFromeLocalCache))
			{ /* 通过file withdraw 本地加载二进制 */
				//				trace("**** [LoadJob.start] 本地缓存命中, wuid:"+_wuid);
				return;
			}
			else
			{ /* 通过 http 远程加载 */
				// StreamerManager.fetch(wuid , whenStreamArrive);
				if(!Streamer.assignTask(wuid))
				{
					/* streamer 都在忙，所以将任务推回队列 */
					QUEUE_FETCHING.unshift(wuid);
				}
				else
				{
					checkFetchingQueue(); /* 将 streamer working 全部调动起来 */
				}
			}
		}

		/**
		 * 当从本地文件缓存中获得加载结果的时候
		 * @param error
		 * @param sourceBa
		 * @param wuid
		 */
		private static  function whenStreamWithdrawFromeLocalCache(error:ErrorEvent, sourceBa:ByteArray, wuid:String = null):void
		{
			if (error != null)
			{ /* 本地文件缓存失败 */
				trace("ERROR [LoadJob.whenStreamWithdrawFromeLocalCache] fail to withdraw stream from local cache, wuid:" + wuid);
				// preventFileCacheWhenFetchFailed(); /* 移除缓存 */
				if (fileCacheDeleteCall != null)fileCacheDeleteCall(wuid);

				// StreamerManager.fetch(wuid , whenStreamArrive);
				if(!Streamer.assignTask(wuid))
				{
					/* streamer 都在忙，所以将任务推回队列 */
					QUEUE_FETCHING.unshift(wuid);
				}
			}
			else
			{ /* 本地文件缓存加载成功 */
				whenStreamArrive(null, wuid, sourceBa, false);
			}
		}
	}
}