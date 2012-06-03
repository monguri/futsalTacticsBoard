package models
{
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;

	//TODO;Recordの中にXMLやFileみたいな都合は隠蔽したいな
	public class RecordInfoModelList
	{
		private var _list:Array;
		
		public function RecordInfoModelList()
		{
			_list = new Array();
			
			CONFIG::SERVER{
				// リストの一番上の項目はサーバダウンロード 
				var record:RecordInfoModel = new RecordInfoModel(null, Const.DOWNLOAD_LIST_LABEL, null);
				_list.push(record);
			}
		}
		
		public function pushRecord(file:File, title:String, comment:String):void
		{
			var record:RecordInfoModel = new RecordInfoModel(file, title, comment);
			_list.push(record);
		}
		
		public function dataProviderList(searchKeyword:String = null):ArrayCollection
		{
			if (searchKeyword == null || searchKeyword == '')
			{
				return new ArrayCollection(_list);
			}
			else
			{
				var searchedRecords:Array = new Array();
				for each (var record:RecordInfoModel in _list)
				{
					if (record.containWord(searchKeyword))
					{
						searchedRecords.push(record);
					}
				}
				
				return new ArrayCollection(searchedRecords);
			}
		}
		
		public function remove(record:RecordInfoModel):void
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
		
		public function removeAll():void
		{
			_list.splice(0, _list.length);
		}
		
		public function length():uint
		{
			return _list.length;
		}
	}
}