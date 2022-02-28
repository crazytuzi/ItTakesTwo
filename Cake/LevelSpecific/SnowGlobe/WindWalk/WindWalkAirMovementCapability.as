import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UWindWalkAirMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"WindWalk");
	default CapabilityDebugCategory = n"WindWalk";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 124;

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
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkActivation::DontActivate;

		if (ShouldBeGrounded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!WindWalkComp.bIsWindWalking)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"WindWalkAirMovement");

		if (HasControl())
		{
			UMovementSettings MovementSettings = UMovementSettings::GetSettings(Player);

			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector Velocity = MoveComp.Velocity;
			
			Velocity += Input * WindWalkComp.Acceleration * DeltaTime;
			Velocity += MoveComp.Gravity * 2.f * DeltaTime;
			Velocity -= Velocity * WindWalkComp.Drag * DeltaTime;
		//	Velocity += WindWalkComp.GetWindForce() * DeltaTime;
			Velocity += WindWalkComp.CurrentForce * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.ApplyTargetRotationDelta();

			MoveCharacter(FrameMove, n"WindWalk");

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"WindWalk");
		}
	}
}
