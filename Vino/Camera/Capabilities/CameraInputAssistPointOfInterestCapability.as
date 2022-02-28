import Vino.Camera.Capabilities.CameraPointOfInterestCapability;

class UCameraInputAssistPointOfInterestCapability : UCameraPointOfInterestCapability
{
	float HasReceivedInputTimer = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkActivation::DontActivate;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::InputAssist))
			return EHazeNetworkActivation::DontActivate;
		if (User.IsAiming() && (GetPointOfInterestPriority() < EHazeCameraPriority::Script))
			return EHazeNetworkActivation::DontActivate;
		if(HasReceivedInputTimer > 0)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::InputAssist))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (User.IsAiming() && (GetPointOfInterestPriority() < EHazeCameraPriority::Script))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if(HasReceivedInputTimer > 0)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		HasReceivedInputTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!User.HasPointOfInterest(EHazePointOfInterestType::InputAssist))
			HasReceivedInputTimer = 0;

		Super::OnDeactivated(DeactivationParams);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		HasReceivedInputTimer = FMath::Max(HasReceivedInputTimer - DeltaTime, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(User.HasPointOfInterest(EHazePointOfInterestType::InputAssist))
		{
			const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			if(AxisInput.Size() > KINDA_SMALL_NUMBER)
			{
				HasReceivedInputTimer = FMath::Max(0.2f, User.GetPointOfInterest().PointOfInterest.InputPauseTime);
				return;
			}		
		}

		Super::TickActive(DeltaTime);
	}
}