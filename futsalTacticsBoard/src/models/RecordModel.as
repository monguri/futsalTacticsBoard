package models
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	
	CONFIG::SAVE_TO_SHARED_OBJECT
	import flash.net.SharedObject;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.SecurityErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.errors.IOError;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLLoaderDataFormat;
	import flash.system.System;

	// シングルトン
	public class RecordModel
	{
		private static var _instance:RecordModel;
		
		/** 録画ファイル情報のリスト */		
		private var _recordList:RecordInfoModelList;

		// 録画データバッファ。録画(書き込み)と再生(読み出し)の両方で記録領域とのI/Oをバッファする。
		private var _bean:RecordBean;
		private var _urlLoadCompleteCallback:Function;
		private var _urlLoadErrorCallback:Function;
		private var _loader:URLLoader;

		private static const RECORD_SAVE_DIRECTORY:String = "app-storage:/";

		public function RecordModel(blocker:Blocker)
		{
			_recordList = new RecordInfoModelList();
			
			var files:Vector.<File> = getRecordFiles();
			for each (var file:File in files)
			{
				// TODO:不正なJSONファイルが一個できるとアプリが起動できなくなるので対処
				var title:String = getFileTitle(file);
				var comment:String = getFileComment(file);
				_recordList.pushRecord(file, title, comment);
			}
		}
		
		public static function getInstance():RecordModel
		{
			if (_instance == null)
			{
				_instance = new RecordModel(new Blocker());
			}
			
			return _instance;
		}
		
		//
		// 録画データバッファ操作
		//
		
		public function clearSaveDataBuffer():void
		{
			_bean = null;
			_bean = new RecordBean();
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
					CONFIG::SAVE_TO_XML_FILE{
						if (file.extension == "xml")
						{
							file.deleteFile();
						}
					}
	
					CONFIG::SAVE_TO_JSON_FILE{
						if (file.extension == "json")
						{
							file.deleteFile();
						}
					}
				}
				
				_recordList.removeAll();
			}
			
			saveRecord();
		}

		public function loadSaveDataToBuffer(record:RecordInfoModel):Boolean
		{
			clearSaveDataBuffer();
			
			var success:Boolean;
			success = loadFrameData(record);
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
			// TODO:titleにスペースとかが入っていてもうまういくか不明
			var so:SharedObject = SharedObject.getLocal(_bean.title);
			// 一度メソッドの引数としてキャストしているから情報が消えるのかも。引数の型を*でやるとうまくいくかも
//			so.data.piecesPoints = _piecesPoints;
//			so.data.piecesTexts = _piecesTexts;
			so.data.recordBean = _bean;
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
			var title:XML = <title>{_bean.title}</title>;
			xml.appendChild(title);
			var comment:XML = <comment>{_bean.comment}</comment>;
			xml.appendChild(comment);
			xml.appendChild(<pieces></pieces>);
			
			var piece:XML;
			var frame:XML;
			for (var i:uint = 0; i < _bean.frameData.length; i++)
			{
				piece = <piece></piece>;
				piece.@id = i; //TODO:idにはballとかfieldPlayerBlueとか持たせたいな
				
				for (var j:uint = 0; j < _bean.frameData[i].length; j++)
				{
					frame = <frame/>;
					frame.@x = _bean.frameData[i][j].x;
					frame.@y = _bean.frameData[i][j].y;
					frame.@text = _bean.frameData[i][j].text;
					piece.appendChild(frame);
				}
				
				xml.pieces.appendChild(piece);
			}
			
			// 保存時は、現在日時をファイル名とする
			var file:File = new File(RECORD_SAVE_DIRECTORY + getCurrentDateTimeString() + ".xml");
			writeStringToFile(file, xml.toXMLString());
			_recordList.pushRecord(file, _bean.title, _bean.comment);
		}
		
		CONFIG::SAVE_TO_JSON_FILE
		private function saveRecord():void
		{
			var jsonStr:String = JSON.stringify(_bean, null, 4);
			var file:File = new File(RECORD_SAVE_DIRECTORY + getCurrentDateTimeString() + ".json");
			trace(jsonStr);
			writeStringToFile(file, jsonStr);
			_recordList.pushRecord(file, _bean.title, _bean.comment);
		}
		
		private function getCurrentDateTimeString():String
		{
			var now:Date = new Date();
			// 協定世界時の1970/1/1 0:00:00からのミリ秒数でファイル名が一意に定まる
			// TODO:しかしファイル共有を考えるなら端末IDの付加が必要
			return now.time.toString();
		}

		CONFIG::SAVE_TO_SHARED_OBJECT
		public function loadFrameData(record:RecordInfoModel):Boolean
		{
			var so:SharedObject = SharedObject.getLocal(record.title);
			if (!so.data.hasOwnProperty("frameData"))
			{
				return false;
			}
			
			var saveData:Vector.<Object> = so.data.frameData; // SharedObjectに入れるとVector.<Object>で保持される
			var datum:FrameDatum;
			var len1:uint = saveData.length;
			var len2:uint = 0;
			for (var i:uint = 0; i < len1; i++)
			{
				len2 = saveData[i].length;
				for (var j:uint = 0; j < len2; j++)
				{
					// xとyのプロパティとその型の情報だけは残っている。Pointごととか、Vectorごと読み出そうとしてもキャストできないというエラーになる
					// 最終的な実値データのプロパティ名とその型の情報だけはObject型に残るということだろう
					datum = new FrameDatum(saveData[i][j].x, saveData[i][j].y, saveData[i][j].text);
					_bean.pushFrameDatum(i, datum);
				}
			}

			return true;
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function loadFrameData(record:RecordInfoModel):Boolean
		{
			var file:File = record.file;
			if (!file.exists)
			{
				return false;
			}
			
			var xml:XML = new XML(readStringFromFile(file));
			var pieces:XMLList = xml.pieces.piece;
			var len1:int = pieces.length();
			var len2:int = 0;
			var frames:XMLList;
			var datum:FrameDatum;
			for (var i:uint = 0; i < len1; i++)
			{
				frames = pieces[i].frame;
				len2 = frames.length();
				for (var j:uint = 0; j < len2; j++)
				{
					datum = new FrameDatum(frames[j].@x, frames[j].@y, frames[j].@text);
					_bean.pushFrameDatum(i, datum);
				}
			}
			
			return true;
		}

		CONFIG::SAVE_TO_JSON_FILE
		public function loadFrameData(record:RecordInfoModel):Boolean
		{
			var file:File = record.file;
			if (!file.exists)
			{
				return false;
			}
			
			// 配列の配列が入っているとSOと同じく直にキャストはできない
			var o:Object = JSON.parse(readStringFromFile(file));
			_bean.title = o.title;
			_bean.comment = o.comment;
			
			// stringify時はVectorでも解釈されるが、parseするとArrayでしか扱えない
			var frameData:Array = o.frameData;
			var datum:FrameDatum;
			var len1:uint = frameData.length;
			var len2:uint = 0;
			for (var i:uint = 0; i < len1; i++)
			{
				len2 = frameData[i].length;
				for (var j:uint = 0; j < len2; j++)
				{
					// xとyのプロパティとその型の情報だけは残っている。Pointごととか、Vectorごと読み出そうとしてもキャストできないというエラーになる
					// 最終的な実値データのプロパティ名とその型の情報だけはObject型に残るということだろう
					datum = new FrameDatum(frameData[i][j].x, frameData[i][j].y, frameData[i][j].text);
					_bean.pushFrameDatum(i, datum);
				}
			}
			return true;
		}
		
		CONFIG::SAVE_TO_SHARED_OBJECT
		public function deleteRecord(record:RecordInfoModel):void
		{
			var so:SharedObject = SharedObject.getLocal(record.title);
			so.clear();
		}
		
		CONFIG::SAVE_TO_XML_FILE
		public function deleteRecord(record:RecordInfoModel):void
		{
			if (record.file.exists)
			{
				record.file.deleteFile();
			}
			
			_recordList.remove(record);
		}
		
		CONFIG::SAVE_TO_JSON_FILE
		public function deleteRecord(record:RecordInfoModel):void
		{
			if (record.file.exists)
			{
				record.file.deleteFile();
			}
			
			_recordList.remove(record);
		}
		
		
		CONFIG::SAVE_TO_XML_FILE
		public function uploadRecord(record:RecordInfoModel):void
		{
			if (record.file.exists)
			{
				record.file.deleteFile();
			}
		}
		
		// TODO:SO版を用意していない
		public function uploadRecord(record:RecordInfoModel, urlLoadCompleteCallback:Function, urlLoadErrorCallback:Function):void
		{
			var file:File = record.file;
			if (file.exists)
			{
				_urlLoadCompleteCallback = urlLoadCompleteCallback;
				_urlLoadErrorCallback = urlLoadErrorCallback;
				
				// リクエストを作成する POSTでファイルの文字列をHTTPヘッダに含めて送信する
				var request:URLRequest = new URLRequest(Const.UPLOAD_URL);
				request.method = URLRequestMethod.POST;
				var urlVar:URLVariables = new URLVariables();
				urlVar.title = record.title;
				urlVar.comment = record.comment;
				urlVar.data = readStringFromFile(file);
				request.data = urlVar;
				var loader:URLLoader = new URLLoader();
				
				// イベントリスナー設定
				loader.addEventListener(Event.COMPLETE, uploadCompleteHandler);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoadHTTPStatusHandler);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoadErrorHandler);
				loader.addEventListener(IOErrorEvent.IO_ERROR, urlLoadErrorHandler);
				
				// 送信
				_loader = loader;
				loader.load(request);
			}
		}
		
		// TODO:SO版を用意していない
		public function downloadRecord(url:String, urlLoadCompleteCallback:Function, urlLoadErrorCallback:Function):void
		{
			_urlLoadCompleteCallback = urlLoadCompleteCallback;
			_urlLoadErrorCallback = urlLoadErrorCallback;
			
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.GET;
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
//			System.useCodePage = true;
			
			// イベントリスナー設定
			loader.addEventListener(Event.COMPLETE, downloadCompleteHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoadHTTPStatusHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoadErrorHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, urlLoadErrorHandler);
			
			// 送信
			_loader = loader;
			loader.load(request);
		}
		
		private function uploadCompleteHandler(event:Event):void
		{
			_loader.removeEventListener(Event.COMPLETE, uploadCompleteHandler);
			_loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoadHTTPStatusHandler);
			_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoadErrorHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoadErrorHandler);
			_loader = null;
			_urlLoadCompleteCallback();
		}
		
		private function downloadCompleteHandler(event:Event):void
		{
			var recordData:String = _loader.data as String;
			var file:File = new File(RECORD_SAVE_DIRECTORY + getCurrentDateTimeString() + ".json");
			writeStringToFile(file, recordData);
			var o:Object = JSON.parse(recordData);
			_recordList.pushRecord(file, o.title, o.comment);
			
			_loader.removeEventListener(Event.COMPLETE, uploadCompleteHandler);
			_loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoadHTTPStatusHandler);
			_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoadErrorHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoadErrorHandler);
			_loader = null;
			_urlLoadCompleteCallback();
		}
		
		private function urlLoadHTTPStatusHandler(event:HTTPStatusEvent):void
		{
			// この後にcompleteイベントがくるので、ステータスコードが成功のときは得に何もしない
			if (event.status >= 300)
			{
				urlLoadErrorHandler(event);
			}
		}
		
		private function urlLoadErrorHandler(event:Event):void
		{
			_loader.removeEventListener(Event.COMPLETE, uploadCompleteHandler);
			_loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoadHTTPStatusHandler);
			_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoadErrorHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoadErrorHandler);
			_loader = null;
			_urlLoadErrorCallback();
		}
		
		// TODO:SO版はリストが取得できない。何を保存しているかは別に保存が必要。それ自身をsoにする必要がある。それが欠点。今のところSO版は凍結
		// 保存方法として、so.data下にArray持たせて、各要素にレコード名にあたるものを持たせるしかない
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
		
		CONFIG::SAVE_TO_JSON_FILE
		private function getRecordFiles():Vector.<File>
		{
			// レコードが増えているかもしれないので画面表示のたびにリストを初期化する
			var dir:File = new File(RECORD_SAVE_DIRECTORY);
			var allFiles:Array = dir.getDirectoryListing();
			var jsonFiles:Vector.<File> = new Vector.<File>();
			for each (var file:File in allFiles)
			{
				if (file.extension == "json")
				{
					jsonFiles.push(file);
				}
			}
			
			return jsonFiles;
		}
		
		CONFIG::SAVE_TO_SHARED_OBJECT
		private function getRecordName(record:RecordInfoModel):String
		{
			var file:File = record.file;
			// -1 は"."の分
			var endIndex:int = file.name.lastIndexOf(file.extension) - 1;
			return file.name.slice(0, endIndex);
		}
		
		// TODO:SO版を用意していない
		public function getNumberRecords():uint
		{
			return _recordList.length();
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function getFileTitle(file:File):String
		{
			var xml:XML = new XML(readStringFromFile(file));
			return xml.title;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_JSON_FILE
		public function getFileTitle(file:File):String
		{
			// RecordBeanにはキャストできない
			var bean:Object = JSON.parse(readStringFromFile(file));
			return bean.title;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function getFileComment(file:File):String
		{
			var xml:XML = new XML(readStringFromFile(file));
			return xml.comment;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_JSON_FILE
		public function getFileComment(file:File):String
		{
			var bean:Object = JSON.parse(readStringFromFile(file));
			return bean.comment;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function setTitle(record:RecordInfoModel, title:String):void
		{
			var file:File = record.file;
			var xml:XML = new XML(readStringFromFile(file));
			xml.title = title;
			writeStringToFile(file, xml.toXMLString());
			
			record.title = title;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_JSON_FILE
		public function setTitle(record:RecordInfoModel, title:String):void
		{
			// RecordBeanにはキャストできない
			var file:File = record.file;
			var bean:Object = JSON.parse(readStringFromFile(file));
			bean.title = title;
			var jsonStr:String = JSON.stringify(bean, null, 4);
			writeStringToFile(file, jsonStr);
			
			record.title = title;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_XML_FILE
		public function setComment(record:RecordInfoModel, comment:String):void
		{
			var file:File = record.file;
			var xml:XML = new XML(readStringFromFile(file));
			xml.comment = comment;
			writeStringToFile(file, xml.toXMLString());
			
			record.comment = comment;
		}
		
		// TODO:SO版を用意していない
		CONFIG::SAVE_TO_JSON_FILE
		public function setComment(record:RecordInfoModel, comment:String):void
		{
			// RecordBeanにはキャストできない
			var file:File = record.file;
			var bean:Object = JSON.parse(readStringFromFile(file));
			bean.comment = comment;
			var jsonStr:String = JSON.stringify(bean, null, 4);
			writeStringToFile(file, jsonStr);
			
			record.comment = comment;
		}
		
		private function readStringFromFile(file:File):String
		{
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
			var str:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			return str;
		}
		
		private function writeStringToFile(file:File, str:String):void
		{
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(str);
			fs.close();
		}
		
		// 要素の中身、属性、Jsonでエスケープすべき文字は同じに扱う
		public function isValidText(text:String):Boolean
		{
			// 文字を入力するたびに判定するので、文字列の最後尾から調べた方が速度が速いと思われる
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
		
		public function get recordBean():RecordBean
		{
			return _bean;
		}
	}
}

internal class Blocker{}