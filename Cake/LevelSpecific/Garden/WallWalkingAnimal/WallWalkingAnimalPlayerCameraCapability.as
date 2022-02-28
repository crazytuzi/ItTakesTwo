import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraControlCapability;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalLerpedCameraSettingsComponent;
import Cake.LevelSpecific.Garden.Vine.VineComponent;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalRiderSettings;


class UWallWalkingAnimalPlayerCameraCapability : UCameraControlCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CameraTags::CameraReplication);
	default CapabilityTags.Add(n"SpiderCamera");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::Input;
	//default TickGroupOrder = 150;

	EWallWalkingAnimalActiveCameraType ActiveCameraType = EWallWalkingAnimalActiveCameraType::Normal;

	AHazePlayerCharacter Player;
	UWallWalkingAnimalComponent AnimalComp;
	UWallWalkingAnimalLerpedCameraSettingsComponent CameraSettingsComp;
	UCameraSpringArmComponent SpringArm;
	UCameraUserComponent CameraUserComp;
	UHazeCrumbComponent AnimalCrumbComp;
	UVineComponent VineComp;
	
	FVector LastActorLocation = FVector::ZeroVector;
	FVector BestCameraDirection = FVector::ZeroVector;
	FHazeCameraSpringArmSettings LastCameraSettings;
	float LastPreviewTargetYawDir = 0;

	FHazeAcceleratedFloat WorldUpSlerpSpeed;
	UWallWalkingAnimalRiderSettings RiderSettings;
	bool bWasWallClimbing = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		AnimalComp = UWallWalkingAnimalComponent::Get(Player);
		SpringArm = UCameraSpringArmComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
		VineComp = UVineComponent::Get(Player);
		RiderSettings = UWallWalkingAnimalRiderSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AnimalComp.CurrentAnimal == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(AnimalComp.CurrentAnimal == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return Super::ShouldDeactivate();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		AnimalCrumbComp = UHazeCrumbComponent::Get(AnimalComp.CurrentAnimal);
		AnimalCrumbComp.IncludeCustomCameraInActorReplication(CameraUserComp, this);

		User.GetCameraSpringArmSettings(LastCameraSettings);
		Player.ApplyCameraSettings(AnimalComp.CamSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Low);
		User.SetYawAxis(AnimalComp.CurrentAnimal.MoveComp.WorldUp);

		User.OnYawAxisChanged.BindUFunction(this, n"OnYawAxisChanged");

		SetMutuallyExclusive(CameraTags::Control, true);
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
		SetMutuallyExclusive(CameraTags::CameraReplication, true);
		
		CameraSettingsComp = UWallWalkingAnimalLerpedCameraSettingsComponent::Get(AnimalComp.CurrentAnimal);
		SpringArm.OnGetSpringArmFinalWorldRotation.BindUFunction(this, n"GetFinalWorldRotation");	

		bWasWallClimbing = GIsTagedWithGravBootsWalkable(AnimalComp.CurrentAnimal.MoveComp.DownHit);
		WorldUpSlerpSpeed.SnapTo(bWasWallClimbing ? RiderSettings.WallCameraSlerpSpeed: RiderSettings.FloorCameraSlerpSpeed);			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AnimalCrumbComp.RemoveCustomCameraInActorReplication(this);
		AnimalCrumbComp = nullptr;

		ApplyNewCameraType(EWallWalkingAnimalActiveCameraType::Normal);
		ActiveCameraType = EWallWalkingAnimalActiveCameraType::Normal;

		if(AnimalComp.CurrentAnimal == nullptr)
			User.SetYawAxis(FVector::UpVector);

		Player.ClearCameraSettingsByInstigator(this);
		Player.DeactivateCameraByInstigator(this);

		SetMutuallyExclusive(CameraTags::Control, false);
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		SetMutuallyExclusive(CameraTags::CameraReplication, false);

		CameraSettingsComp.ClearAllLerpSettings();
		CameraSettingsComp = nullptr;

		if(SpringArm.OnGetSpringArmFinalWorldRotation.GetUObject() == this)
			SpringArm.OnGetSpringArmFinalWorldRotation.Clear();

		if(User.OnYawAxisChanged.GetUObject() == this)
			User.OnYawAxisChanged.Clear();

		Super::OnDeactivated(DeactivationParams);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		const EWallWalkingAnimalActiveCameraType NewCameraType = GetWantedCameraType();
		if(NewCameraType != ActiveCameraType)
		{
			ApplyNewCameraType(NewCameraType);
		}

		if(NewCameraType == EWallWalkingAnimalActiveCameraType::LaunchPreview)
		{
			// This will update the distance to the ceiling while we are moving
			UpdatePreLaunchCameraOffset(DeltaTime);
		}

		if(HasControl())
		{
			//bool bIsLerpingCamera = false;
			FVector WantedWorldUp = AnimalComp.CurrentAnimal.GetWantedCameraWorldUp();
			if(CameraSettingsComp.GetCurrentLerpedCameraUp(User, WantedWorldUp))
			{
				// Custom world up, jumps etc
				bWasWallClimbing = true;
				WorldUpSlerpSpeed.SnapTo(RiderSettings.WallCameraSlerpSpeed);
			}
			else
			{
				// Interpolate world up. Interpolation speed is slow when there has been little change
				// in wanted world up but gets faster when we move into more curved terrain.
				bool bIsWallClimbing = GIsTagedWithGravBootsWalkable(AnimalComp.CurrentAnimal.MoveComp.DownHit);
				if (bIsWallClimbing != bWasWallClimbing)
					WorldUpSlerpSpeed.SnapTo(RiderSettings.TransitionCameraSlerpSpeed);
				else 
					WorldUpSlerpSpeed.AccelerateTo(bIsWallClimbing ? RiderSettings.WallCameraSlerpSpeed : RiderSettings.FloorCameraSlerpSpeed, 2.f, DeltaTime);
				bWasWallClimbing = bIsWallClimbing;

				WantedWorldUp = Math::SlerpVectorTowards(Player.GetMovementWorldUp(), WantedWorldUp, DeltaTime * WorldUpSlerpSpeed.Value);
			}

			Player.ChangeActorWorldUp(WantedWorldUp.GetSafeNormal());	
		}

// #if EDITOR
	
// 		if(AnimalComp.CurrentAnimal.bHazeEditorOnlyDebugBool)
// 		{
// 			const FVector DebugLoc = AnimalComp.CurrentAnimal.GetActorCenterLocation();
// 			//System::DrawDebugArrow(DebugLoc, DebugLoc + (CurrentWorldUp.Value * 300.f), LineColor = FLinearColor::Yellow, Thickness = 6);
// 			System::DrawDebugArrow(DebugLoc, DebugLoc + (User.GetBaseRotation().GetUpVector() * 400.f), LineColor = FLinearColor::DPink, Thickness = 5);
// 		}
// #endif

		const ELerpedCameraActiveType LerpType = CameraSettingsComp.HasActiveLerp();	
		if(LerpType == ELerpedCameraActiveType::TargetReached)
		{
			CameraSettingsComp.ConsumeActiveLerpSettings();
		}	

		ActiveCameraType = NewCameraType;
		Super::TickActive(DeltaTime);

		if(HasControl())
		{
			AnimalCrumbComp.LeaveCameraCrumb();
		}
		else
		{
			FHazeCameraReplicationFinalized ReplicationParams;
			AnimalCrumbComp.ConsumeCrumbTrailCamera(DeltaTime, ReplicationParams);
			//Player.ChangeActorWorldUp(ReplicationParams.WorldUp);
			User.SetDesiredReplicatedRotation(ReplicationParams);
		}
		
		//System::DrawDebugArrow(Player.ActorLocation, Player.ActorLocation + (User.GetYawAxis() * 1500), 30, Thickness = 5.f);

		//PreviousSpringArmWorldRotation = SpringArm.PreviousWorldRotation;
	}

	UFUNCTION(NotBlueprintCallable)
	FRotator GetFinalWorldRotation(FRotator From, FRotator To, float DeltaSeconds, float Speed)
	{
		const ELerpedCameraActiveType LerpType = CameraSettingsComp.HasActiveLerp();	
		if(LerpType != ELerpedCameraActiveType::Inactive)
			return To;
		else
			return SpringArm.GetFinalWorldRotation(From, To, DeltaSeconds, Speed);		
	}

	UFUNCTION(NotBlueprintCallable)
	void OnYawAxisChanged(UCameraUserComponent Component, FQuat NewRotation)
	{
		const ELerpedCameraActiveType LerpType = CameraSettingsComp.HasActiveLerp();	
		if(LerpType != ELerpedCameraActiveType::Inactive)
			Component.ApplyYawAxisAndKeepCurrentDesiredRotationYawPitch(NewRotation);		
		else	
			Component.ApplyDesiredRotationFollowsYawAxis(NewRotation);
	}

	void ApplyNewCameraType(EWallWalkingAnimalActiveCameraType NewType)
	{
		User.GetCameraSpringArmSettings(LastCameraSettings);
		Player.ClearCameraSettingsByInstigator(this);
	
		// Jump to ceiling preview camera
		if(NewType == EWallWalkingAnimalActiveCameraType::LaunchPreview)
		{		
			BestCameraDirection = Player.GetControlRotation().GetForwardVector();
			LastPreviewTargetYawDir = 0;
			LastActorLocation = AnimalComp.CurrentAnimal.GetActorLocation();		
			Player.BlockCapabilities(CameraTags::FindOtherPlayer, this);
		}

		// Static launch to ceiling camera
		else if(NewType == EWallWalkingAnimalActiveCameraType::Launch)
		{
			// Drop camera at current location and activate it.
			AnimalComp.CurrentAnimal.LaunchToCeilingCamera.DetachFromParent();
			AnimalComp.CurrentAnimal.LaunchToCeilingCamera.SetWorldLocationAndRotation(Player.ViewLocation, Player.ViewRotation);
			Player.ActivateCamera(AnimalComp.CurrentAnimal.LaunchToCeilingCamera, CameraBlend::Normal(0.f), this, EHazeCameraPriority::Medium);	
		}

		// Wall transition camera
		else if(NewType == EWallWalkingAnimalActiveCameraType::Transition)
		{
			Player.ApplyCameraSettings(AnimalComp.CamSettings, FHazeCameraBlendSettings(0.f), this, EHazeCameraPriority::Low);

			if(AnimalComp.CurrentAnimal.ActiveTransitionType == EWallWalkingAnimalTransitionType::StepOverLedge 
			|| AnimalComp.CurrentAnimal.ActiveTransitionType == EWallWalkingAnimalTransitionType::StepUpOnWall)
			{
				FLerpedCameraAlignmentData CameraLerp;
				CameraLerp.Type = AnimalComp.CamSettings.SurfaceTransitionLerpType;
				CameraLerp.Time = AnimalComp.CamSettings.SurfaceTransitionAlignmentTime;
				CameraLerp.bIntrovertTranslation = AnimalComp.CurrentAnimal.ActiveTransitionType == EWallWalkingAnimalTransitionType::StepUpOnWall;
				CameraSettingsComp.SetLerpedAlignement(EWallWalkingAnimalActiveCameraType::Transition, CameraLerp, User, SpringArm, Player.GetMovementWorldUp());
			}
		}

		// Normal Camera
		else
		{
			float BlendTime = 0.5f;
			if(ActiveCameraType == EWallWalkingAnimalActiveCameraType::Launch)
				BlendTime = 1.0f;

			Player.ApplyCameraSettings(AnimalComp.CamSettings, FHazeCameraBlendSettings(BlendTime), this, EHazeCameraPriority::Low);
		}

		if (NewType != ActiveCameraType)
		{
			// Active camera type is the previous type which we now have changed away from
			if (ActiveCameraType == EWallWalkingAnimalActiveCameraType::Launch)
				Player.DeactivateCameraByInstigator(this, 1.f);
			if (ActiveCameraType == EWallWalkingAnimalActiveCameraType::LaunchPreview)
				Player.UnblockCapabilities(CameraTags::FindOtherPlayer, this);
		}
	}

	FRotator GetFinalizedDeltaRotation(FRotator InRotation)
	{			
		const EWallWalkingAnimalActiveCameraType CurrentActiveCameraType = CameraSettingsComp.GetActiveSettingsType(ActiveCameraType);

		if(CurrentActiveCameraType == EWallWalkingAnimalActiveCameraType::LaunchPreview)
		{
			FQuat WantedRotation = Math::MakeQuatFromXZ(BestCameraDirection, AnimalComp.CurrentAnimal.MoveComp.GetWorldUp());
			FRotator TargetLocal = User.WorldToLocalRotation(WantedRotation.Rotator());
			TargetLocal.Pitch = 10;

			FRotator CurLocal = User.WorldToLocalRotation(User.CurrentDesiredRotation);
			FRotator LockedDelta = (TargetLocal - CurLocal);

			const float DeltaTime = Owner.GetActorDeltaSeconds();
			LockedDelta.Pitch *= DeltaTime * 10;
			LockedDelta.Yaw *= DeltaTime * 3;

			// The camera overshoots, so we need to reset that
			if(FMath::Abs(LastPreviewTargetYawDir) < KINDA_SMALL_NUMBER && FMath::Abs(LockedDelta.Yaw) < KINDA_SMALL_NUMBER && LastPreviewTargetYawDir != FMath::Sign(LockedDelta.Yaw))
				LockedDelta.Yaw = 0.f;

			LastPreviewTargetYawDir = LockedDelta.Yaw;
			return LockedDelta;
		}

		return Super::GetFinalizedDeltaRotation(InRotation);
	}

	FRotator GetWantedTurnRate() const
	{
		// No rotation during zoomed out mode
		if(AnimalComp.CurrentAnimal.bPreparingToLaunch)
			return FRotator::ZeroRotator;

		if(VineComp != nullptr)
		{
			if(VineComp.VineActiveType == EVineActiveType::ActiveAndLocked)
				return FRotator::ZeroRotator;
		}

		return Super::GetWantedTurnRate();
	}

	EWallWalkingAnimalActiveCameraType GetWantedCameraType()const
	{
		if(AnimalComp.CurrentAnimal.bLaunching)
		{
			return EWallWalkingAnimalActiveCameraType::Launch;
		}

		else if(AnimalComp.CurrentAnimal.bPreparingToLaunch)
		{
			return EWallWalkingAnimalActiveCameraType::LaunchPreview;
		}

		else if(AnimalComp.CurrentAnimal.bTransitioning)
		{
			return EWallWalkingAnimalActiveCameraType::Transition;
		}

		else
		{
			return EWallWalkingAnimalActiveCameraType::Normal;
		}
	}

	void UpdatePreLaunchCameraOffset(float DeltaTime)
	{
		FVector TargetOffset = FVector::ZeroVector;
		float MaxDistance = 0;

		FHitResult CeilingHitResult;
		if(AnimalComp.CurrentAnimal.GetCeilingHitResult(CeilingHitResult))
		{
			FVector MiddlePosition = CeilingHitResult.ImpactPoint;
			MiddlePosition += LastActorLocation;
			MiddlePosition *= 0.5f;
			MaxDistance = (MiddlePosition - LastActorLocation).Size() * 0.9f;

			const FVector DirToCeiling = (CeilingHitResult.TraceEnd - CeilingHitResult.TraceStart).GetSafeNormal();
			const FVector DirLeftRight = FVector::RightVector * FMath::RoundToInt(DirToCeiling.DotProduct(User.GetDesiredRotation().RightVector));
			const FVector DirUpDown = FVector::UpVector * FMath::RoundToInt(DirToCeiling.DotProduct(User.GetDesiredRotation().UpVector));
			TargetOffset = (DirLeftRight + DirUpDown) * MaxDistance;
		}
		else
		{
			MaxDistance = CeilingHitResult.TraceStart.Distance(CeilingHitResult.TraceEnd) * 0.4f;
			const FVector DirToCeiling = (CeilingHitResult.TraceEnd - CeilingHitResult.TraceStart).GetSafeNormal();
			const FVector DirLeftRight = FVector::RightVector * FMath::RoundToInt(DirToCeiling.DotProduct(User.GetDesiredRotation().RightVector));
			const FVector DirUpDown = FVector::UpVector * FMath::RoundToInt(DirToCeiling.DotProduct(User.GetDesiredRotation().UpVector));
			TargetOffset = (DirLeftRight + DirUpDown) * MaxDistance;
		}

		FHazeCameraSpringArmSettings CurrentSettings;
		User.GetCameraSpringArmSettings(CurrentSettings);

		const float CurrentDistance = CurrentSettings.CameraOffset.Distance(TargetOffset);
		TargetOffset = FMath::VInterpTo(CurrentSettings.CameraOffset, TargetOffset, DeltaTime, 4.f);
		Player.ApplyCameraOffset(TargetOffset, FHazeCameraBlendSettings(0.f), this, EHazeCameraPriority::High);

		if(MaxDistance > 0)
		{	
			float IdealDistance = FMath::Lerp(AnimalComp.CamSettings.CameraDistanceAtMaxAiming, LastCameraSettings.IdealDistance, FMath::Min(1.f, CurrentDistance / MaxDistance));
			//IdealDistance = FMath::FInterpTo(CurrentSettings.IdealDistance, IdealDistance, DeltaTime, 2.f); 
			Player.ApplyIdealDistance(IdealDistance, FHazeCameraBlendSettings(1.f), this);
		}
	
		// We need to use the last actor location to get a stable camera
		LastActorLocation = AnimalComp.CurrentAnimal.GetActorLocation();
	}
}
