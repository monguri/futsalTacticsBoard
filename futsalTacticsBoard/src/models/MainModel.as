package models
{
	CONFIG::SAVE_TO_XML_FILE
	import flash.filesystem.File;
	CONFIG::SAVE_TO_XML_FILE
	import flash.filesystem.FileMode;
	CONFIG::SAVE_TO_XML_FILE
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	CONFIG::SAVE_TO_SHARED_OBJECT
	import flash.net.SharedObject;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;

	// シングルトン
	public class MainModel
	{
		private static var _instance:MainModel;
		
		/** 録画ファイル情報のリスト */		
		private var _recordList:RecordList;

		// 録画データバッファ。録画(書き込み)と再生(読み出し)の両方で記録領域とのI/Oをバッファする。
		private var _piecesPoints:Vector.<Vector.<Point>>;
		private var _piecesTexts:Vector.<Vector.<String>>;
		private var _title:String;
		private var _comment:String;

		private static const NUM_PIECES:uint = 11;
		private static const RECORD_SAVE_DIRECTORY:String = "app-storage:/";

		public function MainModel(blocker:Blocker)
		{
			_recordList = new RecordList();
			
			var xmlFiles:Vector.<File> = getRecordFiles();
			for each (var xmlFile:File in xmlFiles)
			{
				var title:String = getXmlFileTitle(xmlFile);
				var comment:String = getXmlFileComment(xmlFile);
				_recordList.pushRecord(xmlFile, title, comment);
			}
		}
		
		public static function getInstance():MainModel
		{
			if (_instance == null)
			{
				_instance = new MainModel(new Blocker());
			}
			
			return _instance;
		}
		
		//
		// 録画データバッファ操作
		//
		
		public function clearSaveDataBuffer():void
		{
			_title = null;
			_comment = null;
			
			// 別のメモリ領域に再確保
			_piecesPoints = new Vector.<Vector.<Point>>();
			_piecesTexts = new Vector.<Vector.<String>>();
		
			// 二次元配列のnewだけでなく一次元配列をnewしておかないと要素をpushできない
			for (var i:uint = 0; i < NUM_PIECES; i++)
			{
				_piecesPoints[i] = new Vector.<Point>;
				_piecesTexts[i] = new Vector.<String>;
			}
		}
		
		public function flushSaveDataBuffer():void
		{
			// 無償版の場合は、一個だけしか保存させない
			// ShareObject版は複数件保存に対応してないので何もしない
			CONFIG::FREE{
				var dir:File = new File(RECORD_SAVE_DIRECTORY);
				var allFiles:Array = dir.getDirectoryListing();
				for each (var file:File in allFiles)
				{
					if (file.extension == "xml")
					{
						file.deleteFile();
					}
				}
				
				_recordList.removeAll();
			}
			
			CONFIG::SAVE_TO_SHARED_OBJECT{
				saveRecord();
			}
			CONFIG::SAVE_TO_XML_FILE{
				saveRecord();
			}

			// メモリ解放
			_piecesPoints = null;
			_piecesTexts = null;
		}

		public function loadSaveDataToBuffer(record:Record):Boolean
		{
			clearSaveDataBuffer();
			
			var success:Boolean;
			success = loadPiecesPoints(record);
			if (!success)
			{
				return false;
			}
			
			success = loadPiecesTexts(record);
			if (!success)
			{
				return false;
			}
			
			return true;
		}

		//
		// 録画データ操作
		//
		/**
		 * セーブする 
		 * @param recordName セーブデータにつける名前
		 * @param data 全コマの位置を入れた配列の配列
		 * @return 
		 */		
		CONFIG::SAVE_TO_SHARED_OBJECT
		private function saveRecord():void
		{
			var so:SharedObject = SharedObject.getLocal(getCurrentDateTimeString());
			// 一度メソッドの引数としてキャストしているから情報が消えるのかも。引数の型を*でやるとうまくいくかも
			so.data.piecesPoints = _piecesPoints;
			so.data.piecesTexts = _piecesTexts;
			try {
				so.flush();
			} catch(e:Error) {
				// do nothing
			}
		}

		CONFIG::SAVE_TO_XML_FILE
		private function saveRecord():void
		{
			//TODO:先頭の<xml>というのはださいかもしれない
			var xml:XML = <xml></xml>;
			var title:XML = <title>{_title}</title>;
			xml.appendChild(title);
			var comment:XML = <comment>{_comment}</comment>;
			xml.appendChild(comment);
			xml.appendChild(<pieces></pieces>);
			
			var piece:XML;
			var point:XML;
			for (var i:uint = 0; i < _piecesPoints.length; i++)
			{
				piece = <piece></piece>;
				piece.@id = i; //TODO:idにはballとかfieldPlayerBlueとか持たせたいな
				
				for (var j:uint = 0; j < _piecesPoints[i].length; j++)
				{
					point = <point/>;
					point.@x = _piecesPoints[i][j].x;
					point.@y = _piecesPoints[i][j].y;
					piece.appendChild(point);
				}
				
				xml.pieces.appendChild(piece);
			}
			
			var text:XML;
			for (i = 0; i < piecesTextsBuffer.length; i++)
			{
				for (j = 0; j < piecesTextsBuffer[i].length; j++)
				{
					text = <text>{piecesTextsBuffer[i][j]}</text>;
					xml.pieces.piece[i].appendChild(text);
				}
			}
			
			// 保存時は、現在日時をファイル名とする
			var file:File = new File(RECORD_SAVE_DIRECTORY + getCurrentDateTimeString() + ".xml");
			writeXmlStringToFile(file, xml.toXMLString());
			_recordList.pushRecord(file, _title, _comment);
		}
		
		private function getCurrentDateTimeString():String
		{
			var now:Date = new Date();
			// 協定世界時の1970/1/1 0:00:00からのミリ秒数でファイル名が一意に定まる
			return now.time.toString();
		}
		
		CONFIG::SAVE_TO_SHARED_OBJECT
		public function loadPiecesPoints(record:Record):Boolean
		{
			var soName:String = getRecordName(record);
			var so:SharedObject = SharedObject.getLocal(soName);
			if (!so.data.hasOwnProperty("piecesPoints"))
			{
				return false;
			}
			
			var saveData:Vector.<Object> = so.data.piecesPoints; // SharedObjectに入れるとVector.<Object>で保持される
			var point:Point;
			var len1:uint = saveData.length;
			var len2:uint = 0;
			for (var i:uint = 0; i < len1; i++)
			{
				len2 = saveData[i].length;
				for (var j:uint = 0; j < len2; j++)
				{
					// xとyのプロパティとその型の情報だけは残っている。Pointごととか、Vectorごと読み出そうとしてもキャストできないというエラーになる
					// 最終的な実値データのプロパティ名とその型の情報だけはObject型に残るということだろう
					point = new Point(saveData[i][j].x, saveData[i][j].y);
					_piecesPoints[i].push(point);
				}
			}

			return true;
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function loadPiecesPoints(record:Record):Boolean
		{
			var file:File = record.file;
			if (!file.exists)
			{
				return false;
			}
			
			var xml:XML = new XML(readXmlStringFromFile(file));
			var pieces:XMLList = xml.pieces.piece;
			var len1:int = pieces.length();
			var len2:int = 0;
			var points:XMLList;
			var point:Point;
			for (var i:uint = 0; i < len1; i++)
			{
				points = pieces[i].point;
				len2 = points.length();
				for (var j:uint = 0; j < len2; j++)
				{
					point = new Point(points[j].@x, points[j].@y);
					_piecesPoints[i].push(point);
				}
			}
			
			return true;
		}

		CONFIG::SAVE_TO_SHARED_OBJECT
		public function loadPiecesTexts(record:Record):Boolean
		{
			var soName:String = getRecordName(record);
			var so:SharedObject = SharedObject.getLocal(soName);
			if (!so.data.hasOwnProperty("piecesTexts"))
			{
				return false;
			}
			
			var saveData:Vector.<Object> = so.data.piecesTexts; // SharedObjectに入れるとVector.<Object>で保持される
			var point:Point;
			var len1:uint = saveData.length;
			var len2:uint = 0;
			for (var i:uint = 0; i < len1; i++)
			{
				len2 = saveData[i].length;
				for (var j:uint = 0; j < len2; j++)
				{
					_piecesTexts[i].push(saveData[i][j]);
				}
			}
		
			return true;
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function loadPiecesTexts(record:Record):Boolean
		{
			var file:File = record.file;
			if (!file.exists)
			{
				return false;
			}
			
			var xml:XML = new XML(readXmlStringFromFile(file));
			var pieces:XMLList = xml.pieces.piece;
			var len1:int = pieces.length();
			var len2:int = 0;
			var texts:XMLList;
			for (var i:uint = 0; i < len1; i++)
			{
				texts = pieces[i].text;
				len2 = texts.length();
				for (var j:uint = 0; j < len2; j++)
				{
					_piecesTexts[i].push(texts[j]);
				}
			}
			
			return true;
		}

		CONFIG::SAVE_TO_SHARED_OBJECT
		public function deleteRecord(record:Record):void
		{
			var so:SharedObject = SharedObject.getLocal(record.title);
			so.clear();
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function deleteRecord(record:Record):void
		{
			if (record.file.exists)
			{
				record.file.deleteFile();
			}
			
			_recordList.remove(record);
		}
		
		// TODO:SO版はリストが取得できない。何を保存しているかは別に保存が必要。それ自身をsoにする必要がある。それが欠点。今のところSO版は凍結
		// 保存方法として、so.data下にArray持たせて、各要素にレコード名にあたるものを持たせるしかない
		CONFIG::SAVE_TO_XML_FILE
		public function getRecordList(searchKeyword:String = null):IList
		{
			return _recordList.dataProviderList(searchKeyword);
		}
		
		CONFIG::SAVE_TO_XML_FILE
		private function getRecordFiles():Vector.<File>
		{
			// レコードが増えているかもしれないので画面表示のたびにリストを初期化する
			var dir:File = new File(RECORD_SAVE_DIRECTORY);
			var allFiles:Array = dir.getDirectoryListing();
			var xmlFiles:Vector.<File> = new Vector.<File>();
			for each (var file:File in allFiles)
			{
				if (file.extension == "xml")
				{
					xmlFiles.push(file);
				}
			}
			
			return xmlFiles;
		}
		
		CONFIG::SAVE_TO_SHARED_OBJECT
		private function getRecordName(record:Record):String
		{
			var file:File = record.file;
			// -1 は"."の分
			var endIndex:int = file.name.lastIndexOf(file.extension) - 1;
			return file.name.slice(0, endIndex);
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function getNumberRecords():uint
		{
			return _recordList.length();
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function getXmlFileTitle(xmlFile:File):String
		{
			var xml:XML = new XML(readXmlStringFromFile(xmlFile));
			return xml.title;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function getXmlFileComment(xmlFile:File):String
		{
			var xml:XML = new XML(readXmlStringFromFile(xmlFile));
			return xml.comment;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function setTitle(record:Record, title:String):void
		{
			var file:File = record.file;
			var xml:XML = new XML(readXmlStringFromFile(file));
			xml.title = title;
			writeXmlStringToFile(file, xml.toXMLString());
			
			record.title = title;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function setComment(record:Record, comment:String):void
		{
			var file:File = record.file;
			var xml:XML = new XML(readXmlStringFromFile(file));
			xml.comment = comment;
			writeXmlStringToFile(file, xml.toXMLString());
			
			record.comment = comment;
		}
		
		CONFIG::SAVE_TO_XML_FILE
		private function readXmlStringFromFile(file:File):String
		{
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
			var xmlStr:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			return xmlStr;
		}
		
		CONFIG::SAVE_TO_XML_FILE
		private function writeXmlStringToFile(file:File, xmlStr:String):void
		{
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(xmlStr);
			fs.close();
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function isValidText(text:String):Boolean
		{
			// 入力するたびの判定に使うので、文字列の最後尾から調べた方が速度が速い
			if (text.lastIndexOf('>') >= 0
				|| text.lastIndexOf('<') >= 0
				|| text.lastIndexOf('&') >= 0
				|| text.lastIndexOf('\'') >= 0
				|| text.lastIndexOf('\"') >= 0) // XMLの要素の内容の文字列が定義済み実体参照の文字を含むとき
			{
				return false;
			}
			
			return true;
		}
		
		//
		// ゲッター/セッター
		//
		public function get piecesPointsBuffer():Vector.<Vector.<Point>>
		{
			return _piecesPoints;
		}
		
		public function get piecesTextsBuffer():Vector.<Vector.<String>>
		{
			return _piecesTexts;
		}

		public function set titleBuffer(value:String):void
		{
			_title = value;
		}

		public function set commentBuffer(value:String):void
		{
			_comment = value;
		}
	}
}

internal class Blocker{}