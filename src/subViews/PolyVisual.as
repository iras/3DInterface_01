/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package subViews
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import subModels.Poly;
	import subModels.PolyMath;
	/**
	 *	Poly subView class
	 *	@ purpose : Polygon Sprite management
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class PolyVisual extends Sprite
	{
		private const h:Number=0.5, l:Number=150;
		private const q1:Number=0.22, q2:Number=0.28, q3:Number=1.4;
		private const a_edge:int=Board.active_edge, i_edge:int=Board.inactive_edge;
		private const stick_col:int=0x5500FF;
		
		private var _pModel:Poly, _math:PolyMath, _mainContr:IV2Controller, _mainView:V2View;
		
		private var _pX:Vector.<Number>,_pY:Vector.<Number>,_pXX:Vector.<Number>;
		private var _fillData:Vector.<Number>;
		private var _depth:Number,_shade:Number;
		// text
		private var _tag:TextField=new TextField, _tal:TextField=new TextField;
		private var _txtFormat:TextFormat=new TextFormat("Arial",9,0xAA6666);
		// misc vars
		private var _edge:int=i_edge;
		private var _dsc:Number; // depth shade correction
		private var qq:Number=1.07,ww:Number=0.2; // vars for "aerial" sticking out of polygon
		private var i:int,wo:int;
		private var _a:Number,_b:Number; // temp vars
		private var alt:Boolean, ctrl:Boolean, any:Boolean;
		
		
		public function PolyVisual (cModel:Poly, cContro:IV2Controller, mView:V2View):void 
		{
			_pModel=cModel; _mainContr=cContro; _mainView=mView; _math=_pModel.pMath;
			
			addEventListener("SubViewREADY",_mainView.ListenToSubViews); // register the V2View obj to receive notifications from this SubView
			
			addEventListener(MouseEvent.MOUSE_DOWN,polyOnPress);
			addEventListener(MouseEvent.MOUSE_UP,  polyReleased);
			
			x=y=250;
			
			initTextFormat();
		}
		
		private function draw():void
		{
			// data retrieval from polyMath instance (number-cruncher object)
			_pX=_math.pprojX; _pY=_math.pprojY; _pXX=_math.pprojXX; // X and Y lists : (centre, normal, vertices...)
			
			_fillData=_math.moreData; // additional data relative to the data for filling the polygon
			_depth=_fillData[1]; _shade=_fillData[0];
			
			// draw poly
			_dsc=(q1+q2*(q3-_depth)); // depth shade correction
			
			graphics.clear(); graphics.lineStyle(2,_edge,_dsc);
			graphics.beginFill(_shade,_dsc);
			if(!Board.mp){graphics.drawCircle(_pX[0],_pY[0],3)}
			graphics.moveTo(_pX[3],_pY[3]);
			wo=_pX.length; for(i=4;i<wo;i++) graphics.lineTo(_pX[i],_pY[i]);
			graphics.endFill();
			
			if (Board.st) // dual stereoscopic version on the right hand-side
			{
				graphics.beginFill(_shade,_dsc);
				if(!Board.mp){graphics.drawCircle(_pXX[0],_pY[0],3)}
				graphics.moveTo(_pXX[3],_pY[3]);
				for(i=4;i<wo;i++) graphics.lineTo(_pXX[i],_pY[i]);
				graphics.endFill()
			}
			
			if (Board.mp) {_tag.visible=_tal.visible=false}
			else
			{
				_a=qq*_pX[0];_b=qq*_pY[0];
				graphics.lineStyle(3,stick_col,_dsc); graphics.moveTo(_a,_b); graphics.lineTo(_a+ww*_pX[1],_b+ww*_pY[1]); // aerial • standard bit - no matters what shape or transition the polygon's going thru.
				//graphics.moveTo(_pX[0],_pY[0]); graphics.lineTo(_pX[0]+ww*_pX[2],_pY[0]+ww*_pY[2]); // direction axis - (debugging)
				
				_tag.visible=true;
				_tag.x=_pX[0]+h*_pX[1]-5;_tag.y=_pY[0]+h*_pY[1]-5;
				if(Board.st){_tal.visible=true; _tal.x=_pXX[0]+h*_pXX[1]-l; _tal.y=_tag.y}
			}
			dispatchEvent(new Event("SubViewREADY"));
		}
		private function initTextFormat():void
		{
			_tag.defaultTextFormat=_txtFormat; _tag.width=20; _tag.text=_pModel.pName; addChild(_tag);
			_tal.defaultTextFormat=_txtFormat; _tal.width=20; _tal.text=_pModel.pName; addChild(_tal); _tal.visible=false;
		}
		
		// handlers
		public function listenToPolyInst(e:Event):void{draw()}
		private function polyOnPress(e:MouseEvent):void
		{
			alt=e.altKey; ctrl=e.ctrlKey; any=alt||ctrl;
			if(!any){_mainContr.PolyOn(_pModel); _edge=a_edge;} // drag a single facet
			else
			{
				if(ctrl) {_mainContr.PolyOn(_pModel); _edge=a_edge; _pModel.sel=true} // drag a single facet and capsize the local connections
				if(alt) if(!_pModel.mainModel.trans01Flag&&!_pModel.pShape){_mainContr.transition12(_math.centre.concat(_math.normal))} // pass values down (sweeping plane values) and commence the trans12
			}
		}
		private function polyReleased(e:MouseEvent):void{_mainContr.PolyOff(); _edge=i_edge; _pModel.sel=false}
		
		public function edge_off():void{_edge=i_edge}
		public function destructor():void
		{
			removeEventListener(MouseEvent.MOUSE_DOWN,polyOnPress);
			removeEventListener(MouseEvent.MOUSE_UP,polyReleased);
			removeEventListener("SubViewREADY",_mainView.ListenToSubViews);
			removeChild(_tag);removeChild(_tal);
			_txtFormat=null; _tag=null; _tal=null;
			graphics.clear();
			_pModel=null; _math=null; _mainContr=null; _mainView=null;
			_pX.length=_pY.length=_pXX.length=_fillData.length=0;
		}
		// getters and setters
		public function get depth():Number{return _depth} // for Z-sorting purposes.
		public function get model():Poly  {return _pModel}
	}
}