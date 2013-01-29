﻿/* * This file is part of the FormManager package. * * @author (c) Tim Shelburne <tim@dontlookstudios.com> * * For the full copyright and license information, please view the LICENSE * file that was distributed with this source code. */package dls.formmanager.form {		import dls.debugger.Debug;	import dls.formmanager.form.Fieldset;	import dls.formmanager.form.HiddenElement;	import dls.formmanager.form.IForm;	import dls.formmanager.form.IFormButton;	import dls.formmanager.form.IFormElement;	import dls.signals.ISignalRelay;	import dls.signals.SignalRelay;
		/*	 * The Form class is used to represent a form structured similarly to an HTML form. It	 * is used in the FormManager as a container for all information related to the form	 * itself.	 */	public class Form implements IForm {				/*=========================================================*		 * PROPERTIES		 *=========================================================*/				private var _debugOptions:Object = { "source" : "FormManager (Form)" };				// ~~~ variables ~~~ //				private var _action:String;		public function get action():String {			return _action;		}				private var _method:String;		public function get method():String {			return _method;		}				private var _submitType:String;		public function get submitType():String {			return _submitType;		}				private var _elements:Vector.<IFormElement> = new <IFormElement>[];				private var _hiddenElements:Vector.<HiddenElement> = new <HiddenElement>[];				public function get allElements():Vector.<IFormElement> {			var totalElements:Vector.<IFormElement> = this.freeElements;						for each (var fieldset:Fieldset in _fieldsets) {				totalElements = totalElements.concat(fieldset.allElements);			}						return totalElements;		}				public function get allElementsWithNames():Object {			var elements:Object = _elements;						for each (var element:HiddenElement in _hiddenElements) {				elements[element.name] = element;			}						for each (var fieldset:Fieldset in _fieldsets) {				var fieldsetElements:Object = fieldset.allElementsWithNames;				for (var name:String in fieldsetElements) {					elements[name] = fieldsetElements[name];				}			}						return elements;		}				private function get freeElements():Vector.<IFormElement> {			var elements:Vector.<IFormElement> = new <IFormElement>[];			for each (var element:IFormElement in _elements) {				elements.push(element);			}			return elements.concat(_hiddenElements);		}				private var _fieldsets:Vector.<Fieldset> = new <Fieldset>[];				private var _submitButton:IFormButton;		public function get submitButton():IFormButton {			return _submitButton;		}				private var _submitForm:SignalRelay;		public function get submitForm():ISignalRelay {			return _submitForm;		}				/*=========================================================*		 * FUNCTIONS		 *=========================================================*/		public function Form(aAction:String, fieldsetNames:Vector.<String> = null, aSubmitButton:IFormButton = null, aMethod:String = "POST", aSubmitType:String = "simple") {			_action = aAction;			_method = aMethod;			_submitType = aSubmitType;						if (aSubmitButton != null) {				_submitButton = aSubmitButton;				_submitForm = new SignalRelay(_submitButton.click);			}						for each (var fieldsetName:String in fieldsetNames) {				_fieldsets.push(new Fieldset(fieldsetName));			}		}		/**		 * add a single element to the form		 *		 * @param - the element to be added		 * @param (optional) - the fieldset to add this element to		 */		public function addElement(element:IFormElement, fieldsetName:String = null, name:String = null):void {			var elementName:String = name != null ? name : element.name;			if (fieldsetName == null) {				Debug.out("Adding element " + elementName + "...", Debug.DEBUG, _debugOptions);				if (!elementWithNameExists(elementName)) {					_elements[elementName] = element;				}				else {					throw new Error("A form element with the name '" + elementName + "' already exists.");				}			}			else {				findFieldsetByName(fieldsetName).addElement(element, elementName);			}		}				/**		 * add multiple elements to the form		 *		 * @param - the elements to be added		 * @param (optional) - the fieldset to add these elements to		 */		public function addElements(elements:Vector.<IFormElement>, fieldsetName:String = null):void {			for each (var element:IFormElement in elements) {				addElement(element, fieldsetName);			}		}				/**
		 * remove an element from the form		 * 		 * @param - the element to be removed		 * @param (optional) - the fieldset to remove the element from
		 */		public function removeElement(element:IFormElement, fieldsetName:String = null):void {			if (fieldsetName != null) {				findFieldsetByName(fieldsetName).removeElement(element);			}			else {				for (var name:String in _elements) {					if (_elements[name] == element) { 						delete _elements[name];					}				}			}		}				/**		 * add an element to the form that doesn't need user interaction		 *		 * @param - the name of the element to be added		 * @param - the value of the element to be added		 * @param (optional) - the fieldset to add the element to		 */		public function addHiddenElement(name:String, value:*, fieldsetName:String = null):void {			if (fieldsetName == null) {				Debug.out("Adding hidden element " + name + " with value " + value + "...", Debug.DEBUG, _debugOptions);				if (!elementWithNameExists(name)) {					_hiddenElements.push(new HiddenElement(name, value));				}				else {					throw new Error("A form element with the name '" + name + "' already exists.");				}			}			else {				findFieldsetByName(fieldsetName).addHiddenElement(new HiddenElement(name, value));			}		}				/**		 * add multiple elements to the form which don't need user interaction		 *		 * @param - an array of objects of the form { "name":"", "value":"" }		 * @param (optional) - the fieldset to add elements to		 */		public function addHiddenElements(elementObjects:Vector.<Object>, fieldsetName:String = null):void {			for each (var elementObj:Object in elementObjects) {				if (elementObj.hasOwnProperty("name") && elementObj.hasOwnProperty("value")) {					addHiddenElement(elementObj.name, elementObj.value, fieldsetName);				}				else {					throw new Error("Each element in the hidden elements list must contain 'name' and 'value' properties.");				}			}		}				/**		 * update a hidden element with a new value		 *		 * @param - the name of the element to be updated		 * @param - the new value of the element to be updated with		 * @param (optional) - the fieldset containing the element		 */		public function updateHiddenElement(name:String, value:*, fieldsetName:String = null):void {			if (fieldsetName != null) {				findFieldsetByName(fieldsetName).updateHiddenElement(name, value);			}			else {				Debug.out("Updating hidden element " + name + " with value " + value + "...", Debug.DEBUG, _debugOptions);				var elementExists:Boolean = false;				for each (var element:HiddenElement in _hiddenElements) {					if (element.name == name) {						elementExists = true;						element.resetValue(value);						break;					}				}								if (!elementExists) {					addHiddenElement(name, value);				}			}		}				/**		 * clear out all the hidden elements in the form (including fieldsets)		 */		public function clearHiddenElements():void {			_hiddenElements = new <HiddenElement>[];						for each (var fieldset:Fieldset in _fieldsets) {				fieldset.clearHiddenElements();			}		}				/**		 * get an object represent the name / value pairs for this form		 */		public function getValuesObject():Object {			var pairs:Object = {};			for each (var element:IFormElement in this.freeElements) {				pairs[element.name] = element.value.toString();			}						for each (var fieldset:Fieldset in _fieldsets) {				var fieldsetPairs:Object = fieldset.getValuesObject();				for (var elementName:String in fieldsetPairs) {					pairs[elementName]= fieldsetPairs[elementName];				}			}						return pairs;		}				/**		 * returns true if an element with the given name is already in the element list		 */		private function elementWithNameExists(name:String):Boolean {			return this.allElementsWithNames[name] != undefined;		}				/**		 * returns true if the given element is already in the element list		 */		private function elementExists(element:IFormElement):Boolean {			for each (var presentElement:IFormElement in this.allElements) {				if (presentElement == element) {					return true;				}			}			return false;		}				/**		 * find a fieldset by its name		 */		private function findFieldsetByName(fieldsetName:String):Fieldset {			for each (var fieldset:Fieldset in _fieldsets) {				if (fieldset.name == fieldsetName) {					return fieldset;				}			}						throw new Error("Fieldset '" + fieldsetName + "' does not exist.");			return null;		}			}	}