package controllers
{
	import components.Piece;
	
	import flash.events.MouseEvent;
	
	import mx.core.IMXMLObject;
	import mx.events.FlexEvent;
	
	import spark.core.ContentCache;
	import spark.events.TextOperationEvent;

	public class PieceController implements IMXMLObject
	{
		private var _view:Piece;
		private var _isDraging:Boolean = false;
		private var _pieceTextChangeCallback:Function;
		
		public function PieceController()
		{
		}
		
		public function initialized(document:Object, id:String):void
		{
			_view = document as Piece;
			_view.addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
		}
		
		//
		// イベントハンドラ
		//
		private function creationCompleteHandler(event:FlexEvent):void
		{
			_view.image.addEventListener(MouseEvent.MOUSE_DOWN, imageMouseDownHandler);
			_view.image.addEventListener(MouseEvent.MOUSE_UP, imageMouseUpHandler);
			_view.textInput.addEventListener(TextOperationEvent.CHANGE, pieceTextChangeHandler);
		}
		
		private function pieceTextChangeHandler(event:TextOperationEvent):void
		{
			_pieceTextChangeCallback(event.currentTarget);	
		}
		
		private function imageMouseDownHandler(event:MouseEvent):void
		{
			// view全体を移動対象にする
			_view.startDrag();
			_isDraging = true;
		}
		
		private function imageMouseUpHandler(event:MouseEvent = null):void
		{
			// view全体を移動対象にする
			_view.stopDrag();
			_isDraging = false;
		}
		
		/**
		 * ドラッグ状態を終了させる 
		 * 
		 */		
		public function stopDrag():void
		{
			imageMouseUpHandler();
		}
		
		//
		// セッター/ゲッター
		//
		public function get isDraging():Boolean
		{
			return _isDraging;
		}

		public function set pieceTextChangeCallback(value:Function):void
		{
			_pieceTextChangeCallback = value;
		}
	}
}