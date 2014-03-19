package gama
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	/**
	 * 对 SAA 文件格式的抽象和封装
	 *
	 * 这个实现有以下几点特性：
	 *  1. 实例的自我管理
	 *  2. 通过 AddDrawRequest 和 RenderDrawRequests 来实现批量渲染
	 *
	 * @author ty
	 */
	public class SAATexture extends BaseTexture
	{

		/**
		 * SAA 格式签名
		 */
		private static const HEADER_SIGNATURE:String                = "SAA";

		/**
		 * 这里开放一个钩子方法，用于播放音效，以在不大改动目前的代码结构的前提下，快速播放音效
		 */
		static public var onSoundPlay:Function ;

		/**
		 * 用于 上传 vertex buffer 数据的容器
		 */
		static private var vetexDataContainer:ByteArray             = new ByteArray;
		vetexDataContainer.endian = Endian.LITTLE_ENDIAN;

		/**
		 * 一个可以复用的 vertex buffer 容器
		 */
		static private var vertexBuffer:VertexBuffer3D;

		/** Cached static lookup of Context3DVertexBufferFormat.FLOAT_2 */
		private static const FLOAT2_FORMAT:String     = Context3DVertexBufferFormat.FLOAT_2;

		/**
		 * 进行绘制
		 * @param renderable
		 */
		override internal function draw(renderable:IRenderableRect):void
		{
			/* should be overridden by child class */

			renderContext.setProgram(Shaders.shadersForSAA);

			var frameId:uint = getAssetFrameIdFromFrameId(renderable.frameId);
			xywhBa.position = frameId << 3;
			var offsetX:Number = xywhBa.readShort();
			var y:Number = renderable.y + xywhBa.readShort(); /* y += offsetY */
			var w:Number = xywhBa.readShort();
			var h:Number = xywhBa.readShort();
			var x:Number;

			// trace("[SAATexture.draw] frameId:"+frameId);

			/* 建立当前绘制请求的 vertex */
			vetexDataContainer.position = 0;

			if(renderable.isXMirrored)
			{  /* 在 x 方向上镜像 */
				x = renderable.x - w - offsetX;
				vetexDataContainer.writeFloat(x + w); vetexDataContainer.writeFloat(y);
				vetexDataContainer.writeFloat(x + w); vetexDataContainer.writeFloat(y + h);
				vetexDataContainer.writeFloat(x);	  vetexDataContainer.writeFloat(y + h);
				vetexDataContainer.writeFloat(x);     vetexDataContainer.writeFloat(y);
			}
			else
			{
				x = renderable.x + offsetX;
				vetexDataContainer.writeFloat(x);    	vetexDataContainer.writeFloat(y);
				vetexDataContainer.writeFloat(x);    	vetexDataContainer.writeFloat(y + h);
				vetexDataContainer.writeFloat(x + w);	vetexDataContainer.writeFloat(y + h);
				vetexDataContainer.writeFloat(x + w);	vetexDataContainer.writeFloat(y);
			}

			// trace("[SAATexture.draw] x:"+x+", y:"+y+"; w:"+w+"; h:"+h+", texture:"+texture);

			/**
			 * TODO:
			 *  是否有必要将 mirrored vertex 预先编译好，用内存来换计算性能？
			 *
			 * ty Dec 9, 2013
			 */

			vertexBuffer.uploadFromByteArray(vetexDataContainer , 0 , 0 , 4);
			renderContext.setVertexBufferAt(0 , vertexBuffer , 0 , FLOAT2_FORMAT); 				/* 设置顶点 */
			renderContext.setVertexBufferAt(1 , uvBuffer , frameId << 1 , FLOAT2_FORMAT);  		/* 设置UV */
			renderContext.setTextureAt(0, texture);			  									/* 设置贴图 */

			renderContext.drawTriangles(IndexBuffers.indexBufferForRect);
		}


		/**
		 * 静态初始化
		 * NOTE: 为什么不叫 init? 因为 init 是 doSWF 的保留字段，在严格模式下不会被混淆
		 * @param renderContext
		 */
		static internal function initialise(context3D:Context3D):void
		{
			renderContext = context3D;
		}

		/**
		 * min length of wuid string
		 */
		static private const MIN_WUID_LENGTH:uint = 3 ;

		/**
		 * @param wuid 素材的 wuid
		 * @param stream  素材的二进制流
		 * @param callback 成功创建的回调， 回调签名 whenCallback(texture:SAATexture);
		 * @return
		 */
		internal static function createTexture(wuid:String , stream:ByteArray):SAATexture
		{
			if (wuid.length < MIN_WUID_LENGTH)
			{
				trace("ERROR [SAATexture.createTexture] bad wuid:" + wuid);
				return null;
			}

			if (renderContext == null)
			{
				trace("ERROR [SAATexture.createTexture] stage 3d not ready");
				return null;
			}

			if (stream == null || stream.length < 10)
			{
				trace("ERROR [SAATexture.createTexture] bad input stream:" + wuid);
				return null;
			}

			stream.position = 0;
			var filesig:String = stream.readUTFBytes(3);
			if (filesig != HEADER_SIGNATURE)
			{
				trace("ERROR [SAATexture.createTexture] bad sig:" + filesig + "; wuid:" + wuid);
				return null;
			}

			var instance:SAATexture;

			try
			{
				instance = new SAATexture(ENFORCER , wuid , stream);
			}
			catch (e:Error)
			{
				trace("[SAATexture.CreateTexture] fail to create instance from stream. wuid:" + wuid + ", error:" + e);
				return null;
			}

			return instance;
		}

		/**
		 * 内自建
		 */
		static private const ENFORCER:Object          = {};

		/**
		 * 渲染目标
		 */
		static private var renderContext:Context3D;

		/**
		 * 返回素材帧的数量
		 * @return
		 */
		override public function get assetFrameNum():uint
		{
			return _numOfAssetFrame;
		}

		/**
		 * 返回逻辑帧的数量
		 * @return
		 */
		override public function get logicalFrameNum():uint
		{
			return playscriptDict ? (playscriptDict[$NUM_OF_LOGICAL_FRAME] || _numOfAssetFrame) : _numOfAssetFrame;
		}

		/**
		 * 总素材帧数
		 */
		private var _numOfAssetFrame:uint;

		/**
		 * 表达 每帧的 xOffset, yOffset, width, height 的 byte array
		 */
		private var xywhBa:ByteArray;

		/**
		 * UV
		 */
		private var uvBuffer:VertexBuffer3D;

		/**
		 * 播放脚本和播放音效的 dictionary
		 * 可能存在的key:
		 *  1. frame number
		 *  2. frame number & BIT_MARK_SOUND_FRAME_ID
		 */
		private var playscriptDict:Dictionary ;

		static private const $NUM_OF_LOGICAL_FRAME:String = "nof" ;

		/**
		 * 播放脚本中的音效的数据位mask
		 */
		static private var BIT_MARK_SOUND_FRAME_ID:uint =  0x01000000 ;

		/**
		 * 根据播放脚本的逻辑帧号计算出所对应的素材帧号
		 * 如果该逻辑帧号上有音效的话，则播放音箱
		 */
		private function getAssetFrameIdFromFrameId(frameId:uint):uint
		{
			if(playscriptDict == null)
			{
				/* 当前的 saa 没有播放脚本 */
				return frameId % _numOfAssetFrame;
			}

			/* 将逻辑帧号的值做合法化处理 */
			frameId = frameId % playscriptDict[$NUM_OF_LOGICAL_FRAME];

			var soundWuid:String;

			if(onSoundPlay != null && (soundWuid = playscriptDict[frameId | BIT_MARK_SOUND_FRAME_ID]) != null)
			{ /* 有播放音效的需求 */
				/**
				 * TODO:
				 * play sound by wuid here
				 *
				 * ty Nov 14, 2013
				 */
				trace("[SAATexture.getAssetFrameIdFromFrameId] TODO: play sound:"+(playscriptDict[frameId | BIT_MARK_SOUND_FRAME_ID]));
				onSoundPlay(soundWuid);

			}

			return playscriptDict[frameId] || (frameId % _numOfAssetFrame);
		}

		/**
		 * 自我析构
		 */
		public function dispose():void
		{
			super.dispose();

			uvBuffer.dispose();
			uvBuffer = null;

			xywhBa.length = 0;
			xywhBa = null;

			playscriptDict = null;

			_numOfAssetFrame = 0;

			// delete WUID_TO_INSTANCE[wuid];

			wuid = null;
		}

		/**
		 * 构造函数
		 * @param enforcer
		 * @param wuid
		 * @param stream
		 */
		public function SAATexture(enforcer:Object , wuid:String , stream:ByteArray)
		{
			if (enforcer !== ENFORCER)
			{
				throw(new VerifyError);
			}

			vertexBuffer = vertexBuffer || renderContext.createVertexBuffer(4 , 2);

			this.wuid = wuid;

			stream.position = 3;
			var atfStartAt:uint  = stream.readUnsignedShort();
			var textureSize:uint = Math.pow(2 , stream.readUnsignedByte());

			/* 6	7	1	UByte	动画的帧数 */
			_numOfAssetFrame = stream.readUnsignedByte();

			/* 7	7 + 动画的帧数 * 8	动画的帧数 * 8	每帧 4 * Short	表达 x（相对于该帧的注册点的x）:Short, y（相对于该帧的注册点的y）:Short, w:UShort, h:UShort */
			var xywhBaLength:int = 8 * _numOfAssetFrame; /* 8 *  =  4 * 2 (shorts) */
			xywhBa = new ByteArray;
			stream.readBytes(xywhBa , 0 , xywhBaLength);

			/* 读一下看看是否有扩展数据 */
			var postionBeforeExt:uint = stream.position;
			if(stream.readUTFBytes(3) === "EXT")
			{ /* 有额外扩展数据 */
				/* n	n + 4	4	uint	一个32位的 bit flag ，每个flag 用于表达之后的一个数据功能是否开启。其中: flag0: 表达是否具有播放脚本。 flag1: 表达是否具有音效wuid组 */
				var bitFlag:uint = stream.readUnsignedInt();
				var n : uint;
				var i : uint;

				if(Boolean(bitFlag & 1))
				{ /*  flag0: 表达是否具有播放脚本。 */
					playscriptDict = playscriptDict || new Dictionary;

					/* 这段二进制的数据格式： UShort(count) + (UShort+UByte)[]	播放脚本的 byte dict, 两个 byte 一组，前一个byte是逻辑帧号，后一个byte是物理帧号 */
					n = stream.readUnsignedShort();
					for(i = 0; i < n; i++)
					{
						playscriptDict[stream.readUnsignedShort()] = stream.readUnsignedByte();
					}
					playscriptDict[$NUM_OF_LOGICAL_FRAME] = n; /* 记录总逻辑帧数 */
				}

				/* 切换到下一个flag */
				bitFlag = bitFlag >>> 1;

				if(Boolean(bitFlag & 1))
				{ /* flag1: 表达是否具有音效wuid组 */
					playscriptDict = playscriptDict || new Dictionary;

					/* 这段二进制的数据格式： UShort(count) + (UShort+UByte)[]	播放脚本的 byte dict, 两个 byte 一组，前一个byte是逻辑帧号，后一个byte是物理帧号 */
					n = stream.readUnsignedShort();
					for(i = 0; i < n; i++)
					{
						playscriptDict[stream.readUnsignedShort() | BIT_MARK_SOUND_FRAME_ID ] = stream.readUTF();
					}
				}
			}
			else
			{ /* 没有额外扩展数据 */
				stream.position = postionBeforeExt;
			}

			/* 读取 uv 片段 */
			uvBuffer = renderContext.createVertexBuffer(4 , _numOfAssetFrame << 1); /* x,y pair for 1 column */
			uvBuffer.uploadFromByteArray(stream , stream.position , 0 , 4);

			/* 上传 texture */
			// texture = renderContext.createTexture(textureSize , textureSize , COMPRESSED_ALPHA , false);
			texture = ATFHelper.createATFTexture(stream, atfStartAt);
			texture.addEventListener(Event.TEXTURE_READY , handleTextureReady);
			try
			{
				texture.uploadCompressedTextureFromByteArray(stream , atfStartAt , true);
			}
			catch (e:Error)
			{
				trace("ERROR upload GPU texture A failed, error:" + e);
				dispose();
				throw(e); /* 将这个错误冒泡给静态创建程序 */
			}
		}
	}
}
