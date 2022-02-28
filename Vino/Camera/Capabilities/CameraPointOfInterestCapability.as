import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.PointOfInterest.PointOfInterestStatics;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Settings.CameraPointOfInterestBehaviourSettings;

class UCameraPointOfInterestCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter Player;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::PointOfInterest);

	default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	UCameraPointOfInterestBehaviourSettings Settings;

	FHazeAcceleratedFloat FocusRotationYaw;
	FHazeAcceleratedFloat FocusRotationPitch;

	FPointOfInterestStatics::FClearOnInput ClearOnInput;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(User.GetOwner());
		Settings = UCameraPointOfInterestBehaviourSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkActivation::DontActivate;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::Forced))
			return EHazeNetworkActivation::DontActivate;
		if (User.IsAiming() && (GetPointOfInterestPriority() < EHazeCameraPriority::Script))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::Forced))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (User.IsAiming() && (GetPointOfInterestPriority() < EHazeCameraPriority::Script))
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	EHazeCameraPriority GetPointOfInterestPriority() const
	{
		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		return POI.Priority;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		User.RegisterDesiredRotationReplication(this);

		FRotator LocalRot = User.WorldToLocalRotation(User.GetDesiredRotation());
		FRotator LocalRotVelocity = User.WorldToLocalRotation(User.GetDesiredRotationVelocity());

		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		if (POI.PointOfInterest.Blend.BlendTime == 0.f)
		{
			LocalRot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);	
			LocalRotVelocity = FRotator::ZeroRotator;
		}

		FocusRotationYaw.Value = LocalRot.Yaw;
		FocusRotationYaw.Velocity = LocalRotVelocity.Yaw; 
		FocusRotationPitch.Value = LocalRot.Pitch;
		FocusRotationPitch.Velocity = LocalRotVelocity.Pitch; 

		ClearOnInput.OnActivated(POI.PointOfInterest.bClearOnInput, this, Player, Settings);

		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.BlockCapabilities(CameraTags::VehicleChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClearOnInput.OnDeactivated(this, Player, Settings);
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.UnblockCapabilities(CameraTags::VehicleChaseAssistance, this);
		User.UnregisterDesiredRotationReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		FRotator HerculePOIrot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);

		if (POI.PointOfInterest.bClearOnInput)
		{
			ClearOnInput.Update(DeltaTime, HerculePOIrot, Settings, GetAttributeVector2D(AttributeVectorNames::CameraDirection), User, Player);
			if (ClearOnInput.ShouldClear(Settings))
			{
				Player.ClearCurrentPointOfInterest();
				return;
			}
		}

		// Force camera direction towards point of interest over blend time.
		float Duration = FMath::Max(0.f, POI.PointOfInterest.Blend.BlendTime); 
		if (!POI.PointOfInterest.bMatchFocusDirection)
			Duration *= 0.8f; // When we aim against a location, the target rotation will change over time, so duration needs to be shorter to compensate. TODO: Fix!

		float TweakedYaw = FPointOfInterestStatics::GetYawByTurnDirection(HerculePOIrot.Yaw, FocusRotationYaw.Value, POI.PointOfInterest);
		FocusRotationYaw.AccelerateTo(TweakedYaw, Duration, DeltaTime);
		float ShortestPathPitch = FocusRotationPitch.Value + FRotator::NormalizeAxis(HerculePOIrot.Pitch - FocusRotationPitch.Value);
		FocusRotationPitch.AccelerateTo(ShortestPathPitch, Duration, DeltaTime);

		FRotator CurDesiredRot = User.WorldToLocalRotation(User.GetDesiredRotation());
		FRotator DeltaRot = (FRotator(FocusRotationPitch.Value, FocusRotationYaw.Value, 0.f) - CurDesiredRot);
		DeltaRot = FPointOfInterestStatics::ApplyTurnScaling(DeltaRot, POI.PointOfInterest);
		User.AddDesiredRotation(DeltaRot);
	}
};
