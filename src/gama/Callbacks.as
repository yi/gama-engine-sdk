package gama
{
	/**
	 * 提供一个最简单的回调方法队列的实现
	 * @author ty
	 *
	 */
	public class Callbacks
	{

		private var _callbacks:Vector.<Function>;
		private var _callOncebacks:Vector.<Function>;

		public function Callbacks()
		{
			_callbacks = new Vector.<Function>;
			_callOncebacks = new Vector.<Function>;
		}

		public function add(func:Function):void
		{
			if (func != null && _callbacks.indexOf(func) < 0)	_callbacks.push(func);
		}

		public function addOnce(func:Function):void
		{
			if (_callOncebacks.indexOf(func) < 0) _callOncebacks.push(func);
		}

		/**
		 * remove all
		 */
		public function clear():void
		{
			if (_callbacks)
				_callbacks.length = 0;

			if (_callOncebacks)
				_callOncebacks.length = 0;
		}

		private var index:int;

		/**
		 * dispatch a call to all listensers
		 * @param rest
		 */
		public function dispatch(...rest):void
		{
			for (index = 0 ; index < _callbacks.length ; index++)
			{
				_callbacks[index].apply(null , rest);
			}
			while (_callOncebacks.length)
			{
				_callOncebacks.shift().apply(null , rest);
			}
		}

		public function remove(func:Function):void
		{
			//			if(_callbacks == null || _callbacks.length == 0) return;
			var i:int = _callbacks.indexOf(func);
			if (i > 0)
			{
				if (index >= i)
					index--;
				if(index < -1)
					index = -1;
				_callbacks.splice(i , 1);
			}
			if (_callOncebacks.indexOf(func) != -1)
				_callOncebacks.splice(_callOncebacks.indexOf(func) , 1);
		}
	}
}
