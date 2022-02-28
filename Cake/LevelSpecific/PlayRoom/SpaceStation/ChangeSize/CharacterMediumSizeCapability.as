import Vino.Movement.Components.MovementComponent;
import Vino.Characters.PlayerCharacter;
import Vino.Camera.Capabilities.DebugCameraCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterFloorMoveCapability;

class UCharacterMediumSizeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gravity");
	default CapabilityTags.Add(n"MediumSize");
	default CapabilityTags.Add(n"MutuallyExclusiveSize");

	default CapabilityDebugCategory = n"ChangeSize";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCharacterChangeSizeComponent ChangeSizeComp;

	float StartScale = 1.f;
	float TargetScale = 1.f;

	float ForceFeedbackIntensity = 0.05f;

	bool bChangingScale = false;
	bool bForceReset = false;

	float TargetMovementSpeed = 1600.f;

	FCharacterSizeValues MovementModifierValues;
	default MovementModifierValues.Small = 0.1f;
	default MovementModifierValues.Medium = 1.f;
	default MovementModifierValues.Large = 4.f;

	float ScaleDuration = 0.25f;

	bool bScalingUp = false;

	bool bFirstTimeActivation = true;

	UPROPERTY()
	UMaterialParameterCollection MaterialParamCollection;

	bool bBlocked = false;

	FVector FailedSizeIncreasedImpactPoint;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
		ChangeSizeComp = UCharacterChangeSizeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bFirstTimeActivation)
			return EHazeNetworkActivation::ActivateFromControl;

		if (IsActioning(n"ForceResetSize") && ChangeSizeComp.CurrentSize != ECharacterSize::Medium)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (!SizeChangeAttemptValid())
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"HasPendingPickup"))
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsPlayingAnimAsSlotAnimation(ChangeSizeComp.ObstructedAnimation))
			return EHazeNetworkActivation::DontActivate;

		if (!Player.IsAnyCapabilityActive(UCharacterFloorMoveCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.bChangingSize)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(UDebugCameraCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.CurrentSize == ECharacterSize::Medium)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	bool SizeChangeAttemptValid() const
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && ChangeSizeComp.CurrentSize == ECharacterSize::Small)
			return true;

		if (WasActionStarted(ActionNames::SecondaryLevelAbility) && ChangeSizeComp.CurrentSize == ECharacterSize::Large)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ChangeSizeComp.CurrentSize != ECharacterSize::Medium)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (bBlocked)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
    void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
    {
		bForceReset = IsActioning(n"ForceResetSize");
		if (bForceReset)
		{
			if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
				bScalingUp = false;
			else
			{
				bScalingUp = true;
				ActivationParams.AddActionState(n"ScalingUp");
			}

			return;
		}

		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
		{
			bScalingUp = true;
			ActivationParams.AddActionState(n"ScalingUp");
		}
		else
			bScalingUp = false;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Clear out the other size capabilities so we know that the activation params here
		// will be correctly setup
		SetMutuallyExclusive(n"MutuallyExclusiveSize", true);
		SetMutuallyExclusive(n"MutuallyExclusiveSize", false);

		bBlocked = false;
		bScalingUp = ActivationParams.GetActionState(n"ScalingUp");
		ResetPlayerGroundPoundLandCameraImpulse(Player);

		if (!bFirstTimeActivation)
		{
			TSubclassOf<UCameraShakeBase> CamShakeClass = bScalingUp ? ChangeSizeComp.CameraShakes.SmallToMedium : ChangeSizeComp.CameraShakes.LargeToMedium;
			Player.PlayCameraShake(CamShakeClass);

			if (HasControl())
			{
				Player.BlockCapabilities(CapabilityTags::Interaction, this);
				Player.BlockCapabilities(CapabilityTags::MovementAction, this);
			}

			ChangeSizeComp.bChangingSize = true;
			bChangingScale = true;

			StartScale = Player.ActorScale3D.Z;

			ChangeSizeComp.SetSize(ECharacterSize::Medium);
		}

		bFirstTimeActivation = false;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if (bBlocked)
		{
			DeactivationParams.AddActionState(n"Blocked");
			DeactivationParams.AddVector(n"ImpactPoint", FailedSizeIncreasedImpactPoint);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (DeactivationParams.GetActionState(n"Blocked"))
		{	
			if (HasControl())
				Player.BlockCapabilities(CapabilityTags::Input, this);
				
			FHazeAnimationDelegate BlendingOutDelegate;
			BlendingOutDelegate.BindUFunction(this, n"ObstructedBlendingOut");
			Player.PlaySlotAnimation(OnBlendingOut = BlendingOutDelegate, Animation = ChangeSizeComp.ObstructedAnimation);
			Niagara::SpawnSystemAtLocation(ChangeSizeComp.SmallToMediumObstructedEffect, DeactivationParams.GetVector(n"ImpactPoint"));
			bChangingScale = false;
			ChangeSizeComp.bChangingSize = false;
			UnblockCapabilities();

			Player.PlayCameraShake(ChangeSizeComp.CameraShakes.SmallObstructed);
			Player.PlayForceFeedback(ChangeSizeComp.ObstructedForceFeedback, false, true, n"Obstructed");

			if (HasControl())
			{
				Player.SetCapabilityActionState(n"ForceSmallSize", EHazeActionState::Active);
			}
		}

		if(bChangingScale)
		{
			UnblockCapabilities();
			bChangingScale = false;
			ChangeSizeComp.bChangingSize = false;
		}

		bForceReset = false;
	}

	UFUNCTION()
	void ObstructedBlendingOut()
	{
		if (HasControl())
			Player.UnblockCapabilities(CapabilityTags::Input, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 0.25f);
		Player.SetActorScale3D(FVector::OneVector);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bChangingScale)
		{
			Player.SetFrameForceFeedback(ForceFeedbackIntensity, ForceFeedbackIntensity);
			float CurAlpha = FMath::GetMappedRangeValueClamped(FVector2D(0.f, ScaleDuration), FVector2D(0.f, 1.f), ActiveDuration);
			CurAlpha = FMath::Clamp(CurAlpha, 0.f, 1.f);
			float CurScale = FMath::Lerp(StartScale, 1.f, CurAlpha);

			if (bScalingUp && HasControl() && !bForceReset)
			{
				TArray<AActor> ActorsToIgnore;
				ActorsToIgnore.Add(Game::GetCody());
				ActorsToIgnore.Add(Game::GetMay());
				FVector TraceStartLoc = Player.ActorLocation + (Player.MovementWorldUp * (Player.CapsuleComponent.CapsuleHalfHeight * CurScale));
				TraceStartLoc += (Player.MovementWorldUp * 5.f);
				FHitResult Hit;
				System::CapsuleTraceSingle(TraceStartLoc, TraceStartLoc + FVector(0.f, 0.f, 1.f), (Player.CapsuleComponent.CapsuleRadius * CurScale) + 5.f, Player.CapsuleComponent.CapsuleHalfHeight * CurScale, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

				if (Hit.bBlockingHit)
				{
					FailedSizeIncreasedImpactPoint = Hit.ImpactPoint;
					bBlocked = true;
					return;
				}
			}

			MoveComp.SetControlledComponentScale(CurScale);

			if (FVector(CurScale).Equals(FVector(TargetScale)))
			{
				bChangingScale = false;
				bForceReset = false;
				UnblockCapabilities();
				ChangeSizeComp.bChangingSize = false;
			}
		}
	}

	void UnblockCapabilities()
	{
		if (HasControl())
		{
			Player.UnblockCapabilities(CapabilityTags::Interaction, this);
			Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		}
	}
}