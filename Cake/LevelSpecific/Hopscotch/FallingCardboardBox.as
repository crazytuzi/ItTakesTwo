import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class AFallingCardboardBox : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	FHazeTimeLike FallingTimeline;
	default FallingTimeline.Duration = 2.f;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialLocation = Mesh.RelativeLocation;

		FActorImpactedByPlayerDelegate OnActorDownImpactedByPlayer;
		OnActorDownImpactedByPlayer.BindUFunction(this, n"Impact");

		FallingTimeline.BindUpdate(this, n"FallingTimelineUpdate");
		FallingTimeline.BindFinished(this, n"FallingTimelineFinished");
		
		BindOnDownImpactedByPlayer(this, OnActorDownImpactedByPlayer);
	}

	UFUNCTION()
	void FallingTimelineUpdate(float CurrentValue)
	{
		Mesh.SetRelativeLocation(FMath::VLerp(InitialLocation, TargetLocation, (FVector(CurrentValue, CurrentValue, CurrentValue))));
	}

	UFUNCTION()
	void FallingTimelineFinished(float CurrentValue)
	{

	}

	UFUNCTION()
	void Impact(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit)
	{

	}
}