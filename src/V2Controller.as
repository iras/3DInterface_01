/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package
{
	import flash.events.TimerEvent;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	import subModels.GlobalDynamics;
	import subModels.Poly;
	import subModels.globalTransitions.*;	
	

	public class V2Controller implements IV2Controller
	{
		private const D2R:Number=Math.PI/180;
		
		private var _model:IV2Model, _globDyn:GlobalDynamics;
		// mouse
		private var _focus:String=""; // mouse focus can be set on : (0) dragger (1) polygon (2) thread (3) none of the previous ones: default.
		private var _1st_time:Boolean=false;
		// dragger_related vars
		private var _x0:Number, _y0:Number; // previous frame Dragger position
		private var _vx:Number, _vy:Number; // dragger velocity
		// polygon vars
		private var _polygon:Poly;
		private var _xp0:Number=0, _yp0:Number=0; // previous frame Poly position
		private var _vxp:Number=0, _vyp:Number=0; // poly velocity
		private var _vth:Number, _vph:Number;
		// timer energy_saver
		private var _etimer:Timer=new Timer(10000,0); // this is to get whether the user is using the 3Dinterface. If not, it stops calculating new frames and then saving energy.
		
		
		
		public function V2Controller (a:IV2Model) 
		{
			_model=a; _globDyn=_model.globDyn;
			
			_x0=300;  _y0=_vx=_vy=0; // init dragger
			
			_etimer.addEventListener(TimerEvent.TIMER, freeze);
		}
		
		// mouse
		public function setMouseNewPos (xm:int, ym:int):void  // this function is called at each new frame by the V2View instance.
		{
			switch (_focus)
			{
				case "dragger":
					if (_1st_time) {_vx=_vy=0; _1st_time=false} else {_vx=xm-_x0; _vy=ym-_y0; _globDyn.vdrx=_vx*D2R; _globDyn.vdry=_vy*D2R}
					_x0=xm; _y0=ym; break;
				
				case "polygon":
					_vth=_polygon.vth; _vph=_polygon.vph;
					if (_1st_time) {_vxp=_vyp=0; _1st_time=false} else {_vxp=xm-_xp0; _vyp=ym-_yp0; _vth=_vxp*D2R; _vph=-_vyp*D2R} // _tmp[0] and _tmp[1] will be calculated from PolyMath.
					_xp0=xm; _yp0=ym; _polygon.vth=_vth; _polygon.vph=_vph; break;
			}
		}
		
		// transitions
		public function transition01():void        
		{
			if (!_model.trans01Flag) // transition01 goes off unless transition01 is already happening.
			{
				_model.trans01=new V2Transition01(_model); _model.trans01Flag=true; // transition commence!
				ETimerStart()
			}
		}
		public function transition12(a:Vector.<Number>):void 
		{
			if (!_model.trans12Flag) // transition12 goes off unless transition12 is already happening.
			{
				_model.trans12=new V2Transition12(_model,a); _model.trans12Flag=true; // transition commence!
				ETimerStart()
			}
		}
		
		public function destructor():void{_etimer.reset(); _etimer.removeEventListener(TimerEvent.TIMER, freeze); _etimer=null; _model=null; _globDyn=null; _polygon=null}
		// dragger movement
		public function DraggerOn ():void{_focus="dragger"; _1st_time=true; ETimerStopAndReset()}
		public function DraggerOff():void{_focus=""; ETimerStart()}
		// polygon movement
		public function PolyOn (a:Poly):void{_focus="polygon"; _1st_time=true; _polygon=a; _polygon.isDragged=true; ETimerStopAndReset()}
		public function PolyOff():void{_focus=""; if(_polygon){_polygon.isDragged=false} ETimerStart()}
		// energy saver
		private function ETimerStart():void {_etimer.reset(); _etimer.start(); _model.energySaver=false}
		private function ETimerStopAndReset():void {_etimer.reset(); _model.energySaver=false}
		private function freeze (e:TimerEvent):void {Mouse.show(); _etimer.reset(); _model.energySaver=true}
	}
}