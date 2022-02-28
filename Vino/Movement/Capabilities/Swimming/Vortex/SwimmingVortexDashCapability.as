import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Rice.Math.MathStatics;

class USwimmingVortexDashCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Vortex);
	default CapabilityTags.Add(SwimmingTags::VortexDash);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 70;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;	
	FSwimmingVortexSettings VortexSettings;

	FName LocomotionTag;
	FVector StartLocation;
	bool bAddedInitialVelocity = false;

	const float SwingBlockDuration = 0.3f;
	bool bSwingBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bVortexActive)
			return EHazeNetworkActivation::DontActivate;

		// ! Prevent Dashing when in vortex and Underwater !
		if (SwimComp.SwimmingScore > 1)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkActivation::DontActivate; 

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(ActiveDuration > VortexSettings.DashDuration && SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		SwimComp.SwimmingState = ESwimmingState::VortexDash;

		StartLocation = Owner.ActorLocation;
		bAddedInitialVelocity = false;

		LocomotionTag = n"SwimmingVortex";

		Owner.BlockCapabilities(n"SwimmingSurface", this);
		Owner.BlockCapabilities(MovementSystemTags::Swinging, this);
		bSwingBlocked = true;

		if (SwimComp.AudioData[Player].VortexDash != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexDash);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SwimmingSurface", this);
		if (bSwingBlocked)
			Owner.UnblockCapabilities(MovementSystemTags::Swinging, this);


		if (SwimComp.SwimmingScore > 0 && !Player.IsAnyCapabilityActive(SwimmingTags::VortexMovement))
			SwimComp.PlaySplashSound(HazeAkComp, MoveComp.Velocity.Size(), ESplashType::Breach);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{	
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingVortexDash");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveCharacter(FrameMove, LocomotionTag, n"Anticipation");
			
			CrumbComp.LeaveMovementCrumb();	
		}

		if (bSwingBlocked && ActiveDuration >= SwingBlockDuration)
		{
			Owner.UnblockCapabilities(MovementSystemTags::Swinging, this);
			bSwingBlocked = false;
		}
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			if (ActiveDuration < VortexSettings.DashAnticipationTime)
			{
				FVector InitialVelocityDirection = GetInitialVelocity();
				InitialVelocityDirection.Normalize();
				InitialVelocityDirection = -InitialVelocityDirection;

				float Alpha = FMath::Pow(ActiveDuration / VortexSettings.DashAnticipationTime, 1.8f);
				FVector AnticipationTargetLocation = StartLocation + (InitialVelocityDirection * VortexSettings.DashAnticipationDistanceFromCenter * Alpha);

				FVector ToAnticipationLocation = AnticipationTargetLocation - Owner.ActorLocation;

				FrameMove.ApplyDelta(ToAnticipationLocation);

				MoveComp.SetTargetFacingDirection(Owner.ActorForwardVector);
			}
			else
			{
				if (!bAddedInitialVelocity)
				{
					bAddedInitialVelocity = true;
					FVector DashVelocity = GetInitialVelocity();

					MoveComp.Velocity = DashVelocity;
					LocomotionTag = n"SwimmingBreach";
				}

				FVector Velocity = MoveComp.Velocity;

				// Add drag
				Velocity -= Velocity * VortexSettings.DashDragStrength * DeltaTime;

				// Turn
				Velocity = GetVelocityAfterTurning(DeltaTime, Velocity);

				// Add gravity
				const float GravityStrength = FMath::Clamp((ActiveDuration - VortexSettings.DashAnticipationTime) / VortexSettings.DashGravityLerpTimer, 0.f, 1.f);
				Velocity -= MoveComp.WorldUp * VortexSettings.DashGravityStrength * GravityStrength * DeltaTime;

				FrameMove.ApplyVelocity(Velocity);

				MoveComp.SetTargetFacingDirection(MoveComp.Velocity.GetSafeNormal());
			}

			FrameMove.OverrideStepUpHeight(0.f);		
			FrameMove.OverrideStepDownHeight(0.f);
		
			FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			if (ActiveDuration >= VortexSettings.DashAnticipationTime)
				LocomotionTag = n"SwimmingBreach";

			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}

	FVector GetInitialVelocity()
	{
		return Owner.ActorTransform.TransformVector(VortexSettings.DashDirection) * VortexSettings.DashImpulse;
	}

	FVector GetVelocityAfterTurning(float DeltaTime, FVector Velocity)
	{
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;

		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		// Scale based off of wanted direction and size of your input
		float RotationScale = FMath::Lerp(SwimmingSettings::Breach.MinimumTurnRateScale, 1.f, (1.f - FMath::Abs(MoveDirection.DotProduct(HorizontalVelocity.SafeNormal)))) * MoveDirection.Size();
		float RotationRate = VortexSettings.DashTurnRate * RotationScale * DeltaTime;

		HorizontalVelocity = Math::RotateVectorTowardsAroundAxis(HorizontalVelocity, MoveDirection, MoveComp.WorldUp, RotationRate);
		return HorizontalVelocity + VerticalVelocity;
	}
}
