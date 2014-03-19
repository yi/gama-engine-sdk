package
{
	public interface IRenderableRect
	{
		/**
		 * Indicates the x coordinate of the RenderableRect instance relative to back buffer canvase
		 * @return
		 */
		function get x():Number;

		/**
		 * Indicates the y coordinate of the RenderableRect instance relative to back buffer canvase
		 * @return
		 */
		function get y():Number;

		/**
		 * Indicates the alpha transparency value of the object specified. Valid values are 0 (fully transparent) to 1 (fully opaque). The default value is 1. Display objects with alpha set to 0 are active, even though they are invisible.
		 * @return
		 */
		function get alpha():Number

		/**
		 * asset id generated on www.getrects.com
		 * @return
		 */
		function get assetId():String

		function get isXMirrored():Boolean

		function get frameId():uint;

		function set frameId(val:uint):void;

	}
}



