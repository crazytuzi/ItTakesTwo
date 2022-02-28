import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Cannon.CourtyardCannonShootCapability;

class UCourtyardCannonCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::SlopeSlide);

	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;

	FAcceleratedCameraDesiredRotation AcceleratedCameraDesiredRotation;
	default AcceleratedCameraDesiredRotation.CooldownPostInput = 0;
	default AcceleratedCameraDesiredRotation.AcceleratedRotationDuration = 0.5;

	

	FHazeAcceleratedRotator AcceleratedDesiredRotation;
	FVector DefaultPivotOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(UCourtyardCannonShootCapability::StaticClass()))
        	return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(UCourtyardCannonShootCapability::StaticClass()))
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
		AcceleratedCameraDesiredRotation.Reset(CameraComp.WorldRotation);

		//Player.ApplyCameraSettings(SplineSlideComp.CameraSettings, FHazeCameraBlendSettings(1.f), this, EHazeCameraPriority::Script);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FVector Input = GetAttributeVector(AttributeVectorNames::RightStickRaw);

		FVector DesiredDirection = MoveComp.Velocity;
		if (DesiredDirection.IsNearlyZero())
			DesiredDirection = Owner.ActorForwardVector;
		//DesiredDirection.Z *= 0.8f;

		FRotator DesiredRotation = FRotator::MakeFromX(DesiredDirection);
		// DesiredRotation.Pitch -= 10.f;

		CameraUser.DesiredRotation = AcceleratedCameraDesiredRotation.Update(CameraUser.DesiredRotation, DesiredRotation, Input, DeltaTime);
	}
}