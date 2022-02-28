import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Peanuts.SpeedEffect.SpeedEffectStatics;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.Core.SnowGlobeSwimmingStatics;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Underwater.MagneticSurfaceBuoy;

class UPlayerMagneticBuoyCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::Magnetic);
	default CapabilityTags.Add(FMagneticTags::PlayerMagneticBuoyCapability);
	default CapabilityTags.Add(SwimmingTags::Underwater);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	
	default CapabilityDebugCategory = n"Movement Swimming";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent MagneticPlayerComponent;
	UMagneticBuoyComponent MagneticBuoyComponent;
	UPlayerHazeAkComponent HazeAkComp;

	USnowGlobeSwimmingComponent SwimComp;

	FVector InitialPlayerToMagnet;
	FHazeAcceleratedRotator ControlRotation;

	bool bIsSurfaceBuoy;

	int32 InteractingPlayers;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
		SwimComp = USnowGlobeSwimmingComponent::Get(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		UMagneticBuoyComponent TargetedMagnetBuoyComponent = Cast<UMagneticBuoyComponent>(MagneticPlayerComponent.TargetedMagnet);
		if(TargetedMagnetBuoyComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!TargetedMagnetBuoyComponent.IsInfluencedBy(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bIsSurfaceBuoy)
		{
			if(!SwimComp.bIsInWater)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		// else
		// {
		if(InitialPlayerToMagnet.DotProduct((MagneticBuoyComponent.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal()) < 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		// }

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddObject(n"MagneticBuoyComponent", MagneticPlayerComponent.TargetedMagnet);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);


		MagneticBuoyComponent = Cast<UMagneticBuoyComponent>(ActivationParams.GetObject(n"MagneticBuoyComponent"));
		MagneticPlayerComponent.ActivateMagnetLockon(MagneticBuoyComponent, this);

		MagneticBuoyComponent.InteractingPlayerCount ++;

		InitialPlayerToMagnet = (MagneticBuoyComponent.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal();
		bIsSurfaceBuoy = MagneticBuoyComponent.Owner.IsA(AMagneticSurfaceBuoy::StaticClass());

		// Audio: Fast to Cruise
		if (SwimComp.AudioData[PlayerOwner].SubmergedEnteredCruise != nullptr)
		{
			HazeAkComp.HazePostEvent(SwimComp.AudioData[PlayerOwner].SubmergedEnteredCruise);

			if(MagneticBuoyComponent.InteractingPlayerCount == 1)
				MagneticBuoyComponent.DopplerDataComp.DopplerInstance.SetEnabled(true);
		}

		//MagneticPlayerComponent.PrepareDopplerPassby(MagneticBuoyComponent.GetOwner(), MagneticBuoyComponent.BuoyPassbyEventData);	
		SwimComp.CallOnMagnetBuoyStartedUsing();

		// Turn off buoy collisions with player
		MoveComp.StartIgnoringActor(MagneticBuoyComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		MagneticPlayerComponent.DeactivateMagnetLockon(this);
		MagneticBuoyComponent.InteractingPlayerCount --;
		if(MagneticBuoyComponent.InteractingPlayerCount == 0)
			MagneticBuoyComponent.DopplerDataComp.DopplerInstance.SetEnabled(false);

		// Turn on buoy collisions with player
		MoveComp.StopIgnoringActor(MagneticBuoyComponent.Owner);

		// Cleanup
		MagneticBuoyComponent = nullptr;
		bIsSurfaceBuoy = false;

		SwimComp.DesiredLockCooldown = SwimmingSettings::Speed.DesiredLockDurationAfterBuoy;

		//MagneticPlayerComponent.EndDopplerPassby();
		SwimComp.CallOnMagnetBuoyStoppedUsing();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		SwimComp.BlockSurfaceDuration = 2.f;
		
		SwimmingStatics::UpdateControlRotation(PlayerOwner, DeltaTime, GetAttributeVector2D(AttributeVectorNames::CameraDirection), ControlRotation);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(FMagneticTags::PlayerMagneticBuoyCapability);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		if(HasControl())
		{
			ESwimmingSpeedState BeforeSwimmingState = SwimComp.SwimmingSpeedState;
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);

			// Accelerate Towards Magnet
			FVector Velocity = MoveComp.Velocity;
			FVector PlayerToMagnet = (MagneticBuoyComponent.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal();
			Velocity += PlayerToMagnet * MagneticBuoyComponent.PlayerImpulse * DeltaTime;

			// Player Movement Acceleration
			SwimComp.VerticalScale = 0.f;
			if (IsActioning(ActionNames::MovementJump))
				SwimComp.VerticalScale += SwimmingSettings::Speed.VerticalInputScale;
			else if (bIsSurfaceBuoy)
				SwimComp.VerticalScale += SwimmingSettings::Speed.VerticalInputScale * 0.5f;
				
			if (IsActioning(ActionNames::Cancel))
				SwimComp.VerticalScale -= SwimmingSettings::Speed.VerticalInputScale;

			// Process player input IF we don't need to steer away from buoy
			FVector MoveDirection = ControlRotation.Value.RotateVector(Input) + (MoveComp.WorldUp * SwimComp.VerticalScale);
			MoveDirection = MoveDirection.ConstrainToPlane(InitialPlayerToMagnet);
			MoveDirection = MoveDirection.GetClampedToMaxSize(1.f);

			FVector TargetVelocity = MoveDirection * SwimComp.DesiredSpeed;
			Velocity = FMath::VInterpTo(Velocity, TargetVelocity, DeltaTime, SwimmingSettings::Speed.InterpSpeedTowardsDesired);

			float Speed = Velocity.Size();
			if (Speed > SwimComp.DesiredSpeed)
			{
				SwimComp.DesiredSpeed = FMath::Min(SwimmingSettings::Speed.DesiredMax, Speed);
				SwimComp.DesiredDecayCooldown = SwimmingSettings::Speed.DesiredDecayDelayAfterDash;
			}

			SwimComp.UpdateSwimmingSpeedState();
			MoveData.ApplyVelocity(Velocity);

			MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal(), 40.f);
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);

			float Speed = CrumbData.Velocity.Size();
			SwimComp.DesiredSpeed = Speed;
			SwimComp.UpdateSwimmingSpeedState();
		}

		// Move and leave crumb!
		MoveCharacter(MoveData, n"SwimmingBuoy");
		CrumbComp.LeaveMovementCrumb();

		// Update VFX
		float DurationAlpha = FMath::Square(Math::Saturate(ActiveDuration / 1.f) + 0.2f);
		SpeedEffect::RequestSpeedEffect(PlayerOwner, FSpeedEffectRequest(DurationAlpha, this));

		// Let abp know we're passing buoy on last tick
		if(InitialPlayerToMagnet.DotProduct((MagneticBuoyComponent.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal()) < 0.f || !SwimComp.bIsInWater)
			PlayerOwner.SetAnimBoolParam(n"PlayerSwamPastBuoy", true);
	}
	
	bool SteerAwayFromBuoy(FVector Velocity, FVector& AdjustedTrajectory) const
	{
		FVector PlayerToBuoyRaw = MagneticBuoyComponent.Owner.ActorLocation - PlayerOwner.ActorLocation;

		FHazeTraceParams Trace;
		Trace.InitWithMovementComponent(MoveComp);
		Trace.TraceShape.SetCapsule(MoveComp.CollisionShape.CapsuleRadius * 8.f, MoveComp.CollisionShape.CapsuleHalfHeight * 3.f);
		Trace.From = PlayerOwner.ActorLocation;
		Trace.To = PlayerOwner.ActorLocation + Velocity.GetSafeNormal() * PlayerToBuoyRaw.Size();

		FHazeHitResult HitResult;
		if(!Trace.Trace(HitResult))
			return false;

		FVector BuoyCenterToR = (HitResult.ShapeLocation - MagneticBuoyComponent.Owner.ActorLocation).GetSafeNormal();
		FVector VelocityCrossImpactNormal = HitResult.ImpactNormal.CrossProduct(Velocity.GetSafeNormal());
		AdjustedTrajectory = -VelocityCrossImpactNormal.CrossProduct(Velocity.GetSafeNormal());
		AdjustedTrajectory = AdjustedTrajectory.ConstrainToPlane(PlayerToBuoyRaw.GetSafeNormal());

		return true;
	}
}