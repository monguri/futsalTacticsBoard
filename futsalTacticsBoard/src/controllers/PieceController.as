package controllers
{
	import flash.events.MouseEvent;
	
	import mx.core.IMXMLObject;
	import mx.events.FlexEvent;
	
	import spark.core.ContentCache;
	
	import views.Piece;

	public class PieceController implements IMXMLObject
	{
		private var _view:Piece;
		private var _isDraging:Boolean = false;
		
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
		protected function creationCompleteHandler(event:FlexEvent):void
		{
			_view.image.addEventListener(MouseEvent.MOUSE_DOWN, imageMouseDownHandler);
			_view.image.addEventListener(MouseEvent.MOUSE_UP, imageMouseUpHandler);
		}
		
		private function imageMouseDownHandler(event:MouseEvent):void
		{
			// view全体を移動対象にする
			_view.startDrag();
			_isDraging = true;
		}
		
		private function imageMouseUpHandler(event:MouseEvent):void
		{
			// view全体を移動対象にする
			_view.stopDrag();
			_isDraging = false;
		}
		
		//
		// セッター/ゲッター
		//
		public function get isDraging():Boolean
		{
			return _isDraging;
		}
	}
}