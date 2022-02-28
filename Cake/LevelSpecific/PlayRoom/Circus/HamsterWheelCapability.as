import Cake.LevelSpecific.PlayRoom.Circus.HamsterWheelActor;
import Vino.Tutorial.TutorialStatics;

UCLASS(Abstract)
class UHamsterWheelCapability : UHazeCapability
{
default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;

    UHazeBaseMovementComponent Movement;

    AHamsterWheelActor CurrentWheel;

	UHazeTriggerComponent Interaction;

	UPROPERTY()
	UBlendSpaceBase CodyBlendSpace;

	UPROPERTY()
	UBlendSpaceBase MayBlendSpace;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
        Movement = UHazeBaseMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(IsActioning(n"InHamsterWheel"))
            return EHazeNetworkActivation::ActivateLocal;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(IsActioning(ActionNames::Cancel))
		    return EHazeNetworkDeactivation::DeactivateFromControl;
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        CurrentWheel = Cast<AHamsterWheelActor>(GetAttributeObject(n"HamsterWheel"));
		Interaction = Cast<UHazeTriggerComponent>(GetAttributeObject(n"Interaction"));

        Player.BlockCapabilities(n"Movement", this);

		if (Player.IsCody())
		{
			Player.PlayBlendSpace(CodyBlendSpace);
		}
		else
		{
			Player.PlayBlendSpace(MayBlendSpace);
		}
		
		Player.CleanupCurrentMovementTrail();
		Player.AttachToComponent(CurrentWheel.PlayerPositionInWheel, AttachmentRule = EAttachmentRule::KeepWorld);
		Player.SetActorRotation(CurrentWheel.PlayerPositionInWheel.WorldRotation+FRotator(0,90,0));
		Player.SetActorLocation(CurrentWheel.PlayerPositionInWheel.WorldLocation);

		FHazeCameraBlendSettings blendSettings;
		blendSettings.BlendTime = 1;

		Player.ApplyCameraSettings(CameraSettings, blendSettings, this, EHazeCameraPriority::Medium);
		
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.UnblockCapabilities(n"Movement", this);
        Player.StopAnimation();
        Player.SetCapabilityActionState(n"InHamsterWheel", EHazeActionState::Inactive);
        Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
        CurrentWheel.ReleaseWheel(Interaction);
		Player.ClearCameraSettingsByInstigator(this);
		Player.StopBlendSpace();
		
		FHazeJumpToData JumpToData;
		JumpToData.AdditionalHeight = 100;
		JumpToData.TargetComponent = CurrentWheel.JumpoffLocation;
		JumpTo::ActivateJumpTo(Player, JumpToData);

		RemoveCancelPromptByInstigator(Player, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CurrentWheel.UpdateMoveDirection(GetAttributeVector(AttributeVectorNames::MovementDirection));
		UpdateAnimations();
	}

	void UpdateAnimations()
	{
		float CurrentSpeed = CurrentWheel.CurrentSpeed;
		FVector Movedir = GetAttributeVector(AttributeVectorNames::MovementDirection);
		float bIsBlocked;

		if (FMath::Abs(CurrentSpeed) < 5.f)
		{
			bIsBlocked = 1;
		}
		else
		{
			bIsBlocked = 0;
		}

		if (FMath::Abs(Movedir.X) < 0.2f  )
		{
			bIsBlocked = 0;
		}

		FVector2D InputRange;
		InputRange.X = -100;
		InputRange.Y = 100;
		FVector2D OutputRange;
		OutputRange.X = -1;
		OutputRange.Y = 1;
		CurrentSpeed = FMath::GetMappedRangeValueClamped(InputRange, OutputRange, CurrentSpeed);

		Player.SetBlendSpaceValues(bIsBlocked,  CurrentSpeed);

		float ForceFeedbackValue = FMath::Lerp(0.f, 0.05f, FMath::Abs(CurrentSpeed));
		if (CurrentSpeed < 0.f)
			Player.SetFrameForceFeedback(0.f, ForceFeedbackValue);
		else if (CurrentSpeed > 0.f)
			Player.SetFrameForceFeedback(ForceFeedbackValue, 0.f);
	}
}