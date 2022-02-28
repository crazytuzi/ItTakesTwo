import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

UCLASS(Abstract)
class ATimeControlDoubleHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftHatchRoot;

	UPROPERTY(DefaultComponent, Attach = LeftHatchRoot)
	UStaticMeshComponent LeftHatchMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightHatchRoot;

	UPROPERTY(DefaultComponent, Attach = RightHatchRoot)
	UStaticMeshComponent RightHatchMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UTimeControlActorComponent TimeControlComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeControlComp.TimeIsChangingEvent.AddUFunction(this, n"TimeChanging");
	}

	UFUNCTION(NotBlueprintCallable)
	void TimeChanging(float Time)
	{
		float LeftHatchRot = FMath::Lerp(0.f, -90.f, Time);
		LeftHatchRoot.SetRelativeRotation(FRotator(0.f, 0.f, LeftHatchRot));

		float RightHatchRot = FMath::Lerp(90.f, 0.f, Time);
		RightHatchRoot.SetRelativeRotation(FRotator(0.f, 0.f, RightHatchRot));
	}
}