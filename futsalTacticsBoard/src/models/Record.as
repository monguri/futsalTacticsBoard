package models
{
	import flash.filesystem.File;

	//TODO;Recordの中にXMLやFileみたいな都合は隠蔽したいな
	public class Record
	{
		private var _file:File;
		private var _title:String;
		
		public function Record(file:File, title:String)
		{
			_file = file;
			_title = title;
		}

		public function getCreationDate():Date
		{
			return _file.creationDate;
		}
		
		public function get file():File
		{
			return _file;
		}

		public function get title():String
		{
			return _title;
		}

		public function set title(value:String):void
		{
			_title = value;
		}
	}
}