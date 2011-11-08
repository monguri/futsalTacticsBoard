package models
{
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;

	//TODO;Recordの中にXMLやFileみたいな都合は隠蔽したいな
	public class RecordList
	{
		private var _list:Array;
		
		public function RecordList()
		{
			_list = new Array();
		}
		
		public function pushRecord(file:File, title:String):void
		{
			var record:Record = new Record(file, title);
			_list.push(record);
		}
		
		public function dataProviderList():ArrayCollection
		{
			// TODO:Arrayを継承でなくクラス内で保持するようにしてもやはり失敗する。原因不明。
			return new ArrayCollection(_list);
		}
		
		public function deleteRecord(record:Record):void
		{
			var len:uint = _list.length;
			for (var i:uint = 0; i < len; i++)
			{
				if (_list[i] === record)
				{
					break;
				}
			}
			
			_list.splice(i, 1);
		}
		
		public function length():uint
		{
			return _list.length;
		}
	}
}