import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Camera.Settings.CameraLazyChaseSettings;

class UTomatoCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::Camera);

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::GamePlay;
	
	ATomato Tomato;
	AHazePlayerCharacter Player;
	UCameraUserComponent User;
	UControllablePlantsComponent PlantComp;
	UCameraLazyChaseSettings Settings;

	float NoInputDuration = 0.0f;
	float MovementDuration = 0.0f;

	float NoInputScalar = 1.0f;

	FHazeAcceleratedRotator ChaseRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		User = UCameraUserComponent::Get(Owner);
		PlantComp = UControllablePlantsComponent::Get(Owner);
		Settings = UCameraLazyChaseSettings::GetSettings(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(PlantComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlantComp.CurrentPlant.IsA(ATomato::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);

		Tomato = Cast<ATomato>(PlantComp.CurrentPlant);

		if(Tomato.CameraLazyChaseSettings != nullptr)
		{
			Owner.ApplySettings(Tomato.CameraLazyChaseSettings, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if(PlantComp.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(Tomato.CameraLazyChaseSettings != nullptr)
		{
			Owner.ClearSettingsByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeDilation = Owner.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
		UpdateInputDuration(RealTimeDeltaSeconds);

		if(NoInputDuration < Settings.CameraInputDelay)
		{
			ChaseRotation.Value = 0.0f;
			ChaseRotation.Velocity = 0.0f;
			return;
		}

		FRotator WantRotation = User.WorldToLocalRotation(GetTargetRotation());
		WantRotation.Pitch = FMath::Clamp(WantRotation.Pitch, -50.0f, 10.0f);
		FRotator DesiredRotation = User.WorldToLocalRotation(User.GetDesiredRotation());

		ChaseRotation.Value = DesiredRotation;

		float SpeedFactor = 1.f;
		if (Settings.ChaseFactorByAngleCurve != nullptr)
		{
			float AngleDiff = FMath::Abs(FRotator::NormalizeAxis(WantRotation.Yaw - DesiredRotation.Yaw));
			SpeedFactor *= Settings.ChaseFactorByAngleCurve.GetFloatValue(AngleDiff);
		}
		
		if (SpeedFactor < 0.01f)
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}

		if ((MovementDuration > Settings.MovementInputDelay))
		{
			ChaseRotation.AccelerateTo(WantRotation, GetAccelerationDuration(), DeltaTime);
		}
		else
		{
			ChaseRotation.Velocity -= ChaseRotation.Velocity * 10.f * DeltaTime;
			ChaseRotation.Value += ChaseRotation.Velocity * DeltaTime;
		}

		FRotator DeltaRot = (ChaseRotation.Value - DesiredRotation).GetNormalized();// * NoInputScalar;
		
		DeltaRot.Roll = 0.f;

		User.AddDesiredRotation(DeltaRot);
	}

	FRotator GetTargetRotation() const
	{
		const float PitchOffset = -20.0f;

		if(Tomato.GetCurrentMovementDirection() < 0.0f)
		{
			FRotator WantRotation = Tomato.GetTargetRotation();
			return FRotator(WantRotation.Pitch + PitchOffset, WantRotation.Yaw - 180.0f, WantRotation.Roll);
		}

		FRotator TargetWorldRotation = Tomato.GetTargetRotation();
		TargetWorldRotation.Pitch += PitchOffset;

		return TargetWorldRotation;
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		NoInputDuration = (AxisInput.IsNearlyZero(0.001f) ? NoInputDuration + DeltaTime : 0.0f);
		MovementDuration = (IsMoving() ? MovementDuration + DeltaTime : 0.0f);
		NoInputScalar = IsMoving() ? 1.0f : NoInputScalar - NoInputScalar * 0.01f * DeltaTime;
	}

	bool IsMoving() const
	{
		return !FMath::IsNearlyZero(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Size());
	}

	float GetAccelerationDuration() const
	{
		return Settings.AccelerationDuration;
	}
}
