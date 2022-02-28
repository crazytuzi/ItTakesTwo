import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourSettingsContainer;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Actors.KeepInViewCameraActor;

event void FPerformingHammerUltimate();
event void FSwarmSpawned(ASwarmActor Swarm);

UCLASS(abstract, HideCategories = "Rendering Collision Debug Actor Replication Input Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation Mobile MeshOffset Activation LOD")
class ASwarmHammerManager : AHazeActor
{
	// Settings
	float SharedGentlemanDistanceThreshold = 2500.f;
	float HammerUltimateTimeThreshold = 48.f;
	float TimeBetweenSwarmSpawning = 0.6f;
	int MaxSwarmsActive = 2;

	default SetActorHiddenInGame(true);

	UPROPERTY()
	UFoghornVOBankDataAssetBase FoghornBank;

	UPROPERTY()
	TPerPlayer<AKeepInViewCameraActor> Cameras;

	FHazeFocusTarget SelfFocusTarget = FHazeFocusTarget();
	default SelfFocusTarget.Actor = this;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DebugMesh;
	default DebugMesh.StaticMesh = Asset("/Engine/BasicShapes/Sphere");
	default DebugMesh.SetCollisionProfileName(n"NoCollision");
	default DebugMesh.SetGenerateOverlapEvents(false);
	default DebugMesh.SetComponentTickEnabled(false);
	default DebugMesh.SetHiddenInGame(false);

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FPerformingHammerUltimate OnHammerUltimateStarted;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FPerformingHammerUltimate OnHammerUltimateEnded;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FSwarmSpawned OnSwarmSpawned;

	UPROPERTY(Category = "Team")
	ASwarmActor StartHammerSwarmRef;

	UPROPERTY(Category = "Team")
	TSubclassOf<ASwarmActor> HammerSwarmToSpawn;

	UPROPERTY(Category = "Movement")
	AActor FastEntrySpline;

	UPROPERTY(Category = "Movement")
	AActor SlowEntrySpline;

	UPROPERTY(Category = "Movement")
	AActor GentlemanSpline;

	UPROPERTY(Category = "Movement")
	AActor ArenaSpline;

	UPROPERTY(Category = "Movement")
	AActor HammerUltimateTargetPoint;

	UPROPERTY(Category = "Behaviour|Default")
	UHazeCapabilitySheet DefaultMonoSheet;

	UPROPERTY(Category = "Behaviour|Default")
	USwarmBehaviourBaseSettings DefaultMonoSettings;

	UPROPERTY(Category = "Behaviour|Default")
	UHazeCapabilitySheet DefaultDuoSheet;

	UPROPERTY(Category = "Behaviour|Default")
	USwarmBehaviourBaseSettings DefaultDuoSettings;

	UPROPERTY(Category = "Behaviour|Intro")
	UHazeCapabilitySheet IntroSheet;

	UPROPERTY(Category = "Behaviour|Intro")
	USwarmBehaviourBaseSettings IntroSettings;

	UPROPERTY(Category = "Behaviour|Ultimate")
	UHazeCapabilitySheet UltimateSheet;

	UPROPERTY(Category = "Behaviour|Ultimate")
	USwarmBehaviourBaseSettings UltimateSettings;

	ASwarmActor SwarmThatWillTriggerUltimate = nullptr;
	FTimerHandle SwarmUltiTimerHandle;

	UPROPERTY(BlueprintReadOnly, Category = "Ultimate Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsUltimate = nullptr;

	int32 SpawnedSwarmCounter = 0;
	float TimeStampSpawnSwarm = -TimeBetweenSwarmSpawning;

	// when the countdown started
	float TimeStampHammerUltimateCountdown = 0.f;

	bool bStopSpawning = true;

	TArray<ASwarmActor> Swarms;
	default Swarms.SetNum(MaxSwarmsActive);

	ASwarmActor SlaveSwarm;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Swarm, match, sap all have may as control side
		SetControlSide(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(const float Dt)
	{
		//UpdateSharedGentlemaning();

		// process unpaused swarm spawning if needed. (it is otherwise handled when swarm dies)
		if(HasControl() && ShouldSpawnSwarm())
			NetSpawnAndRecruitSwarm();
	}

	UFUNCTION()
	void ReleaseSwarmOnIntroSpline(ASwarmActor InSwarm)
	{
		InSwarm.MovementComp.ArenaMiddleActor = this;
		ApplyBehaviour_Intro(InSwarm);
		InSwarm.OnReachedEndOfSpline.AddUFunction(this, n"HandleReachedEndOfSpline");
		TimeStampSpawnSwarm = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void HandleReachedEndOfSpline(ASwarmActor InSwarm)
	{
		if (!HasControl())
			return;

		InSwarm.OnReachedEndOfSpline.Unbind(this, n"HandleReachedEndOfSpline");

		// Start the countdown to Ultimate once the first swarm starts attacking the players
		if(TimeStampHammerUltimateCountdown == 0.f)
			TimeStampHammerUltimateCountdown = Time::GetGameTimeSeconds();

		// const float TimeUntilUltimate = Time::GetGameTimeSince(TimeStampHammerUltimateCountdown);
		// if (TimeUntilUltimate >= HammerUltimateTimeThreshold)
		if(SwarmThatWillTriggerUltimate != nullptr && SwarmThatWillTriggerUltimate == InSwarm)
		{
			NetApplyBehaviour_Ultimate();
		}
		else if (GetNumSwarmsActive() <= 1)
		{
			NetApplyBehaviour_Attack_Mono(InSwarm);
		}
		else if (GetNumSwarmsActive() == 2)
		{
			NetApplyBehaviour_Attack_Duo(InSwarm);
		}
		else 
		{
			// what did we miss
			ensure(false);
		}
	}

	UFUNCTION()
	void HandleSwarmDeath(ASwarmActor InSwarm)
	{
		// needs to be renetworked due to different actor channels
		if (!HasControl())
			return;

		NetHandleSwarmRemoval(InSwarm);

		// sync because timers might be off due to this function being networked
		const float TimeUntilUltimate = Time::GetGameTimeSince(TimeStampHammerUltimateCountdown);
		if (TimeUntilUltimate >= HammerUltimateTimeThreshold)
		{
			NetSpawnSwarmThatWillTriggerUltimate();
		}
		else if(ShouldSpawnSwarm())
		{
			// release 1 swarm
			NetSpawnAndRecruitSwarm();
		}
	}

	UFUNCTION(NetFunction)
	void NetHandleSwarmRemoval(ASwarmActor InSwarm)
	{
		if (InSwarm == SwarmThatWillTriggerUltimate)
		{
			// shouldn't happen because the ulti-swarm is invulnerable
			ensure(false);
			SwarmThatWillTriggerUltimate = nullptr;
		}

		// They say; We got one! Yees!
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmKill");

		InSwarm.OnAboutToDie.Unbind(this, n"HandleSwarmDeath");
		RemoveSwarm(InSwarm);

		// flag that we are allowed to spawn automatically now that
		// the first swarm is dead. (this is also flipped in SwarmHammerRecoverCapability)
		bStopSpawning = false;
	}

	UFUNCTION(NetFunction)
	void NetSpawnSwarmThatWillTriggerUltimate()
	{
//		Print("Spawning Swarm that will trigger Ultimate!");
		ASwarmActor NewSwarm = SpawnAndRecruitSwarm();
		
		if(SwarmThatWillTriggerUltimate == nullptr)
			SwarmThatWillTriggerUltimate = NewSwarm;

		// release max swarms
		SwarmUltiTimerHandle = System::SetTimer(this, n"SpawnSwarmsForUltimateLoop", 0.4f, true);

		// prevent the normal timer from spawning 
		bStopSpawning = true;
	}

	UFUNCTION()
	void SpawnSwarmsForUltimateLoop()
	{
		if (HasControl() && GetNumSwarmsActive() < MaxSwarmsActive)
		{
//			Print("Spawing HAMMER UTLI");
			NetSpawnAndRecruitSwarm();
		}

		if (GetNumSwarmsActive() == MaxSwarmsActive)
		{
			System::ClearAndInvalidateTimerHandle(SwarmUltiTimerHandle);
		}
	}

	bool bStartHammerUltimateDoOnce = false;

	void HandleHammerUltimateStarted()
	{
		if(bStartHammerUltimateDoOnce)
			return;

		bStartHammerUltimateDoOnce = true;

		System::ClearAndInvalidateTimerHandle(SwarmUltiTimerHandle);

		// reset the timer to make sure other swarms don't redo redo ulti
		TimeStampHammerUltimateCountdown = Time::GetGameTimeSeconds();

		// Hammer ulti should be immortal, so this is OK
		bStopSpawning = true;

		OnHammerUltimateStarted.Broadcast();
	}

	UFUNCTION()
	void EndHammerUltimate(ASwarmActor InSwarm)
	{
		// unbind everyone. We are only interested in the first one
		for(ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			SwarmIter.OnUltimatePerformed.Unbind(this, n"EndHammerUltimate");
			SwarmIter.OnAboutToDie.Unbind(this, n"HandleSwarmDeath");
		}

		// BP will pick this up and shatter the ground
		OnHammerUltimateEnded.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetApplyBehaviour_Ultimate()
	{
		for(ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			SwarmIter.OnUltimatePerformed.AddUFunction(this, n"EndHammerUltimate");

			SwarmIter.SwitchBehaviourSettings(UltimateSettings);
			SwarmIter.SwitchBehaviour(UltimateSheet);

			// set-piece, can't die. 
			SwarmIter.SetInvulnerabilityFlag(true);

			// make sure that the extra swarms don't somehow 
			// enter HandleReachedEndOfSpline() after ulti has been started
			SwarmIter.OnReachedEndOfSpline.Unbind(this, n"HandleReachedEndOfSpline");
		}
	}

	// 0 == slow spline, 1 == fast spline
	int SplineChoice = 0;

	UFUNCTION()
	void ApplyBehaviour_Intro(ASwarmActor InSwarm)
	{
		AActor EntrySpline = SplineChoice % 2 == 0 
		? FastEntrySpline 
		: SlowEntrySpline;

		// PrintToScreen("" + InSwarm.GetName() + " | " + EntrySpline.GetName() + " | " + SplineChoice%2, Duration = 5.f);

		++SplineChoice;

		InSwarm.SwitchTo(IntroSheet, IntroSettings, EntrySpline);
	}

	// when we only have 1 swarm
	UFUNCTION(NetFunction)
	void NetApplyBehaviour_Attack_Mono(ASwarmActor InSwarm)
	{
		InSwarm.SwitchTo(DefaultMonoSheet, DefaultMonoSettings, ArenaSpline);

		InSwarm.OverrideBehaviourState(ESwarmBehaviourState::PursueMiddle);

		InSwarm.SetInvulnerabilityFlag(false);

		// They say; Wait is that.. A hammer? IT'S A HAMMER
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmHammer");
	}

	// when we have 2 swarms active
	UFUNCTION(NetFunction)
	void NetApplyBehaviour_Attack_Duo(ASwarmActor InSwarm)
	{
		InSwarm.SwitchTo(DefaultDuoSheet, DefaultDuoSettings, GentlemanSpline);

		InSwarm.OverrideBehaviourState(ESwarmBehaviourState::PursueMiddle);

		InSwarm.SetInvulnerabilityFlag(false);

		// overwrite any existing mono settings with duo
		// (this should generally only happen once, after the intro swarm has called for help)
		for(ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			if(SwarmIter.BehaviourComp.CurrentBehaviourSettings != DefaultMonoSettings)
				continue;

			SwarmIter.SwitchTo(DefaultDuoSheet, DefaultDuoSettings, GentlemanSpline);
		}

		// They say; Wait is that.. A hammer? IT'S A HAMMER
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmHammer");
	}

	UFUNCTION(NetFunction)
	void NetSpawnAndRecruitSwarm()
	{
		SpawnAndRecruitSwarm();
	}

	UFUNCTION(NetFunction)
	void NetCallForSwarmBackup()
	{
		CallForSwarmBackup();
	}

	// the first swarm goes into the air and calls for backup
	// (this happens when player is taking waaay to long to kill the first swarm)
	void CallForSwarmBackup()
	{
		bStopSpawning = false;
		if(ShouldSpawnSwarm())
		{
			SpawnAndRecruitSwarm();
		}
	}

	ASwarmActor SpawnAndRecruitSwarm()
	{
//		Print("Spawning and recruiting swarm");
		ensure(HammerSwarmToSpawn.IsValid());

		FVector StartLocation; FRotator StartRotation;
		GetSpawnLocationAndRotation(StartLocation, StartRotation);

		AActor SpawnedActor = SpawnActor(
			HammerSwarmToSpawn.Get(),
			StartLocation,
			StartRotation,
			bDeferredSpawn = true,
			Level = this.Level
		);

		ASwarmActor Swarm = Cast<ASwarmActor>(SpawnedActor);

		Swarm.MakeNetworked(this, SpawnedSwarmCounter++);

		RecruitSwarm(Swarm);

		FinishSpawningActor(Swarm);

		OnSwarmSpawned.Broadcast(Swarm);
		ReleaseSwarmOnIntroSpline(Swarm);

		Swarm.SetInvulnerabilityFlag(true);

		// They say; oh no it's never ending
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmRevive");

		return Swarm;
	}

	UFUNCTION()
	void RecruitSwarm(ASwarmActor InSwarm)
	{
		AddSwarm(InSwarm);

		// if(ShouldUseSharedGentleman())
		// 	InSwarm.VictimComp.ActivateSharedGentlemanBehaviour();
	}

	void AddSwarm(ASwarmActor InSwarm)
	{

#if TEST
		// ensure that we have a vacant spot open
		TArray<ASwarmActor> CleanedArray = Swarms;
		CleanedArray.RemoveAll(nullptr);
		ensure(CleanedArray.Num() != Swarms.Num());
#endif

		// occupy vacant slots 
		for(int i = 0; i < Swarms.Num(); ++i)
		{
			if(Swarms[i] == nullptr)
			{
				Swarms[i] = InSwarm;
				break;
			}
		}

		InSwarm.OnAboutToDie.AddUFunction(this, n"HandleSwarmDeath");
		InSwarm.OnSapExplosion.AddUFunction(this, n"HandleSapExplosion");
	}

	void RemoveSwarm(ASwarmActor InSwarm)
	{
		const auto Idx = Swarms.FindIndex(InSwarm);

		if(Idx == -1)
		{
			// they should always be in the array.. 
			// was the request deferred somehow?
			ensure(false);
			return;
		}

		InSwarm.OnSapExplosion.Unbind(this, n"HandleSapExplosion");

		if(InSwarm == SlaveSwarm)
			SlaveSwarm = nullptr;

		Swarms[Idx] = nullptr;
	}

	float Timestamp_PlayFoghorn_SapExplosion = 0.f;

	UFUNCTION()
	void HandleSapExplosion(FVector WorldLocation) 
	{
		const float TimeSinceLastVO = Time::GetGameTimeSince(Timestamp_PlayFoghorn_SapExplosion);

		// PlayFoghorn, down below, sends netmessages so we have to limit it.
		if(TimeSinceLastVO < 1.f)
			return;
		
		Timestamp_PlayFoghorn_SapExplosion = Time::GetGameTimeSeconds();

		// Sap Sapexplosion
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmDamage");

		// Sap Sapexplosion (cody)
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmDamageGenericCody", Game::Cody);

		// Sap Sapexplosion (may)
		PlayFoghornVOBankEvent(FoghornBank, n"FoghornDBTreeWaspNestSwarmDamageGenericMay", Game::May);
	}

	void GetSpawnLocationAndRotation(FVector& OutLocation, FRotator& OutRotator) const
	{
		if(FastEntrySpline != nullptr)
		{
			OutLocation = FastEntrySpline.GetActorLocation();
			OutRotator = FastEntrySpline.GetActorRotation();
		}
		else if(SlowEntrySpline != nullptr)
		{
			OutLocation = SlowEntrySpline.GetActorLocation();
			OutRotator = SlowEntrySpline.GetActorRotation();
		}
	}

	bool ShouldSpawnSwarm() const
	{
		// we don't allow spawning during ulti or during intro swarm 
		if(bStopSpawning)
			return false;

		const float TimeSinceSwarmSpawned = Time::GetGameTimeSince(TimeStampSpawnSwarm);
		if(TimeSinceSwarmSpawned < TimeBetweenSwarmSpawning)
			return false;

		return GetNumSwarmsActive() < MaxSwarmsActive;
	}

	int GetNumSwarmsActive() const property 
	{
		int NumSwarms = 0;
		for(int i = 0; i < Swarms.Num(); ++i)
		{
			if(Swarms[i] == nullptr)
				continue;

			++NumSwarms;
		}

		return NumSwarms;
	}

	bool ShouldUseSharedGentleman() const
	{
		if(NumSwarmsActive <= 1)
			return false;

		// deactivate when someone dies
		auto HealthCompCody = UPlayerHealthComponent::Get(Game::GetCody()); 
		if(HealthCompCody.bIsDead)
			return false;

		auto HealthCompMay = UPlayerHealthComponent::Get(Game::GetMay()); 
		if(HealthCompMay.bIsDead)
			return false;

		const float DistSQ = Game::GetDistanceSquaredBetweenPlayers();
		// PrintToScreen("DistBetweenPlayers: " + FMath::Sqrt(DistSQ));
		if(DistSQ <= FMath::Square(SharedGentlemanDistanceThreshold))
		{
			const FBox SwarmBox_1 = Swarms[0].GetTowardsVictimBox();
			const FBox SwarmBox_2 = Swarms[1].GetTowardsVictimBox();
			const bool bIntersecting = SwarmBox_1.Intersect(SwarmBox_2);

			// System::DrawDebugBox(
			// 	SwarmBox_1.Center,
			// 	SwarmBox_1.Extent,
			// 	bIntersecting ? FLinearColor::Red : FLinearColor::Green
			// 	// ,Swarms[0].GetActorRotation()
			// );
			// System::DrawDebugBox(
			// 	SwarmBox_2.Center,
			// 	SwarmBox_2.Extent,
			// 	bIntersecting ? FLinearColor::Red : FLinearColor::Green
			// 	// ,Swarms[1].GetActorRotation()
			// );

			return bIntersecting;
			// return true;
		}

		return false;
	}

	void UpdateSharedGentlemaning()
	{
		if(ShouldUseSharedGentleman())
			ActivateSharedGentlemanFighting();
		else
			DeactivateSharedGentlemanFighting();
	}

	void ActivateSharedGentlemanFighting()
	{
//		System::DrawDebugLine(
//			Game::GetMay().GetActorCenterLocation(),
//			Game::GetCody().GetActorCenterLocation(),
//			FLinearColor::Red,
//			0.f,
//			5.f
//		);

		for(ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			if(SwarmIter.VictimComp.IsUsingSharedGentlemanBehaviour())
				continue;

			SwarmIter.VictimComp.ResetGentlemanBehaviour();
//			Print(SwarmIter.GetName() + ": Clearing Claimaints for ALL");

			// SwarmIter.VictimComp.ClearClaimsForPlayer(Game::GetCody());
			// Print(SwarmIter.GetName() + ": Clearing Claimaints for Cody");

			SwarmIter.VictimComp.ActivateSharedGentlemanBehaviour();
		}
	}

	void DeactivateSharedGentlemanFighting()
	{
//		System::DrawDebugLine(
//			Game::GetMay().GetActorCenterLocation(),
//			Game::GetCody().GetActorCenterLocation(),
//			FLinearColor::Green,
//			0.f,
//			5.f
//		);

		for(ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			if(!SwarmIter.VictimComp.IsUsingSharedGentlemanBehaviour())
				continue;

			SwarmIter.VictimComp.ResetGentlemanBehaviour();
//			Print(SwarmIter.GetName() + ": Clearing Claimaints for ALL");
			// SwarmIter.VictimComp.ClearClaimsForOtherVictim();
			// Print(SwarmIter.GetName() + ": Clearing Claimaints for Victim");

			SwarmIter.VictimComp.DeactivateSharedGentlemanBehaviour();

		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		for(ASwarmActor SwarmIter : Swarms)
		{
			if(SwarmIter == nullptr)
				continue;

			SwarmIter.DisableActor(this);
		}

		return false;
	}

	ASwarmActor GetOtherSwarm(ASwarmActor InSwarm) const
	{

		// assuming there are max 2
		ensure(Swarms.Num() == 2);

		ASwarmActor OtherSwarm = nullptr;
		for(ASwarmActor IterSwarm : Swarms)
		{
			// there is only 1 swarm
			if(IterSwarm == nullptr)
				break;

			if(IterSwarm == InSwarm)
				continue;

			OtherSwarm = IterSwarm;
		}

		return OtherSwarm;
	}

	void ClearKeepInView(AHazePlayerCharacter InPlayer)
	{
		InPlayer.ClearCameraSettingsByInstigator(this);
		InPlayer.ClearFieldOfViewByInstigator(this);
		InPlayer.ClearCameraOffsetByInstigator(this);
		InPlayer.ClearPivotOffsetByInstigator(this);
		InPlayer.ClearPointOfInterestByInstigator(this);
		InPlayer.SetShowLetterbox(false);
	}

	void ApplyKeepInView(AHazePlayerCharacter InPlayer)
	{
		const FVector Delta = GetActorLocation() - InPlayer.GetActorLocation();
		const FRotator ToManagerRot = FRotator::MakeFromX(Delta);

		FRotator FinalRotation = ToManagerRot;
		// FRotator FinalRotation = InPlayer.ViewRotation;
		FinalRotation.Pitch = -35.f;

		Cameras[InPlayer.Player].SetActorRotation(FinalRotation);

		FHazeFocusTarget PlayerFocusTarget = FHazeFocusTarget();
		PlayerFocusTarget.Actor = InPlayer;
		PlayerFocusTarget.ViewOffset = FVector(0.f, 0.f, 200.f);

		Cameras[InPlayer.Player].KeepInViewComponent.AddTarget(SelfFocusTarget);
		Cameras[InPlayer.Player].KeepInViewComponent.AddTarget(PlayerFocusTarget);

		FHazeCameraKeepInViewSettings KeepInViewSettings;
		KeepInViewSettings.bUseMinDistance = true;
		KeepInViewSettings.MinDistance = 1200.f;
		KeepInViewSettings.bUseBufferDistance = true;
		KeepInViewSettings.BufferDistance = 1000.f;

		InPlayer.ApplyCameraKeepInViewSettings(KeepInViewSettings, CameraBlend::Normal(4.f), this);

		// Cameras[InPlayer.Player].ActivateCamera(
		// 	InPlayer,
		// 	CameraBlend::Normal(4.f),
		//  	this,
		// 	EHazeCameraPriority::Script
		// );

		// InPlayer.DeactivateCameraByInstigator(this);

		// CameraKeepInViews[InPlayer.Player].SetWorldRotation(FinalRotation);

		// const float BlendTime = 4.f;
		// InPlayer.ActivateCamera(
		// 	Cameras[InPlayer.Player],
		// 	CameraBlend::Normal(BlendTime),
		//  	this,
		// 	EHazeCameraPriority::Script
		// );

		auto Blend = CameraBlend::Normal(4.f);

		FHazePointOfInterest POI;
		POI.Blend = CameraBlend::Normal(4.f);
		POI.FocusTarget.Actor = this;
		POI.FocusTarget.WorldOffset = FVector(0.f, 0.f, -1200.f);
		// POI.FocusTarget.ViewOffset = FVector(0.f, 0.f, -1200.f);
		InPlayer.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);
		InPlayer.ApplyPivotOffset(FVector(0.f, 0.f, 250.f), Blend, this, EHazeCameraPriority::Script);
		// InPlayer.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 250.f), Blend, this, EHazeCameraPriority::Script);
		InPlayer.ApplyCameraOffset(FVector(0.f, 0.f, 150.f), Blend, this, EHazeCameraPriority::Script);
		InPlayer.ApplyFieldOfView(90.f, Blend, this);

		InPlayer.SetShowLetterbox(true);
	}


}