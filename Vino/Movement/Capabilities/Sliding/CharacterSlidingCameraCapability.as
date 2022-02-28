import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Sliding.SlidingNames;

class UCharacterSlidingCameraCapability : UHazeCapability
{
	default RespondToEvent(SlidingActivationEvents::NormalSliding);

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::SlopeSlide);

	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCharacterSlidingComponent SlidingComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	FVector DefaultPivotOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		SlidingComp = UCharacterSlidingComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (SlidingComp == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (!SlidingComp.bIsSliding)
        	return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SlidingComp == nullptr)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (!SlidingComp.bIsSliding)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);
		FHazeCameraSpringArmSettings Settings;
		CameraUser.GetCameraSpringArmSettings(Settings);
		DefaultPivotOffset = Settings.PivotOffset;
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
		UpdatePivotOffset();
		UpdateDesiredRotation(DeltaTime);
		
		//FVector Offset = ((Owner.ActorForwardVector * Input.Y) + (Owner.ActorRightVector * Input.X)) * 500.f;
		/*FVector Offset = MoveInput * 400.f;
		FVector LookAtLocation = Owner.ActorLocation + Offset;
		FVector ToTarget = LookAtLocation - CameraComp.WorldLocation;
		FRotator CameraRotation = Math::MakeRotFromX(ToTarget);*/

		/*DrawLineFromPlayer(ToTarget);
		CameraComp.SetWorldRotation(AcceleratedTargetRotation.Value);*/

		//Player.ApplyCameraSpringArmSettings(Settings, FHazeCameraBlendSettings(1.0f), this);

	}

	void UpdatePivotOffset()
	{
		float PivotOffsetScale = FMath::Clamp(CameraUser.DesiredRotation.ForwardVector.DotProduct(MoveComp.DownHit.ImpactNormal), 0.f, 1.f);

		FVector PivotOffset = DefaultPivotOffset + (FVector::UpVector * PivotOffsetScale * 600.f);
		FVector RelativePivotOffset = Owner.GetActorTransform().InverseTransformVector(MoveComp.DownHit.Normal);
		Player.ApplyPivotOffset(PivotOffset, FHazeCameraBlendSettings(1.5f), this);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{		
		FVector Velocity = MoveComp.Velocity;

		Velocity.Z *= 0.33f;
		FRotator CameraRotation = Math::MakeRotFromX(Velocity);
		CameraRotation.Roll = 0.f;
		CameraRotation.Pitch -= 10.f;

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(CameraRotation, 2.5f, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}


	void DrawLine(FVector Origin, FVector Vector, FLinearColor Colour = FLinearColor::White, float Duration = 0.f) const
	{
		System::DrawDebugLine(Origin, Origin + Vector, Colour, Duration);
	}

	void DrawLineFromPlayer(FVector Vector, FLinearColor Colour = FLinearColor::White, float Duration = 0.f) const
	{
		DrawLine(Player.ActorLocation, Vector, Colour, Duration);
	}
}
