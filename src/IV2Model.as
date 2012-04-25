/*
Copyright (c) 2012 Ivano Ras, ivano.ras@gmail.com

See the file license.txt for copying permission.
*/

package
{
	import flash.events.IEventDispatcher;
	
	import subModels.*;
	import subModels.globalTransitions.*;
	
	public interface IV2Model extends IEventDispatcher
	{
		function KickOff ():void
		function setSubModelsList (p:Array, t:Array):void
		function destructor():void
		// Setter and Getters
		function get globDyn ():GlobalDynamics
		
		function get totalSubViewObjs ():int
		function get slider     ():Number
		function set slider     (a:Number):void
		function get pArray     ():Array
		
		function get trans01Flag ():Boolean
		function set trans01Flag (a:Boolean):void
		function set trans01     (a:V2Transition01):void
		function get trans12Flag ():Boolean
		function set trans12Flag (a:Boolean):void
		function set trans12     (a:V2Transition12):void
		
		function set energySaver (a:Boolean):void
		function get energySaver ():Boolean
	}
}