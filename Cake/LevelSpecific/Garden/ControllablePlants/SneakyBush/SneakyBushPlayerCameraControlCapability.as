import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraControlCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;


class USneakyBushPlayerCameraControlCapability : UCameraControlCapability
{
	const float LerpSpeed = 10.f;
	const float PitchDownAmount = 35.f;
	const float PitchOffsetClamps = 20;
	const float UpwardTraceLength = 500;

	float CurrentPitch = 0;

	UControllablePlantsComponent PlantsComponent;
	ASneakyBush Bush;
	float TraceLengthAlpha = 1.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		PlantsComponent = UControllablePlantsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		CurrentPitch = User.CurrentDesiredRotation.Pitch;
		Bush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);
		TraceLengthAlpha = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(Bush.MovementComp);
		TraceParams.IgnoreActor(Game::GetCody());
		TraceParams.IgnoreActor(Game::GetMay());
		TraceParams.From = User.CurrentCamera.GetWorldLocation();
		TraceParams.To = TraceParams.From;
		TraceParams.To.Z += UpwardTraceLength;
		
		const float RequiredCollisionLength = 0.5f;
		
		FHazeHitResult Hit;
		if(TraceParams.Trace(Hit) && Hit.Time < RequiredCollisionLength)
		{
			float WantedAlpha = FMath::Lerp(0.f, 1.f, Hit.Time * 2);
			TraceLengthAlpha = FMath::FInterpTo(TraceLengthAlpha, WantedAlpha, DeltaTime, 2.f);
		}
		else
		{
			TraceLengthAlpha = FMath::FInterpConstantTo(TraceLengthAlpha, 1.f, DeltaTime, 0.5f);
		}

		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		float WantedPitch = -PitchDownAmount;
		//WantedPitch += AxisInput.Y * PitchOffsetClamps;
		//WantedPitch += FMath::Lerp(50.f, 0.f, TraceLengthAlpha);
		CurrentPitch = FMath::FInterpTo(CurrentPitch, WantedPitch, DeltaTime, LerpSpeed);


		Super::TickActive(DeltaTime);
	}

	FRotator GetFinalizedDeltaRotation(FRotator InRotation)
	{
		FRotator NewDeltaRotation = InRotation;
		NewDeltaRotation.Pitch = (CurrentPitch - User.CurrentDesiredRotation.Pitch);
		return InRotation;
	}
}