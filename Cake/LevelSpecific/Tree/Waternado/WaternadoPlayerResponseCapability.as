import Vino.Movement.MovementSettings;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.Boat.TreeBoat;
import Cake.LevelSpecific.Tree.Waternado.WaternadoPlayerResponseComponent;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.Tree.Waternado.Waternado;
import Peanuts.Movement.NoCollisionSolver;
import Vino.Characters.PlayerCharacter;

/*
	Capability that handles waternado interactions 
*/

UCLASS(abstract)
class UWaternadoPlayerResponseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	// when player leaves the boat and gets sucked up into the nado
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerSwallowedAudioEvent;

	// once the nado spits out the player they'll enter skydive (when they start falling)
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EnterSkydiveEvent;

	// by landing on the boat or in the water
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EndSkydiveEvent;

	// Will be pushed onto the player upon overlapping the nado
	UPROPERTY(Category = "Movement")
	UMovementSettings SkyDiveMovementSettings;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Going Up")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings_GoingUp = nullptr;

	/* the one from camera settings will not be 
		used because we needed different blendIn times */ 
	UPROPERTY(Category = "Going Up")
	const float CameraSettingsIdealDistanceFromPlayer = 5000.f;

	/*	Setting this value to -1 will make it automatically calculate
		the value so that it blendsOut just as we land. */
	UPROPERTY(Category = "Going Down")
	// const float OverrideCameraSettingsBlendOutTime = -1.f;
	const float OverrideCameraSettingsBlendOutTime = 3.f;

	UPROPERTY(Category = "Going Up")
	const float DesiredHeight = 11000.f;

	UPROPERTY(Category = "Going Up")
	const float ReachDesiredHeightTime = 3.5f;

	UPROPERTY(Category = "Going Up")
	const float RegainMovementTime = 3.0f;

	UPROPERTY(Category = "Going Up")
	const float StayAttachedToNadoTime = 1.5f;

	/* 	Lower values == more pitch. High values == less pitch */
	const float GoingUpPOIPitchOffset = 3000.f;

	// suction oscillations
	const float StartStiffness = 100.f;
	const float StartDamping = 0.0f;
	const float EndDamping = 0.4f;
	const float EndStiffness = 1.f;

	// How long after launch should we wait until this POI is applied?
	UPROPERTY(Category = "Going Down")
	const float ToBoatPOIApplyTime = 1.5f;

	UPROPERTY(Category = "Going Down")
	const float ToBoatPOIBlendInTime = 3.f;

	// Point of view clamps towards the boat ince we start falling
	FHazeCameraClampSettings ToBoatPOIClamps;
	default ToBoatPOIClamps.ClampYawLeft = 180.f;
	default ToBoatPOIClamps.ClampYawRight = 180.f;
	default ToBoatPOIClamps.ClampPitchUp = 90.f;
	default ToBoatPOIClamps.ClampPitchDown = 90.f;

	UHazeMovementComponent MoveComp;
	APlayerCharacter Player;

	UWaternadoPlayerResponseComponent ResponseComponent;
	AWaternado OverlappedWaternado = nullptr;

	float LaunchGravityMultiplier = 0.f;
	float LaunchGravity = 0.f;

	bool bPlayerHasMovementControl = false;
	bool bClearedCamera_GoingUp = false;
	bool bPOIApplied_GoingDown = false;
	bool bStartedFalling = true;

	float TimeStampImpulse = 0.f;
	float TimeUntilArrival = 0.f;
	float TimeSinceImpulse = 0.f;

	UClass PreviousCollisionSolverClass;
	UClass PreviousRemoteCollisionSolverClass;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<APlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		ResponseComponent = UWaternadoPlayerResponseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"WaternadoImpulse"))
			return EHazeNetworkActivation::DontActivate;

		// @TODO will be handled better once we rewrite it to a movement capability
		const float TimeSinceLastImpulse = Time::GetGameTimeSince(TimeStampImpulse);
		if(TimeSinceLastImpulse < 0.5f)
		{
			// Print(Player.GetName() + " TimeSinceLastImpusle: " + TimeSinceLastImpulse);
			return EHazeNetworkActivation::DontActivate;
		}

		// make sure that we've landed at least once after begin play
		if(MoveComp.GetLastValidGround().GetActor() == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BlackboardContainsWaternado())
			return EHazeNetworkActivation::DontActivate;

		// return EHazeNetworkActivation::ActivateFromControl;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// deactivate once we are on the boat again
		if(MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			// return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"OverlappedWaternado", ConsumeWaternadoFromBlackboard());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ApplySettings( SkyDiveMovementSettings, this, EHazeSettingsPriority::Script);

		// Use the no-collision solver while the player is sucked into the air. We'll revert it once they start falling
		MoveComp.GetCurrentCollisionSolverType(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);
		MoveComp.UseCollisionSolver(UNoCollisionSolver::StaticClass(), UNoCollisionSolver::StaticClass());

		// this will detach the player from the boat 
		Player.BlockCapabilities(n"TreeBoat", this);

		// prevent unwanted movement while going up
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		bPlayerHasMovementControl = false;

		OverlappedWaternado = Cast<AWaternado>(ActivationParams.GetObject(n"OverlappedWaternado")); 

		// reset the bool value
		ConsumeAction(n"WaternadoImpulse");

		FVector Impulse = FVector::ZeroVector;

		// inherit the velocity of the ground which the player is standing on
		// (the player velocity itself is relative to the ground)
		if(MoveComp.IsGrounded())
		{
			const FVector HorizontalGroundVelocity = GetGroundVelocity().VectorPlaneProject(FVector::UpVector);
			Impulse += HorizontalGroundVelocity;
		}

		// calculations below assume zero velocity.Z
   		if(MoveComp.Velocity.Z != 0.f)
			Impulse.Z -= MoveComp.Velocity.Z;

		// Calculate impulse and gravity from desired height and time
		const float BaseGravity = FMath::Abs(MoveComp.GetGravityMagnitude() / MoveComp.GetGravityMultiplier());
		LaunchGravity = (2.f * DesiredHeight) / FMath::Square(ReachDesiredHeightTime);
		const float LaunchSpeed = ReachDesiredHeightTime * LaunchGravity;
		LaunchGravityMultiplier = LaunchGravity / BaseGravity;

		UMovementSettings::SetGravityMultiplier(Player, LaunchGravityMultiplier, this);
		bStartedFalling = false;

		Impulse.Z += LaunchSpeed;
		MoveComp.AddImpulse(Impulse);

		ResponseComponent = UWaternadoPlayerResponseComponent::GetOrCreate(Owner);
		ResponseComponent.bNadoSkydiving = true;

		TimeStampImpulse = Time::GetGameTimeSeconds();
		TimeUntilArrival = 1000.f;	// BIG_NUMBER 
		TimeSinceImpulse = 0.f;

		if(Player == Game::Cody)
			PlayFoghornVOBankEvent(OverlappedWaternado.FoghornBank, n"FoghornDBTreeBoatTornadoInsideEffortCody", Game::Cody);
		else
			PlayFoghornVOBankEvent(OverlappedWaternado.FoghornBank, n"FoghornDBTreeBoatTornadoInsideEffortMay", Game::May);

		ApplyCamera_GoingUp();
		bPOIApplied_GoingDown = false;

		Player.PlayerHazeAkComp.HazePostEvent(PlayerSwallowedAudioEvent);
		// PrintToScreen("Broadcast Swallowed audio event", Duration = 3.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClearCamera_GoingUp();

		Player.UnblockCapabilities(n"TreeBoat", this);
		GiveBackMovementToPlayer();

		Player.PlayerHazeAkComp.HazePostEvent(EndSkydiveEvent);
		// PrintToScreen("Broadcast EndSkyDive Event", Duration = 3.f);

		Player.ClearSettingsWithAsset(SkyDiveMovementSettings, this);

		ResponseComponent = UWaternadoPlayerResponseComponent::GetOrCreate(Owner);
		ResponseComponent.bNadoSkydiving = false;

		Player.ClearPointOfInterestByInstigator(this);

		UMovementSettings::ClearGravityMultiplier(Player, this);
		UMovementSettings::ClearHorizontalAirSpeed(Player, this);
	}

	void GiveBackMovementToPlayer()
	{
		if(bPlayerHasMovementControl)
			return;

		// something killed our impulse! Please let sydney know about this <3
//		ensure(Player.MovementComponent.Velocity.Z >= 0.f);

		// Revert back to the previous collision solver
		MoveComp.UseCollisionSolver(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);

		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		bPlayerHasMovementControl = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float Dt)
	{

		TimeSinceImpulse = Time::GetGameTimeSince(TimeStampImpulse);

		const float TimeUntilWeRegainControl = RegainMovementTime - TimeSinceImpulse;
		if(TimeUntilWeRegainControl <= 0.f)
			GiveBackMovementToPlayer();
		else
			VerifyUpImpulse();

		const float TimeUntilGoingDownPOI = ToBoatPOIApplyTime - TimeSinceImpulse;
		if(TimeUntilGoingDownPOI <= 0.f)
			ApplyPOI_GoingDown();

		// suck up the player and 'detach' half way up
		LerpPlayerToNadoXY(Dt);

		float DesiredHorizontalAirSpeed = SkyDiveMovementSettings.HorizontalAirSpeed;

		// While falling (velocity based)
		const float FallingDot = MoveComp.Velocity.DotProduct(FVector::UpVector);
		if(FallingDot < 0.f)
		{
			// Calculate time until arrival at the boat
			FHitResult GroundData = MoveComp.GetLastValidGround();
			AActor Boat = GroundData.GetActor();
			const FVector BoatPos = Boat.GetActorLocation();
			const FVector PlayerPos = Player.GetActorLocation();
			const FVector ToBoat = BoatPos - PlayerPos;
			const float VerticalDistanceToBoat = FMath::Abs(ToBoat.Z);
			TimeUntilArrival = CalcTimeUntilWeLand(VerticalDistanceToBoat);

			// once we start falling 
			if(bStartedFalling == false)
			{
				UMovementSettings::ClearGravityMultiplier(Player, this);
				bStartedFalling = true;
			}

			// while falling (time based)
			if(TimeSinceImpulse > ReachDesiredHeightTime)
			{
				const FVector SpeedBoostImpulse = CalcSpeedBoostImpulse(Dt);
				if(SpeedBoostImpulse != FVector::ZeroVector)
				{
					MoveComp.AddImpulse(SpeedBoostImpulse);

					const FVector ToBoatHorizontalNormalized = ToBoat.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

					const FVector BoatVelocity = GetGroundVelocity();
					const float BoatSpeedInDir = BoatVelocity.DotProduct(ToBoatHorizontalNormalized);

					if (BoatSpeedInDir >= DesiredHorizontalAirSpeed)
					{
						DesiredHorizontalAirSpeed = BoatSpeedInDir;
					}

					const FVector FutureHorizontalVelocity = (MoveComp.Velocity + SpeedBoostImpulse).VectorPlaneProject(FVector::UpVector);
					const float FutureHorizontalSpeedToBoat = FutureHorizontalVelocity.DotProduct(ToBoatHorizontalNormalized);
					if (FutureHorizontalSpeedToBoat >= DesiredHorizontalAirSpeed)
					{
						DesiredHorizontalAirSpeed = FutureHorizontalSpeedToBoat;
					}

				}

				float CamBlendOutTime = TimeUntilArrival;
				if (OverrideCameraSettingsBlendOutTime != -1.f)
				{
					CamBlendOutTime = OverrideCameraSettingsBlendOutTime;
				}

				ClearCamera_GoingUp(CamBlendOutTime);
			}
		}

		UMovementSettings::SetHorizontalAirSpeed(Player, DesiredHorizontalAirSpeed, this);
	}

	FVector CalcSpeedBoostImpulse(const float Dt)
	{
		// To boat data
		FHitResult GroundData = MoveComp.GetLastValidGround();
		AActor Boat = GroundData.GetActor();
		const FVector BoatPos = Boat.GetActorLocation();
		const FVector PlayerPos = Player.GetActorLocation();
		const FVector ToBoat = BoatPos - PlayerPos;
		const FVector ToBoatHorizontal = ToBoat.VectorPlaneProject(FVector::UpVector);
		float HorizontalDistanceToBoat = ToBoatHorizontal.Size();

		// we are close enough to the boat
		if(HorizontalDistanceToBoat <= KINDA_SMALL_NUMBER)
			return FVector::ZeroVector;

		// only when player wants to move
		const FVector InputMoveDir = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if(InputMoveDir.IsNearlyZero())
			return FVector::ZeroVector;

		const FVector HorizontalNormalizedDirectionToBoat = ToBoatHorizontal / HorizontalDistanceToBoat;
		const float SpeedBoostDOT = HorizontalNormalizedDirectionToBoat.DotProduct(InputMoveDir);

		// don't apply boost if the player is trying to avoid the boat
		if(SpeedBoostDOT <= 0.f)
			return FVector::ZeroVector;

		const FVector HorizontalPlayerVelocity = MoveComp.Velocity.VectorPlaneProject(FVector::UpVector);
		float HorizontalSpeedTowardsBoat = HorizontalPlayerVelocity.DotProduct(HorizontalNormalizedDirectionToBoat);

		// Normal movement has to rotate the velocity towards the 
		// desired direction before we apply the impulse, otherwise It'll look weird
		// if(HorizontalSpeedTowardsBoat <= 0.f)
		// 	return FVector::ZeroVector;

		HorizontalSpeedTowardsBoat = FMath::Max(HorizontalSpeedTowardsBoat, 0.f);

		const float PredictedHorizontalDistanceFromSpeed = HorizontalSpeedTowardsBoat * TimeUntilArrival;

		const FVector BoatVelocity = GetGroundVelocity();
		const float BoatSpeedInDir = BoatVelocity.DotProduct(HorizontalNormalizedDirectionToBoat);
		const float ExtraDistanceFromBoatSpeed = BoatSpeedInDir * TimeUntilArrival;
		HorizontalDistanceToBoat += ExtraDistanceFromBoatSpeed;

		if(PredictedHorizontalDistanceFromSpeed >= HorizontalDistanceToBoat)
			return FVector::ZeroVector;

		float ExtraAcc = (HorizontalDistanceToBoat / (TimeUntilArrival * TimeUntilArrival * 0.5f));

		// clamp it to something sane. It might happen to approach infinity
		ExtraAcc = FMath::Min(10000.f, ExtraAcc);
		ExtraAcc *= SpeedBoostDOT;
		
		if(FMath::IsNearlyZero(ExtraAcc))
			return FVector::ZeroVector;

		float ImpulseMagnitude = ExtraAcc * Dt;

		// consider clamping the speed boost when flying faster than usual
		const float FinalHorizontalSpeedTowardsBoatPrediction = HorizontalSpeedTowardsBoat + ImpulseMagnitude;
		if(FinalHorizontalSpeedTowardsBoatPrediction >= 3600.f)
		{
			/*
				prevent the application of enormous speed boosts just as the player
				is about to hit the water. SpeedBoosts are unlimited on high altitudes because:
			 	- it's harder to tell how fast you are actually flying the higher up you are 
				- a constant increase in speed is what feels nice when skydiving 
				- capped speeds made it easy to foretell that you'd miss the target; making the remaining falltime a drag to wait out
			*/
			const float VerticalDistanceToBoat = FMath::Abs(ToBoat.DotProduct(FVector::UpVector));
			if(VerticalDistanceToBoat < 3600.f)
			{
				return FVector::ZeroVector;
			}
		}

		const FVector SpeedBoostImpulse = HorizontalNormalizedDirectionToBoat * ImpulseMagnitude;

		// PrintToScreen(Player.GetName() + " TimeUntilArrival: " + TimeUntilArrival, 0.f, FLinearColor::Yellow);
		// PrintToScreen(Player.GetName() + " PredictedHorizontalDistanceFromSpeed: " + PredictedHorizontalDistanceFromSpeed, 0.f, FLinearColor::LucBlue);
		// PrintToScreen(Player.GetName() + " HorizontalDistanceToBoat: " + HorizontalDistanceToBoat, 0.f, FLinearColor::LucBlue);
		// PrintToScreen("SpeedBoostDOT: " + SpeedBoostDOT);
		// PrintToScreen("HorizontalSpeedTowardsBoat: " + HorizontalSpeedTowardsBoat, 0.f, FLinearColor::Purple);
		// PrintToScreen("ExtraDistanceFromBoatSpeed: " + ExtraDistanceFromBoatSpeed);
		// System::DrawDebugPoint(BoatPos, 10.f, FLinearColor::Red, 0.f);
		// System::DrawDebugCircle(
		// 	BoatPos,
		// 	500.f,		// Boat radius
		// 	32,
		// 	FLinearColor::Red,
		// 	0.f,
		// 	10.f,
		// 	FVector::ForwardVector,
		// 	FVector::RightVector
		// );

		return SpeedBoostImpulse;
	}

	// verify that nothing has messed with our up impulse
	void VerifyUpImpulse()
	{
		if(TimeSinceImpulse == 0.f) 
			return;

		// verify gravity multiplier
		const float CurrentGravMultiplier = -MoveComp.GetGravityMultiplier();
		if(CurrentGravMultiplier != LaunchGravityMultiplier)
		{
			// The gravity multiplier has been overriden by something. 
			// We'll have to reapply ours otherwise we won't reach the top.
			// ensure(false);
			// devEnsure(false, "the gravity multiplier has been overriden. Everything is still working - but please let Sydney know about this");

			UMovementSettings::ClearGravityMultiplier(Player, this);
			UMovementSettings::SetGravityMultiplier(Player, LaunchGravityMultiplier, this);
		}

		// verify Up speed
		const float TimeUntilSkyDive = FMath::Max(ReachDesiredHeightTime - TimeSinceImpulse, 0.f);
		const float PredictedUpSpeed = TimeUntilSkyDive * LaunchGravity;
		const float UpSpeedError = FMath::Abs(MoveComp.Velocity.Z - PredictedUpSpeed);
		// if(UpSpeedError > 1.f)
		if(UpSpeedError > 20.f)
		{
			FVector CorrectUpSpeedImpulse = FVector::ZeroVector;

			// remove the faulty velocity
			CorrectUpSpeedImpulse.Z -= MoveComp.Velocity.Z;

			// apply the correct one
			CorrectUpSpeedImpulse.Z += PredictedUpSpeed;

			MoveComp.AddImpulse(CorrectUpSpeedImpulse);

			// Print(Player.GetName() + " | TimeUntilSkydive: " + TimeUntilSkyDive);
			// Print("Current Velocity Z: " + MoveComp.Velocity.Z);
			// Print("Predicted Velocity Z: " + PredictedUpSpeed);
			// Print("UpSpeedError: " + UpSpeedError);
			// ensure(false);

		}

	}

	void LerpPlayerToNadoXY(const float Dt)
	{
		const float TimeUntilWeDetach = StayAttachedToNadoTime - TimeSinceImpulse;
		if(TimeUntilWeDetach <= 0.f)
			return;

		const FVector PlayerPos = Player.GetActorLocation();

		FVector TargetLocation = OverlappedWaternado.GetActorLocation();
		TargetLocation.Z = PlayerPos.Z;
		const float DistanceToTarget = (TargetLocation - PlayerPos).Size();

		if(DistanceToTarget <= 0.f)
			return;

		// rotate towards boat while we are in the nado
		FHitResult GroundData = MoveComp.GetLastValidGround();
		AActor Boat = GroundData.GetActor();
		if(Boat != nullptr)
		{
			const FVector BoatPos = Boat.GetActorLocation();
			const FVector ToBoat = BoatPos - PlayerPos;
			const FVector ToBoatHorizontal = ToBoat.VectorPlaneProject(FVector::UpVector);
			FRotator TargetRot = Math::MakeRotFromX(ToBoatHorizontal);
			const float CurrentDeltaDEG = Math::GetAngle(ToBoatHorizontal, MoveComp.GetTargetFacingRotation().Vector());
			if(CurrentDeltaDEG > 0.f)
			{
				const float AlphaSpeed = TimeUntilWeDetach / CurrentDeltaDEG;
				MoveComp.SetTargetFacingDirection(ToBoatHorizontal.GetSafeNormal(), AlphaSpeed);
			}
		}

		const float InvAlphaLeft = FMath::Clamp(TimeUntilWeDetach / ReachDesiredHeightTime, 0.f, 1.f); 
		float AlphaLeft = 1.f - InvAlphaLeft;

		// Bends the alpha curve. @TODO add a curve asset for this if we want to expose it to the user. 
		AlphaLeft = FMath::Pow(AlphaLeft, 9.f);

		const float Stiffness = FMath::Lerp(StartStiffness, EndStiffness, AlphaLeft);
		const float Damping = FMath::Lerp(StartDamping, EndDamping, AlphaLeft);
		const float IdealDampingValue = 2.f * FMath::Sqrt(Stiffness);
		const FVector ToPlayer = Player.GetActorLocation() - TargetLocation;
		FVector SpringVelocity = MoveComp.Velocity;
		SpringVelocity -= (ToPlayer * Dt * Stiffness);
		SpringVelocity /= (1.f + (Dt * Dt * Stiffness) + (Damping * IdealDampingValue * Dt));
		const FVector SpringImpulse = SpringVelocity - MoveComp.Velocity;
		const FVector HorizontalSpringImpulse = SpringImpulse.VectorPlaneProject(FVector::UpVector);

		MoveComp.AddImpulse(HorizontalSpringImpulse);

		// PrintToScreen("AlphaLeft: " + AlphaLeft, 0.f, FLinearColor::Yellow);
		// PrintToScreen("Stiffness: " + AlphaLeft);
		// PrintToScreen("Damping: " + AlphaLeft);
		// PrintToScreen("TimeUntilWeDetach: " + TimeUntilWeDetach);
	}

	float CalcAirDragAccMag(const float InVelocityMag, const float Dt, const float Coeff = 0.003f) const
	{
		if(InVelocityMag <= 0.f)
			return 0.f;

		const float VelocityMagSQ = FMath::Square(InVelocityMag);

		// Calculate drag
		const float DragForceMagnitude = -1.f * Coeff * VelocityMagSQ;
		float DragImpulseMagnitude = DragForceMagnitude * Dt;

		// Clamp drag
		const float DragImpulseMagnitudeSQ = DragImpulseMagnitude * DragImpulseMagnitude;
		if (DragImpulseMagnitudeSQ > VelocityMagSQ)
		{
			const float DownScale = InVelocityMag * FMath::InvSqrt(DragImpulseMagnitudeSQ);
			DragImpulseMagnitude *= DownScale;
		}

		return DragImpulseMagnitude;
	}

	float CalcTimeUntilWeStartFalling(const FVector& InVelocity) const
	{
		const float Gravity = MoveComp.GetGravityMagnitude();
		const float Velocity = InVelocity.DotProduct(FVector::UpVector);
		const float TimeUntilGravityWins = FMath::Abs(Velocity / Gravity);

		// Print("PredictedTime : " + TimeUntilGravityWins, Duration = 4.f);
		// const float PredictedHeight = (Velocity * Velocity) / (2.f * Gravity);
		// Print("PredictedHeight: " + PredictedHeight, Duration = 4.f);

		return TimeUntilGravityWins;
	}

	float CalcTimeUntilWeLand(const float InDeltaHeight) const
	{
		const float Velocity = MoveComp.Velocity.DotProduct(FVector::UpVector);

		// We only support falling prediction atm
		if(Velocity >= 0.f)
		{
			ensure(false);
			return -1.f;
		}

		float Gravity = MoveComp.GetGravityMagnitude();
		float TerminalSpeed = MoveComp.MaxFallSpeed;

		const float DistanceABS = FMath::Abs(InDeltaHeight);
		const float VelocityABS = FMath::Abs(Velocity);
		const float AccelerationABS = VelocityABS >= TerminalSpeed ? 0.f : Gravity;

		const float TimeUntilWeReachTerminalSpeed = (TerminalSpeed - VelocityABS) / Gravity;

		float TimeUntilWeLand = 0.f;
		if(TimeUntilWeReachTerminalSpeed <= 0.f)
			TimeUntilWeLand = PredictTimeOfArrival(DistanceABS, VelocityABS, AccelerationABS);
		else
		{
			float DistanceToTerminalSpeed = VelocityABS * TimeUntilWeReachTerminalSpeed;
			DistanceToTerminalSpeed += (Gravity * FMath::Square(TimeUntilWeReachTerminalSpeed) * 0.5f);
			TimeUntilWeLand = PredictTimeOfArrival(DistanceToTerminalSpeed, VelocityABS, Gravity);
			const float RemainingDistance = FMath::Max(DistanceABS - DistanceToTerminalSpeed, 0.f);
			TimeUntilWeLand += PredictTimeOfArrival(RemainingDistance, TerminalSpeed, 0.f);
		}

		return TimeUntilWeLand;
	}

	float PredictTimeOfArrival(const float InDistance, const float InSpeed, const float InAcceleration) const
	{
		float ETA = 0.f;
		const float A = InDistance;
		const float B = InSpeed;
		const float C = InAcceleration * 0.5f;
		if (C == 0.f && B != 0.f)
		{
			ETA = A / B;
		}
		else if (C != 0.f)
		{
 			const float TheSqrt = FMath::Sqrt((4.f*A*C) + (B*B));
			const float R1 = (TheSqrt - B) / (2.f*C);
			const float R2 = (-(TheSqrt + B)) / (2.f*C);
			ETA = R1 > 0.f ? R1 : R2;
		}
		else 
		{
			ETA = 0.f;
		}
		return ETA;
	}

	FVector GetGroundVelocity() const
	{
		FHitResult GroundData = MoveComp.GetLastValidGround();

		if(GroundData.GetActor() == nullptr)
			return FVector::ZeroVector;

		ATreeBoat Boat = Cast<ATreeBoat>(GroundData.GetActor());

		if(Boat != nullptr)
			return Boat.MovementComponent.Velocity;

		// it might be invalid if the player spawns in the air :/ 
		if(GroundData.GetComponent() == nullptr)
			return FVector::ZeroVector;

		return GroundData.GetComponent().GetPhysicsLinearVelocity();
	}

	void ApplyPOI_GoingDown()
	{
		if(bPOIApplied_GoingDown)
			return;

		PlayFoghornVOBankEvent(OverlappedWaternado.FoghornBank, n"FoghornDBTreeBoatTornadoFreeFall");

		Player.PlayerHazeAkComp.HazePostEvent(EnterSkydiveEvent);
		// PrintToScreen("Broadcast Start skyDive EVent", Duration = 3.f);

		bPOIApplied_GoingDown = true;

		FHitResult GroundData = MoveComp.GetLastValidGround();
		AActor Boat = GroundData.GetActor();
		if(Boat == nullptr)
			return;

		FHazeCameraBlendSettings Blend = CameraBlend::Normal(ToBoatPOIBlendInTime);

		FHazePointOfInterest POI;
		POI.Blend = Blend;
		POI.FocusTarget.Actor = Boat;
		POI.Clamps = ToBoatPOIClamps;

		Player.ApplyForcedClampedPointOfInterest(POI, this, EHazeCameraPriority::Medium);
	}

	void ApplyCamera_GoingUp()
	{
		const float HalfWayUpBlendTime = ReachDesiredHeightTime * 0.5f;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = HalfWayUpBlendTime;

		Player.ApplyCameraSettings(CameraSettings_GoingUp, Blend, this, EHazeCameraPriority::Low);

		// Calculate offset direction; which is orthogonal to the line between the nado and the player
		const FVector NadoToPlayer = (OverlappedWaternado.GetActorLocation() - Player.GetActorLocation());
		FVector Ortho = NadoToPlayer.CrossProduct(FVector::UpVector).GetSafeNormal();
		if(Ortho.DotProduct(Player.GetPlayerViewRotation().Vector()) < 0.f)
			Ortho = -Ortho;

		FHazePointOfInterest POI;
		POI.Blend = Blend;
		POI.FocusTarget.Actor = Player;
		POI.FocusTarget.WorldOffset = Ortho * GoingUpPOIPitchOffset;
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);

		//Player.ApplyIdealDistance(CameraSettingsIdealDistanceFromPlayer, CameraBlend::Normal(HalfWayUpBlendTime), this, EHazeCameraPriority::High);
		Player.ApplyIdealDistance(CameraSettingsIdealDistanceFromPlayer, CameraBlend::Normal(ReachDesiredHeightTime), this, EHazeCameraPriority::High);

		bClearedCamera_GoingUp = false;
	}

	void ClearCamera_GoingUp(const float BlendOutTime = -1.f)
	{
		if(bClearedCamera_GoingUp)
			return;

		// Print(Player.GetName() + " BlendOutTimeGoingDown: " + BlendOutTime);

		Player.ClearIdealDistanceByInstigator(this, BlendOutTime);
		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);

		bClearedCamera_GoingUp = true;
	}

	bool BlackboardContainsWaternado() const
	{
		return GetAttributeObject(n"OverlappedWaternado") != nullptr;
	}

	AWaternado ConsumeWaternadoFromBlackboard()
	{
		UObject OutObject;
		ConsumeAttribute(n"OverlappedWaternado", OutObject);
		return Cast<AWaternado>(OutObject);
	}

}

