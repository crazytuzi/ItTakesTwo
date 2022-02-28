import Cake.Weapons.Match.MatchHitResponseComponent;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
import Peanuts.Audio.AudioStatics;
import Peanuts.WeaponTrace.WeaponTraceStatics;

event void FMatchActivatedEventSignature(AMatchProjectileActor Match);
event void FMatchDeactivatedEventSignature(AMatchProjectileActor Match);

UCLASS(abstract)
class AMatchProjectileActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bAffectDynamicIndirectLighting = false;
	default Mesh.bCanEverAffectNavigation = false;
	default Mesh.SetCollisionProfileName(n"WeaponDefault");
	default Mesh.SetGenerateOverlapEvents(false);
  	default Mesh.BodyInstance.bNotifyRigidBodyCollision = false;
  	default Mesh.BodyInstance.bUseCCD = false;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.bCastDynamicShadow = false;
	default Mesh.bOwnerNoSee = false;
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);

	UPROPERTY(Category = "Match Physics")
	UHazeCurlNoiseDataAsset NoiseDataAsset;

	/* Initial velocity when launched. 
		(We moved it here for convenience sake, due to multiple ammo types) */
	UPROPERTY(Category = "Match Physics")
 	// float InitialLaunchImpulse = 20000.f;
 	// float InitialLaunchImpulse = 15000.f;
	float InitialLaunchImpulse = 10000.f;

	UPROPERTY(Category = "Match Physics")
	float GravityZ = -982.f * 0.5f;

	// 0 to 1. Bounciness 
	UPROPERTY(Category = "Match Physics")
	float Restitution = 0.03f;

	// We'll do an extra sphere trace if the 
	// match didn't hit a sap With this radius
	UPROPERTY(Category = "Match Trace")
	float ExtraSphereTraceRadius = 100.f;

	// used in line sphere intersection tests.
	UPROPERTY(Category = "Match Trace")
	float VirtualMatchLength = 55.f;

	UPROPERTY(Category = "Match Effects")
	TSubclassOf<AActor> TempActorToSpawnOnStickySurfaces;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;	

	UPROPERTY()
	UDopplerEffect ProjectileDoppler;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MatchStartBurningEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MatchStopBurningEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MatchPassbyEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactGenericEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RicochetEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactShieldEvent;

	UPROPERTY(Category = "Events")
	TArray<TSubclassOf<UMatchProjectileEventHandler>> EventHandlerTypes;
	TArray<UMatchProjectileEventHandler> EventHandlers;

	int32 MaxDeathsByMatch = 0;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transients

	UHazeCrumbComponent MayCrumbComp;

	bool bAllowSwarmToBeDamagedByMatch = false;
	int32 NumDeathsBymatch = 0;

	bool bActive = true;
	FMatchTargetData TargetData;
	FMatchHomingOscillator HomingOscillator;

	// Physics collision
	protected ECollisionEnabled PreAttachment_CollisionType = ECollisionEnabled::NoCollision;
	protected bool PreAttachment_SimulatePhysics = false;
	protected bool bCollisionSettingsAreCached = false;

	// Movement.
	protected TArray<AActor> IgnoreActors;
	protected FVector Velocity = FVector::ZeroVector;
	protected FVector Acceleration = FVector::ZeroVector;
	bool bSweep = false;

	float TimestampLaunch = 0.f;
	float TimestampRicochet = 0.f;
	float TimestampDeactivation = -3.f;

	// We need this for fixing for filling the gap which is created when changing sweep types
	FVector LastHomingSweepLocation = FVector::ZeroVector;

	float RemainingHomingTime = 0.f;

	// we want to have different behaviour until the camera has fully blended in
	bool bAimCameraFullyBlendedIn = true;

	// Transient
	//////////////////////////////////////////////////////////////////////////
	// Events 

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FMatchActivatedEventSignature OnMatchActivated;
		
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FMatchDeactivatedEventSignature OnMatchDeactivated;

	UFUNCTION(BlueprintEvent)
	void HandleStickyHit(FHitResult HitResult) 
	{
		// Actors with response comps will handle their temp mesh spawning themselves. 
		if (ActorHasMatchResponseComp(HitResult.GetActor()) == false && TempActorToSpawnOnStickySurfaces.IsValid())
		{
			AActor SpawnedActor = SpawnActor(TempActorToSpawnOnStickySurfaces.Get());

			bool bSpawnStuff = true;

			// Make sure we ignore some actors
			TArray<AActor> AttachedActors;

			// Ignore actors attached to MAY
			AHazePlayerCharacter May = Game::GetMay();
			May.GetAttachedActors(AttachedActors);
			for (auto AttachedActor : AttachedActors)
			{
				if (AttachedActor == HitResult.GetActor())
				{
					bSpawnStuff = false;
				}
			}

			// Ignore actors attached to CODY 
			AHazePlayerCharacter Cody = Game::GetCody();
			Cody.GetAttachedActors(AttachedActors);
			for (auto AttachedActor : AttachedActors)
			{
				if (AttachedActor == HitResult.GetActor())
				{
					bSpawnStuff = false;
				}
			}

			// we should never be able to hit another match. Are the collision settings set to ignore Weapontrace?
			AMatchProjectileActor AnotherMatch = Cast<AMatchProjectileActor>(HitResult.GetActor());
			ensure(AnotherMatch == nullptr);

			if (bSpawnStuff)
			{
				const FVector AttachLocation = HitResult.ImpactPoint;
				SpawnedActor.AttachToComponent(HitResult.GetComponent(), NAME_None, EAttachmentRule::SnapToTarget);
				SpawnedActor.SetActorLocation(AttachLocation);


				// const FQuat Rot = Math::MakeQuatFromX(-HitResult.ImpactNormal);
				// const FQuat Rot = Math::MakeQuatFromX(-Velocity.GetSafeNormal());
				// SpawnedActor.SetActorRotation(Rot);
				SpawnedActor.SetActorRotation(GetActorQuat());

				/*
				Niagara::SpawnSystemAttached(
					DefaultStickyHitPuff,
					SpawnedActor.GetRootComponent(),
					NAME_None,
					AttachLocation + (HitResult.ImpactNormal * 10.f),
					Math::MakeQuatFromX(HitResult.ImpactNormal).Rotator(),
					EAttachLocation::KeepWorldPosition,
					true
				);
				*/

				ProjectileDoppler.SetEnabled(false);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void HandleNonStickyHit(FHitResult HitResult) 
	{
		// This might cause problems... It isn't really necessary, but it looks better.  
		// SetActorLocation(HitResult.ImpactPoint);

		// Apply PhyX 
		SimulatePhysX(true);

		TimestampRicochet = Time::GetGameTimeSeconds();

		// Collision response. Bounce velocity after the impact using coefficient of restitution.
		const FVector ProjectedVelocity = Velocity.ProjectOnToNormal(HitResult.ImpactNormal);
		Velocity += (ProjectedVelocity * -1.f * (1.f + Restitution));

		// const FVector LinearImpulse = Velocity;
		const FVector LinearImpulse = Velocity.GetSafeNormal() * 2500.f;
		Mesh.AddImpulse(LinearImpulse, NAME_None, true);

		FVector AngularImpulse = LinearImpulse.CrossProduct(FVector::UpVector) * -1.f;
		Mesh.SetPhysicsAngularVelocityInDegrees(AngularImpulse);
	}

	/* When the match is deactivated. */
	UFUNCTION(BlueprintEvent)
	void HandleRecycled() {}

	UFUNCTION(BlueprintEvent)
	void HandleLaunched() {}

	UFUNCTION(BlueprintEvent)
	void HandleLoaded() {}

	void CallOnEnabledEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnEnabled();
	}
	void CallOnDisabledEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnDisabled();
	}
	void CallOnImpactEvent(FHitResult Hit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnImpact(Hit);
	}
	void CallOnRicochetEvent(FHitResult Hit)
	{
		for(auto Handler : EventHandlers)
			Handler.OnRicochet(Hit);
	}
	void CallOnStartBurningEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStartBurning();
	}
	void CallOnStopBurningEvent()
	{
		for(auto Handler : EventHandlers)
			Handler.OnStopBurning();
	}
	void CallOnTickEvent(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}
	void CallOnHandleLoaded()
	{
		for(auto Handler : EventHandlers)
			Handler.OnHandleLoaded();
	}
	void CallOnLaunched()
	{
		for(auto Handler : EventHandlers)
			Handler.OnLaunched();
	}
	void CallOnTickLoadedEvent(float DeltaTime)
	{
		for(auto Handler : EventHandlers)
			Handler.OnTickLoaded(DeltaTime);
	}

	// Events 
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MayCrumbComp = UHazeCrumbComponent::GetOrCreate(Game::May);

//		Noise::InitNoiseLUT();

		// Create event handlers
		for(auto HandlerType : EventHandlerTypes)
		{
			auto Handler = Cast<UMatchProjectileEventHandler>(NewObject(this, HandlerType));
			Handler.InitInternal(this);
			EventHandlers.Add(Handler);
		}	

		ProjectileDoppler = Cast<UDopplerEffect>(HazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
		ProjectileDoppler.SetObjectDopplerValues(false, Observer = EHazeDopplerObserverType::Cody);
		ProjectileDoppler.PlayPassbySound(MatchPassbyEvent, 1.0f, 1.f, VelocityAngle = 0.92f);	
		ProjectileDoppler.SetEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
		{
			UpdateDelayedDisable();
			return;
		}

		// Handle ragdoll
		bool bSimulating = Mesh.IsSimulatingPhysics();
		if(bSimulating)
		{
			// Deactivate the match after 5 seconds of ragdolling
			if(Time::GetGameTimeSince(TimestampRicochet) > 5.f)
			{
				DeactivateMatch();
			}

			// nothing more to update. We are done here.
			return;
		}

		// Ragdoll above, sweeps below.
		if (!bSweep)
			return;

		if(TargetData.IsHomingTowardsInvalidActor())
		{
			RemainingHomingTime = -1.f;
			TargetData.bHoming = false;
			TargetData.bAutoAim = false;
		}

		FVector DeltaMove = CalculateDeltaMovement(DeltaSeconds);

		if (HasControl())
		{
			TArray<FHitResult> Hits;
			if (SweepDeltaMovement(DeltaMove, Hits))
			{
				HandleHits(DeltaMove, Hits);
			}
		}

		// need to check all bools because HandleHits() might've flipped them 
		if(bActive && bSweep && !Mesh.IsSimulatingPhysics())
			ApplyDeltaMovement(DeltaMove, DeltaSeconds);

		// Disable homing once it's reached it destination (after ApplyDeltaMovement())
		if(TargetData.IsHoming() && RemainingHomingTime <= 0.f)
		{
			if(TargetData.bAutoAim)
			{
				if (HasControl())
				{
					devEnsure(false, "The match missed its auto aim target! Make sure that the AutoAimComponent on " + TargetData.Component.Owner.GetName() + " overlaps something that the match can hit" + "\n please notify sydney about this");
//					System::DrawDebugArrow(GetActorLocation(), GetActorLocation() + DeltaMove, 100.f, FLinearColor::Red, 10.f, 3.f);
//					System::DrawDebugPoint(TargetData.GetHomingLocation(), 40.f, FLinearColor::Green, 10.f);
//					System::DrawDebugPoint(TargetData.Component.GetWorldLocation(), 40.f, FLinearColor::Yellow, 10.f);
//					TArray<FHitResult> DebugHits;
//					SweepDeltaMovement(DeltaMove, DebugHits);
//					Time::SetWorldTimeDilation(0.f);
				}

				TargetData.bAutoAim = false;
			}

			TargetData.bHoming = false;
			RemainingHomingTime = 0.f;
		}

		// Tick audio and visual effects 
		CallOnTickEvent(DeltaSeconds);		

		// auto deactivate the match in the rare case of geo missing collision
		const float TimeSinceLaunch = Time::GetGameTimeSince(TimestampLaunch); 
		if(TimeSinceLaunch > 10.f)
		{
			DeactivateMatch();
			return;
		}

	}

	void UpdateDelayedDisable()
	{
/*
		We have to delay the disable because we have to wait for the niagara trail to disperse.

		Why? The niagara components are forever a part of this actors owningcomponents. Even 
		When you change attachment parent THIS will remain that components owner. Same thing 
		goes for when you spawn the component and attach it to the match. So, upon disabling 
		the match, regardless where the component is or who it is attached to,
		it will still get disabled. I COULD expose a function which removes the component 
		from this actors owningComponents, that way the nigara component doesn't get disabled 
		when we disable this actor. Spawning at location and moving the component doesn't work 
		neither. We could spawn and attach it to the world settings actor though...
*/ 
		if(TimestampDeactivation > 0.f)
		{
			const float TimeSinceDeactivation = Time::GetGameTimeSince(TimestampDeactivation); 
			// PrintToScreen("DelayedDecatcation: " + TimeSinceDeactivation);
			if(TimeSinceDeactivation > 3.f)
			{
				// call DeactivateMatch before disabling the actor if this triggers.
				// We do it elsewhere so it shouldn't be needed.
				ensure(!bActive);
				// DeactivateMatch();

				DisableActor(this);
			}
		}
	}

	void HandleSwarmIntersection(ASwarmActor InSwarm, const FHitResult& InHitData)
	{
		// this check is slightly more accurate then the SapColliderComponent
		// (which only updates extents every ~0.5seconds)
		if (!InSwarm.IsWithinMatchIntersectionRadius(GetActorLocation(), VirtualMatchLength))
			return;

		// handle impulses (cosmetic)
		if (InSwarm.NetHandleMatchIntersectionImpulses(
			InSwarm.GetActorTransform().InverseTransformPosition(GetActorLocation()),
			Velocity.GetSafeNormal(),
			VirtualMatchLength
		))
		{
			// overlap check for swarms that have the overlap comp
			auto MatchResponseComp = UMatchHitResponseComponent::Get(InSwarm);
			if (MatchResponseComp != nullptr)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddStruct(n"HitDataToBroadcast", InHitData);

				MayCrumbComp.LeaveAndTriggerDelegateCrumb(
					FHazeCrumbDelegate(this, n"CrumbHandleOverlap"),
					CrumbParams
				);
			}

		}

		// Handle deaths
		if (bAllowSwarmToBeDamagedByMatch && MaxDeathsByMatch > 0 && NumDeathsBymatch < MaxDeathsByMatch)
		{
			FSwarmIntersectionData SwarmIntersectionData;
			if (InSwarm.FindParticlesWithinMatchDeathRadius(
				SwarmIntersectionData,
				GetActorLocation(),
				VirtualMatchLength,
				MaxDeathsByMatch,
				NumDeathsBymatch
			))
			{
				for (auto& MeshIntersectionDataPair : SwarmIntersectionData.MeshIntersectionDataMap)
				{
					const FMeshIntersectionData& IntersectionData = MeshIntersectionDataPair.GetValue();
					USwarmSkeletalMeshComponent SwarmMesh = MeshIntersectionDataPair.GetKey();
					SwarmMesh.NetHandleRequestToKillParticles(IntersectionData);
					bAllowSwarmToBeDamagedByMatch = false;
				}
			}
		}

	}

	UFUNCTION()
	void CrumbHandleOverlap(const FHazeDelegateCrumbData& CrumbData)
	{
		FHitResult HitDataToBroadcast;
		CrumbData.GetStruct(n"HitDataToBroadcast", HitDataToBroadcast);

		UMatchHitResponseComponent MatchResponseComp = UMatchHitResponseComponent::Get(
			HitDataToBroadcast.GetActor()
		);

		if (MatchResponseComp == nullptr)
			return;

		MatchResponseComp.OnOverlap.Broadcast(
			this,
			HitDataToBroadcast.GetComponent(),
			HitDataToBroadcast
		);
	}

	UFUNCTION()
	void CrumbHandleHit(const FHazeDelegateCrumbData& CrumbData)
	{
		// get data from crumb
		FHitResult HitDataToBroadcast;
		CrumbData.GetStruct(n"HitDataToBroadcast", HitDataToBroadcast);
		const FVector DeltaMove = CrumbData.GetVector(n"DeltaMove");
		const bool bClearAutoAim = CrumbData.GetActionState(n"ClearAutoAim");

		if(bClearAutoAim)
			TargetData.bAutoAim = false;

		bSweep = false;

		// Make sure we have correct rotation before broadcasting
		SetRotationFromDeltaMove(DeltaMove);

		UMatchHitResponseComponent MatchResponseComp = UMatchHitResponseComponent::Get(HitDataToBroadcast.GetActor());

		if (HitDataToBroadcast.GetComponent().HasTag(n"TreeProjectileConsume"))
		{
			if (MatchResponseComp != nullptr)
				MatchResponseComp.OnConsumed.Broadcast(this, HitDataToBroadcast.GetComponent(), HitDataToBroadcast);

			DeactivateMatch();

			return;	// !!!
		}

		if (HitDataToBroadcast.GetComponent().HasTag(ComponentTags::MatchStickable))
		{
			//HandleStickyHit(HitDataToBroadcast);
			CallOnImpactEvent(HitDataToBroadcast);
			DeactivateMatch();
		}
		else
		{
			HandleNonStickyHit(HitDataToBroadcast);
			CallOnRicochetEvent(HitDataToBroadcast);
		}

		// need to check this again because the Actor might be destroyed
		// because we broadcasted the OnIgnited event above. 
		if (HitDataToBroadcast.Actor == nullptr)
			return;

		if (MatchResponseComp != nullptr)
		{
			if (HitDataToBroadcast.GetComponent().HasTag(ComponentTags::MatchStickable))
				MatchResponseComp.OnStickyHit.Broadcast(this, HitDataToBroadcast.GetComponent(), HitDataToBroadcast);
			else 
				MatchResponseComp.OnNonStickyHit.Broadcast(this, HitDataToBroadcast.GetComponent(), HitDataToBroadcast);
		}

	}

	bool ActorHasMatchResponseComp(AActor InActor) const
	{
		// BSP might return nullptr actors.
		if (InActor == nullptr)
			return false;

		return UMatchHitResponseComponent::Get(InActor) != nullptr;
	}

	FVector CalculateDeltaMovement(float DeltaTime)
	{
		FVector DeltaMove = FVector::ZeroVector;

		if (TargetData.IsHoming())
		{
			RemainingHomingTime -= DeltaTime;

			const FVector HomingTargetLocation = TargetData.GetHomingLocation();

			DeltaMove = HomingTargetLocation - GetActorLocation();

			// UE4 Traces early outs on deltas that are smaller than Zero
			if (DeltaMove.IsNearlyZero())
			{
				// just keep going in velocity direction if we happen to overshoot the target
				DeltaMove = Velocity * DeltaTime + Acceleration * 0.5f * DeltaTime * DeltaTime;
			}
			else if (RemainingHomingTime > DeltaTime)
			{
				const float HomingFraction = DeltaTime / RemainingHomingTime;

				DeltaMove *= HomingFraction;

				ensure(!DeltaMove.IsZero());

				// Apply homing Oscillations. Only cosmetic; the trace will be constrained during the sweep
				OscillateTowardsHomingTarget(
					DeltaMove,
					HomingTargetLocation,
					HomingFraction,
					DeltaTime
				);

				ensure(!DeltaMove.IsZero());
			}
//			else if (DeltaTime == 0.f)
//			{
//				DeltaMove = FVector::ZeroVector;
//			}
//			else if (DeltaMove.DotProduct(Velocity) <= 0.f)
//			{
//				// just keep going in velocity direction if we happen to overshoot the target
//				DeltaMove = Velocity * DeltaTime + Acceleration * 0.5f * DeltaTime * DeltaTime;
//			}
		}
		else
		{
			DeltaMove = Velocity * DeltaTime + Acceleration * 0.5f * DeltaTime * DeltaTime;
		}

		return DeltaMove;
	}

	void OscillateTowardsHomingTarget(
		FVector& InOutDeltaMove,
		const FVector HomingTargetLocation,
		const float HomingFraction,
		const float DeltaTime
	)
	{
		HomingOscillator.TimeToProcess += DeltaTime;

#if TEST 
		if (HomingOscillator.TimeToProcess > 5.f)
		{
			// I was told that this wouldn't happen... Just placing this here to be sure..
			devEnsure(false, "Match Oscillation time to process exceeded 5 seconds... \n Please let Sydney know about this");
			// ... Did you pause? Did you use time dilation? When does this happen?
			HomingOscillator.TimeToProcess = 0.f;
		}

		ensure(TargetData.Component != nullptr);
		ensure(TargetData.bHoming);

#endif TEST

		FVector CurrentMatchLocation = GetActorLocation();
		// HomingOscillator.Motor.SnapTo(CurrentMatchLocation, Velocity);

		float RampedHomingFraction = 1.f;
//		if(HomingFraction > 0.025f)
//			RampedHomingFraction = 1.f;

		const FVector HomingStartLocation = HomingOscillator.LaunchLocation;

		const FVector HomingLineNormalized = (HomingTargetLocation - HomingStartLocation).GetSafeNormal();

		const float NoiseScale = 1000.f;
		const float NoiseGain = 25000.f * HomingOscillator.FixedTimestep;

		// make the oscillation animation frame rate independent by advecting with a _fixed_ time step.
		while (HomingOscillator.TimeToProcess >= HomingOscillator.FixedTimestep)
		{

			//////////////////////////////////////////////////////////////////////////

			const FVector LocationOnLine = FMath::ClosestPointOnInfiniteLine(
				HomingStartLocation,
				HomingTargetLocation,
				CurrentMatchLocation
			);

			// reseting this value prevents the motor from stabilizing, ensuring oscillations to continue.
			HomingOscillator.Motor.Value = CurrentMatchLocation;

			// Apply curl noise to oscillator velocity, orthogonal to the homingline
			const FVector NoiseSampleLocation = CurrentMatchLocation + HomingOscillator.NoiseWorldOffset;

			// ensure(NoiseScale > 0.f);

			const FVector CurlNoiseAcc = NoiseDataAsset.GetCurl(NoiseSampleLocation, NoiseScale) * NoiseGain;
			// const FVector CurlNoiseAcc = Noise::GetCurlNoise(NoiseSampleLocation, NoiseScale, NoiseGain);
			// Print("CurlNoiseAcc Size: " + CurlNoiseAcc.Size(), 1.0f);

			const FVector CurlNoiseAccProj = CurlNoiseAcc.VectorPlaneProject(HomingLineNormalized);
			HomingOscillator.Motor.Velocity += CurlNoiseAccProj;

			// Apply oscillations to delta movement, orthogonal to the homingline
			HomingOscillator.Motor.SpringTo(LocationOnLine, 600.f, 0.15f, HomingOscillator.FixedTimestep);
			const FVector DeltaToCameraLine = HomingOscillator.Motor.Value - CurrentMatchLocation;
			const FVector DeltaToCameraLineProj = DeltaToCameraLine.VectorPlaneProject(HomingLineNormalized);
			InOutDeltaMove += (DeltaToCameraLineProj * RampedHomingFraction);

			// Apply oscillations to velocity, orthogonal to the homingline
			FVector ToCameraLineVelocityProj = HomingOscillator.Motor.Velocity.VectorPlaneProject(HomingLineNormalized);
			Velocity += (ToCameraLineVelocityProj * RampedHomingFraction);

			//////////////////////////////////////////////////////////////////////////

			HomingOscillator.TimeToProcess -= HomingOscillator.FixedTimestep;
//			CurrentMatchLocation += InOutDeltaMove;
		}

	}

	void ConstrainDeltaTraceToCameraDirectionWhileHoming(FVector InDeltaMove, FVector& InOutTraceStart, FVector& InOutTraceEnd)
	{
		if(TargetData.IsHoming())
		{
			const FVector TargetLocation = TargetData.GetTargetLocation();

			if(LastHomingSweepLocation == FVector::ZeroVector)
			{
				InOutTraceStart = FMath::ClosestPointOnInfiniteLine(
					TargetData.TraceStart,
					TargetLocation,
					InOutTraceStart
				);
			}
			else
			{
				InOutTraceStart = LastHomingSweepLocation;
			}

			InOutTraceEnd = FMath::ClosestPointOnInfiniteLine(
				TargetData.TraceStart,
				TargetLocation,
				InOutTraceEnd
			);

			ensure(!(InOutTraceEnd - InOutTraceStart).IsZero());

			LastHomingSweepLocation = InOutTraceEnd;
		}
		else if(LastHomingSweepLocation != FVector::ZeroVector)
		{
			const FVector ExtraDeltaMove = (GetActorLocation() - LastHomingSweepLocation);
			InOutTraceStart = LastHomingSweepLocation;
			InOutTraceEnd = InOutTraceStart + ExtraDeltaMove;

			// System::DrawDebugLine(InOutTraceStart, InOutTraceEnd, FLinearColor::Yellow, 3.f, 10.f);

			InOutTraceEnd += InDeltaMove;

			ensure(!(InOutTraceEnd - InOutTraceStart).IsZero());

			LastHomingSweepLocation = FVector::ZeroVector;
		}
	}

	bool SweepDeltaMovement(FVector InDeltaMove, TArray<FHitResult>& Hits) 
	{
		FVector TraceStart = GetActorLocation();
		FVector TraceEnd = TraceStart + InDeltaMove;

//		ensure(!(TraceEnd - TraceStart).IsZero());
//		System::DrawDebugLine(TraceStart, TraceEnd, FLinearColor::Blue, 3.f, 4.f);
		ConstrainDeltaTraceToCameraDirectionWhileHoming(InDeltaMove, TraceStart, TraceEnd);
//		System::DrawDebugLine(TraceStart, TraceEnd, FLinearColor::Red, 3.f, 8.f);
//		ensure(!(TraceEnd - TraceStart).IsZero());

		if (TargetData.IsAutoAiming())
		{
			SweepWhileAutoAiming(TraceStart, TraceEnd, Hits);
		}
		else if(TargetData.IsHoming())
		{
			SweepWhileHoming(TraceStart, TraceEnd, Hits);
		}
		else
		{
			// PrintToScreen("Simple tracing!", Duration = 0.0f);
			SimpleTraceMulti(TraceStart, TraceEnd, Hits);
			FindResponseComponentWithSphereTrace(Hits);
		}

		// this will ensure that we get true for overlaps as well.
		return Hits.Num() != 0;
	}

	bool SimpleTraceMulti(const FVector& TraceStart, const FVector& TraceEnd, TArray<FHitResult>& OutHits) const
	{
		// (Multi because we want overlaps)
		return System::LineTraceMulti(
			TraceStart,
			TraceEnd,
			ETraceTypeQuery::WeaponTrace,
			false,		// btraceComplex
			IgnoreActors,
			EDrawDebugTrace::None,
			OutHits,
			true
		);
	}

	void FindResponseComponentWithSphereTrace(TArray<FHitResult>& Hits) const
	{
		// Do an extra big sphere trace if we didn't hit anything with response comp.
		for (int32 i = Hits.Num() - 1; i >= 0 ; i--)
		{
			if(ActorHasMatchResponseComp(Hits[i].GetActor()))
				break;

			if(!Hits[i].bBlockingHit)
				continue;

			TArray<FHitResult> ExtraHits;
			if (DoSphereSweep(Hits[i].ImpactPoint, false, ExtraHits))
			{
				for (int32 j = ExtraHits.Num() - 1; j >= 0 ; j--)
				{
					if(ActorHasMatchResponseComp(ExtraHits[j].GetActor()))
					{
						// We only allow 1 blockingHit in the Hits array
						Hits.RemoveAt(i);

						Hits.Add(ExtraHits[j]);

						break;
					}
				}
			}
		}
	}

	void SweepWhileAutoAiming(const FVector& TraceStart, const FVector& TraceEnd, TArray<FHitResult>& OutHits) const
	{
		/*
			The match will only be blocked by the auto-aimed actor, while auto-aiming.
			-- but with the exception of actors with the BlockWeaponComponent.

			To achieve this we'll do:

			1. Complex trace against the auto aimed actor
			2. Continue with simple trace against the world in order to find overlaps 
				(and simple hits against the auto-aim target if the Complex trace fails)
			3. Upon hit: remove any blocking hit from the simple hits, keep overlaps and check for the "exception" component

			We do complex trace first because simple trace -> complex trace has proved to be unreliable.
		*/

		// (@TODO: make sure no landscape actors have auto-aim-components in tree)
		FHitResult AutoAimHitData;
		if(Trace::ActorLineTraceSingle(
			TargetData.Component.Owner,
			TraceStart,
			TraceEnd,
			ETraceTypeQuery::WeaponTrace,
			true,	// bComplexTrace
			AutoAimHitData
		))
		{
			// Comp.LineTraceComponent() doesn't set the blocking hit /shrug
			AutoAimHitData.SetBlockingHit(true);

			OutHits.Add(AutoAimHitData);
		}

		// early out once we hit the auto aim target with a complex trace
		if(OutHits.Num() > 0)
			return;

		// simple trace against the world because we want to 
		// catch overlaps on our way to the auto aim target
		// (and also hit the auto aim target if the complex trace fails)
		SimpleTraceMulti(TraceStart, TraceEnd, OutHits);

		// Remove all blocking hits but allow overlaps and exceptional components while auto-aiming
		for (int i = OutHits.Num() - 1; i >= 0 ; i--)
		{
			// we hit the auto aim target! Only 1 blocking hit allowed per trace so we early out here
			if (OutHits[i].Actor == TargetData.Component.Owner)
				break;

			if (OutHits[i].bBlockingHit && !WeaponTrace::IsProjectileBlockingComponent(OutHits[i].Component))
				OutHits.RemoveAt(i);
		}

	}

	void SweepWhileHoming(const FVector& TraceStart, const FVector& TraceEnd, TArray<FHitResult>& OutHits) const
	{
		/*
			1. Complex trace against the component we assume we are going to hit.
			2. Simple trace against the world, when the complex trace fails.
			3. Verify the simple hit by complex tracing against the component we just hit

			We do the complex trace in the first step because complex traces only work on the surface,
			and are thus unreliable. A simple trace followed by a complex trace verification will fail
			when the simple collision is within the complex collision shell.
		*/

		FHitResult ComplexHitData;
		if(TargetData.ComplexTraceTargetComponent(TraceStart, TraceEnd, ComplexHitData))
		{
			OutHits.Add(ComplexHitData);

			// @TODO maybe we should do a simple overlap sweep to catch overlaps?
			return;
		}

		SimpleTraceMulti(TraceStart, TraceEnd, OutHits);

		if(OutHits.Num() > 0 )
			ReplaceSimpleBlockingHitWithComplexHit(TraceStart, TraceEnd, OutHits);

		FindResponseComponentWithSphereTrace(OutHits);
	}

	void ReplaceSimpleBlockingHitWithComplexHit(const FVector& TraceStart, const FVector& TraceEnd, TArray<FHitResult>& Hits) const
	{
		// replace simple blocking hits with complex ones, but allow overlaps.
		for (int i = Hits.Num() - 1; i >= 0 ; i--)
		{
			if (!Hits[i].bBlockingHit)
				continue;

			// complex trace the thing we hit to ensure that we hit the visible part of it
			FHitResult ComplexHitData;
			FName DummySocketName = NAME_None;
			FVector DummyLocation, DummyNormal = FVector::ZeroVector; 
			const bool bComplexHit = Hits[i].Component.LineTraceComponent(
				TraceStart,
				TraceEnd,
				true, 	// bTraceComplex = true,
				false, 	// bShowtrace = false,
				false, 	// bPersistenShowTrace = false,
				DummyLocation,
				DummyNormal,
				DummySocketName,
				ComplexHitData
			);

			// always remove simple blocking hit
			Hits.RemoveAt(i);

			// replace simple blocking hit with complex one
			if(bComplexHit)
			{
				ComplexHitData.SetBlockingHit(true);
				Hits.Add(ComplexHitData);
			}

		}
	}

	// Should only be called on HasControl(), contains netfunctions.
	void HandleHits(const FVector& DeltaMove, TArray<FHitResult>& Hits)
	{
		// Handle swarm hit
		for (int i = Hits.Num() - 1; i >= 0 ; i--)
		{
			// BSP's
			if (Hits[i].Actor == nullptr)
				continue;

			ASwarmActor HitSwarm = Cast<ASwarmActor>(Hits[i].Actor);
			if (HitSwarm == nullptr)
				continue;

			HandleSwarmIntersection(HitSwarm, Hits[i]);

			// Discard the hit because it has been 'handled'
			Hits.RemoveAt(i);
		}

		// Might be empty after the swarm check above.
		if(Hits.Num() == 0)
			return;

		// handle blocks and overlaps
		for (int32 i = Hits.Num() - 1; i >= 0 ; i--)
		{
			if (Hits[i].Actor == nullptr)
				continue; // BSPs...

			const bool bNetworked = Network::IsObjectNetworked(Hits[i].GetActor());
			if(!devEnsure(
				bNetworked,
				"Match hit " + 
				Hits[i].Actor + 
				", which isn't networked. This might cause problems...\n 
				Let sydney know about this please"))
			{
				continue;
			}

			if (Hits[i].bBlockingHit)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddStruct(n"HitDataToBroadcast", Hits[i]);
				CrumbParams.AddVector(n"DeltaMove", DeltaMove);

				if (TargetData.IsAutoAiming() || !TargetData.IsHoming())
					CrumbParams.AddActionState(n"ClearAutoAim");

				// @TODO: we might have to send over results and build a 
				// queue which we pick from when the crumb triggers?

				MayCrumbComp.LeaveAndTriggerDelegateCrumb(
					FHazeCrumbDelegate(this, n"CrumbHandleHit"),
					CrumbParams
				);
			}
			else
			{
				// overlap check for those that have the response component 
				auto MatchResponseComp = UMatchHitResponseComponent::Get(Hits[i].GetActor());
				if (MatchResponseComp != nullptr)
				{
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddStruct(n"HitDataToBroadcast", Hits[i]);

					MayCrumbComp.LeaveAndTriggerDelegateCrumb(
						FHazeCrumbDelegate(this, n"CrumbHandleOverlap"),
						CrumbParams
					);
				}
			}

		} // end for hit loop
	}

	void FilterOutInvalidHitsWhileAutoAiming(const FVector& TraceStart, const FVector& TraceEnd, TArray<FHitResult>& Hits)
	{
		/*
			The match will only be blocked by the auto-aimed actor, while auto-aiming.
			-- but with the exception of actors with the BlockWeaponComponent.

			To make this work we'll do:
			1. LineTrace against the world (simple collision)
			2. Upon hit: Remove any blocks, keep overlaps and check for the exception component
			3. Do a complex trace against _only_ the auto-aimed actor for valid blocks

			(we do normal trace first due to the potential long length of the delta move) 
		*/

		bool bLineTraceAutoAimComp = true;

		for (const auto& Hit : Hits)
		{
			if(WeaponTrace::IsProjectileBlockingComponent(Hit.Component))
			// if(WeaponTrace::HasProjectileBlockingComponent(Hit.Actor))
			{
				bLineTraceAutoAimComp = false;
				break;
			}
		}

		// only skip the filtering if we hit an exceptional component 
		if(!bLineTraceAutoAimComp)
			return;

		// We remove all blocking hits but allow overlaps while auto-aiming
		for (int i = Hits.Num() - 1; i >= 0 ; i--)
		{
			if(Hits[i].bBlockingHit)
			{
				Hits.RemoveAt(i);
				break;
			}
		}

		// We consider actor trace to be safe here because landscapes 
		// aren't gonna have auto-aim components... RIGHT? 
		FHitResult AutoAimHitData;
		if(Trace::ActorLineTraceSingle(
			TargetData.Component.Owner,
			TraceStart,
			TraceEnd,
			ETraceTypeQuery::WeaponTrace,
			true,	// bComplexTrace
			AutoAimHitData
		))
		{
			// Comp.LineTraceComponent() doesn't set the blocking hit /shrug
			AutoAimHitData.SetBlockingHit(true);

			Hits.Add(AutoAimHitData);
		}

	}

	bool DoSphereSweep(const FVector& WorldLocation, const bool bComplexTrace, TArray<FHitResult>& OutHits) const
	{
		return System::SphereTraceMulti(
			WorldLocation,
			WorldLocation,
			ExtraSphereTraceRadius,
			ETraceTypeQuery::WeaponTrace,
			bComplexTrace,
			IgnoreActors,
			EDrawDebugTrace::None,
			OutHits,
			true
		);
	}

	void SetRotationFromDeltaMove(const FVector& DeltaMove)
	{
		SetActorRotation((-DeltaMove).ToOrientationQuat());
	}

	void ApplyDeltaMovement(FVector DeltaMovement, float DeltaTime) 
	{
		// Translation
		AddActorWorldOffset(DeltaMovement);

		SetRotationFromDeltaMove(DeltaMovement);

		if (TargetData.IsHoming())
		{
			Velocity = DeltaMovement / DeltaTime;
			Acceleration = FVector::ZeroVector;

			// Oscillator: really low Dt values will make the spring diverge a bit. Clamp it to 200hz
			HomingOscillator.Motor.Velocity = Velocity;
//			HomingOscillator.Motor.Velocity = DeltaMovement / FMath::Max(DeltaTime, 0.005f);
		}
		else
		{
			const FVector Gravity = FVector(0.f, 0.f, GravityZ);
			Acceleration = Gravity;
			Velocity += Acceleration * DeltaTime;

			// the oscillator
			HomingOscillator.Motor.Velocity = Velocity;
		}

	}

	void Launch(FMatchTargetData InTargetData)
	{
		TargetData = InTargetData;

		AddIgnoreActor(GetOwner());

#if TEST 
		/*	ensure that the match is where we assume it is
			because we do location based calculations down below. */
		const FVector MayLocation = Game::GetMay().GetActorCenterLocation();
		const float DistanceToWeapon = (GetActorLocation() - MayLocation).Size();
		if(DistanceToWeapon > 500.f)
		{
			// The match isn't near the weapon when being launched... why?
			System::DrawDebugSphere(GetActorLocation(), Duration = 4.f);
			Print("DistanceToWeapon: " + DistanceToWeapon, Duration = 4.f);
			devEnsure(false, "The match projectile wasn't near the Sniper when launched.\n " +
				"DistanceToWeapon: " + DistanceToWeapon +
				"\n Please take a screenshot and send it to Sydney"
			);
		}
#endif TEST

		auto Rule = EDetachmentRule::KeepWorld;
		DetachFromActor(Rule,Rule,Rule);

		ActivateMatch();

		FVector LaunchDirection = TargetData.GetTargetLocation() - GetActorLocation();
		LaunchDirection.Normalize();

		ApplyLaunchImpulse(LaunchDirection);

		TimestampLaunch = Time::GetGameTimeSeconds();
 		SimulatePhysX(false);
		bSweep = true;

		RemainingHomingTime = 0.f;
		HomingOscillator = FMatchHomingOscillator();
		LastHomingSweepLocation = GetActorLocation();

#if TEST 
		if(TargetData.bAutoAim)
			ensure(TargetData.IsHoming());
#endif TEST

		if (TargetData.IsHoming())
		{
			const FVector HomingLocation = TargetData.GetHomingLocation();
			const float DistToHomingLocation = HomingLocation.Distance(GetActorLocation());
			RemainingHomingTime = DistToHomingLocation / InitialLaunchImpulse;

			HomingOscillator.Motor.SnapTo(GetActorLocation(), Velocity);

			HomingOscillator.LaunchLocation = GetActorLocation();
			if(bAimCameraFullyBlendedIn)
			{
				// the oscillations will funk out if the camera is to far away. Lets limit range.
				FVector LaunchLocationRange = TargetData.TraceStart - GetActorLocation();

				FVector DeltaVertical = LaunchLocationRange.ProjectOnToNormal(FVector::UpVector);
				DeltaVertical = DeltaVertical.GetClampedToMaxSize(100.f);

				FVector DeltaHorizontal = LaunchLocationRange.VectorPlaneProject(FVector::UpVector);
				DeltaHorizontal = DeltaHorizontal.GetClampedToMaxSize(100.f);

				FVector FurthestLaunchLocation = GetActorLocation();
				FurthestLaunchLocation += DeltaVertical;
				FurthestLaunchLocation += DeltaHorizontal;

				// Print("DeltaHorizontal: " + DeltaHorizontal.Size());
				// Print("DeltaVertical: " + DeltaVertical.Size());

				HomingOscillator.LaunchLocation = FMath::Lerp(
					GetActorLocation(),
					FurthestLaunchLocation,
					FMath::RandRange(0.f, 1.f)
				);

				// HomingOscillator.LaunchLocation = FurthestLaunchLocation;
				// HomingOscillator.LaunchLocation = GetActorLocation();
				// HomingOscillator.LaunchLocation = TargetData.TraceStart;
			}

			// we offset the noise in order to increase the chance of
			// creating a unique noise pattern for every match launch
			const float NoiseTimeOffset = Time::GetGameTimeSeconds() * 10000.f % 10000.f;
			HomingOscillator.NoiseWorldOffset = FVector(NoiseTimeOffset);

//			Print("NoiseTimeOffset: " + NoiseTimeOffset, Duration = 5.f);
//			System::DrawDebugPoint(TargetData.TraceStart, 5.f, FLinearColor::Blue, 0.f);
//			System::DrawDebugPoint(HomingOscillator.LaunchLocation, 5.f, FLinearColor::Yellow, 0.f);
//			System::DrawDebugPoint(GetActorLocation(), 5.f, FLinearColor::Red, 0.f);
		}

		HandleLaunched();
		CallOnLaunched();
		CallOnStartBurningEvent();
	}

	void ApplyLaunchImpulse(FVector ShootDirection)
	{
		Velocity = ShootDirection * InitialLaunchImpulse;
	}

	FVector GetProjectileAcceleration() const 
	{
		return Acceleration;
	}

	void AddIgnoreActor(AActor ActorToIgnore) 
	{
		IgnoreActors.AddUnique(ActorToIgnore);
	}

	void RemoveIgnoreActor(AActor IgnoredActor)
	{
		IgnoreActors.RemoveSwap(IgnoredActor);
	}

	void SimulatePhysX(bool bSimulate) 
	{
		if (bSimulate)
		{
			ApplyCachedPhysicsSettings();
			Mesh.SetSimulatePhysics(true);
			Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		}
		else 
		{
			DisableAndCachePhysicsSettings();
		}
	}

	/* Needs to be done BEFORE we attach */
	void DisableAndCachePhysicsSettings()
	{
		if (bCollisionSettingsAreCached)
			return;

		PreAttachment_CollisionType = Mesh.GetCollisionEnabled();
		PreAttachment_SimulatePhysics = Mesh.IsSimulatingPhysics();
		Mesh.SetSimulatePhysics(false);
		Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		bCollisionSettingsAreCached = true;
	}

	/* Needs to be done AFTER we detach */
	void ApplyCachedPhysicsSettings()
	{
		if (!bCollisionSettingsAreCached)
			return;

		Mesh.SetCollisionEnabled(PreAttachment_CollisionType);
		Mesh.SetSimulatePhysics(PreAttachment_SimulatePhysics);
		bCollisionSettingsAreCached = false;
	}

	void ActivateMatch() 
	{
		if (bActive == true)
			return;

		// we delay the deactivation due to nigara, 
		// so we can't be sure if it is disabled
		if(IsActorDisabled(this))
		{
			EnableActor(this);
			TimestampDeactivation = 0.f;
		}

 		// SetActorTickEnabled(true);
		HideMatch(false);
		bActive = true;		

		OnMatchActivated.Broadcast(this);
		CallOnEnabledEvent();		

		if(ProjectileDoppler != nullptr)
		{
			ProjectileDoppler.SetEnabled(true);
		}		

	}

	UFUNCTION()
	void DeactivateMatch() 
	{
		if (bActive == false)
			return;

		CallOnStopBurningEvent();
						
		bActive = false;
		HideMatch(true);
 		// SetActorTickEnabled(false);

		bAllowSwarmToBeDamagedByMatch = true;

		bSweep = false;
 		SimulatePhysX(false);

		OnMatchDeactivated.Broadcast(this);
 		HandleRecycled();
		CallOnDisabledEvent();

		if(ProjectileDoppler != nullptr)
		{			
			ProjectileDoppler.SetEnabled(false);
			ProjectileDoppler.ResetPassbyTimer(MatchPassbyEvent);			
		}		

		TimestampDeactivation = Time::GetGameTimeSeconds();
		// DisableActor(this);
	}

	void HideMatch(bool bNewHide)
	{
		// Only hide mesh. Particle effects will get 
		// hidden as well if we hide actor.
		Mesh.SetHiddenInGame(bNewHide);

		// SetActorHiddenInGame(bNewHide);
	}

	UFUNCTION(BlueprintEvent)
	void BP_MatchTorchVelocity(float DeltaSeconds)
	{
		
	}
};

struct FMatchHomingOscillator
{
	// the thing that tries to counter the oscillations (and might in turn create oscillations)
	FHazeAcceleratedVector Motor = FHazeAcceleratedVector();

	// where the match was when launched from the weapon
	FVector LaunchLocation = FVector::ZeroVector;

	// Keeps tracking of how much time needs to be stepped
	float TimeToProcess = 0.f;

	// we offset the noise for every match in to increase the chance of every match getting a unique noise pattern
	FVector NoiseWorldOffset = FVector::ZeroVector;

	float FixedTimestep = 1.f / 120.f;
};

struct FMatchTargetData
{
	FMatchTargetData()
	{
		bAutoAim = false;
		bHoming = false;
		TraceStart = FVector::ZeroVector;
		TraceEnd = FVector::ZeroVector;
		RelativeLocation = FVector::ZeroVector;
		Component = nullptr;
		Socket = NAME_None;
	}

	// weapon socket projected onto a line defined by the camera view
	FVector TraceStart = FVector::ZeroVector;

	// offset along camera view. 
	FVector TraceEnd = FVector::ZeroVector;

	// implies homing + collision enabled _only_ for the autoaimed target
	bool bAutoAim = false;

	// implies homing + collision enabled for all geometry. Does not necessarily mean that we have an autoaimed target.
	bool bHoming = false;

	// data user to figure out the correct location in network
	FVector RelativeLocation = FVector::ZeroVector;
	USceneComponent Component = nullptr;
	FName Socket = NAME_None;

	bool ComplexTraceTargetComponent(const FVector& TraceStart, const FVector& TraceEnd, FHitResult& OutHit) const
	{
		FName DummySocketName = NAME_None;
		FVector DummyLocation, DummyNormal = FVector::ZeroVector; 
		const bool bComplexHit = GetPrimitiveComponent().LineTraceComponent(
			TraceStart,
			TraceEnd,
			true, 	// bTraceComplex = true,
			false, 	// bShowtrace = false,
			false, 	// bPersistenShowTrace = false,
			DummyLocation,
			DummyNormal,
			DummySocketName,
			OutHit
		);

		if(bComplexHit)
		{
			OutHit.SetBlockingHit(true);
		}

		return bComplexHit;
	}

	UPrimitiveComponent GetPrimitiveComponent() const
	{
		return Cast<UPrimitiveComponent>(Component);
	}

	bool IsAutoAiming() const
	{
		// the actor might get destroyed while homing 
		if (Component == nullptr)
			return false;

		return bAutoAim;
	}

	bool IsHomingTowardsInvalidActor() const
	{
		if(!IsHoming())
			return false;

		if(Component.Owner.IsActorBeingDestroyed())
			return true;

		AHazeActor PotentialHazeActor = Cast<AHazeActor>(Component.Owner);
		if(PotentialHazeActor != nullptr && PotentialHazeActor.IsActorDisabled())
			return true;

		return false;
	}

	bool IsHoming() const
	{
		// the actor might get destroyed while homing 
		if (Component == nullptr)
			return false;

		return bHoming;
	}

	void SetTargetLocation(const FVector& InWorldPos, USceneComponent InComp, FName InSocketName = NAME_None) 
	{
		if(!ensure(InComp != nullptr))
			return;

		Component = InComp;
		Socket = InSocketName;

		RelativeLocation = InComp.GetSocketTransform(InSocketName).InverseTransformPosition(InWorldPos);
	}

	FVector GetTargetLocation() const
	{
		if(IsHoming())
			return GetHomingLocation();

		return TraceEnd;
	}

	FVector GetHomingLocation() const
	{

#if TEST 
		// we should check IsHoming() before calling this function.
		ensure(bHoming);
		ensure(Component != nullptr);
#endif TEST

		return Component.GetSocketTransform(Socket).TransformPosition(RelativeLocation);
	}

};

UCLASS(abstract)
class UMatchProjectileEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly, NotVisible)
	AMatchProjectileActor Owner;

	void InitInternal(AMatchProjectileActor Projectile)
	{
		SetWorldContext(Projectile);
		Owner = Cast<AMatchProjectileActor>(Projectile);
		Init();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void Init() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnEnabled() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDisabled() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnRicochet(FHitResult Hit) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStartBurning() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnStopBurning() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTickLoaded(float DeltaTime) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnHandleLoaded() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLaunched() {}
}