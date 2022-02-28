import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;
import Cake.LevelSpecific.Tree.Beetle.Health.BeetleHealthComponent;

// Just let beetle fall/slide to a stop. Locally simulated, used after beetle is defeated.
class UBeetleSlideToStopMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Defeat");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 50; // Before others

	UBeetleBehaviourComponent BehaviourComp = nullptr;
	UBeetleHealthComponent HealthComp = nullptr;
    
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
		HealthComp = UBeetleHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
    	 	return EHazeNetworkActivation::DontActivate;
		if (HealthComp.RemainingHealth > 0)
    		return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		BehaviourComp.LogEvent("Activating defeat slide.");
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement Move = MoveComp.MakeFrameMovement(n"BeetleLeap");
		Move.OverrideStepUpHeight(100.f);
		Move.OverrideStepDownHeight(0.f);
		FVector HorizontalVelocity = MoveComp.GetVelocity();
		HorizontalVelocity.Z = 0.f;
		if (!MoveComp.IsAirborne())
		{
			FVector Friction = HorizontalVelocity * 1.5f * DeltaTime;
			if (Friction.SizeSquared() > HorizontalVelocity.SizeSquared())
				HorizontalVelocity = FVector::ZeroVector;
			else
				HorizontalVelocity -= Friction;
		}
		Move.ApplyVelocity(HorizontalVelocity);
		Move.ApplyActorVerticalVelocity();
		Move.ApplyGravityAcceleration();
		MoveCharacter(Move, n"LeapTo");

		if (!HasControl())
		{
			// Consume and ignore crumbs
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		}
	}
};
