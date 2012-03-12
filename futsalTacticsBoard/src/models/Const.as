package models
{
	public class Const
	{
		//
		// コマの背番号
		//
		public static const PLAYER_BLUE1_TEXT:String = "1 Reine";
		public static const PLAYER_BLUE2_TEXT:String = "9 Ronold";
		public static const PLAYER_BLUE3_TEXT:String = "10 Zidene";
		public static const PLAYER_BLUE4_TEXT:String = "7 Rivald";
		public static const PLAYER_BLUE5_TEXT:String = "4 Lusio";
		
		public static const PLAYER_RED1_TEXT:String = "1 川嶋";
		public static const PLAYER_RED2_TEXT:String = "18 本多";
		public static const PLAYER_RED3_TEXT:String = "10 うどん";
		public static const PLAYER_RED4_TEXT:String = "7 えんどう";
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
		
		// コマの数
		public static const NUM_PIECES:int = 11;
		
		//
		// ボタンのラベル
		//
//		public static const RECORD_LIST_BUTTON_LABEL_LIST:String = "REC LIST";
//		public static const RECORD_LIST_BUTTON_LABEL_STOP:String = "PLAY STOP";
		// TODO:play stopでなく、suspendとrestartにしたいが、複雑になるので今はやらない
		//public static const RECORD_LIST_BUTTON_LABEL_SUSPEND:String = "SUSPEND";
		//public static const RECORD_LIST_BUTTON_LABEL_RESTART:String = "RESTART";
		
		public static const RECORD_BUTTON_LABEL_START:String = "RECORD";
		public static const RECORD_BUTTON_LABEL_SUSPEND:String = "STOP";
		public static const PLAY_BUTTON_LABEL_START:String = "PLAY";
		public static const PLAY_BUTTON_LABEL_SUSPEND:String = "STOP";
		
		public static const RESET_BUTTON_LABEL:String = "RESET";
		
		public static const BACK_BUTTON_LABEL:String = "BACK";
		
		//
		// アップロード、ダウンロード
		//
//		public static const SERVER_URL_BASE:String = "http://localhost:8888/futsalTacticsBoard";
		public static const SERVER_URL_BASE:String = "http://futsaltacticsboard.appspot.com/futsalTacticsBoard";
		public static const URL_PARAM_MODE:String = "mode=";
		public static const URL_VALUE_DOWNLOAD_START:String = "downloadstart";
		public static const URL_VALUE_DOWNLOAD:String = "download";
		public static const URL_VALUE_UPLOAD:String = "upload";
		public static const URL_PARAM_RECORD_ID:String = "recordid=";
		public static const DOWNLOAD_LIST_LABEL:String = "[DOWNLOAD FROM SERVER...]";

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
		
		//
		// ダイアログの文言
		//
		public static const FREE_LIMITATION_TITLE:String = "Free Ver. Limitation";
		public static const INVALID_CHARACTER_TITLE:String = "Invalid Char Alert";
		public static const RECORD_SIZE_FULL_TITLE:String = "Size Limit";
		public static const RECORDS_NUMBER_FULL_TITLE:String = "Limit Alert";
		public static const RECORDS_NUMBER_OVER_LIMIT_TITLE:String = "Save Failed";
		public static const UPLOAD_SUCCEDED_TITLE:String = "Upload Success";
		public static const UPLOAD_FAILED_TITLE:String = "Upload Failed";
		public static const DOWNLOAD_SUCCEDED_TITLE:String = "Download Success";
		public static const DOWNLOAD_FAILED_TITLE:String = "Download Failed";
		
		public static const INVALID_CHARACTER_ERROR:String = "Invalid character, cannot save: >, <, &, \' or \".";
		public static const RECORDS_NUMBER_FULL_WARNING:String = "The number of records comes to limit. You can delete some records.";
		public static const RECORDS_NUMBER_OVER_LIMIT_ERROR:String = "The number of records is over limit. Please delete some records.";
		public static const RECORD_SIZE_FULL_MESSAGE:String = "The size of record comes to limit.";
		public static const FREE_LIMITATION_MESSAGE:String = "At this free version, you can have just 1 record.\n 1000 records enable at \"futsal tactics board\".\n Check it!";
		public static const UPLOAD_SUCCEDED_MESSAGE:String = "Uploading record was succeeded.";
		public static const UPLOAD_FAILED_MESSAGE:String = "Sorry, uploading record was failed by an error.";
		public static const DOWNLOAD_SUCCEDED_MESSAGE:String = "Downloading record was succeeded.";
		public static const DOWNLOAD_FAILED_MESSAGE:String = "Sorry, downloading record was failed by an error.";
		
		public function Const()
		{
		}
	}
}