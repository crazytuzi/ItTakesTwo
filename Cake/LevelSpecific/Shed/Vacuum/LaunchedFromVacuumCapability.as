import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Shed.Vacuum.GoingThroughVacuumCapability;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

class ULaunchedFromVacuumCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"GameplayAction");
    default CapabilityTags.Add(n"Vacuum");
	default CapabilityTags.Add(n"LevelSpecific");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 15;

	AHazePlayerCharacter Player;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyLaunchAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayLaunchAnimation;

    UPROPERTY(Category = "Animation")
    UAnimSequence CodyLandAnimation;

    UPROPERTY(Category = "Animation")
    UAnimSequence MayLandAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY()
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY()
	UVacuumVOBank VOBank;

	AVacuumHoseActor Hose;

	EVacuumMountLocation MountLocation;

	UPROPERTY()
	FHazeTimeLike MoveToLaunchLocationTimeLike;
	default MoveToLaunchLocationTimeLike.Duration = 0.1f;

	FVacuumLaunchProperties LaunchProperties;

	FVector CurrentBlendSpaceValues = FVector::ZeroVector;

	bool bLaunching = false;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity CodyZeroGFeature;
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity MayZeroGFeature;

	FTimerHandle BarkHandle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);

		MoveToLaunchLocationTimeLike.BindUpdate(this, n"UpdateLaunchLocation");
		MoveToLaunchLocationTimeLike.BindFinished(this, n"FinishLaunchLocation");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"LaunchedFromVacuum"))
            return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (HasControl() && bLaunching)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (MoveComp.ForwardHit.bBlockingHit)
		{
			if (Hose == nullptr)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else if (Hose.bDisableLaunchOnImpact)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

        if (MoveComp.IsGrounded())
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Player.IsAnyCapabilityActive(UGoingThroughVacuumCapability::StaticClass()))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Player.TriggerMovementTransition(this);

		Hose = Cast<AVacuumHoseActor>(GetAttributeObject(n"Hose"));
		Player.SetAnimFloatParam(n"StopSpinningTime", Hose.StopSpinningTime);
		Player.SetAnimFloatParam(n"ForwardRotationSpeed", Hose.ForwardRotationSpeed);
		Player.SetAnimFloatParam(n"SideRotationSpeed", Hose.SideRotationSpeed);
		Player.SetAnimBoolParam(n"SkipStart", Hose.bSkipStart);

		MountLocation = GetAttributeNumber(n"MountLocation") == 0 ? EVacuumMountLocation::Front : EVacuumMountLocation::Back;

        Player.SetCapabilityActionState(n"LaunchedFromVacuum", EHazeActionState::Inactive);

		Player.ClearPointOfInterestByInstigator(Hose);

		Player.PlayForceFeedback(LaunchForceFeedback, false, false, n"Launch");

		LaunchProperties.LaunchDirection = MountLocation == EVacuumMountLocation::Front ? Hose.FrontAttachmentPoint.ForwardVector : Hose.BackAttachmentPoint.ForwardVector;
		LaunchProperties.LaunchEndLocation = MountLocation == EVacuumMountLocation::Front ? Hose.FrontLaunchLocation.WorldLocation : Hose.BackLaunchLocation.WorldLocation;
		LaunchProperties.LaunchStartLocation = Player.ActorLocation;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(n"Death", this);

		if (HasControl())
		{
			bLaunching = true;
			MoveToLaunchLocationTimeLike.PlayFromStart();
		}

		UMovementSettings::SetVerticalForceAirPushOffThreshold(Owner, 0.f, Instigator = this);
	
		Player == Game::GetCody() ? Player.AddLocomotionFeature(CodyZeroGFeature) : Player.AddLocomotionFeature(MayZeroGFeature);

		Hose.OnLaunchedFromHose.Broadcast(Player, Hose, MountLocation);
		Hose.RemoveBulgingActor(Player);

		if (Hose.bPlayLaunchBarks)
			BarkHandle = System::SetTimer(this, n"PlayBark", 0.5f, true);
	}

	UFUNCTION()
	void PlayBark()
	{
		if (Player.IsMay())
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumLaunchedFromHoseEffortMay");
		else
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumLaunchedFromHoseEffortCody");
	}

	UFUNCTION()
	void UpdateLaunchLocation(float Value)
	{
		FVector NewLocation = FMath::Lerp(LaunchProperties.LaunchStartLocation, LaunchProperties.LaunchEndLocation, Value);

		Player.SetActorLocation(NewLocation);

		CrumbComp.LeaveMovementCrumb();
	}

	UFUNCTION()
	void FinishLaunchLocation()
	{
		FinalizePlayerLaunch();
	}

	void FinalizePlayerLaunch()
	{
		FVector FinalLaunchForce = LaunchProperties.LaunchDirection * Hose.LaunchForce;

		if (FinalLaunchForce.Z < 150.f)
			FinalLaunchForce.Z += 1000.f;

		Player.AddImpulse(FinalLaunchForce);

		bLaunching = false;

		FHazeCrumbDelegate FinalizeLaunchDelegate;
		FinalizeLaunchDelegate.BindUFunction(this, n"Crumb_FinalizeLaunch");
		FHazeDelegateCrumbParams Params;
		CrumbComp.LeaveAndTriggerDelegateCrumb(FinalizeLaunchDelegate, Params);
	}

	UFUNCTION()
	void Crumb_FinalizeLaunch(const FHazeDelegateCrumbData& CrumbData)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		Owner.ClearSettingsByInstigator(this);

		Player == Game::GetCody() ? Player.RemoveLocomotionFeature(CodyZeroGFeature) : Player.RemoveLocomotionFeature(MayZeroGFeature);

		System::ClearAndInvalidateTimerHandle(BarkHandle);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"ZeroGravity");

		if (!MoveComp.CanCalculateMovement())
			return;

		if (HasControl() && bLaunching)
		{
			FHazeRequestLocomotionData LocoData;
			LocoData.AnimationTag = n"ZeroGravity";
			Player.RequestLocomotion(LocoData);
			return;
		}

		if (HasControl())
		{
			const FVector SteeringVector = GetAttributeVector(AttributeVectorNames::MovementDirection);

			FVector NewBlendSpaceValues = FVector::ZeroVector;
			NewBlendSpaceValues.Y = FMath::Lerp(-100.f, 100.f, (SteeringVector.X + 1.f) * 0.5f);
			NewBlendSpaceValues.X = FMath::Lerp(-100.f, 100.f, (SteeringVector.Y + 1.f) * 0.5f);

			NewBlendSpaceValues = Owner.GetActorRotation().UnrotateVector(NewBlendSpaceValues);
			CurrentBlendSpaceValues = FMath::VInterpConstantTo(CurrentBlendSpaceValues, NewBlendSpaceValues, DeltaTime, 300.f);

			Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceX, CurrentBlendSpaceValues.X);
			Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceY, CurrentBlendSpaceValues.Y);

			FVector LaunchDir = LaunchProperties.LaunchDirection;
			LaunchDir = Math::ConstrainVectorToPlane(LaunchDir, FVector::UpVector);
			LaunchDir.Normalize();
			
			FVector MoveDir = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FVector NewMoveDir = Math::ConstrainVectorToDirection(MoveDir, Player.ActorRightVector);
			
			FVector DeltaMove = LaunchDir * Hose.LaunchMoveSpeed;
			DeltaMove += NewMoveDir * 500.f;
			DeltaMove *= DeltaTime;
			
			FinalMovement.ApplyDelta(DeltaMove);
			FinalMovement.ApplyAndConsumeImpulses();
			FinalMovement.ApplyActorVerticalVelocity();
			FinalMovement.ApplyGravityAcceleration();
			FinalMovement.FlagToMoveWithDownImpact();
			FinalMovement.OverrideStepUpHeight(20.f);
			FinalMovement.OverrideStepDownHeight(0.f);
			
			MoveCharacter(FinalMovement, n"ZeroGravity");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FinalMovement.ApplyConsumedCrumbData(ConsumedParams);
			MoveCharacter(FinalMovement, n"ZeroGravity");
		}
	}
}

struct FVacuumLaunchProperties
{
	UPROPERTY()
	FVector LaunchStartLocation;

	UPROPERTY()
	FVector LaunchEndLocation;

	UPROPERTY()
	FVector LaunchDirection;
}
