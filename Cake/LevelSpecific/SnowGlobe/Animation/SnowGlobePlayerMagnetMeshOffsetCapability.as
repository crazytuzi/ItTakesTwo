import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

class USnowGlobePlayerMagnetMeshOffsetDataAsset : UDataAsset
{
	UPROPERTY(DisplayName = "Locomotion Tags With No Offset")
	TArray<FName> NoOffsetTags;
}

class USnowGlobePlayerMagnetMeshOffsetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowGlobe");
	default CapabilityTags.Add(n"SnowGlobePlayerMagnetMeshOffset");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UPROPERTY()
	USnowGlobePlayerMagnetMeshOffsetDataAsset PlayerMagnetMeshOffsetDataAsset;

	UPROPERTY()
	FTransform PlayerMagnetMeshOffset;

	UPROPERTY()
	float MeshOffsetLerpTime = 0.2f;

	UPROPERTY()
	UAnimSequence SequenceSnapSlotAnimationOverride;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;
	APlayerMagnetActor PlayerMagnet;

	UHazeCharacterAnimInstance CharacterAnimInstance;

	FHazeAcceleratedVector TranslationAccelerator;
	FHazeAcceleratedRotator RotationAccelerator;

	FTransform OffsetTarget = FTransform::Identity;

	float LerpTime = 0.f;

	bool bMeshIsOffset = false;
	bool bIsLerping = false;

	bool bShouldSnapOffset = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		CharacterAnimInstance = Cast<UHazeCharacterAnimInstance>(PlayerOwner.Mesh.GetAnimInstance());

		// Bind cutscene end delegate
		PlayerOwner.OnPostSequencerControl.AddUFunction(this, n"OnPostSequencerControl");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerMagnet = UMagneticPlayerComponent::Get(Owner).PlayerMagnet;

		// Used in level_BP's in some spesific edge cases
		if(IsActioning(n"ShouldSnapOffset"))
			bShouldSnapOffset = true;

		// In other edgier cases we want to not snap it...
		if(IsActioning(n"DontOffsetMagnet"))
			bShouldSnapOffset = false;

		// Wacky haxy shit to instantly reset backpack bone
		if(bShouldSnapOffset)
		{
			FHazePlayOverrideAnimationParams OverrideAnimationParams;
			OverrideAnimationParams.Animation = SequenceSnapSlotAnimationOverride;
			OverrideAnimationParams.bLoop = false;
			OverrideAnimationParams.BlendTime = 0.f;
			OverrideAnimationParams.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_Backpack;
			OverrideAnimationParams.bOverwriteIfAlreadyPlaying = true;
			OverrideAnimationParams.Priority = EHazeAnimPriority::AnimPrio_MAX;
			PlayerOwner.PlayOverrideAnimation(FHazeAnimationDelegate(), OverrideAnimationParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShouldOffsetMagnetMesh())
		{
			if(!bMeshIsOffset && !bIsLerping)
				OffsetMesh();
		}
		else
		{
			if(bMeshIsOffset && !bIsLerping)
				ResetMeshOffset();
		}

		if(bIsLerping)
			TickMeshLerp(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// Can only be deactivated by being blocked; which will typically happen whenever a cutscene starts playing
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Eman TODO: Lerp out!
		PlayerMagnet.SetActorRelativeTransform(FTransform::Identity);

		OffsetTarget = FTransform::Identity;

		LerpTime = 0.f;

		bMeshIsOffset = false;
		bIsLerping = false;
	}

	bool ShouldOffsetMagnetMesh()
	{
		if(PlayerMagnetMeshOffsetDataAsset.NoOffsetTags.Contains(CharacterAnimInstance.CurLocomotionRequest.AnimationTag))
			return false;

		if(PlayerOwner.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttraction))
			return false;

		if(PlayerOwner.IsAnyCapabilityActive(FMagneticTags::IsUsingMagnet))
			return false;

		if(IsActioning(n"DontOffsetMagnet"))
			return false;

		return true;
	}

	private void OffsetMesh()
	{
		if(bShouldSnapOffset)
		{
			TranslationAccelerator.SnapTo(PlayerMagnetMeshOffset.Location);
			RotationAccelerator.SnapTo(PlayerMagnetMeshOffset.Rotator());

			LerpTime = MeshOffsetLerpTime;
			bShouldSnapOffset = false;
		}
		else
		{
			TranslationAccelerator.SnapTo(FVector::ZeroVector);
			RotationAccelerator.SnapTo(FRotator::ZeroRotator);
		}

		OffsetTarget = PlayerMagnetMeshOffset;

		bIsLerping = true;
		bMeshIsOffset = true;
	}

	private void ResetMeshOffset()
	{
		TranslationAccelerator.SnapTo(PlayerMagnetMeshOffset.Location);
		RotationAccelerator.SnapTo(PlayerMagnetMeshOffset.Rotator());

		OffsetTarget = FTransform::Identity;

		bIsLerping = true;
		bMeshIsOffset = false;
	}

	private void TickMeshLerp(float DeltaTime)
	{
		LerpTime += DeltaTime;

		FVector Translation = TranslationAccelerator.AccelerateTo(OffsetTarget.Location, MeshOffsetLerpTime, DeltaTime);
		FRotator Rotation = RotationAccelerator.AccelerateTo(OffsetTarget.Rotator(), MeshOffsetLerpTime, DeltaTime);

		PlayerMagnet.SetActorRelativeTransform(FTransform(Rotation, Translation));

		if(LerpTime >= MeshOffsetLerpTime)
		{
			bIsLerping = false;
			LerpTime = 0.f;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPostSequencerControl(FHazePostSequencerControlParams Params)
	{
		if(ShouldOffsetMagnetMesh())
			bShouldSnapOffset = true;
	}
}