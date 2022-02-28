
import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmSkeletalMeshComponent;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourComponent;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmVictimComponent;
import Cake.LevelSpecific.Tree.Swarm.Movement.SwarmMovementComponent;
import Cake.LevelSpecific.Tree.Swarm.Effects.DeadWaspSpawnerActor;

import Vino.AI.Components.GentlemanFightingComponent;

import peanuts.Audio.AudioStatics;

import void DisableAllSapsAttachedTo(USceneComponent Root) from 'Cake.Weapons.Sap.SapManager';
import Cake.LevelSpecific.Tree.Swarm.Collision.SwarmColliderComponent;

event void FSwarmAboutToDieEvent(ASwarmActor Swarm);
event void FSwarmOnDieEvent(ASwarmActor Swarm);
event void FSwarmOnUltimatePerformedEvent(ASwarmActor Swarm);
event void FExplosionDueToSap(FVector WorldLocation);
event void FHitByMatch(FVector WorldLocation);
event void FSwarmShapeChanged(float ShapeChangeDuration);
event void FSwarmReachedEndOfSpline(ASwarmActor Swarm);

USTRUCT()
struct FSwarmCoreDeadParticleAudioSettings
{
	UPROPERTY()
	int MaxTrackedParticles = 36;
	// Skips prioritize check if the global timer is above the duration since the last particle was registered. 
	UPROPERTY()
	float SkipPrioritizeCheckAfter = 1.;
	UPROPERTY()
	float ParticleDuration = 5.;
	UPROPERTY()
	float PrioritizeParticlesBelowDistance = 500.;
	UPROPERTY()
	int PrioritizeToTrackAfterCount = 12;
	//A interval is how many frames?
	UPROPERTY()
	uint IntervalFrameCount = 3;
	UPROPERTY()
	int MaxSoundsPerInterval = 1;
	UPROPERTY()
	int MaxParticlesToTracksPerInterval = 6;
	UPROPERTY()
	bool Debug = false;

	float Gravity = 600.; // Found in MiniWaspParticle
	
}

UCLASS(abstract, HideCategories = "Activation Replication Input Cooking LOD Actor")
class ASwarmActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USwarmSkeletalMeshComponent SkelMeshComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USwarmBehaviourComponent BehaviourComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USwarmMovementComponent MovementComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USwarmVictimComponent VictimComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent DeathEffectHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = Base)
	USwarmColliderComponent Collider;
	
	UPROPERTY(DefaultComponent, Attach = Collider)
	UHazeAkComponent SwarmAttackAnimHazeAkComp;

	/* Capabilities that run the core functionality of the swarm. */
	UPROPERTY(Category = "Swarm")
	TArray<TSubclassOf<UHazeCapability>> CoreCapabilities;

	/* Class which we'll spawn upon killing a swarm particle. */
	UPROPERTY(Category = "Effects")
	TSubclassOf<AActor> DeadWaspClass;

    // Deletus. 
	UPROPERTY(Category = "Effects")
	UParticleSystem CascadeDeadWaspSpawnerTemplate;// = Asset("/Game/Effects/Gameplay/Wasps/CascadeDeadWaspSpawner.CascadeDeadWaspSpawner");

	/* Class which will managed the dead particle spawning */
	UPROPERTY(Category = "Effects")
	TSubclassOf<ADeadWaspSpawnerActor> DeadWaspSpawnerClass;

	//////////////////////////////////////////////////////////////////////////
	// EVENTS

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathExploEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwarmWallDestroyedEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathParticleEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathParticleRicochet;

	UPROPERTY(Category = "Audio Settings")
	FSwarmCoreDeadParticleAudioSettings SwarmCoreParticleAudioSettings;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FExplosionDueToSap OnSapExplosion;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FHitByMatch OnHitByMatch;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FSwarmOnDieEvent OnDie;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FSwarmAboutToDieEvent OnAboutToDie;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FSwarmOnUltimatePerformedEvent OnUltimatePerformed;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FSwarmShapeChanged ShapeChanged;

	UPROPERTY(Category = "Swarm Events", meta = (BPCannotCallEvent))
	FSwarmReachedEndOfSpline OnReachedEndOfSpline;

	// EVENTS
	//////////////////////////////////////////////////////////////////////////

	// we don't allow particles to be marked for death while the swarm is begin revived (for now)
	bool bInvulnerable = false;

	TArray<USwarmSkeletalMeshComponent> SwarmSkelMeshes;

	UFUNCTION(BlueprintPure)
	bool AreParticlesAlive() const
	{
		for (const USwarmSkeletalMeshComponent SkelMeshIter : SwarmSkelMeshes)
		{
			if (SkelMeshIter.GetNumParticlesAlive() > 0)
			{
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	int32 GetNumMaxParticles() const
	{
		int NumMax = 0;
		for(const USwarmSkeletalMeshComponent SkelMeshIter : SwarmSkelMeshes)
			NumMax += 120;
		return NumMax;
	}

	UFUNCTION(BlueprintPure)
	int32 GetNumParticlesAlive() const
	{
		int NumAlive = 0;
		for(const USwarmSkeletalMeshComponent SkelMeshIter : SwarmSkelMeshes)
			NumAlive += SkelMeshIter.GetNumParticlesAlive();
		return NumAlive;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	#if EDITOR
		// preview the animations for all skelmeshes
		// (the rest of the code is in BeginPlay())
		SkelMeshComp.UpdateSwarmAnimationPreview();

		// !!! this will simply not work because the
		// skelmeshes are defined in BP 
		// TArray<USwarmSkeletalMeshComponent> TempSkelMeshes;
		// GetComponentsByClass(TempSkelMeshes);
		// for (int i = 0; i < TempSkelMeshes.Num(); i++)
		// {
		// 	TempSkelMeshes[i].UpdateSwarmAnimationPreview();
		// }
	#endif

		// fix for sequencer preview
		SkelMeshComp.PlayDefaultSwarmAnim();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		// Both matches and saps evaluate on mays side, so the swarm will too. 
		// (the swarm AI doesn't have a preference atm)
		SetControlSide(Game::GetMay());

		GetComponentsByClass(SwarmSkelMeshes);

		// We prefer them in this order, but we don't really depend on it :) 
		SwarmSkelMeshes.Remove(SkelMeshComp);
		SwarmSkelMeshes.Add(SkelMeshComp);
		int i1 = 0, i2 = SwarmSkelMeshes.Num() - 1;
		while(i1 < SwarmSkelMeshes.Num() / 2)
		{
			SwarmSkelMeshes.Swap(i1, i2);
			i1++;
			--i2;
		}

		// While in editor, we can use UseSingleAnimation to preview the swarm assets 
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].AnimationData.AnimToPlay = nullptr;
			SwarmSkelMeshes[i].SetAnimationMode(EAnimationMode::AnimationBlueprint);
		}

		for (auto& CoreCap : CoreCapabilities)
			AddCapability(CoreCap);
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		VictimComp.ResetGentlemanBehaviour();

		// These are cleaned up automatically
 		// for (auto& CoreCap : CoreCapabilities)
 		// 	RemoveCapability(CoreCap);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		VictimComp.ResetGentlemanBehaviour();
		BehaviourComp.Team = JoinTeam(n"SwarmTeam"); 
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		VictimComp.ResetGentlemanBehaviour();

		// We leave the team at multiple places. We do this check in order to avoid warnings
        if(BehaviourComp.Team != nullptr)
		{
			LeaveTeam(n"SwarmTeam");
			BehaviourComp.Team = nullptr;
		}

		// Print("Disabling all saps on: " + SwarmActor.GetName(), Duration = 5.f);
 		DisableAllSapsAttachedTo(RootComponent);

// #if TEST
// 		if (Game::May.HasControl())
// 		{
// 			for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
// 			{
// 				for (const FSwarmParticle& IterParticle : IterMesh.Particles)
// 				{
// 					// DisableAllSapsAttachedTo should have cleaned this..
// 					ensure(IterParticle.AttachedSapId == -1);
// 				}
// 			}
// 		}
// #endif TEST

		return false;
	}

	void PropagateAttackUltimatePerformed() 
	{
		OnUltimatePerformed.Broadcast(this);

		if(IsActorDisabled())
			return;

		// this will happen when we close the editor 
		if(BehaviourComp.Team == nullptr)
			return;

		BehaviourComp.ReportAttackUltimate();
	}

	UFUNCTION(BlueprintPure)
	float GetSwarmRadius() const
	{
		if(SwarmSkelMeshes.Num() > 1)
		{
			float AverageSwarmRadius = 0.f;
			for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
				AverageSwarmRadius += SwarmSkelMeshes[i].GetLocalBoundsRadius();
			AverageSwarmRadius /= SwarmSkelMeshes.Num();

			return AverageSwarmRadius;
		}
		else
		{
			return SkelMeshComp.GetLocalBoundsRadius();
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetSwarmCenterOfParticlesVelocity() const
	{
		if(SwarmSkelMeshes.Num() > 1)
		{
			FVector AverageCenterOfParticlesVelocity = FVector::ZeroVector;
			for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
				AverageCenterOfParticlesVelocity += SwarmSkelMeshes[i].CenterOfParticlesVelocity;
			AverageCenterOfParticlesVelocity /= SwarmSkelMeshes.Num();

			return AverageCenterOfParticlesVelocity;
		}
		else
		{
			return SkelMeshComp.CenterOfParticlesVelocity;
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetSwarmLocalBoundExtent() const
	{
		if(SwarmSkelMeshes.Num() > 1)
		{
			FBox MergedBox = FBox();
			for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
				MergedBox += SwarmSkelMeshes[i].GetLocalBoundBox();

			return MergedBox.GetExtent();
		}
		else
		{
			return SkelMeshComp.GetLocalBoundExtent();
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetSwarmCenterOfParticles() const
	{
		if(SwarmSkelMeshes.Num() > 1)
		{
			FVector AverageCenterOfParticles = FVector::ZeroVector;
			for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
				AverageCenterOfParticles += SwarmSkelMeshes[i].CenterOfParticles;
			AverageCenterOfParticles /= SwarmSkelMeshes.Num();

			return AverageCenterOfParticles;
		}
		else
		{
			return SkelMeshComp.CenterOfParticles;
		}
	}

	UFUNCTION(BlueprintPure)
	FVector GetSwarmCenterLocation() const
	{
		if(SwarmSkelMeshes.Num() > 1)
		{
			FVector AverageCenterLocation = FVector::ZeroVector;
			for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
				AverageCenterLocation += SwarmSkelMeshes[i].GetWorldBoundOrigin();
			AverageCenterLocation /= SwarmSkelMeshes.Num();

			return AverageCenterLocation;
		}
		else
		{
			return SkelMeshComp.CenterOfParticles;
		}
	}

	UFUNCTION()
	void CopyOtherSwarm(ASwarmActor OtherSwarm)
	{
		// no longer needed now that we've fixed inertialization
		// if(RootComponent.GetMobility() == EComponentMobility::Movable)
		// 	SetActorTransform(OtherSwarm.GetActorTransform());

		SkelMeshComp.CopyOtherSwarmMesh(OtherSwarm.SkelMeshComp);

		if (SwarmSkelMeshes.Num() == OtherSwarm.SwarmSkelMeshes.Num())
		{
			for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
			{
				USwarmSkeletalMeshComponent& OurSkelMesh = SwarmSkelMeshes[i];
				USwarmSkeletalMeshComponent& OtherSkelMesh = OtherSwarm.SwarmSkelMeshes[i];
				OurSkelMesh.CopyOtherSwarmMesh(OtherSkelMesh);
			}
		}
		else
		{
			USwarmSkeletalMeshComponent& OtherSkelMesh = OtherSwarm.SkelMeshComp;
			for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
			{
				USwarmSkeletalMeshComponent& OurSkelMesh = SwarmSkelMeshes[i];
				OurSkelMesh.CopyOtherSwarmMesh(OtherSkelMesh);
			}
		}

		MovementComp.DesiredSwarmActorTransform = OtherSwarm.MovementComp.DesiredSwarmActorTransform;
		MovementComp.TranslationVelocity = OtherSwarm.MovementComp.TranslationVelocity;
		MovementComp.PhysicsVelocity = OtherSwarm.MovementComp.PhysicsVelocity;
	}

	UFUNCTION(Category = "Swarm|Movement")
	void TeleportSwarm(const FTransform& DestinationTransform)
	{
		const FVector CurrentLocation = MovementComp.DesiredSwarmActorTransform.GetLocation();
		const FVector DesiredLocation = DestinationTransform.GetLocation();
		const FVector DeltaMove = DesiredLocation - CurrentLocation;

		if (DeltaMove.IsZero())
			return;

		// Move Swarm
		SetActorTransform(DestinationTransform);
		MovementComp.DesiredSwarmActorTransform = DestinationTransform;

		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			USwarmSkeletalMeshComponent& SwarmSkelMeshIter = SwarmSkelMeshes[i];

			// Move particles
			for (int j = 0; j < SwarmSkelMeshIter.Particles.Num(); ++j)
				SwarmSkelMeshIter.ApplyDeltaTranslationToParticleByIndex(j, DeltaMove);

			SwarmSkelMeshIter.CenterOfParticles += DeltaMove;
		}

	}

	UFUNCTION(Category = "Swarm", Meta = (AdvancedDisplay = "OptionalSplineActorToFollow"))
	void SwitchTo(
		UHazeCapabilitySheet OptionalBehaviourSheet,
		USwarmBehaviourBaseSettings OptionalBehaviourSettings = nullptr,
		AActor OptionalSplineActorToFollow = nullptr
	)
	{
		if (OptionalBehaviourSettings != nullptr)
			SwitchBehaviourSettings(OptionalBehaviourSettings);

		if (OptionalSplineActorToFollow != nullptr)
			SwitchSplineToFollow(OptionalSplineActorToFollow);

		if (OptionalBehaviourSheet != nullptr)
			SwitchBehaviour(OptionalBehaviourSheet);
	}

	UFUNCTION()
	void OverrideBehaviourState(ESwarmBehaviourState StateToPrioritize)
	{
		BehaviourComp.OverrideStatePrioritization(StateToPrioritize);
	}

	UFUNCTION()
	void SwitchBehaviour(UHazeCapabilitySheet InSheet)
	{
		if (InSheet == nullptr)
		{
			ensure(false);
			return;
		}

		if(InSheet == BehaviourComp.CurrentBehaviourSheet)
			return;

		BehaviourComp.SwitchSheet(InSheet);

		VictimComp.ResetGentlemanBehaviour();
		VictimComp.ClearAllPlayerOverride();
	}

	UFUNCTION()
	void SwitchBehaviourSettings(USwarmBehaviourBaseSettings InSettings)
	{
		if (InSettings == nullptr)
		{
			ensure(false);
			return;
		}

		if (InSettings == BehaviourComp.CurrentBehaviourSettings)
			return;

		BehaviourComp.SwitchSettings(InSettings);
	}

	UFUNCTION(Category = "Swarm|Movement")
	void SwitchSplineToFollow(AActor ActorWithSpline)
	{
		MovementComp.FollowSplineActor = ActorWithSpline;

		if (ActorWithSpline != nullptr)
			MovementComp.FollowSplineComp = UHazeSplineComponent::Get(ActorWithSpline);
	}

	UFUNCTION(Category = "Swarm|Movement")
	void SwitchSplineComponentToFollow(UHazeSplineComponent SplineComp)
	{
		if (SplineComp == nullptr)
		{
			MovementComp.FollowSplineComp = nullptr;
			MovementComp.FollowSplineActor = nullptr;
		}
		else 
		{
			MovementComp.FollowSplineComp = SplineComp;
			MovementComp.FollowSplineActor = SplineComp.GetOwner();
		}
	}

	UFUNCTION()
	void ReviveSwarmByBoneName(FName ParticleBoneName)
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].ReviveParticleByBoneName(ParticleBoneName);
			SwarmSkelMeshes[i].ParticleindicesMarkedForDeath.Reset();
			SwarmSkelMeshes[i].ExtraVFXParticles.Reset();
			SwarmSkelMeshes[i].bAboutToDie = false;
		}

		if (IsActorDisabled())
			EnableActor(nullptr);
	}

	UFUNCTION()
	void PrepareSwarmForRevival()
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].ParticleindicesMarkedForDeath.Reset();
			SwarmSkelMeshes[i].ExtraVFXParticles.Reset();
			SwarmSkelMeshes[i].bAboutToDie = false;
		}

		if (IsActorDisabled())
			EnableActor(nullptr);
	}

	UFUNCTION()
	void ReviveSwarm()
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].ReviveAllParticles();
			SwarmSkelMeshes[i].ParticleindicesMarkedForDeath.Reset();
			SwarmSkelMeshes[i].ExtraVFXParticles.Reset();
			SwarmSkelMeshes[i].bAboutToDie = false;
		}

		if (IsActorDisabled())
			EnableActor(nullptr);
	}

	UFUNCTION()
	void KillSwarm()
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].KillAllParticles();
			SwarmSkelMeshes[i].bAboutToDie = true;
		}
	}

	ESwarmShape GetCurrentShape() const
	{
		if(BehaviourComp.CurrentBehaviourSettings != nullptr)
			return BehaviourComp.CurrentBehaviourSettings.Shape;
		return ESwarmShape::None;
	}

	ESwarmShape GetPreviousShape() const
	{
		return BehaviourComp.PreviousShape;
	}

	// Check if this swarm is certain shape
	bool IsShape(ESwarmShape InShape) const
	{
		if(BehaviourComp.CurrentBehaviourSettings != nullptr)
			return BehaviourComp.CurrentBehaviourSettings.Shape == InShape;
		return InShape== ESwarmShape::None;
	}

	// plays the animation, linked with an instigator
	UFUNCTION()
	void PlaySwarmAnimation(
		USwarmAnimationSettingsBaseDataAsset InAnimSettingsData,
		UObject InInstigator,
		float InInertiaBlendTime = 0.2f
	)
	{
		// Asset with a single animation
		const auto InAnimSettingsData_Single = Cast<USwarmAnimationSettingsDataAsset>(InAnimSettingsData);
		if(InAnimSettingsData_Single != nullptr)
		{
			// give it to all meshes
			for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
			{
				SwarmSkelMeshes[i].PlaySwarmAnimation_Internal(InAnimSettingsData_Single, InInstigator, InInertiaBlendTime);
			}

			ShapeChanged.Broadcast(InInertiaBlendTime);
			return;
		}

		// Asset with several unique animations
		const auto InAnimSettingsData_Multi = Cast<UMultiSwarmAnimationSettingsDataAsset>(InAnimSettingsData);
		const int FinalAssetIdx = InAnimSettingsData_Multi.Assets.Num() - 1;
		if(InAnimSettingsData_Multi != nullptr && FinalAssetIdx != -1)
		{
			// loop through all skelmeshes and give them unique assets (if we have enough of them)
			int AssetIndex = 0, SwarmSkelMeshIndex = 0;
			while(SwarmSkelMeshIndex < SwarmSkelMeshes.Num())
			{
				SwarmSkelMeshes[SwarmSkelMeshIndex].PlaySwarmAnimation_Internal(
					InAnimSettingsData_Multi.Assets[AssetIndex],
					InInstigator,
					InInertiaBlendTime
				);

				// re-use the last asset next time if we have to few
				if(AssetIndex < FinalAssetIdx)
					++AssetIndex;

				++SwarmSkelMeshIndex;
			}

			ShapeChanged.Broadcast(InInertiaBlendTime);
			return;
		}

	}

	// removes any animations started by the instigator
	UFUNCTION()
	void StopSwarmAnimationByInstigator(UObject InInstigator)
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
			SwarmSkelMeshes[i].StopSwarmAnimation_Internal(InInstigator);
	}

	bool FindParticlesWithinMatchDeathRadius(
		FSwarmIntersectionData& OutSwarmIntersectionData,
		const FVector& InMatchWorldLocation,
		const float InMatchCollisionRadius,
		const int MaxDeathsByMatch,
		int& NumDeathsBymatch
	) const
	{
		int32 NumParticlesAliveBeforeBlast = 0;
		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			NumParticlesAliveBeforeBlast += IterMesh.GetNumParticlesAlive();
			NumParticlesAliveBeforeBlast -= IterMesh.ParticleindicesMarkedForDeath.Num();
		}

#if EDITOR

		// please let Sydney know that the math is wrong 
		ensure(NumParticlesAliveBeforeBlast >= 0);

		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			if (IterMesh.GetSwarmAnimSettingsDataAsset() == nullptr)
			{
				devEnsure(false, "The Match can't damage the swarm because the SwarmMesh is missing an Animation Asset with the settings. The current Behaviour settings, on the swarm, is probably missing the asset. Otherwise the default SwarmAnimSettings on the mesh itself isn't assigned. \n \n Please notify Sydney of this!");
				return false;
			} 
		}

		// Assuming that an empty container is passed in...
		ensure(OutSwarmIntersectionData.MeshIntersectionDataMap.Num() <= 0);

#endif EDITOR

		// all are dead, early out
		if (NumParticlesAliveBeforeBlast <= 0)
			return false;

		// Summarize thresholds due to multiple meshes
		int32 ThresholdMaxDeaths = 0;
		int32 ThresholdMaxVFXSpawnCount = 0;
		int32 NumBonesMarkedForDeath = 0;
		int32 NumVFXParticlesRequested = 0;
		int32 KillAllParticlesThreshold = 0;
		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			const FSwarmAnimationSettings& Settings = IterMesh.GetSwarmAnimSettingsDataAsset().Settings;

			// keep track how many particles have been killed (sap and match weapon combined)
			NumBonesMarkedForDeath += IterMesh.ParticleindicesMarkedForDeath.Num();
			NumVFXParticlesRequested += IterMesh.ExtraVFXParticles.Num();

			KillAllParticlesThreshold += Settings.KillAllParticlesThreshold;
			ThresholdMaxVFXSpawnCount += Settings.MaxSpawnCountPerBlast;
			ThresholdMaxDeaths += Settings.MaxDeathsPerBlast;
		}

		// Only allow sap to finish the swarm 
		if (NumParticlesAliveBeforeBlast <= KillAllParticlesThreshold)
			return false;

		// don't allow any (real) particles to be killed while reviving
		if (bInvulnerable)
			ThresholdMaxDeaths = 0;

		// empty ~= reserve in .as
		OutSwarmIntersectionData.MeshIntersectionDataMap.Empty(SwarmSkelMeshes.Num());

		// int32 NumDeathsBymatch = 0;
		// const int32 MaxDeathsByMatch = 1;

		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			FMeshIntersectionData MeshIntersectionData;
			MeshIntersectionData.ParticleIntersectionDataMap.Empty(IterMesh.Particles.Num());

			const FSwarmAnimationSettings& Settings = IterMesh.GetSwarmAnimSettingsDataAsset().Settings;

			const float CollisionDistThreshold = InMatchCollisionRadius + SkelMeshComp.ParticleRadius;
			const float CollisionDistThresholdSQ = FMath::Square(CollisionDistThreshold);

			// Loop through all particles, and check if are overlapping the match
			for (int i = 0; i < IterMesh.Particles.Num(); ++i)
			{
				const FVector ParticlePos = IterMesh.Particles[i].CurrentTransform.GetLocation();
				const FVector MatchToParticle = ParticlePos - InMatchWorldLocation;
				const float MatchToParticleDistSQ = MatchToParticle.SizeSquared();

				// ignore particles outside of the threshold
				if (MatchToParticleDistSQ > CollisionDistThresholdSQ)
					continue;

				if (NumDeathsBymatch >= MaxDeathsByMatch)
					break;

				bool bMarkedForDeath = false;
				bool bVFXParticleRequested = false;
				if (NumBonesMarkedForDeath < ThresholdMaxDeaths && !IterMesh.ParticleindicesMarkedForDeath.Contains(i))
				{
					bMarkedForDeath = true;
					++NumBonesMarkedForDeath;
				}
				else if(NumVFXParticlesRequested < ThresholdMaxVFXSpawnCount)
				{
					bVFXParticleRequested = true;
					++NumVFXParticlesRequested;
				}

				if (bMarkedForDeath || bVFXParticleRequested)
					MeshIntersectionData.ParticleIntersectionDataMap.Add(i, bMarkedForDeath);

				++NumDeathsBymatch;

			}	// end particle loop

			ensure(MeshIntersectionData.ParticleIntersectionDataMap.Num() <= 120);

			// we don't want to send empty data containers unnecessarily
			if (MeshIntersectionData.ParticleIntersectionDataMap.Num() > 0)
				OutSwarmIntersectionData.MeshIntersectionDataMap.Add(IterMesh, MeshIntersectionData);

		}	// end mesh loop

		return OutSwarmIntersectionData.MeshIntersectionDataMap.Num() != 0;
	}

	UFUNCTION(NetFunction)
	void NetApplyMatchIntersectionData(
		const FVector InMatchRelativeToSwarmLocation,
		const TArray<FMeshIntersectionData>& InIntersectionDataContainer
	)
	{
		const FVector MatchLocation = GetActorTransform().TransformPosition(
			InMatchRelativeToSwarmLocation 
		);

		OnHitByMatch.Broadcast(MatchLocation);
	}

	void HandleSwarmBuilderRevival()
	{
		if (!HasControl())
			return;

		NetHandleSwarmBuilderRevival();
	}

	UFUNCTION(NetFunction)
	void NetHandleSwarmBuilderRevival()
	{
		// (it was attached to the builder incase the builder moved during the building)
		DetachFromActor(EDetachmentRule::KeepWorld);

		// make the finished swarm vulnerable again. 
		SetInvulnerabilityFlag(false);

		// the remote will be behind. Temp solution until we figure out how to network this
		ReviveSwarm();
	}

	void HandleSapExplosion(
		USceneComponent InComp,
		const FName InBoneName,
		const FVector& InRelativeLocation,
		const float InMassFraction
	)
	{
		if (!HasControl())
			return;

		// this swarm isn't gonna be visible and we won't find any
		// nearby swarms because we've left the team upon being disabled
		// @TODO this needs to go through a manager for it to work
		if (IsActorDisabled())
			return;

		// Handle explosion impulses and stun durations. Purely cosmetic.
		NetHandleSapExplosionImpulses(InComp, InRelativeLocation, InMassFraction, InBoneName);

		// Handle particle deaths
		TArray<FSwarmIntersectionData> SwarmIntersectionDataContainer;
		const FVector SapWorldLocation = InComp.GetSocketTransform(InBoneName).TransformPosition(InRelativeLocation);
		if (FindSwarmsWithinSapDeathBlastRadius(SwarmIntersectionDataContainer, SapWorldLocation, InMassFraction))
		{
			for(FSwarmIntersectionData& SwarmIntersectionData : SwarmIntersectionDataContainer)
			{
				for (auto& MeshIntersectionDataPair : SwarmIntersectionData.MeshIntersectionDataMap)
				{
					USwarmSkeletalMeshComponent SwarmMesh = MeshIntersectionDataPair.GetKey();
					const FMeshIntersectionData& IntersectionData = MeshIntersectionDataPair.GetValue();

#if TEST
					// Particles that were marked for death in the intersection phase should be alive!
					for (auto& ParticleIntersectionDataPair : IntersectionData.ParticleIntersectionDataMap)
					{
						const int ParticleIndex = ParticleIntersectionDataPair.GetKey();
						const bool bMarkedForDeath = ParticleIntersectionDataPair.GetValue();
						if(bMarkedForDeath)
						{
							devEnsure(!SwarmMesh.bInvulnerable, "Swarm is Sending over killCommands while being invulnerable. \n Notify sydney");
							if(SwarmMesh.bInvulnerable)
							{
								TArray<FSwarmIntersectionData> DebugSwarmIntersectionData;
								FindSwarmsWithinSapDeathBlastRadius(DebugSwarmIntersectionData, SapWorldLocation, InMassFraction);
							}
							devEnsure( SwarmMesh.Particles[ParticleIndex].bAlive && !SwarmMesh.ParticleindicesMarkedForDeath.Contains(ParticleIndex), "The swarm is trying to kill particles that are already dead on the control side! \n Please notify Sydney about this. It's muy importante");
						}
					}
#endif TEST

					SwarmMesh.NetHandleRequestToKillParticles(IntersectionData);
				}
			}

		}
	}

	UFUNCTION(NetFunction)
	void NetHandleSapExplosionImpulses(
		USceneComponent InSwarmComponent,
		FVector InSapRelativeLocation,
		float InSapMassFraction,
		FName InSwarmBoneName
	)
	{
		const FTransform SwarmBoneTransform = InSwarmComponent.GetSocketTransform(InSwarmBoneName);
		const FVector SapWorldLocation = SwarmBoneTransform.TransformPosition(InSapRelativeLocation);

		// Impulse to _this_ swarm
		if (!IsDead())
		{
			if (GatherAndApplyImpulseDataForSap(SapWorldLocation, InSapMassFraction))
			{
				HandleSapExplosionImpulse(SapWorldLocation);
			}
		}

		// Impulse to _nearby_ swarms that might get caught in the blast
		if (BehaviourComp.Team != nullptr)
		{
			for(AHazeActor TeamMember : BehaviourComp.Team.GetMembers())
			{
				if(TeamMember == nullptr)
					continue;

				if(TeamMember == this)
					continue;

				ASwarmActor OtherSwarm = Cast<ASwarmActor>(TeamMember);

				if (OtherSwarm == nullptr)
					continue;

				if (OtherSwarm.IsDead())
					continue;

				if (OtherSwarm.IsWithinSapBlastRadius(SapWorldLocation, InSapMassFraction))
				{
					if (OtherSwarm.GatherAndApplyImpulseDataForSap(SapWorldLocation, InSapMassFraction))
					{
						OtherSwarm.HandleSapExplosionImpulse(SapWorldLocation);
					}
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	bool NetHandleMatchIntersectionImpulses(
		const FVector& InMatchRelativeToSwarmLocation,
		const FVector& InMatchVelocityNormalized,
		const float InMatchCollisionRadius
	)
	{
		// we want to make sure that the particles don't explode towards the camera.
		const FVector CameraForward = Game::GetMay().GetPlayerViewRotation().Vector();
		const FVector MatchLocation = GetActorTransform().TransformPosition(InMatchRelativeToSwarmLocation);

		bool bValidHit = false;
		for(USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			if(IterMesh.GatherAndApplyImpulseDataForMatch(
				MatchLocation,
				InMatchVelocityNormalized,
				CameraForward,
				InMatchCollisionRadius
			))
			{
				bValidHit = true;
			}
		} 

		if (bValidHit)
			OnHitByMatch.Broadcast(MatchLocation);

		return bValidHit;
	}

	// Splitting up Gather _and_ Apply would require us
	// to create and potentially store (120 particles * SwarmSkelMeshes) structs
	// just to be applied straight afterwards.. And that entire loop might
	// occur 20+ times per frame due to sap explosions
	bool GatherAndApplyImpulseDataForSap(const FVector& InSapWorldLocation, const float InSapMassFraction)
	{
		bool bHitParticle = false;
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if (SwarmSkelMeshes[i].GatherAndApplyImpulseDataForSap(InSapWorldLocation, InSapMassFraction))
			{
				bHitParticle = true;
			}
		}
		return bHitParticle;
	}

	void HandleSapExplosionImpulse(const FVector& InSapWorldLocation)
	{
		BehaviourComp.TimeStamp_LastExplosionDuringState = Time::GetGameTimeSeconds();
		OnSapExplosion.Broadcast(InSapWorldLocation);
	}

	bool FindSwarmsWithinSapDeathBlastRadius(
		TArray<FSwarmIntersectionData>& OutSwarmIntersectionDataContainer,
		const FVector& InSapLocation,
		const float InSapMassFraction
	)  const
	{

#if TEST
		// Assuming that an empty container is passed in...
		ensure(OutSwarmIntersectionDataContainer.Num() <= 0);
#endif TEST

		// gather intersection data for THIS swarm
		FSwarmIntersectionData SwarmIntersectionData;
		if(FindParticlesWithinSapDeathBlastRadius(SwarmIntersectionData, InSapLocation, InSapMassFraction))
			OutSwarmIntersectionDataContainer.Add(SwarmIntersectionData);

		// @TODO: Swarm is dead but sap is still calling explode. Check with Emil.
		// we probably have to route HandleSapExplosion through a swarm manager
		if (BehaviourComp.Team == nullptr)
			return OutSwarmIntersectionDataContainer.Num() > 0;

		// Account for nearby swarms that might get caught in the blast
		for(AHazeActor TeamMember : BehaviourComp.Team.GetMembers())
		{
			if(TeamMember == nullptr)
				continue;

			if(TeamMember == this)
				continue;

			ASwarmActor OtherSwarm = Cast<ASwarmActor>(TeamMember);

			if (OtherSwarm == nullptr)
				continue;

			if (OtherSwarm.IsAboutToDie())
				continue;

			if (OtherSwarm.IsWithinSapDeathBlastRadius(InSapLocation, InSapMassFraction))
			{
				FSwarmIntersectionData NearbySwarmIntersectionData;
				if(OtherSwarm.FindParticlesWithinSapDeathBlastRadius(NearbySwarmIntersectionData, InSapLocation, InSapMassFraction))
				{
					OutSwarmIntersectionDataContainer.Add(NearbySwarmIntersectionData);
				}
			}

		}

		return OutSwarmIntersectionDataContainer.Num() > 0;
	}

	/*	we keep this func here, and not on the mesh, because 
		multiple meshes are to be thought of as a single Swarm mesh */
	bool FindParticlesWithinSapDeathBlastRadius(
		FSwarmIntersectionData& OutSwarmIntersectionData,
		const FVector& InSapLocation,
		const float InSapMassFraction 
	) const
	{

		int32 NumParticlesAliveBeforeBlast = 0;
		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			NumParticlesAliveBeforeBlast += IterMesh.GetNumParticlesAlive();
			NumParticlesAliveBeforeBlast -= IterMesh.ParticleindicesMarkedForDeath.Num();
		}
		
#if TEST 

		// please let Sydney know that the math is wrong 
		ensure(NumParticlesAliveBeforeBlast >= 0);

		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			if (IterMesh.GetSwarmAnimSettingsDataAsset() == nullptr)
			{
				devEnsure(false, "SwarmMesh is missing an Animation Asset with the settings. The current Behaviour settings, on the swarm, is probably missing the asset. Otherwise the default SwarmAnimSettings on the mesh itself isn't assigned. \n \n Please notify Sydney of this!");
				return false;
			} 
		}

		// Assuming that an empty container is passed in...
		ensure(OutSwarmIntersectionData.MeshIntersectionDataMap.Num() <= 0);

#endif TEST

		// all are dead, early out
		if (NumParticlesAliveBeforeBlast <= 0)
			return false;

		// Summarize thresholds due to multiple meshes
		int32 MaxDeathsThreshold = 0;
		int32 MaxVFXSpawnCountThreshold = 0;
		int32 KillAllParticlesThreshold = 0;
		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			const FSwarmAnimationSettings& Settings = IterMesh.GetSwarmAnimSettingsDataAsset().Settings;
			KillAllParticlesThreshold += Settings.KillAllParticlesThreshold;
			MaxVFXSpawnCountThreshold += Settings.MaxSpawnCountPerBlast;
			MaxDeathsThreshold += Settings.MaxDeathsPerBlast;
		}

		// don't allow any (real) particles to be killed while reviving
		if (bInvulnerable)
			MaxDeathsThreshold = 0;

		// empty ~= reserve for FMap in .as
		OutSwarmIntersectionData.MeshIntersectionDataMap.Empty(SwarmSkelMeshes.Num());

		int32 TotalNumBonesMarkedForDeath = 0;
		int32 TotalNumVFXParticlesRequested = 0;
		for(USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			const FSwarmAnimationSettings& Settings = IterMesh.GetSwarmAnimSettingsDataAsset().Settings;

			const float DeathRadiusThreshold = FMath::Lerp(
				Settings.DeathRadiusRangeMin,
				Settings.DeathRadiusRangeMax,
				InSapMassFraction
			);
			const float DeathRadiusThresholdSQ = FMath::Square(DeathRadiusThreshold);

			// System::DrawDebugSphere(InSapLocation, DeathRadiusThreshold, 12, FLinearColor::Blue, 3.f);
//			Print("DeathRadius: " + DeathRadiusThreshold);

			FMeshIntersectionData MeshIntersectionData;

			// empty ~= reserve for FMap in .as
			MeshIntersectionData.ParticleIntersectionDataMap.Empty(IterMesh.Particles.Num());

			// figure out which particles to kill...
			for (int i = 0; i < IterMesh.Particles.Num(); ++i)
			{
				if (IterMesh.Particles[i].bAlive == false)
					continue;

				const FVector SapToParticle = IterMesh.Particles[i].CurrentTransform.GetLocation() - InSapLocation;
				const float SapToParticleDistanceSQ = SapToParticle.SizeSquared();

				const bool bWithinDeathRadius = SapToParticleDistanceSQ < DeathRadiusThresholdSQ; 
				if (!bWithinDeathRadius)
					continue;

				bool bMarkedForDeath = false;
				bool bVFXParticleRequested = false;
				if (TotalNumBonesMarkedForDeath < MaxDeathsThreshold && !IterMesh.ParticleindicesMarkedForDeath.Contains(i))
				{
					bMarkedForDeath = true;
					++TotalNumBonesMarkedForDeath;

//					PrintToScreen("Marked for death: " + i, Duration = 1.f);

					bVFXParticleRequested = true;
					++TotalNumVFXParticlesRequested;
				}
				else if (TotalNumVFXParticlesRequested < MaxVFXSpawnCountThreshold && !IterMesh.ExtraVFXParticles.Contains(i))
				{
					/* note that we do the contains check here just because we might get overflowed with extras.
						Imagine 1 sap blast being big enough to affect all particles. 120 extra spawned but only
						~10 allowed to die per blast. Now imagine 50 saps exploding on the swarm. Only 
						1 explosion is allowed to explode per frame (currently). */
					bVFXParticleRequested = true;
					++TotalNumVFXParticlesRequested;
				}

				if (bMarkedForDeath || bVFXParticleRequested)
				{
#if TEST
					ensure(!MeshIntersectionData.ParticleIntersectionDataMap.Contains(i));
#endif TEST
					MeshIntersectionData.ParticleIntersectionDataMap.Add(i, bMarkedForDeath);
//					bool& bCurrentlyMarkedForDeath = MeshIntersectionData.ParticleIntersectionDataMap.FindOrAdd(i);
//					bCurrentlyMarkedForDeath = bMarkedForDeath;
				}

			} // end particle loop

#if TEST
			ensure(MeshIntersectionData.ParticleIntersectionDataMap.Num() <= 120);
#endif TEST

			// we don't want to send empty data containers unnecessarily
			if (MeshIntersectionData.ParticleIntersectionDataMap.Num() > 0)
				OutSwarmIntersectionData.MeshIntersectionDataMap.Add(IterMesh, MeshIntersectionData);

		} // end mesh loop

		const int32 NumParticlesAliveAfterBlast = NumParticlesAliveBeforeBlast - TotalNumBonesMarkedForDeath;

#if TEST
		ensure(NumParticlesAliveAfterBlast >= 0);
#endif TEST

		// Just kill all particles if there are to few of them left
//		if (true)
		if (NumParticlesAliveAfterBlast <= KillAllParticlesThreshold && NumParticlesAliveAfterBlast > 0 && !bInvulnerable)
		{
			for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
			{
				auto& MeshIntersectionData = OutSwarmIntersectionData.MeshIntersectionDataMap.FindOrAdd(IterMesh);
				for (int i = 0; i < IterMesh.Particles.Num(); ++i)
				{
					// @Optimize: Keep track of an alive particles array globally and use that instead
					if (IterMesh.Particles[i].bAlive == false || IterMesh.ParticleindicesMarkedForDeath.Contains(i))
						continue;

					// (add new ones or) account for particles that were added previously in this function
					bool& bMarkedForDeath = MeshIntersectionData.ParticleIntersectionDataMap.FindOrAdd(i);
					bMarkedForDeath = true;

				} // end particle loop

#if TEST
				ensure(MeshIntersectionData.ParticleIntersectionDataMap.Num() <= 120);
#endif TEST

			}	// end mesh loop
		}

		return OutSwarmIntersectionData.MeshIntersectionDataMap.Num() != 0;
	}

	// Use Sphere (Match) vs Box (swarm) intersection to figure out if it hit the swarm
	bool IsWithinMatchIntersectionRadius(const FVector& InMatchLocation, const float InMatchCollisionRadius) const
	{
		FBox SwarmBox = SkelMeshComp.GetWorldBoundBox();
		for(USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			if (IterMesh != SkelMeshComp)
			{
				SwarmBox += IterMesh.GetWorldBoundBox();
			}
		}
		const float MatchCollisionRadSQ = FMath::Square(InMatchCollisionRadius);
		return FMath::SphereAABBIntersection(InMatchLocation, MatchCollisionRadSQ, SwarmBox);
	}

	bool IsWithinSapDeathBlastRadius(const FVector& InSapLocation, const float InSapMassFraction) const
	{
		// 1. Find largest death blast radius for swarm
		float MaxDeathBlastRadius = 0.f;
		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			const FSwarmAnimationSettings& Settings = IterMesh.GetSwarmAnimSettingsDataAsset().Settings;

			const float DeathRadius = FMath::Lerp( Settings.DeathRadiusRangeMin, Settings.DeathRadiusRangeMax, InSapMassFraction );
			if(DeathRadius > MaxDeathBlastRadius)
				MaxDeathBlastRadius = DeathRadius;
		}

		const float MaxDeathBlastRadiusSquared = FMath::Square(MaxDeathBlastRadius);

		// 2. Use Sphere (sap) vs Box (swarm) intersection to figure out if it hit the swarm
		FBox SwarmBox = SkelMeshComp.GetWorldBoundBox();
		for(USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			if (IterMesh != SkelMeshComp)
			{
				SwarmBox += IterMesh.GetWorldBoundBox();
			}
		}

		return FMath::SphereAABBIntersection(InSapLocation, MaxDeathBlastRadiusSquared, SwarmBox);
	}

	bool IsWithinSapBlastRadius(const FVector& InSapLocation, const float InSapMassFraction) const
	{
		// 1. Find largest blast radius for swarm
		float MaxBlastRadius = 0.f;
		for (USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			const FSwarmAnimationSettings& Settings = IterMesh.GetSwarmAnimSettingsDataAsset().Settings;

			const float DeathRadius = FMath::Lerp( Settings.DeathRadiusRangeMin, Settings.DeathRadiusRangeMax, InSapMassFraction );
			const float ExplosionRadius = DeathRadius * Settings.ExplosionRadiusMultiplier;
			const float LargestBlastRadius = FMath::Max(DeathRadius, ExplosionRadius);

			if(LargestBlastRadius > MaxBlastRadius)
				MaxBlastRadius = LargestBlastRadius;
		}

		const float MaxBlastRadiusSquared = FMath::Square(MaxBlastRadius);

		// 2. Use Sphere (sap) vs Box (swarm) intersection to figure out if it hit the swarm
		FBox SwarmBox = SkelMeshComp.GetWorldBoundBox();
		for(USwarmSkeletalMeshComponent IterMesh : SwarmSkelMeshes)
		{
			if (IterMesh != SkelMeshComp)
			{
				SwarmBox += IterMesh.GetWorldBoundBox();
			}
		}

		return FMath::SphereAABBIntersection(InSapLocation, MaxBlastRadiusSquared, SwarmBox);
	}

	bool IsDead() const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if(SwarmSkelMeshes[i].GetNumParticlesAlive() != 0)
			{
				return false;
			}
		}
		return true;
	}

	bool IsAboutToDie() const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if(!SwarmSkelMeshes[i].bAboutToDie)
			{
				return false;
			}
		}

		return true;
	}

	bool GetParticleClosestToLocation(const FVector& InWorldLocation, FSwarmParticle& OutParticle) const
	{
		int ClosestIndex = -1;
		int ClosestSkelMeshIndex = -1;
		float ClosestDistToParticleSQ = BIG_NUMBER;

		for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
		{
			int ParticleIndex = -1;
			float DistToParticleSQ = BIG_NUMBER;
			SwarmSkelMeshes[i].FindParticleIndexClosestToLocation(InWorldLocation, ParticleIndex, DistToParticleSQ);

			if(DistToParticleSQ < ClosestDistToParticleSQ)
			{
				ClosestSkelMeshIndex = i;
				ClosestIndex = ParticleIndex;
				ClosestDistToParticleSQ = DistToParticleSQ;
			}
		}

		if (ClosestIndex == -1)
			return false;

		OutParticle = SwarmSkelMeshes[ClosestSkelMeshIndex].Particles[ClosestIndex];

		return true;
	}

	bool FindParticleClosestToRay(
		FVector RayStart,
		FVector RayEnd, 
		USwarmSkeletalMeshComponent& OutSwarmSkelMesh,
		FName& OutParticleName,
		FVector& OutRayLocation,
		float& OutDistance
	) const
	{
		float ClosestMeshDistSQ = BIG_NUMBER;

		float ClosestDistSQ = BIG_NUMBER;
		FName ClosestParticleName = NAME_None;
		FVector ClosestLocation = FVector::ZeroVector;

		bool bFound = false;

		for (int i = 0; i < SwarmSkelMeshes.Num(); ++i)
		{
			SwarmSkelMeshes[i].FindParticleClosestToRay(RayStart, RayEnd, ClosestParticleName, ClosestLocation, ClosestDistSQ);

			if(ClosestDistSQ < ClosestMeshDistSQ)
			{
				// we'll sqrt after the loop is done
				OutDistance = ClosestDistSQ;

				OutParticleName = ClosestParticleName;
				OutSwarmSkelMesh = SwarmSkelMeshes[i];
				OutRayLocation = ClosestLocation;

				ClosestMeshDistSQ = ClosestDistSQ;

				bFound = true;
			}
		}

		OutDistance = FMath::Sqrt(OutDistance);

		return bFound;
	}

	void ClaimOtherVictim(ESwarmBehaviourState InState, int MaxAllowed = 1)
	{
		const auto Tag = GetSwarmCapabilityTag(InState); 
		VictimComp.ClaimPlayer(VictimComp.CurrentVictim.OtherPlayer, Tag, MaxAllowed);
	}

	void ClaimVictim(ESwarmBehaviourState InState, int MaxAllowed = 1)
	{
		const auto Tag = GetSwarmCapabilityTag(InState); 
		VictimComp.ClaimPlayer(VictimComp.CurrentVictim, Tag, MaxAllowed);
	}

	void UnclaimVictim(ESwarmBehaviourState InState)
	{
		const auto Tag = GetSwarmCapabilityTag(InState); 
		VictimComp.UnclaimVictim(Tag);
	}

	void UnclaimBothPlayers(ESwarmBehaviourState InState)
	{
		const auto Tag = GetSwarmCapabilityTag(InState); 
		VictimComp.UnclaimBothPlayers(Tag);
	}

	bool IsOtherVictimClaimable(ESwarmBehaviourState InState) const
	{
		return IsClaimable(InState, VictimComp.CurrentVictim.OtherPlayer);
	}

	bool IsVictimClaimable(ESwarmBehaviourState InState) const
	{
		return IsClaimable(InState, VictimComp.CurrentVictim);
	}

	bool IsClaimable(ESwarmBehaviourState InState, AHazePlayerCharacter InPlayer) const
	{
		const auto Tag = GetSwarmCapabilityTag(InState); 
		return VictimComp.IsClaimable(Tag, InPlayer);
	}

	bool IsClaimingVictim(ESwarmBehaviourState InState) const
	{
		const auto Tag = GetSwarmCapabilityTag(InState); 
		return VictimComp.IsClaiming(Tag, VictimComp.CurrentVictim);
	}

	bool AreVFXParticlesRequested() const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if(SwarmSkelMeshes[i].ExtraVFXParticles.Num() != 0)
			{
				return true;
			}
		}
		return false;
	}

	bool AreParticleMarkedForDeath() const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if(SwarmSkelMeshes[i].ParticleindicesMarkedForDeath.Num() != 0)
			{
				return true;
			}
		}
		return false;
	}

	FBox GetTowardsVictimBox()
	{
		FBox AccumulatedSkelMeshBoxes = SkelMeshComp.GetSwarmParticleBox();
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if(SwarmSkelMeshes[i] == SkelMeshComp)
				continue;

			AccumulatedSkelMeshBoxes += SwarmSkelMeshes[i].GetSwarmParticleBox();
		}

		if(VictimComp.CurrentVictim != nullptr)
			AccumulatedSkelMeshBoxes += VictimComp.CurrentVictim.GetActorLocation();

		return AccumulatedSkelMeshBoxes;
	}

	void StopSwarmAudio()
	{
		HazeAkComp.HazePostEvent(StopFlyingEvent);
	}

	bool IsSwarmIntersectingSphere(FVector InSphereLocation, float InSphereRadius) const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			if(SwarmSkelMeshes[i].AreParticlesIntersectingSphere(InSphereLocation, InSphereRadius))
			{
				return true;
			}
		}
		return false;
	}

	bool FindPlayersIntersectingSwarmBounds(TArray<AHazePlayerCharacter>& OutOverlappedPlayers) const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
			SwarmSkelMeshes[i].FindPlayersIntersectingMeshBounds(OutOverlappedPlayers);
		return OutOverlappedPlayers.Num() > 0;
	}

	bool FindPlayersIntersectingSwarmBones(TArray<AHazePlayerCharacter>& OutOverlappedPlayers) const
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
			SwarmSkelMeshes[i].FindPlayersIntersectingMeshBones(OutOverlappedPlayers);
		return OutOverlappedPlayers.Num() > 0;
	}

	// Applied to all particles within radius
	UFUNCTION(BlueprintCallable)
	void AddForceFieldAcceleration( const FVector& Origin, const FSwarmForceField& ForceField)
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].AddForceFieldAcceleration(Origin, ForceField);
		}
	}

	// Applied to all particles within radius
	UFUNCTION(BlueprintCallable)
	void AddForceFieldVelocity(const FVector& Origin, const FSwarmForceField& ForceField)
	{
		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].AddForceFieldVelocity(Origin, ForceField);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetInvulnerabilityFlag(bool bNewRevival)
	{
		bInvulnerable = bNewRevival;

		// the array gets populated on beginplay. We are calling this function to early
		ensure(SwarmSkelMeshes.Num() != 0);

		for (int i = 0; i < SwarmSkelMeshes.Num(); i++)
		{
			SwarmSkelMeshes[i].bInvulnerable = bNewRevival;
		}
	}

}

// Used to handle sap and Match intersections 
struct FSwarmIntersectionData
{
	TMap<USwarmSkeletalMeshComponent, FMeshIntersectionData> MeshIntersectionDataMap;
};


