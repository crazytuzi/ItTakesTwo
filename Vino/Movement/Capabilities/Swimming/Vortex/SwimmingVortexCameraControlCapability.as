import Vino.Camera.Components.CameraUserComponent;
import Peanuts.Containers.BlendedCurvesContainer;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingVortexCameraControlCapability : UHazeCapability
{
	UCameraUserComponent User;

	float AccelerationThreshold = 0.001f;
	FVector2D InputDuration = FVector2D::ZeroVector;  

	FBlendedCurvesContainer YawAccelerationCurves;
	FBlendedCurvesContainer PitchAccelerationCurves;
	default YawAccelerationCurves.DefaultValue = 1.f;
	default PitchAccelerationCurves.DefaultValue = 1.f;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::Control);
	default CapabilityTags.Add(n"PlayerDefault"); 
	
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Vortex);
	default CapabilityTags.Add(SwimmingTags::Camera);

	default CapabilityTags.Add(n"Input");
	default CapabilityTags.Add(n"StickInput");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 99;

	USnowGlobeSwimmingComponent SwimComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{			
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bVortexActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!SwimComp.bVortexActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
		{
			User.RegisterDesiredRotationReplication(this);
			User.InputControllers.Add(this);
		}

		Owner.BlockCapabilities(CameraTags::Control, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
		{
			User.UnregisterDesiredRotationReplication(this);
			User.InputControllers.Remove(this);
		}

		Owner.UnblockCapabilities(CameraTags::Control, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Ignore on remote side; control rotation is replicated
		if(!HasControl())
			return;
		
		const float TimeDilation = Owner.GetActorTimeDilation();
		const float UndilatedDeltaTime = TimeDilation > 0.f ? DeltaTime / TimeDilation : 1.f; // We could save real time i between ticks instead, but probably not necessary

		const FVector CameraInput = GetAttributeVector(AttributeVectorNames::CameraDirection);	
		const FVector MovementInput = FVector(GetAttributeVector(AttributeVectorNames::MovementRaw).Y, 0.f, 0.f);

		const FVector Input =  (CameraInput + MovementInput).GetClampedToMaxSize(1.f);
		const FVector2D AxisInput = FVector2D(Input.X, Input.Y); 

		FRotator TurnRate = User.GetCameraTurnRate();

		// Get camera settings
		FHazeCameraSettings Settings;
		User.GetCameraSettings(Settings);

		UpdateAccelerationCurves(Settings, DeltaTime);
		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		if ((PlayerOwner != nullptr) && (PlayerOwner.IsUsingGamepad()))
		{
			// Accelerate input over time, using curve (e.g. Blueprints/Input/Curve_CameraAcceleration_Yaw)
			InputDuration.X += UndilatedDeltaTime;
			if (FMath::Abs(AxisInput.X) < AccelerationThreshold) 
				InputDuration.X = 0.f;
			TurnRate.Yaw *= YawAccelerationCurves.GetFloatValue(InputDuration.X);
			InputDuration.Y += UndilatedDeltaTime;
			if (FMath::Abs(AxisInput.Y) < AccelerationThreshold) 
				InputDuration.Y = 0.f;
			TurnRate.Pitch *= PitchAccelerationCurves.GetFloatValue(InputDuration.Y);
		}

		FRotator DeltaRotation = FRotator::ZeroRotator;
		DeltaRotation.Yaw = AxisInput.X * UndilatedDeltaTime * TurnRate.Yaw;
		DeltaRotation.Pitch = AxisInput.Y * UndilatedDeltaTime * TurnRate.Pitch;
		User.AddDesiredRotation(DeltaRotation);
	}

	void UpdateAccelerationCurves(const FHazeCameraSettings& Settings, float DeltaTime)
	{
		float BlendTime = User.GetSettingsManager().GetCurrentBlendTime();
		YawAccelerationCurves.SetTargetCurve(Settings.InputAccelerationCurveYaw, BlendTime);
		YawAccelerationCurves.Update(DeltaTime);
		PitchAccelerationCurves.SetTargetCurve(Settings.InputAccelerationCurvePitch, BlendTime);
		PitchAccelerationCurves.Update(DeltaTime);
	}
};