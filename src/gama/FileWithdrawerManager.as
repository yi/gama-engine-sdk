package gama
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;

	public class FileWithdrawerManager
	{

		/**
		 * streamer worker 的总数
		 */
		static public const numOfWorkers:uint = 2;

		/**
		 * worker列表
		 */
		static private const workers:Vector.<FileWithdrawer> = new Vector.<FileWithdrawer>(numOfWorkers, true) ;

		/**
		 * 异步的 withdraw 队列
		 */
		static private var QUEUE:Vector.<String> = new Vector.<String> ;

		/**
		 * 每个  withdraw 请求所对应的回调方法
		 */
		static private var withdrawCallbacks:Dictionary = new Dictionary;

//		/**
//		 * worker 的总数
//		 */
//		static private var worker:FileWithdrawer = new FileWithdrawer;

		/**
		 * wuid的标准长度
		 */
		private static const MIN_WUID_LENGTH:int = Environment.MIN_WUID_LENGTH;

		/**
		 * 任务队列的长度
		 * @return
		 */
		static public function get queueLength():uint
		{
			return QUEUE.length;
		}

		/**
		 * 从本地文件缓存中读取内容
		 *
		 * @param wuid
		 * @param parseType
		 * @param callback
		 * @return  true: 表示成功加入本地缓存的加载队列， false 表示本地没有这个缓存，或者不支持这个缓存类型
		 */
		internal static  function withdraw(wuid:String, callback:Function):Boolean
		{
			// trace("[FileWithdrawerManager.withdraw] wuid:"+wuid);

			if(wuid == null || wuid.length < MIN_WUID_LENGTH)
			{
				trace("CANCLE [FileWithdrawerManager.withdraw] bad argument wuid:"+wuid);
				return false;
			}

			if(!FileHelper.isFileCacheExsit(wuid))
			{
				// trace("CANCLE [FileWithdrawerManager.withdraw] 本地没有这个缓存");
				return false;
			}

			if(withdrawCallbacks[wuid] != null)
			{
				// trace("CANCLE [FileWithdrawerManager.withdraw] 发现已经在请求中的相同的 wuid:"+wuid);
				return false;
			}

			++countRequest;
			QUEUE.push(wuid);
			withdrawCallbacks[wuid] = callback;

			// PlayerHeader.CALLBACK_ENTER_FRAME.addOnce(checkWorker);
			setTimeout(checkWorker, 10);
			return true;
		}

		/**
		 * 请求获取的次数
		 */
		static public var countRequest:uint = 0 ;


		/**
		 * FileDepositerManager 必须显性的 init 之后，才会工作
		 * 这样设计是为了保证一个 assetsmanager.swc 可以同时被 Flash Player 和 AIR 使用
		 */
		static internal function init():void
		{
			/* 挂钩到 LoadJob 上 */
			// LoadJob.fileWithdrawCall = withdraw;

			for (var i:int = 0; i < workers.length; i++)
			{
				workers[i] = new FileWithdrawer;
			}

		}

		/**
		 * 任务成功的次数
		 */
		static public var countSuccess:uint = 0 ;

		/**
		 * 任务失败的次数
		 */
		static public var countFailure:uint = 0 ;

		/**
		 * 所有任务累积的消耗的毫秒
		 */
		static public var countMSSpent:uint = 0;

		/**
		 * 写入的总量
		 */
		static public var countBytes:uint = 0 ;

		/**
		 * 收到worker 发来的结果
		 * @param errorEvent
		 * @param file
		 * @param data
		 * @param msSpent
		 */
		static internal function resultFromWroker(errorEvent:ErrorEvent, wuid:String, data:ByteArray, msSpent:uint = 0, byteLength:uint = 0):void
		{
			// trace("[FileWithdrawerManager.resultFromWroker] error:"+errorEvent+"; wuid:"+wuid+"; data:"+data);

			if(errorEvent == null)
			{
				++ countSuccess;
				countMSSpent += msSpent;
				countBytes += byteLength;
			}
			else
			{
				++ countFailure;
			}

			var callback:Function = withdrawCallbacks[wuid];
			delete withdrawCallbacks[wuid];

			/* whenStreamArrive(error:ErrorEvent, sourceBa:ByteArray, wuid:String = null, writeToCache:Boolean = true) */
			callback(errorEvent, data, wuid);

			// checkWorker();
			// PlayerHeader.CALLBACK_ENTER_FRAME.addOnce(checkWorker);
			setTimeout(checkWorker, 10);
		}

		/**
		 * 给 worker 分配任务
		 * @param event
		 */
		static private function checkWorker(event:Event = null):void
		{
			var wuid:String;

			for each (var worker:FileWithdrawer in workers)
			{

				if(QUEUE.length == 0)
				{
					// trace("[FileWithdrawerManager.checkWorker] queue is clear");
					return;
				}
				if(worker.isAvailable)
				{
					// wuid = wuidQueue.shift();
					wuid = QUEUE.shift();

					if(wuid === FileDepositerManager.depositingWuid)
					{ /* 避免写入和读取冲突 */
						QUEUE.push(wuid);
					}
					else
					{
						worker.withdraw(wuid);
					}
				}
			}
		}

	}
}
