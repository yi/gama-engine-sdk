package sgf.util
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.getTimer;

	/**
	 * General
	 * @author hou
	 */
	public class GA
	{
		/**
		 * ()
		 */
		public static const UPDATE:Callback       = new Callback(0);
		/**
		 * ()
		 */
		public static const UPDATE_ROLE:Callback  = new Callback(0);
		/**
		 * 首次不会 dispatch 需要自己触发
		 * ()
		 */
		public static const STAGE_RESIZE:Callback = new Callback(0);
		/**
		 * ()
		 */
		public static const SECOND:Callback = new Callback(0);

		public static function init(stage:Stage):void
		{
			stage.addEventListener(Event.ENTER_FRAME , enterHandler);
			stage.addEventListener(Event.RESIZE , resizeHandler);
			UPDATE.add(onUpdate);
		}

		private static function onUpdate():void
		{
			updateRole();
			updateSecond();
		}

		private static var updateSecondAt:int;
		private static function updateSecond():void
		{
			if (now < updateSecondAt + 500)
				return;
			updateSecondAt = now;
			SECOND.dispatch();
		}
		private static const FPS:int              = 20;
		private static var updateRoleAt:int;
		private static function updateRole():void
		{
			if (now < updateRoleAt + 1000 / FPS)
				return;
			updateRoleAt = now;
			UPDATE_ROLE.dispatch();
		}

		protected static function resizeHandler(event:Event):void
		{
			STAGE_RESIZE.dispatch();
		}
		private static var now:int;

		private static function enterHandler(event:Event):void
		{
			now = getTimer();
			UPDATE.dispatch();
		}
		public static function getTime():int
		{
			return now;
		}
	}
}
