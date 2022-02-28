import Vino.Interactions.InteractionComponent;

UCLASS(Abstract)
class AOrganPipe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PipeMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractionComponent InteractionPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent Trigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent WindEffect;

	UPROPERTY()
	TArray<AOrganPipe> ConnectedPipes;

	UPROPERTY(meta = (MakeEditWidget))
	TArray<FTransform> TargetTransforms;

	int CurrentStrength = 0;

	bool bOpeningBlocked = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionPoint.OnActivated.AddUFunction(this, n"InteractionActivated");
		InteractionPoint.DisableForPlayer(Game::GetMay(), n"May");

		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
    }

    UFUNCTION()
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionPoint.Disable(n"Used");
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		bOpeningBlocked = true;
		WindEffect.SetHiddenInGame(true);

		for (AOrganPipe CurPipe : ConnectedPipes)
		{
			CurPipe.IncreaseStrength();
		}
    }

	void IncreaseStrength()
	{
		CurrentStrength++;
		WindEffect.SetWorldScale3D(FVector(0.5f, 0.5f, WindEffect.WorldScale.Z * 2));
	}

	void DecreaseStrength()
	{
		CurrentStrength--;
		WindEffect.SetWorldScale3D(FVector(0.5f, 0.5f, WindEffect.WorldScale.Z / 2));
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (bOpeningBlocked)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		FHazeJumpToData JumpToData;
		FVector WorldLoc = ActorTransform.TransformPosition(TargetTransforms[CurrentStrength].Location);
		FQuat WorldRot = ActorTransform.TransformRotation(FQuat(TargetTransforms[CurrentStrength].Rotation));
		JumpToData.Transform.Location = WorldLoc;
		JumpToData.Transform.Rotation = WorldRot;
		JumpTo::ActivateJumpTo(Player, JumpToData);
	}

	UFUNCTION()
	void BlockOpening()
	{

	}
}