import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.PointOfInterest.PointOfInterestStatics;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Settings.CameraPointOfInterestBehaviourSettings;

class UCameraClampedPointOfInterestCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter Player;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::PointOfInterest);

	default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	FHazeAcceleratedFloat FocusRotationYaw;
	FHazeAcceleratedFloat FocusRotationPitch;
	float LastInputTime = 0.f;

	FPointOfInterestStatics::FClearOnInput ClearOnInput;

	UCameraPointOfInterestBehaviourSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(User.GetOwner());
		Settings = 	UCameraPointOfInterestBehaviourSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkActivation::DontActivate;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::Clamped))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::Clamped))
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		User.RegisterDesiredRotationReplication(this);

		FRotator LocalRot = User.WorldToLocalRotation(User.GetDesiredRotation());
		FRotator LocalRotVelocity = User.WorldToLocalRotation(User.GetDesiredRotationVelocity());

		FocusRotationYaw.Value = LocalRot.Yaw;
		FocusRotationYaw.Velocity = LocalRotVelocity.Yaw; 
		FocusRotationPitch.Value = LocalRot.Pitch;
		FocusRotationPitch.Velocity = LocalRotVelocity.Pitch; 

		// We don't want this to mess with input since we allow input within clamps
		ClearOnInput.OnActivated(false, this, Player, Settings);

		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);

		LastInputTime = -BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FCapabilityDeactivationParams& DeactivationParams)
	{
		ClearOnInput.OnDeactivated(this, Player, Settings);
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Allow input, but rubber band back towards POI if we have valid clamps
		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		FRotator HerculePOIrot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);
		FRotator CurDesiredRot = User.WorldToLocalRotation(User.GetDesiredRotation());
	
		if (POI.PointOfInterest.bClearOnInput)
		{
			ClearOnInput.Update(DeltaTime, HerculePOIrot, Settings, GetAttributeVector2D(AttributeVectorNames::CameraDirection), User, Player);
			if (ClearOnInput.ShouldClear(Settings))
			{
				Player.ClearCurrentPointOfInterest();
				return;
			}
		}

		float BlendTime = POI.PointOfInterest.Blend.BlendTime; 
		float POITime = Time::GetGameTimeSince(POI.StartTime);

		FHazeCameraClampSettings Clamps = POI.PointOfInterest.Clamps;
		if (!Clamps.IsUsed())
			return;

		float InitialDampening = GetInitialDampening(BlendTime, POITime);

		// Use what desired rotation outside systems have set, but dampen that when nearing clamps 
		bool bWithinClamps = true;
		float YawDampening = GetClampsYawDampening(HerculePOIrot.Yaw, CurDesiredRot.Yaw, FocusRotationYaw.Value, Clamps, bWithinClamps);
		float ExternalYawDelta = FRotator::NormalizeAxis(CurDesiredRot.Yaw - FocusRotationYaw.Value);
		FocusRotationYaw.Value += ExternalYawDelta * FMath::Min(InitialDampening, YawDampening); 
		float PitchDampening = GetClampsPitchDampening(HerculePOIrot.Pitch, CurDesiredRot.Pitch, FocusRotationPitch.Value, Clamps, bWithinClamps);
		float ExternalPitchDelta = FRotator::NormalizeAxis(CurDesiredRot.Pitch - FocusRotationPitch.Value);
		FocusRotationPitch.Value += ExternalPitchDelta * FMath::Min(InitialDampening, PitchDampening); 

		// Check for input (or other external change of desired rotation)
		float CurRealTime = Time::GetRealTimeSeconds();
		if (!FMath::IsNearlyZero(FMath::Max(ExternalYawDelta, ExternalPitchDelta), 0.01f))
			LastInputTime = CurRealTime;

		// Accelerate towards POI when there is no input (or other external change) and blend time is valid
		if (!bWithinClamps || ((CurRealTime > LastInputTime + POI.PointOfInterest.InputPauseTime) && (BlendTime >= 0.f)))
		{
			float AccelerateDuration = FMath::Max(BlendTime * 2.f, 0.f);
			float TweakedYaw = FPointOfInterestStatics::GetYawByTurnDirection(HerculePOIrot.Yaw, FocusRotationYaw.Value, POI.PointOfInterest);
			FocusRotationYaw.AccelerateTo(TweakedYaw, AccelerateDuration, DeltaTime);
			float ShortestPathPitch = FocusRotationPitch.Value + FRotator::NormalizeAxis(HerculePOIrot.Pitch - FocusRotationPitch.Value);
			FocusRotationPitch.AccelerateTo(ShortestPathPitch, AccelerateDuration, DeltaTime);
		}
		else
		{
			FocusRotationYaw.Velocity = 0.f;
			FocusRotationPitch.Velocity = 0.f;
		}

		// Clamped POI always counts as matching angle when within clamps 
		if (bWithinClamps && (ClearOnInput.MatchedAngleDelayTime == 0.f))
			ClearOnInput.MatchedAngleDelayTime = Time::RealTimeSeconds + Settings.InputClearWithinAngleDelay;

		FRotator DeltaRot = (FRotator(FocusRotationPitch.Value, FocusRotationYaw.Value, 0.f) - CurDesiredRot);
		DeltaRot = FPointOfInterestStatics::ApplyTurnScaling(DeltaRot, POI.PointOfInterest);
		User.AddDesiredRotation(DeltaRot);
	}

	float GetInitialDampening(float BlendTime, float POITime)
	{
		// No dampening by default
		return 1.f;
	}
	
	float GetClampsYawDampening(float POIYaw, float ExternalYaw, float PrevYaw, const FHazeCameraClampSettings& Clamps, bool& bOutWithinClamps)
	{
		float POIDelta = FRotator::NormalizeAxis(ExternalYaw - POIYaw); 
		float CurrentDelta = FRotator::NormalizeAxis(ExternalYaw - PrevYaw); 
		if (!FMath::IsNearlyZero(CurrentDelta, 0.1f) && (FMath::Sign(CurrentDelta) != FMath::Sign(POIDelta)))
			return 1.f; // Turning towards POI

		if (Clamps.bUseClampYawRight && (POIDelta > 0.f))
			return GetClampDampening(Clamps.ClampYawRight, POIDelta, bOutWithinClamps);
		if (Clamps.bUseClampYawLeft && (POIDelta < 0.f))
			return GetClampDampening(Clamps.ClampYawLeft, -POIDelta, bOutWithinClamps);
		return 1.f;
	}

	float GetClampsPitchDampening(float POIPitch, float ExternalPitch, float PrevPitch, const FHazeCameraClampSettings& Clamps, bool& bOutWithinClamps)
	{
		float POIDelta = FRotator::NormalizeAxis(ExternalPitch - POIPitch); 
		float CurrentDelta = FRotator::NormalizeAxis(ExternalPitch - PrevPitch); 
		if ((CurrentDelta != 0.f) && (FMath::Sign(CurrentDelta) != FMath::Sign(POIDelta)))
			return 1.f; // Turning towards POI

		if (Clamps.bUseClampPitchUp && (POIDelta > 0.f))
			return GetClampDampening(Clamps.ClampPitchUp, POIDelta, bOutWithinClamps);
		if (Clamps.bUseClampPitchDown && (POIDelta < 0.f))
			return GetClampDampening(Clamps.ClampPitchDown, -POIDelta, bOutWithinClamps);
		return 1.f;
	}

	float GetClampDampening(float Clamp, float POIDelta, bool& bOutWithinClamps)
	{
		if (Clamp <= 0.f)
			return 0.f;

		if (POIDelta > Clamp)
		{
			bOutWithinClamps = false;
			return 0.f;
		}

		return FMath::Min(1.f, FMath::Square((Clamp - POIDelta) / Clamp));
	}
};
