/**
 * 渲染引擎的入口类
 */
package gama
{
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Matrix3D;

	public class RectEngine
	{

		static private var isDevMode:Boolean = true;

		/**
		 * 当前设备的 context3d
		 */
		public static var renderContext:Context3D;

		private static var cbInitStage3D:Function;

		/**
		 * stage3D instance from the current runtime stage
		 */
		static private var stage3D:Stage3D ;

		/**
		 * 初始化设备上的 Stage3D
		 * @param stage
		 * @param callback 签名 error:String
		 */
		public static function init(stage:Stage, callback:Function):void
		{
			if(!(stage is Stage)) throw(new ArgumentError("stage is missing"));

			if(!(callback is Function)) throw(new ArgumentError("callback is missing"));

			StageHolder.setStage(stage);

			if (stage.stage3Ds.length > 0)
			{
//				_stage = stage;
				stage3D = stage.stage3Ds[0] as Stage3D;
				if(stage3D == null)
				{
					callback('Stage3D is not avaliable');
					return;
				}

				cbInitStage3D = callback;
				listenToStage3DEvent(true);
				stage3D.requestContext3D(Context3DRenderMode.AUTO);
			}
			else
			{
				callback('Stage3D is not avaliable');
			}
		}

		/**
		 * toggle listener to stage3d
		 * @param value
		 */
		static private function listenToStage3DEvent(value:Boolean):void
		{
			if(value)
			{
				stage3D.addEventListener(Event.CONTEXT3D_CREATE , context3DCreated);
				stage3D.addEventListener(ErrorEvent.ERROR , context3DCreateFailed);
			}
			else
			{
				stage3D.removeEventListener(Event.CONTEXT3D_CREATE , context3DCreated);
				stage3D.removeEventListener(ErrorEvent.ERROR , context3DCreateFailed);
			}
		}

		/**
		 * 当 context3D被成功创建的时候
		 * @param event
		 */
		protected static function context3DCreated(event:Event):void
		{
			// trace("[RectEngine.context3DCreated] event:"+event);

			listenToStage3DEvent(false);

			// if you want the rendered area to be offset from the top-left corner, the position of myStage3D can be changed
			stage3D.x = 0;
			stage3D.y = 0;

			// as the CONTEXT3D_CREATE event has triggered, we know that myStage3D has finished creating its Context3D
			renderContext = stage3D.context3D;

			var _stage:Stage = StageHolder.getStage();

			/* 建立显示缓存 */
			renderContext.configureBackBuffer(StageHolder.stageWidth, StageHolder.stageHeight, 0 , false);

			/* 将整个 stage3D 的渲染区域划定为一个 stage3D vertex 从 (-1,-1) 到 (1,1) 的区域
			这样位图的渲染 vertex 就可以以实际像素位置作为参数传入 */
			var context3DMatrix:Matrix3D = new Matrix3D();
			context3DMatrix.appendTranslation(-_stage.stageWidth / 2 , -_stage.stageHeight / 2 , 0);

			// isDevMode && ( renderContext.enableErrorChecking = true);

			context3DMatrix.appendScale(2.0 / _stage.stageWidth , -2.0 / _stage.stageHeight , 1);
			// trace("[LiteSpriteStage.position] _modelViewMatrix.appendScale("+(2.0/_stage.stageWidth)+", "+(-2.0/_stage.stageHeight)+", 1);");

			renderContext.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX , Shaders.VERTEX_CONSTANT_ORDER_BACK_BUFFER_MATRIX , context3DMatrix , true);

			/* 初始化所有子模块 */
			IndexBuffers.initialise(renderContext);
			ATFHelper.initialise(renderContext);
			Shaders.initialise(renderContext);
			ATFTexture.initialise(renderContext);
			SAATexture.initialise(renderContext);
			SCATexture.initialise(renderContext);
			TextureManager.initialise(renderContext);
			LogoTexture.initialise(renderContext);
			/**
			 * NOTE:
			 *  Q: 为什么初始化不通过 for 循环来做？
			 *  A: 因为 for 循环，将初始化方法放在数组里面, doSWF 会认为这是一个枚举请求，是有风险的，故而不会进行混淆
			 *
			 * ty Dec 17, 2013
			 */

			/* 展示 logo */
			TextureManager.startRendering();
			LogoTexture.showLogo(fireAndRemoveCallback);

			/* 初始化到给外部的钩子 */
			depositeTexture = TextureManager.depositeTexture;
			addToWatch = TextureManager.addToWatch;
			removeFromWatch = TextureManager.removeFromWatch;
			dumpWatchlist = TextureManager.dumpWatchlist;
			loadRemoteTexture = TextureManager.loadRemoteTexture;
			flushTextures = TextureManager.flushTexture;
			flushRenderBatch = TextureManager.flushRenderBatch;

			SetBlendPurpose(Context3DBlendPurpose.ALPHA);
		}

		static private function fireAndRemoveCallback(errorMsg:String = null):void
		{
			var callback:Function = cbInitStage3D;
			cbInitStage3D = null;
			if(callback != null) callback(errorMsg);
		}

		/**
		 * Stage3D初始化失败的时候
		 * @param e
		 */
		private static function context3DCreateFailed(e:ErrorEvent):void
		{
			listenToStage3DEvent(false);
			fireAndRemoveCallback("fail to set up Stage3D: " + e.errorID + " - " + e.text);
		}

		static public function set verbos(value:Boolean):void
		{
			Environment.isVebos = value;
		}


		/**
		 * 设定当前的 context 3d 的渲染混合模式
		 * @param blendPurpose
		 */
		static public function SetBlendPurpose(blendPurpose:String):void
		{
			if (renderContext == null)
			{
				return;
			}

			var sourceBlendFactor:String = Context3DBlendPurpose.BLEND_MODE_FACTORS[blendPurpose + 's'];
			var destBlendFactor:String   = Context3DBlendPurpose.BLEND_MODE_FACTORS[blendPurpose + 'd'];

			if (sourceBlendFactor != null && destBlendFactor != null)
			{
				renderContext.setBlendFactors(sourceBlendFactor , destBlendFactor);
			}
		}


		static public function addLogListener(callback:Function):void
		{
			Environment.logDispatcher.addEventListener("log", callback);
		}

		static public function removeLogListener(callback:Function):void
		{
			Environment.logDispatcher.removeEventListener("log", callback);
		}

		/**
		 * method holder
		 */
		static public var depositeTexture:Function ;
		static public var addToWatch:Function ;
		static public var dumpWatchlist:Function ;
		static public var removeFromWatch:Function ;
		static public var loadRemoteTexture:Function ;
		static public var flushTextures:Function ;
		static public var flushRenderBatch:Function ;

	}
}
