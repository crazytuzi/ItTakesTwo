import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;

class UIceSkatingAirGlideCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::FreeFall);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UHazeAsyncTraceComponent TraceComp;

	UHazeMovementComponent MoveComp;
	FIceSkatingJumpSettings JumpSettings;
	FIceSkatingAirSettings AirSettings;
	FHitResult LastGroundedHit;

	bool bHasAsyncTraceResult = false;

	FHitResult PredictedGroundHit;
	ASnowGlobeSwimmingVolume PredictedSwimmingVolume;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		TraceComp = UHazeAsyncTraceComponent::GetOrCreate(Player);
	}

	FVector FindPredictedLandLocation() const
	{
		FVector PredictVelocity = MoveComp.Velocity;
		if (MoveComp.IsGrounded())
			PredictVelocity.Z = JumpSettings.GroundImpulse;

		FVector Result;
		if (!TrajectoryPlaneIntersection(Player.ActorLocation, PredictVelocity, LastGroundedHit.Location, AirSettings.Gravity, Result, MoveComp.WorldUp))
			return Player.ActorLocation;

		return Result;
	}

	void FindPredictedGroundHit() const
	{ 
		float SearchHeight = AirSettings.GlideSearchHeight_Grounded;
		FVector LandLocation = FindPredictedLandLocation();

		FHazeTraceParams Trace;
		Trace.InitWithCollisionProfile(n"PlayerCharacter");
		Trace.IgnoreActor(Player);

		if (IsDebugActive())
			Trace.DebugDrawTime = 0.f;

		Trace.From = LandLocation + MoveComp.WorldUp * AirSettings.GlideSearchUpOffset;
		Trace.To = LandLocation - MoveComp.WorldUp * SearchHeight;

		TraceComp.TraceMulti(Trace, this, n"FindPredictedGroundHitResult");
	}

	UFUNCTION(NotBlueprintCallable)
	private void FindPredictedGroundHitResult(UObject Instigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		if(SkateComp.bIsIceSkating && !IsBlocked())
		{
			bHasAsyncTraceResult = true;
			PredictedGroundHit = FHitResult();
			PredictedSwimmingVolume = nullptr;

			for(auto Hit : Obstructions)
			{
				if (Hit.bBlockingHit)
				{
					PredictedGroundHit = Hit;
					break;
				}

				if (PredictedSwimmingVolume == nullptr)
					PredictedSwimmingVolume = Cast<ASnowGlobeSwimmingVolume>(Hit.Actor);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if(!bHasAsyncTraceResult)
			 return EHazeNetworkActivation::DontActivate;

		if (PredictedGroundHit.bBlockingHit && PredictedSwimmingVolume == nullptr)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsGrounded() && bHasAsyncTraceResult)
		{
			if (PredictedGroundHit.bBlockingHit && Cast<ASnowGlobeSwimmingVolume>(PredictedGroundHit.Actor) == nullptr)
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
			LastGroundedHit = MoveComp.DownHit;

		if (SkateComp.bIsIceSkating && !IsBlocked())
			FindPredictedGroundHit();
		else
			bHasAsyncTraceResult = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SkateComp.bShouldAirGlide = true;
		SkateComp.CallOnAirGlideStartedEvent();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SkateComp.bShouldAirGlide = false;
		SkateComp.bGoingIntoWater = false;
		SkateComp.CallOnAirGlideEndedEvent();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PredictedSwimmingVolume != nullptr)
			SkateComp.bGoingIntoWater = true;
	}
}
