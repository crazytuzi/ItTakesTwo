import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Capabilities.Skydive.CharacterSkydiveComponent;
import Vino.Characters.PlayerCharacter;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UCharacterSkydiveCameraCapability : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::SkyDiving);
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"SkyDive");
	default CapabilityTags.Add(n"SkyDiveCamera");

	default CapabilityDebugCategory = n"Camera";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	APlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCameraUserComponent CameraUser;
	UCameraComponent CameraComp;	
	UCharacterSkydiveComponent SkydiveComp;

	UCameraShakeBase CameraShake;

	FHazeAcceleratedFloat AcceleratedCameraShake;
	FHazeAcceleratedRotator AcceleratedTargetRotation;
	FHazeAcceleratedFloat AcceleratedFOV;
	FHazeAcceleratedFloat AcceleratedIdealDistance;
	FHazeAcceleratedFloat AcceleratedShimmer;
	
	
	FVector DefaultPivotOffset;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<APlayerCharacter>(Owner);		
		CameraUser = UCameraUserComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		SkydiveComp = UCharacterSkydiveComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (IsActioning(MovementActivationEvents::SkyDiving))
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(MovementActivationEvents::SkyDiving))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedCameraShake.SnapTo(0.f);
		AcceleratedShimmer.SnapTo(0.f);
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);
		AcceleratedFOV.SnapTo(70.f, 0.f);
		AcceleratedIdealDistance.SnapTo(1000.f, 0.f);

		if (SkydiveComp.CameraShakeType.IsValid())
			CameraShake = Player.PlayCameraShake(SkydiveComp.CameraShakeType);

		CameraShake.ShakeScale = 0.f;

		FHazeCameraSpringArmSettings Settings;
		CameraUser.GetCameraSpringArmSettings(Settings);
		DefaultPivotOffset = Settings.PivotOffset;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CameraComp.SetRelativeRotation(FRotator::ZeroRotator);
		Player.ClearCameraSettingsByInstigator(this);

		// Player.StopAllCameraShakes(true);
		// if (SkydiveComp.CameraShake.IsValid())
		// 	Player.StopCameraShake(SkydiveComp.CameraShake, false);
		
		if (CameraShake != nullptr)
			Player.StopCameraShake(CameraShake, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateDesiredRotation(DeltaTime);
		
		UpdateFieldOfView(DeltaTime);
		UpdateIdealDistance(DeltaTime);
		UpdateCameraShakeScale(DeltaTime);
		UpdateShimmerScale(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		if(Owner.IsAnyCapabilityActive(CameraTags::PointOfInterest))
			return;

		FVector TargetDirection = Owner.ActorForwardVector;		

		FVector Axis = MoveComp.WorldUp.CrossProduct(TargetDirection).GetSafeNormal();
		float Angle = 70.f * DEG_TO_RAD;
		FQuat RotationQuat = FQuat(Axis, Angle);

		TargetDirection = RotationQuat * TargetDirection;
		FRotator TargetRotation = Math::MakeRotFromX(TargetDirection);

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(TargetRotation, 3.4f, DeltaTime);
		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}

	void UpdateFieldOfView(float DeltaTime)
	{
		FHazeCameraBlendSettings BlendSettings = FHazeCameraBlendSettings(0.2f);

		float TargetFOV = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MoveComp.MoveSpeed), FVector2D(70.f, 110.f), MoveComp.Velocity.Size());
		float NewFOV = AcceleratedFOV.AccelerateTo(TargetFOV, 9.0f, DeltaTime);
		Player.ApplyFieldOfView(NewFOV, BlendSettings, this, EHazeCameraPriority::Medium);
	}

	void UpdateIdealDistance(float DeltaTime)
	{
		FHazeCameraBlendSettings BlendSettings = FHazeCameraBlendSettings(2.f);

		float TargetDistance = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MoveComp.MoveSpeed), FVector2D(1000.f, 150.f), MoveComp.Velocity.Size());
		float NewDistance = AcceleratedIdealDistance.AccelerateTo(TargetDistance, 4.f, DeltaTime);

		Player.ApplyIdealDistance(NewDistance, BlendSettings, this, EHazeCameraPriority::Medium);
	}

	void UpdateCameraShakeScale(float DeltaTime)
	{
		float TargetFallSpeedAlpha = FMath::Abs(MoveComp.Velocity.Z) / MoveComp.DefaultMovementSettings.ActorMaxFallSpeed;
		TargetFallSpeedAlpha = FMath::Clamp(TargetFallSpeedAlpha, 0.f, 1.f);

		float FallSpeedAlpha = AcceleratedCameraShake.AccelerateTo(TargetFallSpeedAlpha, 5.f, DeltaTime);
		CameraShake.ShakeScale = FallSpeedAlpha;
	}

	void UpdateShimmerScale(float DeltaTime)
	{		
		float TargetShimmer = FMath::Abs(MoveComp.Velocity.Z) / MoveComp.DefaultMovementSettings.ActorMaxFallSpeed;
		TargetShimmer = FMath::Clamp(TargetShimmer, 0.f, 1.f);
		TargetShimmer *= 2.f;		

		float Shimmer = AcceleratedShimmer.AccelerateTo(TargetShimmer, 10.f, DeltaTime);

		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(Shimmer, this));
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
