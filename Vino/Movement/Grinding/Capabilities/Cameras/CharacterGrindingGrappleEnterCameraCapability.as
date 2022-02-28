import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.SplineLock.SplineLockComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;

class UCharacterGrindingGrappleEnterCameraCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grappling);

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Camera);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	USplineLockComponent SplineLockComp;
	UHazeMovementComponent MoveComp;
	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;

	FVector CameraLookAtLocation;

	FAcceleratedCameraDesiredRotation AcceleratedDesiredRotation;
	default AcceleratedDesiredRotation.AcceleratedRotationDuration = 3.f;

	FVector DefaultPivotOffset;

	FHazeAcceleratedFloat AcceleratedLookAtScale;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);

		FHazeCameraSpringArmSettings Settings;
		CameraUser.GetCameraSpringArmSettings(Settings);
		DefaultPivotOffset = Settings.PivotOffset;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!Player.IsAnyCapabilityActive(GrindingCapabilityTags::Grapple))
       		return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.TargetGrindSplineData.GrindSpline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(GrindingCapabilityTags::Grapple))
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (UserGrindComp.TargetGrindSplineData.GrindSpline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedDesiredRotation.Reset(CameraUser.DesiredRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CameraComp.SetRelativeRotation(FRotator::ZeroRotator);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateCameraLookAtLocation();
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateCameraLookAtLocation()
	{
		FHazeSplineSystemPosition CameraLookAtSystemPosition = UserGrindComp.TargetGrindSplineData.SystemPosition;
				
		float Remainder = 0.f;
		if (!CameraLookAtSystemPosition.Move(GrindSettings::Grapple.CameraLookAtDistanceAlongSpline, Remainder))
			CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation + (CameraLookAtSystemPosition.WorldForwardVector * Remainder);
		else
			CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation;

		CameraLookAtLocation += UserGrindComp.TargetGrindSplineData.SystemPosition.WorldUpVector * GrindSettings::Grapple.CameraLookAtAdditionalHeight;

		if (IsDebugActive())
			System::DrawDebugSphere(CameraLookAtLocation, 30.f, 12, FLinearColor::Green, 0.f);
	}	

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FVector CameraLocation = Player.ActorLocation;

		FVector DesiredDirection = CameraLookAtLocation - CameraLocation;
		DesiredDirection = UserGrindComp.TargetGrindSplineData.SystemPosition.WorldForwardVector;

		DesiredDirection.Z *= 0.8f;
		FRotator DesiredRotation = Math::MakeRotFromX(DesiredDirection);
		DesiredRotation.Roll = 0.f;

		FVector CameraInput = GetAttributeVector(AttributeVectorNames::CameraDirection);
		CameraUser.DesiredRotation = AcceleratedDesiredRotation.Update(CameraUser.DesiredRotation, DesiredRotation, CameraInput, DeltaTime);
	}
}
