package gama
{
	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;
	/**
	 * Agal 工具类
	 * @author Administrator
	 */
	internal final class Shaders
	{

		/**
		 * vertex 常量的位置： back buffer 的缩放比，长度 4个寄存器
		 */
		static internal const VERTEX_CONSTANT_ORDER_BACK_BUFFER_MATRIX:uint  = 124;

		/**
		 * atf 素材的
		 */
		static internal const VERTEX_CONSTANT_ORDER_ATF_TEXTURE_XYA:uint  = 123;

		/**
		 * SAA 的 shader
		 */
		public static var shadersForSAA:Program3D;

		/**
		 *
		 */
		public static var shadersForATF:Program3D;

		/**
		 *
		 */
		public static var shadersForATFWithCompressedAlpha:Program3D;

		/**
		 * SCA 的 shader
		 */
		public static var shadersForSCA:Program3D;

		/**
		 * 可以复用的 agal 编译器
		 */
		private static var agalAssembler:AGALMiniAssembler;

		/**
		 * dxt5 的 fragment agal
		 */
		private static  var fragmentAgalDXT5WithAlpha:ByteArray ;

		/**
		 * dxt5 的 fragment agal
		 */
		private static  var fragmentAgalWithAlpha:ByteArray ;

		/**
		 * 带透明，不带旋转的 vetex agal
		 */
		private static  var vetexAgalWithAlphaNoRotaion:ByteArray ;

		/**
		 * 将 fragment shader 的字符串内容编译成 agal 二进制
		 * @param agal fragment shader 的字符串内容
		 * @return
		 */
		private static function compileFragmentAgal(agal:String):ByteArray
		{
			if (agal == null || agal.length === 0)
			{
				throw(new ArgumentError);
			}

			// var agalAssembler:AGALMiniAssembler = new AGALMiniAssembler;
			agalAssembler = agalAssembler || new AGALMiniAssembler;

			agalAssembler.assemble(Context3DProgramType.FRAGMENT , agal);
			// trace("[Helpers.CompileFragmentAgal] agalAssembler.agalcode.l:"+agalAssembler.agalcode.length);

			return agalAssembler.agalcode;
		}

		/**
		 * 将 vertex shader 的字符串内容编译成 agal 二进制
		 * @param vertex fragment shader 的字符串内容
		 * @return
		 */
		private static function compileVetexAgal(agal:String):ByteArray
		{
			if (agal == null || agal.length === 0)
			{
				throw(new ArgumentError);
			}

			agalAssembler = agalAssembler || new AGALMiniAssembler;
			agalAssembler.assemble(Context3DProgramType.VERTEX , agal);
			return agalAssembler.agalcode;
		}

		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		static internal function initialise(renderContext:Context3D):void
		{
			var vetexAgal:ByteArray;
			var fragmentAgal:ByteArray;

			/* 单张图片的 shader ========= 开始 ============= */
			/* 单张图片的 shader :: vertex */
			vetexAgal = compileVetexAgal( // vetex shader
				"add vt0, vc"+VERTEX_CONSTANT_ORDER_ATF_TEXTURE_XYA+" , va0 \n " + 			// 对顶点数据进行位移计算，并且赋值到临时寄存器vt0。其中va0 是 vertex 数据, vc123 是附带 x,y 位移的 constants fragment 将外部传入变量0 和 常量4 进行合并
				"mov op, vt0    \n" +      													// 将临时寄存器 vt0 进行输出
				"dp4 op.x, vt0, vc"+ VERTEX_CONSTANT_ORDER_BACK_BUFFER_MATRIX +" \n" + 		// 将输出结果中的 x 根据 stage 3D 像素面积 到 矢量面积的计算进行处理
				"dp4 op.y, vt0, vc"+ (VERTEX_CONSTANT_ORDER_BACK_BUFFER_MATRIX + 1 )+" \n" + // 将输出结果中的 y 根据 stage 3D 像素面积 到 矢量面积的计算进行处理
				"mov v0, va1.xy     \n" +  													// 将 UV 顶点数据 传递给 pixel shader
				"mov v1, vc"+VERTEX_CONSTANT_ORDER_ATF_TEXTURE_XYA+".z   "   					// 将 alpha 数据传递给 fragment program
			);

			/* 单张图片的 shader :: fragment */
			fragmentAgal = compileFragmentAgal(
				"tex ft0, v0, fs0 <2d,clamp,linear,mipnone> \n"+ 		// 对贴图取样
				"mul ft0, ft0, v1.zzzz\n" + 								// 加入 alpha 处理
				"mov oc, ft0 \n" 											//output the final pixel color
			);

			shadersForATF = renderContext.createProgram();
			shadersForATF.upload(vetexAgal, fragmentAgal);

			/* 单张图片的 shader :: fragment */
			fragmentAgal = compileFragmentAgal(
				"tex ft0, v0, fs0 <2d,clamp,linear,mipnone> dxt5 \n"+ 		// 对贴图取样
				"mul ft0, ft0, v1.zzzz\n" + 										// 加入 alpha 处理
				"mov oc, ft0 \n" 													//output the final pixel color
			);

			shadersForATFWithCompressedAlpha = renderContext.createProgram();
			shadersForATFWithCompressedAlpha.upload(vetexAgal, fragmentAgal);
			/* 单张图片的 shader ========= 结束 ============= */

			/* SAA的 shader ========= 开始 ============= */
			/* SAA 的 shader :: vertex */
			vetexAgal = compileVetexAgal( // vetex shader
				"mov op, va0    \n" +    // 将AS所传入的 vertex 值赋值到输出，其中包括用到的 x,y 和不用的 z,w ， z,w 作为占位
				"dp4 op.x, va0, vc"+ VERTEX_CONSTANT_ORDER_BACK_BUFFER_MATRIX +" \n" + 		// 将输出结果中的 x 根据 stage 3D 像素面积 到 矢量面积的计算进行处理
				"dp4 op.y, va0, vc"+ (VERTEX_CONSTANT_ORDER_BACK_BUFFER_MATRIX + 1 )+" \n" + // 将输出结果中的 y 根据 stage 3D 像素面积 到 矢量面积的计算进行处理
				"mov v0, va1.xy     \n" // 将AS 所传入的 UV （va1） 传递给 pixel sheder
			);

			/* SAA的 shader :: fragment */
			fragmentAgal = compileFragmentAgal(
				"tex oc, v0, fs0 <2d,linear,mipnone,clamp> dxt5 \n" 				// 对贴图取样
				// "mul ft0, ft0, v1.zzzz\n" + 											// 加入 alpha 处理
				// "mov oc, ft0 \n" 													//output the final pixel color
			);
			shadersForSAA = renderContext.createProgram();
			shadersForSAA.upload(vetexAgal, fragmentAgal);

			/* SAA的 shader ========= 结束 ============= */

		}
	}
}