package gama
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setInterval;

	public class FileDepositerManager
	{

		/**
		 * 任务失败的次数
		 */
		public static  var countFailure:uint = 0 ;

		/**
		 * 请求获取的次数
		 */
		static public var countRequest:uint = 0 ;

		/**
		 * 写入的总量
		 */
		static public var countBytes:uint = 0 ;

		/**
		 * 任务成功的次数
		 */
		public static  var countSuccess:uint = 0 ;

		/**
		 * 读取总共消耗的ms
		 */
		static public var processedMsSpent:uint ;

		/**
		 * 允许磁盘写入的最小磁盘空间
		 */
		private static  const MIN_DISK_SPACE_FOR_WRITE:Number = 100 * 1024 * 1024 ; // 100m

		/**
		 * 是否耗尽了磁盘空间
		 */
		private static  var _runoutOfDiskSpace:Boolean = false;

		/**
		 * 磁盘所剩余的空间
		 */
		private static  var _spaceAvailable:Number = Number.MAX_VALUE;

		/**
		 * 当前正在写入的 byte array
		 */
		private static  var depositingByteArray:ByteArray ;

		/**
		 * 当前正在写入的 wuid
		 */
		internal static  var depositingWuid:String;

		/**
		 * 写入器
		 */
		private static  var writer:FileStream

		/**
		 * key: wuid, value: byte array to be saved to disk
		 */
		static private const QUEUE:Object = {} ;

		/**
		 * 添加写入请求
		 * @param wuid
		 * @param binary
		 */
		static internal function addToDepositQueue(wuid:String, binary:ByteArray):void
		{
			if(binary == null || binary.length == 0 || wuid == null)
			{
				trace("ERROR [FileDepositerManager.addToDepositQueue] bad request. wuid:"+wuid+"; binary:"+binary);
				return;
			}

			QUEUE[wuid] = binary;
		}

		/**
		 * 检查可写入的素材队列
		 * @param rest
		 */
		private static  function checkDepot(...rest):void
		{
			if(depositingByteArray != null)
			{ /* 当前正在写入中 */
				// trace("IGNORE [FileDepositerManager.checkDepot] in deposition ");
				return;
			}

			var wuid:String;
			for (wuid in QUEUE)
			{ /* 从队列中找出要写入磁盘的二进制 */
				depositingByteArray = QUEUE[wuid] as ByteArray;
				if(depositingByteArray != null) break;
			}

			if(depositingByteArray == null)
			{ /* 没有需要写入缓存的素材 */
				return;
			}
			else
			{ /* 找到二进制，顾从队列中移除之 */
				delete QUEUE[wuid];
			}

			if(FileHelper.isFileCacheExsit(wuid))
			{ /* 要写入的二进制已经存在于磁盘上 */
				delete QUEUE[wuid];
				depositingByteArray.length = 0;
				depositingByteArray = null;
				checkDepot();
				return;
			}

			startAt = getTimer();
			++countRequest;
			countBytes += depositingByteArray.length;
			toggleListening(true);
			try{
				writer.openAsync(FileHelper.getFileForWuid(wuid), FileMode.WRITE);
				writer.writeBytes(depositingByteArray);
				depositingWuid = wuid;
				trace("[FileDepositerManager.checkDepot] write to cache, wuid:"+wuid+", byte length:"+depositingByteArray.length);
			}
			catch(e:Error)
			{
				trace("ERROR [FileDepositerManager.checkDepot] fail to write data, wuid:"+wuid+", error:"+e);
				toggleListening(false);
			}
		}

		static private var startAt:uint ;

		/**
		 * 任务队列的长度
		 * @return
		 */
//		public static  function get queueLength():uint
//		{
//			return AssetsDepot.DEPOSIT_LOG.length;
//		}

		/**
		 * 是否耗尽了磁盘空间
		 */
		public static  function get runoutOfDiskSpace():Boolean
		{
			return _runoutOfDiskSpace;
		}

		/**
		 * 返回磁盘所剩余的空间
		 */
		public static  function get spaceAvailable():Number
		{
			return _spaceAvailable;
		}

		/**
		 * FileDepositerManager 必须显性的 init 之后，才会工作
		 * 这样设计是为了保证一个 assetsmanager.swc 可以同时被 Flash Player 和 AIR 使用
		 */
		internal static  function init():void
		{
			checkDiskSpace();
			if(_runoutOfDiskSpace)
			{
				trace("WARNING [FileDepositerManager.init] run out of disk space");
				return;
			}

			// LoadJob.fileDepositCall = addToDepositQueue;

			/* 每15秒检查一次是否还有足够的磁盘空间 */
			// setInterval(checkDiskSpace, 15000);

			/* 每2秒钟检查一次写入 */
			setInterval(checkDepot, 2000);

			writer = new FileStream;
			writer.addEventListener(Event.CLOSE, checkDepot);
			checkDepot();
		}

		/**
		 * 检查是否还有足够的磁盘空间
		 */
		private static  function checkDiskSpace():void
		{
			_spaceAvailable = File.applicationStorageDirectory.spaceAvailable ;
			_runoutOfDiskSpace = _spaceAvailable < MIN_DISK_SPACE_FOR_WRITE;
			// trace("[FileDepositerManager.checkDiskSpace] _spaceAvailable:"+_spaceAvailable+"; _runoutOfDiskSpace:"+_runoutOfDiskSpace);
		}

		private static  function handleError(event:ErrorEvent):void
		{
			trace("[FileDepositerManager.handleError] error:"+event);
			countFailure ++;
			FileHelper.deleteFileCache(depositingWuid);
			toggleListening(false);
		}

		private static  function handleOutputProgress(event:OutputProgressEvent):void
		{
			// trace("[FileDepositer(#"+_id+").handleOutputProgress] event:"+event);
			if(event.bytesPending > 0) return;

			countSuccess ++;
			processedMsSpent += getTimer() - startAt;
			toggleListening(false);
		}

		private static  function toggleListening(value:Boolean):void
		{
			// trace("[FileDepositer(#"+_id+").toggleListening] value:"+value);
			if(value)
			{
				writer.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, handleOutputProgress);
				writer.addEventListener(IOErrorEvent.IO_ERROR, handleError);
			}
			else
			{
				writer.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, handleOutputProgress);
				writer.removeEventListener(IOErrorEvent.IO_ERROR, handleError);
				writer.close();
				if(depositingByteArray != null)
				{
					depositingByteArray.length = 0;
					depositingByteArray = null;
				}
				depositingWuid = null;
			}
		}
	}
}