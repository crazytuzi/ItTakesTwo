import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AClockworkRotatingTimeCog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTimeControlActorComponent TimeControlComp;
	default TimeControlComp.TimeStepMultiplier = 0.5f;

	UPROPERTY()
	float TargetZRotation;

	FRotator StartingRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeControlComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");

		StartingRotation = MeshRoot.RelativeRotation;
		TargetRotation = FRotator(MeshRoot.RelativeRotation.Pitch, MeshRoot.RelativeRotation.Yaw + TargetZRotation, MeshRoot.RelativeRotation.Roll);
	}

	UFUNCTION()
	void TimeIsChanging(float CurrentPointInTime)
	{
		MeshRoot.SetRelativeRotation(QuatLerp(StartingRotation, TargetRotation, CurrentPointInTime));
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}