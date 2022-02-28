import Vino.Movement.Components.MovementComponent;
import Vino.Characters.PlayerCharacter;
import Vino.Camera.Capabilities.DebugCameraCapability;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterFloorMoveCapability;
import Vino.PlayerHealth.PlayerRespawnComponent;

class UCharacterLargeSizeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gravity");
	default CapabilityTags.Add(n"ChangeSize");
	default CapabilityTags.Add(n"MutuallyExclusiveSize");

	default CapabilityDebugCategory = n"ChangeSize";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 75;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCharacterChangeSizeComponent ChangeSizeComp;

	float TargetScale = 4.f;

	float ForceFeedbackIntensity = 0.05f;

	bool bChangingScale = false;
	bool bForceReset = false;

	float TargetMovementSpeed = 800.f;

	FCharacterSizeValues MovementModifierValues;
	default MovementModifierValues.Small = 0.1f;
	default MovementModifierValues.Medium = 1.f;
	default MovementModifierValues.Large = 4.f;

	float ScaleDuration = 0.25f;

	bool bBlocked = false;

	FVector FailedSizeIncreasedImpactPoint;

	UPROPERTY()
	UMaterialParameterCollection MaterialParamCollection;

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
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"HasPendingPickup"))
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsPlayingAnimAsSlotAnimation(ChangeSizeComp.ObstructedAnimation))
			return EHazeNetworkActivation::DontActivate;

		if (!Player.IsAnyCapabilityActive(UCharacterFloorMoveCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(n"ValidationMovement"))
			return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.bChangingSize)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(UDebugCameraCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (ChangeSizeComp.CurrentSize != ECharacterSize::Medium)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ChangeSizeComp.CurrentSize != ECharacterSize::Large)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (bBlocked)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
    void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
    {

    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bBlocked = false;

		Player.PlayCameraShake(ChangeSizeComp.CameraShakes.MediumToLarge, 3.f);

		if (HasControl())
		{
			Player.BlockCapabilities(CapabilityTags::Interaction, this);
			Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		}

		Player.ApplyCameraSettings(ChangeSizeComp.LargeCameraSettings, FHazeCameraBlendSettings(0.5f), this);

		ChangeSizeComp.bChangingSize = true;
		bChangingScale = true;

		ChangeSizeComp.SetSize(ECharacterSize::Large);

		Player.AddCapabilitySheet(ChangeSizeComp.LargeSheet, EHazeCapabilitySheetPriority::Normal, this);

		Player.AddLocomotionAsset(ChangeSizeComp.LargeStateMachineAsset, this, 50);

		Player.ApplySettings(ChangeSizeComp.LargeHealthSettings, this);
		Player.ApplySettings(ChangeSizeComp.LargeMovementSettings, this);

		if (ChangeSizeComp.LargeRespawnEffect != nullptr)
			SetRespawnSystem(Player, ChangeSizeComp.LargeRespawnEffect);
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
		Player.ClearCameraSettingsByInstigator(this, 0.5f);
		Player.ClearSettingsByInstigator(this);

		Player.RemoveCapabilitySheet(ChangeSizeComp.LargeSheet, this);

		Player.RemoveLocomotionAsset(ChangeSizeComp.LargeStateMachineAsset, this);

		if (DeactivationParams.GetActionState(n"Blocked"))
		{	
			FHazeAnimationDelegate BlendingOutDelegate;
			BlendingOutDelegate.BindUFunction(this, n"ObstructedBlendingOut");
			Player.PlaySlotAnimation(OnBlendingOut = BlendingOutDelegate, Animation = ChangeSizeComp.ObstructedAnimation);
			Niagara::SpawnSystemAtLocation(ChangeSizeComp.MediumToLargeObstructedEffect, DeactivationParams.GetVector(n"ImpactPoint"));
			bChangingScale = false;
			ChangeSizeComp.bChangingSize = false;
			UnblockCapabilities();

			Player.PlayCameraShake(ChangeSizeComp.CameraShakes.MediumObstructed);
			Player.PlayForceFeedback(ChangeSizeComp.ObstructedForceFeedback, false, true, n"Obstructed");

			if (HasControl())
			{
				Player.BlockCapabilities(CapabilityTags::Input, this);
				Player.SetCapabilityActionState(n"ForceResetSize", EHazeActionState::ActiveForOneFrame);
			}
		}

		if (bChangingScale)
		{
			UnblockCapabilities();
			bChangingScale = false;
			ChangeSizeComp.bChangingSize = false;
		}

		ResetRespawnSystem(Player);
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
		Player.ClearCameraSettingsByInstigator(this, 0.5f);
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
			float CurScale = FMath::Lerp(1.f, 4.f, CurAlpha);

			if (HasControl())
			{
				TArray<AActor> ActorsToIgnore;
				ActorsToIgnore.Add(Game::GetCody());
				ActorsToIgnore.Add(Game::GetMay());
				FVector TraceStartLoc = Player.ActorLocation + (Player.MovementWorldUp * (Player.CapsuleComponent.CapsuleHalfHeight * CurScale));
				TraceStartLoc += (Player.MovementWorldUp * 50.f);
				FHitResult Hit;
				System::CapsuleTraceSingle(TraceStartLoc, TraceStartLoc + FVector(0.f, 0.f, 1.f), (Player.CapsuleComponent.CapsuleRadius * CurScale) + 15.f, Player.CapsuleComponent.CapsuleHalfHeight * CurScale, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

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