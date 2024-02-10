import haxe.Json;
import sys.io.File;

typedef Options = {
    public var axisColored:Bool;
    public var drawGrid:Bool;
    public var drawVertsChars:Bool;

    public var drawVertices:Bool;
    public var drawEdges:Bool;
    public var drawFaces:Bool;
    public var drawColoredFaces:Bool;

    public var drawShadowRays:Bool;
    public var drawShadowVertices:Bool;
    public var drawShadowEdges:Bool;
    public var drawShadowFaces:Bool;
    public var drawShadowColoredFaces:Bool;
}
class OptionsHandler {
    public static var instance:Options;

    public static function load() {
        try{
            instance = Json.parse(File.getContent("options"));
            if (instance == null){
                throw "";
            }
        }
        catch (_){
            instance = {
                axisColored: true,
                drawGrid: true,
                drawVertsChars: true,
            
                drawVertices: true,
                drawEdges: true,
                drawFaces: true,
                drawColoredFaces: true,
            
                drawShadowRays: true,
                drawShadowVertices: true,
                drawShadowEdges: true,
                drawShadowFaces: true,
                drawShadowColoredFaces: true,
            };
            save();
        }
    }

    public static function save() {
        File.saveContent("options", Json.stringify(instance));
    }
}