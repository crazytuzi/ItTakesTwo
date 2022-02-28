import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingMagnetBoostGate;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingMagnetGateCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent SkateCamComp;

	FIceSkatingAirSettings AirSettings;
	FIceSkatingJumpSettings JumpSettings;
	FIceSkatingFastSettings FastSettings;
	FIceSkatingCameraSettings CamSettings;
	FIceSkatingMagnetSettings MagnetSettings;
	UMagneticPlayerComponent PlayerMagnetComp;

	UMagneticIceSkatingBoostGateComponent ActiveMagnet;
	AIceSkatingMagnetBoostGate ActiveGate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		SkateCamComp = UIceSkatingCameraComponent::GetOrCreate(Player);
		PlayerMagnetComp = UMagneticPlayerComponent::GetOrCreate(Player);
	}

	bool HasPassedGate() const
	{
		if (ActiveGate == nullptr)
			return false;

		FVector ToGate = ActiveGate.ActorLocation - Player.ActorLocation;
		return ToGate.DotProduct(ActiveGate.ImpulseForward) < 0.f;
	}

	float GetDistanceFromGate() const
	{
		if (ActiveGate == nullptr)
			return -1.f;

		FVector ToGate = ActiveGate.ActorLocation - Player.ActorLocation;
		return ToGate.DotProduct(ActiveGate.ImpulseForward);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		auto GateMagnet = Cast<UMagneticIceSkatingBoostGateComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if (GateMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ActiveGate == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (HasPassedGate())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!HasVisionToMagnet())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			// If we're too close to the gate, lock into it until we pass it
			if (GetDistanceFromGate() > MagnetSettings.GateLockDistance)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		ActivationParams.AddObject(n"Magnet", PlayerMagnetComp.GetTargetedMagnet());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActiveMagnet = Cast<UMagneticIceSkatingBoostGateComponent>(ActivationParams.GetObject(n"Magnet"));
		ActiveGate = Cast<AIceSkatingMagnetBoostGate>(ActiveMagnet.Owner);
		SkateComp.ActiveBoostGate = ActiveGate;

		PlayerMagnetComp.ActivateMagnetLockon(ActiveMagnet, this);

		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);

		SkateComp.CallOnMagnetGateGrab(ActiveGate);

		Player.BlockCapabilities(IceSkatingTags::Slope, this);
		Player.BlockCapabilities(IceSkatingTags::Speed, this);		

		ActiveGate.MagnetInteractingPlayerCount ++;

		if(ActiveGate.MagnetInteractingPlayerCount == 1)	
			ActiveMagnet.DopplerDataComp.DopplerInstance.SetEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerMagnetComp.DeactivateMagnetLockon(this);

		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);

		SkateComp.CallOnMagnetGateRelease(ActiveGate);

		ActiveGate.MagnetInteractingPlayerCount --;

		if(ActiveGate.MagnetInteractingPlayerCount == 0)
			ActiveMagnet.DopplerDataComp.DopplerInstance.SetEnabled(false);		

		ActiveMagnet = nullptr;
		ActiveGate = nullptr;
		SkateComp.ActiveBoostGate = nullptr;

		Player.UnblockCapabilities(IceSkatingTags::Slope, this);
		Player.UnblockCapabilities(IceSkatingTags::Speed, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Gate");
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;

			if (MoveComp.IsGrounded())
			{
				FVector ToGate = ActiveGate.ActorLocation - Player.ActorLocation;
				FVector Forward = ActiveGate.ImpulseForward;

				// We want to accelerate/turn towards some location along the gates' forward, but at some fraction of the distance toward it
				//	so that we start lining up with the gate a bit further out, then turn forwards and go through it
				float ToGateDot = -ToGate.DotProduct(Forward);

				ToGateDot *= 0.4f;
				ToGateDot += 100.f; // Offset so that its always a bit in front of the player, otherwise when getting really close to the gate it might be glitchy

				// Get world-location of where we're supposed to be turning
				FVector TargetLocation = ActiveGate.ActorLocation + ActiveGate.ImpulseForward * ToGateDot;
				FVector TargetDirection = TargetLocation - Player.ActorLocation;
				TargetDirection = TargetDirection.ConstrainToPlane(SkateComp.GroundNormal); // Constrain to ground normal so we dont try to turn off the ground
				TargetDirection.Normalize(); 

				// Start turning and accelerating!
				FVector HoriVelocity;
				FVector VertVelocity;
				Math::DecomposeVector(VertVelocity, HoriVelocity, Velocity, SkateComp.GroundNormal);

				// The farther away we are from being aligned with the gate forward, the slower we want to turn
				FVector SidewayOffset = ToGate.ConstrainToPlane(Forward);

				float SidewayError = SidewayOffset.Size();
				SidewayError = Math::Saturate(SidewayError / 2000.f);

				// Slerp it!
				HoriVelocity = Math::SlerpVectorTowards(HoriVelocity, TargetDirection, (1.f - SidewayError * 0.5f) * ActiveGate.TurningCoefficient * DeltaTime);

				// Accelerate as well, but accelerate less if we're currently turning away from the forward (to align ourselves)
				float AccelerateMultiplier = TargetDirection.DotProduct(Forward);
				float Speed = HoriVelocity.Size();

				// Lerp the speed to the target speed of the gate
				if (Speed < ActiveGate.TargetSpeed)
					Speed = FMath::Lerp(Speed, ActiveGate.TargetSpeed, ActiveGate.AccelerationCoefficient * DeltaTime);

				// When we accelerate, just accelerate in the current velocity forward
				FVector VelocityDir = HoriVelocity.GetSafeNormal();
				if (VelocityDir.IsNearlyZero())
					VelocityDir = TargetDirection;

				HoriVelocity = VelocityDir * Speed;
				Velocity = HoriVelocity + VertVelocity;

				// If we're in the air, apply very heavy gravity
				//if (MoveComp.IsAirborne())
					//Velocity -= MoveComp.WorldUp * 12000.f * DeltaTime;

				// Update the ice skating maxspeed so that when we come out of the gate, we keep going fast!
				if (Speed > SkateComp.MaxSpeed)
					SkateComp.MaxSpeed = FMath::Min(Speed, FastSettings.MaxSpeed_Slope);

			}
			else
			{
				FVector ToGate = ActiveGate.ActorLocation - Player.ActorLocation;
				ToGate.Normalize();

				// Heavily accelerate the velocity towards the gate, while applying high drag to
				//	everything else
				FVector VelocityTowardsGate;
				FVector VelocityRest;

				Math::DecomposeVector(VelocityTowardsGate, VelocityRest, Velocity, ToGate);

				// Velocity
				float SpeedTowardsGate = VelocityTowardsGate.DotProduct(ToGate);

				SpeedTowardsGate = FMath::Lerp(SpeedTowardsGate, ActiveGate.TargetSpeed, ActiveGate.AccelerationCoefficient * DeltaTime);
				VelocityTowardsGate = VelocityTowardsGate.GetSafeNormal() * SpeedTowardsGate;

				// Drag
				VelocityRest -= VelocityRest * MagnetSettings.GateAirFriction * DeltaTime;

				Velocity = VelocityTowardsGate + VelocityRest;

				// At last, add gravity
				Velocity += MoveComp.WorldUp * -MagnetSettings.GateAirGravity * DeltaTime;
			}

			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(FrameMove, n"MagnetGate");
		CrumbComp.LeaveMovementCrumb();

		// Force feedback stuff!
		float DistanceToGate = ActiveMagnet.WorldLocation.Distance(Player.ActorLocation);
		float ForceIntensity =
			MagnetSettings.BaseForceFeedback +
			MagnetSettings.DistanceForceFeedback * (1.f - Math::Saturate(DistanceToGate / 4000.f));

		Player.SetFrameForceFeedback(ForceIntensity, ForceIntensity);
	}

	bool HasVisionToMagnet() const
	{
		if (ActiveMagnet == nullptr)
			return false;

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Player);

		FHitResult Hit;
		return !System::LineTraceSingle(Player.ActorLocation, ActiveMagnet.WorldLocation, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, true);
	}
}
