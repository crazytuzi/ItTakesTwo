import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UMusicFlyingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicFlying");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	UMusicalFlyingSettings Settings;

	float StartupImpulse;

	FVector OldForward;

	float GetFlyingVelocity() const property { return FlyingComp.FlyingVelocity; }
	void SetFlyingVelocity(float Value) property { FlyingComp.FlyingVelocity = Value; }

	bool GetIsHovering() const property { return FlyingComp.bIsHovering; }
	void SetIsHovering(bool Value) property { FlyingComp.bIsHovering = Value; }

	float FlyingVelocityFraction = 0.0f;

	float VerticalVelocity = 0;

	float InputPressedElapsed = 0;
	float StickReleasedElapsed = 0.0f;
	float AccumulatedDive = 0.0f;
	float LastDive = 0.0f;
	float DiveBoost = 0.0f;
	float DiveBoostTarget = 0.0f;
	float DiveAccumulationMax = 5000.0f;

	bool bWasStickDown = false;

	// For animations
	FHazeAcceleratedFloat AcceleratedYaw;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);

		if(FlyingComp.JetpackActor.IsValid())
		{
			FlyingComp.JetpackInstance = Cast<APlayerJetpackActor>(SpawnActor(FlyingComp.JetpackActor));
			
			if(Player.IsMay())
			{
				FlyingComp.JetpackInstance.AttachToActor(Player, n"Backpack");
			}
			else
			{
				FlyingComp.JetpackInstance.AttachToActor(Player, n"JetPackSocket");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!FlyingComp.bIsFlying)
			return EHazeNetworkActivation::DontActivate;
		
		if(!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.YawAxis = Player.Mesh.ForwardVector;
		
		StartupImpulse = Settings.StartupImpulse;

		Player.ApplyCameraSettings(FlyingComp.FlyingCamSettings, FHazeCameraBlendSettings(2.0f), this, EHazeCameraPriority::High);

		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
		VerticalVelocity = 0;
		FlyingVelocityFraction = 0;
		bWasStickDown = false;
	}

	float PitchDiveModifier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//float F = Player.Mesh.ForwardVector.DotProduct(Player.ViewRotation.ForwardVector);
		
		//float Eased = FMath::EaseOut(1.0f, 0.0f, FMath::Abs(F), 1.0f);

		if(IsStickDown())
		{
			InputPressedElapsed += DeltaTime;
		}
		else
		{
			InputPressedElapsed = 0;
		}

		float DiveModifierFraction = (FMath::Clamp(DiveBoost / DiveAccumulationMax, 0.0f, 1.0f) - 1.0f) * -1.0f;
		
		PitchDiveModifier = FMath::EaseOut(0.0f, 1.0f, DiveModifierFraction, 2.0f);


		FlyingVelocityFraction = FMath::Max(MoveComp.Velocity.Size() / Settings.FlyingSpeedMax, 0.0f);

		//PrintToScreen("FlyingVelocityFraction " + FlyingVelocityFraction);
		if(HasControl())
			IsHovering = (FlyingComp.bAlwaysFly || FlyingComp.bIsPerformingLoop) ? false : !IsStickDown();//FlyingVelocityFraction < Settings.Hovering;

		//PrintToScreen("FlyingComp.bIsFlying " + FlyingComp.bIsFlying);

		FlyingComp.CurrentFlyingState = IsHovering ? EMusicalFlyingState::Hovering : EMusicalFlyingState::Flying;

		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicalFlying");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);
			CrumbComp.LeaveMovementCrumb();
		}

		FHazeCameraSettings SensitivitySettings;
		SensitivitySettings.bUseSensitivityFactor = true;
		const float CameraSensitivityFactor = FMath::Clamp(FMath::EaseOut(1.0f, 0.45f, FlyingVelocityFraction, 1.2f), 0.45f, 1.0f);
		SensitivitySettings.SensitivityFactor = CameraSensitivityFactor;
		//PrintToScreen("CameraSensitivityFactor " + CameraSensitivityFactor);
		Player.ApplySpecificCameraSettings(SensitivitySettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend::Normal(0.5f), this, EHazeCameraPriority::High);

		//SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(1.f, this));
	}

	private void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		if(HasControl())
		{
			StickReleasedElapsed += DeltaTime;
			FVector Turn = FlyingComp.TurnInput;
			const float InputFactor = Turn.Size();
			const bool bIsStickDown = IsStickDown();

			float Acceleration = Settings.FlyingSpeed * (FlyingComp.bIsPerformingLoop ? 1.0f : InputFactor);
			float MaxSpeed = Settings.FlyingSpeedMax * InputFactor;
			float TurnRateYaw = (Settings.TurnRateYaw * InputFactor) * (FlyingComp.bIsPerformingLoop ? 0.25f : 1.0f);
			const float SpeedFactor = FlyingVelocity / Settings.FlyingSpeedMax;
			const float StickReleasedFactor = FMath::Min(StickReleasedElapsed / 1.0f, 1.0f);
			float FacingDot = FMath::Max(FlyingComp.TurnInput.DotProduct(Player.Mesh.ForwardVector.GetSafeNormal2D()), 0.0f);
			const float YawTurnRateModifier = FMath::EaseIn(1.0f, 0.55f, SpeedFactor, 5.5f);
			

			TurnRateYaw *= FMath::EaseIn(0.4f * StickReleasedFactor, YawTurnRateModifier, FacingDot * StickReleasedFactor, 3.0f);
			const float FlyingDrag = (bIsStickDown ? Settings.FlyingDrag : Settings.NoInputDrag) * StickReleasedFactor;
			//PrintToScreen("TurnRateYaw " + TurnRateYaw);
			
			//FVector Input = FlyingComp.InputMovementPlane;

			FVector PitchFactor = Player.Mesh.ForwardVector.CrossProduct(MoveComp.WorldUp);
			const float PitchFactorSize = 1.0f;//PitchFactor.Size();
			float PitchTurnRate = Settings.TurnRatePitch * PitchFactorSize;
			
			FVector TargetPitch = IsHovering ? FVector::ForwardVector : FlyingComp.InputMovementPlane;

			FlyingComp.PitchAxis = FQuat::Slerp(FlyingComp.PitchAxis.ToOrientationQuat(), TargetPitch.ToOrientationQuat(), DeltaTime * (PitchTurnRate * PitchDiveModifier)).Vector();

			//PrintToScreen("DiveFraction " + DiveFraction);

			if(!Turn.IsNearlyZero())
			{
				FlyingComp.YawAxis = FQuat::Slerp(FlyingComp.YawAxis.ToOrientationQuat(), Turn.ToOrientationQuat(), TurnRateYaw * DeltaTime).Vector();
			}


			VerticalVelocity += (IsHovering ? (FlyingComp.VerticalInput * Settings.VerticalAcceleration * DeltaTime) : 0.0f);
			VerticalVelocity *= FMath::Pow(Settings.VerticalDrag, DeltaTime);

			FlyingComp.AccumulatedPitchInput += (!IsHovering ? (FlyingComp.VerticalInput * (Settings.VerticalPitchInput * PitchDiveModifier)* DeltaTime) : 0.0f);
			FlyingComp.AccumulatedPitchInput *= FMath::Pow(Settings.VerticalPitchInputDrag, DeltaTime);
			
			FlyingVelocity += Acceleration * DeltaTime;
			FlyingVelocity = FMath::Min(FlyingVelocity, Settings.FlyingSpeedMax + FlyingComp.CurrentBoost);
			FlyingVelocity *= FMath::Pow(FlyingDrag, DeltaTime);

			FlyingComp.CurrentBoost *= FMath::Pow(Settings.BoostDrag, DeltaTime);

			StartupImpulse *= FMath::Pow(Settings.StartupImpulseDrag, DeltaTime);
			

			//PrintToScreen("FlyingComp.TurnInput " + FlyingComp.TurnInput);

			float NewPitch = FMath::Clamp(FlyingComp.PitchAxis.Rotation().Pitch + FlyingComp.AccumulatedPitchInput, -89.9f, 89.9f);

			if(FlyingComp.bIsPerformingLoop)
				NewPitch = FlyingComp.LoopingPitch;

			//PrintToScreen("NewPitch: " + NewPitch);

			FRotator PitchRotation(NewPitch, 0.0f, 0.0f);
			const float OffsetTime = IsHovering ? 0.01f : 0.1f;
			CrumbComp.SetCustomCrumbVector(FVector(NewPitch, FlyingComp.TurnInput.SizeSquared(), FlyingComp.AccumulatedPitchInput));
			Player.MeshOffsetComponent.OffsetRelativeRotationWithTime(PitchRotation, OffsetTime);
			
			float DiveDot = PitchRotation.Vector().DotProduct(-FVector::UpVector);
			DiveBoostTarget *= FMath::Pow(0.15f, DeltaTime);

			if(LastDive > 0.0f && DiveDot <= 0.0f)
			{
				DiveBoostTarget += AccumulatedDive;
				AccumulatedDive = 0.0f;
			}

			DiveBoost = FMath::FInterpTo(DiveBoost, DiveBoostTarget, DeltaTime, 3.0f);

			float DiveFraction = FMath::EaseIn(0.0f, 1.0f, FMath::Max(DiveDot, 0.0f), 2.0f);
			AccumulatedDive += DiveFraction * 9000.0f * DeltaTime;
			AccumulatedDive = FMath::Min(AccumulatedDive, DiveAccumulationMax);

			if(DiveDot < 0.15f)
			{
				AccumulatedDive *= FMath::Pow(0.05f, DeltaTime);
			}

			LastDive = DiveDot;
			
			FVector Velocity = Player.Mesh.ForwardVector * (FlyingVelocity + FlyingComp.CurrentBoost + DiveBoost);

			if(!FMath::IsNearlyZero(StartupImpulse, 0.1f))
			{
				Velocity += FVector::UpVector * StartupImpulse;
			}

			Velocity += FVector::UpVector * VerticalVelocity;

			// Added external impulses, e.g from follow clouds trying to keep players out of them
			FlyingComp.FlyingImpulse *= FMath::Pow(Settings.ImpulseDrag, DeltaTime);
			Velocity += FlyingComp.FlyingImpulse;
			
			MoveComp.SetTargetFacingDirection(FlyingComp.YawAxis.GetSafeNormal());
			FrameMove.ApplyTargetRotationDelta();
			FrameMove.ApplyDelta(Velocity * DeltaTime);
			FrameMove.OverrideStepDownHeight(0.f);

			if(!bIsStickDown && bWasStickDown)
				StickReleasedElapsed = 0.0f;

			bWasStickDown = bIsStickDown;
			//FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
			
			//System::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation + FlyingComp.InputMovementPlane * 1000, 10, FLinearColor::Green);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			const FRotator PitchRotation(ConsumedParams.CustomCrumbVector.X, 0, 0);
			Player.MeshOffsetComponent.OffsetRelativeRotationWithTime(PitchRotation, 0.1f);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
			const float ReplicatedVelocity = ConsumedParams.CustomCrumbVector.Y;
			FlyingComp.AccumulatedPitchInput = ConsumedParams.CustomCrumbVector.Z;

			IsHovering = FlyingComp.bAlwaysFly ? false : (ReplicatedVelocity < 0.1f);
		}

		FVector VelocityChange = OldForward.Rotation().UnrotateVector(Player.Mesh.ForwardVector);

		const float YawDir = FMath::Clamp(Math::GetPercentageBetween(0.0f, 2.0f, VelocityChange.Rotation().Yaw), -1.0f, 1.0f);
		const float PitchDir = FMath::Clamp(Math::GetPercentageBetween(0.0f, 1.0f, VelocityChange.Rotation().Pitch), -1.0f, 1.0f) * -1.0f;
		FlyingComp.TurningDirection.X = YawDir;
		if(!FlyingComp.bIsPerformingLoop)
			FlyingComp.TurningDirection.Y = PitchDir;
		else
			FlyingComp.TurningDirection.Y = -1.0f;

		OldForward = Player.Mesh.ForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if(FlyingComp.bIsReturningToVolume)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!FlyingComp.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.bForceDeactivateFlying = false;
		FlyingComp.OnExitFlying();
		Player.MeshOffsetComponent.ResetRelativeRotationWithTime(0.15f);
		Player.ClearCameraSettingsByInstigator(this);
		CrumbComp.RemoveCustomParamsFromActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(FlyingComp.JetpackInstance != nullptr)
		{
			FlyingComp.JetpackInstance.DetachFromActor();
			FlyingComp.JetpackInstance.DestroyActor();
			FlyingComp.JetpackInstance = nullptr;
		}
	}

	// return true if teh movement stick is pressed down in any direction
	bool IsStickDown() const
	{
		return FlyingComp.TurnInput.SizeSquared() > 0.1f;
	}
}
