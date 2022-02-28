import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Movement.Dash.CharacterDashSettings;

UCLASS(Abstract)
class UPlayerMagnetLaunchPerchJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunch);
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunchJumpCapability);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 192;

	AHazePlayerCharacter Player;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;
	UMagneticPlayerComponent PlayerMagnetComponent;

	AMagnetBasePad MagnetActor;
	UMagneticPerchAndBoostComponent MagnetPerch;

	UCharacterAirJumpsComponent CharacterAirJumpsComponent;

	UCharacterAirDashSettings AirDashSettings;
	FMovementCharacterJumpHybridData JumpData;

	const float JumpAnimationDuration = 0.8f;
	const float ShortJumpDuration = 0.5f;

	const float NoCollisionDuration = 0.2f;

	float ElapsedTime = 0.f;
	float ChargeCapabilityUnblockMark = 0.f;

	bool bRemoteSideHasJumpedOff;
	bool bPlayerCollisionEnabled;
	bool bChargeBlocked;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::Get(Owner);
		PlayerMagnetComponent = UMagneticPlayerComponent::Get(Owner);
		CharacterAirJumpsComponent = UCharacterAirJumpsComponent::Get(Owner);

		AirDashSettings = UCharacterAirDashSettings::GetSettings(Owner);

		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(FMagneticTags::PlayerMagnetLaunchJumpFromPerchState))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		// Line up actor to magnet rotation
		Player.SetActorRotation((-Player.ActorForwardVector).Rotation());
		SyncParams.EnableTransformSynchronizationWithTime();

		// Crumbify magnet reference
		UObject MagnetPerchObject;
		ConsumeAttribute(n"MagnetPerch", MagnetPerchObject);
		SyncParams.AddObject(n"MagnetPerch", MagnetPerchObject);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Get Magnet perch
		MagnetPerch = Cast<UMagneticPerchAndBoostComponent>(ActivationParams.GetObject(n"MagnetPerch"));
		MagnetActor = Cast<AMagnetBasePad>(MagnetPerch.Owner);

		if(HasControl())
		{
			Player.BlockCapabilities(CapabilityTags::Collision, this);
			Player.BlockCapabilities(FMagneticTags::PlayerMagnetLaunchChargeCapability, this);

			if(MagnetPerch.bShotByCannon)
				Player.BlockCapabilities(CapabilityTags::Camera, this);
		}

		CharacterAirJumpsComponent.ResetJumpAndDash();

		// Play jump-off effect
		if(HasControl())
			MagnetActor.PlayJumpFromPerchEffect();

		// Initialize velocity depending on perch-jump type
		if(MagnetActor.bUseLongJumpFromMagnetPerch)
		{
			FVector HorizontalVelocity = MagnetPerch.MagneticVector * AirDashSettings.StartSpeed;
			FVector VerticalVelocity = MoveComp.WorldUp * AirDashSettings.StartUpwardsSpeed;
			MoveComp.SetVelocity(HorizontalVelocity + VerticalVelocity);

			ChargeCapabilityUnblockMark = JumpAnimationDuration * 0.3f;
		}
		else
		{
			StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.AirJumpImpulse * 0.6f);
			ChargeCapabilityUnblockMark = ShortJumpDuration * 0.3f;
		}

		bChargeBlocked = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;

		if(!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"PlayerMagnetLaunchJump");
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideStepDownHeight(5.f); // Is this even needed?

		bool bRemoteSideGotVelocityCrumb = false;
		if(HasControl())
		{
			FVector PlayerInput = GetAttributeVector(AttributeVectorNames::MovementDirection);

			if(MagnetActor.bUseLongJumpFromMagnetPerch)
				TickDashJump(MoveData, PlayerInput, DeltaTime);
			else
				TickShortJump(MoveData, PlayerInput, DeltaTime);

			if(bChargeBlocked && ActiveDuration >= ChargeCapabilityUnblockMark)
			{
				bChargeBlocked = false;
				Player.UnblockCapabilities(FMagneticTags::PlayerMagnetLaunchChargeCapability, this);
			}

			// Restore physics once player has jumped away from platform
			if(ElapsedTime >= NoCollisionDuration && !bPlayerCollisionEnabled)
			{
				Player.Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				Player.UnblockCapabilities(CapabilityTags::Collision, this);

				bPlayerCollisionEnabled = true;
			}
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);

			bRemoteSideGotVelocityCrumb = !CrumbData.Velocity.IsZero();
		}

		MoveCharacter(MoveData, n"AirMovement");
		CrumbComp.LeaveMovementCrumb();

		// Nasty check to play effects when remote side is moving (instead of when capability activates)
		if(!HasControl() && !bRemoteSideHasJumpedOff && bRemoteSideGotVelocityCrumb && MagnetActor != nullptr)
		{
			MagnetActor.PlayJumpFromPerchEffect();
			bRemoteSideHasJumpedOff = true;
		}
	}

	void TickDashJump(FHazeFrameMovement& MoveData, FVector PlayerInput, float DeltaTime)
	{
		FVector MoveDirection = Player.ActorForwardVector;
		if(!PlayerInput.IsNearlyZero())
		{
			FVector InputInfluence = FMath::Square(ActiveDuration / AirDashSettings.Duration);
			MoveDirection = (MoveDirection + PlayerInput.ConstrainToDirection(MagnetActor.ActorRightVector) * InputInfluence).GetSafeNormal();
		}

		// Handle horizontal velocity
		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector TargetVelocity = MoveDirection * HorizontalVelocity.Size();

		if (ActiveDuration <= 0.08f)
			HorizontalVelocity = TargetVelocity;
		else
			HorizontalVelocity = FMath::Lerp(HorizontalVelocity, TargetVelocity, (ActiveDuration / AirDashSettings.Duration) * 0.125f);

		float Deceleration = (AirDashSettings.EndSpeed - AirDashSettings.StartSpeed) / AirDashSettings.Duration;
		HorizontalVelocity += HorizontalVelocity.GetSafeNormal() * Deceleration * DeltaTime;

		MoveData.ApplyVelocity(HorizontalVelocity);
		MoveData.ApplyAndConsumeImpulses();

		// Handle vertical velocity
		float DurationAlpha = ElapsedTime / JumpAnimationDuration;
		float GravityMultiplier = FMath::Square(DurationAlpha) * 9.8f * AirDashSettings.GravityPow * MagnetActor.JumpFromPerchGravityMultiplier;
		FVector VerticalVelocity = MoveComp.Gravity * GravityMultiplier * DeltaTime;
		MoveData.ApplyVelocity(VerticalVelocity);

		if (!TargetVelocity.IsNearlyZero())
			MoveComp.SetTargetFacingDirection(TargetVelocity.GetSafeNormal(), 2.f);		

		MoveData.ApplyTargetRotationDelta();
	}

	void TickShortJump(FHazeFrameMovement& MoveData, FVector PlayerInput, float DeltaTime)
	{
		// Handle horizontal velocity
		FVector HorizontalDelta = GetHorizontalAirDeltaMovement(DeltaTime, MagnetPerch.MagneticVector, MoveComp.HorizontalAirSpeed);
		MoveData.ApplyDelta(HorizontalDelta);
		MoveData.ApplyAndConsumeImpulses();

		// Handle vertical velocity
		FVector VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, false, MoveComp);
		MoveData.ApplyVelocity(VerticalVelocity);

		MoveComp.SetTargetFacingDirection(Player.ActorForwardVector);
		MoveData.ApplyTargetRotationDelta();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime > JumpAnimationDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!MagnetActor.bUseLongJumpFromMagnetPerch)
		{
			if(!MoveComp.IsAirborne())
				EHazeNetworkDeactivation::DeactivateUsingCrumb;

			if(MoveComp.UpHit.bBlockingHit)
				EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
			// If any impulses are applied, cancel the jump
			FVector Impulse = FVector::ZeroVector;
			MoveComp.GetAccumulatedImpulse(Impulse);
			if(!Impulse.IsNearlyZero())
				EHazeNetworkDeactivation::DeactivateUsingCrumb;

			if(ActiveDuration >= ShortJumpDuration)
				EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Eman TODO: Deactivate if player started using magnet and is restarting system

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Restore physics in case capability deactivated before re-enabling them
		if(HasControl() && !bPlayerCollisionEnabled)
		{
			Player.Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			Player.UnblockCapabilities(CapabilityTags::Collision, this);
		}

		// Re-enable magnetic interactions between player and perch
		MagnetPerch.DisabledForObjects.Remove(Owner);

		// Don't clear locomotion stuff if launch charge just activated this frame
		if(!Player.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchChargeCapability))
		{
			AnimationDataComponent.Reset();
			Player.ClearLocomotionAssetByInstigator(AnimationDataComponent);
		}

		if(HasControl())
		{
			if(MagnetPerch.bShotByCannon)
				Player.UnblockCapabilities(CapabilityTags::Camera, this);

			if(bChargeBlocked)
				Player.UnblockCapabilities(FMagneticTags::PlayerMagnetLaunchChargeCapability, this);
		}

		// Cleanup
		MagnetActor = nullptr;
		MagnetPerch = nullptr;
		ElapsedTime = 0.f;
		bRemoteSideHasJumpedOff = false;
		bPlayerCollisionEnabled = false;
	}
}
