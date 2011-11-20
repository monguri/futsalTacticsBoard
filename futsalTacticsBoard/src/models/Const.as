package models
{
	public class Const
	{
		//
		// コマの背番号
		//
		public static const PLAYER_BLUE1_TEXT:String = "1 Reina";
		public static const PLAYER_BLUE2_TEXT:String = "9 Ronald";
		public static const PLAYER_BLUE3_TEXT:String = "10 Zidane";
		public static const PLAYER_BLUE4_TEXT:String = "7 Rivaldo";
		public static const PLAYER_BLUE5_TEXT:String = "4 Lucio";
		
		public static const PLAYER_RED1_TEXT:String = "1 川島";
		public static const PLAYER_RED2_TEXT:String = "18 本田";
		public static const PLAYER_RED3_TEXT:String = "10 香川";
		public static const PLAYER_RED4_TEXT:String = "7 遠藤";
		public static const PLAYER_RED5_TEXT:String = "4 吉田";
		
		//
		// コマの初期位置
		//
		public static const BALL_X:int = 160;
		public static const BALL_Y:int = 230;
		
		public static const PLAYER_BLUE1_X:int = 160;
		public static const PLAYER_BLUE1_Y:int = 50;
		public static const PLAYER_BLUE2_X:int = 160;
		public static const PLAYER_BLUE2_Y:int = 180;
		public static const PLAYER_BLUE3_X:int = 80;
		public static const PLAYER_BLUE3_Y:int = 140;
		public static const PLAYER_BLUE4_X:int = 240;
		public static const PLAYER_BLUE4_Y:int = 140;
		public static const PLAYER_BLUE5_X:int = 160;
		public static const PLAYER_BLUE5_Y:int = 100;
		
		public static const PLAYER_RED1_X:int = 160;
		public static const PLAYER_RED1_Y:int = 400;
		public static const PLAYER_RED2_X:int = 160;
		public static const PLAYER_RED2_Y:int = 270;
		public static const PLAYER_RED3_X:int = 80;
		public static const PLAYER_RED3_Y:int = 310;
		public static const PLAYER_RED4_X:int = 240;
		public static const PLAYER_RED4_Y:int = 310;
		public static const PLAYER_RED5_X:int = 160;
		public static const PLAYER_RED5_Y:int = 350;
		
		//
		// ボタンのラベル
		//
		public static const RECORD_LIST_BUTTON_LABEL_LIST:String = "REC LIST";
		public static const RECORD_LIST_BUTTON_LABEL_STOP:String = "PLAY STOP";
		// TODO:play stopでなく、suspendとrestartにしたいが、複雑になるので今はやらない
		//public static const RECORD_LIST_BUTTON_LABEL_SUSPEND:String = "SUSPEND";
		//public static const RECORD_LIST_BUTTON_LABEL_RESTART:String = "RESTART";
		
		public static const RESET_BUTTON_LABEL:String = "RESET";
		
		public static const RECORD_BUTTON_LABEL_START:String = "RECORD";
		public static const RECORD_BUTTON_LABEL_SUSPEND:String = "REC END";
		
		//
		// 録画情報の文字数制限
		//
		public static const RECORD_TITLE_MAX_CHARS:int = 16;
		public static const RECORD_COMMENT_MAX_CHARS:int = 256;
		
		//
		// 録画容量の制限
		//
		/** 録画本数の制限 */		
		public static const RECORD_NUMBER_LIMIT:int = 1000;
		/** 録画フレーム数の制限 */		
		public static const RECORD_FRAME_RATE_LIMIT:int = 3 * 60 * 24;
		
		public function Const()
		{
		}
	}
}