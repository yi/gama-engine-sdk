package gama
{
	import flash.display3D.Context3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	internal final class TextureManager
	{
		/**
		 * key: wuid, value: SAATexture instance
		 */
		internal static const WUID_TO_INSTANCE:Dictionary = new Dictionary;

		/**
		 * min length of wuid string
		 */
		private static  const MIN_WUID_LENGTH:uint = 3 ;

		/**
		 * 在全局环境下预留的素材的 wuid
		 * note 需要保留的，都注册到这里
		 */
		private static  const PRESEVERED_WUIDS:Dictionary            = new Dictionary;

		/**
		 * 渲染目标列表
		 */
		private static  const WATCH_LIST:Array = [];

		/**
		 * 渲染目标
		 */
		private static  var renderContext:Context3D;

		/**
		 * 清空渲染队列
		 */
		internal static function flushRenderBatch():void
		{
			Environment.log(Environment.$TRACE_MSG_FLUSH_RENDER_BATCH);
			WATCH_LIST.length = 0;
		}

		/**
		 * 清空素材
		 */
		internal static function flushTexture():void
		{
			var arr:Array = Environment.REUSABLE_ARRAY;
			arr.splice(0 , arr.length);

			for (var key:Object in WUID_TO_INSTANCE)
			{
				if (!(key in PRESEVERED_WUIDS))
					arr.push(key);
			}

			var texture:BaseTexture;

			Environment.log(Environment.$TRACE_MSG_FLUSH_TEXTURE + arr.length);

			for each (var wuid:String in arr)
			{
				texture = WUID_TO_INSTANCE[wuid] as BaseTexture;
				if(texture != null) texture.dispose();
				delete WUID_TO_INSTANCE[wuid];
			}
			arr.length = 0;
		}

		static internal function dumpWatchlist():Array
		{
			return WATCH_LIST.concat();
		}

		/**
		 * 暂停渲染
		 */
		internal static function stopRendering():void
		{
			Tick.ticker.removeEventListener(Event.ENTER_FRAME, render);
		}

		/**
		 * 加入需要持久保存的 素材 wuid
		 * @param wuid
		 */
		internal static  function addPreseveredWuid(wuid:String):void
		{
			if (wuid == null || wuid.length < MIN_WUID_LENGTH)
			{
				trace("ERROR [SAATexture.AddPreseveredWuid] bad wuid:" + wuid);
				return;
			}

			if (wuid in PRESEVERED_WUIDS)
				return; /* wuid already added */

			PRESEVERED_WUIDS[wuid] = SAATexture;
		}

		/**
		 * 将一个或者多个可渲染对象添加到被渲染列表中去
		 * @param rest
		 */
		internal static  function addToWatch(...rest:Array):void
		{
			for each (var el: Object in rest)
			{
				if(el is IRenderableRect || el is Vector.<IRenderableRect> || el is Array)
				{
					WATCH_LIST.push(el);
					Environment.log(Environment.$TRACE_MSG_ADD_RENDER_JOB + el);
				}
				else
				{
					Environment.log(Environment.$TRACE_MSG_INVALID_RENDER_JOB);
				}
			}
		}

		internal static function withdrawTexture(wuid:String):BaseTexture
		{
			/* found in cache */
			if (WUID_TO_INSTANCE[wuid] != null)
			{
				return WUID_TO_INSTANCE[wuid] as BaseTexture;
			}
			else
			{
				return null;
			}
		}

		/**
		 * @param wuid 素材的 wuid
		 * @param stream  素材的二进制流
		 * @param callback 成功创建的回调， 回调签名 whenCallback(texture:SAATexture);
		 * @return
		 */
		internal static function depositeTexture(wuid:String , buffer:ByteArray):BaseTexture
		{

			/* found in cache */
			if (WUID_TO_INSTANCE[wuid] != null)
			{
				return WUID_TO_INSTANCE[wuid];
			}

			Environment.log(Environment.$TRACE_MSG_DEPOSITE_TEXTURE + wuid);

			var sig:String = String.fromCharCode(buffer[0], buffer[1], buffer[2]);

			var instance:BaseTexture;

			switch(sig)
			{
				case "ATF":
					instance = ATFTexture.createTexture(wuid, buffer);
					break;
				case "SAA":
					instance = SAATexture.createTexture(wuid, buffer);
					break;
				case "SCA":
					instance = SCATexture.CreateTexture(wuid, buffer);
					break;
				default:
					throw(new Error("invalid binary"));
			}

			WUID_TO_INSTANCE[wuid] = instance;

			return instance;
		}

		/**
		 * 根据 wuid 从远程加载一个贴图素材
		 * @param wuid
		 */
		internal static function loadRemoteTexture(wuid:String):void
		{
			if (WUID_TO_INSTANCE[wuid] != null)
			{
				trace("[TextureManager.loadRemoteTexture] already in memory. wuid:"+wuid);
				return;
			}

			AssetsManager.fetchBinay(wuid, whenRemoteBinaryArrive);
		}

		/**
		 * when asset binary come
		 * @param assetData
		 * @param wuid
		 */
		static private function whenRemoteBinaryArrive(error:ErrorEvent, wuid:String, buffer:ByteArray):void
		{
			if(error == null)
			{
				depositeTexture(wuid, buffer);
			}
			else
			{
				trace("ERROR [TextureManager.whenRemoteBinaryArrive] fail to fetch remote binary:" + error);
			}
		}

		/**
		 * 根据wuid返回对应的 saa 实例
		 * @param wuid
		 * @return
		 */
		internal static  function getInstanceByWuid(wuid:String):BaseTexture
		{
			return WUID_TO_INSTANCE[wuid];
		}

		/**
		 * 返回当前所有持久的 wuid 列表
		 */
		internal static  function getPreseveredWuids():Array
		{
			return DictionaryUtil.getKeys(PRESEVERED_WUIDS);
		}

		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		static internal function initialise(context3D:Context3D):void
		{
			trace("[TextureManager.init] ");
			renderContext = context3D;
		}

		/**
		 * 将一个或者多个可渲染对象从被渲染列表中剔除
		 * @param rest
		 */
		internal static  function removeFromWatch(...rest:Array):void
		{
			var pos:int;

			for each (var rendable:IRenderableRect in rest)
			{
				if(rendable != null)
				{
					while((pos = WATCH_LIST.indexOf(rendable)) >= 0)
					{
						WATCH_LIST.splice(pos, 1);
					}
				}
			}
		}

		/**
		 * 启动渲染
		 */
		internal static  function startRendering():void
		{
			Tick.ticker.addEventListener(Event.ENTER_FRAME, render);
		}

		/**
		 * render a single rect
		 * @param rect
		 */
		private static function renderRect(renderable:IRenderableRect):void
		{
			if(renderable == null) return;

			var texture:BaseTexture;
			texture = WUID_TO_INSTANCE[renderable.assetId];
			if(texture != null)
			{
				// trace("[TextureManager.render] rendable:"+rendable);
				texture.draw(renderable);
			}
			else
			{
				// Environment.log(Environment.$TRACE_MSG_MISSING_ASSET + renderable.assetId);
			}

		}

		/**
		 * 渲染 Stage3D 内容
		 * @param event
		 */
		private static function render(event:Event = null):void
		{
			var el:Object;
			var subEl:Object;
			var renderable:IRenderableRect;

			if (renderContext == null || renderContext.clear == null)
			{
				return;
			}

			/* 进行渲染 */
			try
			{
				renderContext.clear();

				// trace("[TextureManager.render] WATCH_LIST.length:"+WATCH_LIST.length);

				if(WATCH_LIST.length === 0)
				{
					renderContext.present();
					return;
				}

				for each (el in WATCH_LIST)
				{
					if(el is IRenderableRect)
					{
						/* single element */
						renderRect(el as IRenderableRect);
					}
					else if(el is Vector.<IRenderableRect>)
					{
						/* reduce type casting from processing array */
						for each(renderable in el) renderRect(renderable);
					}
					else if(el is Array)
					{
						for each(subEl in el) renderRect(subEl as IRenderableRect);
					}
					else
					{
						Environment.log(Environment.$TRACE_MSG_NON_RENDERABLE_OBJECT + el);
					}
				}

				renderContext.present();
			}
			catch (e:Error)
			{
				trace("ERROR fail to render stage 3D content. error:" + e);
			}
		}
	}
}