import Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer;
import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;
import Vino.Camera.Components.CameraUserComponent;

class UMinigameVolleyballVolleyballCameraControlCapability : UHazeCapability
{
	UCameraUserComponent User;
	UMinigameVolleyballPlayerComponent VolleyballComponent;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::Control);
	default CapabilityTags.Add(n"PlayerDefault"); 

	default CapabilityTags.Add(n"Input");
	//default CapabilityTags.Add(n"StickInput");

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	const float LerpSpeed = 10.f;
	const float PitchDownAmount = 18.f;
	const float FocusOffset = 2500;
	const float YawOffset = 0.f;
	const FVector2D InputFocusOffset(600, 20);

	AHazePlayerCharacter Player;
	FHazeAcceleratedRotator AcceleratedCameraRot;
	FRotator LastWantedRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		User = UCameraUserComponent::Get(Owner);
		VolleyballComponent = UMinigameVolleyballPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings Blend;
		Player.ApplyCameraSettings(VolleyballComponent.CameraSettings, Blend, this);

		if (User != nullptr)
		{
			User.RegisterDesiredRotationReplication(this);
			User.InputControllers.Add(this);
		}
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);

		if (User != nullptr)
		{
			User.UnregisterDesiredRotationReplication(this);
			User.InputControllers.Remove(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Ignore on remote side; control rotation is replicated
		if(!HasControl())
			return;

		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		FVector FocusLocation = VolleyballComponent.Field.NetCollision.GetWorldLocation();
		FVector CameraLocation = User.GetCurrentCamera().GetWorldLocation();

		FRotator CurrentRotation = User.GetDesiredRotation();
		FRotator WantedRotation = GetFocusDirection().ToOrientationRotator();
		WantedRotation.Roll = 0;
		WantedRotation.Pitch = -PitchDownAmount;
		WantedRotation.Pitch += AxisInput.Y * InputFocusOffset.Y;
		WantedRotation.Yaw += YawOffset;
		WantedRotation = FMath::RInterpTo(CurrentRotation, WantedRotation, DeltaTime, LerpSpeed);
		User.SetDesiredRotation(WantedRotation);
	}

	FVector GetFocusDirection() const
	{
		const FTransform FieldTransform = VolleyballComponent.Field.GetFieldTransformForPlayer(Player);

		FVector FocusLocation = VolleyballComponent.Field.NetCollision.GetWorldLocation();
		FocusLocation += FieldTransform.Rotation.ForwardVector * FocusOffset;

		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		FocusLocation += FieldTransform.Rotation.RightVector * AxisInput.X * InputFocusOffset.X;

		FVector CameraLocation = Owner.GetActorLocation();
		return (FocusLocation - CameraLocation).GetSafeNormal();
	}
}