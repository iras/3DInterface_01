/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package subModels
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 *	Thready submodel
	 *	@ purpose : holding local Bezier wire model
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class Thready extends EventDispatcher
	{
		private var _threadyName:String;
		private var _threadyMath:ThreadyMath;
		
		private var _endPoint1:Poly, _endPoint2:Poly;
		private var _count:int=0; // hold the count of polys updated to get when the new wire can be drawn.
		
		
		public function Thready(p1:Poly,p2:Poly):void 
		{			
			_endPoint1=p1; _endPoint2=p2;
			
			// register the polyUpdate function to the specific Poly (Model) CHANGE event. It allows this Threasy obj to receive notifications from the associated Endpoints (Polys).
			_endPoint1.addEventListener("CHANGE_"+_endPoint1.pName, ListenToPolyInst); // LOOK OUT for the registered NAME - a mispelling there can't be trackable !
			_endPoint2.addEventListener("CHANGE_"+_endPoint2.pName, ListenToPolyInst); // LOOK OUT for the registered NAME - a mispelling there can't be trackable !
						
			_threadyMath=new ThreadyMath(_endPoint1,_endPoint2);  // instantiate the number-cruncher.
		}
		public function destructor():void{_threadyMath.destructor();_threadyMath=null;_endPoint1=null;_endPoint2=null;} 
		// Handler
		private function ListenToPolyInst(e:Event): void 
		{
			_count++;
			
			if (_count==2)
			{				
				_threadyMath.doTheMath(); _count=0;
				dispatchEvent(new Event("CHANGE_"+_threadyName)); // let the ThreadyVisual instance know that the new _polyProjections Array are ready for collection.
			}
		}
		// Getters and Setters
		public function get tName():String{return _threadyName}
		public function set tName(a:String):void{_threadyName=a}
		public function get threadyMath():ThreadyMath{return _threadyMath}
	}
}