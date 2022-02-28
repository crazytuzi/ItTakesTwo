import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.MovementSettings;

class UClockworkLastBossFreeFallPlayerCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::Falling);
		
	default TickGroup = ECapabilityTickGroups::LastMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	
	bool bCollidedWithCog = false;
	bool bCollidedWithBar = false;
	const float FallSpeed = 3500.f;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature;

	UHazeLocomotionFeatureBase FeatureToUse; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);

		FeatureToUse = Player == Game::GetCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"FreeFalling"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!IsActioning(n"FreeFalling"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ClockworkFreeFall");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, n"FreeFall");
			
			CrumbComp.LeaveMovementCrumb();	
		}	
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		bCollidedWithCog = IsActioning(n"FreeFallCollidedCog");
		Player.SetAnimBoolParam(n"FreeFallCollidedCog", bCollidedWithCog); 

		bCollidedWithBar = IsActioning(n"FreeFallCollidedBar");
		Player.SetAnimBoolParam(n"FreeFallCollidedBar", bCollidedWithBar); 

		float FallHeight = Owner.ActorLocation.Z;
		ensure(ConsumeAttribute(n"FallCurrentHeight", FallHeight)); // This will give an ensure when debugging if you haven't set the attribute.

		if (HasControl())
		{			
			FVector Velocity = MoveComp.Velocity;
			FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FVector MoveRaw = GetAttributeVector(AttributeVectorNames::MovementRaw);

			FVector Blendspace = Player.ActorTransform.InverseTransformVector(MoveDirection);
			Player.SetAnimVectorParam(n"FreeFallBlendSpace", Blendspace);

			FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
			FVector TargetVelocity = MoveDirection * MoveComp.MoveSpeed;
			FVector NewHorizontalVelocity = FMath::VInterpConstantTo(HorizontalVelocity, TargetVelocity, DeltaTime, 6000.f);

			FrameMove.ApplyVelocity(NewHorizontalVelocity);
			FrameMove.ApplyAndConsumeImpulses();

			
			FrameMove.ApplyDelta(FVector(0.f, 0.f, FallHeight - Owner.ActorLocation.Z));
			

			FVector FacingDirection = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			if (FacingDirection.IsNearlyZero())
				FacingDirection = Owner.ActorForwardVector;
			FacingDirection.Normalize();			
			//MoveComp.SetTargetFacingDirection(FacingDirection, 2.5f);
			if (!MoveDirection.IsNearlyZero())
				FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FVector Velocity = ConsumedParams.Velocity.GetClampedToMaxSize(1.f).ConstrainToPlane(MoveComp.WorldUp);
			FVector Blendspace = Player.ActorTransform.InverseTransformVector(Velocity);
			Player.SetAnimVectorParam(n"FreeFallBlendSpace", Blendspace);

			FVector NewPosition = Owner.ActorLocation + ConsumedParams.DeltaTranslation;
			NewPosition.Z = FallHeight;

			FrameMove.SetRotation(ConsumedParams.Rotation.Quaternion());
			FrameMove.ApplyDelta(NewPosition - Owner.ActorLocation);
		}	
	}
}
