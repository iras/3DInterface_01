/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/


package
{
	import subModels.*;
	
	public interface IV2Controller
	{
		function destructor():void
			
		// Transitions
		function transition01 ():void
		function transition12 (b:Vector.<Number>):void
		
		// Mouse Pos
		function setMouseNewPos (xm:int, ym:int):void
		
		// Dragger
		function DraggerOn  ():void
		function DraggerOff ():void
		
		// Polygon movement
		function PolyOn  (a:Poly):void
		function PolyOff ():void
	}
}