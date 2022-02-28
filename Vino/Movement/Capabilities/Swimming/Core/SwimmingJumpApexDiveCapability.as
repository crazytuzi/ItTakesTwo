import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Audio.Capabilities.PlayerVelocityDataUpdateCapability;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Rice.Math.MathStatics;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Capabilities.Swimming.SnowGlobeStopSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Audio.Movement.PlayerMovementAudioComponent;

class USwimmingJumpApexDiveCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::AboveWater);
	default CapabilityTags.Add(SwimmingTags::Breach);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 140;
	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 300);

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;

	const float Cooldown = 0.8f;
	const float Gravity = 2700.f;

	FVector Velocity;

	bool bDiveTriggered = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActioning(n"AllowDive"))
        {
            CharacterOwner.SetCapabilityActionState(n"AllowDive", EHazeActionState::Inactive);
			FVector DiveVelocity; 
			ConsumeAttribute(n"DiveVelocity", DiveVelocity);

			Velocity = DiveVelocity;
            bDiveTriggered = true;
        }
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

        if (MoveComp.IsGrounded())
        	return EHazeNetworkActivation::DontActivate;

		if (SwimComp.IsSwimmingActive())
        	return EHazeNetworkActivation::DontActivate;

		if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) >= -800.f)
        	return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < Cooldown)
        	return EHazeNetworkActivation::DontActivate;

		if (!CheckIfLandingInWater())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		SwimComp.SwimmingState = ESwimmingState::Breach;
		SwimComp.AddFeature(Player);

		Velocity = ActivationVelocity;

		SwimComp.BlockSurfaceDuration = 2.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		Player.ClearPointOfInterestByInstigator(this);
		Player.SetCapabilityActionState(n"ResetDolphinCombo", EHazeActionState::Active);

		HazeAkComp.HazePostEvent(AudioMoveComp.FallingSkydivingEvents.StopFallingEvent);

			// If nothing else in the swimming system took over...
		if (SwimComp.SwimmingState == ESwimmingState::Breach)
			SwimComp.SwimmingState = ESwimmingState::Inactive;
			
		// if ((!MoveComp.IsGrounded() || !SwimComp.bIsInWater) && Player.IsAnyCapabilityActive(MovementSystemTags::LedgeGrab))
		// 	SwimComp.SwimmingState = ESwimmingState::Inactive;

		if (SwimComp.SwimmingScore > 0 && !Player.IsAnyCapabilityActive(SwimmingTags::Vortex))
			SwimComp.PlaySplashSound(HazeAkComp, MoveComp.Velocity.Size(), ESplashType::Breach);
	}	


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingBreach");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SwimmingBreach");
		
		CrumbComp.LeaveMovementCrumb();

		HazeAkComp.SetRTPCValue("Rtpc_Player_Falling_Duration", ActiveDuration);
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{					
			Velocity = Velocity - MoveComp.WorldUp * Gravity * DeltaTime;			
			UpdateHorizontalVelocity(DeltaTime);

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepUpHeight(0.f);		
			FrameMove.OverrideStepDownHeight(0.f);
		
			MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal());
			FrameMove.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}	
	}

	void UpdateHorizontalVelocity(float DeltaTime)
	{
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;

		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		if (MoveDirection.DotProduct(HorizontalVelocity.GetSafeNormal()) < 0.f)
		{
			HorizontalVelocity = FMath::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, 1.f);
		}

		// Scale based off of wanted direction and size of your input
		float RotationScale = FMath::Lerp(SwimmingSettings::Breach.MinimumTurnRateScale, 1.f, (1 - FMath::Abs(MoveDirection.DotProduct(HorizontalVelocity.SafeNormal)))) * MoveDirection.Size();
		float RotationRate = SwimmingSettings::Breach.TurnRateDegrees * RotationScale * DeltaTime;

		HorizontalVelocity = Math::RotateVectorTowardsAroundAxis(HorizontalVelocity, MoveDirection, MoveComp.WorldUp, RotationRate);
		Velocity = HorizontalVelocity + VerticalVelocity;
	}

	bool CheckIfLandingInWater() const
	{
		FTrajectoryPoints Trajectory = CalculateTrajectory(Player.ActorLocation, 1500.f, ActivationVelocity, Gravity, 0.5f);

		for (int Index = 0, Count = Trajectory.Positions.Num() - 1; Index < Count; ++Index)
		{
			FVector CurrentPoint = Trajectory.Positions[Index];
			FVector NextPoint = Trajectory.Positions[Index + 1];


			TArray<AActor> ActorsToIgnore;
			TArray<FHitResult> Hits;

			if (IsDebugActive())
				DebugDrawLine(CurrentPoint, NextPoint, FLinearColor::Red);

			EDrawDebugTrace DrawDebugTrace = IsDebugActive() ? EDrawDebugTrace::ForDuration : EDrawDebugTrace::None;
			System::LineTraceMultiByProfile(CurrentPoint, NextPoint, n"PlayerCharacter", false, ActorsToIgnore, DrawDebugTrace, Hits, true, DrawTime = 0.f);	

			for (FHitResult Hit : Hits)
			{
				if (Hit.bBlockingHit)
				{
					// You hit something solid - don't dive
					return false;
				}
				else if (Cast<ASnowGlobeStopSwimmingVolume>(Hit.Actor) != nullptr)
				{
					// You hit a stop volume - Disregard all valid Swimming Volumes this trace

					bool bBlockingHit = false;
					// You hit a swimming volume - Make sure you didn't also hit a wall, or Stop Swimming Volume
					for (FHitResult SwimHit : Hits)
					{
						if (SwimHit.bBlockingHit)
							bBlockingHit = true;
					}

					if (bBlockingHit)
						return false;

					break;
				}
				else if (Cast<ASnowGlobeSwimmingVolume>(Hit.Actor) != nullptr)
				{
					bool bBlockingHit = false;
					bool bOverlappedStopVol = false;					

					// You hit a swimming volume - Make sure you didn't also hit a wall, or Stop Swimming Volume
					for (FHitResult SwimHit : Hits)
					{						
						// You hit a wall - Return to jail, do not pass go
						if (SwimHit.bBlockingHit)
							bBlockingHit = true;

						// You hit a Stop Swimming Volume - Invalid overlap, try again next trace
						if (Cast<ASnowGlobeStopSwimmingVolume>(SwimHit.Actor) != nullptr)
							bOverlappedStopVol = true;
					}

					if (bBlockingHit)
						return false;
					if (bOverlappedStopVol)
						break;

					return true;
				}
			}
		}

		return false;
	}

	FVector GetActivationVelocity() const property
	{
		FVector Vel = MoveComp.Velocity;

		Vel += Owner.ActorForwardVector * 200.f * GetAttributeVector(AttributeVectorNames::MovementDirection).Size();
		Vel += Owner.ActorUpVector * 300.f;

		return Vel;
	}
}
