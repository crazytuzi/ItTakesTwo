import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Settings.CameraVehicleChaseSettings;

class UCameraVehicleChaseCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");

	default CapabilityTags.Add(CameraTags::VehicleChaseAssistance);

	default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	float NoInputDuration = BIG_NUMBER;
	float MovementDuration = 0.f;
	FHazeAcceleratedRotator ChaseRotation;
	FHazeAcceleratedFloat AccelerationDuration;

	bool bLastInputWasCamera = false;
	UCameraVehicleChaseSettings Settings;
	bool bWasUsingLookAhead = false;

	bool bDebugDraw = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		Settings = User.VehicleChaseSettings;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!User.HasControl() && !PlayerUser.CameraSyncronizationIsBlocked())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!User.HasControl() && !PlayerUser.CameraSyncronizationIsBlocked())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);
		ChaseRotation.SnapTo(User.WorldToLocalRotation(User.DesiredRotation));
		
		if (Settings.InitialAccelerationDuration >= 0.f)
			AccelerationDuration.SnapTo(Settings.InitialAccelerationDuration);
		else
			AccelerationDuration.SnapTo(Settings.AccelerationDuration);
		
		SetMutuallyExclusive(CameraTags::VehicleChaseAssistance, true);
		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		bWasUsingLookAhead = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);
		SetMutuallyExclusive(CameraTags::VehicleChaseAssistance, false);
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		PlayerUser.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeDilation = PlayerUser.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
		UpdateInputDuration(RealTimeDeltaSeconds);

		if (NoInputDuration <= Settings.CameraInputDelay)	
		{
			OnCameraInput();
			return;
		}

		// If the last input we did was camera, and we haven't touched the move stick
		// since then, then we should not do chase until we start applying movement again
		if (bLastInputWasCamera && Settings.bOnlyChaseAfterMovementInput)
		{
			OnCameraInput();
			return;
		}

		ChaseRotation.Value = User.WorldToLocalRotation(User.DesiredRotation);

		FTransform ChaseTransform;
		ChaseTransform = Owner.RootComponent.WorldTransform;

		// We want to chase towards the camera-parents forward
		TSubclassOf<UHazeCameraParentComponent> ParentClass(UCameraSpringArmComponent::StaticClass());
		UHazeCameraParentComponent Parent = User.GetCurrentCameraParent(ParentClass);

		if (Parent != nullptr)
		{
			// Since the parent might be the thing we're rotating, we want to get its transform _without_ rotation
			FTransform RelativeTransform = Parent.RelativeTransform;
			RelativeTransform.Rotation = FQuat::Identity;

			if (Parent.AttachParent != nullptr)
				ChaseTransform = Parent.AttachParent.GetWorldTransform();
				
			ChaseTransform.ConcatenateRotation(FQuat(Settings.ChaseOffset));
			ChaseTransform = ChaseTransform * RelativeTransform;
		}

		FRotator DesiredRot = User.WorldToLocalRotation(User.DesiredRotation);
		FRotator TargetRot = User.WorldToLocalRotation(ChaseTransform.Rotation.Rotator());
		TargetRot.Roll = 0.f;

		AccelerationDuration.AccelerateTo(Settings.AccelerationDuration, Settings.AccelerationChangeDuration, RealTimeDeltaSeconds);

		ChaseRotation.Value = DesiredRot; // This value is expected to be changed by outside systems
		if ((MovementDuration > Settings.MovementInputDelay) && SettingsAllowChaseCamera())
		{
			ChaseRotation.AccelerateTo(TargetRot, AccelerationDuration.Value, DeltaTime);
		}
		else
		{
			// Allow velocity to decelerate to 0
			ChaseRotation.Velocity -= ChaseRotation.Velocity * 10.f * DeltaTime;
			ChaseRotation.Value += ChaseRotation.Velocity * DeltaTime;
		}
		
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRot).GetNormalized();
	 	
		User.AddDesiredRotation(DeltaRot);	

		UpdateLookAhead(ChaseTransform);
	}

	float GetIdealDistance()
	{
		FHazeCameraSpringArmSettings SpringarmSettings;
		User.GetCameraSpringArmSettings(SpringarmSettings);
		return SpringarmSettings.IdealDistance;
	}

	void UpdateLookAhead(FTransform ChaseTransform)
	{
		if (Settings.LookAheadDistance > 0.f)
		{
			float LookAheadViewCos = PlayerUser.ViewRotation.Vector().DotProduct(ChaseTransform.Rotation.ForwardVector);
			if (LookAheadViewCos < 0.f)
			{
				ClearLookAhead();
			}
			else
			{
				// Apply a world pivot offset so pivot will be projected onto the line from camera target location
				// to a location LookAheadDistance in front of chase transform.
				FVector CamLocInChasePlane = ChaseTransform.Location + (PlayerUser.ViewLocation - ChaseTransform.Location).VectorPlaneProject(ChaseTransform.Rotation.UpVector);
				FVector LookAheadLoc = ChaseTransform.Location + ChaseTransform.Rotation.ForwardVector * Settings.LookAheadDistance;
				FVector ProjectedLoc = Math::ProjectPointOnInfiniteLine(CamLocInChasePlane, LookAheadLoc - CamLocInChasePlane, ChaseTransform.Location);
				FHazeCameraSpringArmSettings LookAheadSettings;
				LookAheadSettings.bUseWorldPivotOffset = true;
				LookAheadSettings.WorldPivotOffset = ProjectedLoc - ChaseTransform.Location;
				LookAheadSettings.WorldPivotOffset *= FMath::Clamp(LookAheadViewCos * 1.5f, 0.f, 1.f);
				PlayerUser.ApplyCameraSpringArmSettings(LookAheadSettings, CameraBlend::Additive(Settings.LookAheadBlendTime), this, EHazeCameraPriority::Script);
				bWasUsingLookAhead = true;

				//bDebugDraw = true;
				if (bDebugDraw)
				{
					System::DrawDebugLine(ChaseTransform.Location, LookAheadLoc, FLinearColor::Purple, 0.f, 20.f);
					System::DrawDebugLine(CamLocInChasePlane, LookAheadLoc, FLinearColor::Yellow, 0.f, 20.f);
					System::DrawDebugLine(ChaseTransform.Location, ChaseTransform.Location + LookAheadSettings.WorldPivotOffset, FLinearColor::Red, 0.f, 5.f);
				}
			}
		}
		else if (bWasUsingLookAhead)
		{
			ClearLookAhead();
		}
	}

	void ClearLookAhead()
	{
		FHazeCameraSpringArmSettings LookAheadSettings;
		LookAheadSettings.bUseWorldPivotOffset = true;
		PlayerUser.ClearSpecificCameraSettings(FHazeCameraSettings(), FHazeCameraClampSettings(), LookAheadSettings, this, 5.f);			
		bWasUsingLookAhead = false;
	}

	void OnCameraInput()
	{
		ChaseRotation.Velocity = 0.f;
		if (Settings.InputResetAccelerationDuration >= 0.f)
		{
			if (Settings.InputResetAccelerationDuration > AccelerationDuration.Value)
				AccelerationDuration.SnapTo(Settings.InputResetAccelerationDuration);
		}
		ClearLookAhead();
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if (AxisInput.IsNearlyZero(0.001f))
		{
			NoInputDuration += DeltaTime;
		}
		else
		{
			NoInputDuration = 0.f;
			bLastInputWasCamera = true;
		}

		// Track whether the last input was camera or movvement
		const FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		if (!MoveInput.IsNearlyZero())
			bLastInputWasCamera = false;

		if (IsMoving())
			MovementDuration += DeltaTime;
		else
			MovementDuration = 0.f;
	}

	FRotator GetTargetRotation()
	{
		return Owner.GetActorRotation();
	}

	bool IsMoving()
	{
		//const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		//return !AxisInput.IsNearlyZero(0.01f);
		return PlayerUser.GetActualVelocity().SizeSquared2D() > 0.001f;
	}

	bool SettingsAllowChaseCamera()
	{
		FHazeCameraSettings CamSettings;
		User.GetCameraSettings(CamSettings);
		CamSettings.Override(User.GetCurrentCamera().Settings);
		if (!CamSettings.bAllowChaseCamera)
			return false;		

		return true;
	}
};