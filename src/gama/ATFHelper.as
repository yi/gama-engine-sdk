package gama
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.utils.ByteArray;

	internal final class ATFHelper
	{

		/**
		 * 渲染目标
		 */
		private static  var renderContext:Context3D;

		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		static internal function initialise(context3D:Context3D):void
		{
			renderContext = context3D;
		}

		/**
		 * Create a new atf texture from the given byte array.
		 * @param data
		 * @param offset
		 * @return
		 */
		internal static function createATFTexture(data:ByteArray, offset:uint=0):Texture
		{
			if (!isAtfData(data, offset)) throw new ArgumentError("Invalid ATF data");

			if (data[offset + 6] === 255)
			{
				data.position = 12 + offset; // new file version
			}
			else
			{
				data.position =  6 + offset; // old file version
			}

			var mFormat:String;

			var textureFormat:uint = data.readUnsignedByte();

			switch (textureFormat)
			{
				case 0:
				case 1: mFormat = Context3DTextureFormat.BGRA; break;
				case 2:
				case 3: mFormat = Context3DTextureFormat.COMPRESSED; break;
				case 4:
				case 5: mFormat = "compressedAlpha"; break; // explicit string to stay compatible with older versions
				default: throw new Error("Invalid ATF format");
			}

			var mWidth:uint = Math.pow(2, data.readUnsignedByte());
			var mHeight:uint = Math.pow(2, data.readUnsignedByte());

			var texture:Texture = renderContext.createTexture(mWidth , mHeight , mFormat , false);

			return texture;
		}

		/**
		 * 获得 atf 文件的尺寸
		 * @param data
		 * @param offset
		 * @return width << 16 | height
		 */
		internal static function getATFTextureSize(data:ByteArray, offset:uint=0):uint
		{
			if (!isAtfData(data, offset)) throw new ArgumentError("Invalid ATF data");

			if (data[6] == 255) data.position = 13 + offset; // new file version
			else                data.position =  7 + offset; // old file version

			return (Math.pow(2, data.readUnsignedByte()) << 16) | Math.pow(2, data.readUnsignedByte());
		}

		/**
		 * detect if a given buffer is an atf
		 * @param data
		 * @param offset
		 * @return
		 */
		internal static function isAtfData(data:ByteArray, offset:uint=0):Boolean
		{
			if (data.length - offset < 3) return false;
			else
			{
				var signature:String = String.fromCharCode(data[offset], data[offset + 1], data[offset + 2]);
				return signature == "ATF";
			}
		}

	}
}