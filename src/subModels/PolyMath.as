/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package subModels
{	/**
	 *	Poly geometry class
	 *	@ purpose : local polygon geometry processing
	 *  author : Ivano Ras, Nov 2010, ivano.ras@gmail.com
	 */
	public class PolyMath
	{
		private const _3rd:Number=0.333333333333333333, _cpi:Number=-.4, _cpe:Number=1.8;
		private const _l0:Number=0,_l1:Number=0.5,_l2:Number=-0.86602540378; // light versor components
		private const _p1:Number=1300,_p2:Number=20,_p3:Number=65; // persp consts
		private const t:Number=0.0001,s:Number=-t; // thresholds
		private const sv:Number=Board.sv, o:Number=Board.o; // stereoscopic consts
		
		private var _mainModel:IV2Model, _poly:Poly;
		private var _X:Vector.<Number>,_Y:Vector.<Number>,_Z:Vector.<Number>; // fixed frame poligon coords list.
		private var _x:Vector.<Number>=new Vector.<Number>(),_y:Vector.<Number>=new Vector.<Number>(),_z:Vector.<Number>=new Vector.<Number>(); // local (moving) frame poligon coords list.
		private var _t:Vector.<Number>=new Vector.<Number>(3,false),_b:Vector.<Number>=new Vector.<Number>(3,false),_n:Vector.<Number>=new Vector.<Number>(3,false);// local (moving) frame versors (tangent, binormal, normal) components
		private var _r:Vector.<Number>=new Vector.<Number>(3,false),_pr:Vector.<Number>=new Vector.<Number>(3,false),_dr:Vector.<Number>=new Vector.<Number>(3,false);// _r joins the fixed frame origin to moving frame origin, _pr[] is the prev pos _dr[]=_r[]-_pr[] is the displacement.
		private var _r_mag:Number,_rsr:Number,_t_mag:Number=0; // _r_mag=_r magnitude, _rsr=1/_r_mag, _t_mag=_t magnitude.
		private var _u:Vector.<Number>=new Vector.<Number>(),_v:Vector.<Number>=new Vector.<Number>(),_w:Vector.<Number>=new Vector.<Number>(); // temp wrapper_frame poligon coords list (frame where the eulerWrapperRotate() "trackball rotation" is applied to)
		private var _ro:Vector.<Number>=new Vector.<Number>(3,false), _no:Vector.<Number>=new Vector.<Number>(3,false), _to:Vector.<Number>=new Vector.<Number>(3,false), _bo:Vector.<Number>=new Vector.<Number>(3,false), _bo0:Number,_bo1:Number,_bo2:Number;//temp wrapper_frame versors;
		private var _pprojX:Vector.<Number>=new Vector.<Number>(),_pprojY:Vector.<Number>=new Vector.<Number>(),_pprojXX:Vector.<Number>=new Vector.<Number>(); // persp projections (on the screen) plus a spare stereoscopic view.
		// euler rotation vars
		private var _ct:Number=1,_st:Number=0,_cr:Number=1,_sr:Number=0;
		// dynamics vars
		private var _th:Number,_ph:Number,_vth:Number,_vph:Number; // angles and angular velocities across the sphere
		private var _s:Number=0,_shade:int; // slide parameter and facet colour
		// temp vars
		private var _tm:Number,_tn:Number,c1:Number,c2:Number;
		private var i:int,j:int,wo:int;
		private var d0:Number,d1:Number,d2:Number, rsr:Number; // reciprocal of square root
		private var q:Number,w:Number,e:Number;
		private var _c:Number;
		private var _cptn:Vector.<Number>=new Vector.<Number>(3,false), _plns:Vector.<Number>=new Vector.<Number>(6,false); // vectors for ThreadyMath objs
		
		
		public function PolyMath (m:IV2Model,n:Poly,ax:Vector.<Number>,ay:Vector.<Number>,az:Vector.<Number>):void {_mainModel=m; _poly=n; _X=ax; _Y=ay; _Z=az; concavityTest(); _poly.vth=_poly.vph=0}
		public function doTheMath ():void {_pprojX.length=_pprojY.length=_pprojXX.length=0; globalTransf(); perspTransf(); getThreadyVectsReady()}
		private function globalTransf ():void
		{
			_vth=_poly.vth; _vph=-_poly.vph;
			if (!_poly.isDragged) eulerLocalRotate(Math.cos(_t_mag),Math.sin(_t_mag));
			else eulerGlobalRotate(Math.cos(_vth),Math.sin(_vth),Math.cos(-_vph),Math.sin(-_vph));
			
			findCentreAndNormal(); findTBversors(); // tangent and binormal versors (lying on the polygon) are used by Thready objs to get right the junctions positions behind the poligon.
			
			findShade(); // poligon shade
		}
		private function perspTransf ():void 
		{
			_tm=_mainModel.globDyn.drx; _tn=-_mainModel.globDyn.dry;
			eulerWrapperRotate(Math.cos(_tm), Math.sin(_tm), Math.cos(_tn), Math.sin(_tn));
			
			applyPersp (_ro[0]-1,_ro[1]-1,_ro[2]+_p2); // centre
			applyPersp (_no[0]-1,_no[1]-1,_no[2]+_p2); // normal
			applyPersp (_to[0]-1,_to[1]-1,_to[2]+_p2); // tangent
			wo=_X.length; for(i=0;i<wo;i++){applyPersp(_u[i]-1,_v[i]-1,_w[i]+_p2)} // polygon vertices
		}
		// basic vector transformations
		private function glob2locCoords ():void {wo=_X.length; for(i=0;i<wo;i++){_x[i]=_X[i]*_t[0]+_Y[i]*_t[1]+_Z[i]*_t[2];_y[i]=_X[i]*_b[0]+_Y[i]*_b[1]+_Z[i]*_b[2];_z[i]=_X[i]*_n[0]+_Y[i]*_n[1]+_Z[i]*_n[2]}}
		private function loc2globCoords ():void {wo=_X.length; for(i=0;i<wo;i++){_X[i]=_x[i]*_t[0]+_y[i]*_b[0]+_z[i]*_n[0];_Y[i]=_x[i]*_t[1]+_y[i]*_b[1]+_z[i]*_n[1];_Z[i]=_x[i]*_t[2]+_y[i]*_b[2]+_z[i]*_n[2]}}
		private function eulerLocalRotate (a:Number,b:Number):void
		{
			glob2locCoords(); // local rotation to avoid gimbal lock.
			_ct=a; _st=b; wo=_X.length;
			for(i=0;i<wo;i++) {c1=_x[i]; c2=_z[i]; _x[i]=c1*_ct-c2*_st; _z[i]=c1*_st+c2*_ct} // Rot
			loc2globCoords();
		}
		private function eulerWrapperRotate (a:Number,b:Number,c:Number,d:Number):void
		{
			_ct=a; _st=b; _cr=c; _sr=d; wo=_X.length;
			for(i=0;i<wo;i++) {c1=_X[i]; c2=_Z[i]; _u[i]=c1*_ct-c2*_st; _w[i]=c1*_st+c2*_ct} // rotate horiz
			for(i=0;i<wo;i++) {c1=_w[i]; c2=_Y[i]; _w[i]=c1*_cr-c2*_sr; _v[i]=c1*_sr+c2*_cr} // rotate vert
			
			c1=_r[0]; c2=_r[2];_ro[0]=c1*_ct-c2*_st;_ro[2]=c1*_st+c2*_ct;
			c1=_ro[2];c2=_r[1];_ro[2]=c1*_cr-c2*_sr;_ro[1]=c1*_sr+c2*_cr; // centre
			
			c1=_n[0]; c2=_n[2];_no[0]=c1*_ct-c2*_st;_no[2]=c1*_st+c2*_ct;
			c1=_no[2];c2=_n[1];_no[2]=c1*_cr-c2*_sr;_no[1]=c1*_sr+c2*_cr; // normal
			
			c1=_t[0]; c2=_t[2];_to[0]=c1*_ct-c2*_st;_to[2]=c1*_st+c2*_ct;
			c1=_to[2];c2=_t[1];_to[2]=c1*_cr-c2*_sr;_to[1]=c1*_sr+c2*_cr; // tangent
			
			c1=_b[0]; c2=_b[2];_bo[0]=c1*_ct-c2*_st;_bo[2]=c1*_st+c2*_ct;
			c1=_bo[2];c2=_b[1];_bo[2]=c1*_cr-c2*_sr;_bo[1]=c1*_sr+c2*_cr; // binormal
		}
		private function eulerGlobalRotate (a:Number,b:Number,c:Number,d:Number):void
		{
			_ct=a; _st=b; _cr=c; _sr=d; wo=_X.length;
			for(i=0;i<wo;i++) {c1=_Z[i]; c2=_Y[i]; _Z[i]=c1*_cr-c2*_sr; _Y[i]=c1*_sr+c2*_cr} // rotate vert
			for(i=0;i<wo;i++) {c1=_X[i]; c2=_Z[i]; _X[i]=c1*_ct-c2*_st; _Z[i]=c1*_st+c2*_ct} // rotate horiz
		}
		// misc transformations
		public function slidingOutwards():void {_s=_mainModel.slider; d0=_n[0]*_s; d1=_n[1]*_s; d2=_n[2]*_s; wo=_X.length; for (i=0;i<wo;i++) {_X[i]+=d0;_Y[i]+=d1;_Z[i]+=d2}}
		public function resize (a:Number):void {wo=_X.length; for(i=0;i<wo;i++){_X[i]=(_X[i]-_r[0])*a+_r[0]; _Y[i]=(_Y[i]-_r[1])*a+_r[1]; _Z[i]=(_Z[i]-_r[2])*a+_r[2]}}
		// persp transformations
		private function applyPersp (xx:Number,yy:Number,zz:Number):void {_c=_p1/zz;_pprojX.push(_p3+xx*_c);_pprojY.push(_p3+yy*_c);_pprojXX.push(o+_p3+(xx-sv)*_c)} // 1300 = 65*20; that's an optimised version of ->  80*(1+(xx-1)*20/(20+zz))
		// misc methods
		private function findCentreAndNormal ():void
		{
			if (!_poly.pShape){q=(_X[0]+_X[1]+_X[2])*_3rd; w=(_Y[0]+_Y[1]+_Y[2])*_3rd; e=(_Z[0]+_Z[1]+_Z[2])*_3rd } // triangular case
			else              {q=(_X[0]+_X[4]+_X[8])*_3rd; w=(_Y[0]+_Y[4]+_Y[8])*_3rd; e=(_Z[0]+_Z[4]+_Z[8])*_3rd } // circular case
			_r_mag=Math.sqrt(q*q+w*w+e*e); _rsr=1/_r_mag;
			_r=Vector.<Number>([q,w,e]); _n=Vector.<Number>([q*_rsr,w*_rsr,e*_rsr]);
		}
		private function findTBversors ():void
		{
			d0=_pr[0]-_r[0]; d1=_pr[1]-_r[1]; d2=_pr[2]-_r[2];
			if((d0<s)||(d0>t)||(d1<s)||(d1>t)||(d2<s)||(d2>t))
			{
				_dr.length=0; _dr.push(d0,d1,d2); // vector difference between actual vector _r and previous one: _pr
				d0=_n[1]*_dr[2]-_n[2]*_dr[1]; d1=-_n[0]*_dr[2]+_n[2]*_dr[0]; d2=_n[0]*_dr[1]-_n[1]*_dr[0]; rsr=1/Math.sqrt(d0*d0+d1*d1+d2*d2);
				_b.length=0; _b.push(d0*rsr,d1*rsr,d2*rsr); // binormal components, orthogonal to both _n and _t (_t is calculated right below)
				_t.length=0; _t.push(_b[1]*_n[2]-_b[2]*_n[1],-_b[0]*_n[2]+_b[2]*_n[0],_b[0]*_n[1]-_b[1]*_n[0]); // tangent components
				_pr=_r; // save _r for next frame
			}
		}
		private function findB ():void {_b.length=0; _b.push(_n[1]*_t[2]-_n[2]*_t[1],-_n[0]*_t[2]+_n[2]*_t[0],_n[0]*_t[1]-_n[1]*_t[0])}
		private function concavityTest ():void // CONCAVITY TEST - test and set all the polygons facing outwards. This test is triangle-specific and also because the vectors _r and _n are overlapped
		{   // centre
			if (!_poly.pShape){q=(_X[0]+_X[1]+_X[2])*_3rd; w=(_Y[0]+_Y[1]+_Y[2])*_3rd; e=(_Z[0]+_Z[1]+_Z[2])*_3rd } // triangular case
			else              {q=(_X[0]+_X[4]+_X[8])*_3rd; w=(_Y[0]+_Y[4]+_Y[8])*_3rd; e=(_Z[0]+_Z[4]+_Z[8])*_3rd } // circular case
			_r_mag=Math.sqrt(q*q+w*w+e*e); _rsr=1/_r_mag;
			_r[0]=q;_r[1]=w;_r[2]=e;  _pr[0]=_r[0]+0.5;_pr[1]=_r[1]+0.5;_pr[2]=_r[2]+0.5; // also added a random value to the previous versor in order to initialise it.
			// normal (x_product of vectors difference).
			if (!_poly.pShape) // TRIANGLE case.
			{d0=(_Y[1]-_Y[0])*(_Z[2]-_Z[0])-(_Y[2]-_Y[0])*(_Z[1]-_Z[0]); d1=-(_X[1]-_X[0])*(_Z[2]-_Z[0])+(_X[2]-_X[0])*(_Z[1]-_Z[0]); d2=(_X[1]-_X[0])*(_Y[2]-_Y[0])-(_X[2]-_X[0])*(_Y[1]-_Y[0])}
			else // CIRCLE case.
			{d0=(_Y[4]-_Y[0])*(_Z[8]-_Z[0])-(_Y[8]-_Y[0])*(_Z[4]-_Z[0]); d1=-(_X[4]-_X[0])*(_Z[8]-_Z[0])+(_X[8]-_X[0])*(_Z[4]-_Z[0]); d2=(_X[4]-_X[0])*(_Y[8]-_Y[0])-(_X[8]-_X[0])*(_Y[4]-_Y[0])}
			rsr=1/Math.sqrt(d0*d0+d1*d1+d2*d2); _n=Vector.<Number>([d0*rsr,d1*rsr,d2*rsr]);
			
			// concavity test
			var d:Vector.<Number>=Vector.<Number>([_r[0]+_n[0],_r[1]+_n[1],_r[2]+_n[2]]);
			if ((d[0]*d[0]+d[1]*d[1]+d[2]*d[2])<=1)
			{_n=Vector.<Number>([-_n[0],-_n[1],-_n[2]]); _X=Vector.<Number>([_X[0],_X[2],_X[1]]); _Y=Vector.<Number>([_Y[0],_Y[2],_Y[1]]); _Z=Vector.<Number>([_Z[0],_Z[2],_Z[1]])} // flip the normal and swap the order in the last 2 points' coords so the normal spontaneously sticks outwardly
			findTBversors ();
		}
		private function findAngles ():void {_th=Math.atan2(_r[1],_r[0]);_ph=Math.acos(_r[2]*_rsr)}// angles theta and phi of _r in the fixed frame (latitude, longitude)
		private function findShade ():void
		{
			d0=Math.floor((_l0*_n[0]+_l1*_n[1]+_l2*_n[2])*225); // .product (_light,_n)
			if(d0<0){d0=-d0} _shade=int(d0)+int(d0<<8)+int(d0<<16); // analogous to doing: d0+25 + d0*256 + d0*65536
		}
		// shape transformations
		public function changeTriangleToCircle():void
		{
			if (!_poly.pShape)
			{	_poly.pShape=true; // toggle to circular shape (dodecagon)
				var x0f:Number,y0f:Number,z0f:Number,x1f:Number,y1f:Number,z1f:Number,x2f:Number,y2f:Number,z2f:Number; // Triangle Coordinates shifted with respect to the rotating frame's centre.
				x0f=_X[0]-_r[0];y0f=_Y[0]-_r[1];z0f=_Z[0]-_r[2]; x1f=_X[1]-_r[0];y1f=_Y[1]-_r[1];z1f=_Z[1]-_r[2]; x2f=_X[2]-_r[0];y2f=_Y[2]-_r[1];z2f=_Z[2]-_r[2]; // P0, P1, P2
				var x01f:Number,y01f:Number,z01f:Number,x02f:Number,y02f:Number,z02f:Number,x21f:Number,y21f:Number,z21f:Number;
				x01f=-x2f;y01f=-y2f;z01f=-z2f;  x02f=-x1f;y02f=-y1f;z02f=-z1f;  x21f=-x0f;y21f=-y0f;z21f=-z0f; // P01=-P2;  P02=-P1;   P21=-P0;
				var x001:Number,y001:Number,z001:Number,x011:Number,y011:Number,z011:Number,x121:Number,y121:Number,z121:Number,x212:Number,y212:Number,z212:Number,x202:Number,y202:Number,z202:Number,x020:Number,y020:Number,z020:Number;
				var cn:Number=0.5*1.15;  // the factor 1.15 makes the vector a little longer to lay on circle.
				x001=(x01f+x0f)*cn; y001=(y01f+y0f)*cn; z001=(z01f+z0f)*cn; // P001 = mid (P0,P01) + a bit
				x011=(x01f+x1f)*cn; y011=(y01f+y1f)*cn; z011=(z01f+z1f)*cn; // P011 = mid (P01,P1) + a bit
				x121=(x21f+x1f)*cn; y121=(y21f+y1f)*cn; z121=(z21f+z1f)*cn; // P011 = mid (P21,P1) + a bit
				x212=(x21f+x2f)*cn; y212=(y21f+y2f)*cn; z212=(z21f+z2f)*cn; // P212 = mid (P2,P21) + a bit
				x202=(x02f+x2f)*cn; y202=(y02f+y2f)*cn; z202=(z02f+z2f)*cn; // P202 = mid (P2,P02) + a bit
				x020=(x02f+x0f)*cn; y020=(y02f+y0f)*cn; z020=(z02f+z0f)*cn; // P020 = mid (P02,P0) + a bit
				// now, transformed values r gonna get back into the rotating frame Array.
				_X.length=_Y.length=_Z.length=12;// (*) as3 vectors need to have their new length specified when changing.
				//_X[0]=_X[0];    _Y[0]=_Y[0];      _Z[0]=_Z[0]  // P0 • skipped since it's a redundant op.
				_X[4]=_X[1];      _Y[4]=_Y[1];      _Z[4]=_Z[1]; // P1 • assignment got past down the line to avoid reassignments.
				_X[8]=_X[2];      _Y[8]=_Y[2];      _Z[8]=_Z[2]; // P2 • assignment got past down the line to avoid reassignments.
				_X[1]=x001+_r[0]; _Y[1]=y001+_r[1]; _Z[1]=z001+_r[2]; // P001
				_X[2]=x01f+_r[0]; _Y[2]=y01f+_r[1]; _Z[2]=z01f+_r[2]; // P01
				_X[3]=x011+_r[0]; _Y[3]=y011+_r[1]; _Z[3]=z011+_r[2]; // P011
				_X[5]=x121+_r[0]; _Y[5]=y121+_r[1]; _Z[5]=z121+_r[2]; // P121
				_X[6]=x21f+_r[0]; _Y[6]=y21f+_r[1]; _Z[6]=z21f+_r[2]; // P21
				_X[7]=x212+_r[0]; _Y[7]=y212+_r[1]; _Z[7]=z212+_r[2]; // P212
				_X[9]=x202+_r[0]; _Y[9]=y202+_r[1]; _Z[9]=z202+_r[2]; // P202
				_X[10]=x02f+_r[0];_Y[10]=y02f+_r[1];_Z[10]=z02f+_r[2]; // P02
				_X[11]=x020+_r[0];_Y[11]=y020+_r[1];_Z[11]=z020+_r[2]; // P020
			} else trace ("! It's already a Circle");
		}
		public function changeCircleToTriangle():void {if(_poly.pShape){_poly.pShape=false;_X=Vector.<Number>([_X[0],_X[4],_X[8]]);_Y=Vector.<Number>([_Y[0],_Y[4],_Y[8]]);_Z=Vector.<Number>([_Z[0],_Z[4],_Z[8]])} else trace("! It's already a Triangle")}
		
		private function getThreadyVectsReady():void
		{_cptn.length=_plns.length=0; _plns=_to.concat(_bo); _cptn.push(_cpi*_no[0]+_ro[0],_cpi*_no[1]+_ro[1],_cpi*_no[2]+_ro[2])}
		public function destructor():void{_mainModel=null;_poly=null;_X.length=_Y.length=_Z.length=_x.length=_y.length=_z.length=_t.length=_b.length=_n.length=_r.length=_pr.length=_dr.length=_u.length=_v.length=_w.length=_ro.length=_no.length=_to.length=_bo.length=_pprojX.length=_pprojY.length=_pprojXX.length=_cptn.length=_plns.length=0}
		// getters & setters
		public function get moreData():Vector.<Number>{return Vector.<Number>([_shade,_ro[2]])}
		public function get pprojX ():Vector.<Number>{return _pprojX}
		public function get pprojY ():Vector.<Number>{return _pprojY}
		public function get pprojXX():Vector.<Number>{return _pprojXX} // additional X vector for stereo view
		// getters for ThreadyMath instance (wrapped values, not real ones!)
		public function get planars():Vector.<Number>{return _plns} // tangent joined to binormal
		public function get c_point():Vector.<Number>{return _cptn}
		public function get cpoint2():Vector.<Number>{return Vector.<Number>([_cpe*_no[0]+_ro[0],_cpe*_no[1]+_ro[1],_cpe*_no[2]+_ro[2]])}
		public function get centre ():Vector.<Number>{return _ro}
		public function get normal ():Vector.<Number>{return _no}
		// getters for GlobalDynamics instance
		public function get r_mag ():Number{return _r_mag}
		public function get r():Vector.<Number>{return _r}
		public function get n():Vector.<Number>{return _n}
		public function get tg():Vector.<Number>{return _t} public function set tg(a:Vector.<Number>):void{_t=a; findB()}
		public function get vtg():Number{return _t_mag}     public function set vtg(a:Number):void{_t_mag=a}
	}
}