package gama
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	/**
	 * 顶点的 buffer 集合
	 * @author Administrator
	 *
	 */
	internal final class IndexBuffers
	{

		/**
		 *  3行的 人物名字贴图的渲染方式
		 *
		 *  0  +---------+ 7
		 *     |         |
		 *  1  +---------+ 6
		 *     |         |
		 *  2  +---------+ 5
		 *     |         |
		 *  3  +---------+ 4
		 *
		 */
		internal static var indexBufferFor3LineTag:IndexBuffer3D;

		/**
		 * 绘制矩形的 index buffer
		 */
		internal static var indexBufferForRect:IndexBuffer3D;

		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		internal static  function initialise(renderContext:Context3D):void
		{
			/* 初始化 index buffers */
			if(indexBufferForRect == null)
			{
				indexBufferForRect = renderContext.createIndexBuffer(6);
				indexBufferForRect.uploadFromVector(new <uint>[0 , 1 , 2 , 2 , 3 , 0] , 0 , 6);
			}

			if(indexBufferFor3LineTag == null)
			{
				indexBufferFor3LineTag = renderContext.createIndexBuffer(18);
				indexBufferFor3LineTag.uploadFromVector(new <uint>[0 , 1 , 2 , 2 , 3 , 0 ,
					4 , 5 , 6 , 6 , 7 , 4 ,
					8 , 9 , 10 , 10 , 11 , 8] , 0 , 18);
			}
		}
	}
}