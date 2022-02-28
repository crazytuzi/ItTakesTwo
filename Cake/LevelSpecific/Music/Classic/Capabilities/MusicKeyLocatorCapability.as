import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;

class UMusicKeyLocatorCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 0;
	
	AMusicalFollowerKey PickedUpKey = nullptr;
	UMusicKeyComponent KeyComp;
	float PickupRange = 2000.0f;

	float TickFreq = 0.25f;
	float TickElapsed = 0;
	
	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		KeyComp = UMusicKeyComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!KeyComp.bPickupKeys)
			return EHazeNetworkActivation::DontActivate;

		if(KeyComp.DisableTimeCurrent > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(!KeyComp.CanPickUpKeys())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!KeyComp.bPickupKeys)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(KeyComp.DisableTimeCurrent > 0.0f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!KeyComp.CanPickUpKeys())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		KeyComp.WantedKey = nullptr;

		UHazeAITeam KeyTeam = HazeAIBlueprintHelper::GetTeam(n"MusicalKeyTeam");

		if(KeyTeam == nullptr)
			return;

		TSet<AHazeActor> KeyList = KeyTeam.GetMembers();

		for(AHazeActor KeyActor : KeyList)
		{
			AMusicalFollowerKey Key = Cast<AMusicalFollowerKey>(KeyActor);
			if(Key != nullptr)
			{
				Key.ClearPendingTarget_Local(Owner);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		UHazeAITeam KeyTeam = HazeAIBlueprintHelper::GetTeam(n"MusicalKeyTeam");

		if(KeyTeam == nullptr)
			return;

		TSet<AHazeActor> KeyList = KeyTeam.GetMembers();

		for(AHazeActor KeyActor : KeyList)
		{
			if(KeyActor.GetSquaredDistanceTo(Owner) < FMath::Square(KeyComp.PickupRange))
			{
				AMusicalFollowerKey Key = Cast<AMusicalFollowerKey>(KeyActor);
				if(Key != nullptr && !Key.HasFollowTarget() && !Key.ContainsPendingTarget(Owner) && !KeyComp.HasKey(Key) && !Key.HasReachedTargetLocation())
				{
					Key.AddPendingFollowTarget(Owner);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		KeyComp.DisableTimeCurrent -= DeltaTime;
	}
}
