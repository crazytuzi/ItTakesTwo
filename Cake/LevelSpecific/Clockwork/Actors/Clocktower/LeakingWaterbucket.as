import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Vino.Pickups.PlayerPickupComponent;

class ALeakingWaterBucket : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WaterSplashFX;
	default WaterSplashFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UTimeControlActorComponent TimeControl;
	default TimeControl.bCanBeTimeControlled = false;
	default TimeControl.bAddConstantProgression = false;
	default TimeControl.ConstantIncreaseValue = 0.25f;
	default TimeControl.StartingPointInTime = 1.f;

	AHazePlayerCharacter PlayerHoldingBucket;

	bool bEverHadWater = false;

	UFUNCTION(BlueprintPure)
	float GetWaterLevel()
	{
		return 1.f - TimeControl.GetPointInTime();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"CanPlayerInteract");
		InteractionComponent.AddTriggerCondition(n"ActivationPoint", Condition);
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerInteract(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		// If the trigger owner has an activation point, we only focus on the trigger if the activaiton point is focused
		if (TimeControl.bCanBeTimeControlled)
		{
			UHazeActivationPoint ActivationPoint = UHazeActivationPoint::Get(TriggerComponent.GetOwner());
			if(ActivationPoint != nullptr)
			{
				return ActivationPoint.IsTargetedBy(PlayerCharacter);
			}

			return false;
		}
		else
		{
			return true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Water = GetWaterLevel();

		bool bShouldLeak = (Water > 0.f);
		if (TimeControl.bIsCurrentlyBeingTimeControlled)
			bShouldLeak = false;

		if (bShouldLeak && !WaterSplashFX.IsActive())
			WaterSplashFX.Activate();
		else if (!bShouldLeak && WaterSplashFX.IsActive())
			WaterSplashFX.Deactivate();
	}

	void StartLeakingWater()
	{
		bEverHadWater = true;
		WaterSplashFX.Activate();
		TimeControl.bCanBeTimeControlled = true;
		TimeControl.bAddConstantProgression = true;
		TimeControl.ManuallySetPointInTime(0.f);
	}

	void EmptyWaterInBucket()
	{
		TimeControl.ManuallySetPointInTime(1.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPickedUpDelegate(Player, PickupActor);

		PlayerHoldingBucket = Player;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPutDownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPutDownDelegate(Player, PickupActor);

		PlayerHoldingBucket = nullptr;
	}

	void ForcePlayerToDropBucket()
	{
		if (PlayerHoldingBucket != nullptr)
		{
			UPlayerPickupComponent::Get(PlayerHoldingBucket).ForceDrop(false);
		}
	}

	void ForcePlayerToPickupBucket(AHazePlayerCharacter Player)
	{
		UPlayerPickupComponent::Get(Player).ForcePickUp(this, true);
	}
}