package;

import openfl.Vector;
import flixel.FlxG;
import flixel.math.FlxPoint;

typedef TVector = {
	public var x:Float;
	public var y:Float;
	public var z:Float;
}

class LVector
{
    public static var coordsMulty:Float = 50;
    public static var zOffset:Float = 0.5;

	public static var globalOffset:LVector = new LVector();

	public static var offsetX:Float = -4;
	public static var offsetY:Float = 7.5;
	public static var offsetZ:Float = 8;

	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(X:Float = 0, Y:Float = 0, Z:Float = 0)
	{
		x = X;
		y = Y;
		z = Z;
	}

	public static function fromTypedef(vector:TVector): LVector {
		return new LVector(vector.x, vector.y, vector.z);
	}

	public function toTypedef(): TVector {
		return {x:x, y:y, z:z};
	}

	public function clone():LVector {
		return new LVector(x, y, z);
	}

	@:op(A + B)
	public function plus(right:LVector):LVector
	{
		x += right.x;
		y += right.y;
		z += right.z;
		return new LVector(x, y, z);
	}

	@:op(A - B)
	public function minus(right:LVector):LVector
	{
		x -= right.x;
		y -= right.y;
		z -= right.z;
		return new LVector(x, y, z);
	}

	@:op(A * B)
	public function multyV(right:LVector):LVector
	{
		x *= right.x;
		y *= right.y;
		z *= right.z;
		return new LVector(x, y, z);
	}

	@:op(A * B)
	public function multyF(right:Float):LVector
	{
		x *= right;
		y *= right;
		z *= right;
		return new LVector(x, y, z);
	}

	@:op(A / B)
	public function divideV(right:LVector):LVector
	{
		x /= right.x;
		y /= right.y;
		z /= right.z;
		return new LVector(x, y, z);
	}

	@:op(A / B)
	public function divideF(right:Float):LVector
	{
		x /= right;
		y /= right;
		z /= right;
		return new LVector(x, y, z);
	}
    public function rotate(rotation:LVector):LVector
    { 
        var thetaX:Float = rotation.x * Math.PI / 180.0;
        var thetaY:Float = rotation.y * Math.PI / 180.0;
        var thetaZ:Float = rotation.z * Math.PI / 180.0;

        var cosX:Float = Math.cos(thetaX);
        var sinX:Float = Math.sin(thetaX);

        var cosY:Float = Math.cos(thetaY);
        var sinY:Float = Math.sin(thetaY);

        var cosZ:Float = Math.cos(thetaZ);
        var sinZ:Float = Math.sin(thetaZ);

        var oldX:Float = x;
        var oldY:Float = y;
        var oldZ:Float = z;

        y = oldY * cosX - oldZ * sinX;
        z = oldY * sinX + oldZ * cosX;

        x = oldX * cosY + z * sinY;
        z = z * cosY - oldX * sinY;

        x = x * cosZ - y * sinZ;
        y = x * sinZ + y * cosZ;

        return this;
    }
    public function toFlxPoint():FlxPoint {
		var toConvert:LVector = clone();
		toConvert.x += offsetX + globalOffset.x;
		toConvert.y += offsetY + globalOffset.y;
		toConvert.z += offsetZ + globalOffset.z;

		toConvert.x += toConvert.z * zOffset;
		toConvert.y += toConvert.z * zOffset;

        return new FlxPoint(FlxG.width * PlayState.SCENE_SCALE / 2 + toConvert.x * coordsMulty, FlxG.height * PlayState.SCENE_SCALE - toConvert.y * coordsMulty);
    }
}
class Logic {
    public static function RayCast(rayPosition:LVector, rayRotation:LVector): LVector {

        var direction = new LVector(0, -1, 0).rotate(rayRotation);

        var t:Float = -rayPosition.y / direction.y;

        var intersectionX:Float = rayPosition.x + t * direction.x;
        var intersectionZ:Float = rayPosition.z + t * direction.z;

		if (rayPosition.y <= 0) {
			return rayPosition;
		}

        return new LVector(intersectionX, 0, intersectionZ);
    }
}