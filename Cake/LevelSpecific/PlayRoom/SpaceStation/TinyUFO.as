event void FTinyUFOEvent();

class ATinyUFO : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent UfoRoot;

	UPROPERTY(DefaultComponent, Attach = UfoRoot)
	UStaticMeshComponent UfoMesh;

	UPROPERTY(DefaultComponent, Attach = UfoRoot)
	UStaticMeshComponent LandingGear;

	UPROPERTY(DefaultComponent, Attach = UfoRoot)
	UCapsuleComponent PlayerTrigger;

	UPROPERTY()
	FTinyUFOEvent OnPlayerAbducted;

	FHazeTimeLike AbductPlayerTimeLike;
	default AbductPlayerTimeLike.Duration = 0.25f;

	FVector PlayerStartLoc;

	bool bPlayerAbducted = false;
	AHazePlayerCharacter AbductedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");

		AbductPlayerTimeLike.BindUpdate(this, n"UpdateAbductPlayer");
		AbductPlayerTimeLike.BindFinished(this, n"FinishAbductPlayer");
	}

	UFUNCTION()
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.IsMay())
			return;

		if (bPlayerAbducted)
			return;

		AbductedPlayer = Player;
		bPlayerAbducted = true;
		PlayerStartLoc = Player.ActorLocation;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		AbductPlayerTimeLike.PlayFromStart();
		Player.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateAbductPlayer(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(PlayerStartLoc, UfoRoot.WorldLocation + FVector(0.f, 0.f, 65.f), CurValue);
		AbductedPlayer.SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishAbductPlayer()
	{
		if (bPlayerAbducted)
		{
			OnPlayerAbducted.Broadcast();
		}
		else
		{
			AbductedPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
			AbductedPlayer.UnblockCapabilities(CapabilityTags::Collision, this);
		}
	}

	UFUNCTION()
	void ReleasePlayer()
	{
		bPlayerAbducted = false;
		AbductPlayerTimeLike.ReverseFromEnd();
	}
}