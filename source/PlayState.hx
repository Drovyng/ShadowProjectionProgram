package;

import flixel.FlxCamera;
import Logic.LVector;
import Logic.LVector;
import Logic.LVector;
import flixel.group.FlxGroup.FlxTypedGroup;
import reworked.RFlxUICheckbox.RFlxUICheckBox;
import Options.OptionsHandler;
import flixel.tweens.*;
import flixel.text.FlxText;
import flixel.addons.ui.FlxUISprite;
import openfl.display.BitmapData;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUISpriteButton;
import flixel.addons.ui.FlxUIAssets;
import flixel.math.FlxMath;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.FlxObject;
import flixel.math.FlxRect;
import Model.ModelHandler;
import reworked.*;
import flixel.system.FlxAssets;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUIState;
import sys.FileSystem;
import Logic.LVector;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.util.FlxSpriteUtil;
import flixel.FlxSprite;
import StringTools;

class PlayState extends FlxUIState
{
	public static var instance:PlayState;

	public static var SCENE_SCALE:Int = 2;

	public static var gameCamera:FlxCamera;

	public var rayRotation:LVector = new LVector(0, 0, 0);

	public var allowControls:Bool = true;

	public var planeScale:Float = 8;

	public var planeSprite:FlxSprite;
	public var axisSprite:FlxSprite;

	public var vertSprite:FlxSprite;
	public var edgeSprite:FlxSprite;
	public var faceSprite:FlxSprite;

	public var showRayDir:Bool = false;

	public var axisShow:String = "xyz";
	public var axisList:Array<FlxSprite> = [];

	public static var modelToLoad:Model = null;
	public var model:Model;
	public var modelVertices:Array<LVector>;
	public var modelShadowVertices:Array<LVector>;

	public var camFollow:FlxObject = new FlxObject(FlxG.width * SCENE_SCALE / 2, FlxG.height * SCENE_SCALE / 2);
	public var camFollowPos:FlxPoint = new FlxPoint(FlxG.width * SCENE_SCALE / 2, FlxG.height * SCENE_SCALE / 2);
	public var camFollowVector:LVector = new LVector();

	public var facesColors:Array<FlxColor> = [
		FlxColor.RED,
		FlxColor.GREEN,
		FlxColor.BLUE,
		FlxColor.PINK,
		FlxColor.LIME,
		FlxColor.CYAN,
	];

	public static function loadNextModel(nextModel:Model) {
		modelToLoad = nextModel;

		LoadingSubstate.onEnd = function() {
			FlxG.switchState(new PlayState());
		};

		instance.openSubState(new LoadingSubstate(true));
	}

	public function loadModel(getModel:Model) {
		if (getModel == null || getModel.vertices == null || getModel.edges == null || getModel.faces == null || getModel.raysRot == null){

			var modelsFiles:Array<String> = [];
			if (!FileSystem.exists("models")){
				FileSystem.createDirectory("models");
			}
			else{
				if (FileSystem.isDirectory("models")) 
				{
					modelsFiles = FileSystem.readDirectory("models/");
				}
			}

			for (modl in modelsFiles){
				if (!StringTools.endsWith(modl, ".mspp")){
					modelsFiles.remove(modl);
				}
			}
			if (modelsFiles.length > 0){
				ModelHandler.getModel(FlxG.random.getObject(modelsFiles));
				return;
			}
			else {
				var models:Array<Model> = [
					{
						vertices: [new LVector(-2, 2, 0), new LVector(0, 3, 6), new LVector(1, 2, 0)],
						edges: [[0, 1], [1, 2], [2, 0]],
						faces: [[0, 1, 2]],
						raysRot: new LVector()
					},
					{
						vertices: [new LVector(-3, 2, 2), new LVector(0, 6, 0), new LVector(2, 2, 2), new LVector(2.5, 3, -2)],
						edges: [[0, 1], [1, 2], [2, 3], [3, 0], [0, 2], [1, 3]],
						faces: [[0, 1, 2], [2, 1, 3], [3, 1, 0], [0, 2, 3]],
						raysRot: new LVector(5, 0, 35)
					},
					{
						vertices: [new LVector(-1.5, 2, 1.5), new LVector(1.5, 2, 1.5), new LVector(1.5, 2, -1.5), new LVector(-1.5, 2, -1.5), new LVector(-1.5, 5, 1.5), new LVector(1.5, 5, 1.5), new LVector(1.5, 5, -1.5), new LVector(-1.5, 5, -1.5)],
						edges: [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]],
						faces: [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]],
						raysRot: new LVector(60, 315, 0)
					}
				];
				model = FlxG.random.getObject(models);
			}
			trace(model);
			trace(model.raysRot);
			rayRotation = LVector.fromTypedef(model.raysRot);
			return;
		}
		model = getModel;

		rayRotation = LVector.fromTypedef(model.raysRot);
	}

	public function updateRaySteppers() {
		UI_Ray_AxisSteppers[1].value = -rayRotation.z;
		UI_Ray_AxisSteppers[2].value = rayRotation.y;
		UI_Ray_AxisSteppers[3].value = rayRotation.x;
	}

	override public function create()
	{
		VertexCharsIndices.insert(0, "");

		FlxG.random.shuffle(facesColors);

		instance = this;
		
		OptionsHandler.load();

		FlxAssets.FONT_DEFAULT = "Arial";

		loadModel(modelToLoad);
		
		super.create();

		
		gameCamera = new FlxCamera();
		gameCamera.bgColor = 0xFF8888DD;
		gameCamera.follow(camFollow, null, 1);

		FlxG.cameras.reset(gameCamera);
		FlxCamera.defaultCameras = [gameCamera];


		
		var bgSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * SCENE_SCALE, FlxG.height * SCENE_SCALE, 0xFF8888DD);
		add(bgSprite);


		planeSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * SCENE_SCALE, FlxG.height * SCENE_SCALE);
		add(planeSprite);


		axisSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * SCENE_SCALE, FlxG.height * SCENE_SCALE);
		add(axisSprite);

		
		faceSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * SCENE_SCALE, FlxG.height * SCENE_SCALE, FlxColor.TRANSPARENT);
		add(faceSprite);

		edgeSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * SCENE_SCALE, FlxG.height * SCENE_SCALE, FlxColor.TRANSPARENT);
		add(edgeSprite);

		vertSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * SCENE_SCALE, FlxG.height * SCENE_SCALE, FlxColor.TRANSPARENT);
		add(vertSprite);

		add(UI_VerticesTexts);
		add(UI_ShadowVerticesTexts);

		createUIStuff();

		onChangeEverything();

		LoadingSubstate.onEnd = function() {
			allowControls = true;
		};
		openSubState(new LoadingSubstate(false));

		update(0);

		camFollow.x = camFollowPos.x;
		camFollow.y = camFollowPos.y;

		allowControls = false;
	}

	public var UI_OffsetY:Float = 40;
	public var UI_Box:RFlxUITabMenu;
	public var UI_SL_Box:RFlxUITabMenu;
	public var UI_Opt_Box:RFlxUITabMenu;
	public var UI_Ray_Box:RFlxUITabMenu;

	public var UI_Ray_AxisSteppers:Array<RFlxUINumericStepper> = [];
	public var UI_Ray_AxisSteppersText:Array<FlxUIText> = [];
	public var UI_Ray_AxisSteppersLabels:Array<String> = [
		"Шаг",
		"Ось X",
		"Ось Y",
		"Ось Z"
	];
	public var UI_Ray_AxisWrongText:FlxUIText;
	public var UI_Ray_AxisSpriteBG:FlxSprite;
	public var UI_Ray_AxisSprite:FlxSprite;

	public var UI_AxisSteppers:Array<RFlxUINumericStepper> = [];
	public var UI_AxisSteppersText:Array<FlxUIText> = [];
	public var UI_AxisSteppersLabels:Array<String> = [
		"Шаг",
		"Ось X",
		"Ось Y",
		"Ось Z"
	];
	public var UI_OptionsHandlerButton:FlxUISprite;

	public var UI_OptionsHandlerCheckBoxes:Array<RFlxUICheckBox> = [];
	public var UI_OptionsHandlerTexts:Array<FlxUIText> = [];
	public var UI_OptionsHandlerLabels:Array<Dynamic> = [
		["Показать сетку", "drawGrid"],
		["Подписывать Вершины", "drawVertsChars"],
		[],
		["Вершины", "drawVertices"],
		["Рёбра", "drawEdges"],
		["Грани", "drawFaces"],
		["Цветные Грани", "drawColoredFaces"],
		[],
		["Лучи Паралл. Проэктир.", "drawShadowRays"],
		["Вершины Образа", "drawShadowVertices"],
		["Рёбра Образа", "drawShadowEdges"],
		["Грани Образа", "drawShadowFaces"],
		["Цветные Грани Образа", "drawShadowColoredFaces"]
	];
	public var UI_OptionsHandlerTween:FlxTween;
	public var UI_OptionsHandlerOpened:Bool;

	public var rayRotationError:Bool = false;

	
	public var UI_VerticesTexts:FlxTypedGroup<FlxUIText> = new FlxTypedGroup<FlxUIText>();
	public var UI_ShadowVerticesTexts:FlxTypedGroup<FlxUIText> = new FlxTypedGroup<FlxUIText>();

	public function reloadVerticesTexts() {
		if (rayRotationError) return;
		UI_VerticesTexts.forEachAlive(function(text) {
			text.destroy();
		});
		UI_VerticesTexts.clear();
		UI_ShadowVerticesTexts.forEachAlive(function(text) {
			text.destroy();
		});
		UI_ShadowVerticesTexts.clear();

		for (v in 0...modelVertices.length) {

			var point = modelVertices[v].toFlxPoint();
			var pointShadow = Logic.RayCast(modelVertices[v], rayRotation).toFlxPoint();

			UI_VerticesTexts.add(createVertexText(v, point, false));
			UI_VerticesTexts.add(createVertexText(v, pointShadow, true));
		}
	}
	public var VertexChars:Array<String> = "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z".split(" ");
	public var VertexCharsIndices:Array<String> = "₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉".split(" ");
	public function createVertexText(index:Int, point:FlxPoint, isShadow:Bool):FlxUIText {
		var text = new FlxUIText(point.x + 5, point.y - 37, 100, VertexChars[index % VertexChars.length] + VertexCharsIndices[Std.int((index - (index % VertexChars.length)) / VertexChars.length)] + (isShadow ? "'" : ""), 32);
		text.color = 0x000000;
		return text;
	}

	public var UI_SL_ResetButton:FlxUIButton;
	public var UI_SL_LoadButton:FlxUIButton;
	public var UI_SL_SaveButton:FlxUIButton;

	public function createUIStuff() {
		UI_Box = new RFlxUITabMenu(null, [{name: "Управление", label: "Управление"}], true);
		UI_Box.resize(280, FlxG.height);
		UI_Box.setPosition(1000, 0);
		UI_Box.skipButtonUpdate = true;
		UI_Box.scrollFactor.set();
		add(UI_Box);
		

		UI_Ray_Box = new RFlxUITabMenu(null, [{name: "Перспектива", label: "Перспектива"}], true);
		UI_Ray_Box.resize(280, FlxG.height / 2);
		UI_Ray_Box.setPosition(0, FlxG.height / 2);
		UI_Ray_Box.skipButtonUpdate = true;
		UI_Box.add(UI_Ray_Box);

		var textWidth = 75;

		for (i in 0...UI_Ray_AxisSteppersLabels.length){
			var posY = 30 * i + UI_OffsetY;
			var getted:Dynamic = UI_Ray_AxisSteppersLabels[i];
			
			var text = new FlxUIText(8, posY, textWidth, getted, 20);
			text.color = 0x000000;

			UI_Ray_Box.add(text);
			UI_Ray_AxisSteppersText.push(text);
			var stepper = new RFlxUINumericStepper(textWidth + 8, posY, 5, i == 0 ? 5 : 0, i == 0 ? 5 : -1, i == 0 ? 90 : 360, 0, 1, null, null, null, false, "°");
			//stepper.textAdd = "°";
			stepper.params = [0, i];
			stepper.text_field.color = 0x000000;

			UI_Ray_Box.add(stepper);
			UI_Ray_AxisSteppers.push(stepper);
		}

		UI_Ray_AxisWrongText = new FlxUIText(0, 0, 760, "Лучи параллельного проектирования вне лимита!", 30);
		UI_Ray_AxisWrongText.setBorderStyle(FlxTextBorderStyle.OUTLINE);
		UI_Ray_AxisWrongText.alignment = CENTER;
		UI_Ray_AxisWrongText.color = 0xFFFF5050;
		UI_Ray_AxisWrongText.borderColor = 0xFF000000;
		UI_Ray_AxisWrongText.borderSize = 2;
		UI_Ray_AxisWrongText.visible = false;
		UI_Ray_Box.add(UI_Ray_AxisWrongText);

		UI_Ray_AxisWrongText.y = 20;
		UI_Ray_AxisWrongText.x = 240;

		var saveY = (30 * UI_Ray_AxisSteppersLabels.length + 1) + UI_OffsetY;

		axisList.push(new FlxSprite().loadGraphic(new AxisXYZBitmapData(0, 0)));
		axisList.push(new FlxSprite().loadGraphic(new AxisXBitmapData(0, 0)));
		axisList.push(new FlxSprite().loadGraphic(new AxisYBitmapData(0, 0)));
		axisList.push(new FlxSprite().loadGraphic(new AxisZBitmapData(0, 0)));

		// X OFFSET =  (280 - 190) / 2

		UI_Ray_AxisSpriteBG = new FlxSprite(45, saveY).makeGraphic(190, 190, 0xFF000000);
		UI_Ray_AxisSprite = new FlxSprite(50, saveY + 5).makeGraphic(180, 180, 0xFFAAAAAA);

		UI_Ray_Box.add(UI_Ray_AxisSpriteBG);
		UI_Ray_Box.add(UI_Ray_AxisSprite);

		for (spr in axisList){

			spr.setGraphicSize(UI_Ray_AxisSprite.width, UI_Ray_AxisSprite.height);
			spr.offset.set();
			spr.x = 50;
			spr.y = saveY + 5;

			spr.updateHitbox();

			spr.visible = false;

			UI_Ray_Box.add(spr);
		}

		for (i in 0...UI_AxisSteppersLabels.length){
			var posY = 30 * i + UI_OffsetY * 2;
			var getted:Dynamic = UI_Ray_AxisSteppersLabels[i];
			
			var text = new FlxUIText(8, posY, textWidth, getted, 20);
			text.color = 0x000000;

			UI_Box.add(text);
			UI_AxisSteppersText.push(text);
			var stepper = new RFlxUINumericStepper(textWidth + 8, posY, 0.25, i == 0 ? 0.25 : 0, i == 0 ? 0.25 : -40, i == 0 ? 2 : 40, 2, 1, null, null, null, false, " см");
			//stepper.textAdd = " см";
			stepper.params = [1, i];
			stepper.text_field.color = 0x000000;
			
			UI_Box.add(stepper);
			UI_AxisSteppers.push(stepper);
		}
		
		UI_Opt_Box = new RFlxUITabMenu(null, [{name: "Настройки", label: "Настройки"}], true);
		UI_Opt_Box.resize(240, 30 * (UI_OptionsHandlerLabels.length + 3) + UI_OffsetY);
		UI_Opt_Box.setPosition(0, 0);
		UI_Opt_Box.skipButtonUpdate = true;
		UI_Opt_Box.scrollFactor.set();
		add(UI_Opt_Box);

		UI_OptionsHandlerButton = new FlxUISprite();
		UI_OptionsHandlerButton.loadGraphic(new OptionsBitmapData(0, 0));
		UI_OptionsHandlerButton.scrollFactor.set();
		UI_OptionsHandlerButton.setGraphicSize(48, 48);
		UI_OptionsHandlerButton.setPosition(UI_Opt_Box.width / 2 - 24, 30 * (UI_OptionsHandlerLabels.length + 1.5) - 24 + UI_OffsetY);
		UI_OptionsHandlerButton.updateHitbox();
		UI_OptionsHandlerButton.antialiasing = false;
		
		UI_Opt_Box.add(UI_OptionsHandlerButton);

		for (i in 0...UI_OptionsHandlerLabels.length){
			var posY = 30 * i + UI_OffsetY;

			if (UI_OptionsHandlerLabels[i].length == 0) {
				UI_OptionsHandlerCheckBoxes.push(null);
				UI_OptionsHandlerTexts.push(null);
				continue;
			}

			var checkBox = new RFlxUICheckBox(8, posY, null, null, "", 0, [0, i]);
			checkBox.checked = Reflect.getProperty(OptionsHandler.instance, UI_OptionsHandlerLabels[i][1]);
			checkBox.ID = i;
			UI_OptionsHandlerCheckBoxes.push(checkBox);
			UI_Opt_Box.add(checkBox);
			
			var text = new FlxUIText(36, posY, 204, UI_OptionsHandlerLabels[i][0], 16);
			UI_OptionsHandlerTexts.push(text);
			UI_Opt_Box.add(text);
		}

		UI_Opt_Box.setPosition(0, -UI_Opt_Box.height + 90);


		
		
		UI_SL_Box = new RFlxUITabMenu(null, [{name: "Сохранение/Загрузка", label: "Сохранение/Загрузка"}], true);
		UI_SL_Box.resize(416, 40 + UI_OffsetY);
		UI_SL_Box.skipButtonUpdate = true;
		UI_SL_Box.scrollFactor.set();
		add(UI_SL_Box);

		UI_SL_ResetButton = new FlxUIButton(8, UI_OffsetY, "Сбросить", function() {
			loadNextModel(null);
		});
		UI_SL_ResetButton.label.size = 20;
		UI_SL_ResetButton.label.width = 128;
		UI_SL_ResetButton.resize(128, 24);
		UI_SL_Box.add(UI_SL_ResetButton);


		UI_SL_LoadButton = new FlxUIButton(136, UI_OffsetY, "Загрузить", function() {
			ModelHandler.getModelByUser();
		});
		UI_SL_LoadButton.label.size = 20;
		UI_SL_LoadButton.label.width = 128;
		UI_SL_LoadButton.resize(128, 24);
		UI_SL_Box.add(UI_SL_LoadButton);


		UI_SL_SaveButton = new FlxUIButton(272, UI_OffsetY, "Сохранить", function() {
			ModelHandler.saveModel();
		});
		UI_SL_SaveButton.label.size = 20;
		UI_SL_SaveButton.label.width = 128;
		UI_SL_SaveButton.resize(128, 24);
		UI_SL_Box.add(UI_SL_SaveButton);

		
		UI_SL_Box.setPosition(0, FlxG.height - UI_SL_Box.height);
	}
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		super.getEvent(id, sender, data, params);
		switch (id)
		{
			case "change_numeric_stepper":
				if (params != null)
				{
					switch(params[0]) 
					{
						case 0:
							if (sender.value == -1 || data == -1) {
								sender.value = 360 - UI_Ray_AxisSteppers[0].value;
							} else if (sender.value == 360 || data == 360) {
								sender.value = UI_Ray_AxisSteppers[0].value;
							}
							switch (params[1]){
								case 1:
									rayRotation.z = -sender.value;
								case 2:
									rayRotation.y = sender.value;
								case 3:
									rayRotation.x = sender.value;
							}
							rayRotationError = (new LVector(0, -1, 0).rotate(rayRotation)).y >= 0;
							if (!rayRotationError){
								var vecNew = new LVector(0, 1, 0).clone().minus(Logic.RayCast(new LVector(0, 1, 0), rayRotation));
								rayRotationError = Math.sqrt(vecNew.x * vecNew.x + vecNew.y * vecNew.y + vecNew.z * vecNew.z) >= 40;
							}
							UI_Ray_AxisWrongText.visible = rayRotationError;

							if (params[1] != 0) {
								onChangeEverything();
							}
							else{
								UI_Ray_AxisSteppers[1].stepSize = data;
								UI_Ray_AxisSteppers[2].stepSize = data;
								UI_Ray_AxisSteppers[3].stepSize = data;
							}

						case 1:
							if (params[1] == 0){
								UI_AxisSteppers[1].stepSize = data;
								UI_AxisSteppers[2].stepSize = data;
								UI_AxisSteppers[3].stepSize = data;
								return;
							}
							if (selectedVertex == -1) return;
							var vert = modelVertices[selectedVertex];
							switch (params[1]){
								case 1:
									vert.x = sender.value;
								case 2:
									vert.y = sender.value;
								case 3:
									vert.z = sender.value;
							}
							model.vertices[selectedVertex] = vert.toTypedef();
							onChangeEverything();
					}
				}
			case "click_check_box":
				if (params != null)
				{
					switch(params[0]) 
					{
						case 0:
							var nameVar = UI_OptionsHandlerLabels[sender.ID][1];
							Reflect.setProperty(OptionsHandler.instance, nameVar, sender.checked);
							OptionsHandler.save();
							onChangeEverything();
					}
				}
		}
	}
	public function onChangeEverything() {
		
		modelVertices = [];
		modelShadowVertices = [];

		for (v in 0...model.vertices.length) {

			var vert = LVector.fromTypedef(model.vertices[v]);
			var vertShadow = Logic.RayCast(vert, rayRotation);
			modelVertices.push(vert);
			modelShadowVertices.push(vertShadow);
		}

		onChangeAxis();
		onChangeModel();
		reloadVerticesTexts();
	}
	public function onChangeModel() {
		FlxSpriteUtil.fill(vertSprite, FlxColor.TRANSPARENT);
		FlxSpriteUtil.fill(edgeSprite, FlxColor.TRANSPARENT);
		FlxSpriteUtil.fill(faceSprite, FlxColor.TRANSPARENT);
		FlxSpriteUtil.fill(vertSprite, FlxColor.TRANSPARENT);
		FlxSpriteUtil.fill(edgeSprite, FlxColor.TRANSPARENT);
		FlxSpriteUtil.fill(faceSprite, FlxColor.TRANSPARENT);
		if (model != null && !rayRotationError){
			if (OptionsHandler.instance.drawVertices){
				for (v in 0...modelVertices.length) {
					var point = modelVertices[v].toFlxPoint();
					FlxSpriteUtil.drawCircle(vertSprite, point.x, point.y, 6, v == selectedVertex ? 0xFF0000FF : 0xFF000000);
				}
			}
			if (OptionsHandler.instance.drawEdges){
				for (e in 0...model.edges.length) {
					var start = modelVertices[model.edges[e][0]].toFlxPoint();
					var end = modelVertices[model.edges[e][1]].toFlxPoint();
					FlxSpriteUtil.drawLine(edgeSprite, start.x, start.y, end.x, end.y, {
						thickness: 1.75,
						color: 0xFF000000
					});
				}
			}
			if (OptionsHandler.instance.drawFaces){
				for (f in 0...model.faces.length) {
					var vertices:Array<FlxPoint> = [];
					for (i in 0...model.faces[f].length){
						vertices.push(modelVertices[model.faces[f][i]].toFlxPoint());
					}
					if (OptionsHandler.instance.drawColoredFaces)
					{
						//var hue = 360 / model.faces.length * f;
						var hue = facesColors[f % facesColors.length];
						hue.alphaFloat = 0.25;
						FlxSpriteUtil.drawPolygon(faceSprite, vertices, hue); //FlxColor.fromHSB(hue, 75, 90, 0.25));
					}
					else
					{
						FlxSpriteUtil.drawPolygon(faceSprite, vertices, 0x40666666);
					}
				}
			}
			
			if (OptionsHandler.instance.drawShadowVertices){
				for (v in 0...modelVertices.length) {
					var point = modelShadowVertices[v].toFlxPoint();
					FlxSpriteUtil.drawCircle(vertSprite, point.x, point.y, 6, 0xFF000000);
				}
			}

			if (OptionsHandler.instance.drawShadowRays){
				for (v in 0...modelVertices.length) {
					var start = modelVertices[v].toFlxPoint();
					var end = modelShadowVertices[v].toFlxPoint();

					FlxSpriteUtil.drawLine(edgeSprite, start.x, start.y, end.x, end.y, {
						thickness: 1.75,
						color: 0xFF444444
					});
				}
			}
			if (OptionsHandler.instance.drawShadowEdges){
				for (e in 0...model.edges.length) {
					var start = modelShadowVertices[model.edges[e][0]].toFlxPoint();
					var end = modelShadowVertices[model.edges[e][1]].toFlxPoint();
					FlxSpriteUtil.drawLine(edgeSprite, start.x, start.y, end.x, end.y, {
						thickness: 1.75,
						color: 0xFF000000
					});
				}
			}
			if (OptionsHandler.instance.drawShadowFaces){
				for (f in 0...model.faces.length) {
					var vertices:Array<FlxPoint> = [];
					for (i in 0...model.faces[f].length){
						vertices.push(modelShadowVertices[model.faces[f][i]].toFlxPoint());
					}
					if (OptionsHandler.instance.drawShadowColoredFaces)
					{
						//var hue = 360 / model.faces.length * f;
						var hue = facesColors[f % facesColors.length];
						hue.alphaFloat = 0.25;
						FlxSpriteUtil.drawPolygon(faceSprite, vertices, hue);//FlxColor.fromHSB(hue, 75, 90, 0.25));
					}
					else
					{
						FlxSpriteUtil.drawPolygon(faceSprite, vertices, 0x40666666);
					}
				}
			}
			camFollowVector = new LVector();
			var divide:Float = 0;
			for (vert in modelVertices){
				camFollowVector.plus(vert);
				divide += 1;
			}
			for (vert in modelShadowVertices){
				camFollowVector.plus(vert);
				divide += 1;
			}
			camFollowVector.divideF(divide);
			camFollowPos = camFollowVector.toFlxPoint();
		}
	}
	public function onChangeAxis() 
	{
		var offset:LVector = new LVector(
			Std.int(camFollowVector.x), 
			Std.int(camFollowVector.y),
			Std.int(camFollowVector.z)
		);

		FlxSpriteUtil.fill(axisSprite, FlxColor.TRANSPARENT);

		FlxSpriteUtil.flashGfx.clear();
		FlxSpriteUtil.fill(planeSprite, 0xFF8888DD);
		FlxSpriteUtil.drawPolygon(planeSprite, [
			new LVector(-planeScale,  0,  -planeScale).plus(offset).toFlxPoint(), 
			new LVector( planeScale,  0,  -planeScale).plus(offset).toFlxPoint(), 
			new LVector( planeScale,  0,  planeScale ).plus(offset).toFlxPoint(), 
			new LVector(-planeScale,  0,  planeScale ).plus(offset).toFlxPoint()
		], 0xFFBBBBBB);

		if (OptionsHandler.instance.drawGrid)
		{
			var scale:Int = Std.int(planeScale);

			for (i in -scale...scale+1)
			{
				if (i == 0) continue;

				var axisX1 = new LVector(-scale, 0, i).plus(offset).toFlxPoint();
				var axisX2 = new LVector(scale, 0, i).plus(offset).toFlxPoint();
				FlxSpriteUtil.drawLine(planeSprite, axisX1.x, axisX1.y, axisX2.x, axisX2.y, {
					thickness: 1.5,
					color: 0xFF000000
				});
				var axisZ1 = new LVector(i, 0, -scale).plus(offset).toFlxPoint();
				var axisZ2 = new LVector(i, 0, scale).plus(offset).toFlxPoint();
				FlxSpriteUtil.drawLine(planeSprite, axisZ1.x, axisZ1.y, axisZ2.x, axisZ2.y, {
					thickness: 1.5,
					color: 0xFF000000
				});
			}
		}

		var scale = planeScale;
		var pos = new LVector();
		if (selectedVertex != -1){
			scale = 2.5;
			pos = modelVertices[selectedVertex];
		}
		UI_VerticesTexts.visible = OptionsHandler.instance.drawVertsChars;
		UI_ShadowVerticesTexts.visible = OptionsHandler.instance.drawVertsChars;

		var axisIndex = ["xyz", "x", "y", "z"].indexOf(axisShow);

		for (i in 0...4)
		{
			if ((i == axisIndex && showRayDir) || (i == 0 && !showRayDir))
			{
				axisList[i].visible = true;
			}
			else
			{
				axisList[i].visible = false;
			}
		}
		
		if (StringTools.contains(axisShow, "x") || showRayDir)
		{
			var axisX1 = new LVector(pos.x - scale, pos.y, pos.z).plus(offset).toFlxPoint();
			var axisX2 = new LVector(pos.x + scale, pos.y, pos.z).plus(offset).toFlxPoint();
			FlxSpriteUtil.drawLine(axisSprite, axisX1.x, axisX1.y, axisX2.x, axisX2.y, {
				thickness: 3.5,
				color: 0xFFFF6060
			});
		}
		if (StringTools.contains(axisShow, "z") || showRayDir)
		{
			var axisZ1 = new LVector(pos.x, pos.y, pos.z - scale).plus(offset).toFlxPoint();
			var axisZ2 = new LVector(pos.x, pos.y, pos.z + scale).plus(offset).toFlxPoint();
			FlxSpriteUtil.drawLine(axisSprite, axisZ1.x, axisZ1.y, axisZ2.x, axisZ2.y, {
				thickness: 3.5,
				color: 0xFF6060FF
			});
		}
		if (StringTools.contains(axisShow, "y") || showRayDir)
		{
			var axisY1 = new LVector(pos.x, pos.y + (selectedVertex != -1 ? -scale : 0), pos.z).plus(offset).toFlxPoint();
			var axisY2 = new LVector(pos.x, pos.y + scale, pos.z).plus(offset).toFlxPoint();
			FlxSpriteUtil.drawLine(axisSprite, axisY1.x, axisY1.y, axisY2.x, axisY2.y, {
				thickness: 3.5,
				color: 0xFF60FF60
			});
		}
	}

	var last_axisShow:String = "";

	var selectedVertex:Int = -1;

	override public function update(elapsed:Float)
	{
		if (!allowControls) return;

		camFollow.x = FlxMath.lerp(camFollow.x, camFollowPos.x, elapsed);
		camFollow.y = FlxMath.lerp(camFollow.y, camFollowPos.y, elapsed);

		super.update(elapsed);

		if (FlxG.mouse.justPressed && model != null && !FlxG.mouse.overlaps(UI_Box))
		{
			var changed = true;
			selectedVertex = -1;
			for (v in 0...modelVertices.length) 
			{
				var point = modelVertices[v].toFlxPoint();
				var mouse = FlxG.mouse.getPosition();
				if (point.x - 5 <= mouse.x && point.x + 5 >= mouse.x && point.y - 5 <= mouse.y && point.y + 5 >= mouse.y) 
				{
					if (v != selectedVertex)
					{
						selectedVertex = v;
					}
					else 
					{
						changed = false;
					}
					break;
				}
			}
			if (changed) 
			{
				onChangeEverything();

				var vert = selectedVertex != -1 ? modelVertices[selectedVertex] : new LVector();

				UI_AxisSteppers[1].value = vert.x;
				UI_AxisSteppers[2].value = vert.y;
				UI_AxisSteppers[3].value = vert.z;
			}
		}
		if (FlxG.mouse.overlaps(UI_OptionsHandlerButton)){
			if (FlxG.mouse.pressed){
				UI_OptionsHandlerButton.color = 0x777777;
			}
			else{
				UI_OptionsHandlerButton.color = 0xAAAAAA;
			}
			if (FlxG.mouse.justReleased && UI_OptionsHandlerTween == null){
			
	  			UI_OptionsHandlerTween = FlxTween.tween(UI_Opt_Box, {y: (UI_OptionsHandlerOpened ? -UI_Opt_Box.height + 90 : 0)}, 0.5, {ease: FlxEase.quartOut, onComplete: function(_){
					UI_OptionsHandlerTween = null;
					UI_OptionsHandlerOpened = !UI_OptionsHandlerOpened;
				}});
			}
		}
		else{
			UI_OptionsHandlerButton.color = 0xFFFFFF;
		}

		showRayDir = FlxG.mouse.overlaps(UI_Ray_Box) || rayRotationError;
		UI_Ray_AxisWrongText.visible = rayRotationError;

		axisShow = "xyz";
		for (i in 1...UI_Ray_AxisSteppersLabels.length){
			if (FlxG.mouse.overlaps(UI_Ray_AxisSteppers[i]) || FlxG.mouse.overlaps(UI_Ray_AxisSteppersText[i])){
				switch (i){
					case 1:
						axisShow = "x";
					case 2:
						axisShow = "y";
					case 3:
						axisShow = "z";
				}
				showRayDir = true;
				break;
			}
		}
		for (i in 1...UI_AxisSteppersLabels.length){
			if (FlxG.mouse.overlaps(UI_AxisSteppers[i]) || FlxG.mouse.overlaps(UI_AxisSteppersText[i])){
				switch (i){
					case 1:
						axisShow = "x";
					case 2:
						axisShow = "y";
					case 3:
						axisShow = "z";
				}
				break;
				showRayDir = false;
			}
		}
		if (axisShow != last_axisShow)
		{
			onChangeAxis();
		}
		last_axisShow = axisShow;
	}
}
@:bitmap("../assets/UI_Button_Options.png") class OptionsBitmapData extends BitmapData { }
@:bitmap("../assets/AxisXYZ.png") class AxisXYZBitmapData extends BitmapData { }
@:bitmap("../assets/AxisX.png") class AxisXBitmapData extends BitmapData { }
@:bitmap("../assets/AxisY.png") class AxisYBitmapData extends BitmapData { }
@:bitmap("../assets/AxisZ.png") class AxisZBitmapData extends BitmapData { }