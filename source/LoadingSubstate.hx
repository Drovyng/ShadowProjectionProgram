import flixel.FlxG;
import flixel.FlxCamera;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUISubState;

class LoadingSubstate extends FlxUISubState {

    public static var onEnd:Void->Void;

    public var timer:Float = 1;
    public var isPre:Bool;

    public var background:FlxSprite;
    public var backgroundCamera:FlxCamera;

    public function new(_isPre:Bool) {
        super();

        isPre = _isPre;
    }
    override function create() {
        super.create();

        backgroundCamera = new FlxCamera();
        backgroundCamera.bgColor.alpha = 0;
        FlxG.cameras.add(backgroundCamera);

        background = new FlxSprite().loadGraphic(new LoadingBitmapData(0, 0));
        background.scrollFactor.set();
        add(background);
        background.cameras = [backgroundCamera];

        background.alpha = isPre ? 0 : 1;
    }
    override function update(elapsed:Float) {
        super.update(elapsed);

        timer -= elapsed * 2;
        if (timer <= 0)
        {
            onEnd();
            close();
            return;
        }
        background.alpha = isPre ? 1 - timer : timer;
    }
}
@:bitmap("../assets/Loading.png") class LoadingBitmapData extends BitmapData { }