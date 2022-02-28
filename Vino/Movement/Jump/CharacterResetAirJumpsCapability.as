import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Jump.AirJumpsComponent;

class UCharacterResetAirJumpsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AirJump");
	default CapabilityTags.Add(n"AirJumpReset");
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 3;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCharacterAirJumpsComponent AirJumpsComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ResetAirJumps"))
        	return EHazeNetworkActivation::ActivateLocal;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AirJumpsComp.ResetJumpAndDash();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ConsumeAction(n"ResetAirJumps");		
	}
}
