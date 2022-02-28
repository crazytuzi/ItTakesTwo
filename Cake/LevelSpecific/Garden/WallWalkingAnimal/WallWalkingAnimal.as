import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenSpider;
import Vino.Movement.MovementSettings;
import Peanuts.Outlines.Outlines;
import Peanuts.Movement.DefaultDepenetrationSolver;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalLerpedCameraSettingsComponent;
import Cake.Environment.GPUSimulations.PurpleGuckCleanableByWater;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalLaunchPreviewActor;

import void AddWallWalkingAnimal(AWallWalkingAnimal, AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent";
import void AddWallWalkingAnimalToSolver(AWallWalkingAnimal, UHazeCollisionSolver) from "Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalCollisionSolver";

/* 
 * MOVEMENT COMPONENT
*/
class UWallWalkingAnimalMovementComponent : UHazeMovementComponent
{
	AWallWalkingAnimal AnimalOwner;
	float MoveSpeedMultiplier = 1.f;
	bool bCanUpdateMovement = false;

	private float WalkableSlopeAngleMultiplier = 1.f;

	FHitResult LastValidPostMoveGround;
	bool bHasAValidPostMoveLocation;
	
	UFUNCTION(BlueprintOverride)
    void BeginPlay() override
    {
		// Dont call super, we do our own stuff here.

		AnimalOwner = Cast<AWallWalkingAnimal>(Owner);
		if (DefaultMovementSettings != nullptr)
		{
			HazeOwner.ApplyDefaultSettings(DefaultMovementSettings);
		}
		
		ActiveSettings = UMovementSettings::GetSettings(HazeOwner);
		JumpSettings = UCharacterJumpSettings::GetSettings(HazeOwner);
		DefaultMovementSpeed = ActiveSettings.MoveSpeed;
        UseCollisionSolver(n"WallWalkingAnimalCollisionSolver", n"DefaultCharacterRemoteCollisionSolver");
		UseMoveWithCollisionSolver(n"DefaultCharacterMoveWithCollisionSolver", n"DefaultCharacterRemoteCollisionSolver");
	}

	UFUNCTION(BlueprintOverride)
    void OnCollisionSolverCreate(UHazeCollisionSolver CreatedSolver) override
    {
		AddWallWalkingAnimalToSolver(AnimalOwner, CreatedSolver);
		Super::OnCollisionSolverCreate(CreatedSolver);
    }

	UFUNCTION(BlueprintOverride)
	void PreMove()
	{
		AnimalOwner.WantedTransitionType = EWallWalkingAnimalTransitionType::None;
		WalkableSlopeAngleMultiplier = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void PostMove()
	{	
		if(bCanUpdateMovement && !AnimalOwner.bHasBeenResetted)
		{
			bool bStandingOnPurpleGuck = false;
			if(GIsTagedWithGravBootsWalkable(Impacts.DownImpact))
			{
				auto CleanableSurface = Cast<ACleanableSurface>(Impacts.DownImpact.Actor);
				if(CleanableSurface != nullptr)
				{
					if(!CleanableSurface.CanStandOn(Impacts.DownImpact.ImpactPoint))
					{
						bStandingOnPurpleGuck = true;
					}
				}
			}	

			if(bStandingOnPurpleGuck)
			{
				AnimalOwner.StandingOnPrupleGuckTime += AnimalOwner.GetActorDeltaSeconds();
			}
			else
			{
				AnimalOwner.StandingOnPrupleGuckTime = 0;
			}

			if(AnimalOwner.IsTransitioning())
			{
				bHasAValidPostMoveLocation = false;
			}
			else if(IsGrounded())
			{
				if(AnimalOwner.IsAnimalHitSurfaceStandable(Impacts.DownImpact))
				{
					bHasAValidPostMoveLocation = true;
					LastValidPostMoveGround = Impacts.DownImpact;
				}
			}		
		}

		AnimalOwner.bWasTransitioning = AnimalOwner.IsTransitioning();
	}

	UFUNCTION(BlueprintOverride)
	float GetWalkableAngle() const
	{
		return ActiveSettings.WalkableSlopeAngle * WalkableSlopeAngleMultiplier;
	}

	UFUNCTION(BlueprintOverride)
	float GetMoveSpeed() const
	{
		return Super::GetMoveSpeed() * MoveSpeedMultiplier;
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_SetMovementSpeedMultiplier(const FHazeDelegateCrumbData& CrumbData)
	{
		MoveSpeedMultiplier = CrumbData.GetValue(n"MoveSpeed");
	}

	UFUNCTION(BlueprintOverride)
	float GetGravityMultiplier() const
	{
		return -ActiveSettings.GravityMultiplier;
	}

}

/* 
 * ANIMAL
*/
UCLASS(Abstract)
class AWallWalkingAnimal : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
    UInteractionComponent InteractionPoint;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
    USceneComponent TransitionPoint;

	UPROPERTY(DefaultComponent)
	UWallWalkingAnimalMovementComponent MoveComp;
	default MoveComp.bDepenetrateOutOfOtherMovementComponents = false;

	UPROPERTY(DefaultComponent)
	UWallWalkingAnimalLerpedCameraSettingsComponent LerpCameraComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent SpiderHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent LaunchToCeilingCamera;

	UPROPERTY()
	UNiagaraSystem WebBeamType;

	UPROPERTY()
	UNiagaraSystem WebBeamImpactType;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LandForceFeedback;

	UPROPERTY()
	TSubclassOf<AWallWalkingAnimalLaunchPreviewActor> PreviewActorClass;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DefaultDeathEffect;

	default CapsuleComponent.CapsuleRadius = 48.f;
	default CapsuleComponent.CapsuleHalfHeight = 88.f;
	
	default ReplicateAsMovingActor();

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LandRumble;

	UPROPERTY()
	UWallWalkingAnimalMovementSettings MovementSettings;

	UPROPERTY()
	FCollisionProfileName MountedCollisionProfile;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet RequiredSheet;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bMounted = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bJumping = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPreparingToLaunch = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bLaunching = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bTransitioning = false;
	bool bWasTransitioning = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bResettingWorldUp = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bValidSurface = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float TuringDirection = 0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFallingOffWall = false;

	private AHazePlayerCharacter RidingPlayer;
	FVector SpiderWantedMovementDirection = FVector::ZeroVector;
	bool bRidingPlayerIsAiming = false;
	bool bFaceCameraDirection = true;
	
	private EWallWalkingAnimalTransitionType CurrentTransitionType = EWallWalkingAnimalTransitionType::None;
	EWallWalkingAnimalTransitionType WantedTransitionType = EWallWalkingAnimalTransitionType::None;

	FHitResult CurrentTransitionTarget;
	FQuat TransitionTargetRotation = FQuat::Identity;
	float LaunchLeftAlpha = 0;
	float CurrentInputBlockTime = 0;
	float LaunchCooldown = 0.f;

	FWallWalkingAnimalGroundHitResult GroundTraces;

	const float MaxStandOnGuckTime = 1.f;
	float StandingOnPrupleGuckTime = 0;
	FName OriginalCollision;
	float LockedForwardTimeStamp = 0;
	bool bHasBeenResetted = false;

	bool bHasAimDirection = false;
	FVector PlayerDirection;

	private FHitResult CeilingHitResult;
	private bool bCeilingHitResultIsValid = false;
	

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MoveComp.Setup(CapsuleComponent);
		DisableMovementComponent();
		OriginalCollision = CapsuleComponent.GetCollisionProfileName();

		// Interaction 
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		InteractionPoint.SetWorldLocation(Mesh.GetSocketLocation(n"Totem"));

		// Applies the spidersettings onto the movement settings
		ApplySettings();

	#if EDITOR
		MovementSettings.OnAssetChanged.AddUFunction(this, n"ApplySettings");
	#endif

		// Capability
		AddCapability(n"WallWalkingAnimalFaceInputCapability");
		AddCapability(n"WallWalkingAnimalMovementCapability");
		AddCapability(n"WallWalkingAnimalAlignToSurfaceCapability");
		AddCapability(n"WallWalkingAnimalLaunchCapability");
		//AddCapability(n"WallWalkingAnimalHandleCutsceneEndCapability");
		//AddCapability(n"WallWalkingAnimalSurfaceTransitionCapability");
		//AddCapability(n"WallWalkingAnimalFallOffWallCapability");
		//AddCapability(n"WallWalkingAnimalStandingOnPurpleGuckCapability"); // In BP

		// Debug
		AddDebugCapability(n"WallWalkingAnimalDebugCapability");
		
		OnPostSequencerControl.AddUFunction(this, n"HandlePostSequenceControl");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		AnimalDismounted();
	}

	UFUNCTION()
	void ApplySettings()
	{
		UMovementSettings ComposeOnto = UMovementSettings::TakeTransientSettings(this, this, EHazeSettingsPriority::Defaults);
		MovementSettings.ApplyToMovementSettings(ComposeOnto);
		ReturnTransientSettings(ComposeOnto);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// DEBUG
	#if EDITOR

		if(bHazeEditorOnlyDebugBool)
		{
			auto CurrentPlayer = GetPlayer();
			if(CurrentPlayer != nullptr)
				System::DrawDebugCoordinateSystem(GetActorCenterLocation() + FVector(200.f, 200.f, 200.f), CurrentPlayer.GetControlRotation(), 200.f, 0.f, 10.f);
		}

	#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActorTeleported()
	{
		BlockCapabilities(n"SurfaceAlign", this);
		BlockCapabilities(CapabilityTags::Movement, this);
		BlockCapabilities(CapabilityTags::LevelSpecific, this);

		ChangeActorWorldUp(FVector::UpVector);
		CurrentTransitionTarget = FHitResult();
		TransitionTargetRotation = FQuat::Identity;
		bLaunching = false;
		LaunchLeftAlpha = 0;
		CurrentInputBlockTime = 0;
		StandingOnPrupleGuckTime = 0;

		if(bFallingOffWall)
			SetCapabilityActionState(n"AudioRespawn", EHazeActionState::ActiveForOneFrame);

		bFallingOffWall = false;

		if(RidingPlayer != nullptr)
		{
			RidingPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
			RidingPlayer.BlockCapabilities(ActionNames::WeaponAim, this);
			RidingPlayer.ChangeActorWorldUp(FVector::UpVector);

			RidingPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
			RidingPlayer.UnblockCapabilities(ActionNames::WeaponAim, this);

		}

		UnblockCapabilities(n"SurfaceAlign", this);
		UnblockCapabilities(CapabilityTags::Movement, this);
		UnblockCapabilities(CapabilityTags::LevelSpecific, this);
		MoveComp.StopMovement();
		bHasBeenResetted = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void HandlePostSequenceControl(FHazePostSequencerControlParams Params)
	{
		Mesh.ResetAllAnimation();
		if(Player != nullptr)
		{
			Player.ConsumeButtonInputsRelatedTo(ActionNames::WeaponAim);
			Player.ConsumeButtonInputsRelatedTo(ActionNames::WeaponFire);
		}
	}

	bool IsTransitioning()const
	{
		return bTransitioning || CurrentTransitionType != EWallWalkingAnimalTransitionType::None;
	}

	bool WasTransitioning() const
	{
		return bWasTransitioning;
	}

	bool IsAnimalHitSurfaceStandable(FHitResult SurfaceHit, bool bOnlyValidIfWalkableOnly = false) const
	{
		if(!SurfaceHit.bBlockingHit)
			return false;

		if(SurfaceHit.bStartPenetrating)
			return false;

		if(GIsTagedWithGravBootsWalkable(SurfaceHit))
		{
			if(bOnlyValidIfWalkableOnly)
				return false;

			return true;
		}	

		if(!SurfaceHit.Component.HasTag(ComponentTags::Walkable))	
			return false;

		if(!SurfaceHit.Normal.IsUnit())
			return false;

		return true;
	}

	bool IsAnimalHitSurfaceWalkable(FHitResult SurfaceHit, bool bOnlyValidIfWalkableOnly = false) const
	{
		if(!IsAnimalHitSurfaceStandable(SurfaceHit, bOnlyValidIfWalkableOnly))
			return false;

		FVector WorldUp = FVector::UpVector;
		if(GIsTagedWithGravBootsWalkable(SurfaceHit))
			WorldUp = GetMovementWorldUp();

		float MaxSlopeAngle = FMath::Cos(FMath::DegreesToRadians(MoveComp.GetWalkableAngle()));
		float SurfaceHitAngle = WorldUp.DotProduct(SurfaceHit.ImpactNormal);

		if(SurfaceHitAngle <= MaxSlopeAngle)
			return false;

		return true;;
	}

	UFUNCTION()
	void SetMovementSpeedMultiplier(float Value)
	{
		if(HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddValue(n"MoveSpeed", Value);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(MoveComp, n"Crumb_SetMovementSpeedMultiplier"), CrumbParams);
		}
    }

	void SetMovementSpeedMultiplierLocal(float Value)
	{
		MoveComp.MoveSpeedMultiplier = Value;
	}

    UFUNCTION(NotBlueprintCallable)
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		MountAnimal(Player);
    }

	UFUNCTION()
	void MountAnimal(AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return;

		devEnsure(HasControl() == Player.HasControl(), "You: " + Player.GetName() + " can't mount an animal: " + GetName() + ", if you dont have the same controlside");

		RidingPlayer = Player;
		InteractionPoint.Disable(n"Mounted");
		Player.AddCapabilitySheet(RequiredSheet, EHazeCapabilitySheetPriority::Normal, this);
		SetControlSide(Player);
		AddWallWalkingAnimal(this, Player);
		Mesh.AddMeshToPlayerOutline(Player, this);	
		bMounted = true;
		SetCapabilityActionState(n"AudioSpiderMount", EHazeActionState::ActiveForOneFrame);

		CapsuleComponent.SetCollisionProfileName(Trace::GetCollisionProfileName(MountedCollisionProfile));
		
		Player.TriggerMovementTransition(this);
		Player.DisableMovementComponent(this);
		Player.BlockMovementSyncronization(this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(GardenSickle::SickleAttack, this);
		
		Player.AttachToActor(this);
		Player.Mesh.AttachToComponent(Mesh, n"Totem");
		EnableMovementComponent();
	}

	void AnimalDismounted()
	{
		if(RidingPlayer == nullptr)
			return;

		RidingPlayer.UnblockMovementSyncronization(this);
		RidingPlayer.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		RidingPlayer.UnblockCapabilities(CapabilityTags::Collision, this);
		RidingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		RidingPlayer.UnblockCapabilities(GardenSickle::SickleAttack, this);

		FTransform MeshTransform = RidingPlayer.Mesh.GetWorldTransform();
		RidingPlayer.Mesh.AttachTo(RidingPlayer.MeshOffsetComponent, AttachType = EAttachLocation::SnapToTarget);

/* 		RidingPlayer.MeshOffsetComponent.SetWorldLocationAndRotation(MeshTransform.GetLocation(), MeshTransform.GetRotation());
		RidingPlayer.MeshOffsetComponent.FreezeAndResetWithTime(0.2f); */
		
		RidingPlayer.DetachRootComponentFromParent(true);
		RidingPlayer.EnableMovementComponent(this);
		RidingPlayer.ChangeActorWorldUp(FVector::UpVector);
		RidingPlayer.RemoveAllCapabilitySheetsByInstigator(this);

		InteractionPoint.Enable(n"Mounted");
		bMounted = false;
		SetCapabilityActionState(n"AudioSpiderDismount", EHazeActionState::ActiveForOneFrame);

		Mesh.RemoveMeshFromPlayerOutline(this);
		FinishTransition();
		
		SpiderWantedMovementDirection = FVector::ZeroVector;
		TriggerMovementTransition(this);

		CapsuleComponent.SetCollisionProfileName(OriginalCollision);
		TuringDirection = 0;
		ChangeActorWorldUp(FVector::UpVector);
		DisableMovementComponent();
		RidingPlayer = nullptr;
	}

	void LaunchToCeiling(FHitResult Target)
	{
		bLaunching = true;
		SetCapabilityActionState(n"AudioSpiderJump", EHazeActionState::ActiveForOneFrame);
		CurrentTransitionTarget = Target;
		CurrentTransitionType = EWallWalkingAnimalTransitionType::LaunchStart;
		if(RidingPlayer != nullptr)
		{
			RidingPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		}
	}

	void TriggerLaunchToCeiling()
	{
		CurrentTransitionType = EWallWalkingAnimalTransitionType::Launch;
	}

	void TriggerLaunchToCeilingEnding()
	{
		CurrentTransitionType = EWallWalkingAnimalTransitionType::LaunchEnd;
		SetCapabilityActionState(n"AudioSpiderLand", EHazeActionState::ActiveForOneFrame);
	}

	// void StepUpOnWall(FHitResult Target)
	// {
	// 	if(CurrentTransitionType != EWallWalkingAnimalTransitionType::None)
	// 		FinishTransition();

	// 	CurrentTransitionTarget = Target;
	// 	CurrentTransitionType = EWallWalkingAnimalTransitionType::StepUpOnWall;
	// 	if(RidingPlayer != nullptr)
	// 	{
	// 		RidingPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
	// 	}


	// }

	// void StepOverLedge(FHitResult Target)
	// {
	// 	if(CurrentTransitionType != EWallWalkingAnimalTransitionType::None)
	// 		FinishTransition();

	// 	CurrentTransitionTarget = Target;
	// 	CurrentTransitionType = EWallWalkingAnimalTransitionType::StepOverLedge;
	// 	if(RidingPlayer != nullptr)
	// 	{
	// 		RidingPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
	// 	}
	// }

	void FinishTransition()
	{
		if(CurrentTransitionType != EWallWalkingAnimalTransitionType::None)
		{
			if(CurrentTransitionTarget.bBlockingHit)
			{
				ChangeActorWorldUp(CurrentTransitionTarget.ImpactNormal);
				LockedForwardTimeStamp = Time::GetGameTimeSeconds() + 0.15f;
			}
			
			if(RidingPlayer != nullptr)
				RidingPlayer.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		}

		CurrentTransitionType = EWallWalkingAnimalTransitionType::None;
		WantedTransitionType = EWallWalkingAnimalTransitionType::None;
		CurrentTransitionTarget = FHitResult();
		bLaunching = false;	
	}

	EWallWalkingAnimalTransitionType GetActiveTransitionType() const property
	{
		return CurrentTransitionType;
	}

	bool IsCarryingPlayer()const
	{
		return RidingPlayer != nullptr;
	}

	FVector GetWantedCameraWorldUp() const
	{
		if(IsTransitioning())
			return MoveComp.GetWorldUp();

		const FHitResult& Ground = MoveComp.Impacts.DownImpact;
		if(!GIsTagedWithGravBootsWalkable(Ground))
			return FVector::UpVector;
			
		return Mesh.GetWorldRotation().UpVector;
	}

	FVector GetWantedMeshRelativeLocation() const
	{
		if(IsTransitioning())
			return FVector::ZeroVector;

		FVector TraceWorldLocation;
		if(!GroundTraces.GetImpactLocationMiddle(TraceWorldLocation))
			return FVector::ZeroVector;

		const float MaxOffsetAmount = 1.f; // Bigger is down into ground, less is up in air
		return (TraceWorldLocation - GetActorLocation()) * MaxOffsetAmount;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPlayer() const property
	{
		return RidingPlayer;
	}

	void SendMovementAnimationRequest(const FHazeFrameMovement& MoveData, FVector InputVector, FName AnimationRequestTag, FName SubAnimationRequestTag)
    {
        FHazeRequestLocomotionData AnimationRequest;
 
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = MoveData.MovementDelta;
		AnimationRequest.LocomotionAdjustment.WorldRotation = MoveData.Rotation;
 		AnimationRequest.WantedVelocity = MoveData.Velocity;
		AnimationRequest.WantedWorldTargetDirection = InputVector;
        AnimationRequest.WantedWorldFacingRotation = MoveComp.GetTargetFacingRotation();
		AnimationRequest.MoveSpeed = MoveComp.MoveSpeed;
		
		if(!MoveComp.GetAnimationRequest(AnimationRequest.AnimationTag))
		{
			AnimationRequest.AnimationTag = AnimationRequestTag;
		}

        if (!MoveComp.GetSubAnimationRequest(AnimationRequest.SubAnimationTag))
        {
            AnimationRequest.SubAnimationTag = SubAnimationRequestTag;
        }

        RequestLocomotion(AnimationRequest);
    }

	FVector GetGroundUp() const
	{
		if(IsAnimalHitSurfaceStandable(MoveComp.DownHit))
			return MoveComp.DownHit.Normal;

		return MoveComp.WorldUp;
	}

	void UpdateCeilingHitResult(FHitResult NewRestult)
	{
		CeilingHitResult = NewRestult;
		bCeilingHitResultIsValid = IsAnimalHitSurfaceStandable(CeilingHitResult);
		if(bCeilingHitResultIsValid && CeilingHitResult.ImpactNormal.DotProduct(MoveComp.WorldUp) > -0.75f)
		{
			bCeilingHitResultIsValid = false;
		}
	}

	void ClearCeilingHitResult()
	{
		bCeilingHitResultIsValid = false;
	}

	bool GetCeilingHitResult(FHitResult& Out) const
	{
		Out = CeilingHitResult;
		return bCeilingHitResultIsValid;
	}
}

enum EWallWalkingAnimalTransitionType
{
	None,
	StepUpOnWall,
	StepOverLedge,
	LaunchStart,
	Launch,
	LaunchEnd,
}

// bool GIsValidSlopeAngle(FHitResult SurfaceHit, FVector UpToCompareAgainstNormal, float WalkableSlopeAngle)
// {
// 	float MaxSlopeAngle = FMath::Cos(FMath::DegreesToRadians(WalkableSlopeAngle));
// 	float SurfaceHitAngle = UpToCompareAgainstNormal.DotProduct(SurfaceHit.ImpactNormal);
// 	return (SurfaceHitAngle > MaxSlopeAngle);
// }

bool GIsTagedWithGravBootsWalkable(FHitResult SurfaceHit)
{
	if(!SurfaceHit.bBlockingHit)
		return false;

	if(SurfaceHit.Component == nullptr)
		return false;
	
	if(SurfaceHit.Component.HasTag(ComponentTags::GravBootsWalkable))
		return true;

	auto LandScape = Cast<ALandscape>(SurfaceHit.Component.Owner);
	if(LandScape == nullptr)
		return false;
	
	if(LandScape.Tags.Contains(ComponentTags::GravBootsWalkable))
		return true;

	return false;
}

class UWallWalkingAnimalCameraSettings : UHazeCameraSpringArmSettingsDataAsset
{
	UPROPERTY(Category = "CameraSpringArm")
	float CameraDistanceAtMaxAiming = 2200.f;

	UPROPERTY(Category = "CameraSpringArm")
	float SurfaceTransitionAlignmentTime = 0.6f;

	UPROPERTY(Category = "CameraSpringArm")
	ELerpedCameraType SurfaceTransitionLerpType = ELerpedCameraType::EaseOut;
}

class UWallWalkingAnimalMovementSettings : UDataAsset
{
	UPROPERTY()
	float MoveSpeed = 2600;

	UPROPERTY()
	float GravityMultiplier = 12;

	UPROPERTY()
	float WalkableSlopeAngle = 55;

	UPROPERTY()
	float StepUpAmount = 30;

	UPROPERTY()
	float GroundRotationSpeed = 3;

	UPROPERTY()
	float AirRotationSpeed = 0;

	UPROPERTY()
	FVector2D FutureTraceLenght = FVector2D(600.f, 1000.f);

	UPROPERTY()
	float MoveBackwardsSpeedMultiplier = 0.25;

	UPROPERTY()
	float PreparingToLaunchMoveSpeedMultiplier = 0.2f;

	UPROPERTY()
	float PlayerAimingSpeedMultiplier = 0.5f;

	UPROPERTY()
	FVector CeilingTraceAmount = FVector(0.f, 0.f, 2500.f);

	UPROPERTY()
	float CeilingMaxTrace = 1600;

	UPROPERTY()
	float InputBlockTimeDuringTransition = 0.1f;

	void ApplyToMovementSettings(UMovementSettings SettingsToApplyTo)
	{
		SettingsToApplyTo.MoveSpeed = MoveSpeed;
		SettingsToApplyTo.bOverride_MoveSpeed = true;

		SettingsToApplyTo.GravityMultiplier = GravityMultiplier;
		SettingsToApplyTo.bOverride_GravityMultiplier = true;

		SettingsToApplyTo.WalkableSlopeAngle = WalkableSlopeAngle;
		SettingsToApplyTo.bOverride_WalkableSlopeAngle = true;

		SettingsToApplyTo.StepUpAmount = StepUpAmount;
		SettingsToApplyTo.bOverride_StepUpAmount = true;

		SettingsToApplyTo.GroundRotationSpeed = GroundRotationSpeed;
		SettingsToApplyTo.bOverride_GroundRotationSpeed = true;

		SettingsToApplyTo.AirRotationSpeed = AirRotationSpeed;
		SettingsToApplyTo.bOverride_AirRotationSpeed = true;
	}
}



struct FWallWalkingAnimalGroundHitResultData
{
	FVector RelativeLocation;
	FVector CurrentNormal;
	bool bIsValid = false;

	FVector CurrentWorldPosition;
	bool bLocationIsValue = false;
}

struct FWallWalkingAnimalGroundHitResult
{
	void AddTrace(FVector RelativeLocation)
	{
		FWallWalkingAnimalGroundHitResultData NewEntry;
		NewEntry.RelativeLocation = RelativeLocation;
		Traces.Add(NewEntry);
	}

	void UpdateTraces(AWallWalkingAnimal Animal, float TraceLength, float DebugTime = -1)
	{
		auto MoveComp = Animal.MoveComp;
		const FVector UpVector = Animal.GetGroundUp();
	
		const FVector OwnerLocation = MoveComp.Owner.GetActorLocation();

		const FRotator TraceRotation = Math::MakeRotFromYZ(MoveComp.Owner.GetActorRightVector(), UpVector);
		const FTransform OwnerTransform(TraceRotation, OwnerLocation);
		for(FWallWalkingAnimalGroundHitResultData& Trace : Traces)
		{
			const FVector WorldLocation = OwnerTransform.TransformPositionNoScale(Trace.RelativeLocation);
			const FVector ZOffset = UpVector * Animal.GetCollisionSize().Y;

			FHazeHitResult GroundHit;
			const bool bImpact = MoveComp.LineTrace(WorldLocation + ZOffset, WorldLocation - ZOffset - (UpVector * TraceLength), GroundHit, DebugTime);
			if(Animal.IsAnimalHitSurfaceStandable(GroundHit.FHitResult))
			{
				Trace.bIsValid = true;
				Trace.CurrentNormal = GroundHit.Normal;

				Trace.bLocationIsValue = true;
				Trace.CurrentWorldPosition = GroundHit.ImpactPoint;
			}
			else
			{
				
			// #if EDITOR
			// 	System::DrawDebugArrow(GroundHit.FHitResult.TraceStart, GroundHit.FHitResult.TraceEnd, 25, FLinearColor::Red, 0.f, 5.f);
			// #endif

				Trace.bIsValid = false;
				Trace.bLocationIsValue = false;
			}
		}
		
	}

	void SetTracesNormal(FVector Normal)
	{
		for(auto& Trace : Traces)
		{
			Trace.bIsValid = true;
			Trace.CurrentNormal = Normal;
			Trace.bLocationIsValue = false;
		}
	}

	FVector GetImpactNormal()const
	{
		FVector FinalResult = FVector::ZeroVector;
		int ValidImpacts = 0;
		for(const FWallWalkingAnimalGroundHitResultData& Trace : Traces)
		{
			if(!Trace.bIsValid)
				continue;

			ValidImpacts++;
			FinalResult += Trace.CurrentNormal;
		}

		if(ValidImpacts > 0)
			FinalResult = FinalResult.GetSafeNormal();
		return FinalResult;
	}

	bool GetImpactLocationMiddle(FVector& Out) const 
	{
		FVector FinalResult = FVector::ZeroVector;
		int ValidImpacts = 0;
		for(const FWallWalkingAnimalGroundHitResultData& Trace : Traces)
		{
			if(!Trace.bIsValid)
				continue;

			if(!Trace.bLocationIsValue)
				continue;

			ValidImpacts++;
			FinalResult += Trace.CurrentWorldPosition;
		}

		if(ValidImpacts <= 0)
			return false;

		Out = FinalResult / ValidImpacts;
		return true;
	}

	private TArray<FWallWalkingAnimalGroundHitResultData> Traces;
}
