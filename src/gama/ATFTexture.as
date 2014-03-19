package gama
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	internal final class ATFTexture extends BaseTexture
	{
		/**
		 * 内自建
		 */
		private static  const ENFORCER:Object          = {};

		/**
		 * Cached static lookup of Context3DVertexBufferFormat.FLOAT_2
		 */
		private static const FLOAT2_FORMAT:String = Context3DVertexBufferFormat.FLOAT_2;

		/**
		 * ATF 格式签名
		 */
		private static const HEADER_SIGNATURE:String                = "ATF";

		/**
		 * min length of texture data stream
		 */
		private static  const MIN_DATA_STREAM_LENGTH:uint = 10;

		/**
		 * min length of wuid string
		 */
		private static  const MIN_WUID_LENGTH:uint = 3 ;


		private static  const PROGRAME_TYPE_VERTEX:String = Context3DProgramType.VERTEX;

		/**
		 * 渲染目标
		 */
		private static  var renderContext:Context3D;

		/**
		 *
		 */
		private static  var uvBuffer:VertexBuffer3D;

		/**
		 * 贴图的宽度
		 */
		public var halfTextureWidth:uint ;

		/**
		 * 贴图的高度
		 */
		public var halfTextureHeight:uint ;

		/**
		 * 在每次 draw 的时候，写入 x, y, alpha 通过 programe constant 传给 GPU
		 */
		private static  var vertexProgrameContainer:ByteArray = new ByteArray ;

		/**
		 * @param wuid 素材的 wuid
		 * @param stream  素材的二进制流
		 * @param callback 成功创建的回调， 回调签名 whenCallback(texture:SAATexture);
		 * @return
		 */
		internal static function createTexture(wuid:String , stream:ByteArray):ATFTexture
		{
			if (wuid.length < MIN_WUID_LENGTH)throw(new Error("invalid ATF wuid:" + wuid));

			if (renderContext == null) throw(new Error("stage 3d not ready"));

			if (stream == null || stream.length < MIN_DATA_STREAM_LENGTH)throw(new Error("bad input buffer"));

			stream.position = 0;
			var filesig:String = stream.readUTFBytes(3);
			if (filesig != HEADER_SIGNATURE) throw(new Error("bad signature"));

			var instance:ATFTexture;

			instance = new ATFTexture(ENFORCER , wuid , stream);

			return instance;
		}

		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		static internal function initialise(context3D:Context3D):void
		{
			renderContext = context3D;

			uvBuffer = renderContext.createVertexBuffer(4, 2);
			uvBuffer.uploadFromVector(new <Number>[0,0,0,1,1,1,1,0 ], 0, 4);
		}

		{
			vertexProgrameContainer.endian = Endian.LITTLE_ENDIAN;
			vertexProgrameContainer.length = 4 * 4;
		}

		/**
		 * constructor
		 * @param enforcer
		 * @param wuid
		 * @param stream
		 */
		public function ATFTexture(enforcer:Object , wuid:String , stream:ByteArray)
		{
			if (enforcer !== ENFORCER)throw(new VerifyError);

			texture = ATFHelper.createATFTexture(stream);
			var textureSize:uint = ATFHelper.getATFTextureSize(stream);
			halfTextureWidth = textureSize >>> 16;
			halfTextureHeight = textureSize & 0xffff

			this.wuid = wuid;

			texture.addEventListener(Event.TEXTURE_READY , handleTextureReady);
			try
			{
				texture.uploadCompressedTextureFromByteArray(stream , 0 , true);
				vetexBuffers = renderContext.createVertexBuffer(4,2);

				// indexBufferForRect.uploadFromVector(new <uint>[0 , 1 , 2 , 2 , 3 , 0] , 0 , 6);
				vetexBuffers.uploadFromVector(new <Number>[0,0, 0, halfTextureHeight, halfTextureWidth,halfTextureHeight, halfTextureWidth,0], 0, 4)
			}
			catch (e:Error)
			{
				trace("ERROR [SAATexture.SAATexture] upload texture failed, error:" + e);
				texture.removeEventListener(Event.TEXTURE_READY , handleTextureReady);
				dispose();
				throw(e); /* 将这个错误冒泡给静态创建程序 */
			}

			halfTextureWidth = halfTextureWidth /2 ;
			halfTextureHeight = halfTextureHeight /2;

		}

		/**
		 *
		 */
		private var vetexBuffers:VertexBuffer3D ;

		/**
		 * 进行绘制
		 * @param renderable
		 */
		override internal function draw(renderable:IRenderableRect):void
		{
			/* should be overridden by child class */
			// trace("[ATFTexture.draw] renderable:"+renderable.x+";"+renderable.y);

			renderContext.setProgram(Shaders.shadersForATF);

			renderContext.setVertexBufferAt(0, vetexBuffers , 0, FLOAT2_FORMAT); 	/* 设置顶点 */
			renderContext.setVertexBufferAt(1, uvBuffer, 0, FLOAT2_FORMAT);  		/* 设置UV */
			renderContext.setTextureAt(0, texture);									/* 设置贴图 */

			/* 传入位置的偏移量 */
			vertexProgrameContainer.position = 0;
			vertexProgrameContainer.writeFloat(renderable.x - halfTextureWidth); 							// x offset  /* 请求的偏移是中心点，算出左上点 */
			vertexProgrameContainer.writeFloat(renderable.y - halfTextureHeight); 							// y offset  /* 请求的偏移是中心点，算出左上点 */
			vertexProgrameContainer.writeFloat(renderable.alpha);						/* 传入 alpha 数据 */
			renderContext.setProgramConstantsFromByteArray(PROGRAME_TYPE_VERTEX, Shaders.VERTEX_CONSTANT_ORDER_ATF_TEXTURE_XYA, 1, vertexProgrameContainer, 0);

			/**
			 * NOTE:
			 * ATF 的渲染逻辑设计成：
			 *
			 * ty Dec 6, 2013
			 */

			renderContext.drawTriangles(IndexBuffers.indexBufferForRect);
		}
	}
}