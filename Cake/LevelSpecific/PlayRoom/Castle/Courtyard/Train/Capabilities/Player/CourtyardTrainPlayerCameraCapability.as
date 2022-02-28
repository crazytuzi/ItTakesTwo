import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainUserComponent;
import Vino.Camera.Components.CameraUserComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainTrack;

class UCourtyardTrainPlayerCameraCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Camera);
	
	default TickGroup = ECapabilityTickGroups::PostWork;
	default TickGroupOrder = 150;

	default CapabilityDebugCategory = CapabilityTags::Camera;

	AHazePlayerCharacter Player;
	UCourtyardTrainUserComponent TrainComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;

	FAcceleratedCameraDesiredRotation AcceleratedCameraDesiredRotation;
	//FHazeAcceleratedRotator RemoteAcceleratedRotation;

	default AcceleratedCameraDesiredRotation.AcceleratedRotationDuration = 0.35f;
	default AcceleratedCameraDesiredRotation.CooldownPostInput = 0.25f;
	default AcceleratedCameraDesiredRotation.InputScaleInterpSpeed = 0.1f;

	ACourtyardTrainTrack Track;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrainComp = UCourtyardTrainUserComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		CameraComp = UCameraComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TrainComp.State == ECourtyardTrainState::Inactive)
        	return EHazeNetworkActivation::DontActivate;

		if (TrainComp.Train == nullptr && TrainComp.Carriage == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (TrainComp.InteractionComp == nullptr)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		if (TrainComp.State == ECourtyardTrainState::Train)
		{
			Track = TrainComp.Train.Track;
		}
		else if (TrainComp.State == ECourtyardTrainState::Carriage)
		{
			Track = TrainComp.Carriage.Track;
		}
		
		Player.BlockCameraSyncronization(this);
		
		AcceleratedCameraDesiredRotation.Reset(CameraComp.WorldRotation);
		
		// Activate third person camera
		//TrainComp.bFirstPersonCameraActive = false;
		if (TrainComp.ThirdPersonCameraSettings != nullptr)
			Player.ApplyCameraSettings(TrainComp.ThirdPersonCameraSettings, FHazeCameraBlendSettings(0.8f), this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);

		Player.ClearCameraSettingsByInstigator(this, 0.8f);

		Player.UnblockCameraSyncronization(this);
		
		//CameraUser.SetYawAxis(FVector::UpVector);
		Track = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//UpdateYawAxis();
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FHazeSplineSystemPosition PlayerPosition = Track.Spline.GetPositionClosestToWorldLocation(Owner.ActorLocation);

		FVector ToCamera = Player.ViewLocation - PlayerPosition.WorldLocation;
		float CameraHeight = PlayerPosition.WorldUpVector.DotProduct(ToCamera);

		PlayerPosition.Move(500.f);

		FVector ToPlayer = Owner.ActorLocation - PlayerPosition.WorldLocation;
		FVector LookAtLocation = PlayerPosition.WorldLocation;
		LookAtLocation += PlayerPosition.WorldUpVector * CameraHeight * 0.75f;

		if (IsDebugActive())
			System::DrawDebugSphere(LookAtLocation, 20.f, 10, FLinearColor::Red, 0.f, 2.f);

		FVector ToLookAt = LookAtLocation - Player.ViewLocation;
		FVector Input = GetAttributeVector(AttributeVectorNames::RightStickRaw);
		FRotator DesiredRotation = FRotator::MakeFromX(ToLookAt);

		CameraUser.DesiredRotation = AcceleratedCameraDesiredRotation.Update(CameraUser.DesiredRotation, DesiredRotation, Input, DeltaTime);
	}
}