package models
{
	import flash.filesystem.File;

	//TODO;Recordの中にXMLやFileみたいな都合は隠蔽したいな
	public class Record
	{
		private var _file:File;
		private var _title:String;
		private var _comment:String;
		
		public function Record(file:File, title:String, comment:String)
		{
			_file = file;
			_title = title;
			_comment = comment;
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

		public function get comment():String
		{
			return _comment;
		}

		public function set comment(value:String):void
		{
			_comment = value;
		}
	}
}