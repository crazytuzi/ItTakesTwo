import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

class UFlyingMachineHealthWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Health);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 120;

	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

	// Settings
	FFlyingMachineSettings Settings;

	// Widget
	UFlyingMachineHealthWidget HealthWidget;

	float RecentTimer = 0.f;
	float RecentHealth = 1.f;
	float LastRecentHealth = 1.f;
	float HealthPercent = 1.f;
	bool bHasTriggeredAudioRegen = false;
	bool bDidTakeDamage = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Machine = Cast<AFlyingMachine>(Owner);
		Machine.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
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
		if (!Machine.HasPilot())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HealthWidget = Cast<UFlyingMachineHealthWidget>(Widget::AddFullscreenWidget(Machine.HealthWidgetClass));
		HealthPercent = RecentHealth = LastRecentHealth = Machine.Health / Settings.MaxHealth;
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
		HealthPercent = Machine.Health / Settings.MaxHealth;
		RecentTimer -= DeltaTime;
		if (RecentTimer < 0.f)
		{
			LastRecentHealth = HealthPercent;

			if(!bHasTriggeredAudioRegen && bDidTakeDamage)
			{
				Machine.SetCapabilityActionState(n"AudioStartDecayHealth", EHazeActionState::Active);
				bHasTriggeredAudioRegen = true;
				bDidTakeDamage = false;
			}
		}

		RecentHealth = FMath::FInterpTo(RecentHealth, LastRecentHealth, DeltaTime, 12.f);
		
		if(FMath::IsNearlyEqual(RecentHealth, LastRecentHealth, 0.01f) && bHasTriggeredAudioRegen)
		{
			Machine.SetCapabilityActionState(n"AudioStopDecayHealth", EHazeActionState::Active);
			bHasTriggeredAudioRegen = false;
		}

		HealthWidget.HealthPercent = HealthPercent;
		HealthWidget.RecentHealth = RecentHealth;
	}
}