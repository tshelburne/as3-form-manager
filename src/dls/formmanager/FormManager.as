﻿/** This file is part of the FormManager package.** @author (c) Tim Shelburne <tim@dontlookstudios.com>** For the full copyright and license information, please view the LICENSE* file that was distributed with this source code.*/package dls.formmanager {		import flash.events.MouseEvent;		import dls.debugger.Debug;	import dls.formmanager.IFormManager;	import dls.formmanager.form.IForm;	import dls.formmanager.form.IFormElement;	import dls.formmanager.form.HiddenElement;	import dls.formmanager.submitter.IFormSubmitter;	import dls.formmanager.validator.IFormValidator;	import dls.formmanager.validator.errors.IValidationError;	import dls.signals.MultisignalRelay;		import org.osflash.signals.ISignal;	import org.osflash.signals.Signal;
		/*	* This manager class abstracts basic form functionality (submission and 	* validation) from where the form is used.	*/	public class FormManager implements IFormManager {				/*=========================================================*		* PROPERTIES		*=========================================================*/				private var _debugOptions:Object = { "source" : "FormManager" };				private var _forms:Vector.<IForm> = new <IForm>[];				private var _watchedElements:Vector.<IFormElement> = new <IFormElement>[];				private var _formSubmitters:Vector.<IFormSubmitter>;				private var _formValidator:IFormValidator;				private var _success:MultisignalRelay;		public function get success():ISignal {			return _success;		}				private var _submissionError:MultisignalRelay;		public function get submissionError():ISignal {			return _submissionError;		}				private var _validationError:Signal = new Signal(Vector.<IValidationError>);		public function get validationError():ISignal {			return _validationError;		}				/*=========================================================*		* FUNCTIONS		*=========================================================*/				public function FormManager(formSubmitters:Vector.<IFormSubmitter>, formValidator:IFormValidator) {			_formSubmitters = formSubmitters;			_formValidator = formValidator;						_success = new MultisignalRelay();			_submissionError = new MultisignalRelay();			for each (var submitter:IFormSubmitter in _formSubmitters) {				_success.addSignal(submitter.success);				_submissionError.addSignal(submitter.error);			}		}				/**		 * begin managing the form submitted		 */		public function manageForm(form:IForm):void {			if (_forms.indexOf(form) < 0) {				_forms.push(form);				form.submitForm.add( function(e:MouseEvent):void { submitForm(form); } );			}		}				/**		 * cease manageing the form of the given name		 */		public function removeForm(form:IForm):void {			if (_forms.indexOf(form) >= 0) {				_forms.splice(_forms.indexOf(form), 1);				form.submitForm.removeAll();			}		}				/**		 * helper function to check a single element's validity		 * 		 * TODO: find out why clearValidationErrors() isn't working on HiddenElement's. this is a temporary fix to address it.		 */		public function validateElement(element:IFormElement):Vector.<IValidationError> {			Debug.out("Validating element " + element.name + " with value " + element.value + "...", Debug.DETAILS, _debugOptions);			var errors:Vector.<IValidationError> = _formValidator.validateElement(element);						if (!(element is HiddenElement)) {								element.clearValidationErrors();				if (errors.length > 0) {					watchElement(element);					for each (var error:IValidationError in errors) {						element.addValidationError(error);					}				}			}						return errors;		}				/**		 * helper function to check a single form's validity		 */		public function validateForm(form:IForm):Vector.<IValidationError> {			var errors:Vector.<IValidationError> = new <IValidationError>[];						for each (var element:IFormElement in form.allElements) {				errors = errors.concat(validateElement(element));			}						return errors;		}				/**
		 * add a listener on an element's value for auto-validation
		 */		public function watchElement(element:IFormElement):void {			if (_watchedElements.indexOf(element) == -1) {				_watchedElements.push(element);								element.valueChanged.add(validateElement);			}		}				/**
		 * remove the listener on an element's value for auto-validation
		 */		public function stopWatchingElement(element:IFormElement):void {			if (_watchedElements.indexOf(element) != -1) {				_watchedElements.splice(_watchedElements.indexOf(element), 1);								element.valueChanged.remove(validateElement);			}		}				/**		 * handle submitting and relaying the response for the given form		 */		public function submitForm(form:IForm):void {			Debug.out("Validating form...", Debug.ACTIONS, _debugOptions);			var errors:Vector.<IValidationError> = validateForm(form);						if (errors.length == 0) {				for each (var element:IFormElement in form.allElements) {					stopWatchingElement(element);				}				for each (var submitter:IFormSubmitter in _formSubmitters) {					if (submitter.canSubmit(form)) {						Debug.out("Submitting form...", Debug.ACTIONS, _debugOptions);						submitter.submit(form);						break;					}				}			}			else {				Debug.out("Validation errors...", Debug.ACTIONS, _debugOptions);				_validationError.dispatch(errors);			}		}			}	}