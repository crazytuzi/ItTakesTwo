import Peanuts.Spline.SplineActor;
import Vino.Camera.Components.WorldCameraShakeComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Crusher.Level.CastleCrusherBridge;

event void FOnCrusherReachedBridge();

class ACastleCrusher : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY()
	bool bEnabled = false;

	UPROPERTY()
	AHazeActor MoveToBridgeActor;
	bool bReachedBridge = false;

	UPROPERTY()
	AHazeActor MoveToCrushActor;

	UPROPERTY()
	bool bShouldCrushPlayers = false;

	UPROPERTY()
	FOnCrusherReachedBridge OnReachedBridge;

	UPROPERTY(EditDefaultsOnly, Category = Effects)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY()
	ACastleCrusherBridge CrusherBridge;

	UPROPERTY()
	float Speed = 0.f;
	
	UFUNCTION()
	void StartCrushing()
	{
		bEnabled = true;
	}
}