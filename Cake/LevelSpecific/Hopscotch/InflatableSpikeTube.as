import Vino.PlayerHealth.PlayerHealthStatics;
class AInflatableSpikeTube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeLazyPlayerOverlapComponent KillShape;
	default KillShape.Shape.Type = EHazeShapeType::Capsule;
	default KillShape.Shape.CapsuleHalfHeight = 881.4f;
	default KillShape.Shape.CapsuleRadius = 337.28f;
	default KillShape.RelativeRotation = FRotator(0.f, 0.f, 90.f);
	default KillShape.ResponsiveDistanceThreshold = 5000.f;

	UPROPERTY()
	float TargetZValue = 500.f;

	UPROPERTY()
	bool bShowTargetLoc = false;

	UPROPERTY()
	FHazeTimeLike MoveTubeTimeline;
	default MoveTubeTimeline.bSyncOverNetwork = true;
	default MoveTubeTimeline.SyncTag = n"InflatableTubeMove";
	default MoveTubeTimeline.bLoop = true;
	default MoveTubeTimeline.bFlipFlop = true;
	default MoveTubeTimeline.Duration = 2.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveTubeTimeline.BindUpdate(this, n"MoveTubeTimelineUpdate");
		MeshRoot.SetRelativeLocation(FVector::ZeroVector);
		KillShape.OnComponentBeginOverlap.AddUFunction(this, n"KillCollisionOverlap");
		MoveTubeTimeline.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetLoc)
			MeshRoot.SetRelativeLocation(FVector(0.f, 0.f, TargetZValue));
		 else
			MeshRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.AddLocalRotation(FRotator(100.f * DeltaTime, 0.f, 0.f));
	}

	UFUNCTION()
	void MoveTubeTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(FVector::ZeroVector, FVector(0.f, 0.f, TargetZValue), CurrentValue));
	}
	
	UFUNCTION()
	void KillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		KillPlayer(Player);
	}
}