import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Effects.DeadWaspSpawnerActor;
import Cake.LevelSpecific.Tree.Swarm.Audio.SwarmCoreHandleDeadParticleAudio;
import Cake.Weapons.Sap.SapManager;

class USwarmCoreHandleDeadParticlesCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCoreHandleDeadParticles");

	// default TickGroup = ECapabilityTickGroups::LastMovement;

	// We need to ensure that the anim thread is done before this runs
	default TickGroup = ECapabilityTickGroups::PostWork;

	ASwarmActor SwarmActor = nullptr;
	AActor CascadeDeadWaspSpawner;
	UParticleSystemComponent CascadeDeadWaspSpawnerComponent;
	ADeadWaspSpawnerActor NiagaraDeadWaspSpawner;
	TArray<USwarmSkeletalMeshComponent> SwarmSkelMeshComps;
	USwarmCoreDeadParticleAudioEffect SwarmAudioHandler;

	float TimeStamp_RadialDeathImpulse = 0.f;
	float DEBUG_TimeStamp = 0.f;

	// bookkeeping the indices for the particles that we've spawned a dead particle for this frame
	TArray<int32> ParticlesSpawnedThisFrame;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
		SwarmActor.GetComponentsByClass(SwarmSkelMeshComps);
//		CascadeDeadWaspSpawner = SpawnActor(AActor::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator);
//		CascadeDeadWaspSpawnerComponent = UParticleSystemComponent::GetOrCreate(CascadeDeadWaspSpawner);
//		CascadeDeadWaspSpawnerComponent.SetTemplate(SwarmActor.CascadeDeadWaspSpawnerTemplate);
		NiagaraDeadWaspSpawner = GetOrCreateDeadWaspSpawner();
		ParticlesSpawnedThisFrame.Reserve(960);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SwarmActor.AreVFXParticlesRequested() && !SwarmActor.AreParticleMarkedForDeath())
			return EHazeNetworkActivation::DontActivate;

		// !!! This should be local. Otherwise remote might 
		// be disabled by control before it is done.
		// the network handling for this is handled during
		// the intersection phase in SwarmActor
		return EHazeNetworkActivation::ActivateLocal;
		// return EHazeNetworkActivation::ActivateFromControl
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SwarmActor.AreVFXParticlesRequested() && !SwarmActor.AreParticleMarkedForDeath())
		{
			// !!! This should be local. Otherwise remote might 
			// be disabled by control before it is done.
			// the network handling for this is handled during
			// the intersection phase in SwarmActor
			return EHazeNetworkDeactivation::DeactivateLocal;
			// return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParam)
	{
		if (SwarmActor.HazeAkComp != nullptr && 
			SwarmAudioHandler == nullptr) 
		{
			SwarmAudioHandler = Cast<USwarmCoreDeadParticleAudioEffect>(
				SwarmActor.DeathEffectHazeAkComp.AddEffect(USwarmCoreDeadParticleAudioEffect::StaticClass(),
					false, false
				));
			SwarmAudioHandler.SetupEvents(SwarmActor);
		}

		TimeStamp_RadialDeathImpulse = Time::GetGameTimeSeconds();
	}
	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// we don't want to spawn niagara effects if cutscene blocks us for example.
		if(!IsBlocked())
		{
			const float Dt = SwarmActor.GetActorDeltaSeconds();
			while (SwarmActor.AreVFXParticlesRequested() || SwarmActor.AreParticleMarkedForDeath())
			{
				// this happens because the swarm gets disabled prematurely.
				// Print("Not all particles are dead! Kill 'em, Kill 'em all");
				ensure(SwarmSkelMeshComps.Num() != 0);
				for(USwarmSkeletalMeshComponent SkelMeshComp : SwarmSkelMeshComps)
				{
					KillParticles(SkelMeshComp, Dt);
				}
			}
		}

		// make sure we kill all particles if control side dies and triggers disable actor.
		if(SwarmActor.AreParticlesAlive() && SwarmActor.IsAboutToDie())
		{
//			Print("Forced ControlSide kill them all");
			ensure(SwarmSkelMeshComps.Num() != 0);
			for(USwarmSkeletalMeshComponent SkelMeshComp : SwarmSkelMeshComps)
			{
				SkelMeshComp.KillAllParticles();
				SkelMeshComp.ParticleindicesMarkedForDeath.Empty();
				SkelMeshComp.ExtraVFXParticles.Empty();
			}
		}

		TimeStamp_RadialDeathImpulse = 0.f;
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// same as reset?
		ParticlesSpawnedThisFrame.Reset(960);

		for(USwarmSkeletalMeshComponent SkelMeshComp : SwarmSkelMeshComps)
			KillParticles(SkelMeshComp, DeltaSeconds);
	}

	void KillParticles(USwarmSkeletalMeshComponent InSkelMeshComp, const float Dt) 
	{
		const FSwarmAnimationSettings& CurrentAnimSettings = InSkelMeshComp.GetSwarmAnimSettingsDataAsset().Settings;

		// Simplified version of: 1 second / (NumParticles / time)
		const float SubStepFixedDeltaTime = FMath::Max(
			CurrentAnimSettings.MinimumTimeToKill / 120.f,
			KINDA_SMALL_NUMBER
		);

//		if(SwarmActor.IsAboutToDie())
//		{
//			if(Time::GetGameTimeSince(TimeStamp_RadialDeathImpulse) > 0.125f)
//			{
//				const float SwarmRad = SwarmActor.SkelMeshComp.GetSwarmRadius();
//				FSwarmForceField RadialImpulseSettings;
//				RadialImpulseSettings.Radius = SwarmRad;
//				RadialImpulseSettings.Strength = 1000;
//				RadialImpulseSettings.bLinearFalloff = true;
//				SwarmActor.AddForceFieldVelocity(SwarmActor.GetActorCenterLocation() + (FVector::UpVector * -SwarmRad), RadialImpulseSettings);
//			}
//			else
//			{
//				FSwarmForceField RadialImpulseSettings;
//				RadialImpulseSettings.Radius = SwarmActor.SkelMeshComp.GetSwarmRadius();
//				RadialImpulseSettings.Strength = -500;
//				RadialImpulseSettings.bLinearFalloff = true;
//				SwarmActor.AddForceFieldVelocity(SwarmActor.GetActorCenterLocation(), RadialImpulseSettings);
//				return;
//			}
//		}

		// Print("VFX Spawn Count: " + InSkelMeshComp.ExtraVFXParticles.Num(), 3.f, FLinearColor::Yellow);
		// Print("Marked For Death: " + InSkelMeshComp.ParticleindicesMarkedForDeath.Num(), 3.f, FLinearColor::Yellow);

		NiagaraDeadWaspSpawner.SpawnDeadWasp_Init();

		// substep the killing to make it more dramatic and save performance
		InSkelMeshComp.TimeToProcessDeadParticles += Dt;
		while (InSkelMeshComp.TimeToProcessDeadParticles >= SubStepFixedDeltaTime)
		{
			// SpawnDeadParticles(InSkelMeshComp, Dt);
			// SpawnDeadParticlesCascade(InSkelMeshComp, Dt);
			KillRealSwarmParticle(InSkelMeshComp, Dt);
			SpawnExtraNiagaraParticles(InSkelMeshComp, Dt);
			InSkelMeshComp.TimeToProcessDeadParticles -= SubStepFixedDeltaTime;
		}

		NiagaraDeadWaspSpawner.SpawnDeadWasp_Finalize();

		// PrintToScreen("Spawn Niagara Particle Index Que: " + InSkelMeshComp.ExtraVFXParticles.Num());
		// PrintToScreen("Bone Particles marked for death: " + InSkelMeshComp.ParticleindicesMarkedForDeath.Num());
	}

	void KillRealSwarmParticle(USwarmSkeletalMeshComponent InSkelMeshComp, const float Dt) 
	{
		if (InSkelMeshComp.ParticleindicesMarkedForDeath.Num() <= 0)
			return;

		const int ParticleIdx = InSkelMeshComp.ParticleindicesMarkedForDeath[0];

#if TEST
		ensure(InSkelMeshComp.Particles[ParticleIdx].bAlive);
#endif TEST

		// Special stuff for saps!
		// If saps are attached to this particle, then disable them!
		// They are not guaranteed to all explode because the swarm death radius is bigger than
		//		the sap explode spread radius
		int SapIndex = InSkelMeshComp.Particles[ParticleIdx].AttachedSapId;
		if (SapIndex >= 0)
		{
			SapLog("SWARM " + InSkelMeshComp.Owner.GetName() + " | " + InSkelMeshComp.GetName() + " | " + " ParicleIdx \t [" + ParticleIdx + "\t] DISABLE SAP [" + SapIndex + "\t]");
			DisableSwarmSapByIndex(SapIndex);
		}

		SpawnNiagaraParticleByIndex(InSkelMeshComp, ParticleIdx, Dt);
		InSkelMeshComp.KillParticleByIndex(ParticleIdx);
		InSkelMeshComp.ParticleindicesMarkedForDeath.RemoveAt(0);
	}

	void SpawnExtraNiagaraParticles(USwarmSkeletalMeshComponent InSkelMeshComp, const float Dt)
	{
		if (InSkelMeshComp.ExtraVFXParticles.Num() <= 0)
			return;

		const int ParticleIdx = InSkelMeshComp.ExtraVFXParticles[0];
		SpawnNiagaraParticleByIndex(InSkelMeshComp, ParticleIdx, Dt);

		InSkelMeshComp.ExtraVFXParticles.RemoveAt(0);
	}

	void SpawnNiagaraParticleByIndex(USwarmSkeletalMeshComponent InSkelMeshComp, int InParticleIndex, const float Dt)
	{
		if (ParticlesSpawnedThisFrame.Contains(InParticleIndex))
		{
			// PrintToScreen("Index has already been spawned: " + InParticleIndex, Duration = 1.f);
			return;
		}

		const FSwarmParticle& SwarmParticle = InSkelMeshComp.Particles[InParticleIndex];

		if (!SwarmParticle.bAlive || SwarmParticle.CurrentTransform.ContainsNaN())
		{
			// PrintToScreen("Index is dead: " + InParticleIndex, Duration = 1.f);
			return;
		}

		const FVector Position = InSkelMeshComp.Particles[InParticleIndex].CurrentTransform.GetLocation();

		FVector LinImpulse = FVector::ZeroVector;
		FVector AngImpulse = FVector::ZeroVector;
		CalculateDeathImpulseForParticle(
			InSkelMeshComp,
			Dt,
			InParticleIndex,
			LinImpulse,
			AngImpulse
		);

		NiagaraDeadWaspSpawner.SpawnDeadWasp_Intermediate(
			Position,
			SwarmParticle.CurrentTransform.GetRotation(),
			LinImpulse,
			AngImpulse
		);

		SwarmAudioHandler.Register(Position, LinImpulse);

		ParticlesSpawnedThisFrame.Add(InParticleIndex);
	}

	void CalculateDeathImpulseForParticle(
		const USwarmSkeletalMeshComponent InSkelMeshComp,
		const float Dt,
		const int InParticleIndex,
		FVector& OutImpulseLinear,
		FVector& OutImpulseAngular
	) const
	{
		const FSwarmParticle& SwarmParticle = InSkelMeshComp.Particles[InParticleIndex];

		// The impulses will be baked into the Velocity:
		// The skelMesh will apply impulses which the proxy 
		// will consume and apply to its velocity
		OutImpulseLinear = SwarmParticle.Velocity;

		// Account for forces that haven't necessarily been consumed yet,
		// due to potentially different ActorChannels and tick groups
		if (!SwarmParticle.AccumulatedAccelerations.IsZero())
			OutImpulseLinear += (SwarmParticle.AccumulatedAccelerations * Dt);

		if (!SwarmParticle.AccumulatedVelocities.IsZero())
			OutImpulseLinear += SwarmParticle.AccumulatedVelocities;

		FVector ParticleRelativeToCenter = SwarmParticle.CurrentTransform.GetLocation() - InSkelMeshComp.CenterOfParticles; 
		ParticleRelativeToCenter.Normalize();

		FVector Position = SwarmParticle.CurrentTransform.GetLocation();

		const FVector MayViewPoint = Game::GetMay().ViewLocation;
		const FVector AwayFromMay = Position - MayViewPoint;
		const FVector AwayFromMayNormalized = AwayFromMay.GetSafeNormal();

		FSwarmAnimationSettings AnimSettings;
		InSkelMeshComp.GetSwarmAnimationSettings(AnimSettings);

//			if(Time::GetGameTimeSince(DEBUG_TimeStamp) > 1.f)
//			{
//				// Outer
//				System::DrawDebugConeInDegrees(
//					Position,
//					AwayFromMayNormalized,
//					AwayFromMay.Size(),
//					FMath::RadiansToDegrees(AnimSettings.HalfConeAngleRad_Outer),
//					FMath::RadiansToDegrees(AnimSettings.HalfConeAngleRad_Outer),
//					16,
//					FLinearColor::Yellow,
//					3.f,
//					3.f
//				);
//				// Inner
//				System::DrawDebugConeInDegrees(
//					Position,
//					AwayFromMayNormalized,
//					AwayFromMay.Size(),
//					FMath::RadiansToDegrees(AnimSettings.HalfConeAngleRad_Inner),
//					FMath::RadiansToDegrees(AnimSettings.HalfConeAngleRad_Inner),
//					16,
//					FLinearColor::Blue,
//					3.f,
//					3.f
//				);
//			}
//			DEBUG_TimeStamp = Time::GetGameTimeSeconds();

		// normalize() + size()
		const float ImpulseMagnitude = OutImpulseLinear.Size();
		if(ImpulseMagnitude > SMALL_NUMBER)
		{
			OutImpulseLinear /= ImpulseMagnitude;
		}
		else 
		{
			// generate a random direction if the vector is to small
			OutImpulseLinear = Math::GetRandomHalfConeDirection(
				AwayFromMayNormalized,
				FVector::UpVector,
				AnimSettings.HalfConeAngleRad_Outer,
				AnimSettings.HalfConeAngleRad_Inner
			);
		}

		bool bPointingDownwards = OutImpulseLinear.DotProduct(FVector::UpVector) < AnimSettings.ExplodingDownwardsThreshold;
		if(AnimSettings.ExplodingDownwardsThreshold != 0.f 
		&& AnimSettings.bOnlyApplyExplosionForcesUpwards 
		&& bPointingDownwards)
		{
			// we brute force generate a valid direction by iteration, because the reflection
			// solution only works when the threshold is in the middle, symmetrical with the cone.
			int iterCount = 0;
			while(bPointingDownwards && iterCount < 50)
			{
				OutImpulseLinear = Math::GetRandomConeDirection(
					AwayFromMayNormalized,
					AnimSettings.HalfConeAngleRad_Outer,
					AnimSettings.HalfConeAngleRad_Inner
				);

				++iterCount;

				bPointingDownwards = OutImpulseLinear.DotProduct(FVector::UpVector) < AnimSettings.ExplodingDownwardsThreshold;
			}
		}
		else
		{
			// we want to keep the pure velocity direction if possible, which is why 
			// we do all the checks rather then just generate a direction immediately
			const float DOTBetweenAwayFromMayAndImpulse = OutImpulseLinear.DotProduct(AwayFromMayNormalized);
			const bool bPointingTowardsMay = DOTBetweenAwayFromMayAndImpulse < 0.f;
			if(bPointingTowardsMay
			|| FMath::Acos(DOTBetweenAwayFromMayAndImpulse) > AnimSettings.HalfConeAngleRad_Outer 
			|| FMath::Acos(DOTBetweenAwayFromMayAndImpulse) < AnimSettings.HalfConeAngleRad_Inner
			)
			{
				OutImpulseLinear = Math::GetRandomConeDirection(
					AwayFromMayNormalized,
					AnimSettings.HalfConeAngleRad_Outer,
					AnimSettings.HalfConeAngleRad_Inner
				);
			}

			// reflect it if it is pointing downwards
			if (AnimSettings.bOnlyApplyExplosionForcesUpwards)
			{
				const float ReflectionDot = OutImpulseLinear.DotProduct(FVector::UpVector);
				if (ReflectionDot < 0.f)
				{
					OutImpulseLinear -= (FVector::UpVector * 2.f * ReflectionDot);
				}
			}

		}

#if TEST
		ensure(OutImpulseLinear.IsNormalized());
#endif 

		OutImpulseAngular = OutImpulseLinear.CrossProduct(ParticleRelativeToCenter);
		OutImpulseAngular *= PI;
		
		const float DesiredSpeed = FMath::Lerp(
			AnimSettings.MaxDeathExplodeSpeed,
			ImpulseMagnitude,
			AnimSettings.InheritParticleSpeedAlpha
		);

//		Print("DesiredSpeed: " + DesiredSpeed);
		OutImpulseLinear *= DesiredSpeed;
	}

	ADeadWaspSpawnerActor GetOrCreateDeadWaspSpawner()
	{
		if (SwarmActor.DeadWaspSpawnerClass.IsValid() == false)
		{
			ensure(false);
			return nullptr;
		}

		AActor Manager = Game::GetManagerActor(SwarmActor.DeadWaspSpawnerClass, true);
		if (Manager == nullptr)
		{
			Manager = SpawnActor(SwarmActor.DeadWaspSpawnerClass, Level = SwarmActor.Level);
		}

		return Cast<ADeadWaspSpawnerActor>(Manager);
	}

//	void SpawnDeadParticlesCascade(USwarmSkeletalMeshComponent InSkelMeshComp, float Dt)
//	{
//		if (InSkelMeshComp.ExtraVFXParticles.Num() <= 0)
//			return;
//
//		const int ParticleIdx = InSkelMeshComp.ExtraVFXParticles[0];
//		const FSwarmParticle& SwarmParticle = InSkelMeshComp.Particles[ParticleIdx];
//		if (SwarmParticle.CurrentTransform.ContainsNaN() == false)
//		{
//			// velocity
//			FVector FinalParticleVelocity = SwarmParticle.Velocity;
//			FinalParticleVelocity += SwarmParticle.AccumulatedVelocities;
//			FinalParticleVelocity += (SwarmParticle.AccumulatedAccelerations * Dt);
//			FVector LinearImpulse = FinalParticleVelocity;
//			LinearImpulse *= 2.f;
//
//			CascadeDeadWaspSpawnerComponent.GenerateParticleEvent(
//				n"SpawnWasp",
//				0.0f,
//				SwarmParticle.CurrentTransform.GetLocation(),
//				FVector::ZeroVector,
//				LinearImpulse
//			);
//
//		}
//		InSkelMeshComp.ExtraVFXParticles.RemoveAt(0);
//	}
//
//	void SpawnDeadParticleActor(USwarmSkeletalMeshComponent InSkelMeshComp, const float Dt)
//	{
//		if (InSkelMeshComp.ExtraVFXParticles.Num() <= 0)
//			return;
//
//		const int ParticleIdx = InSkelMeshComp.ExtraVFXParticles[0];
//		const FSwarmParticle& SwarmParticle = InSkelMeshComp.Particles[ParticleIdx];
//
//		// TEMP. Transform might go NaN which invalidates
//		// the spawning, which in turn spews out error messages.  
//		// TODO: remove this check once we start pooling the dead wasps instead
//		if (SwarmParticle.CurrentTransform.ContainsNaN() == false)
//		{
//			AActor DeadWasp = SpawnActor(
//				SwarmActor.DeadWaspClass.Get(),
//				SwarmParticle.CurrentTransform.GetLocation(),
//				SwarmParticle.CurrentTransform.GetRotation().Rotator()
//			);
//
////				FTransform TM = SwarmParticle.CurrentTransform;
////				System::DrawDebugCoordinateSystem(TM.GetLocation(), TM.GetRotation().Rotator(), 1000, 5.f, 5.f);
//
//			UStaticMeshComponent DeadWaspRootMesh = UStaticMeshComponent::Get(DeadWasp);
//			DeadWaspRootMesh.SetSimulatePhysics(true);
//
//			// The accumulation is handled on the animation proxy. 
//			// But we can't guarantee that it will happen in the correct
//			// order atm. TODO: add a TickGroup that is sure to trigger
//			// after animation proxy has done it's thing instead 
//			FVector FinalParticleVelocity = SwarmParticle.Velocity;
//			FinalParticleVelocity += SwarmParticle.AccumulatedVelocities;
//			FinalParticleVelocity += (SwarmParticle.AccumulatedAccelerations * Dt);
//
//			// Linear Impulse
//			FVector LinearImpulse = FinalParticleVelocity;
//			LinearImpulse *= 2.f;
//
//			// Angular Impulse
//			FVector AngularImpulse = FinalParticleVelocity;
//			AngularImpulse = AngularImpulse.CrossProduct(FVector(0.f, 0.f, 1.f));
////				AngularImpulse.Normalize();
////				AngularImpulse *= 1000.f;
//
//			DeadWaspRootMesh.AddImpulse(LinearImpulse, NAME_None, bVelChange = true);
//			DeadWaspRootMesh.AddAngularImpulseInDegrees(AngularImpulse, NAME_None, bVelChange = true);
//		}
//
//		InSkelMeshComp.ExtraVFXParticles.RemoveAt(0);
//	}

}

