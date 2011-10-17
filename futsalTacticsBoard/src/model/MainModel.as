package model
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
		private static var instance:MainModel;
		private var _recordList:ArrayCollection;

		// 録画データバッファ。録画(書き込み)と再生(読み出し)の両方で記録領域とのI/Oをバッファする。
		private var _piecesPoints:Vector.<Vector.<Point>>;
		private var _piecesTexts:Vector.<Vector.<String>>;

		private static const NUM_PIECES:uint = 11;
		private static const RECORD_SAVE_DIRECTORY:String = "app-storage:/";

		public function MainModel(blocker:Blocker)
		{
			// do nothing
		}
		
		public static function getInstance():MainModel
		{
			if (instance == null)
			{
				instance = new MainModel(new Blocker());
			}
			
			return instance;
		}
		
		//
		// 録画データバッファ操作
		//
		
		public function clearSaveDataBuffer():void
		{
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
			}
			
			MainModel.getInstance().saveRecord();

			// メモリ解放
			_piecesPoints = null;
			_piecesTexts = null;
		}

		public function loadSaveDataToBuffer(recordName:String):Boolean
		{
			MainModel.getInstance().clearSaveDataBuffer();
			
			var success:Boolean;
		
			success = MainModel.getInstance().loadPiecesPoints(recordName);
			if (!success)
			{
				return false;
			}
			
			success = MainModel.getInstance().loadPiecesTexts(recordName);
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
		public function saveRecord():void
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
		public function saveRecord():void
		{
			var xml:XML = <pieces></pieces>;
			var piece:XML;
			var point:XML;
			var text:XML;
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
				xml.appendChild(piece);
			}
			
			for (i = 0; i < piecesTextsBuffer.length; i++)
			{
				for (j = 0; j < piecesTextsBuffer[i].length; j++)
				{
					text = <text>{piecesTextsBuffer[i][j]}</text>;
					xml.piece[i].appendChild(text);
				}
			}
			trace(xml);
			
			// 保存時は、現在日時をファイル名とする
			var file:File = new File(RECORD_SAVE_DIRECTORY + getCurrentDateTimeString() + ".xml");
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(xml.toXMLString());
			fs.close();
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function renameRecord(file:File, newName:String):void
		{
			var dest:File = new File(RECORD_SAVE_DIRECTORY + newName + ".xml");
			// TODO:第２引数を上書きモードにしているので、既存のファイルがあると上書きになってしまう。例外も考慮してない。
			file.moveTo(dest, true);
		}

		CONFIG::SAVE_TO_SHARED_OBJECT
		public function loadPiecesPoints(recordName:String):Boolean
		{
			var so:SharedObject = SharedObject.getLocal(recordName);
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
		
		private function getCurrentDateTimeString():String
		{
			var now:Date = new Date();
			var year:Number = now.fullYear;
			var month:Number = now.month + 1;
			var date:Number = now.date;
			var hours:Number = now.hours;
			var minutes:Number = now.minutes;
			var seconds:Number = now.seconds;
			return (year.toString() + "-" + month.toString() + "-" + date.toString() + " " + hours.toString() + minutes.toString() + seconds.toString());
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function loadPiecesPoints(recordName:String):Boolean
		{
			var file:File = new File(RECORD_SAVE_DIRECTORY + recordName + ".xml");
			if (!file.exists)
			{
				return false;
			}
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
			var xmlStr:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			
			var xml:XML = new XML(xmlStr);
			var pieces:XMLList = xml.piece;
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
		public function loadPiecesTexts(recordName:String):Boolean
		{
			var so:SharedObject = SharedObject.getLocal(recordName);
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
		public function loadPiecesTexts(recordName:String):Boolean
		{
			var file:File = new File(RECORD_SAVE_DIRECTORY + recordName + ".xml");
			if (!file.exists)
			{
				return false;
			}
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
			var xmlStr:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			
			var xml:XML = new XML(xmlStr);
			var pieces:XMLList = xml.piece;
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
		public function deleteRecord(recordName:String):void
		{
			var so:SharedObject = SharedObject.getLocal(recordName);
			so.clear();
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function deleteRecord(recordName:String):void
		{
			var file:File = new File(RECORD_SAVE_DIRECTORY + recordName + ".xml");
			if (file.exists)
			{
				file.deleteFile();
			}
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

		// TODO:SO版では複数件保存したりリストとして参照したりできてない。
		// 保存方法として、so.data下にArray持たせて、各要素にレコード名にあたるものを持たせるしかない
		public function getRecordList():IList
		{
			// レコードが増えているかもしれないので画面表示のたびにリストを初期化する
			var dir:File = new File(RECORD_SAVE_DIRECTORY);
			var allFiles:Array = dir.getDirectoryListing();
			var xmlFiles:Array = new Array();
			for each (var file:File in allFiles)
			{
				if (file.extension == "xml")
				{
					xmlFiles.push(file);
				}
			}
			_recordList = new ArrayCollection(xmlFiles);
			return _recordList;
		}
		
		public function getRecordName(file:File):String
		{
			// -1 は"."の分
			var endIndex:int = file.name.lastIndexOf(file.extension) - 1;
			return file.name.slice(0, endIndex);
			
		}
	}
}

internal class Blocker{}