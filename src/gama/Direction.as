package gama
{
	import flash.geom.Point;
	import flash.utils.Dictionary;

	/**
	 * ...
	 * @author Yi
	 */
	public class Direction
	{
//		public static const DIR_LABELS:Array = ['北','东北','东','东南','南','西南','西','西北'];
		public static const NORTH:int                          = 0;
		public static const NORTH_EAST:int                     = 1;
		public static const EAST:int                           = 2;
		public static const SOUTH_EAST:int                     = 3;
		public static const SOUTH:int                          = 4;
		public static const SOUTH_WEST:int                     = 5;
		public static const WEST:int                           = 6;
		public static const NORTH_WEST:int                     = 7;
		public static const NONE:int                     	   = -1;

		/**
		 * 默认方向为下方
		 */
		public static var DEFAULT_DIRECTION:int              = SOUTH;

		/**
		 * 	总方向数量
		 */
		public static const TOTAL_DIRECTION_NUM:int            = 8;

		/**
		 * 素材的方向总数
		 */
		public static const ASSET_DIRECTION_NUM:int            = 5;


		/**
		 * degrees of each direction.
		 *
		 * use example:
		 * DIRECTION_DEGREE[NORTH_EAST] // 45
		 */
		public static const DIRECTION_DEGREE:Array             = [0 , 45 , 90 , 135 , 180 , 225 , 270 , 315];

		/**
		 * radians of each direction
		 */
		public static const DIRECTION_RADIANS:Array            = [0 , Math.PI / 4 , Math.PI / 2 ,
																  Math.PI * 3 / 4 , Math.PI ,
																  Math.PI * 5 / 4 , Math.PI * 3 / 2 ,
																  Math.PI * 7 / 4];

		/**
		 * 在 x轴上的被镜像后方向
		 */
		public static const REVERSIBLE_DIRECTIONS:Vector.<int> = new Vector.<int>;
		REVERSIBLE_DIRECTIONS.push(0 , 7 , 6 , 5 , 4 , 3 , 2 , 1);

		static private const MIRRORED_DIRECTIONS:Dictionary = new Dictionary ;
		MIRRORED_DIRECTIONS[NORTH_WEST] = NORTH_EAST;
		MIRRORED_DIRECTIONS[WEST] = EAST;
		MIRRORED_DIRECTIONS[SOUTH_WEST] = SOUTH_EAST;

		/**
		 * 返回一个方向的实际素材方向
		 * @param dir
		 * @return
		 */
		static public function getAssetDirection(dir:int):int
		{
			return MIRRORED_DIRECTIONS[dir] || dir;
		}

		/**
		 * 判断给定的方向是否是一个镜像方向
		 * @param dir
		 * @return
		 */
		static public function isMirroredDirection(dir:int):Boolean
		{
			return MIRRORED_DIRECTIONS[dir] != null;
		}

		/**
		 * Calculate the radians between 2 given points/ 1 give point from current zero point/ given
		 * x delta and y delta
		 *
		 * @param 	input	Could accept following form:
		 * 					1) start point:Point, end point:Point
		 * 					2) target point:Point
		 * 					3) x delta:Number, y delta:Number
		 * @return  a radians number
		 */
		public static function getRadians(... input:*):Number
		{
			var deltaPoint:Point = getDelta(input);

			var delta_x:Number   = deltaPoint.x;
			var delta_y:Number   = deltaPoint.y;

			var r:Number         = Math.atan2(delta_y , delta_x);
			if (delta_y < 0)
			{
				r += (2 * Math.PI);
			}
			return r;
		}

		/**
		 * convert radians value of an angle to degree value
		 * @param	radians
		 * @return
		 */
		public static function radiansToDegrees(radians:Number):int
		{
			return 360 - Math.floor(radians / (Math.PI / 180));
		}

		/**
		 * 获取一个随机的方向
		 */
		public static function Random():int
		{
			return (Math.random() * TOTAL_DIRECTION_NUM) >> 0;
		}

		/**
		 * 返回两点之间的方向
		 * @return
		 *
		 */
		static public function directionBetweenPoints(... rest):int
		{
			return radiansToDirection(getRadians.apply(null , rest));
		}

		/**
		 * 返回两点之间的角度
		 * @return
		 *
		 */
		static public function degreeBetweenPoints(... rest):int
		{
			return radiansToDegrees(getRadians.apply(null , rest));
		}

		/**
		 * 根据给定的弧度计算出方向
		 *
		 * @param radians
		 * @return 方向的int值
		 *
		 */
		public static function radiansToDirection(radians:Number):int
		{
			var piGree:int = Math.floor(radians / (Math.PI / 8));
			var direction:int;

			/* TODO:
			 *  将下面的 switch 优化为一个数值计算
			 *
			 * Yi Aug 8, 2010
			 */

			switch (piGree)
			{
				case 15:
				case 0:
					direction = EAST;
					break;
				case 1:
				case 2:
					direction = SOUTH_EAST;
					break;
				case 3:
				case 4:
					direction = SOUTH;
					break;
				case 5:
				case 6:
					direction = SOUTH_WEST;
					break;
				case 7:
				case 8:
					direction = WEST;
					break;
				case 9:
				case 10:
					direction = NORTH_WEST;
				case 11:
					break;
				case 12:
					direction = NORTH;
					break;
				case 13:
				case 14:
					direction = NORTH_EAST;
			}

			return direction;
		}

		/**
		 * 获取两个 birck location key 之间的方向
		 * @param xDelta
		 * @param yDelta
		 * @return
		 */
		public static function GetDirectionOfBrickLocationKey(current:uint, destination:uint):int
		{
			return GetDirection((destination >>> 16) - (current >>> 16), ((destination & 0xffff) - (current & 0xffff)));
		}

		/**
		 * 给定直角坐标系中坐标点的x,y，返回这个点所位于的8个方向中的方向值，即 北:0, 东:2, 南: 4， 西: 6
		 * @param xDelta
		 * @param yDelta
		 * @return
		 */
		public static function GetDirection(xDelta:int, yDelta:int):int
		{
			/* 在预先计算的方向列表中没有找到匹配的目标方向，因此进行实际计算 */
			var direction:int = Math.round(
				(
					Math.atan2(
						yDelta, xDelta
					)/Math.PI + 1
				) * 4
			) - 2;
			return direction == -2 ? 6 : direction == -1 ? 7 : direction;
		}

		static private const DIRECTION_POLAR_X:Array = [0, 0.707106, 1, 0.707106, 0, - 0.707106, -1, -0.707106] ;
		static private const DIRECTION_POLAR_Y:Array = [-1, -0.707106, 0, 0.707106, 1, 0.707106, 0, -0.707106] ;

		static public function PolarXOnDirect(len:Number, direction:int):Number
		{
			return len * DIRECTION_POLAR_X[direction]
		}

		static public function PolarYOnDirect(len:Number, direction:int):Number
		{
			return len * DIRECTION_POLAR_Y[direction]
		}

		/**
		 * Calculate the delta between 2 given points/ 1 give point from current zero point/ given
		 * x delta and y delta
		 *
		 * @param 	input	Could accept following form:
		 * 					1) start point:Point, end point:Point
		 * 					2) target point:Point
		 * 					3) x delta:Number, y delta:Number
		 * @return  a radians number
		 */
		public static function getDelta(... input:*):Point
		{
			var delta_x:Number , delta_y:Number;

			// TODO: take out this to getDelta()
			switch (input.length)
			{
				case 1:
					if (input[0] is Point)
					{
						delta_x = input[0].x;
						delta_y = input[0].y;
						break;
					}
					else if (input[0] is Array && input[0].length == 2)
					{
						input[1] = input[0][1];
						input[0] = input[0][0];
					}
					else
					{
						throw new Error("Invalid input arguments(1)");
					}
				case 2:
					if (input[0] is Point && input[1] is Point)
					{
						delta_x = input[1].x - input[0].x;
						delta_y = input[1].y - input[0].y;
					}
					else
					{
						delta_x = Number(input[0]);
						delta_y = Number(input[1]);

						if (isNaN(delta_x) || isNaN(delta_y))
							throw new Error("Invalid input arguments(2)");
					}
					break;
				default:
					throw new Error("Invalid input arguments(3)");
			}

			return new Point(delta_x , delta_y);
		}

		private static const dirToDxy:Array            = [
			//dx,dy
			[0 , 0] ,//-1
			[-1 , 0] ,//0
			[-1 , 1] ,//1
			[0 , 1] ,//2
			[1 , 1] ,//3
			[1 , 0] ,//4
			[1 , -1] ,//5
			[0 , -1] ,//6
			[-1 , -1],//7
			];

		/**
		 * 由于方向而引起的格子的 x, y 的变化
		 */
		public static const DIR_TO_BRICK_XY_CHANGE:Vector.<int> = new <int>[
			//dx,dy
			0 , 0 ,//-1
			-1 , 0 ,//0
			-1 , 1 ,//1
			0 , 1 ,//2
			1 , 1 ,//3
			1 , 0 ,//4
			1 , -1 ,//5
			0 , -1 ,//6
			-1 , -1//7
		];

		/**
		 * 将目标点在方向上行走一步
		 * @param src
		 * @param dir
		 * @return
		 */
		public static function step(src:Point , dir:int):Point
		{
			return new Point(src.x + dirToDxy[dir][0] , src.y + dirToDxy[dir][1]);
		}
	}
}
