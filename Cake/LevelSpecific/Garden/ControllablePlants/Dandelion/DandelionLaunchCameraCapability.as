import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionTags;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;

class UDandelionLaunchCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DandelionCamera");

	FHazeAcceleratedRotator ChaseRotation;

	ADandelion Dandelion;
	UCameraUserComponent User;
	UControllablePlantsComponent PlantsComp;

	float CurrentPitch = 0.0f;
	float CurrentTime = 0.0f;
	float TargetTime = 2.8f;

	bool bFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlantsComp = UControllablePlantsComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentTime = 0.0f;
		bFinished = false;
		ChaseRotation.Velocity = 0.0f;
		Dandelion = Cast<ADandelion>(PlantsComp.CurrentPlant);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ADandelion TempDand = Cast<ADandelion>(PlantsComp.CurrentPlant);

		if(TempDand == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if(!TempDand.bActivateLaunchCamera)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bFinished)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Dandelion.bActivateLaunchCamera = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);

		if(AxisInput.Size() > 0.0f)
		{
			bFinished = true;
		}

		FRotator TargetRotation = User.WorldToLocalRotation(FRotator(-30.0f, 0.0f, 0.0f));

		FRotator DesiredRotation = User.WorldToLocalRotation(User.GetDesiredRotation());
		ChaseRotation.Value = DesiredRotation;

		ChaseRotation.AccelerateTo(TargetRotation, TargetTime, DeltaTime);
		
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRotation).GetNormalized();

		DeltaRot.Roll = 0.0f;
		DeltaRot.Yaw = 0.0;

		User.AddDesiredRotation(DeltaRot);

		CurrentTime += DeltaTime;
		if(CurrentTime > TargetTime)
		{
			bFinished = true;
		}
	}
}
