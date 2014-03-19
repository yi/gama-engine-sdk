package gama
{
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.utils.Dictionary;
	/**
	 * texture 的基类
	 * @author Administrator
	 *
	 */
	internal class BaseTexture
	{

		/**
		 * key: wuid, value: ATFTexture instance
		 */
		private static const WUID_TO_INSTANCE:Dictionary            = new Dictionary;

		/**
		 * 贴图对象
		 */
		protected var texture:Texture;

		/**
		 * 素材是否就绪
		 */
		internal var isReady:Boolean = false;

		/**
		 * 素材的wuid
		 */
		internal var wuid:String;

		/**
		 * 素材准备就绪
		 * @param event
		 */
		protected function handleTextureReady(event:Event):void
		{
			texture.removeEventListener(Event.TEXTURE_READY , handleTextureReady);
			isReady = true;
		}

		/**
		 * 自我析构
		 */
		internal function dispose():void
		{
			if (isReady)
			{
				texture.dispose();
				isReady = false;
			}
			texture.removeEventListener(Event.TEXTURE_READY , handleTextureReady);
			texture = null;

			delete TextureManager.WUID_TO_INSTANCE[wuid];
		}

		/**
		 * 进行绘制
		 * @param renderable
		 */
		internal function draw(renderable:IRenderableRect):void
		{
			/* should be overridden by child class */
		}

		/**
		 * 返回素材帧的数量
		 * @return
		 */
		public function get assetFrameNum():uint
		{
			return 1;
		}

		/**
		 * 返回逻辑帧的数量
		 * @return
		 */
		public function get logicalFrameNum():uint
		{
			return 1;
		}

	}
}