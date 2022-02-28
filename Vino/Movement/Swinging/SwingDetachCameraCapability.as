import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;
import Vino.Movement.Swinging.SwingComponent;

class USwingDetachCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Swinging);
	default CapabilityTags.Add(n"SwingingCamera");

	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 100;
	AHazePlayerCharacter Player;
	USwingingComponent SwingingComponent;
	UHazeMovementComponent MoveComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;

	FAcceleratedCameraDesiredRotation AcceleratedDesiredRotation;
	default AcceleratedDesiredRotation.AcceleratedRotationDuration = 1.75f;
	
	const float Duration = 1.5f;
	const float DesiredZScale = 0.4f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(n"SwingingDetach"))
        	return EHazeNetworkActivation::DontActivate;

		if (SwingingComponent.PreviousSwingPoint == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (!SwingingComponent.PreviousSwingPoint.CameraSettings.bUseDetchCamera)
        	return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(MovementSystemTags::AirMovement))
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration >= Duration)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		AcceleratedDesiredRotation.Reset(CameraUser.DesiredRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateDesiredPitch(DeltaTime);
	}

	void UpdateDesiredPitch(float DeltaTime)
	{
		FVector CameraInput = GetAttributeVector(AttributeVectorNames::CameraDirection);

		FVector DesiredDirection = MoveComp.Velocity;
		DesiredDirection.Z *= DesiredZScale;
		DesiredDirection.Z = FMath::Min(DesiredDirection.Z, 0.f);
		FRotator DesiredRotation = FRotator::MakeFromX(DesiredDirection);

		AcceleratedDesiredRotation.Update(CameraUser.DesiredRotation, DesiredRotation, CameraInput, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedDesiredRotation.GetValue();
	}
}