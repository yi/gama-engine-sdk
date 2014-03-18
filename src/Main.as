package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.bit101.components.PushButton;
	import com.bit101.components.Style;
	import com.bit101.components.TextArea;

	import flash.display.Sprite;
	import flash.display3D.Context3DProgramType;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;

	import sgf.util.Base64;

	[SWF(width = "960" , height = "640")]
	public class Main extends Sprite
	{
		public function Main()
		{
			Style.LABEL_TEXT = 0;
			addChildren();
		}
		private static const INPUT_SRC:String  = '请输入agal';
		private static const OUTPUT_OUT:String = '等待编译结果';
		private var srcTA:TextArea;
		private var outTA:TextArea;

		private function addChildren():void
		{
			srcTA = new TextArea(this , 10 , 10 , INPUT_SRC);
			srcTA.setSize(500 , 140);
			var b:PushButton = new PushButton(this , 290 , 160 , '清空' , clearHandler);
			b = new PushButton(this , b.x + 120 , b.y , '生成' , genHandler);
			outTA = new TextArea(this , 10 , 200 , OUTPUT_OUT);
			outTA.setSize(500 , 140);
		}

		private function genHandler(e:MouseEvent):void
		{
			var asm:AGALMiniAssembler = new AGALMiniAssembler();
			var agal:String           = srcTA.text;
			var bin:ByteArray;
			if (agal.indexOf('op') != -1)
			{
				bin = asm.assemble(Context3DProgramType.VERTEX , agal);
				agal = Base64.encode(bin);
			}
			else if (agal.indexOf('oc') != -1)
			{
				bin = asm.assemble(Context3DProgramType.FRAGMENT , agal);
				agal = Base64.encode(bin);
			}
			else
				agal = '无法解析agal! 需要包含输出agal code';
			outTA.text = agal;
		}

		private function clearHandler(e:MouseEvent):void
		{
			outTA.text = srcTA.text = '';
		}
	}
}
