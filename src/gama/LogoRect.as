package gama
{
	internal final class LogoRect implements IRenderableRect
	{

		public var fadeAmount:Number = 0.05;
		private var _alpha:Number = .01;

		private var _x:Number = 0;
		private var _y:Number = 0;

		public function LogoRect(x:Number, y:Number)
		{
			_x = x;
			_y = y;
		}

		/**
		 * Indicates the alpha transparency value of the object specified. Valid values are 0 (fully transparent) to 1 (fully opaque). The default value is 1. Display objects with alpha set to 0 are active, even though they are invisible.
		 * @return
		 */
		public function get alpha():Number{
			return _alpha;
		}

		/**
		 * asset id generated on www.getrects.com
		 * @return
		 */
		public function get assetId():String{
			return "$$logo";
		}

		public function fadeIn(...rest):void
		{
			_alpha += fadeAmount;
			if(_alpha > 1) _alpha = 1;
		}

		public function fadeOut(...rest):void
		{
			_alpha -= fadeAmount * 3;
			if(_alpha < 0) _alpha = 0;
		}

		public function get frameId():uint{
			return 0;
		}

		public function set frameId(val:uint):void{
			// do nothing
		}

		public function get isXMirrored():Boolean
		{
			return false;
		}

		/**
		 * Indicates the x coordinate of the RenderableRect instance relative to back buffer canvase
		 * @return
		 */
		public function get x():Number{
			return _x;
		}

		/**
		 * Indicates the y coordinate of the RenderableRect instance relative to back buffer canvase
		 * @return
		 */
		public function get y():Number{
			return _y;
		}
	}
}