import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UWindWalkJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"WindWalk");
	default CapabilityTags.Add(n"WindWalkJump");
	default CapabilityDebugCategory = n"WindWalk";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 119;

	AHazePlayerCharacter Player;
	UWindWalkComponent WindWalkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		WindWalkComp = UWindWalkComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
	    if (!WasActionStarted(ActionNames::MovementJump))
	        return EHazeNetworkActivation::DontActivate;

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkActivation::DontActivate;

		if (!ShouldBeGrounded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!WasActionStarted(ActionNames::MovementJump))
	        return EHazeNetworkDeactivation::DeactivateLocal;

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveComp.AddImpulse(FVector::UpVector * 500.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}