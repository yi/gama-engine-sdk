

package gama
{
	import flash.utils.Dictionary;

	public class DictionaryUtil
	{

		/**
		 * clear all keys in the given dict
		 * @param d
		 * @return
		 *
		 */
		internal static function setEmpty(d:Dictionary):void
		{
			var reusableArray:Array = Environment.REUSABLE_ARRAY;
			if(d == null) return;
			reusableArray.length = 0;
			for (var key:Object in d)
			{
				reusableArray.push(key);
			}

			for each (key in reusableArray)
			{
				delete d[key];
			}
			reusableArray.length = 0;
		}

		/**
		 * count key length of a dictionary
		 * @param d
		 * @return
		 */
		static internal function count(d:Dictionary):uint
		{
			var count:uint = 0;
			if(d == null) return 0;
			for (var key:Object in d)
			{
				count++;
			}
			return count;
		}

		static internal function clone(src:Dictionary):Dictionary
		{
			if(src == null) return null;
			var result:Dictionary = new Dictionary;
			for (var key:Object in src)
			{
				result[key] = src[key];
			}
			return result;
		}

		/**
		 * remove a bunch of keys from the give dict
		 * @param d
		 * @param keys
		 */
		internal static function removeKeys(d:Dictionary, keys:Array):void
		{
			if(d == null || keys == null || keys.length === 0) return;
			for each (var key:Object in keys)
			{
				delete d[key];
			}
		}

		/**
		*	Returns an Array of all keys within the specified dictionary.
		*
		* 	@param d The Dictionary instance whose keys will be returned.
		*
		* 	@return Array of keys contained within the Dictionary
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 9.0
		*	@tiptext
		*/
		internal static function getKeys(d:Dictionary):Array
		{
			var a:Array = new Array();

			for (var key:Object in d)
			{
				a.push(key);
			}

			return a;
		}

		/**
		*	Returns an Array of all values within the specified dictionary.
		*
		* 	@param d The Dictionary instance whose values will be returned.
		*
		* 	@return Array of values contained within the Dictionary
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 9.0
		*	@tiptext
		*/
		internal static function getValues(d:Dictionary):Array
		{
			var a:Array = new Array();

			for each (var value:Object in d)
			{
				a.push(value);
			}

			return a;
		}

		/**
		 * 返回一个Dictionary中 key/value 的对数
		 * @param d
		 * @return
		 *
		 */
		internal static function getLength(d:Dictionary):int
		{
			var n:int = 0;
			for (var key:Object in d)
			{
				n++;
			}
			return n;
		}

		/**
		 * 返回两个 Dictionary 实例中的交集（由a[key]来决定，返回的dict的value是 a 的value）
		 * @param a
		 * @param b
		 * @return 一个新的dict结果对象
		 */
		internal static function intersect(a:Dictionary, b:Dictionary):Dictionary
		{
			var result:Dictionary = new Dictionary;
			for (var key:Object in a)
			{
				if(b[key] != null) result[key] = a[key];
			}
			return result;
		}

		/**
		 * 拿 dict a 的 keys 对 dict b 打洞，把 dict b 中和 a 共有的 keys 都移除
		 * @param a
		 * @param b
		 * @return 一个新的dict结果对象, 其values是 b 的values的子集
		 *
		 */
		internal static function punch(a:Dictionary, b:Dictionary):Dictionary
		{
			var result:Dictionary = new Dictionary;
			for (var key:Object in b)
			{
				if(a[key] == null) result[key] = b[key];
			}
			return result;
		}
	}
}