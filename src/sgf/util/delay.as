package sgf.util
{
	public function delay(func:Function , clear:Boolean = false):void
	{
		clear ? ForDelay.remove(func) : ForDelay.add(func);
	}
}
import sgf.util.GA;

class ForDelay
{
	private static const handlers:Array = [];

	public static function add(func:Function):void
	{
		if (handlers.indexOf(func) == -1)
			handlers.push(func);
	}

	public static function remove(func:Function):void
	{
		var index:int = handlers.indexOf(func);
		if (index != -1)
			handlers.splice(index , 1);
	}

	private static function onUpdate():void
	{
		while (handlers.length)
			handlers.pop()();
	}
	GA.UPDATE.add(onUpdate);
}
