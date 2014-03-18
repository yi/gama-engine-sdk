package sgf.util
{

	public class Callback
	{
		private var callbacks:Array;
		private var adds:Array;
		private var removes:Array;

		private var _numAgrs:int;

		public function Callback(numArgs:int)
		{
			_numAgrs = numArgs;
			callbacks = [];
			adds = [];
			removes = [];
		}

		public function add(func:Function):void
		{
			if (func.length != _numAgrs)
				throw('[Callback::add] function param num incorrect' + this , func.length , _numAgrs);
			if (dispatching)
				addSelf(adds , func);
			else
				addSelf(callbacks , func);
		}

		private function addSelf(arr:Array , func:Function):void
		{
			if (arr.indexOf(func) == -1)
				arr.push(func);
		}

		private function removeSelf(arr:Array , func:Function):void
		{
			var index:int = arr.indexOf(func);
			if (index != -1)
				arr.splice(index , 1);
		}

		public function remove(func:Function):void
		{
			if (dispatching)
				addSelf(removes , func);
			else
				removeSelf(callbacks , func);
		}

		private var dispatching:Boolean;

		/**
		 * dispatch a call to all listensers
		 * @param rest
		 */
		public function dispatch(... rest):void
		{
			if (rest.length != _numAgrs)
				throw('[Callback::dispatch] dispath param num incorrect' + this , rest.length , _numAgrs);
			while (removes.length)
				removeSelf(callbacks , removes.pop());

			var i:int , len:int;
			len = callbacks.length;
			dispatching = true;
			for (i = 0 ; i < len ; i++)
				(callbacks[i] as Function).apply(null , rest);
			dispatching = false;

			while (adds.length)
				addSelf(callbacks , adds.pop());
		}
	}
}
