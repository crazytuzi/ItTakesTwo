import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UWindWalkDashCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WindWalk");
	default CapabilityTags.Add(n"WindWalkDash");
	default CapabilityTags.Add(n"BlockWhileLedgeGrabbing");
	default CapabilityDebugCategory = n"WindWalk";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 120;

	AHazePlayerCharacter Player;
	UWindWalkComponent WindWalkComp;
	UHazeMovementComponent MoveComp;

	bool bCanDash = true;

	float DashTime;
	float DashCooldown = 0.5f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WindWalkComp = UWindWalkComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!bCanDash)
			return EHazeNetworkActivation::DontActivate;

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkActivation::DontActivate;

	    if (!WasActionStarted(ActionNames::MovementDash))
	        return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Time::GetGameTimeSeconds() > DashTime)
			return EHazeNetworkDeactivation::DeactivateLocal;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		MoveComp.AddImpulse(Player.GetActorForwardVector() * 500.f);
		MoveComp.SetAnimationToBeRequested(n"WindWalkDash");

		DashTime = Time::GetGameTimeSeconds() + DashCooldown;
		bCanDash = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bCanDash = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		/*
		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		FVector Velocity = MoveComp.Velocity;
		
		Velocity += Input * WindWalkComp.Acceleration * DeltaTime;
		Velocity -= Velocity * WindWalkComp.Drag * DeltaTime;
		Velocity += WindWalkComp.GetWindForce() * DeltaTime;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"WindWalkGroundMovement");

		FrameMove.ApplyVelocity(Velocity);
		FrameMove.ApplyAndConsumeImpulses();
		FrameMove.ApplyTargetRotationDelta();

		MoveCharacter(FrameMove, n"WindWalk");
		*/
	}
}