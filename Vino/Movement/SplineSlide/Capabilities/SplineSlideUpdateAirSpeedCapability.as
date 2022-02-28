import Vino.Movement.MovementSystemTags;
import Vino.Movement.SplineSlide.SplineSlideComponent;
import Vino.Movement.SplineSlide.SplineSlideTags;
import Vino.Movement.Components.MovementComponent;

class USplineSlideUpdateAirSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::SplineSlide);
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 80;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	USplineSlideComponent SplineSlideComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SplineSlideComp = USplineSlideComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(SplineSlideTags::GroundMovement))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player.IsAnyCapabilityActive(SplineSlideTags::GroundMovement))
			return EHazeNetworkDeactivation::DontDeactivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		// If any other move with a higher priority activates, you should deactivate and reset
		if (!MoveComp.CanCalculateMovement())		
			return EHazeNetworkDeactivation::DeactivateLocal;			

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UMovementSettings::ClearHorizontalAirSpeed(Player, Instigator = Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
		{
			FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			UMovementSettings::SetHorizontalAirSpeed(Player, HorizontalVelocity.Size(), Instigator = Player);			
		}
	}
}