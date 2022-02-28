import Vino.Camera.CameraStatics;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Settings.CameraImpulseSettings;
import Vino.Camera.Settings.CameraLazyChaseSettings;
import Vino.Camera.Settings.CameraVehicleChaseSettings;
import Vino.Camera.Settings.CameraUserSettings;

event void FOnCameraSnapEvent();
event void FOnOtherPlayerFullscreenCutscene();
event void FOnCameraUserReset();
event void FOnUpdateHideOnOverlap();

delegate void FOnYawAxisChanged(UCameraUserComponent Component, FQuat NewRotation);

class UCameraUserComponent : UHazeActiveCameraUserComponent
{
	// Ticking during last demotable gives some small glitches when framerate is unsteady. Ticking during postupdatework seems to get rid of these.
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	UPROPERTY()
	UCameraLazyChaseSettings DefaultLazyChaseSettingsWeak = Asset("/Game/Blueprints/Cameras/LazyChase/DA_DefaultLazyChaseSettings_Weak.DA_DefaultLazyChaseSettings_Weak");

	UPROPERTY()
	UCameraLazyChaseSettings DefaultLazyChaseSettingsStrong = Asset("/Game/Blueprints/Cameras/LazyChase/DA_DefaultLazyChaseSettings_Strong.DA_DefaultLazyChaseSettings_Strong");

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset FindOtherPlayerAdditiveSettings = Asset("/Game/Blueprints/Cameras/CameraSettings/DA_FindOtherPlayerAdditiveSettings.DA_FindOtherPlayerAdditiveSettings");

	UPROPERTY(Category = "Network")
	float ReplicationAccelerationDuration = 0.8f;
	float ReplicationAccelerationRestoreDuration = 5.f;
	FHazeAcceleratedFloat CurrentReplicationAccelerationDuration;
	
	UCameraLazyChaseSettings LazyChaseSettings;
	UCameraVehicleChaseSettings VehicleChaseSettings;
	UCameraImpulseSettings ImpulseSettings;
	UCameraUserSettings CameraUserSettings;

	FOnCameraSnapEvent OnSnapped;
	FOnOtherPlayerFullscreenCutscene OnOtherPlayerFullscreenCutscene;
	FOnCameraUserReset OnReset;
	FOnUpdateHideOnOverlap UpdateHideOnOverlap;

	FHazeAcceleratedFloat TurnRatePitch;
	FHazeAcceleratedFloat TurnRateYaw;

	private FQuat InternalBaseRotation;
	default InternalBaseRotation = FQuat::Identity;

	int32 IgnoreInputTicks = 5;

	TSet<UObject> InputControllers;
	TSet<UObject> ControlCameraWithoutScreenSizeAllower;

	bool bUsingDebugCamera = false;
	AHazeDebugCameraActor DebugCamera;

	FOnYawAxisChanged OnYawAxisChanged;

	AHazePlayerCharacter PlayerOwner;

	private FHazeCameraReplicationFinalized LastSyncedData;
	private FHazeAcceleratedRotator AcceleratedSyncedRotation;
	
	bool bRegisteredInput = false;

	FVector CurrentCameraVelocity = FVector::ZeroVector;
	FRotator CurrentCameraAngularVelocity = FRotator::ZeroRotator;
	FVector PreviousCameraWorldLocation = FVector(BIG_NUMBER);
	FRotator PreviousCameraWorldRotation = FRotator(BIG_NUMBER);

	UPROPERTY()
	private int64 CameraDebugDisplayFlags = 0;
	
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset DebugAnimationInspectionSettings = Asset("/Game/Blueprints/Cameras/CameraSettings/DA_CamSettings_AnimationInspection.DA_CamSettings_AnimationInspection");

	EHazeCameraSnapType DeferredSnap = EHazeCameraSnapType::None;
	FVector DeferredSnapCameraDirection = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		const FRotator TargetRate = GetTargetTurnRate();
		TurnRatePitch.Value = TargetRate.Pitch;
		TurnRateYaw.Value = TargetRate.Yaw;

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		LazyChaseSettings = UCameraLazyChaseSettings::GetSettings(HazeOwner);
		VehicleChaseSettings = UCameraVehicleChaseSettings::GetSettings(HazeOwner);

		ImpulseSettings = UCameraImpulseSettings::GetSettings(HazeOwner);

		CameraUserSettings = UCameraUserSettings::GetSettings(HazeOwner);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		SnapSyncRotation();

#if TEST
	ensure(ECameraDebugDisplayType::MAX < ECameraDebugDisplayType(65));
#endif		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float BlendDuration = IsAiming() ? 0.f : 1.f;
		const FRotator TargetRate = GetTargetTurnRate();
		TurnRatePitch.AccelerateTo(TargetRate.Pitch, BlendDuration, DeltaSeconds);
		TurnRateYaw.AccelerateTo(TargetRate.Yaw, BlendDuration,  DeltaSeconds);

		if(!HasControl())
			UpdateReplicatedRotation(Time::GetUndilatedWorldDeltaSeconds());
		
		// Ignore input for a few ticks while when starting up, since we can get delayed input 
		// e.g. from mouse when starting PIE with the "game gets mouse control" setting.
		if (IgnoreInputTicks > 0)
			IgnoreInputTicks--;

		if (DeltaSeconds > 0.f)
		{
			FVector CamLoc = PlayerOwner.GetPlayerViewLocation();
			if (PreviousCameraWorldLocation == FVector(BIG_NUMBER))
				CurrentCameraVelocity = FVector::ZeroVector;
			else 
				CurrentCameraVelocity = (CamLoc - PreviousCameraWorldLocation) / DeltaSeconds;	
			PreviousCameraWorldLocation = CamLoc;

			FRotator CamRot = PlayerOwner.GetPlayerViewRotation();
			if (PreviousCameraWorldRotation == FRotator(BIG_NUMBER))
				CurrentCameraAngularVelocity = FRotator::ZeroRotator;
			else 
				CurrentCameraAngularVelocity = (CamRot - PreviousCameraWorldRotation).GetNormalized() * (1.f / DeltaSeconds);	
			PreviousCameraWorldRotation = CamRot;
		}
	}

	FRotator GetTargetTurnRate() property
	{
		if (!CanControlCamera())
		  	return FRotator::ZeroRotator;

		if (InputControllers.Num() == 0)
			return FRotator::ZeroRotator;	

		return GetCameraTargetTurnRate();		
	}

	UFUNCTION()
	void SetDesiredRotation(const FRotator& WorldRotation) property
	{	
		if(PlayerOwner == nullptr || PlayerOwner.CanApplyLocalCameraRotationChange())
		{
			SetDesiredRotationInternal(WorldRotation);
		}
	}

	void SetDesiredRotationInternal(FRotator WorldRotation)
	{
		FRotator NewRot = WorldToLocalRotation(WorldRotation);

		if(HasControl())
		 	NewRot = ClampLocalRotation(NewRot);

		// Finalize
		CurrentDesiredRotation = (InternalBaseRotation * FQuat(NewRot)).Rotator();
		
		if(!HasControl())
			SnapSyncRotation();
	}

	UFUNCTION(BlueprintOverride)
	void AddDesiredRotation(FRotator OriginalLocalRotationDelta)
	{
		if(PlayerOwner == nullptr || PlayerOwner.CanApplyLocalCameraRotationChange())
		{
			// All rotation will be applied in local space
			const FRotator LocalRot = WorldToLocalRotation(CurrentDesiredRotation);
			FRotator LocalRotationDelta = OriginalLocalRotationDelta;

			// We first clamp the wanted rotation
			if(HasControl())
			{
				const FRotator WantedRot = LocalRot + OriginalLocalRotationDelta;
				const FRotator ClampedRot = ClampLocalRotation(WantedRot);
				const FRotator ClampDiff = WantedRot - ClampedRot;
				LocalRotationDelta = OriginalLocalRotationDelta - ClampDiff;
			}

			// You need to apply pitch in camera space and yaw in base rotation space when using quats 
			FQuat NewQuatRot = FQuat(FRotator(0.f, LocalRotationDelta.Yaw,0.f)) * FQuat(LocalRot) * FQuat(FRotator(LocalRotationDelta.Pitch,0.f,0.f));

			// Need this for Boatsled; fix and do proper for Split!!!
			if(CameraUserSettings.bApplyRollToDesiredRotation)
				NewQuatRot = FQuat(FRotator(0.f, LocalRotationDelta.Yaw,0.)) * FQuat(LocalRot) * FQuat(FRotator(LocalRotationDelta.Pitch,0.f, LocalRotationDelta.Roll));

			CurrentDesiredRotation = (InternalBaseRotation * NewQuatRot).Rotator();
			
			if(!HasControl())
			 	SnapSyncRotation();
		}
	}

	FRotator ClampLocalRotation(FRotator WantedLocalRotation)
	{
		FRotator NewRot = WantedLocalRotation;
		FHazeCameraClampSettings Clamps;
		if (GetClamps(Clamps))
		{
	        FRotator LocalCenterOffset = (InternalBaseRotation.Inverse() * Clamps.CenterOffset.Quaternion()).Rotator();
            if (Clamps.bUseClampPitchDown || Clamps.bUseClampPitchUp)
                NewRot.Pitch = FMath::ClampAngle(NewRot.Pitch, LocalCenterOffset.Pitch - FMath::Min(Clamps.ClampPitchDown, 89.f), LocalCenterOffset.Pitch + FMath::Min(Clamps.ClampPitchUp, 89.f));
            if (Clamps.bUseClampYawLeft || Clamps.bUseClampYawRight)
                NewRot.Yaw = FMath::ClampAngle(NewRot.Yaw, LocalCenterOffset.Yaw - FMath::Min(Clamps.ClampYawLeft, 179.9f), LocalCenterOffset.Yaw + FMath::Min(Clamps.ClampYawRight, 179.9f));	
		}

		NewRot.Roll = 0.f;
		return NewRot;
	}

	void SetDesiredReplicatedRotation(FHazeCameraReplicationFinalized ReplicationParams) property
	{
		LastSyncedData = ReplicationParams;	
	}

	bool IsSyncingWithCrumb() const
	{
		auto CrumbComp = UHazeCrumbComponent::Get(Owner);
		if (CrumbComp == nullptr)
			return false;
		return !CrumbComp.CameraSyncronisationIsBlocked();
	}

	FRotator GetLastReplicatedRotation() const property
	{
		return LastSyncedData.Rotation;
	}

	// Set how many seconds replicated camera rotation should lag behind and over what time it should revert to default acceleration duration.
	void SetTemporaryReplicationAccelerationDuration(float AccelerationDuration, float RestoreTime)
	{
		CurrentReplicationAccelerationDuration.SnapTo(AccelerationDuration, 0.f);
		ReplicationAccelerationRestoreDuration = RestoreTime;
	}

	private void UpdateReplicatedRotation(float DeltaTime)
	{	
		CurrentReplicationAccelerationDuration.AccelerateTo(ReplicationAccelerationDuration, ReplicationAccelerationRestoreDuration, DeltaTime);
		float AccDuration = CurrentReplicationAccelerationDuration.Value;

		if(IsSyncingWithCrumb())
		{
			FVector WantedWorldUp = Math::SlerpVectorTowards(GetBaseRotation().GetUpVector(), LastSyncedData.WorldUp, DeltaTime * 15.f);
			SetYawAxis(WantedWorldUp);
			CurrentDesiredRotation = AcceleratedSyncedRotation.AccelerateTo(LastSyncedData.Rotation, AccDuration * 0.1f, DeltaTime);
			// CurrentDesiredRotation = LastSyncedData.Rotation;
			// AcceleratedSyncedRotation.Value = CurrentDesiredRotation;
			// AcceleratedSyncedRotation.Velocity = 0;
		}
		else
		{
			// TODO (Split): When not syncing with crumbs we should use a higher acceleration duration which 
			// blends down to default duration when we start syncing with crumbs again, to make transition smoother.
			CurrentDesiredRotation = AcceleratedSyncedRotation.AccelerateTo(LastSyncedData.Rotation, AccDuration, DeltaTime);
			GetDesiredReplicationRotation(LastSyncedData);
		}
	}

	void SnapSyncRotation()
	{
		GetDesiredReplicationRotation(LastSyncedData);
		AcceleratedSyncedRotation.Value = LastSyncedData.Rotation;
		AcceleratedSyncedRotation.Velocity = 0;
		CurrentDesiredRotation = LastSyncedData.Rotation;
		ResetCameraVelocity();
		CurrentReplicationAccelerationDuration.SnapTo(ReplicationAccelerationDuration);
	}

	UFUNCTION(BlueprintOverride)
	FRotator GetCameraTurnRate() const property 
	{		
		FRotator TurnRate = FRotator(TurnRatePitch.Value, TurnRateYaw.Value, 0.f);	
		FHazeCameraSettings Settings;
		GetCameraSettings(Settings);
		TurnRate *= Settings.SensitivityFactor;
		if(PlayerOwner == nullptr)
			return TurnRate;

		// Todo, change the settings to be composable settings
		//UPerPlayerSettings PerPlayerSettings = UPerPlayerSettings::GetSettings(PlayerOwner);

		if (IsAiming())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimYaw) * Settings.SensitivityFactorYaw;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::AimPitch) * Settings.SensitivityFactorPitch;
		}
		else
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Yaw) * Settings.SensitivityFactorYaw;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::Pitch) * Settings.SensitivityFactorPitch;
		}

		if (PlayerOwner.IsCameraPitchInverted())
			TurnRate.Pitch *= -1.f;

		if (PlayerOwner.IsCameraYawInverted())
			TurnRate.Yaw *= -1.f;

		if (!PlayerOwner.IsUsingGamepad())
		{
			TurnRate.Yaw *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MouseYaw) * Settings.SensitivityFactorYaw;;
			TurnRate.Pitch *= PlayerOwner.GetSensitivity(EHazeSensitivityType::MousePitch) * Settings.SensitivityFactorPitch;;
		}

		return TurnRate;
	}

	UFUNCTION(BlueprintOverride)
	void SetYawAxis(const FVector& Axis) property
	{
		// Check if angle is the same (within ~0.08 degrees)
		if(InternalBaseRotation.UpVector.DotProduct(Axis) > 0.999999f)
			return;

		FVector PrevFwd = InternalBaseRotation.Vector();
		FVector NewFwd = PrevFwd.VectorPlaneProject(Axis);
		if (NewFwd.IsNearlyZero())
		{
			// Axis is parallell with previous fwd vector, new fwd should be previous up or down vector
			FVector PrevUp = InternalBaseRotation.GetUpVector();
			NewFwd = (PrevFwd.DotProduct(Axis) > 0.f) ? -PrevUp : PrevUp;
		}

		if(OnYawAxisChanged.IsBound())
		{
			OnYawAxisChanged.Execute(this, Math::MakeQuatFromXZ(NewFwd, Axis));
			return;
		}
		
		ApplyDesiredRotationFollowsYawAxis(Math::MakeQuatFromXZ(NewFwd, Axis));	
	}

	UFUNCTION(BlueprintOverride)
	bool CanReplicateRotation() const
	{
		return DeferredSnap == EHazeCameraSnapType::None;
	}

	void ApplyDesiredRotationFollowsYawAxis(FQuat NewRotation)
	{
 		const FQuat LocalDesiredRot = InternalBaseRotation.Inverse() * FQuat(DesiredRotation);
		InternalBaseRotation = NewRotation;
		
		// Finalize
		FRotator NewRot = WorldToLocalRotation((InternalBaseRotation * LocalDesiredRot).Rotator());	

		if(HasControl())
			SetDesiredRotation((InternalBaseRotation * LocalDesiredRot).Rotator());
		else
			CurrentDesiredRotation = (InternalBaseRotation * FQuat(NewRot)).Rotator();
	}

	void ApplyYawAxisAndKeepCurrentDesiredRotationYawPitch(FQuat NewRotation)
	{
		FVector OldUp = InternalBaseRotation.GetUpVector();
		FVector NewUp = NewRotation.GetUpVector();

		FRotator OldDesiredLocalRotation = (NewRotation.Inverse() * FQuat(GetDesiredRotation())).Rotator();
		
		const FQuat LocalDesiredRot = InternalBaseRotation.Inverse() * FQuat(DesiredRotation);
		InternalBaseRotation = NewRotation;

		FRotator NewRot = WorldToLocalRotation((InternalBaseRotation * LocalDesiredRot).Rotator());
		CurrentDesiredRotation = (InternalBaseRotation * FQuat(NewRot)).Rotator();

		FRotator NewDesiredLocalRotation = WorldToLocalRotation(GetDesiredRotation());
		float PitchDeltaChange = NewDesiredLocalRotation.Pitch - OldDesiredLocalRotation.Pitch;
		AddDesiredRotation(FRotator(-PitchDeltaChange, 0.f, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	FQuat GetBaseRotation() property
	{
		return InternalBaseRotation;
	}

	UFUNCTION(BlueprintOverride)
	FRotator WorldToLocalRotation(const FRotator& WorldRotation)const
	{
		return (InternalBaseRotation.Inverse() * FQuat(WorldRotation)).Rotator();
	}

	UFUNCTION(BlueprintOverride)
	FRotator LocalToWorldRotation(const FRotator& LocalRotation)const
	{
		return (InternalBaseRotation * FQuat(LocalRotation)).Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void OnTeleportOwner()
	{
		FHazeCameraSettings Settings;
		GetCameraSettings(Settings);
		if (Settings.bSnapOnTeleport)
		{
			if (DeferredSnap != EHazeCameraSnapType::None)
				return; // We already have deferred snap, don't interrupt that

			FVector DesiredDirection = GetDesiredRotation().Vector();
			SnapCamera(DesiredDirection);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void SnapCamera(const FVector& Direction)
	{
		// When we reset the player, we will have a snapbehind.
		// When this happens, we always want to snap the remote side so we need
		// to be able to reach the 'SnapCameraInternal' when that happens.
		const bool bWasDeferredSnap = DeferredSnap != EHazeCameraSnapType::None;
		
		// Clear any deferred snap, so that won't override this
		DeferredSnap = EHazeCameraSnapType::None;

		if(bWasDeferredSnap)
		{
			SnapCameraInternal(Direction, true);
		}
		else if(PlayerOwner == nullptr || PlayerOwner.CanApplyLocalCameraRotationChange())
		{
			if(HasControl() || !IsSyncingWithCrumb() || PlayerOwner.CameraSyncronizationIsBlocked())
			{
				SnapCameraInternal(Direction, true);
			}
			else
			{
				SnapSyncRotation();
				SnapCameraInternal(Direction, false);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void SnapCameraAtEndOfFrame(FVector Direction, EHazeCameraSnapType SnapType = EHazeCameraSnapType::World)
	{
		DeferredSnap = SnapType;
		DeferredSnapCameraDirection = Direction;
	}

	UFUNCTION(BlueprintOverride)
    FVector GetYawAxis() const property
    {
        return InternalBaseRotation.UpVector;
    }

	void SnapCameraInternal(const FVector& Direction, bool bSnapDesired)
	{
		const FRotator TargetRate = GetTargetTurnRate();
		TurnRatePitch.SnapTo(TargetRate.Pitch);
		TurnRateYaw.SnapTo(TargetRate.Yaw);
	
		// Get wanted world rotation in with zero roll in local space. Note that Direction.Rotation() would not work.
		FRotator SnapRot = LocalToWorldRotation(InternalBaseRotation.Inverse().RotateVector(Direction).Rotation()); 

		// Asynchronously update selector and snap view to make sure current camera gets blended in fully 
		// (for clamps and in case any parent comps depend on that)
		GetCameraSelector().UpdateActiveCamera(this, GetCameraViewPoint());
		GetCameraViewPoint().Snap(); 

		// Snap all settings after we know view camera (as that affect center offset of clamps)
		GetSettingsManager().Snap();

		// Snap desired rotation.
		if (bSnapDesired)
			SetDesiredRotationInternal(SnapRot);

		// Snap all parents of current camera up to camera root. Snap parentmost first.
		TArray<UHazeCameraParentComponent> CameraParents;
		UHazeCameraComponent Camera = GetCameraViewPoint().GetCurrentCamera();
		USceneComponent Parent = Camera.GetAttachParent();
		while ((Parent != nullptr) && !Parent.IsA(UHazeCameraRootComponent::StaticClass()))
		{
			UHazeCameraParentComponent CameraParent = Cast<UHazeCameraParentComponent>(Parent);
			if (CameraParent != nullptr)
				CameraParents.Add(CameraParent);	
			Parent = Parent.GetAttachParent();
		}
		for (int32 i = CameraParents.Num() - 1; i >= 0; i--)
		{
			CameraParents[i].Snap();
		}

		// Lastly, snap view again to ensure we have the correct view set asynchronously.
		GetCameraViewPoint().Snap(); 
		ResetCameraVelocity();
			 
		// Broadcast delegate
		OnSnapped.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		InternalBaseRotation = FQuat::Identity;
		CurrentDesiredRotation.Roll = 0.f;
		ResetCameraVelocity();
		OnReset.Broadcast();
	}

	void ResetCameraVelocity()
	{
		CurrentCameraVelocity = FVector::ZeroVector;
		PreviousCameraWorldLocation = PlayerOwner.GetPlayerViewLocation();
		CurrentCameraAngularVelocity = FRotator::ZeroRotator;
		PreviousCameraWorldRotation = PlayerOwner.GetPlayerViewRotation();
	}

	UHazeCameraComponent GetCurrentCamera() const property
	{
		return GetCameraViewPoint().GetCurrentCamera();
	}

	UFUNCTION()
	UHazeCameraParentComponent GetCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent> ParentClass)
	{
		UHazeCameraComponent CurCam = GetCurrentCamera();
		if (CurCam == nullptr)
			return nullptr;

		USceneComponent CurParent = CurCam.GetAttachParent();
		while (CurParent != nullptr)
		{
			if (CurParent.IsA(ParentClass))
				return Cast<UHazeCameraParentComponent>(CurParent);
			CurParent = CurParent.GetAttachParent();
		}
		return nullptr;
	}

	bool HasCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent> ParentClass)
	{
		return (GetCurrentCameraParent(ParentClass) != nullptr);
	}

	bool IsUsingDefaultCamera()
	{
		UCameraComponent CurCam = GetCurrentCamera();
		return (CurCam != nullptr) && (CurCam.Owner == Owner);
	}

	bool InitialIgnoreInput()
	{
		return (IgnoreInputTicks > 0);
	}

	// Return true if we're controlling part of the screen. False if other player has full screen (or there are non-player controlled screens covering the entire screen)
	bool HasScreenSize() const
	{
		FVector2D Res = SceneView::GetPlayerViewResolution(PlayerOwner);
		return (Res.X > 1.f) && (Res.Y > 1.f);
	}

	// Returns true if there are any currently active cameras that will respond to user input and we have screen space
	bool CanControlCamera() const
	{
		if (!HasScreenSize() && (ControlCameraWithoutScreenSizeAllower.Num() == 0))
		 	return false;

 		if (!PlayerOwner.IsAnyCapabilityActive(CameraTags::Control) &&
            !PlayerOwner.IsAnyCapabilityActive(CameraTags::VehicleChaseAssistance) && 
            !PlayerOwner.IsAnyCapabilityActive(CameraTags::PointOfInterest) &&
            !PlayerOwner.IsAnyCapabilityActive(CameraTags::CustomControl))
            return false;

		if ((GetCurrentCamera() != nullptr) && GetCurrentCamera().IsControlledByInput())
			return true;

		UHazeCameraViewPoint View = GetCameraViewPoint();
		TArray<FHazeCameraBlendFraction> BlendingOutCameras;
		View.GetCurrentCameraBlends(BlendingOutCameras);
		for (FHazeCameraBlendFraction BlendingOutCamera : BlendingOutCameras)
		{
			if ((BlendingOutCamera.Camera != nullptr) && BlendingOutCamera.Camera.IsControlledByInput())
				return true;
		}

		if (bUsingDebugCamera)
			return true;

		return false;
	}

	bool IsCameraAttachedToPlayer() const
	{
		UHazeCameraComponent Camera = GetCurrentCamera();
		if (Camera.IsAttachedTo(PlayerOwner))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ApplyCameraImpulseClamps(FVector& InOutTranslation, FRotator& InOutRotation)
	{
		if (!ensure(ImpulseSettings != nullptr))
			return;
		ImpulseSettings.ApplyClamps(InOutTranslation, InOutRotation);
	}

	UFUNCTION(BlueprintPure)
	FVector GetCameraVelocity()
	{
		return CurrentCameraVelocity;
	}

	UFUNCTION(BlueprintPure)
	FRotator GetCameraAngularVelocity()
	{
		return CurrentCameraAngularVelocity;
	}

	UFUNCTION(BlueprintPure)
	bool HasDebugDisplayFlags()
	{
#if TEST
		if (CameraDebugDisplayFlags != 0)
			return true;
#endif		
		return false;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldDebugDisplay(ECameraDebugDisplayType DebugDisplay)
	{
#if TEST
		if ((CameraDebugDisplayFlags & (1 << DebugDisplay)) != 0)
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintCallable)
	void ToggleDebugDisplay(ECameraDebugDisplayType DebugDisplay)
	{
#if TEST
		CameraDebugDisplayFlags ^= (1 << DebugDisplay);		
#endif
	}

	UFUNCTION(BlueprintCallable)
	void EnableDebugDisplay(ECameraDebugDisplayType DebugDisplay)
	{
#if TEST
		CameraDebugDisplayFlags |= (1 << DebugDisplay);		
#endif
	}

	UFUNCTION(BlueprintCallable)
	void DisableDebugDisplay(ECameraDebugDisplayType DebugDisplay)
	{
#if TEST
		CameraDebugDisplayFlags &= ~(1 << DebugDisplay);		
#endif
	}

	UFUNCTION(BlueprintCallable)
	void ClearDebugDisplayFlags()
	{
#if TEST
		CameraDebugDisplayFlags = 0;	
#endif
	}
}


UFUNCTION()
UHazeCameraParentComponent GetCurrentlyUsedCameraParentComponent(AHazePlayerCharacter Player, TSubclassOf<UHazeCameraParentComponent> ParentClass)
{
	if (Player == nullptr)
		return nullptr;

	return UCameraUserComponent::Get(Player).GetCurrentCameraParent(ParentClass);
}