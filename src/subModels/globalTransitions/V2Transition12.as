/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package subModels.globalTransitions
{
	import subModels.*;
	
	// Global Transition 12 - Avalanche spreading linearly across the sphere. Such effect is achieved by means of a plane moving thru the sphere.
	//                        The plane parameters (centre + normal versor) are acquired from the PolyVisual instance that has been clicked on. 
	//                        V2Transition12's function is to trigger off a LOCAL TRANSITION in each Poly instances after the plane has gone beyond
	//                        them in its movemenet across the sphere. See whiteboard for more details.
	public class V2Transition12
	{
		private var _model:IV2Model, _pArrayModel:Array;
		
		// Sweeping plane data
		private var _n:Vector.<Number>=new Vector.<Number>();
		private var _r:Vector.<Number>=new Vector.<Number>();
		private var _sp:Number=0.33; // velocity of sweep_plane moving along the versor normal.
		// misc vars
		private var i:int, wo:int;
		private var test:Boolean, OnTickTest:Boolean;
		private var pCentre:Vector.<Number>;
		private var dpp0:Number, dpp1:Number, dpp2:Number;
		
		
		
		public function V2Transition12 (aModel:IV2Model, a:Vector.<Number>) 
		{
			_model=aModel; _pArrayModel=_model.pArray;
			
			// init sweeping-plane data
			_r.push(a[0]); _r.push(a[1]); _r.push(a[2]);
			_n.push(-a[3]);_n.push(-a[4]);_n.push(-a[5]); // normal is reversed - plane will progress inwards, towards centre of sphere and beyond to carry out the sweep
						
			wo=_pArrayModel.length; for(i=0;i<wo;i++) _pArrayModel[i].locTransOVER=false; // reset flag "local transition over flag".
		}
		public function onTick ():void 
		{
			OnTickTest=false; // set to false to catch whether there're still polygons not yet triggered off at the end of the for-loop.
			wo=_pArrayModel.length;
			for(i=0;i<wo;i++)
			{
				if (!_pArrayModel[i].locTrans12Flag)
				{
					if (SPlane_Test (_pArrayModel[i])) _pArrayModel[i].locTrans12Flag=true; // if the Poly passes the test, its local transition will get started.
					OnTickTest=true; // this assignment tells (outside the loop) that there've been being still polygons that needed to fire off their local transitions during this loop.
				}
			}
			
			shiftSPlane();
			
			// check whether this V2Transition12 instance has done transitioning. If yes, let the model know about it and clean it all up.
			if (!OnTickTest) {_model.trans12Flag=false; _model=null; _pArrayModel=[]} // clean up
		}
		private function SPlane_Test (a:Poly):Boolean 
		{
			test=false;
			pCentre=a.pMath.centre;
			
			// vector distance (centre_poli,_orig)  See whiteboards for more details
			dpp0=pCentre[0]-_r[0]; dpp1=pCentre[1]-_r[1]; dpp2=pCentre[2]-_r[2];
			
			if ((dpp0*_n[0]+dpp1*_n[1]+dpp2*_n[2])<0) test=true;
			return test;
		}
		private function shiftSPlane ():void{_r[0]+=_n[0]*_sp; _r[1]+=_n[1]*_sp; _r[2]+=_n[2]*_sp}
	}
}