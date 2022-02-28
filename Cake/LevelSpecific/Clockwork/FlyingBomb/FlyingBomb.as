import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Vino.Interactions.Widgets.InteractionWidget;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Peanuts.Audio.AudioStatics; 
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBombCrosshair;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkOutsideVOBank;

enum EFlyingBombState
{
	Idle,
	HeldByBird,
	Falling,
	Chasing,
	GoingBack,
	Exploded,
};

class AFlyingBomb : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent VisualOffset;

	UPROPERTY(DefaultComponent, Attach = VisualOffset)
	USceneComponent VisualRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GrabWidgetRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeLazyPlayerOverlapComponent NearbySphere;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::High;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.f;

	UPROPERTY(DefaultComponent)
	UFlyingBombVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UClockworkOutsideVOBank VOBank;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingBombEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingBombEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PickUpFlyingBombEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DropFlyingBombEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExploFlyingBombEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFallFlyingBombEvent;

	/* Amount of time a bomb can be held before it explodes. */
	UPROPERTY(BlueprintReadOnly)
	float MaxHeldTime = 0.f;

	/* Radius from the start position where this bomb roams while idle. */
	UPROPERTY(BlueprintReadOnly)
	float IdleRadius = 500.f;

	/* Radius where if the player picks up a bomb within this radius the bombs will aggro. */
	UPROPERTY(BlueprintReadOnly)
	float AggroRadius = 3500.f;

	/* Radius where if the player is further away than this the bombs will give up chasing. */
	UPROPERTY(BlueprintReadOnly)
	float EscapeRadius = 8000.f;

	/* Radius where the widget to grab the bomb shows up from. */
	UPROPERTY(BlueprintReadOnly)
	float GrabWidgetDistance = 15000.f;

	/* Radius within which the player is able to pick up the bomb. */
	UPROPERTY(BlueprintReadOnly)
	float GrabDistance = 5000.f;

	/* Grace radius that the bomb can still be picked up if it is behind the bird. */
	UPROPERTY(BlueprintReadOnly)
	float GrabBehindDistance = 250.f;

	// Current state of the bomb's AI
	UPROPERTY(BlueprintReadOnly, NotEditable)
	EFlyingBombState CurrentState = EFlyingBombState::Idle;

	// Curve for bombs to get closer to the bird while chasing
	UPROPERTY()
	UCurveFloat ChaseCurve;

	// Duration that the player has a point of interest on the bomb after dropping it
	UPROPERTY(Category = "Dropped Bomb Camera")
	float DroppedBombPOIDuration = 2.f;

	// Blend time for the dropped bomb POI
	UPROPERTY(Category = "Dropped Bomb Camera")
	float DroppedBombPOIBlend = 1.f;

	// How long input on the bird is blocked after dropping bomb
	UPROPERTY(Category = "Dropped Bomb Camera")
	float DroppedBombInputBlockDuration = 0.f;

	// Camera settings applied while the player has a POI on the dropped bomb
	UPROPERTY(Category = "Dropped Bomb Camera")
	UHazeCameraSettingsDataAsset DroppedBombCameraSettings;

	// Whether to automatically remove the dropped bomb point of interest after the bomb explodes
	UPROPERTY(Category = "Dropped Bomb Camera")
	bool bDroppedBombRemovePoIOnExplode = false;

	// Currently targeted bird by the bomb
	AClockworkBird HeldByBird;
	float HeldSinceGameTime = 0.f;

	AClockworkBird ChasingBird;
	UBirdFlyingBombTrackerComponent ChasingTracker;

	TArray<AClockworkBird> NearbyBirds;

	AClockworkBird LocalWantHeldByBird;
	AHazePlayerCharacter LastHeldPlayer;

	const float IdleMaxVelocity = 125.f;
	const float IdleAcceleration = 5.f;
	const float IdleTargetReachedDistance = 100.f;
	const float IdleMaxTiltPitch = 25.f;

	const float BombFallGravity = 5000.f;

	const float ChaseTargetDelay = 1.f;
	const float ChaseEstablishTime = 1.f;
	const float ChaseCatchupTime = 2.f;

	const float RespawnDelay = 10.f;

	FVector StartPosition;
	FRotator StartRotation;

	UFUNCTION(BlueprintEvent)
	void BP_OnStateChanged(EFlyingBombState NewState) {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void EnableInWorld()
	{
		EnableActor(nullptr);
		DisableComp.bRenderWhileDisabled = true;
	}

	void SetState(EFlyingBombState NewState) property
	{
		CurrentState = NewState;
		BP_OnStateChanged(NewState);

		if (HasActorBegunPlay())
		{
			if (NewState == EFlyingBombState::Idle)
				DisableComp.SetUseAutoDisable(true);
			else
				DisableComp.SetUseAutoDisable(false);
		}
	}

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		NearbySphere.Shape.InitializeAsSphere(
			FMath::Max(AggroRadius,
			FMath::Max(GrabWidgetDistance,
				GrabDistance))
		);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		MoveComp.Setup(Collision);
		StartPosition = ActorLocation;
		StartRotation = ActorRotation;

		AddCapability(n"FlyingBombIdleCapability");
		AddCapability(n"FlyingBombLocalPreHeldCapability");
		AddCapability(n"FlyingBombHeldCapability");
		AddCapability(n"FlyingBombExplodeCapability");
		AddCapability(n"FlyingBombFallCapability");

		NearbySphere.DetachFromParent(bMaintainWorldPosition=true);
        NearbySphere.OnComponentBeginOverlap.AddUFunction(this, n"NearbyBeginOverlap");
        NearbySphere.OnComponentEndOverlap.AddUFunction(this, n"NearbyEndOverlap");
		
		HazeAkComp.HazePostEvent(StartFlyingBombEvent);
		HazeAkComp.SetTrackVelocity(true, 1000.f);
	}

	void TryPickupBomb(AClockworkBird ByBird)
	{
		VisualOffset.FreezeAndResetWithTime(0.2f);
		if (HasControl())
		{
			NetSetHoldingBird(ByBird);
		}
		else
		{
			if (HeldByBird != ByBird)
			{
				ensure(HeldByBird == nullptr);
				if (HeldByBird == nullptr)
					LocalWantHeldByBird = ByBird;
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetHoldingBird(AClockworkBird Bird)
	{
		if (HeldByBird != nullptr)
			HeldByBird.bIsHoldingBomb = false;
		HeldByBird = Bird;
		if (HeldByBird != nullptr)
			{
				HeldByBird.bIsHoldingBomb = true;
				HazeAkComp.HazePostEvent(StopFlyingBombEvent);
				HazeAudio::SetPlayerPanning(HazeAkComp, LastHeldPlayer);
			}
	}

    UFUNCTION()
    void NearbyBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			auto Tracker = UBirdFlyingBombTrackerComponent::GetOrCreate(Player);
			Tracker.NearbyBombs.Add(this);

			auto Bird = GetPlayerBird(Player);
			if (Bird != nullptr)
				NearbyBirds.Add(Bird);
		}
    }

    UFUNCTION()
    void NearbyEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			auto Tracker = UBirdFlyingBombTrackerComponent::Get(Player);
			if (Tracker != nullptr)
				Tracker.NearbyBombs.Remove(this);

			for (int i = NearbyBirds.Num() - 1; i >= 0; --i)
			{
				if (NearbyBirds[i] == nullptr || NearbyBirds[i].ActivePlayer == nullptr || NearbyBirds[i].ActivePlayer == Player)
					NearbyBirds.RemoveAt(i);
			}
		}
    }
};

AClockworkBird GetPlayerBird(AHazePlayerCharacter Player)
{
	auto FlyingComp = UClockworkBirdFlyingComponent::Get(Player);
	if (FlyingComp == nullptr)
		return nullptr;
	return FlyingComp.MountedBird;
}

class UBirdFlyingBombTrackerComponent : UActorComponent
{
	const int MaxChasingBombs = 6;

	TArray<AFlyingBomb> ChasingBombs;
	int BombCounter = 0;
	float LastBombFireGameTime = 0.f;

	TArray<AFlyingBomb> NearbyBombs;
	AFlyingBomb HeldBomb;
	AFlyingBomb FollowDroppedBomb;

	FVector GetChaseSlot(int BombNumber)
	{
		float Spacing = 250.f;
		switch (BombNumber % 6)
		{
			case 0: return FVector(0.f, 0.f, 0.f) * Spacing;
			case 1: return FVector(0.1f, -0.9f, 0.6f) * Spacing;
			case 2: return FVector(0.2f, -1.2f, -0.5f) * Spacing;
			case 3: return FVector(0.f, 1.f, 0.f) * Spacing;
			case 4: return FVector(0.f, 2.f, -0.75f) * Spacing;
			case 5: return FVector(-0.3f, -2.f, 0.25f) * Spacing;
		}

		return FVector(0.f, 0.f, 0.f);
	}
};

class UFlyingBombVisualizerComponent : UActorComponent
{
};

class UFlyingBombVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFlyingBombVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AFlyingBomb Bomb = Cast<AFlyingBomb>(Component.Owner);
		if (Bomb == nullptr)
			return;

		DrawWireSphere(Bomb.ActorLocation, Bomb.IdleRadius, FLinearColor::White, Thickness = 6.f);
		DrawWireSphere(Bomb.ActorLocation, Bomb.AggroRadius, FLinearColor::Red, Thickness = 6.f);
		DrawWireSphere(Bomb.ActorLocation, Bomb.EscapeRadius, FLinearColor::Green, Thickness = 6.f);
	}
};