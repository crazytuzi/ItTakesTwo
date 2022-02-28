import Vino.PlayerHealth.PlayerHealthComponent;

class UPlayerVisibilityCapability : UHazeCollisionEnableCapability
{
	default RespondToEvent(n"NeverActivate");
	default CapabilityTags.Add(CapabilityTags::Visibility);

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	int BlockCounter = 0;

	TArray<AActor> HiddenActors;
	TArray<USceneComponent> HiddenComponents;

 	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
			HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		if (BlockCounter == 0)
		{
			if (Player != nullptr)
				Player.SetActorHiddenInGame(true);
			if (HealthComp != nullptr)
				HealthComp.bVisibilityBlocked = true;

			TArray<USceneComponent> Comps;
			Comps.Reserve(32);
			Comps.Add(Player.RootComponent);

			int CheckIndex = 0;

			while (CheckIndex < Comps.Num())
			{
				USceneComponent Comp = Comps[CheckIndex];

				// Check if we should hide this specific component
				if (Comp.Owner != Owner)
				{
					if (Comp.Owner != nullptr && Comp.Owner.RootComponent == Comp)
					{
						// If an actor's root is attached to us, hide that whole actor
						if (!Comp.Owner.bHidden)
						{
							HiddenActors.Add(Comp.Owner);
							Comp.Owner.SetActorHiddenInGame(true);
						}
					}
					else
					{
						// Set visibility on this component only
						if (Comp.IsVisible())
						{
							Comp.SetVisibility(false);
							HiddenComponents.Add(Comp);
						}
					}
				}

				// Recurse through children of this component
				for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
				{
					auto Child = Comp.GetChildComponent(i);
					if (Child != nullptr)
						Comps.AddUnique(Child);
				}

				CheckIndex += 1;
			}
		}
		BlockCounter += 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		BlockCounter -= 1;
		if (BlockCounter == 0)
		{
			if (Player != nullptr)
				Player.SetActorHiddenInGame(false);
			if (HealthComp != nullptr)
				HealthComp.bVisibilityBlocked = false;

			// Unhide attached actors
			for (int i = 0, Count = HiddenActors.Num(); i < Count; ++i)
			{
				if (HiddenActors[i] != nullptr)
					HiddenActors[i].SetActorHiddenInGame(false);
			}
			HiddenActors.Empty();

			// Unhide attached components
			for (int i = 0, Count = HiddenComponents.Num(); i < Count; ++i)
			{
				if (HiddenComponents[i] != nullptr)
					HiddenComponents[i].SetVisibility(true);
			}
			HiddenActors.Empty();
		}
	}
};