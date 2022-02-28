import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Vino.Movement.Swinging.SwingComponent;

class UCymbalPlayerSwingingOffsetCapability : UHazeCapability
{
	UCymbalComponent CymbalComp;
	USwingingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CymbalComp = UCymbalComponent::Get(Owner);
		SwingComp = USwingingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SwingComp.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		const FVector RelativeLocation(0.0f, 0.0f, 45.0f);
		const FRotator RelativeRotation = FRotator::ZeroRotator;

		CymbalComp.SetCymbalOffset(RelativeLocation, RelativeRotation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SwingComp.IsSwinging())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CymbalComp.ResetCymbalOffsetValue(0.5f);
	}
}
