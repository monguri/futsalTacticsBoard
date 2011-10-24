package models
{
	public class Const
	{
		public static const FIELD_PLAYER_BLUE1_TEXT:String = "9 Ronald";
		public static const FIELD_PLAYER_BLUE2_TEXT:String = "10 Zidane";
		public static const FIELD_PLAYER_BLUE3_TEXT:String = "7 Rivaldo";
		public static const FIELD_PLAYER_BLUE4_TEXT:String = "4 Lucio";
		
		public static const FIELD_PLAYER_RED1_TEXT:String = "18 本田";
		public static const FIELD_PLAYER_RED2_TEXT:String = "10 香川";
		public static const FIELD_PLAYER_RED3_TEXT:String = "7 遠藤";
		public static const FIELD_PLAYER_RED4_TEXT:String = "4 吉田";
		
		public static const GOAL_KEEPER_BLUE_TEXT:String = "1 Reina";
		public static const GOAL_KEEPER_RED_TEXT:String = "1 川島";
		
		public static const RECORD_LIST_BUTTON_LABEL_LIST:String = "REC LIST";
		public static const RECORD_LIST_BUTTON_LABEL_STOP:String = "PLAY STOP";
		// TODO:play stopでなく、suspendとrestartにしたいが、複雑になるので今はやらない
		//public static const RECORD_LIST_BUTTON_LABEL_SUSPEND:String = "SUSPEND";
		//public static const RECORD_LIST_BUTTON_LABEL_RESTART:String = "RESTART";
		
		public static const RESET_BUTTON_LABEL:String = "RESET";
		
		public static const RECORD_BUTTON_LABEL_START:String = "RECORD";
		public static const RECORD_BUTTON_LABEL_SUSPEND:String = "REC END";
		
		// レコード名は拡張子含めて３２文字に収まるように26に
		public static const RECORD_NAME_MAX_CHARS:int = 26;
		public static const RECORD_COMMENT_MAX_CHARS:int = 256;
		
		public function Const()
		{
		}
	}
}