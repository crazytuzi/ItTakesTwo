import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.Hopscotch.SideContent.HoopsBallHoleFill;

class AHoopsBall : APickupActor
{
	default MeshShadowPriority = EShadowPriority::Background;

	AHazePlayerCharacter PlayerThrown;
	float PoolTimer = 3.f;
	bool bShouldTickPoolTimer = false;
	bool bHasBeenPooled = false;
	bool bBallWasPickedUp = false;

	float TeleportTimerToStart = 0.f;
	bool bShouldTickTeleportStartTimer = false;
	float TeleportTimerToPool = 0.f;
	bool bShouldTickTeleportPoolTimer = false;

	FVector CurrentStartLocation;
	FVector PoolLocation;

	UPROPERTY()
	AHoopsBallHoleFill ConnectedHoleFill;

	UPROPERTY()
	AActor PoolLocationActor;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		Mesh.GenerateOverlapEvents = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetBallEnabled(false);

		PoolLocation = PoolLocationActor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickTeleportStartTimer)
		{
			TeleportTimerToStart += DeltaTime;
			if (TeleportTimerToStart >= 1.f)
			{
				TeleportBallToStart();
				bShouldTickTeleportStartTimer = false;
			}
		}
		
		if (bShouldTickTeleportPoolTimer)
		{
			TeleportTimerToPool += DeltaTime;
			if (TeleportTimerToPool >= 1.f)
			{
				TeleportBallToPool();
				bShouldTickTeleportPoolTimer = false;
			}
		}

		if (!bShouldTickPoolTimer || !HasControl())
			return;

		PoolTimer -= DeltaTime;
		if (PoolTimer <= 0.f)
		{
			bShouldTickPoolTimer = false;
			SetBallInPool();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor) override
	{
		Super::OnPickedUpDelegate(Player, PickupActor);
		bBallWasPickedUp = true;
	}

	UFUNCTION()
	void SetBallInPool()
	{
		NetSetBallInPool();
	}

	UFUNCTION(NetFunction)
	private void NetSetBallInPool()
	{
		StopPickupFlightAfterThrow();
		TeleportTimerToPool = 1.f;
		bShouldTickTeleportPoolTimer = true;
	}

	void TeleportBallToPool()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		bHasBeenPooled = true;
		TriggerMovementTransition(this);
		TeleportActor(PoolLocation, FRotator::ZeroRotator);
		PoolTimer = 3.f;
	}

	void TeleportBallsToStartingPosition(FVector Loc)
	{
		StopPickupFlightAfterThrow();

		CurrentStartLocation = Loc;
		TeleportTimerToStart = 0.f;
		bShouldTickTeleportStartTimer = true;
	}

	void TeleportBallToStart()
	{
		if (bHasBeenPooled || bBallWasPickedUp || bShouldTickPoolTimer)
		{
			// TriggerMovementTransition(this);
			TeleportActor(CurrentStartLocation, FRotator::ZeroRotator);
		}

		bHasBeenPooled = false;
		bBallWasPickedUp = false;
		bShouldTickPoolTimer = false;
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void SetBallEnabled(bool bEnabled)
	{
		if(bEnabled)
		{
			for(auto Player : Game::GetPlayers())
			{
				InteractionComponent.EnableForPlayer(Player, n"BallDisabled");
				AttachToComponent(ConnectedHoleFill.BottomMeshRoot, n"", EAttachmentRule::KeepWorld);
			}
		}
		else
			for(auto Player : Game::GetPlayers())
			{
				InteractionComponent.DisableForPlayer(Player, n"BallDisabled");
			}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnThrownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnThrownDelegate(Player, PickupActor);
		SetBallEnabled(false);
		bShouldTickPoolTimer = true;
		PlayerThrown = Player;
	}
}