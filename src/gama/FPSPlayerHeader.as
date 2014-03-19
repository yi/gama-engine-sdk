package gama
{
	import flash.events.Event;
	import flash.utils.getTimer;

	/**
	 * 这是一个静态的 enter_frame 计时器，这个ticker和 和 static.PlayerHeader 不同之处在于：
	 * 这个ticker 内建了 fps 的判断，专供动画渲染所使用，避免每个script runner 都去独立计算一遍
	 * fps 的有效性
	 *
	 * @author yi
	 */
	final public class FPSPlayerHeader
	{
		/**
		 * 渲染层最大的 fps
		 */
		private static  const MAX_FPS:uint = 60 ;

		/**
		 * 渲染出所允许的最小的 fps
		 */
		private static  const MIN_FPS:uint = 2 ;

		/**
		 * 信号回调：播放了多少帧
		 * 回调方法： whenFramePast(numOfFramePast:uint);
		 */
		public static  const onFramePast:Callbacks = new Callbacks ;

		private static  var _fps:uint ;
		private static  var _spf:uint ;

		/**
		 * 上一次渲染的事件
		 */
		private static  var lastFrameAt:uint = 0;

		/**
		 * 启动渲染
		 */
		internal static function start(...rest):void
		{
			// trace("[FPSPlayerHeader.Start] ");
			lastFrameAt = getTimer();
			Tick.ticker.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			onFramePast.dispatch(0);
		}

		/**
		 * 暂停渲染
		 */
		internal static function stop(...rest):void
		{
			// trace("[FPSPlayerHeader.Stop] ");
			Tick.ticker.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}

		/**
		 * 让外部代码可以调整整个程序的渲染层的 fps
		 * @param value
		 */
		public static  function setFps(value:uint):void
		{
			value = uint(value);
			if(value == _fps) return;
			if(value < MIN_FPS) value = MIN_FPS;
			if(value > MAX_FPS) value = MAX_FPS;
			_fps = value;
			_spf = (1000 / value) >> 0;
		}

		/**
		 * 每次flash player 的 enter frame 播放头触发
		 */
		private static  function handleEnterFrame(event:Event):void
		{
			// trace("[FPSPlayerHeader.handleEnterFrame] fps:"+_fps+"; _spf"+_spf);
			var now:int = getTimer();
			if(now < lastFrameAt + _spf) return;

			var numOfFrame:uint = ((now - lastFrameAt)/_spf + .5) >> 0;
			lastFrameAt = now;

			onFramePast.dispatch(numOfFrame);
		}

		/* static init */
		{
			setFps(15);
			start();
		}
	}
}