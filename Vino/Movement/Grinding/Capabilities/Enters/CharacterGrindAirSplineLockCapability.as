import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.UserGrindComponent;

class UCharacterGrindAirSplineLockCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	UHazeMovementComponent MoveComp;
	UUserGrindComponent UserGrindComp;

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 109;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		UserGrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.IsSplineLocked())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!UserGrindComp.IsSplineLocked())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!UserGrindComp.IsStickOnlyLocked() && !MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!UserGrindComp.ShouldLockToSpline(GetAttributeVector(AttributeVectorNames::MovementDirection)) && !UserGrindComp.IsHardLocked())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		UserGrindComp.UnlockHorizontalSplineLock();
	}
}
