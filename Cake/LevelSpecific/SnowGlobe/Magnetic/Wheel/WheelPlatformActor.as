import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelActor;

UCLASS(Abstract)
class AWheelPlatformActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent Platform;

	UPROPERTY()
	AMagneticWheelActor Wheel;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"WheelPlatformMovementCapability");
	}
}