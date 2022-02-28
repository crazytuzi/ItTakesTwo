import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledJumpCameraSettings;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledState;

USTRUCT()
struct FBoatsledJumpParams
{
	UPROPERTY()
	FVector LandingLocation;

	UPROPERTY()
	float JumpHeight;

	UPROPERTY()
	UHazeSplineComponent TrackSplineComponent;

	UPROPERTY()
	EBoatsledState NextBoatsledState;

	UPROPERTY()
	FBoatsledJumpCameraSettings JumpCameraSettings;
}