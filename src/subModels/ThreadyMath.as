/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/


package subModels
{
	/**
	 *	thready geometry class
	 *	@ purpose : 3D cubic Bezier curve processing
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class ThreadyMath
	{
		private const _d:Number=0.09, _wo:Number=0.95; // loop consts
		private const _r1:Number=1300,_r2:Number=20,_r3:Number=65; // persp consts
		private const _s:Number=0.2;
		private const sv:Number=Board.sv,o:Number=Board.o; // stereo consts
		
		private var _endPoint1:Poly,_endPoint2:Poly; // these vars are disposable.
		private var _pMath1:PolyMath,_pMath2:PolyMath; // temp PolyMath instance holder.
		private var _sel:Boolean=false;
		// basic vars
		private var _xb:Number,_yb:Number,_zb:Number; // generic bezier spline point (...down the bezier curve, with parameter:t)
		private var _cx:Number,_bx:Number,_ax:Number,_cy:Number,_by:Number,_ay:Number,_cz:Number,_bz:Number,_az:Number; // curve coefficents (Basic Bezier formula method)
		private var _x:Vector.<Number>=new Vector.<Number>(4,false),_y:Vector.<Number>=new Vector.<Number>(4,false),_z:Vector.<Number>=new Vector.<Number>(4,false);
		private var _x0i:Number,_y0i:Number,_z0i:Number, _x3i:Number,_y3i:Number,_z3i:Number; // origin endpoint copy + destination endpoint copy
		private var _v1ax:Number,_v1ay:Number,_v1az:Number,_v1bx:Number,_v1by:Number,_v1bz:Number; // 1st_versors_pair 
		private var _v2ax:Number,_v2ay:Number,_v2az:Number,_v2bx:Number,_v2by:Number,_v2bz:Number; // 2nd_versors_pair
		private var _q0:Number,_q1:Number; // new   origin    endpoint coords in the mobile reference (polygon 1)
		private var _p0:Number,_p1:Number; // new destination endpoint coords in the mobile reference (polygon 2)
		// perspective projections (on the screen) + spline z-values.
		private var _pprojX:Vector.<Number>=new Vector.<Number>(), _pprojY:Vector.<Number>=new Vector.<Number>();
		private var _pprojXX:Vector.<Number>=new Vector.<Number>(); // spare one for stereoscopic view.
		private var _depths:Vector.<Number>=new Vector.<Number>();
		// misc vars
		private var _c:Vector.<Number>=new Vector.<Number>(); // generic vector
		private var _c0:Number, _c1:Number, _c2:Number;
		private var d0:Number,d1:Number,d2:Number,rsr:Number; // generic vars used in initCustomEndpoints()
		private var _ct:Number,_st:Number,_cr:Number,_sr:Number; // used in Rotation_Transf()
		private var _rp0:Number,_rp1:Number,_rp2:Number,e1:Number,e2:Number; // used in Rotation_Transf(), CalculateBezierCoefficents(),
		private var _j:Number; // used in calcPtsDownTheSpline()
		private var i:int;
		
		
		public function ThreadyMath (a:Poly, b:Poly):void {_endPoint1=a; _pMath1=_endPoint1.pMath; _endPoint2=b; _pMath2=_endPoint2.pMath; getDataFromEndpts(); initCustomEndpts()}
		public function doTheMath ():void {_pprojX.length=0; _pprojY.length=_pprojXX.length=0; _depths.length=0; globalTransf(); perspTransf()}
		private function globalTransf ():void {getDataFromEndpts(); initCustomEndpts(); moveCustomEndptsInAbsFrame(); calcBezierCoeffs()}
		private function perspTransf ():void
		{	//  1st point  :   t=0
			applyPersp(_x[0]-1,_y[0]-1,_z[0]+_r2); _depths.push(_z[0]); // it saves some work (11 mults + 3 adds in the main loop)
			//  nth points : 0<t<0.95
			for(_j=_d;_j<_wo;_j+=_d){calcSplinePt(_j); applyPersp(_xb-1,_yb-1,_zb+_r2); _depths.push(_zb)} // compute new Bezier value (_xb,_yb,_zb) due to the value of t (renamed _tmp in this case).
			//  last point :   t=1
			applyPersp(_x[3]-1,_y[3]-1,_z[3]+_r2); _depths.push(_z[3]); // it saves some work (11 mults + 3 adds in the main loop)
		}
		// init
		private function initCustomEndpts ():void // calculate two points 'near' the center as endpoints according to a rule (see whiteboard's snapshot)
		{	d0=_x[3]-_x[0]; d1=_y[3]-_y[0]; d2=_z[3]-_z[0]; rsr=1/Math.sqrt(d0*d0+d1*d1+d2*d2); // Distance (vector) between Polygons (on 1st polygon)
			_c0=d0*rsr; _c1=d1*rsr; _c2=d2*rsr; // normalised Distance (versor) (on 1st endpoint aka 1st polygon), it'll be split up in polygon versors components.
			_q0= _c0*_v1ax+_c1*_v1ay+_c2*_v1az; _q1= _c0*_v1bx+_c1*_v1by+_c2*_v1bz; // .product // (_q0,_q1) : Versor_Distance coords projected onto the rotating frame 1 = (polygon 1)
			_p0=-_c0*_v2ax-_c1*_v2ay-_c2*_v2az; _p1=-_c0*_v2bx-_c1*_v2by-_c2*_v2bz; // .product // (_p0,_p1) : Versor_Distance coords projected onto the rotating frame 2 = (polygon 2)  (the Versor Distance is reversed on the polygon2-frame)
			// now, choose the coords of origin endpoint (_q0,_q1) and destination endpoint (_p0,_p1) in the rotating frames 1 and 2.
			_q0*=_s;_q1*=_s; _p0*=_s;_p1*=_s; // make them shorter than the versor (at random)
		}
		private function getDataFromEndpts ():void 
		{
			_sel=_endPoint1.sel||_endPoint2.sel;
			if (_sel){_c=_pMath1.centre.concat(_pMath1.cpoint2.concat(_pMath2.cpoint2.concat(_pMath2.centre.concat(_pMath1.planars.concat(_pMath2.planars)))))}
			else     {_c=_pMath1.centre.concat(_pMath1.c_point.concat(_pMath2.c_point.concat(_pMath2.centre.concat(_pMath1.planars.concat(_pMath2.planars)))))}
			// four crucial points' coordinates
			_x[0]=_x0i=_c[0]; _y[0]=_y0i=_c[1]; _z[0]=_z0i=_c[2]; // origin endpoint
			_x[1]=_c[3];_y[1]=_c[4];_z[1]=_c[5]; // cpoint 1
			_x[2]=_c[6];_y[2]=_c[7];_z[2]=_c[8]; // cpoint 2
			_x[3]=_x3i=_c[9]; _y[3]=_y3i=_c[10]; _z[3]=_z3i=_c[11]; // destination endpoint
			// four polygon versors (2 + 2 versors)
			_v1ax=_c[12];_v1ay=_c[13];_v1az=_c[14]; _v1bx=_c[15];_v1by=_c[16];_v1bz=_c[17]; // 1st othonormal versors_pair - polygon 1
			_v2ax=_c[18];_v2ay=_c[19];_v2az=_c[20]; _v2bx=_c[21];_v2by=_c[22];_v2bz=_c[23]; // 2nd othonormal versors_pair - polygon 2
		}
		// global vector transformations
		private function moveCustomEndptsInAbsFrame ():void // transfers the 2 points (_q0,_q1) and (_p0,_p1) in the fixed frame
		{	_x[0]=_x0i+_q0*_v1ax+_q1*_v1bx;_y[0]=_y0i+_q0*_v1ay+_q1*_v1by;_z[0]=_z0i+_q0*_v1az+_q1*_v1bz; // new origin Endpoint coords (fixed frame)
			_x[3]=_x3i+_p0*_v2ax+_p1*_v2bx;_y[3]=_y3i+_p0*_v2ay+_p1*_v2by;_z[3]=_z3i+_p0*_v2az+_p1*_v2bz; // new destination Endpoint coords (fixed frame)
		}
		private function calcBezierCoeffs ():void 
		{	e1=_x[1]-_x[0];e2=_x[2]-_x[1]; _cx=e1+e1+e1;_bx=e2+e2+e2-_cx;_ax=_x[3]-_x[0]-_cx-_bx;
			e1=_y[1]-_y[0];e2=_y[2]-_y[1]; _cy=e1+e1+e1;_by=e2+e2+e2-_cy;_ay=_y[3]-_y[0]-_cy-_by;
			e1=_z[1]-_z[0];e2=_z[2]-_z[1]; _cz=e1+e1+e1;_bz=e2+e2+e2-_cz;_az=_z[3]-_z[0]-_cz-_bz;
		}
		// persp transformations
		private function applyPersp (xx:Number,yy:Number,zz:Number):void{e1=_r1/zz;_pprojX.push(_r3+xx*e1);_pprojY.push(_r3+yy*e1);_pprojXX.push(o+_r3+(xx-sv)*e1)} // 1300 = 65*20;  that's an optimised version of ->  80*(1+(xx-1)*20/(20+zz))
		private function calcSplinePt (t:Number):void // basic Bezier algorithm : good enough for 10 points/curve (12 multiplications/point). Recurs MidPoint one's more expensive in this case.
		{e1=t*t;e2=e1*t; _xb=_ax*e2+_bx*e1+_cx*t+_x[0];_yb=_ay*e2+_by*e1+_cy*t+_y[0];_zb=_az*e2+_bz*e1+_cz*t+_z[0]}
		
		public function destructor():void {_endPoint1=null;_endPoint2=null;_pMath1=null;_pMath2=null;_x.length=_y.length=_x.length=_pprojX.length=_pprojY.length=_pprojXX.length=_depths.length=_c.length=0}
		// getters & setters
		public function get pprojX():Vector.<Number>{return _pprojX}
		public function get pprojY():Vector.<Number>{return _pprojY}
		public function get pprojXX():Vector.<Number>{return _pprojXX}
		public function get depths():Vector.<Number>{return _depths}
		public function get sel():Boolean{return _sel}    public function set sel(a:Boolean):void{_sel=a}
	}
}