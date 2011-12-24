package models
{
	public class RecordBean
	{
		private var _title:String;
		private var _comment:String;
		private var _frameData:Vector.<Vector.<FrameDatum>>;
		
		public function RecordBean()
		{
			_frameData = new Vector.<Vector.<FrameDatum>>;
			// 二次元配列のnewだけでなく一次元配列をnewしておかないと要素をpushできない
			for (var i:uint = 0; i < Const.NUM_PIECES; i++)
			{
				_frameData[i] = new Vector.<FrameDatum>;
			}
		}

		public function pushFrameDatum(playerNum:int, datum:FrameDatum):void
		{
			_frameData[playerNum].push(datum);
		}
		
		public function frameLength():int
		{
			// 毎フレームすべての配列にデータを入れるので番号0のものの長さを返せばよい
			return _frameData[0].length;
		}
		
		public function get title():String
		{
			return _title;
		}

		public function set title(value:String):void
		{
			_title = value;
		}

		public function get comment():String
		{
			return _comment;
		}

		public function set comment(value:String):void
		{
			_comment = value;
		}

		public function get frameData():Vector.<Vector.<FrameDatum>>
		{
			return _frameData;
		}

		public function set frameData(value:Vector.<Vector.<FrameDatum>>):void
		{
			_frameData = value;
		}
	}
}