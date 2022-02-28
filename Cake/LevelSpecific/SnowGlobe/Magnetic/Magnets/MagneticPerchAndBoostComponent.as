import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetPadAnimationDataAsset;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

event void FOnBasePadUsedPerchStateChanged(bool BeingUsed);
event void FOnBasePadBoost();

enum EMagnetPlatformType
{
	None,
	Ground,
	Wall,
	Ceiling
}

// this component gives you a boost or a grab depending on the polarity
UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagneticPerchAndBoostComponent : UMagneticComponent
{
	UPROPERTY()
	UPlayerMagnetPadAnimationDataAsset AnimationStateMachineAsset;

	UPROPERTY(Category = "Attribute|Boost")
	bool bCanBoost = true;

	// Set in magnet base pad actor
	UPROPERTY(BlueprintReadOnly)
	float BoostLaunchForce;

	// Set in magnet base pad actor
	UPROPERTY(BlueprintReadOnly)
	float CarryingPickupBoostForce;

	UPROPERTY(Category = "Attribute")
	FVector OverrideBoostDirection = FVector::ZeroVector;

	UPROPERTY(Category = "Attribute|Attract")
	bool bCanAttract = true;

	float LaunchSpeed = 8000.f;

	UPROPERTY()
	float PerchPointDistanceFromBase = 75.f;

	UPROPERTY()
	float CameraDistanceToPerch = 300.f;

	UPROPERTY()
	bool bAffectCamera = true;

	UPROPERTY(BlueprintReadOnly)
	bool bShotByCannon = false;

	FOnBasePadUsedPerchStateChanged OnBasePadUsedPerchStateChanged;
	FOnBasePadBoost OnBasePadBoost;

	// Boost constants
	const FVector CodyBoostWallOffset = FVector(190.f, 60.f, 70.f);
	const FVector CodyBoostGroundOffset = FVector(-80.f, 0.f, 0.f);
	const FVector MayBoostWallOffset = FVector::ZeroVector;
	const FVector MayBoostGroundOffset = FVector::ZeroVector;

	const float CeilingPerchPlayerMagnetOffset = 140.f;

	bool bPadIsActive = true;
	bool bPadIsBeingUsed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bIgnoreAttachParentInLineOfSightTest = false;
	}

	// This function implements how the magnets are displayed and grabable
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{
		// Don't activate magnet if player is not facing magnet
		FVector MagnetToPlayer = (Player.ActorCenterLocation - Owner.ActorLocation).GetSafeNormal();
		if(MagnetToPlayer.DotProduct(MagneticVector) < 0.f)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Prioritized queries are always valid
		if(Query.bIsPreSelected)
			return EHazeActivationPointStatusType::Valid;

		// Don't activate magnet if other player is using it
		UMagneticPlayerComponent OtherMagneticPlayerComponent = UMagneticPlayerComponent::Get(Player.OtherPlayer);
		if(OtherMagneticPlayerComponent.ActivatedMagnet != nullptr && OtherMagneticPlayerComponent.ActivatedMagnet.Owner == Owner)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't activate magnet if player is activating player attraction
		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(Player);
		if(MagneticPlayerAttractionComponent != nullptr && MagneticPlayerAttractionComponent.IsPlayerAttractionActive())
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Handle polarity-specific cases
		UMagneticComponent PlayerPolarityComponet = UMagneticComponent::Get(Player);
		if(HasEqualPolarity(PlayerPolarityComponet))
		{
			if(!bCanBoost)
				return EHazeActivationPointStatusType::InvalidAndHidden;

			// Don't activate if player is not above magnet
			// MagnetToPlayer = (Player.ActorCenterLocation - Owner.ActorLocation).GetSafeNormal();
			// if(MagnetToPlayer.DotProduct(Player.MovementWorldUp) < 0.f)
			// {
			// 	if(Player.ActorLocation.Distance(WorldLocation) > 200.f)
			// 		return EHazeActivationPointStatusType::InvalidAndHidden;
			// }
		}
		else
		{
			if(!bCanAttract)
				return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		// Super magnets should not display edge gui
		if(!IsInCameraView(Player))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't show visible dot on super magnets
		if(Query.DistanceType == EHazeActivationPointDistanceType::Visible)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		return Super::SetupActivationStatus(Player, Query);
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const override
	{
		// Only show targetted magnet when perching on a different wall magnet
		if(IsWallPerch() && Player.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchPerchCapability))
		{
			if(Query.IsTargeted())
				return EHazeActivationPointStatusType::Invalid;

			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		return Super::SetupWidgetVisibility(Player, Query);
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{
		float ValidationScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);

		// Boost platforms take priority
		if(HasEqualPolarity(UMagneticComponent::Get(Player)))
		{
			ValidationScoreAlpha *= 2.f;
		}
		else
		{
			// Use magnetic input vector bias only when perching on magnet
			if(Player.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchPerchCapability))
			{
				UMagneticPlayerComponent MagneticPlayerComponent = UMagneticPlayerComponent::Get(Player);

				FVector PlayerToMagnet = (WorldLocation - Player.ActorLocation).GetSafeNormal();
				float PlayerInputBias = Math::Saturate(PlayerToMagnet.DotProduct(MagneticPlayerComponent.PlayerInputBias));
				
				// ValidationScoreAlpha *= PlayerInputBias;
				ValidationScoreAlpha = (ValidationScoreAlpha + PlayerInputBias) / 2.f;
			}
			else
			{
				auto PrioritizedMagnet = UMagneticPlayerComponent::Get(Player).PrioritizedMagnet;
				if(PrioritizedMagnet != nullptr && PrioritizedMagnet != this)
					return 0.f;
			}
		}

		return Math::Saturate(ValidationScoreAlpha);
	}

	FVector GetMagneticVector() const property
	{
		return Owner.ActorForwardVector.GetSafeNormal();
	}

	FVector GetPlayerPerchPoint(AHazePlayerCharacter PlayerCharacter, bool AdjustForCeilingMeshOffset = false) const
	{
		FVector HeightAdjust = FVector::ZeroVector;

		// If this is a ceiling perch, player needs to be offset downwards so that the collision shape
		// doesn't overlap the platform; also offset by magnet's length
		if(GetCurrentPlatformType() == EMagnetPlatformType::Ceiling && AdjustForCeilingMeshOffset)
		{
			UHazeMovementComponent MovementComponent = UHazeMovementComponent::Get(PlayerCharacter);
			UCapsuleComponent SphereCollider = Cast<UCapsuleComponent>(MovementComponent.CollisionShapeComponent);
			
			HeightAdjust.Z = SphereCollider.CapsuleHalfHeight * 2.f + CeilingPerchPlayerMagnetOffset;
		}

		return Owner.GetActorLocation() + GetMagneticVector() * PerchPointDistanceFromBase - HeightAdjust;
	}

	FVector GetPlayerBoostPoint(AHazePlayerCharacter PlayerCharacter) const
	{
		// Adjust height offset if magnet is of wall type
		FVector UpOffset = FVector::ZeroVector;
		FVector RightOffset = FVector::ZeroVector;
		float DistanceFromPoint = PerchPointDistanceFromBase;

		EMagnetPlatformType MagnetPlatformType = GetCurrentPlatformType();
		if(MagnetPlatformType == EMagnetPlatformType::Wall)
		{
			FVector BoostWallOffset = PlayerCharacter.IsMay() ? MayBoostWallOffset : CodyBoostWallOffset;

			FVector PlayerToMagnet = (PlayerCharacter.ActorLocation - WorldLocation).GetSafeNormal();
			FVector ProperRightVector = PlayerToMagnet.CrossProduct(MagneticVector);
			ProperRightVector = MagneticVector.CrossProduct(PlayerCharacter.MovementWorldUp).GetSafeNormal();

			// Apply character-specific offsets
			UpOffset = MagneticVector.CrossProduct(ProperRightVector).GetSafeNormal() * BoostWallOffset.Z;
			RightOffset = ProperRightVector * BoostWallOffset.Y;
			DistanceFromPoint = BoostWallOffset.X;
		}
		else if(MagnetPlatformType == EMagnetPlatformType::Ground)
		{
			FVector BoostGroundOffset = PlayerCharacter.IsMay() ? MayBoostGroundOffset : CodyBoostGroundOffset;
			UpOffset = -PlayerCharacter.ActorForwardVector * BoostGroundOffset.X;
		}

		return Owner.GetActorLocation() + GetMagneticVector() * DistanceFromPoint + RightOffset + UpOffset;
	}

	// Note: Do not cache this variable! Always get the freshest!
	EMagnetPlatformType GetCurrentPlatformType() const property
	{
		EMagnetPlatformType MagnetPlatformType;
     	float Inclination = GetMagneticVector().DotProduct(FVector::UpVector);

		if(Inclination < -0.6f)
			MagnetPlatformType = EMagnetPlatformType::Ceiling;
		else if (Inclination < 0.85f)
			MagnetPlatformType = EMagnetPlatformType::Wall;
		else if(Inclination <= 1.f )
			MagnetPlatformType = EMagnetPlatformType::Ground;

		return MagnetPlatformType;
	}

	void StartUsingPad()
	{
		bPadIsBeingUsed = true;
		OnBasePadUsedPerchStateChanged.Broadcast(bPadIsBeingUsed);
	}

	void StopUsingPad()
	{
		bPadIsBeingUsed = false;
		OnBasePadUsedPerchStateChanged.Broadcast(bPadIsBeingUsed);
	}

	void UsedBoost()
	{
		OnBasePadBoost.Broadcast();
	}

	bool IsGroundPerch() const
	{
		return GetCurrentPlatformType() == EMagnetPlatformType::Ground;
	}

	bool IsPerfectGroundPerch() const
	{
		return FMath::IsNearlyEqual(GetMagneticVector().DotProduct(FVector::UpVector), 1.f, 0.005f);
	}

	bool IsWallPerch() const
	{
		return GetCurrentPlatformType() == EMagnetPlatformType::Wall;
	}

	bool IsCeilingPerch() const
	{
		return GetCurrentPlatformType() == EMagnetPlatformType::Ceiling;
	}

	UHazeLocomotionStateMachineAsset GetLocomotionStateMachineAsset(AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerPickupComponent PickupComponent = UPlayerPickupComponent::Get(PlayerCharacter);
		if(PickupComponent.IsHoldingObject())
		{
			switch(PickupComponent.GetPickupType())
			{
				case EPickupType::Small:
				case EPickupType::HeavySmall:
					return AnimationStateMachineAsset.SmallPickupLocomotionStateMachine;

				case EPickupType::Big:
					return AnimationStateMachineAsset.PickupLocomotionStateMachine;
			}
		}

		return AnimationStateMachineAsset.NormalLocomotionStateMachine;
	}

	// Super magnets are available for querying while player is perching
	protected bool ShouldInvalidateStatusOnPlayerMagnetPerch() const override
	{
		return false;
	}

	// Will prioritize this super magnet above the rest for the given time
	void PrioritizeForPlayerOverTime(AHazePlayerCharacter PlayerCharacter, float Time)
	{
		UMagneticPlayerComponent::Get(PlayerCharacter).PrioritizedMagnet = this;

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.SetCapabilityAttributeObject(n"PlayerCharacter", PlayerCharacter);
		HazeOwner.SetCapabilityAttributeObject(FMagneticTags::SuperMagnetComponent, this);
		HazeOwner.SetCapabilityAttributeValue(FMagneticTags::SuperMagnetPriorityDuration, Time);

		// This capability will clear the prioritization flag
		HazeOwner.AddCapability(FMagneticTags::MagneticPerchAndBoostPriorityCapability);
	}
}