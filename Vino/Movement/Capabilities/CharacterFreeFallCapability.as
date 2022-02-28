import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.MovementSettings;

UCLASS(Abstract)
class UCharacterFreeFallCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AirMovement);
	default CapabilityTags.Add(MovementSystemTags::Falling);
		
	default TickGroup = ECapabilityTickGroups::LastMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

    UPROPERTY()
    UAnimSequence CodyAnimation;
    UPROPERTY()
    UAnimSequence MayAnimation;
	UAnimSequence FallingAnimation;

	UPROPERTY()
	UBlendSpace CodyBlendSpace;
	UPROPERTY()
	UBlendSpace MayBlendSpace;

	UPROPERTY()
	UAnimSequence CodyLandingAnimation;
	UPROPERTY()
	UAnimSequence MayLandingAnimation;

	FVector AccumulatedForces = FVector::ZeroVector;
	AHazePlayerCharacter Player;

	bool bLanding = false;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	FVector2D CurrentBlendSpaceValue;
	FVector2D TargetBlendSpaceValue;

	FTimerHandle BlendSpaceUpdateTimer;

	float InputDelay = 0.2f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);

		FallingAnimation = Player.IsCody() ? CodyAnimation : MayAnimation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"FreeFalling"))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"FreeFalling"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bLanding = false;

        SetMutuallyExclusive(CapabilityTags::Movement, true);

		UBlendSpace BlendSpace = Player.IsCody() ? CodyBlendSpace : MayBlendSpace;

		Player.PlayBlendSpace(BlendSpace);

        FHazeCameraBlendSettings BlendSettings;
        BlendSettings.BlendTime = 1.f;
        Player.ApplyCameraSettings(CameraSettings, BlendSettings, this);

		Player.BlockCapabilities(n"CanActivateCheckpointVolumes", this);

		if (Player.HasControl())
			BlendSpaceUpdateTimer = System::SetTimer(this, n"UpdateBlendSpaceValue", 0.2f, true);

		System::SetTimer(this, n"EnableInput", InputDelay, false);

		UMovementSettings::SetActorMaxFallSpeed(Owner, 1500.f, Instigator = this);		
	}

	UFUNCTION()
	void EnableInput()
	{
		//Player.UnblockCapabilities(CapabilityTags::StickInput, nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!AccumulatedForces.IsNearlyZero())
		{
			AccumulatedForces = FVector::ZeroVector;
		}

		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, false);
		}

		SetMutuallyExclusive(CapabilityTags::Movement, false);

		Player.StopBlendSpace();

		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(n"CanActivateCheckpointVolumes", this);

		if (Player.HasControl())
			System::ClearAndInvalidateTimerHandle(BlendSpaceUpdateTimer);

		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bLanding)
			return;

		FHitResult HitResult;

		bLanding = MoveComp.LineTraceGround(Player.ActorLocation, HitResult);

		if(bLanding)
		{
			bLanding = true;

			if(IsActioning(n"FreeFallSafety"))
			{
				LandSafely();
				return;
			}
			else
			{
				LandUnsafely();
				return;
			}
		}

		const bool bHasControl = HasControl();

		FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
        if(bHasControl)
        {
            InputVector = InputVector.ConstrainToPlane(MoveComp.WorldUp);
			TargetBlendSpaceValue = FVector2D(InputVector.X, InputVector.Y);
        }

		UpdateBlendSpace(DeltaTime);

		InputVector.Z = -2.5f;

		FHazeFrameMovement FreeFallMove = MoveComp.MakeFrameMovement(n"FreeFall");
		FreeFallMove.ApplyAndConsumeImpulses();
		FreeFallMove.ApplyGravityAcceleration();
		FreeFallMove.ApplyDelta(InputVector * 500.f * DeltaTime);
		FreeFallMove.ApplyTargetRotationDelta();		
		FreeFallMove.OverrideStepUpHeight(0.f);
		FreeFallMove.OverrideStepDownHeight(1.f);

		MoveCharacter(FreeFallMove, FeatureName::AirMovement);

		if(!bHasControl)
		{
			CrumbComp.SetCrumbDebugActive(this, IsDebugActive());
		}
	}

	UFUNCTION()
	void UpdateBlendSpaceValue()
	{
		NetUpdateBlendSpaceValue(TargetBlendSpaceValue);
	}

	UFUNCTION(NetFunction)
	void NetUpdateBlendSpaceValue(FVector2D NewValue)
	{
		TargetBlendSpaceValue = NewValue;
	}

	void UpdateBlendSpace(float DeltaTime)
	{
        CurrentBlendSpaceValue.X = FMath::FInterpTo(CurrentBlendSpaceValue.X, TargetBlendSpaceValue.X, DeltaTime, 5.f);
        CurrentBlendSpaceValue.Y = FMath::FInterpTo(CurrentBlendSpaceValue.Y, TargetBlendSpaceValue.Y, DeltaTime, 5.f);
		
		Player.SetBlendSpaceValues(CurrentBlendSpaceValue.X, CurrentBlendSpaceValue.Y);
	}

	void LandSafely()
	{
		Player.SetCapabilityActionState(n"FreeFalling", EHazeActionState::Inactive);
		UAnimSequence LandingAnimation = Player.IsCody() ? CodyLandingAnimation : MayLandingAnimation;
		Player.PlaySlotAnimation(Animation = LandingAnimation);

		FHazePointOfInterest PointOfInterestSettings;
		PointOfInterestSettings.FocusTarget.Actor = Player;
		PointOfInterestSettings.FocusTarget.LocalOffset = FVector(500.f, 0.f, 500.f);
		PointOfInterestSettings.Duration = 0.5f;
		Player.ApplyPointOfInterest(PointOfInterestSettings, this);
	}

	void LandUnsafely()
	{
		Player.SetCapabilityActionState(n"FreeFalling", EHazeActionState::Inactive);
		KillPlayer(Player, DeathEffect);
	}
}
