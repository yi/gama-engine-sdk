package sgf.util
{
	public function sat(value:Number,max:Number=0,min:Number=0):Number
	{
		return Math.max(Math.min(max,value),min);
	}
}