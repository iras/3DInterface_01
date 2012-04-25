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
	
	import subModels.Thready;
	import subModels.ThreadyMath;
	/**
	 *	Thready subView class
	 *	@ purpose : Wire Sprite management
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class ThreadyVisual extends Sprite
	{
		private const c:Number=0.4,d:Number=0.7,e:Number=0.2,f:Number=1.55;
		private const d7:Number=0.7, d3:Number=0.3; // consts to make the line dotted.
		private const orng:int=0xFF5500;
		
		private var _assocModel:Thready, _math:ThreadyMath, _mainView:V2View;
		private var _pX:Vector.<Number>,_pY:Vector.<Number>,_pXX:Vector.<Number>;
		private var _depths:Vector.<Number>; // spline points z-depths (to change the colour of each linear segment constituting the spline).
		
		private var _zSortDepth:Number; // Not to confuse this Number with the vector _depths. This var _zSortDepth is for z-sorting purposes.
		
		// misc
		private var i:int,k:int,wo:int;
		private var _dsa:Number;
		private var _max:Number=0;
		
		
		public function ThreadyVisual (aModel:Thready, mView:V2View):void 
		{
			_assocModel=aModel; _math=_assocModel.threadyMath; _mainView=mView;
			addEventListener("SubViewREADY",_mainView.ListenToSubViews); // register the V2View instance to receive notifications from this SubView
			
			x=y=250;
		}
		private function draw ():void 
		{
			_pX=_math.pprojX;_pY=_math.pprojY;_pXX=_math.pprojXX; // spline X-Y coords list plus stereoscopic one.
			_depths=_math.depths; // spline points z-depths.
			
			k=_pX.length-1; graphics.clear();
			if (_assocModel.threadyMath.sel)
			{
				_zSortDepth=-10; graphics.lineStyle(3,orng); alpha=0.5;
				for(i=0;i<k;i++)             {graphics.moveTo(_pX[i],_pY[i]); graphics.lineTo(_pX[i+1]*d7+_pX[i]*d3,_pY[i+1]*d7+_pY[i]*d3)} // draw Bezier spline
				if(Board.st){for(i=0;i<k;i++){graphics.moveTo(_pXX[i],_pY[i]);graphics.lineTo(_pXX[i+1]*d7+_pXX[i]*d3,_pY[i+1]*d7+_pY[i]*d3)}} // 2nd spline for stereoscopic view.
			}
			else {
				_zSortDepth=max(_depths); if(_zSortDepth<0){_zSortDepth+=e} else {_zSortDepth-=e} alpha=1; // the if() part is to adjust the threads positions inside the sphere.
				for(i=0;i<k;i++)             {graphics.lineStyle(1,depthShadeAdj(_depths[i]),d); graphics.moveTo(_pX[i],_pY[i]); graphics.lineTo(_pX[i+1],_pY[i+1])} // draw Bezier spline
				if(Board.st){for(i=0;i<k;i++){graphics.lineStyle(1,depthShadeAdj(_depths[i]),d); graphics.moveTo(_pXX[i],_pY[i]);graphics.lineTo(_pXX[i+1],_pY[i+1])}} // 2nd spline for stereoscopic view.
			}
			
			graphics.lineStyle(3,0xFFFFCC,1); // add synapse-shaped junctions at the 2 endpoints.
			graphics.moveTo(_pX[0],_pY[0]);graphics.lineTo(_pX[0]+c,_pY[0]+c); // it doesn't really matter which the final point is coz it's just a thin junction ;)
			graphics.moveTo(_pX[k],_pY[k]);graphics.lineTo(_pX[k]+c,_pY[k]+c);
			
			if (Board.st)
			{ // same as above (stereoscopic bit)
				graphics.moveTo(_pXX[0],_pY[0]);graphics.lineTo(_pXX[0]+c,_pY[0]+c);
				graphics.moveTo(_pXX[k],_pY[k]);graphics.lineTo(_pXX[k]+c,_pY[k]+c);
			}
			
			dispatchEvent (new Event("SubViewREADY"));
		}
		private function depthShadeAdj(a:Number):uint{_dsa=80*(f-a); return (190+int(_dsa<<8)+int(_dsa<<16))} // (analogous to : tmp+25 + tmp*256 + tmp*65536)
		private function max(a:Vector.<Number>):Number{_max=a[0]; wo=a.length; for(i=1;i<wo;i++) if(a[i]>_max)_max=a[i]; return _max}
		// Handler
		public function ListenToThreadyInst (e:Event):void {draw()}
		
		public function destructor():void
		{
			removeEventListener("SubViewREADY",_mainView.ListenToSubViews);
			graphics.clear();
			_assocModel=null; _math=null; _mainView=null;
			_pX.length=_pY.length=_pXX.length=_depths.length=0;
		}
		// Getter
		public function get depth():Number {return _zSortDepth} // for z-sorting purposes.
		public function get model():Thready{return _assocModel}
	}
}