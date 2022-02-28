import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

event void FOnObjectReachedEndEventSignature(bool IsAtEnd, AMagneticMoveableObjectConstrained Object);
class AMagneticMoveableObjectConstrained : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PullLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PushLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UMagnetGenericComponent MagnetComponent;

	UPROPERTY(DefaultComponent)
	UArrowComponent ForwardArrow;

	UPROPERTY()
	FOnObjectReachedEndEventSignature OnMoveableObjectReachedEnd;

	UPROPERTY()
	bool bReachedEnd = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PullLocation.SetHiddenInGame(true);
		PushLocation.SetHiddenInGame(true);
	}
}