/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package
{
	// VIEW2MODEL Class : I originally wished to extend EventDispatcher in setting V2Model but then ENTER_FRAME property wasn't covered so I
	//                    had to use the Sprite Class which is extended from EventDispatcher. Obviously, I'm NOT going to addChild(this) anywhere.
	
	import flash.events.Event;
	import flash.display.Sprite;
	import subModels.Poly;
	import subModels.Thready;
	import subModels.GlobalDynamics;
	import subModels.globalTransitions.*;
	

	public class V2Model extends Sprite implements IV2Model
	{
		private var _globDyn:GlobalDynamics;
		// SubModels vars
		private var _poly:Poly, _thready:Thready;
		private var _pArrayModel:Array=[], _tArrayModel:Array=[]; // list of subModels (Poly, Thready) Instances
		// misc vars
		private var _time:Number=0;
		private var _slider:Number=0.001;
		// Energy Saver vars
		private var _energySaver:Boolean=false; // energy saver not active at the beginning.
		// Global transitions vars
		private var _trans_01:V2Transition01, _trans_01_flag:Boolean=false;
		private var _trans_12:V2Transition12, _trans_12_flag:Boolean=false;
		
		
		
		public function V2Model() {_globDyn=new GlobalDynamics(this)}
		public function KickOff():void {addEventListener (Event.ENTER_FRAME,onFrame)}
		
		private function onFrame (e:Event):void {if (!_energySaver) {generateNewValues(); dispatchEvent(new Event("NewFRAME"))}}
		private function generateNewValues():void 
		{
			_time++;
			// global transitions
			if (_trans_01_flag) {_trans_01.onTick ()}
			if (_trans_12_flag) {_trans_12.onTick ()}
			// global dynamics
			_globDyn.updateDyn ();
		}
		public function destructor():void
		{
			removeEventListener(Event.ENTER_FRAME,onFrame);
			_globDyn.destructor(); _globDyn=null;
			for each(var p:Poly    in _pArrayModel) {p.destructor()} _pArrayModel=[]; _poly=null;
			for each(var t:Thready in _tArrayModel) {t.destructor()} _tArrayModel=[]; _thready=null;
			_trans_01=null; _trans_12=null
		}
		
		// Setters and Getters
		public function get globDyn ():GlobalDynamics {return _globDyn}
		//    - math
		public function get slider ():Number{return _slider}
		public function set slider (a:Number):void{_slider=a}
		//    - submodels
		public function setSubModelsList (p:Array,t:Array):void{_pArrayModel=p; _tArrayModel=t}
		public function get totalSubViewObjs ():int{return (_pArrayModel.length+_tArrayModel.length-1)}
		public function get pArray ():Array{return _pArrayModel}
		//    - energy saver
		public function set energySaver (a:Boolean):void{_energySaver=a}
		public function get energySaver ():Boolean{return _energySaver}
		//    - global transitions
		public function get trans12Flag ():Boolean{return _trans_12_flag}
		public function set trans12Flag (a:Boolean):void{_trans_12_flag=a}
		public function set trans12 (a:V2Transition12):void{_trans_12=a}
		public function get trans01Flag ():Boolean{return _trans_01_flag}
		public function set trans01Flag (a:Boolean):void{_trans_01_flag=a}
		public function set trans01 (a:V2Transition01):void{_trans_01=a}
	}
}