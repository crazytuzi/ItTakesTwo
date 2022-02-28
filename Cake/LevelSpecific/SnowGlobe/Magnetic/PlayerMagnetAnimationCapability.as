import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Rice.Math.MathStatics;
import Vino.Movement.MovementSystemTags;

USTRUCT()
struct FMagnetMovementAndRotationLock
{
	UPROPERTY()
	FName MovementTag;

	UPROPERTY()
	bool bShouldLockRotation;
};

class UPlayerMagnetAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetAnimationCapability);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 80;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	UPROPERTY()
	TArray<FMagnetMovementAndRotationLock> MovementLocoBlockTags;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset MagnetStrafeLocomotionCody;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset MagnetStrafeLocomotionMay;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;
	UMagneticPlayerComponent MagneticPlayerComponent;

	UMagneticComponent ActivatedMagnet;

	FVector PreviousPlayerForward;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MagneticPlayerComponent.ActivatedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!MagneticPlayerComponent.ActivatedMagnet.IsA(UMagneticComponent::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if(!Cast<UMagneticComponent>(MagneticPlayerComponent.ActivatedMagnet).bUseGenericMagnetAnimation)
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"IsSwimming"))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::LedgeGrab))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::WallSlide))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActivatedMagnet = Cast<UMagneticComponent>(MagneticPlayerComponent.ActivatedMagnet);

		// Add strafe state machine
		PlayerOwner.AddLocomotionAsset(PlayerOwner.IsCody() ? MagnetStrafeLocomotionCody : MagnetStrafeLocomotionMay, this);

		PreviousPlayerForward = PlayerOwner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector PlayerToMagnet = (ActivatedMagnet.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal();
		FVector ConstrainedPlayerToMagnet = PlayerToMagnet.ConstrainToPlane(PlayerOwner.MovementWorldUp).GetSafeNormal();

		bool bShouldLockRotation = false;
		bool bShouldRequestLocomotion = ShouldRequestMagnetLocomotion(bShouldLockRotation);
		if(bShouldRequestLocomotion && PlayerOwner.Mesh.CanRequestLocomotion())
		{
			// Request locomotion
			FHazeRequestLocomotionData LocomotionData;
			LocomotionData.AnimationTag = n"MagnetStrafe";
			LocomotionData.WantedWorldTargetDirection = MovementComponent.ActualVelocity;
			LocomotionData.WantedVelocity = MovementComponent.ActualVelocity;
			PlayerOwner.RequestLocomotion(LocomotionData);
		}

		// Face magnet for strafing
		if(bShouldLockRotation)
		{
			MovementComponent.SetTargetFacingDirection(ConstrainedPlayerToMagnet, MovementComponent.RotationSpeed);

			// This covers the jump case, where the jump capability steers the player rotation
			PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime(ConstrainedPlayerToMagnet.Rotation());
		}
		else
		{
			PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();
		}

		// Update magnet angle value
		float MagnetAngle = GetAngleBetweenVectorsAroundAxis(PlayerToMagnet, ConstrainedPlayerToMagnet, PlayerOwner.MovementWorldUp.CrossProduct(ConstrainedPlayerToMagnet).GetSafeNormal());
		PlayerOwner.SetAnimFloatParam(n"MagnetAngle", MagnetAngle);

		// Update magnet rotation speed value
		float MagnetYawAngle = -GetAngleBetweenVectorsAroundAxis(ConstrainedPlayerToMagnet, PreviousPlayerForward, PlayerOwner.MovementWorldUp);
		PlayerOwner.SetAnimFloatParam(n"MagnetRotationSpeed", MagnetYawAngle);

		// Save frame's actor forward or player to magnet, depending on these conditions
		PreviousPlayerForward = !bShouldRequestLocomotion && bShouldLockRotation ?
			ConstrainedPlayerToMagnet :
			PlayerOwner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerComponent.ActivatedMagnet == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsActioning(n"IsSwimming"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::LedgeGrab))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::WallSlide))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.ClearLocomotionAssetByInstigator(this);
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();
	}

	bool ShouldRequestMagnetLocomotion(bool& bShouldLockRotation)
	{
		// Insert ugly swiming hax...
		// can't check tag because SnowGlobeSwimmingAudioCapability uses it and is active at all times in lake
		if(IsActioning(n"IsSwimming"))
		{
			bShouldLockRotation = false;
			return false;
		}

		for(FMagnetMovementAndRotationLock TagTuple : MovementLocoBlockTags)
		{
			if(PlayerOwner.IsAnyCapabilityActive(TagTuple.MovementTag))
			{
				bShouldLockRotation = TagTuple.bShouldLockRotation;
				return false;
			}
		}

		bShouldLockRotation = true;

		// Don't request locomotion when requesting 'landing' feature
		if(MovementComponent.BecameGrounded() || PlayerOwner.Mesh.CurrentFeatureMatchesAnimationRequest(n"Landing"))
			return false;

		return true;
	}
}