import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.LevelSpecific.Tree.DarkRoom.FlyingAnimalRide;
import Vino.Camera.Capabilities.CameraTags;

class UFlyingAnimalRideChaseCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::ChaseAssistance);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 150;
    default CapabilityDebugCategory = CameraTags::Camera;

	FHazeAcceleratedRotator ChaseRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (!IsUsingFlyingAnimalRideCamera())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	bool IsUsingFlyingAnimalRideCamera() const
	{
		UHazeCameraComponent CurCamera = PlayerUser.GetCurrentlyUsedCamera();
		if(CurCamera == nullptr)
			return false;
			
		return CurCamera.GetOwner().IsA(UFlyingAnimalRide::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!IsUsingFlyingAnimalRideCamera())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);
		ChaseRotation.SnapTo(GetTargetRotationLocal());

		// Use local camera simulation
		PlayerUser.BlockCameraSyncronization(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);
		PlayerUser.UnblockCameraSyncronization(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Local camera simulation
		float TimeDilation = PlayerUser.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;

		FRotator DesiredRot = User.WorldToLocalRotation(User.DesiredRotation);
		ChaseRotation.Value = DesiredRot; // This is expected to be changed by other system
		ChaseRotation.AccelerateTo(GetTargetRotationLocal(), 5.f, DeltaTime);
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRot).GetNormalized();
		User.AddDesiredRotation(DeltaRot);
	}

	FRotator GetTargetRotationLocal()
	{
		UHazeCameraComponent CurCamera = PlayerUser.GetCurrentlyUsedCamera();
		if (!ensure(CurCamera != nullptr))
			return FRotator::ZeroRotator;

		FRotator Rot = User.WorldToLocalRotation(CurCamera.GetOwner().GetActorRotation());
		Rot.Roll = 0.f;
		Rot.Pitch += -30.f;
		return Rot;
	}
}