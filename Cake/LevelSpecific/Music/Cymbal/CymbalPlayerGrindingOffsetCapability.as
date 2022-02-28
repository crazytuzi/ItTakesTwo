import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.UserGrindComponent;

class UCymbalPlayerGrindingOffsetCapability : UHazeCapability
{
	UCymbalComponent CymbalComp;
	UUserGrindComponent GrindComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CymbalComp = UCymbalComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!GrindComp.HasActiveGrindSpline())
			return EHazeNetworkActivation::DontActivate;

		if(MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		const FVector RelativeLocation(0.0f, 0.0f, 50.0f);
		const FRotator RelativeRotation(0.0f, 0.0f, 0.0);

		CymbalComp.SetCymbalOffset(RelativeLocation, RelativeRotation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!GrindComp.HasActiveGrindSpline())
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
