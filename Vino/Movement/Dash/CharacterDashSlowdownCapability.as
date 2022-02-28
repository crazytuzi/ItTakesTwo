import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Dash.CharacterDashComponent;

class UCharacterDashSlowdownCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MovementSystemTags::Dash);
	default CapabilityTags.Add(n"DashSlowdown");

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 130;
	
	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterDashComponent DashComp;
	FCharacterDashSlowdownSettings DashSlowdownSettings;

	float DecelerationSpeed = 0.f;
	bool bShouldActivate;
	uint NetIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DashComp.ConsumeDashEnded())
			bShouldActivate = true;
		else
			bShouldActivate = false;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!bShouldActivate)
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.IsGrounded())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= DashSlowdownSettings.Duration)
       		return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		float InputSize = GetAttributeVector(AttributeVectorNames::MovementDirection).Size();
		float TargetSpeed = MoveComp.MoveSpeed * InputSize;
		float SpeedDifference = TargetSpeed - MoveComp.Velocity.Size();
		DecelerationSpeed = FMath::Abs(SpeedDifference / DashSlowdownSettings.Duration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"DashSlowdown");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"Movement");
			
			CrumbComp.LeaveMovementCrumb();
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector MoveDirection = GetMoveDirectionOnSlope(MoveComp.DownHit.Normal) * GetAttributeVector(AttributeVectorNames::MovementRaw).Size();

			const FVector TargetVelocity = MoveDirection * MoveComp.MoveSpeed;
			FVector VelocityToTarget = TargetVelocity - MoveComp.Velocity;
			FVector DecelerationDirection = VelocityToTarget.GetSafeNormal();

			FVector Deceleration = DecelerationDirection * DecelerationSpeed * DeltaTime;
			FVector NewVelocity = MoveComp.Velocity + Deceleration;

			if (VelocityToTarget.Size() < Deceleration.Size())
				NewVelocity = TargetVelocity;

			if(!NewVelocity.IsNearlyZero())
				MoveComp.SetTargetFacingDirection(NewVelocity.GetSafeNormal(), 10.f);

			FrameMove.ApplyVelocity(NewVelocity);
			FrameMove.ApplyTargetRotationDelta();
			FrameMove.FlagToMoveWithDownImpact();

			Player.SetAnimFloatParam(n"DashSlowdownTargetSpeed", GetAttributeVector(AttributeVectorNames::MovementDirection).Size());
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;		

			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);

			Player.SetAnimFloatParam(n"DashSlowdownTargetSpeed", ConsumedParams.GetReplicatedInput().Size());		
		}
	}
}