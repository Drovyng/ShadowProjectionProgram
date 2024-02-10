package;

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

	public var rayRotation:LVector = new LVector(0, 0, 0);


	public var planeScale:Float = 8;

	public var planeSprite:FlxSprite;
	public var axisSprite:FlxSprite;

	public var vertSprite:FlxSprite;
	public var edgeSprite:FlxSprite;
	public var faceSprite:FlxSprite;

	public var showRayDir:Bool = false;
	public var raySprite:FlxSprite;

	public var axisShow:String = "xyz";

	public var model:Model;
	public var modelVertices:Array<LVector>;
	public var modelShadowVertices:Array<LVector>;

	public var camFollow:FlxObject = new FlxObject(FlxG.width / 2, FlxG.height / 2);
	public var camFollowPos:FlxPoint = new FlxPoint(FlxG.width / 2, FlxG.height / 2);

	public var modelAlphaTween:Float = 0;

	public var facesColors:Array<FlxColor> = [
		FlxColor.RED,
		FlxColor.GREEN,
		FlxColor.BLUE,
		FlxColor.PINK,
		FlxColor.LIME,
		FlxColor.CYAN,
	];

	public function loadModel(getModel:Model, ?redraw:Bool = true) {
		if (getModel == null || getModel.vertices == null || getModel.edges == null || getModel.faces == null){

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
						raysRot: new LVector()
					}
				];
				model = FlxG.random.getObject(models);
			}

			if (redraw) {
				rayRotation = LVector.fromTypedef(model.raysRot);
				updateRaySteppers();
				onChangeEverything();
			}
			return;
		}
		model = getModel;

		if (redraw) {
			rayRotation = LVector.fromTypedef(model.raysRot);
			updateRaySteppers();
			onChangeEverything();
		}
	}

	public function updateRaySteppers() {
		UI_Ray_AxisSteppers[1].value = rayRotation.x;
		UI_Ray_AxisSteppers[2].value = rayRotation.y;
		UI_Ray_AxisSteppers[3].value = rayRotation.z;
	}

	override public function create()
	{
		VertexCharsIndices.insert(0, "");

		FlxG.random.shuffle(facesColors);

		instance = this;
		
		OptionsHandler.load();

		FlxAssets.FONT_DEFAULT = "Arial";

		loadModel(null, false);
		
		super.create();

		FlxG.camera.bgColor = 0xFF8888DD;
		FlxG.camera.follow(camFollow, null, 1);

		
		var bgSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF8888DD);
		add(bgSprite);


		planeSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height);
		add(planeSprite);


		axisSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height);
		add(axisSprite);

		
		faceSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		add(faceSprite);

		edgeSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		add(edgeSprite);

		vertSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		add(vertSprite);

		raySprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		add(raySprite);

		add(UI_VerticesTexts);
		add(UI_ShadowVerticesTexts);

		createUIStuff();

		onChangeEverything();
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
		["Цветные оси", "axisColored"],
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
		UI_Ray_AxisWrongText = new FlxUIText(8, (30 * UI_Ray_AxisSteppersLabels.length + 1) + UI_OffsetY, 264, "Лучи параллельного проектирования вне лимита!", 32);
		UI_Ray_AxisWrongText.setBorderStyle(FlxTextBorderStyle.OUTLINE);
		UI_Ray_AxisWrongText.color = FlxColor.RED;
		UI_Ray_AxisWrongText.borderColor = FlxColor.RED;
		UI_Ray_AxisWrongText.borderSize = 0.5;
		UI_Ray_Box.add(UI_Ray_AxisWrongText);


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
			loadModel(null);
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
									rayRotation.x = sender.value;
								case 2:
									rayRotation.y = sender.value;
								case 3:
									rayRotation.z = sender.value;
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

		FlxSpriteUtil.flashGfx.clear();
		FlxSpriteUtil.fill(planeSprite, 0xFF8888DD);
		FlxSpriteUtil.fill(axisSprite, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawPolygon(planeSprite, [
			new LVector(-planeScale,  0,  -planeScale).toFlxPoint(), 
			new LVector( planeScale,  0,  -planeScale).toFlxPoint(), 
			new LVector( planeScale,  0,  planeScale ).toFlxPoint(), 
			new LVector(-planeScale,  0,  planeScale ).toFlxPoint()
		], 0xFFBBBBBB);

		if (OptionsHandler.instance.drawGrid){
			var scale:Int = Std.int(planeScale);
			for (i in -scale...scale+1)
			{
				if (i == 0) continue;

				var axisX1 = new LVector(-scale, 0, i).toFlxPoint();
				var axisX2 = new LVector(scale, 0, i).toFlxPoint();
				FlxSpriteUtil.drawLine(planeSprite, axisX1.x, axisX1.y, axisX2.x, axisX2.y, {
					thickness: 1.5,
					color: 0xFF000000
				});
				var axisZ1 = new LVector(i, 0, -scale).toFlxPoint();
				var axisZ2 = new LVector(i, 0, scale).toFlxPoint();
				FlxSpriteUtil.drawLine(planeSprite, axisZ1.x, axisZ1.y, axisZ2.x, axisZ2.y, {
					thickness: 1.5,
					color: 0xFF000000
				});
			}
		}
		onChangeModel();
		onChangeAxis();
		reloadVerticesTexts();
	}
	public function onChangeModel() {
		if (showRayDir)
		{
			FlxSpriteUtil.fill(raySprite, FlxColor.TRANSPARENT);
			
			var start = new LVector().toFlxPoint();
			var end = new LVector(0, 7, 0).rotate(rayRotation).toFlxPoint();

			FlxSpriteUtil.drawLine(raySprite, start.x, start.y, end.x, end.y, {
				thickness: 2,
				color: rayRotationError ? 0x80CC0000 : 0x80000000
			});
		} 
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
			var center:LVector = new LVector();
			var divide:Float = 0;
			for (vert in modelVertices){
				center.plus(vert);
				divide += 1;
			}
			for (vert in modelShadowVertices){
				center.plus(vert);
				divide += 1;
			}
			center.divideF(divide);
			camFollowPos = center.toFlxPoint();
		}
	}
	public function onChangeAxis() {
		var scale = planeScale;
		var pos = new LVector();
		if (selectedVertex != -1){
			scale = 2.5;
			pos = modelVertices[selectedVertex];
		}
		UI_VerticesTexts.visible = OptionsHandler.instance.drawVertsChars;
		UI_ShadowVerticesTexts.visible = OptionsHandler.instance.drawVertsChars;

		if (StringTools.contains(axisShow, "x"))
		{
			var axisX1 = new LVector(pos.x - scale, pos.y, pos.z).toFlxPoint();
			var axisX2 = new LVector(pos.x + scale, pos.y, pos.z).toFlxPoint();
			FlxSpriteUtil.drawLine(axisSprite, axisX1.x, axisX1.y, axisX2.x, axisX2.y, {
				thickness: 3.5,
				color: OptionsHandler.instance.axisColored ? 0xFFFF6060 : 0xFF000000
			});
		}
		if (StringTools.contains(axisShow, "z"))
		{
			var axisZ1 = new LVector(pos.x, pos.y, pos.z - scale).toFlxPoint();
			var axisZ2 = new LVector(pos.x, pos.y, pos.z + scale).toFlxPoint();
			FlxSpriteUtil.drawLine(axisSprite, axisZ1.x, axisZ1.y, axisZ2.x, axisZ2.y, {
				thickness: 3.5,
				color: OptionsHandler.instance.axisColored ? 0xFF6060FF : 0xFF000000
			});
		}
		if (StringTools.contains(axisShow, "y"))
		{
			var axisY1 = new LVector(pos.x, pos.y + (selectedVertex != -1 ? -scale : 0), pos.z).toFlxPoint();
			var axisY2 = new LVector(pos.x, pos.y + scale, pos.z).toFlxPoint();
			FlxSpriteUtil.drawLine(axisSprite, axisY1.x, axisY1.y, axisY2.x, axisY2.y, {
				thickness: 3.5,
				color: OptionsHandler.instance.axisColored ? 0xFF60FF60 : 0xFF000000
			});
		}
	}

	var last_showRayDir:Bool = false;
	var last_axisShow:String = "";

	var selectedVertex:Int = -1;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		camFollow.x = FlxMath.lerp(camFollow.x, camFollowPos.x, elapsed);
		camFollow.y = FlxMath.lerp(camFollow.y, camFollowPos.y, elapsed);

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
			
	  			UI_OptionsHandlerTween = FlxTween.tween(UI_Opt_Box, {y: (UI_OptionsHandlerOpened ? -UI_Opt_Box.height + 90 : 0)}, 0.5, {ease: FlxEase.bounceOut, onComplete: function(_){
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

		var modelAlphaTweenTarget:Float = showRayDir ? 0.25 : 1;
		modelAlphaTween = FlxMath.lerp(modelAlphaTween, modelAlphaTweenTarget, elapsed * 10);
		if (Math.abs(modelAlphaTweenTarget - modelAlphaTween) <= 0.075){
			modelAlphaTween = modelAlphaTweenTarget;
		}
		vertSprite.alpha = modelAlphaTween;
		edgeSprite.alpha = modelAlphaTween;
		faceSprite.alpha = modelAlphaTween;

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
				showRayDir = true;
				break;
			}
		}
		if (axisShow != last_axisShow){
			onChangeEverything();
		}
		last_axisShow = axisShow;
		
		if (showRayDir != last_showRayDir){
			onChangeEverything();
		}
		last_showRayDir = showRayDir;
	}
}
@:bitmap("../assets/UI_Button_Options.png") class OptionsBitmapData extends BitmapData { }