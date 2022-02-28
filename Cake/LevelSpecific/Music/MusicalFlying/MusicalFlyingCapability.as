import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingSettings;
import Peanuts.SpeedEffect.SpeedEffectStatics;

// This is the physics part of flying and will only activate once startup has decided that it is time to do so.

UCLASS(Deprecated)
class UMusicalFlyingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MusicalFlying");
	default CapabilityTags.Add(n"MusicalAirborne");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;

	UMusicalFlyingSettings Settings;

	FHazeAcceleratedFloat AcceleratedYaw;
	FHazeAcceleratedFloat AcceleratedPitch;
	FHazeAcceleratedFloat AcceleratedYawTurn;

	UCurveFloat CurrentFloatCurve;

	// Counting the time we spend flying.
	float FlyingElapsed = 0.0f;

	float CurrentPitch = 0.0f;

	float CurrentYaw = 0;

	float AccumulatedYaw = 0;
	float PitchScale = 1;
	float AccumulatedDive = 0;
	float AccumulatedDiveMax = 80;
	float AccumulatedDiveInc = 50;
	//FVector CurrentYaw;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!FlyingComp.bFlyingValid)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.ExitVolumeBehavior != EMusicalFlyingExitVolumeBehavior::Nothing)
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.FlyingStartupTime > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(FlyingComp.bDoLoop)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.ExitVolumeBehavior != EMusicalFlyingExitVolumeBehavior::Nothing)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!FlyingComp.bFly)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!FlyingComp.bFlyingValid)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.FlyingStartupTime > 0.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(FlyingComp.bDoLoop)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingElapsed = 0.0f;
		CurrentPitch = FlyingComp.StartupFacingDirection.Rotation().Pitch * -1.0f;
		CurrentYaw = FlyingComp.StartupFacingDirection.Rotation().Yaw;
		CurrentFloatCurve = Settings.StartupAccelerationInAir;
		AccumulatedYaw = 0;
		PitchScale = 1;

		if(FlyingComp.bStartedOnGround)
		{
			CurrentFloatCurve = Settings.StartupAccelerationGround;
		}

		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);
		if(CymbalComp != nullptr)
			CymbalComp.bTargeting = true;

		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.MeshOffsetComponent.OffsetRelativeRotationWithTime(FRotator::ZeroRotator);
		CrumbComp.RemoveCustomParamsFromActorReplication(this);

		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);
		if(CymbalComp != nullptr)
			CymbalComp.bTargeting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FlyingElapsed += DeltaTime;

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"MusicalFlying");
			CalculateFrameMove(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);
			CrumbComp.LeaveMovementCrumb();
		}

		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(1.f, this));
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{			
			const float StartupScalar = CurrentFloatCurve != nullptr ? CurrentFloatCurve.GetFloatValue(FlyingElapsed) : 1.0f;

			FVector2D Input = FlyingComp.FlyingInput;
			
			float YawScalar = 1.0f;

			// Scale yaw input so it becomes less sensetive horizontally.
			const float TargetY = FMath::EaseOut(0.0f, 1.0f, FMath::Abs(Input.Y), 2);
			
			AcceleratedYawTurn.AccelerateTo(TargetY * FMath::Sign(Input.Y), 1.0f, DeltaTime);
			float TargetYaw = FMath::EaseIn(0.0f, 40.0f, FMath::Abs(AcceleratedYawTurn.Value), 30);

			float BrakeScalar = FlyingComp.BrakingFactor;

			if(FlyingComp.TightTurnState == EMusicalFlyingTightTurn::Left)
			{
				YawScalar = Input.Y < 0.0f ? 1.4f : 0.9f;
			}
			else if(FlyingComp.TightTurnState == EMusicalFlyingTightTurn::Right)
			{
				YawScalar = Input.Y > 0.0f ? 1.4f : 0.9f;
			}

			FlyingComp.CurrentBoost *= FMath::Pow(Settings.BoostDrag, DeltaTime);
			FlyingComp.CurrentBoostCooldown -= DeltaTime;

			FlyingComp.CurrentTurnRate = Input.Y;

			const float Acceleration = IsInputPressed() ? 0.1f : 0.0f;

			//AcceleratedYaw.AccelerateTo((Settings.TurnRateYaw + TargetYaw) * Input.Y, Acceleration, DeltaTime);
			AcceleratedPitch.AccelerateTo(Settings.TurnRatePitch * Input.X, Acceleration, DeltaTime);

			//PrintToScreen("AcceleratedYaw " + AcceleratedYaw.Value);
			//PrintToScreen("CurrentPitch " + CurrentPitch);
			//PrintToScreen("PitchScale " + PitchScale);

			CurrentYaw += AcceleratedYaw.Value * DeltaTime;
			CurrentPitch = FMath::Clamp(CurrentPitch + (AcceleratedPitch.Value * PitchScale) * DeltaTime, -89.9f, 89.9f);

			// lets try something new
			FQuat TargetRotPitch = FQuat(Owner.ActorRightVector, FMath::DegreesToRadians(CurrentPitch));
			FQuat TargetRotYaw = FQuat(MoveComp.WorldUp, FMath::DegreesToRadians(CurrentYaw));


			FVector MoveDirection = (TargetRotPitch * TargetRotYaw).Vector();
			
			FVector PitchC = MoveDirection.CrossProduct(MoveComp.WorldUp);
			
			// This makes pitch sluggish the more upwards/downwards we are flying.
			float TestV = FMath::Clamp(FMath::EaseOut(0.3f, 1.0f, PitchC.Size(), 0.8f), 0.3f, 1.0f);

			// how much we are diving.
			float DiveFraction = MoveDirection.DotProduct(-MoveComp.WorldUp);

			if(DiveFraction > 0.0f)
			{
				const float TargetDiveInc = FMath::EaseIn(0.0f, 1.0f, DiveFraction, 5);
				AccumulatedDive = FMath::Min(AccumulatedDive + (TargetDiveInc * AccumulatedDiveInc * DeltaTime), AccumulatedDiveMax);
			}
				
			if(!FMath::IsNearlyZero(AccumulatedDive) && DiveFraction < 0.0f)
			{
				FlyingComp.CurrentBoost += AccumulatedDive * 30;
				AccumulatedDive = 0;
			}

			PitchScale = TestV;
			FVector Velocity = MoveDirection * ((Settings.FlyingSpeed * StartupScalar) + FlyingComp.CurrentBoost - (Settings.BreakingThrottle * BrakeScalar));

			FRotator NewRotation = FRotator(MoveDirection.Rotation().Pitch, 0.0f, 0.0f);
			Player.MeshOffsetComponent.OffsetRelativeRotationWithSpeed(NewRotation);
			CrumbComp.SetCustomCrumbRotation(NewRotation);
			//PrintToScreen("TargetRotYaw.Vector() " + TargetRotYaw.Vector());
			MoveComp.SetTargetFacingDirection(TargetRotYaw.Vector());
			FrameMove.ApplyTargetRotationDelta();
			FrameMove.ApplyDelta(Velocity * DeltaTime);
			
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Player.MeshOffsetComponent.OffsetRelativeRotationWithSpeed(ConsumedParams.CustomCrumbRotator);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}
	}

	bool IsInputPressed() const
	{
		return GetAttributeVector2D(AttributeVectorNames::MovementRaw).SizeSquared() > 0.1f;
	}
}
