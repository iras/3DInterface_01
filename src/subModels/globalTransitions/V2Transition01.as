/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package subModels.globalTransitions
{
	// Global Transition 01   -   This transition takes care of opening up the polyhedron initially closed  (blossoming phase)
	public class V2Transition01
	{
		private var _model:IV2Model, _pArrayModel:Array; // List of subModels Poly Instances
		
		private var _slider:Number;
		
		// timing vars
		private var _trans_time:Number=0;
		// misc vars
		private var i:int, wo:int;
		private var test:Boolean;
		
		
		
		public function V2Transition01 (aModel:IV2Model) 
		{
			_model=aModel; _pArrayModel=_model.pArray;
			_model.slider=0.2; // DO NOT go above 1 otherwise the algorithm blows up.
			
			wo=_pArrayModel.length;
			for (i=0;i<wo;i++) _pArrayModel[i].locTrans01Flag=true; // allow Poly instances to start the local transition that in this case is only apply the Sliding();
		}
		
		public function onTick ():void 
		{
			_trans_time+=0.3;
			
			if (_trans_time<14)
			{
				_slider=_model.slider;
				_slider=0.9*_slider*(1-_slider); // 1st-order non-linear differential equation. Solution : logistic function (sigmoidal-shape curve)
				_model.slider=_slider;
			}
			else // clean up
			{
				_model.trans01Flag=false;
				wo=_pArrayModel.length; for (i=0;i<wo;i++) _pArrayModel[i].locTrans01Flag=false;
				_model=null; _pArrayModel=[];
			}
		}
	}
}