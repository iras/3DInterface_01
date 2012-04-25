/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package
{
	import fl.controls.CheckBox;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	import subModels.*;
	import subViews.*;
	
	
	/**
	 *	V2View class
	 *	@ purpose : both client (Document Class) and main MVC view class.
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	[SWF(backgroundColor="#001133", frameRate="24", width="800", height="600")]
	public class V2View extends Sprite
	{
		// V2View vars (as client)
		private var _model:IV2Model, _controller:IV2Controller;
		private var _top:Sprite=new Sprite(),_ensemble:Sprite=new Sprite(); // _top sprite will always stay on top of the sprite hierarchy and will host mouse pointers and dragger.
		// V2View vars   (as a view)
		private var _polyVisual:PolyVisual, _threadyVisual:ThreadyVisual;
		private var _pArrayView:Array=[],_tArrayView:Array=[],_objArrayView:Array=[];
		private var _totalViewObjs:int,_vObjsCounter:int;
		// model vars
		private var _poly:Poly,_thready:Thready;
		private var _pArrayModel:Array=[],_tArrayModel:Array=[];
		// dragger var
		private var _btn:Sprite;
		// checkboxes vars
		private var _qual:CheckBox=new CheckBox(),_nply:CheckBox=new CheckBox(),_wedge:CheckBox=new CheckBox(),_stereo:CheckBox=new CheckBox();
		// data loader vars
		private var xml:XML, urlLoader:URLLoader=new URLLoader(), urlRequest:URLRequest=new URLRequest();
		// misc vars
		private var i:int,j:int,wo:int;
		private var _polyhedron:Vector.<Number>=new Vector.<Number>(), qqq:Array=new Array();
		private var _fmt:TextFormat=new TextFormat("Arial",11,0xAAAAAA);
		// frame rate tracker vars (debugging)
		// private var time:int, prevTime:int=0, f:TextField=new TextField(); 
		
		
		
		public function V2View() {stageInit(); preInit()}
		private function stageInit():void {stage.scaleMode=StageScaleMode.NO_SCALE; stage.align=StageAlign.TOP_LEFT; stage.quality=StageQuality.MEDIUM}
		private function preInit():void
		{
			if (Board.mp) urlRequest.url="80poly.xml"; else urlRequest.url="20poly.xml";
			urlLoader.dataFormat=URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE,load_complete);
			urlLoader.load(urlRequest);
		}
		private function init():void
		{
			addChild(_ensemble); addChild(_top);
			
			// client init (V2View takes up the client role in instantiating the rest of the classes)
			_model=new V2Model(); _controller=new V2Controller(_model);
			
			// view init
			_model.addEventListener("NewFRAME", ListenToV2ModelInst); // register here b4 instantiating the subModels and subViews in order to be the first one to receive NewFRAME notifications from V2Model (to get how many subViews he has to expect to get back to it before applying the zSort to the whole group of subViews)
			
			// initiate subModel-subView Diads (Poly-PolyVisual and Thready-ThreadyVisual)
			initPolygons(); // init the pair    Poly-PolyVisual.
			initThreadys(); // init the pair Thready-ThreadyVisual.
			_polyhedron.length=0; // empty space
			
			// send copy of the subModels Arrays to the Top model.
			_model.setSubModelsList(_pArrayModel,_tArrayModel); // (*) although the V2Model instance is decoupled with the subModels (dispatches Events to communicate with them), it will manage the addition/deletion of them them at RUNTIME.
			_model.KickOff(); // Start Timing (Event.ENTER_FRAME)
			
			initDragger(); initCheckBoxes();
			
			_controller.transition01(); // start blossoming
			
			// f.width=20; _top.addChild(f); // frame rate tracker - top left of the screen (debugging)
			
			stage.addEventListener(MouseEvent.MOUSE_UP,mouseBtnReleased);
		}
		private function initPolygons():void 
		{
			wo=_polyhedron.length/9;
			for (i=0;i<wo;i++)
			{
				// (1) Poly (subModel) instantiation and initiation and function registered to be notified from _model NewFRAME Events.
				_poly=new Poly(_model,_polyhedron.slice(i*9,(i+1)*9));
				_poly.pName="p"+(i+1); _poly.pId=i+1;
				_model.addEventListener ("NewFRAME",_poly.ListenToTopModelInst); // LOOK OUT for RUNTIME event NAME - no STATIC Const defined in a Custom Event class for it ! Mispelling not trackable!
				
				// (2) PolyVisual (subView) instantiation and initiation
				_polyVisual=new PolyVisual(_poly,_controller,this);
				_polyVisual.name="p"+(i+1);
				
				// (3) register the new PolyVisual's instance update function to catch CHANGE events dispatched by the associated new Poly (subModel) instance.
				_poly.addEventListener("CHANGE_"+_polyVisual.name,_polyVisual.listenToPolyInst); // LOOK OUT for RUNTIME event NAME - no STATIC CONSTs defined in a Custom Event class for them ! Mispelling not trackable!
				
				// (4) push the new Poly (subModel) and PolyVisual (subView) instances into their respective Array.
				_pArrayModel.push(_poly); _pArrayView.push(_polyVisual);
			}
		}
		private function initThreadys ():void
		{
			var lengthP:int=_polyhedron.length/9, r1:int, r2:int;
			for (j=0;j<70;j++)
			{
				r1=int(Math.random()*lengthP); r2=int(Math.random()*lengthP);
				
				if ((r1!=r2)&&_pArrayModel[r1].isLinked(_pArrayModel[r2])&&_pArrayModel[r2].isLinked(_pArrayModel[r1]))
				{
					// (1) Thready (subModel) instantiation and initiation. This object will contain references to the 2 RANDOM Poly (subModel) objs at the end points.
					_thready=new Thready (_pArrayModel[r1],_pArrayModel[r2]); // * In the Thready Constructor, this new obj will be set to receive notifications from the Endpoints CHANGE. (Polys)
					_pArrayModel[r1].incrLinksCounter(); _pArrayModel[r2].incrLinksCounter(); // increment the count by one in each Poly instance.
					_pArrayModel[r1].addLink (_pArrayModel[r2]);_pArrayModel[r2].addLink(_pArrayModel[r1]);// save the new link in each other's _links var.
					_thready.tName="t"+(j+1+lengthP );
					
					// (2) ThreadyVisual (subView) instantiation and initiation.
					_threadyVisual=new ThreadyVisual(_thready,this);
					_threadyVisual.name="t"+(j+1+lengthP);
					
					// (3) register the new ThreadyVisual's instance update function to catch CHANGE events dispatched by the associated new Thready (subModel) instance.
					_thready.addEventListener("CHANGE_"+_threadyVisual.name,_threadyVisual.ListenToThreadyInst); // LOOK OUT for RUNTIME event NAME - no STATIC CONSTs defined in a Custom Event class for them ! Mispelling not trackable!
					
					// (4) push the new Thready (subModel) and ThreadyVisual (subView) instances into their respective Array.
					_tArrayModel.push(_thready); _tArrayView.push(_threadyVisual);
				}
			}
		}
		public function restartV2View():void
		{
			_qual.removeEventListener(MouseEvent.CLICK,toggleQuality);  _top.removeChild(_qual);
			_nply.removeEventListener(MouseEvent.CLICK,toggleDensity);  _top.removeChild(_nply);
			_wedge.removeEventListener(MouseEvent.CLICK,toggleDynamics);_top.removeChild(_wedge);
			_stereo.removeEventListener(MouseEvent.CLICK,toggleStereo); _top.removeChild(_stereo);
			
			stage.removeEventListener(MouseEvent.MOUSE_UP,mouseBtnReleased);
			
			_model.removeEventListener("NewFRAME",ListenToV2ModelInst);
			for each(var q:ThreadyVisual in _tArrayView){q.model.removeEventListener("CHANGE_"+q.name,q.ListenToThreadyInst); q.destructor()}
			for each(var p:PolyVisual    in _pArrayView){p.model.removeEventListener("CHANGE_"+p.name,p.listenToPolyInst); _model.removeEventListener("NewFRAME",p.model.ListenToTopModelInst);p.destructor()}
			for (i=0;i<_objArrayView.length;i++){_ensemble.removeChild(_objArrayView[i])} _objArrayView=[];
			_tArrayView=[]; _pArrayView=[]; removeChild(_ensemble);
			_poly=null; _thready=null; _polyVisual=null; _threadyVisual=null;
			
			//_top.removeChild(f); // frame rate tracker
			_btn.removeEventListener(MouseEvent.MOUSE_DOWN,btnDownHandler);
			_btn.removeEventListener(MouseEvent.MOUSE_UP,btnUpHandler);
			_btn.removeEventListener(Event.MOUSE_LEAVE,btnUpHandler);
			_btn.graphics.clear();_top.removeChild(_btn);removeChild(_top);
			
			_controller.destructor(); _controller=null;
			_model.destructor(); _model=null;
			_pArrayModel=[]; _tArrayModel=[];
			
			preInit() // start off again
		}
		// handlers
		private function ListenToV2ModelInst (e:Event):void // this method is registered in this V2View instance.
		{
			_totalViewObjs=_model.totalSubViewObjs; _vObjsCounter=0;
			
			//for (i=0;i<_objArrayView.length;i++) {removeChild (_objArrayView[i])} // empty the Display List - I might not need this !!!!!!!!!!!!!!!  TODO : check this out !
			_objArrayView=[];
			
			_controller.setMouseNewPos(stage.mouseX,stage.mouseY); // set the new mouse position in the controller.
			
			// time=getTimer(); f.text=String(1000/(time-prevTime)); prevTime=getTimer(); // frame rate tracker
		}
		public function ListenToSubViews (e:Event):void // this method is registered in PolyVisual + ThreadyVisual objects.
		{
			if (_vObjsCounter<_totalViewObjs) {_vObjsCounter++; _objArrayView.push(e.target as Sprite)}
			else // ---  this bit will work as soon as all the subviews have been drawn
			{
				_objArrayView.push(e.target as Sprite);  // add the last sprite to the _objArrayView
				_objArrayView.sortOn("depth",Array.DESCENDING|Array.NUMERIC); // Z-sorting
				
				wo=_objArrayView.length; for(i=0;i<wo;i++){_ensemble.addChild(_objArrayView[i])}
			}
		}
		private function load_complete(e:Event):void
		{
			xml=new XML(e.target.data); for each(var q:XML in xml.face){qqq=qqq.concat(q.data.split(","))} xml=null; // extract data
			for each(var w:String in qqq) {_polyhedron.push(Number(w))} qqq=[]; // convert vector elements's String type to type Number
			init()
		}
		// checkboxes and dragger init + handlers
		private function initCheckBoxes():void
		{
			_nply.textField.autoSize=TextFieldAutoSize.LEFT; _nply.setStyle("textFormat",_fmt); _nply.x=50; _top.addChild(_nply);
			_nply.label="denser sphere"; _nply.addEventListener(MouseEvent.CLICK,toggleDensity);
			_wedge.textField.autoSize=TextFieldAutoSize.LEFT;_wedge.setStyle("textFormat",_fmt); _wedge.x=200;
			_wedge.label="wegde off"; _wedge.addEventListener(MouseEvent.CLICK,toggleDynamics); _top.addChild(_wedge);
			_stereo.textField.autoSize=TextFieldAutoSize.LEFT;_stereo.setStyle("textFormat",_fmt); _stereo.x=350;
			_stereo.label="stereoscopic view";_stereo.addEventListener(MouseEvent.CLICK,toggleStereo); _top.addChild(_stereo);
			_qual.textField.autoSize=TextFieldAutoSize.LEFT; _qual.setStyle("textFormat",_fmt); _qual.x=500;
			_qual.label="higher quality"; _qual.addEventListener(MouseEvent.CLICK,toggleQuality); _top.addChild(_qual)
		}
		private function toggleQuality (e:Event):void {if(_qual.selected) stage.quality=StageQuality.HIGH; else stage.quality=StageQuality.MEDIUM}
		private function toggleDensity (e:Event):void {if(_nply.selected) Board.mp=true; else Board.mp=false; Board.doorstop=true; restartV2View()}
		private function toggleDynamics(e:Event):void {if(_wedge.selected)Board.doorstop=false; else Board.doorstop=true}
		private function toggleStereo  (e:Event):void {if(_stereo.selected)Board.st=true; else Board.st=false; Board.doorstop=true; restartV2View()}
		
		private function initDragger():void  
		{
			_btn=new Sprite(); _btn.graphics.beginFill(0xCBFF00,0.5); _btn.graphics.drawCircle(20,20,16); _btn.graphics.endFill();
			
			_btn.addEventListener(MouseEvent.MOUSE_DOWN, btnDownHandler);
			_btn.addEventListener(MouseEvent.MOUSE_UP, btnUpHandler);
			_btn.addEventListener(Event.MOUSE_LEAVE, btnUpHandler); // same handler as if the button got released.
			
			_top.addChild(_btn); _btn.x=400; _btn.y=70;
		}
		private function btnUpHandler  (e:MouseEvent):void {e.currentTarget.stopDrag (); _controller.DraggerOff()}
		private function btnDownHandler(e:MouseEvent):void {e.currentTarget.startDrag(); _controller.DraggerOn()}
		
		private function mouseBtnReleased(e:MouseEvent):void{_controller.PolyOff(); for each(var p:PolyVisual in _pArrayView){p.edge_off(); p.model.sel=false}}
	}
}