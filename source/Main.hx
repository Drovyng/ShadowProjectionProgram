package;

import Logic.LVector;
import Options.OptionsHandler;
import Model.ModelHandler;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, PlayState, 60, 60, true));

		FlxG.console.registerClass(PlayState);
		FlxG.console.registerClass(LVector);
		FlxG.console.registerClass(Logic);
		FlxG.console.registerClass(ModelHandler);
		FlxG.console.registerClass(OptionsHandler);
	}
}