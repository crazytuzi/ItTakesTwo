import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;

class UTreeBeetleRidingHealthWidgetCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 120;

	UTreeBeetleRidingComponent BeetleRidingComponent;
	AHazePlayerCharacter Player;

	// Widget
	UTreeBeetleRidingHealthWidget HealthWidget;

	float RecentTimer = 0.f;
	float RecentHealth = 1.f;
	float LastRecentHealth = 1.f;
	float HealthPercent = 1.f;
	bool bHasTriggeredAudioRegen = false;
	bool bDidTakeDamage = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);	
	}

	UFUNCTION()
	void HandleTakeDamage(float Damage)
	{
		RecentTimer = 0.8f;
		bHasTriggeredAudioRegen = false;
		bDidTakeDamage = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.IsMay())
			return EHazeNetworkActivation::DontActivate;

		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!BeetleRidingComponent.Beetle.bIsRunning)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!BeetleRidingComponent.Beetle.bIsRunning)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BeetleRidingComponent.Beetle.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");

		HealthWidget = Cast<UTreeBeetleRidingHealthWidget>(Widget::AddFullscreenWidget(BeetleRidingComponent.HealthWidgetClass));
		HealthPercent = RecentHealth = LastRecentHealth = BeetleRidingComponent.Beetle.Health / BeetleRidingComponent.Beetle.MaxHealth;
		RecentTimer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (BeetleRidingComponent.Beetle != nullptr)
			BeetleRidingComponent.Beetle.OnTakeDamage.Clear();

		Widget::RemoveFullscreenWidget(HealthWidget);
		HealthWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HealthPercent = BeetleRidingComponent.Beetle.Health / BeetleRidingComponent.Beetle.MaxHealth;
		RecentTimer -= DeltaTime;
		if (RecentTimer < 0.f)
		{
			LastRecentHealth = HealthPercent;	

			if(!bHasTriggeredAudioRegen && bDidTakeDamage)
			{
				BeetleRidingComponent.Beetle.SetCapabilityActionState(n"AudioStartDecayHealth", EHazeActionState::ActiveForOneFrame);
				bHasTriggeredAudioRegen = true;
				bDidTakeDamage = false;
			}
		}

		RecentHealth = FMath::FInterpTo(RecentHealth, LastRecentHealth, DeltaTime, 12.f);

		HealthWidget.HealthPercent = HealthPercent;
		HealthWidget.RecentHealth = RecentHealth;

		if(FMath::IsNearlyEqual(RecentHealth, LastRecentHealth, 0.01f) && bHasTriggeredAudioRegen)
		{
			BeetleRidingComponent.Beetle.SetCapabilityActionState(n"AudioStopDecayHealth", EHazeActionState::ActiveForOneFrame);
			bHasTriggeredAudioRegen = false;
		}
	}
}