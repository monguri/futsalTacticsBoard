package controllers
{
	import components.Dialog;
	import components.Piece;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.SoftKeyboardEvent;
	import flash.geom.Point;
	
	import models.Const;
	import models.FrameDatum;
	import models.RecordInfoModel;
	import models.RecordModel;
	
	import mx.core.IMXMLObject;
	import mx.events.FlexEvent;
	
	import spark.components.TextInput;
	import spark.components.supportClasses.ViewReturnObject;
	import spark.core.ContentCache;
	import spark.core.IContentLoader;
	import spark.transitions.SlideViewTransition;
	import spark.transitions.SlideViewTransitionMode;
	import spark.transitions.ViewTransitionDirection;
	
	import views.AddRecordView;
	import views.BoardView;
	
	public class BoardController implements IMXMLObject
	{
		private var _view:BoardView;
		
		private static const MODE_RECORD:uint = 0; // 録画モード
		private static const MODE_PLAY:uint = 1; // 再生モード
		private var _mode:uint = MODE_RECORD;
		
		// 状態フラグ
		private var _isRecording:Boolean = false;
		private var _isPlaying:Boolean = false;
		
		private var _pieces:Vector.<Piece>;
		
		// 録画中のフレーム数
		private var _recordFrame:uint = 0;
		
		// 再生中のフレーム数
		private var _playFrame:uint = 0;

		public function BoardController()
		{
		}
		
		public function initialized(document:Object, id:String):void
		{
			trace("initialized");
			_view = document as BoardView;
			_view.addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
			_view.addEventListener(FlexEvent.ADD, addHandler);
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
			_view.ball.x = Const.BALL_X - _view.ball.width / 2;
			_view.ball.y = Const.BALL_Y - _view.ball.height / 2;
		
			_view.playerBlue1.x = Const.PLAYER_BLUE1_X - _view.playerBlue1.width / 2;
			_view.playerBlue1.y = Const.PLAYER_BLUE1_Y - _view.playerBlue1.height / 2;
			_view.playerBlue2.x = Const.PLAYER_BLUE2_X - _view.playerBlue2.width / 2;
			_view.playerBlue2.y = Const.PLAYER_BLUE2_Y - _view.playerBlue2.height / 2;
			_view.playerBlue3.x = Const.PLAYER_BLUE3_X - _view.playerBlue3.width / 2;
			_view.playerBlue3.y = Const.PLAYER_BLUE3_Y - _view.playerBlue3.height / 2;
			_view.playerBlue4.x = Const.PLAYER_BLUE4_X - _view.playerBlue4.width / 2;
			_view.playerBlue4.y = Const.PLAYER_BLUE4_Y - _view.playerBlue4.height / 2;
			_view.playerBlue5.x = Const.PLAYER_BLUE5_X - _view.playerBlue5.width / 2;
			_view.playerBlue5.y = Const.PLAYER_BLUE5_Y - _view.playerBlue5.height / 2;
		
			_view.playerRed1.x = Const.PLAYER_RED1_X - _view.playerBlue1.width / 2;
			_view.playerRed1.y = Const.PLAYER_RED1_Y - _view.playerBlue1.height / 2;
			_view.playerRed2.x = Const.PLAYER_RED2_X - _view.playerBlue2.width / 2;
			_view.playerRed2.y = Const.PLAYER_RED2_Y - _view.playerBlue2.height / 2;
			_view.playerRed3.x = Const.PLAYER_RED3_X - _view.playerBlue3.width / 2;
			_view.playerRed3.y = Const.PLAYER_RED3_Y - _view.playerBlue3.height / 2;
			_view.playerRed4.x = Const.PLAYER_RED4_X - _view.playerBlue4.width / 2;
			_view.playerRed4.y = Const.PLAYER_RED4_Y - _view.playerBlue4.height / 2;
			_view.playerRed5.x = Const.PLAYER_RED5_X - _view.playerBlue5.width / 2;
			_view.playerRed5.y = Const.PLAYER_RED5_Y - _view.playerBlue5.height / 2;
		
			_view.playerBlue1.text = Const.PLAYER_BLUE1_TEXT;
			_view.playerBlue2.text = Const.PLAYER_BLUE2_TEXT;
			_view.playerBlue3.text = Const.PLAYER_BLUE3_TEXT;
			_view.playerBlue4.text = Const.PLAYER_BLUE4_TEXT;
			_view.playerBlue5.text = Const.PLAYER_BLUE5_TEXT;
			_view.playerRed1.text = Const.PLAYER_RED1_TEXT;
			_view.playerRed2.text = Const.PLAYER_RED2_TEXT;
			_view.playerRed3.text = Const.PLAYER_RED3_TEXT;
			_view.playerRed4.text = Const.PLAYER_RED4_TEXT;
			_view.playerRed5.text = Const.PLAYER_RED5_TEXT;
		}
		
		private function addHandler(event:Event):void
		{
			trace("add");
			// 描画されてから再生されるようにADDED_TO_STAGEイベントハンドラで再生開始
			var o:ViewReturnObject = _view.navigator.poppedViewReturnedObject;
			if (o != null)
			{ // AddRecordViewからのpop
				// Do nothing
				var saveFlag:Boolean = o.object as Boolean;
				if (saveFlag) // 保存するとき
				{
					RecordModel.getInstance().flushSaveDataBuffer(); // バッファのデータを記録領域に保存
				}
				RecordModel.getInstance().clearSaveDataBuffer(); // バッファをクリア
				
				_mode = MODE_RECORD;
				_view.recordPlayButton.label = Const.RECORD_BUTTON_LABEL_START;
			}
			else if (_view.data != null) // RecordViewのPlayボタンからのpush
			{
				var success:Boolean = RecordModel.getInstance().loadSaveDataToBuffer(_view.data as RecordInfoModel);
				// ロード失敗なら再生状態に遷移しない
				if (!success) {
					return;
				}
			
				// 再生中はボタンの機能は殺す
				_view.backButton.enabled = false;
				_view.resetButton.enabled = false;
				
				_mode = MODE_PLAY;
				_view.recordPlayButton.label = Const.PLAY_BUTTON_LABEL_SUSPEND;
				
				// 再生状態に
				_isPlaying = true;
			}
			else
			{ // RecordListViewからのpush
				_mode = MODE_RECORD;
				_view.recordPlayButton.label = Const.RECORD_BUTTON_LABEL_START;
			}
		}
		
		private function creationCompleteHandler(event:Event):void
		{
			trace("creation complete");
			_pieces = new Vector.<Piece>;
			_pieces.push(_view.ball);
			_pieces.push(_view.playerBlue1);
			_pieces.push(_view.playerBlue2);
			_pieces.push(_view.playerBlue3);
			_pieces.push(_view.playerBlue4);
			_pieces.push(_view.playerBlue5);
			_pieces.push(_view.playerRed1);
			_pieces.push(_view.playerRed2);
			_pieces.push(_view.playerRed3);
			_pieces.push(_view.playerRed4);
			_pieces.push(_view.playerRed5);
			
			// ContentCacheを使って画像描画の高速化
			var contentLoader:IContentLoader = new ContentCache();
			_view.courtImage.contentLoader = contentLoader;
			
			for each (var piece:Piece in _pieces)
			{
				piece.textInput.addEventListener(SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, pieceTextInputSoftKeyboardDeactivateHandler);
				piece.image.contentLoader = contentLoader;
				piece.controller.pieceTextChangeCallback = pieceTextChangeHandler;
			}

			// ボタンのマウスクリックイベント;
			_view.recordPlayButton.addEventListener(MouseEvent.CLICK, recordPlayButtonMouseClickHandler);
			_view.resetButton.addEventListener(MouseEvent.CLICK, resetButtonMouseClickHandler);
			_view.backButton.addEventListener(MouseEvent.CLICK, backButtonMouseClickHandler);
			
			//コマの位置、テキストを初期状態へ
			resetData();
		}
		
		/**
		 * コマのTextInputのTEXT_INPUTイベントハンドラ 
		 * @param event
		 * 
		 */
		private function pieceTextInputSoftKeyboardDeactivateHandler(event:SoftKeyboardEvent = null):void
		{
			if (_isRecording)
			{
				writeDataToSaveDataBuffer();
			}
		}
		
		private function pieceTextChangeHandler(pieceText:TextInput):void
		{
			switch (_mode)
			{
				case MODE_RECORD:
					var valid:Boolean = RecordModel.getInstance().isValidText(pieceText.text);
					_view.recordPlayButton.enabled = valid;
					if (!valid)
					{
						// TODO:このダイアログのOKボタンを押したら、ソフトキーボードが引っ込んで、jsonに使用不可文字が入らないか？?
						_view.invalidCharAlert.show(_view, Const.INVALID_CHARACTER_ERROR, "Invalid Char Alert", Dialog.BUTTON_OK);
					}
					break;
				case MODE_PLAY:
					// do nothing
					break;
				default:
					trace("Assert");
					break;
			}
		}
		
		/**
		 * ENTER_FRAMEイベントハンドラ
		 * @param event
		 * 
		 */
		private function enterFrameHandler(event:Event):void
		{
			switch (_mode)
			{
				case MODE_RECORD:
					// 録画中、ドラッグアンドドローをしているときに座標を毎フレーム保存する。テキスト入力はテキスト入力ハンドラで保存する。
					if (_isRecording && isAnyPieceDraging())
					{
						// TODO:座標をすべて保存するのでなくevent.targetのObjectと座標をPointを保存したい。テキストも保存するからそれとの分離がポイント
						recordEnterFrameHandler();
					}
					break;
				case MODE_PLAY:
					if (_isPlaying)
					{
						playEnterFrameHandler();
					}
					break;
				default:
					trace("Assert");
					break;
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
				var saveFrameLimit:Dialog = new Dialog();
				saveFrameLimit.show(_view, Const.RECORD_SIZE_FULL_MESSAGE, "Size Limit", Dialog.BUTTON_OK);
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
				recordPlayButtonMouseClickHandler();
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
//			if (RecordModel.getInstance().piecesPointsBuffer[0].length <= _playFrame)
			if (RecordModel.getInstance().recordBean.frameLength() <= _playFrame)
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
				recordPlayButtonMouseClickHandler();
			}
		}
		
		/* 録画ボタンのマウスクリックイベント */
		public function recordPlayButtonMouseClickHandler(event:MouseEvent = null):void
		{
			switch (_mode)
			{
				case MODE_RECORD:
					if (_isRecording)
					{
						var v:SlideViewTransition = new SlideViewTransition();
						v.mode = SlideViewTransitionMode.COVER;
						v.direction = ViewTransitionDirection.UP;
						_view.navigator.pushView(AddRecordView, null, null, v);
						
						_view.recordPlayButton.label = Const.RECORD_BUTTON_LABEL_START;
				
						// 録画終了したら他のボタン復活
						_view.backButton.enabled = true;
						_view.resetButton.enabled = true;
					}
					else
					{
						RecordModel.getInstance().clearSaveDataBuffer(); // バッファをクリア
						writeDataToSaveDataBuffer();// ボタンを押したときの初期状態を記録
						_view.recordPlayButton.label = Const.RECORD_BUTTON_LABEL_SUSPEND;
				
						// 録画中は他のボタンの機能は殺す
						_view.backButton.enabled = false;
						_view.resetButton.enabled = false;
					}
					
						
					// 録画フレーム数初期化
					_recordFrame = 0;
					// 録画状態ON/OFFトグル
					_isRecording = ! _isRecording;
					break;
				case MODE_PLAY:
					if (_isPlaying)
					{
						_view.recordPlayButton.label = Const.PLAY_BUTTON_LABEL_START;
						// 再生停止したら他のボタンを復活
						_view.backButton.enabled = true;
						_view.resetButton.enabled = true;
					}
					else
					{
						_view.recordPlayButton.label = Const.PLAY_BUTTON_LABEL_SUSPEND;
						// 再生中は他のボタンの機能は殺す
						_view.backButton.enabled = false;
						_view.resetButton.enabled = false;
					}
					
					// 再生状態/非再生状態　のトグル
					_isPlaying = ! _isPlaying;
					break;
				default:
					// do nothing
					trace("Assert");
					break;
			}
			
		}
		
		/* リセットボタンのマウスクリックイベント */
		public function resetButtonMouseClickHandler(event:MouseEvent):void
		{
			resetData();
		}
		
		/* バックボタンのマウスクリックイベント */
		public function backButtonMouseClickHandler(event:MouseEvent = null):void
		{
			var v:SlideViewTransition = new SlideViewTransition();
			v.mode = SlideViewTransitionMode.UNCOVER;
			v.direction = ViewTransitionDirection.DOWN;
			_view.navigator.popView(v);
		}
		
		private function writeDataToSaveDataBuffer():void
		{
			var i:uint = 0;
			var datum:FrameDatum;
			for each (var piece:Piece in _pieces)
			{
//				RecordModel.getInstance().piecesPointsBuffer[i].push(new Point(piece.x, piece.y));
//				RecordModel.getInstance().piecesTextsBuffer[i].push(piece.text);
				datum = new FrameDatum(piece.x, piece.y, piece.text);
				RecordModel.getInstance().recordBean.pushFrameDatum(i, datum);
				i++;
			}
		}
		
		private function readDataFromSaveData(frame:uint = 0):void
		{
			var i:uint = 0;
			for each (var piece:Piece in _pieces)
			{
//				piece.x = RecordModel.getInstance().piecesPointsBuffer[i][frame].x;
//				piece.y = RecordModel.getInstance().piecesPointsBuffer[i][frame].y;
//				piece.textInput.text = RecordModel.getInstance().piecesTextsBuffer[i][frame];
				piece.x = RecordModel.getInstance().recordBean.frameData[i][frame].x;
				piece.y = RecordModel.getInstance().recordBean.frameData[i][frame].y;
				piece.textInput.text = RecordModel.getInstance().recordBean.frameData[i][frame].text;
				i++;
			}
		}
	}
}