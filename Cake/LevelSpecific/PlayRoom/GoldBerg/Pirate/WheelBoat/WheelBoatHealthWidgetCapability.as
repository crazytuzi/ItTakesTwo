import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatHealthWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
    default CapabilityTags.Add(n"WheelBoat");
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 120;

	AWheelBoatActor WheelBoat;

	UWheelBoatHealthWidget HealthWidget;

	float RecentTimer = 0.f;
	float RecentHealth = 1.f;
	float LastRecentHealth = 1.f;
	float HealthPercent = 1.f;
	bool bHasTriggeredAudioRegen = false;
	bool bDidTakeDamage = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WheelBoat = Cast<AWheelBoatActor>(Owner);
		WheelBoat.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
	}

	UFUNCTION()
	void HandleTakeDamage(float Damage)
	{
		RecentTimer = 0.8f;
		bDidTakeDamage = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if(!WheelBoat.bShowHealthWidget)
            return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WheelBoat.bDocked)
            return EHazeNetworkDeactivation::DeactivateLocal;
		
		else if(WheelBoat.PlayerInLeftWheel == nullptr && WheelBoat.PlayerInRightWheel == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HealthWidget = Cast<UWheelBoatHealthWidget>(Widget::AddFullscreenWidget(WheelBoat.HealthWidgetClass));
		HealthPercent = RecentHealth = LastRecentHealth = WheelBoat.Health / WheelBoat.MaxHealth;
		RecentTimer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget::RemoveFullscreenWidget(HealthWidget);
		HealthWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HealthPercent = WheelBoat.Health / WheelBoat.MaxHealth;
		RecentTimer -= DeltaTime;
		if (RecentTimer < 0.f)
		{
			LastRecentHealth = HealthPercent;
			
			if(!bHasTriggeredAudioRegen && bDidTakeDamage)
			{
				WheelBoat.SetCapabilityActionState(n"AudioStartDecayHealth", EHazeActionState::Active);
				bHasTriggeredAudioRegen = true;
				bDidTakeDamage = false;
			}
		}

		RecentHealth = FMath::FInterpTo(RecentHealth, LastRecentHealth, DeltaTime, 12.f);

		if(FMath::IsNearlyEqual(RecentHealth, LastRecentHealth, 0.01f) && bHasTriggeredAudioRegen)
		{
			WheelBoat.SetCapabilityActionState(n"AudioStopDecayHealth", EHazeActionState::Active);
			bHasTriggeredAudioRegen = false;
		}

		HealthWidget.HealthPercent = HealthPercent;
		HealthWidget.RecentHealth = RecentHealth;
	}
}