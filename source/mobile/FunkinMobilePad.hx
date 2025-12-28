package mobile;

import mobile.MobilePad;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class FunkinMobilePad extends MobilePad {
	override public function createVirtualButton(x:Float, y:Float, framePath:String, ?scale:Float = 1.0, ?ColorS:Int = 0xFFFFFF):MobileButton {
		var frames:FlxGraphic;

		final path:String = MobileConfig.mobileFolderPath + 'MobilePad/Textures/$framePath.png';
		#if MODS_ALLOWED
		final modsPath:String = Paths.modFolders('mobile/MobilePad/Textures/$framePath.png');
		if(FileSystem.exists(modsPath))
			frames = FlxGraphic.fromBitmapData(BitmapData.fromFile(modsPath));
		else #end if(Assets.exists(path))
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(path));
		else
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(MobileConfig.mobileFolderPath + 'MobilePad/Textures/default.png'));

		var button = new MobileButton(x, y);
		button.scale.set(scale, scale);
		button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));

		button.updateHitbox();
		button.updateLabelPosition();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.antialiasing = ClientPrefs.globalAntialiasing;
		button.tag = framePath.toUpperCase();

		if (ColorS != -1) button.color = ColorS;
		return button;
	}

	public function addButtonCustom(name:String, IDs:Array<String>, ?uniqueID:Int = -1, X:Float, Y:Float, Graphic:String, ?Scale:Float = 1.0, ?Color:Int = 0xFFFFFF, indexType:String = 'DPad', ?returnKey:String) {
		var button:MobileButton = new MobileButton(0, 0);
		button = createVirtualButton(X, Y, Graphic, Scale, Color);
		button.name = name;
		button.uniqueID = uniqueID;
		button.IDs = IDs;
		button.returnedKey = returnKey;
		button.onDown.callback = () -> onButtonDown.dispatch(button, IDs, uniqueID);
		button.onOut.callback = button.onUp.callback = () -> onButtonUp.dispatch(button, IDs, uniqueID);

		actions.push(button);
		add(button);
		buttonFromName.set(name, button);
		switch (indexType.toUpperCase()) {
			case 'DPAD':
				buttonIndexFromName.set(name, countedDPadIndex);
				countedDPadIndex++;
			case 'ACTION':
				buttonIndexFromName.set(name, countedActionIndex);
				countedActionIndex++;
		}
	}

	public function new(?DPad:String, ?Action:String, ?globalAlpha:Float = 0.7, ?disableCreation:Bool) {
		if (!disableCreation)
		{
			if (DPad != "NONE")
			{
				if (!MobileConfig.dpadModes.exists(DPad))
					throw 'The mobilePad dpadMode "$DPad" doesn\'t exists.';

				for (buttonData in MobileConfig.dpadModes.get(DPad).buttons)
				{
					if (buttonData.scale == null) buttonData.scale = 1.0;
					var buttonName:String = buttonData.button;
					var buttonIDs:Array<String> = buttonData.buttonIDs;
					var buttonUniqueID:Int = (buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1);
					var buttonGraphic:String = buttonData.graphic;
					var buttonScale:Float = buttonData.scale;
					var buttonColor = buttonData.color;
					var buttonX:Float = buttonData.x;
					var buttonY:Float = buttonData.y;
					var buttonReturn:String = buttonData.returnKey;

					addButtonCustom(buttonName, buttonIDs, buttonUniqueID, buttonX, buttonY, buttonGraphic, buttonScale, Util.colorFromString(buttonColor), 'DPad', buttonReturn);
				}
			}

			if (Action != "NONE")
			{
				if (!MobileConfig.actionModes.exists(Action))
					throw 'The mobilePad actionMode "$Action" doesn\'t exists.';

				for (buttonData in MobileConfig.actionModes.get(Action).buttons)
				{
					if (buttonData.scale == null) buttonData.scale = 1.0;
					var buttonName:String = buttonData.button;
					var buttonIDs:Array<String> = buttonData.buttonIDs;
					var buttonUniqueID:Int = (buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1);
					var buttonGraphic:String = buttonData.graphic;
					var buttonColor = buttonData.color;
					var buttonScale:Float = buttonData.scale;
					var buttonX:Float = buttonData.x;
					var buttonY:Float = buttonData.y;
					var buttonReturn:String = buttonData.returnKey;

					addButtonCustom(buttonName, buttonIDs, buttonUniqueID, buttonX, buttonY, buttonGraphic, buttonScale, Util.colorFromString(buttonColor), 'Action', buttonReturn);
				}
			}
		}

		super(DPad, Action, globalAlpha, true);
	}
}