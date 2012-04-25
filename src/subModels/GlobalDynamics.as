/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/


package subModels
{
	/**
	*	global dynamics class
	*	@ purpose : overall superficial dynamics processing
	*	author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	*/
	public class GlobalDynamics
	{
		private const MIN:Number=0.435; // 5° = 0.087 radians, 25° = 0.435 radians
		private const c:Number=0.7; // dampening factor, actually the real one is 1-c
		private const o:Number=0.3; // reduces the strenght of the repulsive forces.
		private const k:Number=0.01; // spring const
		private const thr:Number=1e-10; // if the velocity falls under this threshold, it won't affect the poly's values.
		
		private var _mainModel:IV2Model, _pArrayModel:Array;
		
		private var _vdrx:Number,_vdry:Number,_drx:Number=0,_dry:Number=0; // Dragger velocity (which is then interpreted as angular vel)
		// misc vars
		private var _mj:PolyMath;
		private var i:int,j:int,wo:int;
		private var _vv:Number, _rv:Number;
		private var _tmp:Vector.<Number>, _tmp1:Vector.<Number>;
		// mutual angles part
		private var _amx:Vector.<Vector.<Number>>=new Vector.<Vector.<Number>>(); // temp matrix holding all the mutual angles.
		private var _x1:Number,_y1:Number,_z1:Number; // temp holder of the poly centre.
		private var _t:Number; // temp
		// dynamics vars
		private var _id1:int, _id2:int;
		private var _fi:Number,_fj:Number,_fk:Number; // temp repulsive contribution.
		private var _t0:Number, _t1:Number, _t2:Number, _vt:Number // temp storage for the poly tangent and its magnitude.
		private var _angle:Number;
		private var _f:Vector.<Vector.<Number>>=new Vector.<Vector.<Number>>(); // store temp forces to be added at the end.
		private var df1:Number, df2:Number;
		private var afg:Boolean, rfg:Boolean; // flags
		private var _rep:Number, _atr:Number;
		private var _ri:Vector.<Number>, _rj:Vector.<Number>;
		private var b0:Number,b1:Number,b2:Number; // binormal components
		private var d0:Number,d1:Number,d2:Number, rsr:Number; // projected distance components and reciprocal of _d's magnitude.
		
		
		
		public function GlobalDynamics (m:IV2Model):void {_mainModel=m; _vdrx=0; _vdry=0; _drx=_dry=0} //0.7;-0.262;   // Initial Spin.
		public function updateDyn ():void {doOverallRot(); doSurfaceDynamics()}
		private function doOverallRot ():void {_vdrx*=0.75; _vdry*=0.75; _drx+=_vdrx; _dry+=_vdry} // update the Dragger cinematic angular contribution - each PolyMath instance will fetch these 2 values and add it locally to their dynamic part.
		private function doSurfaceDynamics ():void
		{
			_pArrayModel=_mainModel.pArray;
			
			findMutualAngles(); // all angles between between two poligons'centres.
			if (Board.doorstop) findOnlyRepForces(); else findForces();
			addUpForces(); // ODEs system solver
			
			// TODO : Clean up all _f_array's internal arrays=[] before releasing _f_array itself.
			// TODO : How can I avoid re-instantiating the structure at every new frame ? ? ?
			// TODO : Change all the arrays to vectors.
		}
		// computationally intensive method : T(n)=O(n^2). (19 mults, 11 adds) per (inner) cycle. TODO: correct the time complexity.
		private function findOnlyRepForces ():void
		{
			_f.length=0; wo=_pArrayModel.length; _f.length=wo; // clean up vector
			for (j=0;j<wo;j++)
			{
				_rj=_pArrayModel[j].pMath.r;
				_id1=_pArrayModel[j].pId-1; // decrement _id1 to align the Poly-indexing and the AnglesMatrix-indexing.
				_fi=_fj=_fk=0;
				_f[j]=new Vector.<Number>(3,false); // reset values + init new temp array to store force contributions in 3D coords.
				for (i=0;i<wo;i++)
				{
					_id2=_pArrayModel[i].pId-1; // same comment as for id1 above
					_angle=_amx[_id1][_id2];
					
					if (_angle>0)
					{
						if (_angle<MIN) // TODO : I can avoid calculating the acos() for each angle! I just need to know the range in which the cosine is supposed to find itself at when matching the selected boundaries...
						{
							_ri=_pArrayModel[i].pMath.r; _rep=_atr=0;
							// find the versor difference (_ri-_rj) projected on the plane (_rj's tangent,binormal), in a similar way as in PolyMath.findTBversors(), two x-products.
							b0=_ri[1]*_rj[2]-_ri[2]*_rj[1]; b1=-_ri[0]*_rj[2]+_ri[2]*_rj[0]; b2=_ri[0]*_rj[1]-_ri[1]*_rj[0]; // x-product 1 : not normalised binormal components.
							d0=b1*_rj[2]-b2*_rj[1];         d1=-b0*_rj[2]+b2*_rj[0];         d2=b0*_rj[1]-b1*_rj[0]; // x-product 2 : not normalised vector diff components.
							
							_rep=o*(MIN-_angle); // if it's within reach, the repulsive influence gets calculated.
							
							rsr=_rep/Math.sqrt(d0*d0+d1*d1+d2*d2);
							_fi+=d0*rsr; _fj+=d1*rsr; _fk+=d2*rsr; // the repulsive contrib vector is been updated with versor difference components multiplied by its angle and dampening factor.
						}
					}
				}
				_f[j][0]=_fi; _f[j][1]=_fj; _f[j][2]=_fk
			}
		}
		// computationally intensive method : T(n)=O(n^2). (19 mults, 11 adds) per (inner) cycle. TODO: correct the time complexity.
		private function findForces ():void
		{
			_f.length=0; wo=_pArrayModel.length; _f.length=wo; // clean up vector
			for (j=0;j<wo;j++)
			{
				_rj=_pArrayModel[j].pMath.r;
				_id1=_pArrayModel[j].pId-1; // decrement _id1 to align the Poly-indexing and the AnglesMatrix-indexing.
				_fi=_fj=_fk=0;
				_f[j]=new Vector.<Number>(3,false); // reset values + init new temp array to store force contributions in 3D coords.
				for (i=0;i<wo;i++)
				{
					_id2=_pArrayModel[i].pId-1; // same comment as for id1 above
					_angle=_amx[_id1][_id2];
					
					if (_angle>0)
					{
						rfg=_angle<MIN; afg=_pArrayModel[j].isLinked(_pArrayModel[i]); // conditions check
						
						if (rfg||afg) // TODO : I can avoid calculating the acos() for each angle! I just need to know the range in which the cosine is supposed to find itself at when matching the selected boundaries...
						{
							_ri=_pArrayModel[i].pMath.r; _rep=_atr=0;
							// find the versor difference (_ri-_rj) projected on the plane (_rj's tangent,binormal), in a similar way as in PolyMath.findTBversors(), two x-products.
							b0=_ri[1]*_rj[2]-_ri[2]*_rj[1]; b1=-_ri[0]*_rj[2]+_ri[2]*_rj[0]; b2=_ri[0]*_rj[1]-_ri[1]*_rj[0]; // x-product 1 : not normalised binormal components.
							d0=b1*_rj[2]-b2*_rj[1];         d1=-b0*_rj[2]+b2*_rj[0];         d2=b0*_rj[1]-b1*_rj[0]; // x-product 2 : not normalised vector diff components.
							
							if (rfg) {_rep=o*(MIN-_angle)} // if it's within reach, the repulsive influence gets calculated.
							if (afg) {_atr=k*(_angle-0.4)}
							
							rsr=(_rep-_atr)/Math.sqrt(d0*d0+d1*d1+d2*d2);
							_fi+=d0*rsr; _fj+=d1*rsr; _fk+=d2*rsr; // the repulsive contrib vector is been updated with versor difference components multiplied by its angle and dampening factor.
						}
					}
				}
				_f[j][0]=_fi; _f[j][1]=_fj; _f[j][2]=_fk
			}
		}
		private function addUpForces ():void // Euler ODE system solver. To replace with a stable RK4 method later on.
		{
			//var a:Number;
			for (j=0;j<wo;j++)
			{
				_mj=_pArrayModel[j].pMath; _tmp1=_mj.tg; _vt=c*_mj.vtg; // fetch poly tangent versor and poly tangent magnitude multiplied by c.
				_t0=_tmp1[0]*_vt; _t1=_tmp1[1]*_vt; _t2=_tmp1[2]*_vt; // tangent versor components multiplied by their rescaled magnitude.
				
				//a=_pArrayModel[j].totalThreads; if (a>0) {if (a>4) a=0; else a=1/(a*a)} else a=1;
				
				_t0-=_f[j][0]; _t1-=_f[j][1]; _t2-=_f[j][2]; // _r += _t*v; anyway I'm not going to update it here coz _r will spontaneously come out from going thru the rotations in the PolyMath instance.
				// keep this comment! ...basic linear dynamics which doesn't apply to this case with spherical topology though: _vth=_vth*0.7-_f_array[j][0]; //_th += _vth;
				
				_vv=_t0*_t0+_t1*_t1+_t2*_t2;
				if (_vv>thr) {_vv=Math.sqrt(_vv); _rv=1/_vv; _mj.tg=Vector.<Number>([_t0*_rv,_t1*_rv,_t2*_rv]); _mj.vtg=_vv} // put new poly tangent versor back in polyMath inst only if _vv is greater than a threshold.
			}
		}
		
		// computationally intensive method : T(n)=O(n^2). (1 acos(), 3 mults, 2 sums) per pair. It finds all the mutual angles amongst Polys and fling'em all in a matrix (*) By multiplying the angle by the radius of the sphere, you get its correspondent geodesic distance (great circle) on the sphere.
		private function findMutualAngles ():void
		{
			_amx.length=0; wo=_pArrayModel.length; _amx.length=wo;
			
			for (j=0;j<wo;j++) _amx[j]=new Vector.<Number>(wo,false); // create rows. It cannot be initiated in the big for-loop below coz there're cross assignments. If it was, some assignments would address spaces not yet existing.
			
			for (j=0;j<wo;j++)
			{
				_tmp=_pArrayModel[j].pMath.n; _x1=_tmp[0]; _y1=_tmp[1]; _z1=_tmp[2];
				for (i=0;i<wo;i++)
				{
					if (j<i)
					{
						_tmp=_pArrayModel[i].pMath.n;
						_t=(_x1*_tmp[0]+_y1*_tmp[1]+_z1*_tmp[2]); // .product divided by the 2 vectors magnitudes (normalised here) = cosine of the angle between the 2 vectors. Initially I used the two origin vectors instead of the normals, but since the poligon normals overlap with the origins and are normalised, I couldn't not use them.
						if(_t>1)_t=1; if(_t<-1)_t=-1; // correct possible rounding errors to keep the values within the range [-1,1] b4 applying acos().
						_amx[j][i]=Math.acos(_t);
						
						_amx[i][j]=_amx[j][i]; // diagonal mirroring to get a symmetrical matrix
					}
				}
			}
			for (j=0;j<wo;j++) _amx[j][j]=0; // reset matrix diagonal
		}
		public function destructor():void {_mainModel=null; _pArrayModel=[]; _mj=null; _tmp.length=_tmp1.length=_amx.length=_f.length=0}
		// getters and setters (Dragger)
		public function get vdrx():Number{return _vdrx} public function set vdrx(a:Number):void{_vdrx=a}
		public function get vdry():Number{return _vdry} public function set vdry(a:Number):void{_vdry=a}
		public function get drx ():Number{return _drx}
		public function get dry ():Number{return _dry}
	}
}