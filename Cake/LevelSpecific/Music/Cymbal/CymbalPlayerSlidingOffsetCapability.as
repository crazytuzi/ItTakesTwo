import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Vino.Movement.MovementSystemTags;

class UCymbalPlayerSlidingOffsetCapability : UHazeCapability
{
	UCymbalComponent CymbalComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CymbalComp = UCymbalComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Owner.IsAnyCapabilityActive(MovementSystemTags::SlopeSlide))
			return EHazeNetworkActivation::DontActivate;

		if(MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//const FVector RelativeLocation(20.0f, 0.0f, 50.0f);
		const FVector RelativeLocation(20.0f, 0.0f, 10.0f);
		const FRotator RelativeRotation(0.0f, 25.0f, 0.0f);

		CymbalComp.SetCymbalOffset(RelativeLocation, RelativeRotation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Owner.IsAnyCapabilityActive(MovementSystemTags::SlopeSlide))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CymbalComp.ResetCymbalOffsetValue(0.5f);
	}
}
