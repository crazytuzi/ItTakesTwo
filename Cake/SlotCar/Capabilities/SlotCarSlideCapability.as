import Cake.SlotCar.SlotCarActor;
import Cake.SlotCar.SlotCarSettings;

class USlotCarSlideCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SlotCar");
	default CapabilityTags.Add(n"SlotCarMovement");
	default CapabilityTags.Add(n"SlotCarSlide");

	default CapabilityDebugCategory = n"SlotCar";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	ASlotCarActor SlotCar;
	FVector MeshRelativeLocation;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SlotCar = Cast<ASlotCarActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SlotCar.AcceleratedYaw.SnapTo(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FRotator NewRotation = FRotator(0.f, 0.f, 0.f);
		SlotCar.CarBody.SetRelativeRotation(NewRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//float TopSpeed = (SlotCarSettings::Speed.Acceleration - SlotCarSettings::Speed.Deceleration) / SlotCarSettings::Speed.Drag;
		float TopSpeed = 3400.f;
		float TopSpeedPercentage = FMath::Max(SlotCar.CurrentSpeed / TopSpeed, 0.f);
		SlotCar.AcceleratedYaw.Velocity += SlotCar.RotationLastFrame * 10.5f * FMath::Pow(TopSpeedPercentage, 4.f);
		SlotCar.AcceleratedYaw.SpringTo(0.f, 150.f, 0.75f, DeltaTime);

		FRotator NewRotation = FRotator(0.f, SlotCar.AcceleratedYaw.Value, 0.f);
		SlotCar.CarBody.SetRelativeRotation(NewRotation);

		if (IsDebugActive())
		{
			System::DrawDebugLine(SlotCar.ActorLocation, SlotCar.ActorLocation + ((SlotCar.ActorTransform.TransformVector(NewRotation.ForwardVector)) * 250.f), FLinearColor::Green, 0.f, 12.f);
			System::DrawDebugLine(SlotCar.ActorLocation, SlotCar.ActorLocation + SlotCar.ActorForwardVector * 250.f, FLinearColor::Red, 0.f, 12.f);

			PrintToScreenScaled("CurrentSpeed: " + SlotCar.CurrentSpeed, Color = FLinearColor::LucBlue, Scale = 2.f);
			PrintToScreenScaled("Velocity: " + SlotCar.AcceleratedYaw.Velocity, Color = FLinearColor::Green, Scale = 2.f);
			PrintToScreenScaled("Yaw: " + SlotCar.AcceleratedYaw.Value, Color = FLinearColor::Red, Scale = 2.f);
		}

		// Force Feedback
		float YawAbs = FMath::Abs(SlotCar.AcceleratedYaw.Value);
		float YawPercentage = FMath::Clamp(YawAbs / SlotCarSettings::Slide.AngleMax, 0.f, 1.f);
		float SmallForceFeedbackValue = (YawPercentage - 0.1f) / (1.f - 0.1f);
		SlotCar.HazeAkComp.SetRTPCValue("Rtpc_World_Shared_SideContent_SlotCars_SkidAmount", YawPercentage);
		//PrintToScreen("Skid: " + YawPercentage, 0.f);
		//SmallForceFeedbackValue = 1.f;
		float LargeForceFeedbackValue = SmallForceFeedbackValue * 0.5f;
		SlotCar.OwningPlayer.SetFrameForceFeedback(LargeForceFeedbackValue, SmallForceFeedbackValue);
	}
}