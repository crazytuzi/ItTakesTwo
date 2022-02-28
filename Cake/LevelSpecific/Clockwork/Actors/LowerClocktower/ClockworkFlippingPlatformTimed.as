import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AClockworkFlippingPlatformTimed : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	FRotator StartingRot = FRotator::ZeroRotator;
	FRotator TargetRot = FRotator(0.f, 0.f, 90.f);

	UPROPERTY()
	FHazeTimeLike FlipPlatformTimeline;
	default FlipPlatformTimeline.Duration = 2.f;
	default FlipPlatformTimeline.bLoop = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlipPlatformTimeline.BindUpdate(this, n"FlipPlatformTimelineUpdate");

		FlipPlatformTimeline.PlayFromStart();
	}

	UFUNCTION()
	void FlipPlatformTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(QuatLerp(StartingRot, TargetRot, CurrentValue));
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