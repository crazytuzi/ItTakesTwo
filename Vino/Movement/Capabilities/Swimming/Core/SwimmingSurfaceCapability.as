import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.SwimmingSurfaceComponent;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingJumpApexDiveCapability;

class USwimmingSurfaceCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Surface);
	
	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 100);
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10;

	default CapabilityDebugCategory = n"Movement Swimming";

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	USwimmingSurfaceComponent SurfaceComp;
	UCharacterAirJumpsComponent AirJumpsComp;
	UPlayerHazeAkComponent HazeAkComp;

	FHazeAcceleratedVector AcceleratedVerticalOffset;

	bool bMovingForward = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		SurfaceComp = USwimmingSurfaceComponent::Get(Player);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{		
		if (SwimComp.bIsInWater)
			SurfaceComp.GetOrCreateSurfaceData(Player);	

		if (SwimComp.BlockSurfaceDuration > 0.f)
			SwimComp.BlockSurfaceDuration -= DeltaTime;

		if (IsDebugActive())
		{
			DebugDrawLine(SurfaceComp.GetTopTraceLocation(Player, MoveComp), SurfaceComp.GetBottomTraceLocation(Player, MoveComp), FLinearColor::Red, 0.f, 3.f);
			//DebugDrawLine(UpSurfaceAcceptanceLocation, DownSurfaceAcceptanceLocation, FLinearColor::Yellow, 0.f, 5.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bIsInWater)
       		return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingSpeedState != ESwimmingSpeedState::Normal)
       		return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::MovementCrouch))
       		return EHazeNetworkActivation::DontActivate;

		// If you are moving away from the surface
		if (MoveComp.Velocity.DotProduct(SurfaceComp.SurfaceData.ToSurface) < 0.f)
				return EHazeNetworkActivation::DontActivate;

		// If the surface is above you
		if (SurfaceComp.SurfaceData.ToSurface.DotProduct(MoveComp.WorldUp) > 0.f)
		{
			if (SurfaceComp.SurfaceData.DistanceToSurface > SwimmingSettings::Surface.AcceptanceRangeBelowSurface)
				return EHazeNetworkActivation::DontActivate;
		}
		else
		{
			if (SurfaceComp.SurfaceData.DistanceToSurface > SwimmingSettings::Surface.AcceptanceRangeAboveSurface)
				return EHazeNetworkActivation::DontActivate;

			if (SwimComp.BlockSurfaceDuration > 0.f)	
				return EHazeNetworkActivation::DontActivate;
			
			if (Player.IsAnyCapabilityActive(SwimmingTags::Breach))
				return EHazeNetworkActivation::DontActivate;

			if (Player.IsAnyCapabilityActive(USwimmingJumpApexDiveCapability::StaticClass()))
				return EHazeNetworkActivation::DontActivate;
			
			if (!SwimComp.bForceSurface)
			{
				float DownwardsSpeed = MoveComp.Velocity.DotProduct(-MoveComp.WorldUp);
				if (DownwardsSpeed > ((SwimmingSettings::Speed.DesiredFast + SwimmingSettings::Speed.DesiredCruise) / 2))
					return EHazeNetworkActivation::DontActivate;
			}
		}

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(n"PlayerShadow", this);

		SwimComp.SwimmingState = ESwimmingState::Surface;
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		float VerticalSpeed = MoveComp.WorldUp.DotProduct(MoveComp.Velocity);
		AcceleratedVerticalOffset.SnapTo(-SurfaceComp.SurfaceData.ToSurface, MoveComp.WorldUp * VerticalSpeed);

		AirJumpsComp.ResetJumpAndDash();

		UAkAudioEvent AudioEvent = SwimComp.bIsUnderwater ? SwimComp.AudioData[Player].SurfaceEnteredFromWater : SwimComp.AudioData[Player].SurfaceEnteredFromAir;
		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent);

		SwimComp.CallOnEnteredSurface();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);

		if (bMovingForward)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SurfaceStoppedMoving);

		bMovingForward = false;
		
		SwimComp.CallOnExitedSurface();		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingSurface");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SwimmingSurface");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
			SwimComp.bIsSwimmingForward = !MoveInput.IsNearlyZero();

			UAkAudioEvent AudioEvent;

			if (!bMovingForward && !MoveInput.IsNearlyZero())
			{
				AudioEvent = SwimComp.AudioData[Player].SurfaceStartedMoving;
				bMovingForward = true;
			}
			else if (bMovingForward && MoveInput.IsNearlyZero())
			{
				AudioEvent = SwimComp.AudioData[Player].SurfaceStoppedMoving;
				bMovingForward = false;
			}

			if (AudioEvent != nullptr)
				HazeAkComp.HazePostEvent(AudioEvent);

			AcceleratedVerticalOffset.SpringTo(FVector::ZeroVector, 35.f, 0.35f, DeltaTime);
			FVector NewVerticalLocation = SurfaceComp.SurfaceData.WorldLocation + AcceleratedVerticalOffset.Value;
			FVector VerticalDelaMove = (NewVerticalLocation - Player.CapsuleComponent.WorldLocation).ConstrainToDirection(MoveComp.WorldUp);
			FrameMove.ApplyDelta(VerticalDelaMove);

			FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
			HorizontalVelocity -= HorizontalVelocity * SwimmingSettings::Surface.Drag * DeltaTime;
			HorizontalVelocity += MoveInput * SwimmingSettings::Surface.HorizontalAcceleration * DeltaTime;	
			FrameMove.ApplyVelocity(HorizontalVelocity);

			FrameMove.OverrideStepDownHeight(0.f);

			if (MoveComp.HasAccumulatedImpulse())
			{
				FVector Impulse;
				MoveComp.GetAccumulatedImpulse(Impulse);
				MoveComp.ConsumeAccumulatedImpulse();

				Impulse = Impulse.ConstrainToPlane(MoveComp.WorldUp);
				FrameMove.ApplyVelocity(Impulse);
			}

			FVector FacingDirection = MoveComp.Velocity.GetSafeNormal();
			if (FacingDirection.IsNearlyZero())
				FacingDirection = Owner.ActorForwardVector;
			MoveComp.SetTargetFacingDirection(FacingDirection, 5.f);			
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);

			SwimComp.bIsSwimmingForward = !ConsumedParams.ReplicatedInput.IsNearlyZero();
		}

		FrameMove.ApplyTargetRotationDelta();
	}	
}
