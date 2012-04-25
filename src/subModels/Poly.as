/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/


package subModels
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 *	Poly submodel
	 *	@ purpose : holding local polygon model
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class Poly extends EventDispatcher // Polygon (Triangle/Circle) SubModel Class
	{
		private const _q1:Number=1.22,_w1:Number=0.14,_q2:Number=1.2,_w2:Number=0.07;
		private var _mainModel:IV2Model;
		private var _sel:Boolean=false;
		
		private var _polyName:String, _polyId:int; // Id is used by the GlobalDynamics instance for indexing purposes (when calculating mutual angles)
		private var _n_threads:int=0; // number of threads hanging from this polygon.
		private var _links:Array=[]; // list of Poly instances this Poly instance is connected to.
		private var _pMath:PolyMath; // associated object devoted only to 3D number crunching.
		private var _isDragged:Boolean=false;
		private var _pShape:Boolean=false; // false:triangle, true:circle-ish (dodecagon)
		
		private var _polyX:Vector.<Number>=new Vector.<Number>(),_polyY:Vector.<Number>=new Vector.<Number>(),_polyZ:Vector.<Number>=new Vector.<Number>();
		private var _moreData:Array; // it contains polygon shade plus z-value for depth-of-field calculations.
		// local dynamics angular data  (initial conditions when collected from the GlobalDynamics instance and then after processing they become New Values that are put back in from the same GlobalDynamics instance).
		private var _vth:Number, _vph:Number; // theta dot, phi dot
		// local transitions vars
		private var _locTransTime:Number=0, _locTransTimeIncr:Number=0.33;
		private var _locTrans01:Boolean=false, _locTrans12:Boolean=false, _locEndOfFirstPart:Boolean=false, _locTransOVER:Boolean=false; // _localTransOVER is to make sure that unwanted re-fires do not take place while the global transition is still on.
		// misc
		private var i:int,j:int;
		
		
		public function Poly (m:IV2Model,a:Vector.<Number>):void // a = list of 3D polygon corners : ( x0,y0,z0,x1,y1,z1,x2,... )
		{
			_mainModel=m;
			
			 for(i=0;i<(a.length/3);i++) {j=3*i; _polyX[i]=a[j];_polyY[i]=a[j+1];_polyZ[i]=a[j+2]} // split "a" content into 3 arrays.
			
			 _pMath=new PolyMath(_mainModel,this,_polyX,_polyY,_polyZ); // instantiate the number-cruncher. _vth,_vph will be initiated by this object.
		}
		// Handler
		public function ListenToTopModelInst (e:Event):void 
		{
			_pMath.doTheMath();
			
			// local transitions look-up table
			if (_locTrans01) locTrans01();
			if (_locTrans12) locTrans12();
			
			dispatchEvent (new Event("CHANGE_"+_polyName)); // let the view know that the new PProjX,PProjY Arrays are ready for collection.
		}
		// local transitions functions
		private function locTrans01():void {_pMath.slidingOutwards()} // this local transition is done instantly.
		private function locTrans12():void 
		{
			if (!_locTransOVER)
			{
				if (!_locEndOfFirstPart)
				{
					_locTransTime+=_locTransTimeIncr;
					_pMath.resize (0.61);
					
					if (_locTransTime>1) {_locEndOfFirstPart=true; _pMath.changeTriangleToCircle()}
				}
				else
				{
					_locTransTime+=_locTransTimeIncr;
					if (Board.mp) _pMath.resize (_q1+_n_threads*_w1); else _pMath.resize (_q2+_n_threads*_w2);
					
					if (_locTransTime>2) {_locEndOfFirstPart=false; _locTrans12=false; _locTransOVER=true; _locTransTime=0}
				}
			}
		} // this local transition takes a short while to complete.
		
		public function isLinked (a:Poly):Boolean{return(_links.indexOf(a)==-1)}
		public function addLink  (a:Poly):void{_links.push(a)}
		public function incrLinksCounter():void {_n_threads++}
		public function destructor():void {_pMath.destructor();_pMath=null;_mainModel=null;_links=[];_polyX.length=_polyY.length=_polyZ.length=0;_moreData=[]} 
		// Getters and Setters
		public function get mainModel():IV2Model{return _mainModel}// PolyVisual instance needs this function.
		public function get pName    ():String  {return _polyName} public function set pName(a:String):void{_polyName=a}
		public function get pId      ():int     {return _polyId}   public function set pId(a:int):void{_polyId=a}
		public function get pMath    ():PolyMath{return _pMath}
		public function get pShape   ():Boolean {return _pShape}   public function set pShape(a:Boolean):void{_pShape=a}
		public function get sel      ():Boolean {return _sel}      public function set sel(a:Boolean):void{_sel=a} // is poly selected?
		public function get links    ():Array   {return _links}
		public function get totalThreads():int  {return _n_threads}
		public function get vth():Number{return _vth} public function set vth(a:Number):void{_vth=a}
		public function get vph():Number{return _vph} public function set vph(a:Number):void{_vph=a}
		
		public function set locTrans12Flag(a:Boolean):void{_locTrans12=a} public function get locTrans12Flag():Boolean{return _locTrans12}
		public function set locTrans01Flag(a:Boolean):void{_locTrans01=a}
		public function set locTransOVER(a:Boolean):void{_locTransOVER=a}
		public function get isDragged():Boolean{return _isDragged} public function set isDragged(a:Boolean):void{_isDragged=a}
	}
}