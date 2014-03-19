package gama
{
	/**
	 * 资源类型的枚举
	 *
	 * 采用 32bit 来表达类型， 最低位为1位， 低8bit用来表达类型
	 *
	 * - 第1位， true 表达直接返回 bytearray, false 表达要进行解析
	 * - 第2位， true 表达 bytearray.readObject(), false 表达不进行object读取
	 * - 第3位， true 表达 loader.loadBytes(), false 表达不进行loadBytes
	 * - 第4位， true 表达直接返回 loader.content, false 表达不返回
	 * - 第5位， true 表达直接返回 loader.content.bitmapData, false 表达不返回
	 * - 第6位， true 表达直接返回 animation, false 表达不返回
	 *
	 *
	 * @author ty
	 */
	internal class AssetType
	{

		static internal const BINARY:uint = 0 ;

		static internal const GPU_TEXTURE:uint = 10 ;

		static internal const SOUND:uint = 20 ;

		static internal const DATA_OBJECT:uint = 30 ;

		static internal function isTimeSensitive(value:uint):Boolean
		{
			return value === DATA_OBJECT || value === BINARY;
		}

	}
}
