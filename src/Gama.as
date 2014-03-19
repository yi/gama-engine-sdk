package
{
	import flash.display.Stage;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import gama.FPSPlayerHeader;
	import gama.RectEngine;

	public final class Gama
	{
		/**
		 * 版本号
		 */
		public static  const VERSION:String = "0.2.0";

		/**
		 * 跳帧管理器
		 */
		private static  const TICK_WATCHING_RENDERBALE:Dictionary = new Dictionary(true);

		/**
		 * 将 IRenderableRect 加入渲染队列
		 * @param rest
		 */
		public static  function addToRenderBatch(...rest:Array):void
		{
			if(rest.length > 0)RectEngine.addToWatch.apply(null, rest);
		}


		static public function set verbos(value:Boolean):void
		{
			RectEngine.verbos = value;
		}

		/**
		 * 将 IRenderableRect 加入跳帧队列
		 * @param rest
		 */
		public static  function addToTickWatch(...rest:Array):void
		{
			for each (var renderable:IRenderableRect in rest)
			{
				if(renderable) TICK_WATCHING_RENDERBALE[renderable] = Gama;
			}
		}

		/**
		 * 清空内存中的贴图
		 */
		public static  function flushTextures():void
		{
			RectEngine.flushTextures();
		}

		/**
		 * 清空渲染任务队列
		 */
		public static  function flushRenderBatch():void
		{
			RectEngine.flushRenderBatch()
		}

		/**
		 * 列出当前的渲染对象队列
		 * @return
		 */
		public static  function dumpRenderBatch():Vector.<IRenderableRect>
		{
			return RectEngine.dumpWatchlist();
		}

		/**
		 * 引擎初始化
		 * @param stage
		 * @param callback
		 *
		 */
		public static function init(stage:Stage, callback:Function):void
		{
			RectEngine.init(stage, callback);
		}


		static public function addLogListener(callback:Function):void
		{
			RectEngine.addLogListener(callback);
		}

		static public function removeLogListener(callback:Function):void
		{
			RectEngine.removeLogListener(callback);
		}

		/**
		 * 载入远程 texture
		 * @param rest
		 */
		static public function loadRemoteTexture(...assetIds:Array):void
		{
			trace("[Rects.loadRemoteTexture] assetsIds:"+assetIds);

			for (var i:int = 0, n:int = assetIds.length, assetId:String; i < n; i++)
			{
				assetId = String(assetIds[i] || "");
				if(assetId != null && assetId.length > 3) RectEngine.loadRemoteTexture(assetId);
			}
		}

		/**
		 * 从渲染列表中 移除 IRenderableRect
		 * @param rest
		 *
		 */
		public static  function removeFromRenderBatch(...rest:Array):void
		{
			if(rest.length > 0)RectEngine.removeFromWatch.apply(null, rest);
		}

		/**
		 * 从跳帧列表中 移除 IRenderableRect
		 * @param rest
		 */
		public static  function removeFromTickWatch(...rest:Array):void
		{
			for each (var renderable:IRenderableRect in rest)
			{
				if(renderable in TICK_WATCHING_RENDERBALE) delete TICK_WATCHING_RENDERBALE[renderable];
			}
		}

		/**
		 * 设定跳帧的帧频
		 * @param value
		 */
		public static  function setFps(value:uint):void
		{
			FPSPlayerHeader.setFps(value);
		}

		/**
		 * 在逻辑帧跳帧的时候，变更  IRenderableRect 的帧数
		 * @param value
		 */
		private static  function whenFramePast(value:int):void
		{
			// trace("[Rects.whenFramePast] value:"+value);
			for (var key:IRenderableRect in TICK_WATCHING_RENDERBALE)
			{
				key.frameId += value;
			}
		}

		CONFIG::debugging
		{
			/**
			 * 导入二进制流的贴图
			 */
			public static function depositeTexture(wuid:String , buffer:ByteArray):void
			{
				trace("[Rects.depositeTexture] wuid:"+wuid);
				RectEngine.depositeTexture(wuid, buffer);
			}
		}

		{
			/* static init */
			FPSPlayerHeader.onFramePast.add(whenFramePast);
		}
	}
}