package gama
{
	import flash.display.Stage;

	/**
	 * 在内存里面的随时获得 stage 实例而不需要依赖其他类
	 * @author Administrator
	 */

	internal final class StageHolder
	{
		static private var _stage:Stage ;


		static internal var stageHeight:Number ;

		static internal var stageWidth:Number ;

		static internal var halfStageHeight:Number ;

		static internal var halfStageWidth:Number ;

		static internal function setStage(value:Stage):void
		{
			if(value == null) throw(new ArgumentError);
			_stage = value;
			stageHeight = _stage.stageHeight;
			stageWidth = _stage.stageWidth;
			halfStageHeight = stageHeight / 2;
			halfStageWidth = stageWidth /2;
		}

		static internal function getStage():Stage
		{
			return _stage;
		}
	}
}