package gama
{
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	/**
	 * 展示图标的 atf
	 * @author Administrator
	 */
	internal class LogoTexture {

		[Embed( source = "../assets/logo_powered_by.atf", mimeType="application/octet-stream")]
		private static var TextureAsset:Class;

		/**
		 * a callback to be fired when logo show goes off
		 */
		private static  var callbackWhenGoesOff:Function ;

		private static  var logoRect:LogoRect ;

		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		internal static  function initialise(context3D:Context3D):void
		{
			logoRect = new LogoRect(StageHolder.halfStageWidth, StageHolder.halfStageHeight);
			TextureManager.depositeTexture(logoRect.assetId, new TextureAsset as ByteArray);
		}

		internal static  function removeLogo():void
		{
			Tick.ticker.removeEventListener(Event.ENTER_FRAME, logoRect.fadeOut);
			TextureManager.removeFromWatch(logoRect);
			TextureManager.flushTexture();
			logoRect = null;
			TextureAsset = null;

			var callback:Function = callbackWhenGoesOff;
			callbackWhenGoesOff = null;
			if(callback != null) callback();
		}

		internal static  function showLogo(callback:Function = null):void
		{
			callbackWhenGoesOff = callback;
			TextureManager.addToWatch(logoRect);
			Tick.ticker.addEventListener(Event.ENTER_FRAME, logoRect.fadeIn);
			setTimeout(fadeoutLogo, 1500);
		}

		private static  function fadeoutLogo():void
		{
			Tick.ticker.removeEventListener(Event.ENTER_FRAME, logoRect.fadeIn);
			Tick.ticker.addEventListener(Event.ENTER_FRAME, logoRect.fadeOut);
			setTimeout(removeLogo, 1000 / (logoRect.fadeAmount * 3) / StageHolder.getStage().frameRate);
		}
	}
}

