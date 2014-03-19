package gama
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	/**
	 * 这是 基于 ATF 素材的，人物造型切片的素材容器
	 *
	 * @author ty
	 *
	 */
	public class SCATexture extends BaseTexture
	{

		/**
		 * 这里开放一个钩子方法，用于播放音效，以在不大改动目前的代码结构的前提下，快速播放音效
		 */
		static public var onSoundPlay:Function ;

		/**
		 * 播放脚本中的音效的数据位mask
		 */
		static private var BIT_MARK_SOUND_FRAME_ID:uint =  0x01000000 ;

		/**
		 * ATF texture 的上传格式
		 */
		private static  const COMPRESSED_ALPHA:String = "compressedAlpha";

		/**
		 * 内自建
		 */
		private static  const ENFORCER:Object = {} ;

		/**
		 * SAA 格式签名
		 */
		private static  const HEADER_SIGNATURE: String = "SCA";


		static private const MIN_WUID_LENGTH:uint = 3 ;

		/**
		 * key: wuid, value: SAATexture instance
		 */
		private static  const WUID_TO_INSTANCE:Dictionary = new Dictionary;

		/**
		 * 用于 draw traingle 的统一的 index buffer
		 */
//		private static  var indexBufferForRect:IndexBuffer3D ;

		/**
		 * 渲染目标
		 */
		private static  var renderContext:Context3D;

		/**
		 * 一个可以复用的 vertex buffer 容器
		 */
		private static  var vertexBuffer:VertexBuffer3D;

		/**
		 * 一个可以复用的 uv buffer 容器
		 */
		private static  var uvBuffer:VertexBuffer3D;

		private static var colorMasks:Vector.<Number> = new Vector.<Number>(4);
		colorMasks[3] = 1;

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
		 * 初始化静态数据
		 */
		static private function initStatic():void
		{
			if(renderContext == null) return; /* context 3d not ready */

			vertexBuffer = renderContext.createVertexBuffer(4, 3);

			uvBuffer = renderContext.createVertexBuffer(4, 2);

			// indexBufferForRect = IndexBuffers.indexBufferForRect;
		}

		/**
		 * @param wuid 素材的 wuid
		 * @param stream  素材的二进制流
		 * @return
		 */
		public static  function CreateTexture(wuid:String, stream:ByteArray):SCATexture
		{
			if(wuid == null || wuid.length < MIN_WUID_LENGTH)
			{
				throw(new ArgumentError);
			}

			if(stream == null || stream.length < 10)
			{
				trace("ERROR [SCATexture.CreateTexture] bad input stream:"+wuid);
				return null;
			}

			stream.position = 0;
			if(stream.readUTFBytes(3) != HEADER_SIGNATURE)
			{
				trace("ERROR [SCATexture.CreateTexture] bad sig:"+wuid);
				return null;
			}

			/* found in cache */
			if(WUID_TO_INSTANCE[wuid] != null)
			{
				return WUID_TO_INSTANCE[wuid];
			}

			var instance:SCATexture;
			try
			{
				instance = new SCATexture(ENFORCER, wuid, stream);
			}
			catch(e:Error)
			{
				trace("[SCATexture.CreateTexture] fail to create instance from stream. error:"+e);
				return null;
			}

			WUID_TO_INSTANCE[wuid] = instance;
			return instance;
		}

		/**
		 * 构造函数
		 * @param enforcer
		 * @param wuid
		 * @param stream
		 */
		public function SCATexture(enforcer:Object, wuid:String, stream:ByteArray)
		{
			if(enforcer !== ENFORCER)
			{
				throw( new VerifyError);
			}

//			if(renderContext == null) initStatic();

			this.wuid = wuid;

			infoDict = new Dictionary

			stream.position = 3;

			/* byte position of where atf data stream starts */
			var atfStartAt:uint = stream.readUnsignedInt();  /* step 2 */

			/* byte position of where uv data stream starts */
			var uvStartAt:uint = stream.readUnsignedInt();   /* step 3 */

			/* power of texture size */
			var textureSize:uint = Math.pow(2, stream.readUnsignedByte()); /* step 4 */

			/* count of asset frames */
			var count:uint = stream.readUnsignedByte(); /* step 5 */
			if(count == 0 || count > 12)
			{
				throw(new Error('bad numOfPose:'+count));
			}

			// var motionId:uint;
			// var numOfFrame:uint;
			for (var i:int = 0; i < count; i++)
			{ /* step 6 */
				infoDict[stream.readUnsignedByte()] = stream.readUnsignedByte(); /* infoDict[motionId] = numOfFrame; */
			}

			var motionDirFrameId:uint;

			count = stream.readUnsignedShort() / 4; /* step 7 */
			for (i = 0; i < count; i++)
			{ 	/* step 8: 在没有播放脚本的情况下，每个素材播放帧所对应的切片数据的数据位置下标 */
				motionDirFrameId = stream.readUnsignedInt();
				infoDict[motionDirFrameId] = i;
			}
			// trace("DUMP: [CharacterAnimationToATF.generateSCAHeader] motionDirFrameIds:"+arr);

			var xywhBaLength:int = 8 * count; /* 8 *  =  4 * 2 (shorts) */
			xywhBa = new ByteArray;
			stream.readBytes(xywhBa, 0, xywhBaLength); /* step 9 */

//			/* 找出站立的素材帧中最大的 y 偏移量 */
//			var frameNumOfStand:uint = infoDict[DEFAULT_MOTION_ID] || 0;
//			var tempYOffset:Number;
//			var dataIndex:uint;
//			for (i = 0; i < frameNumOfStand; i++)
//			{
//				motionDirFrameId = DEFAULT_MOTION_ID << 16 | DEFAULT_DIRECTION << 8 | i;
//				dataIndex = infoDict[motionDirFrameId];
//				xywhBa.position = (dataIndex << 3) + 2;
//				tempYOffset = xywhBa.readShort();
//				if(maxYOffsetOfStand > tempYOffset)
//				{
//					maxYOffsetOfStand = tempYOffset;
//				}
//			}

			maxYOffsetOfStand -= 20;
			/**
			 * NOTE:
			 *  通过 maxYOffsetOfStand -= 20 给造型切片的头顶预留足够的空间
			 *
			 * ty Nov 26, 2012
			 */

			// uvBuffer.uploadFromByteArray(stream, uvStartAt, 0, 4);

			if(stream.position < uvStartAt)
			{ /* 还有额外的附加属性 */

				/* 读一下看看是否有扩展数据 */
				var postionBeforeExt:uint = stream.position;
//				var motionId:uint;
				var frameCount:uint;
				if(stream.readUTFBytes(3) === "EXT")
				{ /* 有额外扩展数据 */
					/* n	n + 4	4	uint	一个32位的 bit flag ，每个flag 用于表达之后的一个数据功能是否开启。其中: flag0: 表达是否具有播放脚本。 flag1: 表达是否具有音效wuid组 */
					var bitFlag:uint = stream.readUnsignedInt();
					var n : uint;

					if(Boolean(bitFlag & 1))
					{ /*  flag0: 表达是否具有播放脚本。 */

						/* 这段二进制的数据格式： UShort(count) + (UInt + UShort)[]	播放脚本被转译成 motionDirFrameId 之后 和 assetFrame 的关系，其中 motionDirFrameId 为 UInt, assetFrame 为 UShort */
						n = stream.readUnsignedShort();
						for(i = 0; i < n; i++)
						{
							// var motionid:uint = stream.readUnsignedInt();
							// var countOfFrame:uint = stream.readUnsignedShort();
							// infoDict[motionid] = countOfFrame;
							// trace("[SCATexture.SCATexture] motionid:"+motionid+"("+ motionid.toString(16) +"); countOfFrame:"+countOfFrame);
							infoDict[stream.readUnsignedInt()] = stream.readUnsignedShort();
						}
					}

					/* 切换到下一个flag */
					bitFlag = bitFlag >>> 1;

					if(Boolean(bitFlag & 1))
					{ /* flag1: 表达是否具有音效wuid组 */

						/* 这段二进制的数据格式： UShort(count) + (UShort+UByte)[]	播放脚本的 byte dict, 两个 byte 一组，前一个byte是逻辑帧号，后一个byte是物理帧号 */
						n = stream.readUnsignedShort();
						for(i = 0; i < n; i++)
						{
							var frameId:uint = stream.readUnsignedInt() | BIT_MARK_SOUND_FRAME_ID ;
							var soundWuid:String = stream.readUTF();
							infoDict[frameId] = soundWuid;
							// infoDict[stream.readUnsignedInt() | BIT_MARK_SOUND_FRAME_ID ] = stream.readUTF();
						}
					}
				}
				else
				{ /* 没有额外扩展数据 */
					stream.position = postionBeforeExt;
					trace("!!!!!!!!!!!!!!! [SCATexture.SCATexture] UV Start 开始处不匹配，但是没有扩展信息，不应该啊，不应该啊");
				}
			}

			/* read in uv data stream */
			uvBa = new ByteArray; /* step 9 */
			stream.position = uvStartAt;
			stream.readBytes(uvBa, 0, count * 32); /* 32 = 4byte * 8 for each pair */
			uvBa.endian = Endian.LITTLE_ENDIAN; /* 传入显卡的byte array 必须是 little endian */

			/* upload texture */
			texture = renderContext.createTexture(textureSize, textureSize, COMPRESSED_ALPHA, false);
			texture.addEventListener(Event.TEXTURE_READY, handleTextureReady);
			try{
				texture.uploadCompressedTextureFromByteArray(stream, atfStartAt, true);
			}
			catch(e:Error)
			{
				trace("ERROR upload GPU texture C failed, error:"+e);
				dispose();
				throw(e); /* 将这个错误冒泡给静态创建程序 */
			}
		}

		/**
		 * 将给定的 动作 id 放到当前素材所具备的所有造型切片中查找，
		 * 如果给定的动作上么有素材的话，那么找到具有素材的匹配动作
		 * @param motionId
		 * @return
		 */
		public function getAvaliableMotionId(motionId:uint):uint
		{
			// trace("[SCATexture.getAvaliableMotionId] motionId:"+motionId+"; motionId in infoDict:"+(motionId in infoDict));
			if(motionId in infoDict) return motionId;

//			while(motionId !== DEFAULT_MOTION_ID && !(motionId in infoDict))
//			{
//				motionId = MOTION_LOST_N_FOUND[motionId];
//			}
//			return motionId;
			return 0;
		}


//		/**
//		 * 帮助缺失的动作找到 缺失时候的补偿动作
//		 */
//		static private const MOTION_LOST_N_FOUND:Dictionary = Pose.MOTION_LOST_N_FOUND;

		/**
		 * 方向关系的对照表
		 * 2 方向组
		 */
		static private const DIRECTION_RELATIONSHIP:Dictionary = new Dictionary ;

		/**
		 * 北东南，5项方向组
		 */
		static public const DIRECTION_MODE_FIVE:uint = 5 ;

		/**
		 * 南北两项方向组
		 */
		static public const DIRECTION_MODE_TWO:uint = 2;


		static public function SetDirectionMode(mode:uint):void
		{
			switch(mode	)
			{
				case DIRECTION_MODE_TWO:
					Direction.DEFAULT_DIRECTION = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.NORTH] = Direction.NORTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.NORTH_EAST] = Direction.NORTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.EAST] = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.SOUTH_EAST] = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.SOUTH] = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.SOUTH_WEST] = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.WEST] = Direction.NORTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.NORTH_WEST] = Direction.NORTH_EAST;
					break;

				case DIRECTION_MODE_FIVE:
					Direction.DEFAULT_DIRECTION = Direction.SOUTH;
					DIRECTION_RELATIONSHIP[Direction.NORTH] = Direction.NORTH;
					DIRECTION_RELATIONSHIP[Direction.NORTH_WEST] = Direction.NORTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.WEST] = Direction.EAST;
					DIRECTION_RELATIONSHIP[Direction.SOUTH_WEST] = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.SOUTH] = Direction.SOUTH;
					DIRECTION_RELATIONSHIP[Direction.SOUTH_EAST] = Direction.SOUTH_EAST;
					DIRECTION_RELATIONSHIP[Direction.EAST] = Direction.EAST;
					DIRECTION_RELATIONSHIP[Direction.NORTH_EAST] = Direction.NORTH_EAST;
					break;

				default:
					trace("ERROR [SCATexture.SetDirectionMode] unknown mode:"+mode);
			}
		}

		static private const MERGED_DIRECTIONS:Dictionary = new Dictionary ;
		MERGED_DIRECTIONS[Direction.NORTH_EAST] = Direction.NORTH;
		MERGED_DIRECTIONS[Direction.SOUTH_EAST] = Direction.SOUTH;

		/**
		 * 方向的总数量
		 */
		static private const NUM_OF_DIRECTIONS:int = 8;


		static private const DEFAULT_DIRECTION:uint = Direction.SOUTH ;

		/**
		 * 颜色滤镜：红
		 */
		static public const COLOR_MASK_RED:uint =  1 << 3;

		/**
		 * 颜色滤镜：绿
		 */
		static public const COLOR_MASK_GREEN:uint =  1 << 2;

		/**
		 * 颜色滤镜：蓝
		 */
		static public const COLOR_MASK_BLUE:uint =  1 << 1;

		/**
		 * 颜色滤镜：青
		 */
		static public const COLOR_MASK_CYAN:uint =  COLOR_MASK_GREEN | COLOR_MASK_BLUE;

		/**
		 * 颜色滤镜：紫
		 */
		static public const COLOR_MASK_PURPLE:uint =  COLOR_MASK_RED | COLOR_MASK_BLUE;

		/**
		 * 颜色滤镜：黄
		 */
		static public const COLOR_MASK_YELLOW:uint =  COLOR_MASK_RED | COLOR_MASK_GREEN;

		/**
		 * 颜色滤镜：关闭
		 */
		static public const COLOR_MASK_OFF:uint =  0;

		/**
		 * 添加渲染请求
		 */
		/**
		 *
		 * @param sca SCA 实例
		 * @param pixelX 对齐点所在的 x
		 * @param pixelY 对齐点所在的 y
		 * @param motionId  要绘制的动作编号
		 * @param direction  要绘制的方向
		 * @param frameId 要绘制的素材帧编号
		 * @param alpha  透明度。取值区间 [0, 1]
		 * @param hpPercent 当前的血量百分比, 格式如下：
		 *  1. 如果不显示血量，则使用 NaN （默认不显示）
		 *  2. 友方的血量为正数， 敌方为负数
		 *  3. 整数部分作为对象的等级。 如果不需要渲染等级的话，整数为 0
		 *  4. 小数部分是血量的百分比
		 * @param colorMask 绘制时候的采用的色彩遮罩
		 */
		static public function AddDrawRequestByInstance(sca:SCATexture, pixelX:int, pixelY:int, motionId:uint, direction:uint, frameId:uint, alpha:Number = 1, hpPercent:Number = NaN, colorMask:uint = 0):void
		{
			// trace("[SCATexture.AddDrawRequestByInstance] motionId:"+motionId);

			if(sca == null || !sca.isReady) return;

//			if(motionId === DEAD_MOTION_ID) frameId = sca.getDeadMotionFrameId();

			motionId = sca.getAvaliableMotionId(motionId); /* 确保 动作的有效性 */

			direction = direction % NUM_OF_DIRECTIONS; /* 避免无效的方向 */

			var assetDirection:uint = DIRECTION_RELATIONSHIP[direction]; /* 读出实际素材的方向*/

			/**
			 * 数据步长9,次序如下
			 * 实例，pixelX, pixelY, motionId, assetDirection, frameId, isMirrored, alpha, colorMask,
			 */
			// REQUEST_QUEUE.push(sca, pixelX, pixelY, motionId, assetDirection, frameId, assetDirection !== direction, alpha > 1 ? 1 : alpha, hpPercent, colorMask);
			REQUEST_QUEUE.push(sca, pixelX, pixelY, motionId, assetDirection, frameId, Direction.isMirroredDirection(direction), alpha > 1 ? 1 : alpha, hpPercent, colorMask);
		}


		/**
		 * 用于 上传 vertex buffer 数据的容器
		 */
		static private var vetexDataContainer:ByteArray = new ByteArray;
		vetexDataContainer.endian = Endian.LITTLE_ENDIAN;

		/**
		 * 用于渲染贴图的 shader
		 */
//		static private var shaderForTexture:Program3D;

		/**
		 * 用于渲染血条的 shader
		 */
//		static private var shaderForBloodBar:Program3D;

		/** Cached static lookup of Context3DVertexBufferFormat.FLOAT_2 */
		private static const FLOAT2_FORMAT:String = Context3DVertexBufferFormat.FLOAT_2;

		private static const FLOAT3_FORMAT:String = Context3DVertexBufferFormat.FLOAT_3;

		/**
		 * 渲染请求的 byte 步长
		 * 				requestBa.writeShort(pixelX);
				requestBa.writeShort(pixelY);
				requestBa.writeByte(motionId);
				requestBa.writeByte(assetDirection);
				requestBa.writeByte(frameId);
				requestBa.writeBoolean(assetDirection !== direction);
				requestBa.writeByte(alpha);
				hpPercent
				requestBa.writeByte(colorMask);

		 */
		static private const REQUEST_QUEUE_STEP:uint = 10 ;

		/**
		 * 数据步长9,次序如下
		 * 实例，pixelX, pixelY, motionId, assetDirection, frameId, isMirrored, alpha, colorMask,
		 */
		static private const REQUEST_QUEUE:Array = [];



		/**
		 * 返回给定动作的素材帧数
		 * @param motionId
		 * @return
		 */
		public function getAssetNumForMontion(motionId:int):int
		{
			return infoDict[motionId];
		}

		/**
		 * 绘制当前队列中的所有渲染请求
		 */
		static public function RenderDrawRequests():void
		{
			// trace("[SCATexture.RenderDrawRequests] renderContext:"+renderContext);

			if(renderContext == null)
			{
				// trace("[SCATexture.RenderDrawRequests] context 3d not ready");
				return;
			}
			// var colorMasks:Vector.<Number> = new Vector.<Number>(4);
			var sca:SCATexture;
			var offset:Number;
			var x:Number;
			var y:Number;

			var frameId:int;
			var motionId:int;
			var direction:int;
			var isMirrored:Boolean;
			var i:int;
			var n:int;
			var w:Number;
			var h:Number;
			var xywhBa:ByteArray;
			var dataIndex:int;
			var motionDireFrameId:uint;
			var avaliableFrameNumOfMotion:uint;
			var colorMask:uint;
			var alpha:Number;
			var infoDict:Dictionary;
			var hpPercent:Number;
			var bloorColorType:int;
			var level:uint;

//			trace("[SCATexture.RenderDrawRequests] hpPercent:"+hpPercent);

			renderContext.setProgram(Shaders.shadersForSCA);

			n = REQUEST_QUEUE.length;
			for (i = 0; i < n; i+= REQUEST_QUEUE_STEP)
			{
				x = REQUEST_QUEUE[i+1];
				y = REQUEST_QUEUE[i+2];
				sca = REQUEST_QUEUE[i];
				xywhBa = sca.xywhBa;
				hpPercent = REQUEST_QUEUE[i+8];

				/* 请求中要求绘制血条 */
				if(!isNaN(hpPercent))
				{
					// trace("[SCATexture.RenderDrawRequests] 绘制血条, hpPercent:"+hpPercent);

					if(hpPercent < 0)
					{
						hpPercent = - hpPercent;
						bloorColorType = 6;
					}
					else
					{
						bloorColorType = 3;
					}

					offset = y + sca.maxYOffsetOfStand;


//					renderContext.setProgram(shaderForBloodBar);
//
//					/* 向AGAL传入当前的 x,y 偏移量 */
//					XYOFFSET_CONSTANT_CONTAINER.position = 0;
//					XYOFFSET_CONSTANT_CONTAINER.writeFloat(x);
//					XYOFFSET_CONSTANT_CONTAINER.writeFloat(offset);
//					renderContext.setProgramConstantsFromByteArray(PROGRAME_TYPE_VERTEX, 4, 1, XYOFFSET_CONSTANT_CONTAINER, 0); /* vc4 */
//
//					if(hpPercent < 1)
//					{
//						/* 绘制外框 */
//						renderContext.setVertexBufferAt( 0, bloodBarBuffer, 0, FLOAT3_FORMAT); //va0 is position
//						renderContext.setVertexBufferAt( 1, bloodBarBuffer, 9, FLOAT3_FORMAT ); //va1 is color
//						renderContext.drawTriangles( indexBufferForRect, 0, 2 );
//
//						/* 绘制内框 */
//						renderContext.setVertexBufferAt( 0, bloodBarSmallStepBuffer, hpPercent * INNER_BLOOD_BAR_WIDTH / 2 >>> 0 << 1, FLOAT2_FORMAT ); //va0 is position
//						renderContext.setVertexBufferAt( 1, bloodBarBuffer, bloorColorType, FLOAT3_FORMAT ); //va1 is color 内框的黑色
//						renderContext.drawTriangles( indexBufferForRect, 0, 2 );
//					}
//					else
//					{
//						hpPercent = hpPercent % 1;
//
//						/* 绘制内框 */
//						renderContext.setVertexBufferAt( 0, bloodBarInnerStepBuffer, hpPercent * INNER_BLOOD_BAR_WIDTH / 2 >>> 0 << 1, FLOAT2_FORMAT ); //va0 is position
//						renderContext.setVertexBufferAt( 1, bloodBarBuffer, bloorColorType, FLOAT3_FORMAT ); //va1 is color 内框的黑色
//						renderContext.drawTriangles( indexBufferForRect, 0, 2 );
//					}
//
//					renderContext.setProgram(shaderForTexture);
				}

				motionId = REQUEST_QUEUE[i+3];
				direction = REQUEST_QUEUE[i+4];
				frameId = REQUEST_QUEUE[i+5];
				isMirrored = REQUEST_QUEUE[i+6];
				alpha = REQUEST_QUEUE[i+7];
				colorMask = REQUEST_QUEUE[i+9];

				/* 读出素材中当前动作所具有的动画实际素材帧数 */
				infoDict = sca.infoDict;
				avaliableFrameNumOfMotion = infoDict[motionId];
				frameId = frameId % avaliableFrameNumOfMotion;

				/* 找到适合的动作 */
				motionDireFrameId = motionId << 16 | direction << 8 | frameId;
//				if(!(motionDireFrameId in infoDict))
//				{
//					motionDireFrameId = motionId << 16 | ( direction in MERGED_DIRECTIONS ? MERGED_DIRECTIONS[direction] : DEFAULT_DIRECTION )<< 8 | frameId;
//					if(!(motionDireFrameId in infoDict))
//					{
//						motionDireFrameId = motionId << 16 | DEFAULT_DIRECTION << 8 | frameId;
//						if(!(motionDireFrameId in infoDict))
//						{
//							trace("ERROR [SCATexture.RenderDrawRequests] 素材帧缺失。 motionid:"+motionId+"; direction:"+direction+"; frame:"+frameId+"; wuid:"+sca.wuid);
//							continue;
//						}
//					}
//				}

				dataIndex = sca.infoDict[motionDireFrameId];

				// trace("[SCATexture.RenderDrawRequests] motionDireFrameId:"+motionDireFrameId+"("+motionDireFrameId.toString(16)+"), dataIndex:"+dataIndex);

				if(isNaN(dataIndex))
				{
					trace("ERROR [SCATexture.RenderDrawRequests] missng texture: motion:"+motionId+"; direction:"+direction+"; frame:"+frameId+"; wuid:"+sca.wuid);
					continue;
				}

				var soundWuid:String;

				if(onSoundPlay != null && (soundWuid = sca.infoDict[motionDireFrameId | BIT_MARK_SOUND_FRAME_ID]) != null)
				{
					trace("[SCATexture.RenderDrawRequests] play sound:"+(sca.infoDict[motionDireFrameId | BIT_MARK_SOUND_FRAME_ID]));
					onSoundPlay(soundWuid);
				}


				xywhBa.position = dataIndex << 3; // * 8;

				/* 绘制造型切片 */
				offset = xywhBa.readShort();
				y += xywhBa.readShort(); /* y += offsetY */
				w = xywhBa.readShort();
				h = xywhBa.readShort();

				if(isMirrored)
				{
					x -= w + offset;
				}
				else
				{
					x += offset;
				}

				// trace("[SCATexture.RenderDrawRequests] ", offsetX, x, y, w, h);

				/* 建立当前绘制请求的 vertex */
				vetexDataContainer.position = 0;

				if(isMirrored)
				{ /* x 镜像, 点位是 3，2，1，0 */
					vetexDataContainer.writeFloat(x + w);	vetexDataContainer.writeFloat(y);  vetexDataContainer.writeFloat(alpha);
					vetexDataContainer.writeFloat(x + w);	vetexDataContainer.writeFloat(y + h); vetexDataContainer.writeFloat(alpha);
					vetexDataContainer.writeFloat(x); vetexDataContainer.writeFloat(y + h); vetexDataContainer.writeFloat(alpha);
					vetexDataContainer.writeFloat(x);	vetexDataContainer.writeFloat(y); vetexDataContainer.writeFloat(alpha);
				}
				else
				{ /* 点位是 0,1,2,3 */
					vetexDataContainer.writeFloat(x);	vetexDataContainer.writeFloat(y); vetexDataContainer.writeFloat(alpha);
					vetexDataContainer.writeFloat(x); vetexDataContainer.writeFloat(y + h); vetexDataContainer.writeFloat(alpha);
					vetexDataContainer.writeFloat(x + w);	vetexDataContainer.writeFloat(y + h); vetexDataContainer.writeFloat(alpha);
					vetexDataContainer.writeFloat(x + w);	vetexDataContainer.writeFloat(y); vetexDataContainer.writeFloat(alpha);
				}

				try{
					renderContext.setTextureAt(0, sca.texture); /* 设置贴图 */

					vertexBuffer.uploadFromByteArray(vetexDataContainer, 0, 0, 4); /* 上传绘制区域的 vetex 顶点 */

					uvBuffer.uploadFromByteArray(sca.uvBa, 32 * dataIndex, 0, 4);	/* 上传绘制区域的 uv */

					/* 设置色彩遮罩 */
					colorMasks[0] = Boolean(colorMask >>> 3 & 1) ? 3 : 1  	// r
					colorMasks[1] = Boolean(colorMask >>> 2 & 1) ? 3 : 1	// g
					colorMasks[2] = Boolean(colorMask >>> 1 & 1) ? 3 : 1	// b

					renderContext.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,colorMasks);
					renderContext.setVertexBufferAt(0,vertexBuffer , 0, FLOAT3_FORMAT); /* 设置顶点 */
					renderContext.setVertexBufferAt(1, uvBuffer, 0, FLOAT2_FORMAT);  /* 设置UV */
					renderContext.drawTriangles(IndexBuffers.indexBufferForRect, 0, 2); /* 根据 index 渲染 */
				}
				catch(e:Error)
				{
					// trace("ERROR [SCATexture.RenderDrawRequests] err:"+e);
				}
			}

			REQUEST_QUEUE.splice(0, n);
		}

		static private const PROGRAME_TYPE_VERTEX:String = Context3DProgramType.VERTEX;

		/**
		 * 用于向绘制 血条的 agal 传入当前的 x,y 偏移量的 byte array
		 */
		static private const XYOFFSET_CONSTANT_CONTAINER:ByteArray = new ByteArray ;
		XYOFFSET_CONSTANT_CONTAINER.endian = Endian.LITTLE_ENDIAN;
		XYOFFSET_CONSTANT_CONTAINER.length = 16; /* 4 float * 4 */

		/**
		 * 返回死亡动作，在倒地动作中所占有的素材帧号
		 * @return
		 */
//		private function getDeadMotionFrameId():uint
//		{
//			var val:int = infoDict[KNOCK_DOWN_MOTION_ID];
//			return val > 0 ?  val - 1 : 0; /* 没有倒地动作时返回 0 */
//		}

		/**
		 * 存储实例中所有信息的 dictionary
		 * 其中的数据结构包括：
		 * motionId ： number of frame
		 * motionDirFrameId : index of xywh buffer position
		 */
		private var infoDict:Dictionary;

		/**
		 * 表达 每帧的 xOffset, yOffset, width, height 的 byte array
		 */
		private var xywhBa:ByteArray;

		/**
		 * 存储uv的 byte array
		 */
		private var uvBa:ByteArray;

		/**
		 * 造型切片在向南站立时候的头顶的y偏移量
		 */
		public var maxYOffsetOfStand:Number = 0;

		/**
		 * 自我析构
		 */
		public function dispose():void
		{
			super.dispose();

			xywhBa.length = 0;
			xywhBa = null;

			uvBa.length = 0;
			uvBa = null;

			infoDict = null;

			delete WUID_TO_INSTANCE[wuid];

			wuid = null;
		}

		{
			SetDirectionMode(DIRECTION_MODE_TWO); //默认为2向方向组
		}
	}
}