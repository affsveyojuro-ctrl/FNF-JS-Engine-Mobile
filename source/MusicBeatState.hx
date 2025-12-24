package;

import backend.PsychCamera;
import flixel.addons.ui.FlxUIState;
import lime.app.Application;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var oldStep:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	var _psychCameraInitialized:Bool = false;

	public static var windowNameSuffix(default, set):String = "";
	public static var windowNameSuffix2(default, set):String = ""; //changes to "Outdated!" if the version of the engine is outdated
	public static var windowNamePrefix:String = "Friday Night Funkin': JS Engine";

	// better then updating it all the time which can cause memory leaks
	static function set_windowNameSuffix(value:String){
		windowNameSuffix = value;
		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2;
		return value;
	}
	static function set_windowNameSuffix2(value:String){
		windowNameSuffix2 = value;
		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2;
		return value;
	}
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables()
		return getState().variables;
	
	// this is just because FlxUIState has arguments in it's constructor
	public function new() {
		trace('called');
		#if MOBILE_CONTROLS_ALLOWED
		createMobileManager();
		#end
		trace('called');
		super();
		trace('called');
	}

	#if MOBILE_CONTROLS_ALLOWED
	public var mobileManager:MobileControlManager;
	override function destroy() {
		trace('called');
		super.destroy();
		trace('called');
		if (mobileManager != null) mobileManager.destroy();
		trace('called');
	}
	private function createMobileManager() {
		trace('called');
		if (mobileManager == null) mobileManager = new MobileControlManager(this);
		trace('called');
	}
	#end
	override function create() {
		trace('called');
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		trace('called');
		super.create();
		trace('called');

		if(!_psychCameraInitialized && !Main.isPlayState()) initPsychCamera();
		trace('called');

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		trace('called');
		FlxTransitionableState.skipNextTransOut = false;
		trace('called');

		try {windowNamePrefix = Assets.getText(Paths.txt("windowTitleBase", "preload"));}
		catch(e) {}
		trace('called');

		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2;
		trace('called');
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	override function update(elapsed:Float)
	{
		trace('called');
		oldStep = curStep;
		trace('called');

		updateCurStep();
		updateBeat();
		trace('called');

		if (oldStep != curStep && curStep > 0)
		{
			stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}
		trace('called');

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		trace('called');

		FlxG.autoPause = ClientPrefs.autoPause;
		trace('called');

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});
		trace('called');

		super.update(elapsed);
		trace('called');
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			final beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		final lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;

				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		final shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
		updateBeat();
	}

	override function startOutro(onOutroComplete:()->Void):Void
	{
		if (!FlxTransitionableState.skipNextTransIn)
		{
			openSubState(new CustomFadeTransition(0.6, false));
			CustomFadeTransition.finishCallback = onOutroComplete;
			return;
		}

		FlxTransitionableState.skipNextTransIn = false;

		onOutroComplete();
	}

	public var stages:Array<BaseStage> = [];
	//runs whenever the game hits a step
	public function stepHit():Void
	{
		//trace('Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	//runs whenever the game hits a beat
	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	//runs whenever the game hits a section
	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
