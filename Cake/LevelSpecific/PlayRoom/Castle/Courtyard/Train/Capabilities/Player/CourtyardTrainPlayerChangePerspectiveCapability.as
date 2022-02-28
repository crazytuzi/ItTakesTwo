import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainUserComponent;
class UCourtyardTrainPlayerChangePerspectiveCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Camera);
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 150;

	default CapabilityDebugCategory = CapabilityTags::Camera;

	AHazePlayerCharacter Player;
	UCourtyardTrainUserComponent TrainComp;
	UCameraUserComponent CameraUser;

	UPROPERTY()
	FHazeTimeLike YawAxisTimelike;
	default YawAxisTimelike.Duration = 0.8f;

	AHazeActor Vehicle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrainComp = UCourtyardTrainUserComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);

		YawAxisTimelike.BindUpdate(this, n"YawAxisTimelikeUpdate");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TrainComp.InteractionComp == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (TrainComp.State == ECourtyardTrainState::Inactive)
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::InteractionTrigger))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (TrainComp.InteractionComp == nullptr)
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WasActionStarted(ActionNames::InteractionTrigger))
        	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (TrainComp.State == ECourtyardTrainState::Train)
			Vehicle = TrainComp.Train;
		else if (TrainComp.State == ECourtyardTrainState::Carriage)
			Vehicle = TrainComp.Carriage;

		if (TrainComp.FirstPersonCameraSettings != nullptr)
			Player.ApplyCameraSettings(TrainComp.FirstPersonCameraSettings, FHazeCameraBlendSettings(0.8f), this, EHazeCameraPriority::High);

		YawAxisTimelike.Play();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		YawAxisTimelike.Reverse();

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		// Reset to make sure it doesnt get stuck outside of the level
		CameraUser.SetYawAxis(FVector::UpVector);
	}

	UFUNCTION()
	void YawAxisTimelikeUpdate(float Value)
	{
		// Run it in update too, so it updates the yaw axis while the capability is inactive
		// Figured this was safer than doing some PreTick logic
		UpdateYawAxisToFirstPerson();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateYawAxisToFirstPerson();
	}

	void UpdateYawAxisToFirstPerson()
	{		
		FTransform VehicleTransform = Vehicle.ActorTransform;
		if (TrainComp.Carriage != nullptr)
			VehicleTransform = TrainComp.Carriage.ActorTransform;

		FVector VehicleYawAxis = VehicleTransform.Rotation.UpVector;
		FVector YawAxis = FMath::Lerp(FVector::UpVector, VehicleYawAxis, YawAxisTimelike.Value);

		CameraUser.SetYawAxis(YawAxis);
	}
}