package controllers
{
	import components.Alert;
	import components.Piece;
	
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.SoftKeyboardEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	
	import models.Const;
	import models.MainModel;
	
	import mx.core.IMXMLObject;
	import mx.events.FlexEvent;
	
	import spark.components.supportClasses.ViewReturnObject;
	import spark.core.ContentCache;
	import spark.core.IContentLoader;
	import spark.transitions.SlideViewTransition;
	import spark.transitions.SlideViewTransitionMode;
	import spark.transitions.ViewTransitionDirection;
	
	import views.AddRecordView;
	import views.MainView;
	import views.RecordListView;
	
	public class MainController implements IMXMLObject
	{
		private var _view:MainView;
		
		// 状態フラグ
		private var _isRecording:Boolean = false;
		private var _isPlaying:Boolean = false;
		
		private var _pieces:Vector.<Piece>;
		
		// 録画中のフレーム数
		private var _recordFrame:uint = 0;
		
		// 再生中のフレーム数
		private var _playFrame:uint = 0;

		public function MainController()
		{
		}
		
		public function initialized(document:Object, id:String):void
		{
			trace("initialized");
			_view = document as MainView;
			_view.addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
			_view.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			_view.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}

		//
		// イベントハンドラ
		//
		/**
		 * 位置データリセット、セーブバッファクリア
		 * 
		 */
		private function resetData():void
		{
			_view.ball.x = 160 - _view.ball.width / 2;
			_view.ball.y = 230 - _view.ball.height / 2;
		
			_view.goalKeeperBlue.x = 160 - _view.goalKeeperBlue.width / 2;
			_view.goalKeeperBlue.y = 50 - _view.goalKeeperRed.height / 2;
		
			_view.fieldPlayerBlue1.x = 160 - _view.fieldPlayerBlue1.width / 2;
			_view.fieldPlayerBlue1.y = 180 - _view.fieldPlayerBlue1.height / 2;
			_view.fieldPlayerBlue2.x = 80 - _view.fieldPlayerBlue2.width / 2;
			_view.fieldPlayerBlue2.y = 140 - _view.fieldPlayerBlue2.height / 2;
			_view.fieldPlayerBlue3.x = 240 - _view.fieldPlayerBlue3.width / 2;
			_view.fieldPlayerBlue3.y = 140 - _view.fieldPlayerBlue3.height / 2;
			_view.fieldPlayerBlue4.x = 160 - _view.fieldPlayerBlue4.width / 2;
			_view.fieldPlayerBlue4.y = 100 - _view.fieldPlayerBlue4.height / 2;
		
			_view.goalKeeperRed.x = 160 - _view.goalKeeperBlue.width / 2;
			_view.goalKeeperRed.y = 400 - _view.goalKeeperRed.height / 2;
		
			_view.fieldPlayerRed1.x = 160 - _view.fieldPlayerBlue1.width / 2;
			_view.fieldPlayerRed1.y = 270 - _view.fieldPlayerBlue1.height / 2;
			_view.fieldPlayerRed2.x = 80 - _view.fieldPlayerBlue2.width / 2;
			_view.fieldPlayerRed2.y = 310 - _view.fieldPlayerBlue2.height / 2;
			_view.fieldPlayerRed3.x = 240 - _view.fieldPlayerBlue3.width / 2;
			_view.fieldPlayerRed3.y = 310 - _view.fieldPlayerBlue3.height / 2;
			_view.fieldPlayerRed4.x = 160 - _view.fieldPlayerBlue4.width / 2;
			_view.fieldPlayerRed4.y = 350 - _view.fieldPlayerBlue4.height / 2;
		
			_view.fieldPlayerBlue1.text = Const.FIELD_PLAYER_BLUE1_TEXT;
			_view.fieldPlayerBlue2.text = Const.FIELD_PLAYER_BLUE2_TEXT;
			_view.fieldPlayerBlue3.text = Const.FIELD_PLAYER_BLUE3_TEXT;
			_view.fieldPlayerBlue4.text = Const.FIELD_PLAYER_BLUE4_TEXT;
			_view.fieldPlayerRed1.text = Const.FIELD_PLAYER_RED1_TEXT;
			_view.fieldPlayerRed2.text = Const.FIELD_PLAYER_RED2_TEXT;
			_view.fieldPlayerRed3.text = Const.FIELD_PLAYER_RED3_TEXT;
			_view.fieldPlayerRed4.text = Const.FIELD_PLAYER_RED4_TEXT;
			_view.goalKeeperBlue.text = Const.GOAL_KEEPER_BLUE_TEXT;
			_view.goalKeeperRed.text = Const.GOAL_KEEPER_RED_TEXT;
		}
		
		public function addedToStageHandler(event:Event):void
		{
			trace("added to stage");
			// initializeイベントやcreationCompleteではタイミングが早くて_view.stageがnullになるのでaddedToStageイベントを使うのが確実
			_view.stage.quality = StageQuality.MEDIUM;
			_view.stage.frameRate = 24;
			
			// 描画されてから再生されるようにADDED_TO_STAGEイベントハンドラで再生開始
			var o:ViewReturnObject = _view.navigator.poppedViewReturnedObject;
			if (o == null) {
				return;
			}
			
			if (o.object is File) // RecordViewのPlayボタンからのpop
			{
				// 拡張子をのぞいたファイル名を取得する。1+ は"."を取り除くため
				var file:File = (o.object as File);
				var recordName:String = MainModel.getInstance().getRecordName(file);
			
				var success:Boolean = MainModel.getInstance().loadSaveDataToBuffer(recordName);
				// ロード失敗なら再生状態に遷移しない
				if (!success) {
					return;
				}
			
				_view.recordListButton.label = Const.RECORD_LIST_BUTTON_LABEL_STOP;
				
				// 再生中は他のボタンの機能は殺す
				_view.recordButton.enabled = false;
				_view.resetButton.enabled = false;
				
				// 再生状態/非再生状態　のトグル
				_isPlaying = ! _isPlaying;
			}
			else if (o.object is Boolean) // AddRecordViewからのpop
			{
				// Do nothing
				var saveFlag:Boolean = o.object as Boolean;
				if (saveFlag) // 保存するとき
				{
					MainModel.getInstance().flushSaveDataBuffer(); // バッファのデータを記録領域に保存
				}
				MainModel.getInstance().clearSaveDataBuffer(); // バッファをクリア
			}
		}
		
		public function creationCompleteHandler(event:Event):void
		{
			trace("creation complete");
			resetData();//初期状態へ
		
			_pieces = new Vector.<Piece>;
			_pieces.push(_view.ball);
			_pieces.push(_view.goalKeeperBlue);
			_pieces.push(_view.goalKeeperRed);	
			_pieces.push(_view.fieldPlayerBlue1);
			_pieces.push(_view.fieldPlayerBlue2);
			_pieces.push(_view.fieldPlayerBlue3);
			_pieces.push(_view.fieldPlayerBlue4);
			_pieces.push(_view.fieldPlayerRed1);
			_pieces.push(_view.fieldPlayerRed2);
			_pieces.push(_view.fieldPlayerRed3);
			_pieces.push(_view.fieldPlayerRed4);
			
			// ContentCacheを使って画像描画の高速化
			var contentLoader:IContentLoader = new ContentCache();
			_view.courtImage.contentLoader = contentLoader;
			
			for each (var piece:Piece in _pieces)
			{
				piece.textInput.addEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, pieceTextInputSoftKeyboardDeactivateHandler);
				piece.image.contentLoader = contentLoader;
			}

			// ボタンのラベル設定
			_view.recordButton.label = Const.RECORD_BUTTON_LABEL_START;
			_view.resetButton.label = Const.RESET_BUTTON_LABEL;
			_view.recordListButton.label = Const.RECORD_LIST_BUTTON_LABEL_LIST;
			
			// ボタンのマウスクリックイベント;
			_view.recordButton.addEventListener(MouseEvent.CLICK, recordButtonMouseClickHandler);
			_view.resetButton.addEventListener(MouseEvent.CLICK, resetButtonMouseClickHandler);
			_view.recordListButton.addEventListener(MouseEvent.CLICK, recordListButtonMouseClickHandler);
			
			// 無償版の場合は、アプリ起動時に制限事項のポップアップを出す
			CONFIG::FREE{
				var freeVerLimit:Alert = new Alert();
				freeVerLimit.show(_view, "At this free version, you can have just 1 record. 1000 records enable at \"futsal tactics board.\"", "Free Ver. Limitation");
			}
		}
		
		/**
		 * コマのTextInputのTEXT_INPUTイベントハンドラ 
		 * @param event
		 * 
		 */
		public function pieceTextInputSoftKeyboardDeactivateHandler(event:SoftKeyboardEvent = null):void
		{
			if (_isRecording)
			{
				writeDataToSaveDataBuffer();
			}
		}
		
		/**
		 * ENTER_FRAMEイベントハンドラ
		 * @param event
		 * 
		 */
		public function enterFrameHandler(event:Event):void
		{
			// 録画中、ドラッグアンドドローをしているときに座標を毎フレーム保存する。テキスト入力はテキスト入力ハンドラで保存する。
			if (_isRecording && isAnyPieceDraging())
			{
				// TODO:座標をすべて保存するのでなくevent.targetのObjectと座標をPointを保存したい。テキストも保存するからそれとの分離がポイント
				recordEnterFrameHandler();
			}
			else if (_isPlaying)
			{
				playEnterFrameHandler();
			}
		}
		
		private function isAnyPieceDraging():Boolean
		{
			for each (var piece:Piece in _pieces)
			{
				if (piece.controller.isDraging)
				{
					return true;
				}
			}
		
			return false;
		}
		
		private function recordEnterFrameHandler():void
		{
			if (_recordFrame >= Const.RECORD_FRAME_RATE_LIMIT) // 録画可能な容量をオーバーした
			{
				var saveFrameLimit:Alert = new Alert();
				saveFrameLimit.show(_view, "The size of record comes to limit.", "Size Limit");
				stopRecording();
				_recordFrame = 0;
				return;
			}
			
			writeDataToSaveDataBuffer();
			_recordFrame++;
		}
		
		private function stopRecording():void
		{
			if (_isRecording)
			{
				stopAllPieceDrag(); // ドラッグ中に録画停止された場合に各pieceのドラッグ状態をoffにする必要がある
				recordButtonMouseClickHandler();
			}
		}
		
		private function stopAllPieceDrag():void
		{
			for each (var piece:Piece in _pieces)
			{
				piece.controller.stopDrag();
			}
		}
		
		private function playEnterFrameHandler():void
		{
			// 録画したデータをすべて再生で吐き出した(毎フレームすべての配列にデータを入れるので一つだけ長さをチェックすればよい)
			if (MainModel.getInstance().piecesPointsBuffer[0].length <= _playFrame)
			{
				stopPlaying();
				// 次回再生は０フレーム目から
				_playFrame = 0;
				return;
			}
			
			// 録画データ配列から取り出してそこに移動する
			readDataFromSaveData(_playFrame);
			_playFrame++;
		}
		
		private function stopPlaying():void
		{
			if (_isPlaying)
			{
				recordListButtonMouseClickHandler();
			}
		}
		
		/* 録画ボタンのマウスクリックイベント */
		public function recordButtonMouseClickHandler(event:MouseEvent = null):void
		{
			if (_isRecording)
			{
				var v:SlideViewTransition = new SlideViewTransition();
				v.mode = SlideViewTransitionMode.COVER;
				v.direction = ViewTransitionDirection.UP;
				_view.navigator.pushView(AddRecordView, null, null, v);
				// TODO:Cancelボタンを押したときは保存しない。それと、こちらから遷移したときはタイトルはAddRecord。.
				
				_view.recordButton.label = Const.RECORD_BUTTON_LABEL_START;
		
				// 録画終了したら他のボタン復活
				_view.resetButton.enabled = true;
				_view.recordListButton.enabled = true;
			}
			else
			{
				MainModel.getInstance().clearSaveDataBuffer(); // バッファをクリア
				writeDataToSaveDataBuffer();// ボタンを押したときの初期状態を記録
				_view.recordButton.label = Const.RECORD_BUTTON_LABEL_SUSPEND;
		
				// 録画中は他のボタンの機能は殺す
				_view.resetButton.enabled = false;
				_view.recordListButton.enabled = false;
			}
			
				
			// 録画フレーム数初期化
			_recordFrame = 0;
			// 録画状態ON/OFFトグル
			_isRecording = ! _isRecording;
		}
		
		/* リセットボタンのマウスクリックイベント */
		public function resetButtonMouseClickHandler(event:MouseEvent):void
		{
			resetData();
		}
		
		/* 再生ボタンのマウスクリックイベント */
		public function recordListButtonMouseClickHandler(event:MouseEvent = null):void
		{
			if (_isPlaying)
			{
				_view.recordListButton.label = Const.RECORD_LIST_BUTTON_LABEL_LIST;
				
				// 再生停止したら他のボタンを復活
				_view.recordButton.enabled = true;
				_view.resetButton.enabled = true;
				
				// 再生中フレーム数は初期化 TODO:録画リストボタンと再生/再生中断ボタンを分けたらここで0にしちゃうと途中から再生ができない
				_playFrame = 0;
				
				// 再生状態/非再生状態　のトグル
				_isPlaying = ! _isPlaying;
			}
			else
			{
				_view.navigator.pushView(RecordListView);
			}
		}
		
		private function writeDataToSaveDataBuffer():void
		{
			var i:uint = 0;
			for each (var piece:Piece in _pieces)
			{
				MainModel.getInstance().piecesPointsBuffer[i].push(new Point(piece.x, piece.y));
				MainModel.getInstance().piecesTextsBuffer[i].push(piece.text);
				i++;
			}
		}
		
		private function readDataFromSaveData(frame:uint = 0):void
		{
			var i:uint = 0;
			for each (var piece:Piece in _pieces)
			{
				piece.x = MainModel.getInstance().piecesPointsBuffer[i][frame].x;
				piece.y = MainModel.getInstance().piecesPointsBuffer[i][frame].y;
				piece.textInput.text = MainModel.getInstance().piecesTextsBuffer[i][frame];
				i++;
			}
		}
	}
}