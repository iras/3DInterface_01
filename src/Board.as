/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package
{
	import flash.display.Sprite;
	/**
	 *	public board
	 *	@ purpose : holding the statics
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class Board extends Sprite
	{
		public static const sv:Number=1; // dist between eyes in pixels.
		public static const o:Number=350;  // adjustment (in pixels) for the left view
		public static const d:Number=o*0.81;
		
		public static const inactive_edge:int=0x00FF88;
		public static const   active_edge:int=0xFF2222;
		
		public static var st:Boolean=false; // stereoscopic view flag
		public static var mp:Boolean=false; // more poligons flag
		
		public static var doorstop:Boolean=true; // is the wedge in?
	}
}