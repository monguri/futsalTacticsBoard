package models
{
	public class FrameDatum
	{
		// jsonファイルへの出力のため、_xのように_をつけない
		public var x:int;
		public var y:int
		public var text:String;
		
		public function FrameDatum(_x:int, _y:int, _text:String)
		{
			x = _x;
			y = _y;
			text = _text;
		}
	}
}