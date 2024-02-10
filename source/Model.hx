package;

import Logic.TVector;
import openfl.desktop.DockIcon;
import Logic.LVector;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import sys.io.File;
import haxe.Json;

typedef Model = {
    public var vertices:Array<TVector>;
    public var edges:Array<Array<Int>>;
    public var faces:Array<Array<Int>>;
    public var raysRot:TVector;
}
class ModelHandler {
    private static var _file:FileReference;
    public static function getModelByUser() {
        _file = new FileReference();
        _file.browse([new FileFilter("Model by ShadowProjectionProgram (.mspp)", "*.mspp")]);
        _file.addEventListener(Event.SELECT, onModelBrowsed);
    }
    public static function getModel(path:String) {
        return PlayState.instance.loadModel(parseModel(File.getContent("models/" + path)), false);
    }
    private static function onModelBrowsed(_) {
        _file.load();
        PlayState.instance.loadModel(parseModel(_file.data.toString()));
		_file.removeEventListener(Event.SELECT, onModelBrowsed);
        _file = null;
    }
    private static function parseModel(data:String): Model {
        try{
            return Json.parse(data);
        }
        catch(_){
            return null;
        }
    }
    public static function saveModel() {
        _file = new FileReference();
        _file.save(Json.stringify(PlayState.instance.model), "model.mspp");
    }
}