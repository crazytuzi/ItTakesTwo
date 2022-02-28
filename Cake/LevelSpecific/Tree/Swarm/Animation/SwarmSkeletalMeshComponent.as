
import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmAnimationSettingsDataAsset;

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset StartingAnimations HazeSettings Activation")
class USwarmSkeletalMeshComponent : UHazeSwarmSkeletalMeshComponent
{
	default bHiddenInGame = false;
	default bOwnerNoSee = false;

//	default CastShadow = false;
//	default bCastDynamicShadow = false;
//	default bAffectDynamicIndirectLighting = false;
	default ShadowPriority = EShadowPriority::Background;

	default bCanEverAffectNavigation = false;
	default VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	default SetAnimationMode(EAnimationMode::AnimationSingleNode);
	default SetApplyRootMotionToOwnerRoot(true);
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
	default BodyInstance.bNotifyRigidBodyCollision = false;
	default SetGenerateOverlapEvents(false);

	default bReceivesDecals = false;

	//////////////////////////////////////////////////////////////////////////
	// !!! Anim Thread stuff () 
	default bHazeAllowThreadedUpdateAndEvaluation = true;
	//////////////////////////////////////////////////////////////////////////

	bool bInvulnerable = false;

	UPROPERTY(Category = "Animation")
	USwarmAnimationSettingsDataAsset DefaultSwarmAnimSettingsDataAsset;

	// == BlendTime. But it will be used to telegraph certain attacks.
	UPROPERTY(Category = "Animation")
	float DefaultSwarmInertiaBlendTime = 0.2f;

	//////////////////////////////////////////////////////////////////////////
	// Transients

	float TimeToProcessDeadParticles = 0.f;

	// This will tell niagara to stop drawing the particles
	UPROPERTY(NotEditable)
	TArray<int32> ParticleindicesMarkedForDeath;

	// this will spawn a temp actor with some effects. 
	UPROPERTY(NotEditable)
	TArray<int32> ExtraVFXParticles;

//	UPROPERTY(NotEditable, Transient)
	private TArray<FStackableSwarmAnimationSettingsDataAssets> SwarmAnimSettings;

	// Transients
	//////////////////////////////////////////////////////////////////////////

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayDefaultSwarmAnim();
		ParticleindicesMarkedForDeath.Reserve(120);
		ExtraVFXParticles.Reserve(480);
	}

	void PlayDefaultSwarmAnim()
	{
		PlaySwarmAnimation_Internal(DefaultSwarmAnimSettingsDataAsset, this, DefaultSwarmInertiaBlendTime);
	}

	#if EDITOR
	void UpdateSwarmAnimationPreview()
	{
		if (DefaultSwarmAnimSettingsDataAsset == nullptr)
			return;

		const auto PrevAnimMode = GetAnimationMode();

		// Calling this function will ensure that changes to 
		// AnimToPlay will be applied the same frame
		SetAnimationMode(EAnimationMode::AnimationBlueprint);

		EditorOnlyOverrideAnimationData(
			DefaultSwarmAnimSettingsDataAsset.Settings.OptionalSwarmAnimation.Sequence,
			DefaultSwarmAnimSettingsDataAsset.Settings.OptionalSwarmAnimation.bLoop,
			AnimationData.bSavedPlaying,
			AnimationData.SavedPosition,
			AnimationData.SavedPlayRate
		 );

		SetAnimationMode(PrevAnimMode);
	}
	#endif

	UFUNCTION()
	void ProcessPendingAnimModifers_Cutscenes()
	{
		if (PendingAnimModifierSettings.Num() == 0)
			return;

		// Process pending queue. Discard the ones that don't
		// match with the currently playing animation.
		for (int i = PendingAnimModifierSettings.Num() - 1; i >= 0; --i)
		{
			ActiveAnimModifierSettings.Add(PendingAnimModifierSettings[i]);
			PendingAnimModifierSettings.RemoveAt(i);
		}

	}

	void ProcessPendingAnimModifers()
	{
		if (PendingAnimModifierSettings.Num() == 0)
			return;

		UAnimSequenceBase CurrentAnim = GetCurrentlyPlayingAnimation();

		// Nuke the queue if we've switched to procedural anim.
		if (CurrentAnim == nullptr)
		{
			PendingAnimModifierSettings.Empty();
			return;
		}

		// Process pending queue. Discard the ones that don't
		// match with the currently playing animation.
		for (int i = PendingAnimModifierSettings.Num() - 1; i >= 0; --i)
		{
			if (PendingAnimModifierSettings[i].RefAnimation == CurrentAnim)
			{
				ActiveAnimModifierSettings.Add(PendingAnimModifierSettings[i]);
			}
			PendingAnimModifierSettings.RemoveAt(i);
		}

	}

	void PlaySwarmAnimation_Internal(
		USwarmAnimationSettingsDataAsset InAnimSettingsData,
		UObject Instigator,
		float InInertiaBlendTime = 0.2f
	)
	{
		ensure(Instigator != nullptr);
		// ensure(InAnimSettingsData != nullptr);

		SwarmAnimSettings.Add(
			FStackableSwarmAnimationSettingsDataAssets(
				InAnimSettingsData,
				Instigator,
				InInertiaBlendTime
			)
		);

		if(!IsPlayingProceduralAnimation())
		{
			/* 	might be null due to being called from construction script.
				we don't do the null check prior to calling this func because of 
				everything else inside this func. We added it to the construction 
				script in order to able to preview the animation in sequencer. 
				we added the code in a haste. It should be redone if you have time. */
			if(GetAnimInstance() != nullptr)
			{
				GetAnimInstance().RequestInertialization(InInertiaBlendTime);
			}
		}

		// @TODO: test without these when u has time 
		PendingAnimModifierSettings.Reset();
		ActiveAnimModifierSettings.Reset();
//		UnstunAllParticles();
	}

	void StopSwarmAnimation_Internal(UObject Instigator)
	{
		for (int i = SwarmAnimSettings.Num() - 1; i >= 0; --i)
		{
			if (SwarmAnimSettings[i].Instigator == Instigator)
			{
				SwarmAnimSettings.RemoveAt(i);
			}
		}
	}

	// IsUnharmed
	bool IsComplete() const
	{
		return GetNumParticlesAlive() == GetNumSwarmBones();
	}

	UFUNCTION(BlueprintPure)
	USwarmAnimationSettingsDataAsset GetSwarmAnimSettingsDataAsset() const property
	{
		if (SwarmAnimSettings.Num() != 0)
			return SwarmAnimSettings.Last().AnimSettingsDataAsset;
		return nullptr;
	}

	UFUNCTION(BlueprintOverride, Category = "Swarm")
	bool GetSwarmAnimationSettings(FSwarmAnimationSettings& SettingsToOverwrite) const
	{
		const USwarmAnimationSettingsDataAsset AnimSettingsDataAsset = GetSwarmAnimSettingsDataAsset();
		if (AnimSettingsDataAsset != nullptr)
		{
			SettingsToOverwrite = AnimSettingsDataAsset.Settings;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	float GetSwarmInertiaBlendTime() const  property
	{
		if (SwarmAnimSettings.Num() != 0)
			return SwarmAnimSettings.Last().InertiaBlendTime;
		return 0.f;
	}

	UFUNCTION(BlueprintPure, Category = "Swarm")
	FHazePlaySequenceData GetAnimSequenceDataFromSwarmAnimSettings() const property
	{
		const USwarmAnimationSettingsDataAsset AnimSettingsDataAsset = GetSwarmAnimSettingsDataAsset();
		if (AnimSettingsDataAsset != nullptr)
			return AnimSettingsDataAsset.Settings.OptionalSwarmAnimation;
		return FHazePlaySequenceData();
	}

	UFUNCTION(BlueprintPure, Category = "Swarm")
	FHazePlayBlendSpaceData GetBlendSpaceDataFromSwarmAnimSettings() const property
	{
		const USwarmAnimationSettingsDataAsset AnimSettingsDataAsset = GetSwarmAnimSettingsDataAsset();
		if (AnimSettingsDataAsset != nullptr)
			return AnimSettingsDataAsset.Settings.OptionalSwarmBlendSpace;
		return FHazePlayBlendSpaceData();
	}

	UFUNCTION(BlueprintOverride, Category = "Swarm")
	UAnimSequenceBase GetCurrentlyPlayingAnimation() const property
	{
		const USwarmAnimationSettingsDataAsset AnimDataAsset = GetSwarmAnimSettingsDataAsset();
		if (AnimDataAsset == nullptr)
			return nullptr;
		// We'll switch to procedural animation if we don't have enough particles
//		else if(GetNumParticlesAlive() < AnimDataAsset.Settings.KillAllParticlesThreshold)
		else if(bAboutToDie)
			return nullptr;
		else 
			return AnimDataAsset.Settings.OptionalSwarmAnimation.Sequence;
	}

	UFUNCTION(BlueprintPure, Category = "Swarm")
	UBlendSpaceBase GetCurrentlyPlayingBlendSpaceAnimation() const property
	{
		const USwarmAnimationSettingsDataAsset AnimDataAsset = GetSwarmAnimSettingsDataAsset();
		if (AnimDataAsset == nullptr)
			return nullptr;
		else if(bAboutToDie)
			return nullptr;
		else 
			return AnimDataAsset.Settings.OptionalSwarmBlendSpace.BlendSpace;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayingProceduralAnimation() const 
	{
		const USwarmAnimationSettingsDataAsset AnimDataAsset = GetSwarmAnimSettingsDataAsset();
		if (AnimDataAsset == nullptr)
			return true;
		else if (AnimDataAsset.Settings.OptionalSwarmAnimation.Sequence == nullptr && AnimDataAsset.Settings.OptionalSwarmBlendSpace.BlendSpace == nullptr)
			return true;
		else if(bAboutToDie)
			return true;
		else
			return false;
	}

	bool FindPlayersIntersectingMeshBounds(TArray<AHazePlayerCharacter>& OutOverlappedPlayers) const
	{
		AHazePlayerCharacter May = nullptr;
		AHazePlayerCharacter Cody = nullptr;
		Game::GetMayCody(May, Cody);

		if (Math::AreComponentBoundsIntersecting(this, May.CapsuleComponent))
			OutOverlappedPlayers.AddUnique(May);

		if (Math::AreComponentBoundsIntersecting(this, Cody.CapsuleComponent))
			OutOverlappedPlayers.AddUnique(Cody);

		return OutOverlappedPlayers.Num() > 0;
	}

	bool FindPlayersIntersectingMeshBones(TArray<AHazePlayerCharacter>& OutOverlappedPlayers) const
	{
		// check if player and swarm bounds are intersecting first.
		TArray<AHazePlayerCharacter> IntersectingPlayers;
		if (FindPlayersIntersectingMeshBounds(IntersectingPlayers) == false)
			return false;

		// then we check against all swarm bones. 
		const float PlayerRadius = 90.f;
		const float SumRadiusSQ = FMath::Square(PlayerRadius + ParticleRadius);

		for (int i = IntersectingPlayers.Num() - 1; i >= 0; --i)
		{
			const FVector PlayerLoc = IntersectingPlayers[i].GetActorCenterLocation();

			const UCapsuleComponent PlayerCapsuleComp = IntersectingPlayers[i].CapsuleComponent;
			FHazeIntersectionCapsule PlayerCapsule;
			PlayerCapsule.MakeUsingOrigin(
				PlayerCapsuleComp.WorldLocation,
				PlayerCapsuleComp.WorldRotation,
				PlayerCapsuleComp.CapsuleHalfHeight,
				PlayerCapsuleComp.CapsuleRadius
			);

//			System::DrawDebugSphere(PlayerLoc, PlayerRadius);

			for (int j = 0; j < Particles.Num(); ++j)
			{
				if (Particles[j].bAlive == false)
					continue;

				if (Particles[j].bStunned == true)
					continue;

				const FVector ParticleLoc = Particles[j].CurrentTransform.GetLocation();
				const float DistToPlayer_SQ = (ParticleLoc - PlayerLoc).SizeSquared();

				// check if spheres are intersecting
				if (DistToPlayer_SQ < SumRadiusSQ)
				{

					/*
						 Do an extra Capsule vs. Capsule trace just to be sure.

						 This was desired in the swarm slide scenario because the
						 gameplay involves close-up mini-wasp vs player collisions. 
						 It felt unfair when being hit by the mini-wasp (represented here with a sphere) 
						 when that wasn't reflected visually.
					*/

					FHazeIntersectionCapsule ParticleCapsule;
					ParticleCapsule.MakeUsingOrigin(
						ParticleLoc - FVector::UpVector * 20.f,
						Particles[j].CurrentTransform.GetRotation().Rotator(),
						60.f, 
						30.f
					);

					FHazeIntersectionResult IntersectionResult;
					IntersectionResult.QueryCapsuleCapsule(PlayerCapsule, ParticleCapsule);
					if(IntersectionResult.bIntersecting)
					{
//						System::DrawDebugCapsule(
//							ParticleCapsule.Origin,
//							ParticleCapsule.HalfHeight,
//							ParticleCapsule.Radius,
//							ParticleCapsule.Rotation,
//							FLinearColor::Red
//						);
//
//						System::DrawDebugCapsule(
//							PlayerCapsule.Origin,
//							PlayerCapsule.HalfHeight,
//							PlayerCapsule.Radius,
//							PlayerCapsule.Rotation,
//							FLinearColor::Blue
//						);

//						System::DrawDebugSphere(ParticleLoc, ParticleRadius);

						OutOverlappedPlayers.AddUnique(IntersectingPlayers[i]);
						break;
					}

				}
			}
		}

		return OutOverlappedPlayers.Num() > 0;
	}

	FVector GetAlignBoneLocalLocation() const
	{
		return GetSocketTransform(
			n"Align",
			ERelativeTransformSpace::RTS_Component
		).GetLocation();
	}

	UFUNCTION(BlueprintOverride)
	void ModifyOnAngelScript_Vector(FVector& InVector)
	{
	}

	UFUNCTION(BlueprintOverride)
	void ModifyOnAngelScript_Quat(FQuat& InQuat)
	{
	}

	UFUNCTION(BlueprintOverride)
	FQuat ModifyOnAngelScript_VectorToQuat(FSwarmParticle& InParticle, FVector& InVector)
	{
		return FQuat::Identity;
	}

	UFUNCTION(BlueprintPure)
	bool HasEnoughParticlesForAnimation() const
	{
		// if (GetSwarmAnimSettingsDataAsset() != nullptr)
		// {
		// 	const int32 NumParticlesNeeded = GetSwarmAnimSettingsDataAsset().Settings.KillAllParticlesThreshold;
		// 	return GetNumParticlesAlive() >= NumParticlesNeeded;
		// }
		// return false;

		return !bAboutToDie;
	}

	int GetKillAllParticlesThreshold() const
	{
		if (GetSwarmAnimSettingsDataAsset() != nullptr)
		{
			const FSwarmAnimationSettings& Settings = GetSwarmAnimSettingsDataAsset().Settings;
			return Settings.KillAllParticlesThreshold;
		}
		return GetNumSwarmBones();
	}

	bool FindParticleIndexClosestToLocation(FVector InWorldLocation, int& OutParticleIndex, float& OutDistanceSQ)
	{
		int ClosestIndex = -1;
		float ClosestDistToParticleSQ = BIG_NUMBER;

		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bAlive == false)
				continue;

			const FVector ParticleLoc = Particles[i].CurrentTransform.GetLocation();
			const float DistSQ = ParticleLoc.DistSquared(InWorldLocation);

			if (DistSQ < ClosestDistToParticleSQ)
			{
				ClosestIndex = i;
				ClosestDistToParticleSQ = DistSQ;
			}
		}

		// All particles are dead
		if (ClosestIndex == -1)
			return false;

		OutParticleIndex = ClosestIndex;
		OutDistanceSQ = ClosestDistToParticleSQ;

		return true;
	}

	bool AreParticlesIntersectingSphere(FVector InSphereLocation, float InSphereRadius) const
	{
		const float DistanceThresholdSQ = FMath::Square(ParticleRadius + InSphereRadius);
		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bAlive == false)
				continue;

			const float DistanceBetweenSQ = Particles[i].CurrentTransform.GetLocation().DistSquared(InSphereLocation);
			if(DistanceBetweenSQ > DistanceThresholdSQ)
				continue;

			// if(Math::AreSpheresNotIntersecting(
			// 	Particles[i].CurrentTransform.GetLocation(),
			// 	ParticleRadius,
			// 	InSphereLocation,
			// 	InSphereRadius))
			// {
			// }
			
			return true;
		}

		return false;
	}

	bool FindParticleClosestToRay(FVector RayStart, FVector RayEnd, FName& OutParticleName, FVector& OutRayLocation, float& OutDistanceSQ)
	{
		float ClosestDistSqrd = 0.f;
		FVector ClosestRayLocation;
		int ClosestIndex = -1;
		FVector RayDelta = RayEnd - RayStart;
		float RayLength = RayDelta.Size();
		FVector Direction = RayDelta / RayLength;

		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bAlive == false)
				continue;

			const FVector ParticleLoc = Particles[i].CurrentTransform.GetLocation();
			const FVector Delta = ParticleLoc - RayStart;
			float RayDistance = Delta.DotProduct(Direction);
			RayDistance = FMath::Clamp(RayDistance, 0.f, RayLength);

			const FVector ClosestRayPoint = RayStart + Direction * RayDistance;
			const FVector ClosestDelta = ParticleLoc - ClosestRayPoint;

			const float DistSqrd = ClosestDelta.SizeSquared();

			if (DistSqrd < ClosestDistSqrd || ClosestIndex == -1)
			{
				ClosestIndex = i;
				ClosestDistSqrd = DistSqrd;
				ClosestRayLocation = ClosestRayPoint;
			}
		}

		// All particles are dead
		if (ClosestIndex == -1)
			return false;

		OutParticleName = GetParticleBoneName(ClosestIndex);
		OutDistanceSQ = ClosestDistSqrd;
		OutRayLocation = ClosestRayLocation;

		return true;
	}

	void CopyOtherSwarmMesh(UHazeSwarmSkeletalMeshComponent OtherSwarmMesh)
	{
		Particles = OtherSwarmMesh.Particles;
		for(auto Particle : Particles)
			Particle.AttachedSapId = -1;

		CenterOfParticles = OtherSwarmMesh.CenterOfParticles;
		CenterOfParticlesVelocity = OtherSwarmMesh.CenterOfParticlesVelocity;
		CenterOfParticlesAngularVelocity = OtherSwarmMesh.CenterOfParticlesAngularVelocity;
		bOtherSwarmParticlesCopied = true;
		HazeForceUpdateAnimation(true);
	}

	bool GatherAndApplyImpulseDataForMatch(
		const FVector& InMatchLocation,
		const FVector& InMatchVelocityNormalized,
		const FVector& InCameraForward,
		const float InMatchCollisionRadius
	)
	{
		bool bValidHit = false;

		const auto& Settings = GetSwarmAnimSettingsDataAsset().Settings;

		// Settings: keep these constant until we need unique settings per animation
		const float StunDuration = 1.f;
		const float ExtraStunImpulseMultiplier = 3.f;
		float ImpulseMagnitude = 300.f; // !! not zero 

		const float CollisionDistThreshold = InMatchCollisionRadius + ParticleRadius;
		const float CollisionDistThresholdSQ = FMath::Square(CollisionDistThreshold);

		// Loop through all particles, and check if are overlapping the match
		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bAlive == false)
				continue;

			FSwarmParticle& Particle = Particles[i];

			const FVector ParticlePos = Particle.CurrentTransform.GetLocation();
			const FVector MatchToParticle = ParticlePos - InMatchLocation;
			const float MatchToParticleDistSQ = MatchToParticle.SizeSquared();

			// ignore particles outside of the threshold
			if (MatchToParticleDistSQ > CollisionDistThresholdSQ)
				continue;

			FVector ImpulseDirection = FVector::ZeroVector;
			if (MatchToParticleDistSQ <= SMALL_NUMBER)
			{
				ImpulseDirection = FMath::VRand();
			}
			else
			{
				const float MatchToParticleDist = FMath::Sqrt(MatchToParticleDistSQ);

				// reduce the magnitude based on distance
//				float DistanceMultiplier = (1.0f - (MatchToParticleDist / CollisionDistThreshold)); 
//				DistanceMultiplier = FMath::Pow(DistanceMultiplier, 0.5f);
//				ImpulseMagnitude *= DistanceMultiplier;

				const FVector MatchToParticleNormalized = MatchToParticle / MatchToParticleDist;

				// The delta direction is most important, thus we double it.
				ImpulseDirection = MatchToParticleNormalized * 2.f;
			}

			// Take the match velocity into account
			ImpulseDirection += InMatchVelocityNormalized;

			// increase the probability that the particles will explode outwards from the camera
			ImpulseDirection += InCameraForward;

			// constrain the impulse to an invisible wall 
			// (if it happens to be exploding towards the camera)
			if(ImpulseDirection.DotProduct(InCameraForward) < 0.f)
				ImpulseDirection = ImpulseDirection.VectorPlaneProject(InCameraForward);

			ImpulseDirection.Normalize();

			FVector Impulse = ImpulseDirection * ImpulseMagnitude;

			// Make the stun impulse stronger because air drag will be fighting against it.
			Impulse *= ExtraStunImpulseMultiplier;

			if (Impulse.IsZero())
				continue;

//			const FVector MayViewPoint = Game::GetMay().ViewLocation;
//			const FVector AwayFromMay = Particle.CurrentTransform.GetLocation() - MayViewPoint;
//			const FVector AwayFromMayNormalized = AwayFromMay.GetSafeNormal();
//			const FVector RandomConeDir = Math::GetRandomHalfConeDirection(
//				AwayFromMayNormalized,
//				FVector::UpVector,
//				PI * 0.5f,
//				0.f
//			);
//			const float ImpulseMagInConeDir = Impulse.DotProduct(RandomConeDir);
//			Impulse = RandomConeDir * FMath::Abs(ImpulseMagInConeDir);

			if(Settings.bOnlyApplyExplosionForcesUpwards)
			{
				// reflect it if it is pointing downwards
				const float ReflectionDot = Impulse.DotProduct(FVector::UpVector);
				if (ReflectionDot < 0.f)
				{
					Impulse -= (FVector::UpVector * 2.f * ReflectionDot);
				}
			}

			AddVelocityToParticle(Particle, Impulse);

			if (Settings.bEnableStun && !Particle.bStunned)
			{
				Particle.bStunned = true;
				Particle.StunAlpha = Settings.StunSettings.bInverseAnimFraction ? 0.f : 0.999f;
			}

			bValidHit = true;

		} // end particle loop

		return bValidHit;
	}

	bool GatherAndApplyImpulseDataForSap(
		const FVector& InSapLocation,
		const float InSapMassFraction
	)
	{
		const FSwarmAnimationSettings& Settings = GetSwarmAnimSettingsDataAsset().Settings;

		const float ThresholdDeathRadius = FMath::Lerp(
			Settings.DeathRadiusRangeMin,
			Settings.DeathRadiusRangeMax,
			InSapMassFraction
		);
		const float ThresholdImpulseRadius = ThresholdDeathRadius * Settings.ExplosionRadiusMultiplier;
		const float ThresholdImpulseRadiusSQ = FMath::Square(ThresholdImpulseRadius);

		// System::DrawDebugSphere(InSapLocation, ThresholdImpulseRadius, 12, FLinearColor::Green, 3.f);

		bool bHitParticle = false;

		for (int i = 0; i < Particles.Num(); ++i)
		{
			if (Particles[i].bAlive == false)
				continue;

			FSwarmParticle& Particle = Particles[i];

			const FVector SapToParticle = Particle.CurrentTransform.GetLocation() - InSapLocation;
			const float SapToParticleDistanceSQ = SapToParticle.SizeSquared();

			// Handle Impulse radius
			const bool bWithinImpulseRadius = SapToParticleDistanceSQ < ThresholdImpulseRadiusSQ; 
			if (!bWithinImpulseRadius)
				continue;

			FVector Impulse = FVector::ZeroVector;
			float ImpulseMagnitude = Settings.ExplosionMagnitude;
			if (SapToParticleDistanceSQ < SMALL_NUMBER)
			{
				// Random impulse direction if the sap is exactly on the bone
				Impulse = FMath::VRand();
			}
			else if(SapToParticleDistanceSQ < ThresholdImpulseRadiusSQ)
			{
				const float SapToParticleDistance = FMath::Sqrt(SapToParticleDistanceSQ);
				const FVector SapToParticleNormalized = SapToParticle / SapToParticleDistance;

				// Scale blast by distance
				if (ThresholdImpulseRadius != 0.f)
					ImpulseMagnitude *= (1.0f - (SapToParticleDistance / ThresholdImpulseRadius));
				else
					ImpulseMagnitude *= 0.f;

				Impulse = SapToParticleNormalized;
			}
			else if(bAboutToDie)
			{
				// give Niagara something to work with at least.
				// (It looked weird when they just fell due to gravity)
				const float SapToParticleDistance = FMath::Sqrt(SapToParticleDistanceSQ);
				const FVector SapToParticleNormalized = SapToParticle / SapToParticleDistance;
				Impulse = SapToParticleNormalized;
			}
			
			if(ImpulseMagnitude <= 0.f)
				continue;

			// constrain the impulse to explode away from May
			// (we need it to behave the same way as the death impulse)
			const FVector MayViewPoint = Game::GetMay().ViewLocation;
			const FVector AwayFromMay = Particle.CurrentTransform.GetLocation() - MayViewPoint;
			const FVector AwayFromMayNormalized = AwayFromMay.GetSafeNormal();
			const float DOTBetweenAwayFromMayAndImpulse = Impulse.DotProduct(AwayFromMayNormalized);
			const bool bPointingTowardsMay = DOTBetweenAwayFromMayAndImpulse < 0.f;
			if(bPointingTowardsMay
			|| FMath::Acos(DOTBetweenAwayFromMayAndImpulse) > Settings.HalfConeAngleRad_Outer 
			|| FMath::Acos(DOTBetweenAwayFromMayAndImpulse) < Settings.HalfConeAngleRad_Inner
			)
			{
				Impulse = Math::GetRandomConeDirection(
					AwayFromMayNormalized,
					Settings.HalfConeAngleRad_Outer,
					Settings.HalfConeAngleRad_Inner
				);
			}

			if(Settings.bOnlyApplyExplosionForcesUpwards)
			{
				// reflect it if it is pointing downwards
				const float ReflectionDot = Impulse.DotProduct(FVector::UpVector);
				if (ReflectionDot < 0.f)
				{
					Impulse -= (FVector::UpVector * 2.f * ReflectionDot);
				}
			}

			Impulse *= ImpulseMagnitude;

			AddVelocityToParticle(Particle, Impulse);

			bHitParticle = true;

			if (Settings.bEnableStun && !Particle.bStunned)
			{
				Particle.bStunned = true;
				Particle.StunAlpha = Settings.StunSettings.bInverseAnimFraction ? 0.f : 0.999f;
			}

		}	// end particle loop

		return bHitParticle;
	}

	bool IsDead() const
	{
		return GetNumParticlesAlive() == 0;
	}

	UFUNCTION(NetFunction)
	void NetHandleRequestToKillParticles(const FMeshIntersectionData& InData)
	{
		for (auto& ParticleIntersectionDataPair : InData.ParticleIntersectionDataMap)
		{
			const int ParticleIndex = ParticleIntersectionDataPair.GetKey();
			const bool bMarkedForDeath = ParticleIntersectionDataPair.GetValue();

			if (bMarkedForDeath)
			{
				MarkParticleForDeath(ParticleIndex);
			}
			else
			{
				// the existence of the index indicates that we've 
				// requested a VFX particle. This is part of the network optimization
				RequestExtraVFXParticle(ParticleIndex);
			}

		}

		int NumAlive = GetNumParticlesAlive();
		NumAlive -= ParticleindicesMarkedForDeath.Num();
		bAboutToDie = NumAlive <= 0;
	}

	void MarkParticleForDeath(uint8 InParticleIdx)
	{
#if TEST

		devEnsure(Particles[InParticleIdx].bAlive, 
			"The swarm is trying to kill particles that are already dead... \n Please notify Sydney about this and where it happened"
		);

		if (ParticleindicesMarkedForDeath.Contains(InParticleIdx))
		{
			// This shouldn't happen because we make sure that we don't 
			// add duplicates in the intersection phase
			devEnsure(false, 
				"The swarm is trying to kill the same particle multiple times \n Please notify Sydney about this and where it happened"
			);

			ParticleindicesMarkedForDeath.Remove(InParticleIdx);
		}
#endif TEST
		ParticleindicesMarkedForDeath.Add(InParticleIdx);
	}

	void RequestExtraVFXParticle(uint8 InParticleIdx)
	{
		ExtraVFXParticles.Add(InParticleIdx);
#if TEST
		// we could theoretically peak at 480 (4 swarms * 120)... but even that is very unlikely
		ensure(ExtraVFXParticles.Num() < 480);
#endif TEST
	}

}

struct FMeshIntersectionData
{
	// int == particle index, bool == bMarkParticleForDeath
	// Existence of an entry with bool set to false symbolizes that 
	// we should spawn a Niagara Particle but not actually kill the particle
	TMap<uint8, bool> ParticleIntersectionDataMap;
	// we use a map (and not an array of tuples) because the struct operator 
	// override for '==' (in AS at this time) will not be reflected 
	// down in c++ when you call array::contains()
}


