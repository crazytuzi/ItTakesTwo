import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.MusicTargetingComponent;

class UMusicFlyingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"MusicalFlyingCamera");

	default CapabilityDebugCategory = n"Movement Flying";

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default TickGroupOrder = 51;
	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;
	UHazeCameraComponent Camera;
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;
	UMusicTargetingComponent TargetingComp;
	UMusicalFlyingSettings Settings;

	float NewIdealDistance = 0.0f;

	FVector WidgetOffsetCurrent;

	FHazeAcceleratedRotator AcceleratedTargetRotation;
	FHazeAcceleratedVector2D AcceleratedInput;

	float CurrentYawOffset = 0;

	FRotator CurrentRotation;

	FVector TargetOffset;
	FVector CurrentTargetOffset;

	FHazeAcceleratedRotator ChaseRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		Camera = UHazeCameraComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!FlyingComp.bIsFlying)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!FlyingComp.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		NewIdealDistance = FlyingComp.FlyingCamSettings.SpringArmSettings.IdealDistance;
		AcceleratedTargetRotation.Value = CameraUser.WorldToLocalRotation(Player.Mesh.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearIdealDistanceByInstigator(this);
		Player.ClearCameraOffsetByInstigator(this);
	}

	bool HasCameraInput() const
	{
		return GetAttributeVector2D(AttributeVectorNames::CameraDirection).SizeSquared() > 0.1f;
	}

	bool IsInputPressed() const
	{
		return FlyingComp.TurnInput.SizeSquared() > 0.1f;
	}

	float VelCameraDotCurrent = 0.0f;
	float VelCameraUpCurrent = 0.0f;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float VelCameraDot = 0.0f;
		float VelCameraUp = 0.0f;

		float InterpSpeed = 2.0f;
		
		//if(MoveComp.Velocity.Size() > 5.5f)
		//{
			float SpeedFraction = FMath::Clamp(MoveComp.Velocity.SizeSquared() / FMath::Square(3000.0f), 0.0f, 1.0f);
			float SpeedDotFraction = FMath::EaseIn(0.0f, 1.0f, SpeedFraction, 1.0f);
			//PrintToScreen("SpeedDotFraction " + SpeedDotFraction);

			VelCameraDot = Player.ViewRotation.RightVector.DotProduct(Player.GetActorRotation().Vector()) * SpeedDotFraction;
			FVector FacingDirection = FVector::ZeroVector;
			if(FMath::Abs(FlyingComp.AccumulatedPitchInput) > 1.0f)
				FacingDirection = FQuat(FVector::RightVector, FMath::DegreesToRadians(FlyingComp.AccumulatedPitchInput)).Vector();
			else
				FacingDirection = MoveComp.Velocity.GetSafeNormal();
			VelCameraUp = FVector::UpVector.DotProduct(FacingDirection) * SpeedDotFraction;
			if(FlyingComp.bIsHovering)
				VelCameraUp = VelCameraDot = 0.0f;
		
		//}

		//PrintToScreen("VelCameraUp " + VelCameraUp);
		
		float DotFraction = FMath::Max((FMath::Abs(VelCameraDot) / 1.0f), 0.0f);
		//PrintToScreen("DotFraction " + DotFraction);
		float DotInterpSpeed = FMath::EaseIn(5.5f, 6.5f, DotFraction, 3.0f);
		//PrintToScreen("DotInterpSpeed " + DotInterpSpeed);
		VelCameraDotCurrent = FMath::FInterpTo(VelCameraDotCurrent, VelCameraDot * Settings.CrosshairHorizontalMovementModifier, DeltaTime, DotInterpSpeed);
		VelCameraUpCurrent = FMath::FInterpTo(VelCameraUpCurrent, VelCameraUp * Settings.CrosshairVerticalMovementModifier, DeltaTime, DotInterpSpeed);

		float CameraFaceingDot = Player.ViewRotation.ForwardVector.GetSafeNormal2D().DotProduct(Player.Mesh.ForwardVector.GetSafeNormal2D());

		FVector TargetOffs(VelCameraDotCurrent, VelCameraUpCurrent, 0.0f);

		if(TargetingComp.HasValidTarget())
		{
			TargetOffs = FVector::ZeroVector;
		}
		//PrintToScreen("CameraFaceingDot " + CameraFaceingDot);
		
		//PrintToScreen("VelCameraDotCurrent " + VelCameraDotCurrent);
		//PrintToScreen("VelCameraUpCurrent " + VelCameraUpCurrent);


		
		WidgetOffsetCurrent = FMath::VInterpTo(WidgetOffsetCurrent, TargetOffs, DeltaTime, Settings.CrosshairInterpSpeed);
		//WidgetOffsetCurrent *= 0.5f;
		//PrintToScreen("WidgetOffsetCurrent " + WidgetOffsetCurrent);
		TargetingComp.UpdateWidgetOffset(WidgetOffsetCurrent * 0.15f);

		const bool bCameraInput = HasCameraInput();
		FVector Input = FlyingComp.MovementRaw;
		FRotator TargetRotation = CameraUser.WorldToLocalRotation(Player.Mesh.WorldRotation);
		
		const float YawOffset = 5;
		const float YawOffsetSpeed = !IsInputPressed() ? 0.5f : 20.0f;

		float Alpha = MoveComp.Velocity.SizeSquared() / FMath::Square(Settings.FlyingSpeedMax);
		float MaxSpeedFraction = FMath::EaseIn(0.0f, 1.0f, Alpha, 0.5f);

		//PrintToScreen("MaxSpeedFraction " + MaxSpeedFraction);

		const float TargetYawOffset = YawOffset * MaxSpeedFraction;
		CurrentYawOffset = FMath::FInterpTo(CurrentYawOffset, TargetYawOffset, DeltaTime, YawOffsetSpeed);
		//PrintToScreen("CurrentYawOffset " + CurrentYawOffset);

		TargetRotation.Yaw += CurrentYawOffset;

		const float CameraDot = FMath::Max(Player.ViewRotation.ForwardVector.DotProduct(Player.Mesh.ForwardVector), 0.0f);
		const float CameraDotRight = FMath::Abs(Player.ViewRotation.ForwardVector.DotProduct(Player.Mesh.RightVector));
		//PrintToScreen("CameraDotRight " + CameraDotRight);

		float TimeDilation = Owner.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.0f) ? DeltaTime / TimeDilation : 1.0f;

		//AcceleratedTargetRotation.AccelerateTo(TargetRotation, 2.0f, RealTimeDeltaSeconds);

		const float VelocitySize = FlyingComp.FlyingVelocityTotal;
		const float SpeedScalar = FMath::Clamp(MaxSpeedFraction, 0.7f, FMath::Clamp(1.5f * CameraDot, 1.0f, 1.5f));

		const float IdealDistanceMax = 0;
		const float IdealDistanceMin = 0;

		NewIdealDistance = FMath::FInterpTo(NewIdealDistance, FlyingComp.FlyingCamSettings.SpringArmSettings.IdealDistance * SpeedScalar, DeltaTime, 10.0f);
		Player.ApplyIdealDistance(NewIdealDistance, FHazeCameraBlendSettings(1.0f), this, EHazeCameraPriority::High);
		//PrintToScreen("NewIdealDistance " + NewIdealDistance);
		//PrintToScreen("NewIdealDistance " + NewIdealDistance);

		const float OffsetSpeedScalar = FMath::Clamp(VelocitySize / Settings.FlyingSpeedMax, 1.0f, FMath::Clamp(2.0f * CameraDotRight, 1.0f, 2.0f)) - 1.0f;
		//PrintToScreen("OffsetSpeedScalar " + OffsetSpeedScalar);

		const float OffsetLength = (Settings.HorizontalCameraOffset - (Settings.HorizontalCameraOffset * (OffsetSpeedScalar * 2.0f)));
		const FVector OffsetMax(0, OffsetLength * VelCameraDot, (OffsetLength * 0.1f) * VelCameraDot);
		Alpha = FMath::Clamp((TargetOffset.SizeSquared()) / FMath::Square(OffsetLength), 0.1f, 1.0f );

		const float Exp = 1.1f;
		
		TargetOffset = FMath::EaseInOut(TargetOffset, OffsetMax, Alpha, Exp);

		TargetOffset.GetClampedToMaxSize(OffsetLength);
		//PrintToScreen("CurrentTargetOffset " + CurrentTargetOffset);
		//PrintToScreen("Alpha " + Alpha);

		//if(bCameraInput)
		//	TargetOffset = FVector::ZeroVector;

		TargetOffset = bCameraInput ? FVector::ZeroVector : TargetOffset;

		CurrentTargetOffset = FMath::VInterpTo(CurrentTargetOffset, TargetOffset, DeltaTime, 10.25f);
		Player.ApplyCameraOffset(CurrentTargetOffset, FHazeCameraBlendSettings(1.0f), this, EHazeCameraPriority::Script);

		FRotator DesiredRotation = CameraUser.WorldToLocalRotation(CameraUser.GetDesiredRotation());
		AcceleratedTargetRotation.Value = DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(TargetRotation, 0.8f, DeltaTime);
		
		
		//CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
		FRotator DeltaRot = (AcceleratedTargetRotation.Value - DesiredRotation).GetNormalized();
		//CameraUser.AddDesiredRotation(DeltaRot);
	}
}
