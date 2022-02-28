import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Grinding.UserGrindComponent;

class UCharacterStrafeTurnAroundCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;
	UUserGrindComponent GrindComp;

	const float TurnAroundDuration = 0.3f;

	FRotator StartingRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GrindComp.IsGrindingActive())
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementStrafeTurnAround))
        	return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponAim))
        	return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (AngleToTarget > 1.f)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StartingRotation = CameraUser.DesiredRotation;
		TargetRotation =  StartingRotation + FRotator(0.f, 180.01f, 0.f);

		FRotator DeltaRotation = StartingRotation - TargetRotation;
		DeltaRotation.Normalize();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FRotator YawRotation = FMath::RInterpTo(CameraUser.DesiredRotation, TargetRotation, DeltaTime, 12.f);
		FRotator NewRotation(CameraUser.DesiredRotation.Pitch, YawRotation.Yaw, CameraUser.DesiredRotation.Roll);
		CameraUser.DesiredRotation = NewRotation;		
	}

	float GetAngleToTarget() const property
	{
		FVector CurrentForward = CameraUser.DesiredRotation.ForwardVector.ConstrainToPlane(FVector::UpVector);
		FVector TargetForward = TargetRotation.ForwardVector.ConstrainToPlane(FVector::UpVector);
		float Angle = CurrentForward.AngularDistance(TargetForward) * RAD_TO_DEG;

		return Angle;
	}
}