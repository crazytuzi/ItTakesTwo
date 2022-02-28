import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;

class UWaspIntensifyAggressionCapability : UHazeCapability
{
	UWaspComposableSettings Settings;
	UWaspHealthComponent HealthComp;
	int NextThreshold = 0; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        // Set common references 
		HealthComp = UWaspHealthComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
		ensure((HealthComp != nullptr) && (Settings != nullptr));

		UWaspRespawnerComponent RespawnComp = UWaspRespawnerComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnReset.AddUFunction(this, n"Reset");
	}

	UFUNCTION()
	void Reset()
	{
		Owner.ClearSettingsByInstigator(this);
		Owner.RemoveAllCapabilitySheetsByInstigator(this);
		NextThreshold = 0;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Settings.AggressionThresholds.IsValidIndex(NextThreshold))
    		return EHazeNetworkActivation::DontActivate;

		if (HealthComp.GetHealthFraction() > Settings.AggressionThresholds[NextThreshold].HealthFraction)
    		return EHazeNetworkActivation::DontActivate;
			
		// We've reached next health fraction
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Clear any previous Settings and apply new ones
		Owner.ClearSettingsByInstigator(this);
		if (Settings.AggressionThresholds[NextThreshold].Settings != nullptr)
			Owner.ApplySettings(Settings.AggressionThresholds[NextThreshold].Settings, this, EHazeSettingsPriority::Gameplay);

		// Remove any previous capability sheet (i.e. return to base behaviour unless we set a new sheet)
		Owner.RemoveAllCapabilitySheetsByInstigator(this);
		if (Settings.AggressionThresholds[NextThreshold].CapabilitySheet != nullptr)
			Owner.AddCapabilitySheet(Settings.AggressionThresholds[NextThreshold].CapabilitySheet);

		NextThreshold++;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Reset();
	}
}