import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

class UMagneticPlayerAttractionDoubleLaunchMeetCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionDoubleLaunchMeetCapability);

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent;
	UMagneticPlayerAttractionComponent OtherPlayerMagneticAttractionComponent;

	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		OtherPlayerMagneticAttractionComponent = UMagneticPlayerAttractionComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UMagneticPlayerAttractionComponent MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::DoubleLaunchStun)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(FMagneticTags::MagneticEffect, this);

		MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);

		// Kill dat momentum
		MoveComp.SetVelocity(FVector::ZeroVector);

		// Set animation sm flag
		AnimationDataComponent.bBothPlayersColliding = true;

		// Play camera shake
		PlayerOwner.PlayCameraShake(MagneticPlayerAttractionComponent.PerchCameraShakeClass, 1.5f);

		// Play force feedback
		PlayerOwner.PlayForceFeedback(MagneticPlayerAttractionComponent.DoubleLaunchCollisionFeedback, false, false, FMagneticTags::MagneticPlayerAttractionDoubleLaunchMeetCapability);

		// Fire smash event
		UMagneticPlayerComponent::Get(Owner).PlayerMagnet.OnMPAPlayersConverged.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		if(HasControl() && ShouldEndStun())
			MagneticPlayerAttractionComponent.NetSetDoubleLaunchStunIsDone(true);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionDoubleLaunchMeet");
		FVector Velocity = MoveComp.GetVelocity();

		// Add small horizontal push
		float RepelAlpha = Math::Saturate(ActiveDuration / 0.3f);
		float RepelAcceleration = 1.f - FMath::Square(RepelAlpha);
		FVector RepelDirection = (PlayerOwner.ActorLocation - PlayerOwner.OtherPlayer.ActorLocation).GetSafeNormal();
		Velocity += RepelDirection * 200.f * RepelAcceleration * DeltaTime;

		// Add vertical velocity
		if(ShouldPlayersFall())
		{
			float GravityMultiplier = FMath::Square(Math::Saturate(ActiveDuration / 0.5f));
			Velocity -= MoveComp.WorldUp * MoveComp.GravityMagnitude * GravityMultiplier * DeltaTime;
		}

		MoveData.ApplyVelocity(Velocity);
		MoveCharacter(MoveData, n"MagnetAttract");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::DoubleLaunchStun)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(FMagneticTags::MagneticEffect, this);

		// Clear animation stuff
		AnimationDataComponent.Reset();
		PlayerOwner.ClearLocomotionAssetByInstigator(MagneticPlayerAttractionComponent);

		MagneticPlayerAttractionComponent = nullptr;
	}

	bool ShouldPlayersFall()
	{
		if(!IsNetworked())
			return true;

		if(OtherPlayerMagneticAttractionComponent.AttractionState == EMagneticPlayerAttractionState::DoubleLaunchStun)
			return true;

		return false;
	}

	bool ShouldEndStun()
	{
		return (ActiveDuration >= MagneticPlayerAttractionComponent.DoubleLaunchStunTime) && !MagneticPlayerAttractionComponent.bDoubleLaunchStunIsDone;
	}
}