namespace FollowCloudAvoidance
{
	const FName TeamName = n"FollowCloudAvoidanceTeam";
}

class UFollowCloudRepulsorComponent : USceneComponent
{
	// Up to this distance repulsion effect will be at maximum
	UPROPERTY()
	float InnerRadius = 1000.f;

	// How far away repulsion effect will start having any effect
	UPROPERTY()
	float OuterRadius = 2000.f;

	// We push away with this force within inner radius, with the force petering down to zero at outer radius
	UPROPERTY()
	float RepulseForce = 100.f;

	UFUNCTION(BlueprintPure)
	bool CanRepulse(FVector RepulseeLoc)
	{
		return RepulseeLoc.IsNear(WorldLocation, OuterRadius);
	}

	UFUNCTION(BlueprintPure)
	FVector GetRepulsionForce(FVector RepulseeLoc)
	{
		FVector AvoidanceDir; 
		float Dist = BIG_NUMBER; 
		(RepulseeLoc - WorldLocation).ToDirectionAndLength(AvoidanceDir, Dist);
		float Force = FMath::GetMappedRangeValueClamped(FVector2D(InnerRadius, OuterRadius), FVector2D(RepulseForce, 0.f), Dist);
		return AvoidanceDir * Force;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cast<AHazeActor>(Owner).JoinTeam(FollowCloudAvoidance::TeamName);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Cast<AHazeActor>(Owner).LeaveTeam(FollowCloudAvoidance::TeamName);
	}
}

class AFollowCloudRepulsorActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Engine/EngineResources/Cursors/SplitterHorz");
	default Billboard.bIsEditorOnly = true;
	default Billboard.RelativeScale3D = 30.f;

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UFollowCloudRepulsorComponent RepulsorComp;
}
