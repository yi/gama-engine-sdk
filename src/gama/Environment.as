package gama
{
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.events.TextEvent;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.utils.ByteArray;

	internal final class Environment
	{

		internal static  const $TIMEOUT:String = "Timeout" ;

		internal static  const $RECTS:String = "[SDK] " ;

		internal static  const $TRACE_MSG_ASSET_FETCH_FAILED:String = $RECTS + "fail to fetch asset, wuid:" ;

		internal static  const $TRACE_MSG_DOWNLOADING:String = $RECTS + "downloading:" ;

		internal static  const $TRACE_MSG_DEPOSITE_TEXTURE:String = $RECTS + "deposite texture: " ;

		internal static  const $TRACE_MSG_ADD_RENDER_JOB:String = $RECTS + "add render job: " ;

		internal static  const $TRACE_MSG_INVALID_RENDER_JOB:String = $RECTS + "invalid render job: " ;

		internal static  const $TRACE_MSG_FLUSH_TEXTURE:String = $RECTS + "number of textures flushed from memory: " ;

		internal static  const $TRACE_MSG_FLUSH_RENDER_BATCH:String = $RECTS + "all render batch flushed: " ;

		internal static  const $TRACE_MSG_NON_RENDERABLE_OBJECT:String = $RECTS + "non-renderable object: " ;

		internal static  const $TRACE_MSG_MISSING_ASSET:String = $RECTS + "missing asset for: " ;

//		internal static var ASSETS_HOST:String = "rg.sgfgames.com/";

		static public var isVebos:Boolean = false;

		static internal var logDispatcher:EventDispatcher = new EventDispatcher ;

		static private const EVENT_LOG:TextEvent = new TextEvent("log");

		static internal function log(msg:String):void
		{
			if(isVebos)
			{
				trace(msg);
				EVENT_LOG.text = msg;
				logDispatcher.dispatchEvent(EVENT_LOG);
			}
		}

		/**
		 * 加载远程二进制流的过期时间，单位 毫秒
		 */
		static internal var REMOTE_FETCHING_TIMEOUT:uint = 1000 ;

		/**
		 * 素材文件的扩展名
		 */
		internal static var ASSET_FILE_EXT:String = ".rgm";

		/**
		 * 素材文件在服务器上的存放路径
		 */
		internal static var ASSET_FILE_PATH:String = "";

		/**
		 * 是否是以独立的应用程序模式在运行
		 */
		internal static  const IS_RUN_AS_APP:Boolean = Capabilities.playerType.toLowerCase() == "desktop";

		/**
		 * 是否是ARM芯片，如果是 ARM 芯片的话，在渲染层降低开销
		 */
		internal static  const IS_ARM_CPU:Boolean = (IS_RUN_AS_APP && Capabilities.cpuArchitecture == "ARM");

		/**
		 * 是否是在 iPhone 模式下运行
		 */
		internal static const IS_RUN_ON_IOS:Boolean = (IS_RUN_AS_APP && (Capabilities.manufacturer.toLowerCase() == "adobe ios"));

		/**
		 * 是否是在 Android 模式下运行
		 */
		internal static const IS_RUN_ON_ANDROID:Boolean = (IS_RUN_AS_APP && (Capabilities.manufacturer.toLowerCase() == "android linux"));

		/**
		 * 当前所运行的设备的类型名字
		 */
		internal static const DEVICE_OS_TYPE:String = IS_RUN_ON_IOS ? "ios" : IS_RUN_ON_ANDROID ? "android" : "desktop";

		/**
		 * wuid的标准长度
		 */
		internal static var MIN_WUID_LENGTH:uint = 3;

		/**
		 * 一个复用的错误事件
		 */
		internal static const REUSABLE_ERROR_EVENT:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR) ;

		internal static  const $QUESTION_MARK:String = "?" ;

		/**
		 * 可复用的Array
		 */
		internal static const REUSABLE_ARRAY:Array = [];

		/**
		 * 可复用的 byte array
		 */
		internal static const reusableByteArray:ByteArray = new ByteArray;

		/**
		 * 返回一个素材的下载地址字符串
		 * @param wuid 素材的WUID
		 * @param forceFresh 默认为 false, 如果为 true，那么生产的下载地址中会带有服务器素材时间戳，以跳过浏览器缓存中的老版本文件
		 * @return 素材的下载地址字符串
		 */
		internal static function getAssetURL(wuid:String):String
		{
			if(wuid == null || wuid.length < Environment.MIN_WUID_LENGTH)
			{
				// trace(" ERROR [AssetsHelper.getAssetURL] 无效的 wuid: "+wuid);
				throw(new ArgumentError);
				return null;
			}
			// return "http://"+ ASSETS_HOST +"/"+ ASSET_FILE_PATH + wuid + ASSET_FILE_EXT;
			return "http://rg.sgfgames.com/binaries/"+wuid+"/"+DEVICE_OS_TYPE;
		}


		/**
		 * 禁止一个可交互对象上的所有交互行为
		 * @param interactiveObj
		 */
		internal static  function disableInteractive(interactiveObj:InteractiveObject):void
		{
			interactiveObj.mouseEnabled = false;
			interactiveObj.tabEnabled = false;

			/* disable interaction for text field */
			var tf:TextField = interactiveObj as TextField;
			if (tf != null)
			{
				tf.border = false;
				tf.background = false;
				tf.selectable = false;
				tf.multiline = false;
				tf.mouseWheelEnabled = false;
			}

			var disoc:DisplayObjectContainer = interactiveObj as DisplayObjectContainer;
			if (disoc != null)
			{
				disoc.mouseChildren = false;
			}
		}
	}
}