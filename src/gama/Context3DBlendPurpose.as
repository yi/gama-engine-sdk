package gama
{
	import flash.display3D.Context3DBlendFactor;
	import flash.utils.Dictionary;

	public class Context3DBlendPurpose
	{

		/*

		The following examples demonstrate the blending math using source color = (.6,.4,.2,.4), destination color = (.8,.8,.8,.5), and various blend factors.

		Purpose	Source factor	Destination factor	Blend formula	Result
		No blending	ONE	ZERO	(.6,.4,.2,.4) * ( 1, 1, 1, 1) + (.8,.8,.8,.5) * ( 0, 0, 0, 0)	( .6, .4, .2, .4)
		Alpha	SOURCE_ALPHA	ONE_MINUS_SOURCE_ALPHA	(.6,.4,.2,.4) * (.4,.4,.4,.4) + (.8,.8,.8,.5) * (.6,.6,.6,.6)	(.72,.64,.56,.46)
		Additive	ONE	ONE	(.6,.4,.2,.4) * ( 1, 1, 1, 1) + (.8,.8,.8,.5) * ( 1, 1, 1, 1)	( 1, 1, 1, .9)
		Multiply	DESTINATION_COLOR	ZERO	(.6,.4,.2,.4) * (.8,.8,.8,.5) + (.8,.8,.8,.5) * ( 0, 0, 0, 0)	(.48,.32,.16, .2)
		Screen	ONE	ONE_MINUS_SOURCE_COLOR	(.6,.4,.2,.4) * ( 1, 1, 1, 1) + (.8,.8,.8,.5) * (.4,.6,.8,.6)	(.92,.88,.68, .7)

		*/

		static public const NO_BLENDING:String = 'n' ;

		static public const ALPHA:String = 'a' ;

		static public const ADDITIVE:String = 'd' ;

		static public const MULTIPLY:String = 'm' ;

		static public const SCREEN:String = 's' ;


		static internal const BLEND_MODE_FACTORS:Dictionary = new Dictionary ;
		BLEND_MODE_FACTORS[NO_BLENDING + 's'] = Context3DBlendFactor.ONE;
		BLEND_MODE_FACTORS[NO_BLENDING + 'd'] = Context3DBlendFactor.ZERO;

		BLEND_MODE_FACTORS[ALPHA + 's'] = Context3DBlendFactor.SOURCE_ALPHA;
		BLEND_MODE_FACTORS[ALPHA + 'd'] = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;

		BLEND_MODE_FACTORS[ADDITIVE + 's'] = Context3DBlendFactor.ONE;
		BLEND_MODE_FACTORS[ADDITIVE + 'd'] = Context3DBlendFactor.ONE;

		BLEND_MODE_FACTORS[MULTIPLY + 's'] = Context3DBlendFactor.DESTINATION_COLOR;
		BLEND_MODE_FACTORS[MULTIPLY + 'd'] = Context3DBlendFactor.ZERO;

		BLEND_MODE_FACTORS[SCREEN + 's'] = Context3DBlendFactor.ONE;
		BLEND_MODE_FACTORS[SCREEN + 'd'] = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;

	}
}