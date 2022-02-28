
// Automatically make overlaps lazy for passed in components
class ULazyPlayerOverlapManagerComponent : UActorComponent
{
	// If player is further away from the actor than this don't check any overlaps
	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float ActorOverallMaxDistance = 0.f;

	// Players closer than this distance will update overlaps every frame
	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float ActorResponsiveDistance = 2500.f;

	private TArray<UPrimitiveComponent> Components;
	private TArray<bool> States;
	private bool bLazyOverlapsEnabled = true;
	private bool bRandomizeStartTick = true;

	UFUNCTION()
	void SetLazyOverlapsEnabled(bool bEnabled)
	{
		if (bEnabled && !bLazyOverlapsEnabled)
		{
			bLazyOverlapsEnabled = true;
			bRandomizeStartTick = true;
			SetComponentTickEnabled(true);
			SetComponentTickInterval(0.f);
		}
		else if (!bEnabled && bLazyOverlapsEnabled)
		{
			bLazyOverlapsEnabled = false;
			SetComponentTickEnabled(false);
		}
	}

	UFUNCTION()
	void MakeOverlapsLazy(UPrimitiveComponent Primitive)
	{
		Components.Add(Primitive);
		States.Add(false);
		States.Add(false);
		Primitive.bGenerateOverlapEvents = false;
	}

	UFUNCTION()
	void MakeOverlapsLazyMultiple(TArray<UPrimitiveComponent> Primitives)
	{
		for (auto Primitive : Primitives)
			MakeOverlapsLazy(Primitive);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (int PlayerIndex = 0; PlayerIndex < 2; ++PlayerIndex)
		{
			auto Player = Game::GetPlayer(EHazePlayer(PlayerIndex));
			for (int i = 0, Count = Components.Num(); i < Count; ++i)
			{
				if (Components[i] == nullptr)
					continue;
				int StateIndex = i*2 + PlayerIndex;
				if (States[StateIndex])
				{
					UHazeLazyPlayerOverlapComponent::TriggerEndOverlap(Player, Components[i]);
					States[StateIndex] = false;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float MinDistanceSQ = MAX_flt;
		for (int PlayerIndex = 0; PlayerIndex < 2; ++PlayerIndex)
		{
			auto Player = Game::GetPlayer(EHazePlayer(PlayerIndex));
			float PlayerDistanceSQ = Player.GetSquaredDistanceTo(Owner);
			if (PlayerDistanceSQ < MinDistanceSQ)
				MinDistanceSQ = PlayerDistanceSQ;

			if (ActorOverallMaxDistance <= 0.f || PlayerDistanceSQ <= FMath::Square(ActorOverallMaxDistance))
			{
				auto PlayerCapsule = Player.CapsuleComponent;
				FVector PlayerLoc = Player.ActorLocation;
				FQuat PlayerQuat = Player.ActorQuat;
				for (int i = 0, Count = Components.Num(); i < Count; ++i)
				{
					if (Components[i] == nullptr)
						continue;

					bool bOverlaps = Trace::ComponentOverlapComponent(
						Components[i], PlayerCapsule, PlayerLoc, PlayerQuat
					);

					int StateIndex = i*2 + PlayerIndex;
					if (States[StateIndex] != bOverlaps)
					{
						if (bOverlaps)
							UHazeLazyPlayerOverlapComponent::TriggerBeginOverlap(Player, Components[i]);
						else
							UHazeLazyPlayerOverlapComponent::TriggerEndOverlap(Player, Components[i]);
						States[StateIndex] = bOverlaps;
					}
				}
			}
			else
			{
				for (int i = 0, Count = Components.Num(); i < Count; ++i)
				{
					if (Components[i] == nullptr)
						continue;

					int StateIndex = i*2 + PlayerIndex;
					if (States[StateIndex])
					{
						UHazeLazyPlayerOverlapComponent::TriggerEndOverlap(Player, Components[i]);
						States[StateIndex] = false;
					}
				}
			}
		}

		if (ActorResponsiveDistance > 0.f)
		{
			float RespDistSQ = FMath::Square(ActorResponsiveDistance);
			if (MinDistanceSQ < RespDistSQ)
			{
				SetComponentTickInterval(0.f);
			}
			else
			{
				float WantedTickInterval = FMath::Clamp(FMath::Lerp(
					0.f, 1.f, (MinDistanceSQ - RespDistSQ) / RespDistSQ
				), 0.f, 1.f);

				if (bRandomizeStartTick)
				{
					WantedTickInterval = FMath::RandRange(0.f, WantedTickInterval);
					bRandomizeStartTick = false;
				}

				SetComponentTickInterval(WantedTickInterval);
			}
		}
		else if (bRandomizeStartTick)
		{
			SetComponentTickInterval(FMath::RandRange(0.f, 1.f));
			bRandomizeStartTick = false;
		}
		else
		{
			SetComponentTickInterval(1.f);
		}
	}
};