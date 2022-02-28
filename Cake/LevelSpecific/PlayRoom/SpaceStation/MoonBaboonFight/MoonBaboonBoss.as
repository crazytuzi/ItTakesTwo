import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonLaserPointer;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocketImpactComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonLaserSpinner;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocket;
import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineActor;
import Vino.Audio.AudioActors.HazeAmbientSound;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonLaserCircle;
import Peanuts.Health.BossHealthBarWidget;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonLaserBomb;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonInUFO;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

event void FMoonBaboonEvent();

class AMoonBaboonBoss : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase UFOSkelMesh;

	UPROPERTY(DefaultComponent, Attach = UFOSkelMesh, AttachSocket = Base)
	UBoxComponent EnterUFOTrigger;

	UPROPERTY(DefaultComponent, Attach = UFOSkelMesh, AttachSocket = Base)
	USceneComponent EnterUFOJumpToPoint;

	UPROPERTY(DefaultComponent, Attach = UFOSkelMesh, AttachSocket = LaserGunRing3)
	UArrowComponent LaserPointerNozzle;

	UPROPERTY(DefaultComponent, Attach = UFOSkelMesh, AttachSocket = Base)
	UNiagaraComponent HoverEffectComp;

	UPROPERTY(DefaultComponent, Attach = LaserPointerNozzle)
	UNiagaraComponent LaserChargeEffect;

	UPROPERTY(DefaultComponent)
	USpaceRocketImpactComponent RocketImpactComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent GrabInteraction;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent RemoveLaserGunInteraction;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LiftSyncComp;

	UPROPERTY(Category = "Level Actors")
	AMoonBaboonInUfo MoonBaboon;

	UPROPERTY(Category = "Level Actors")
	ASplineActor SplineActor;
	UHazeSplineComponentBase SplineToFollow;
	float CurrentSplineDistance;

	UPROPERTY(NotEditable)
	float OffsetFromGround = 1115.f;

	TArray<AActor> ActorsToIgnore;
	
	UPROPERTY()
	EMoonBaboonAttackMode CurrentAttackMode;

	UPROPERTY()
	FMoonBaboonEvent OnRocketPhaseCompleted;
	
	UPROPERTY()
	FMoonBaboonEvent OnCodyEnteredUFO;

	UPROPERTY()
	FMoonBaboonEvent OnLaserGunRippedOff;

	UPROPERTY(Category = "Level Actors")
	AMoonBaboonLaserPointer LaserPointer;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMoonBaboonLaserCircle> SlamCircleClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMoonBaboonLaserBomb> LaserBombClass;
	TArray<AMoonBaboonLaserBomb> LaserBombPool;
	FTimerHandle LaserBombTimerHandle;
	AHazePlayerCharacter LastBombPlayer;
	float BombDelay = 1.75f;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SlamCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SlamForceFeedback;

	UPROPERTY(NotVisible)
	bool bRocketPhaseCompleted = false;

	UPROPERTY(NotVisible)
	int CurRocketHits;
	UPROPERTY()
	int RocketHitsNeeded = 5;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MediumLiftAnimation;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence SmallLiftAnimation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBarWidget;
	float CurrentHealth = 1.f;

	bool bLifted = false;

	UPROPERTY(Category = "Level Actors")
	AMoonBaboonLaserSpinner LaserSpinner;

	UPROPERTY(Category = "Level Actors")
	ASpaceRocket MayRocket;
	UPROPERTY(Category = "Level Actors")
	ASpaceRocket CodyRocket;
	TArray<ASpaceRocket> Rockets;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(NotVisible)
	FHazeAudioEventInstance StartUFOLoopingEventInstance;

	UPROPERTY(NotVisible)
	FHazeAudioEventInstance BrokenUfOLoopingEventInstance;
	UPROPERTY(NotVisible)
	FHazeAudioEventInstance UfoBrokenAlarmEventInstance;

	UPROPERTY(Category = "Audio Events UFO Engine")
	UAkAudioEvent StartUFOLoopingEvent;

	UPROPERTY(Category = "Audio Events UFO Engine")
	UAkAudioEvent StopUFOLoopingEvent;		

	UPROPERTY(Category = "Audio Events UFO Rocket")
	UAkAudioEvent StartRocketLoopingEvent;

	UPROPERTY(Category = "Audio Events UFO Rocket")
	UAkAudioEvent StopRocketLoopingEvent;

	UPROPERTY(Category = "Audio Events UFO Rocket")
	UAkAudioEvent MoonBaboonRocketImpactEvent;

	UPROPERTY(Category = "Audio Events UFO Slam")
	UAkAudioEvent UfoSlamBoostStartEvent;

	UPROPERTY(Category = "Audio Events UFO Slam")
	UAkAudioEvent UfoGroundSlamStartEvent;

	UPROPERTY(Category = "Audio Events UFO Slam")
	UAkAudioEvent UfoGroundSlamImpactSweetenerEvent;

	UPROPERTY(Category = "Audio Events UFO Rocket")
	UAkAudioEvent UFoHitByRocketEvent;

	UPROPERTY(Category = "Audio Events UFO Engine")
	UAkAudioEvent UfoBrokenEvent;

	UPROPERTY(Category = "Audio Events UFO Alarm")
	UAkAudioEvent UfoBrokenAlarmEvent;

	UPROPERTY(Category = "Level Actors")
	AHazeAmbientSound SweepingAlarmAmbientSound;

	UPROPERTY(Category = "Level Actors")
	AHazeAmbientSound AggressiveAlarmAmbientSound;

	UPROPERTY(Category = "Level Actors")
	AHazeAmbientSound InsideUFOSweepingAlarmAmbientSound;

	UPROPERTY(Category = "Level Actors")
	AHazeAmbientSound InsideUFOHighAlarmAmbientSound;

	UPROPERTY(Category = "Level Actors")
	AHazeAmbientSound InsideUFOMediumAlarmAmbientSound;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;
	
	float LastElevationDelta;
	float LastElevation;
	float LastRotationDelta;
	float LastVelocityDelta;
	
	FTimerHandle SlamTimer;

	bool bCodyEnteredUfo = false;

	bool bAllowSlamming = true;
	bool bFollowPlayerForSlam = false;
	bool bSlamming = false;

	AHazePlayerCharacter PlayerToLookAt;

	UPROPERTY(NotEditable)
	FVector LaserImpactLocation;
	bool bLaserActive = false;

	int PowerCoresDestroyed = 0;
	bool bAllPowerCoresDestroyed = false;

	bool bBossStunned = false;

	float DelayBetweenSlams = 4.5f;

	UPROPERTY()
	AHazeActor FloorActor;

	FTimerHandle LaserPointerTauntTimerHandle;
	float LaserPointerTauntDelay = 5.f;

	float RocketProximityBarkDistance = 3000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		MoonBaboon.AttachToComponent(UFOSkelMesh, n"Base");

		OffsetFromGround = 1115.51001f + 26.f;

		if (LaserPointer != nullptr)
			LaserPointer.AttachToComponent(LaserPointerNozzle, AttachmentRule = EAttachmentRule::SnapToTarget);

		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());

		SplineToFollow = SplineActor.Spline;

		LiftSyncComp.OverrideControlSide(Game::GetCody());

		GrabInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
		GrabInteraction.OnActivated.AddUFunction(this, n"OnGrabInteractionActivated");

		RemoveLaserGunInteraction.SetExclusiveForPlayer(EHazePlayer::May);
		RemoveLaserGunInteraction.OnActivated.AddUFunction(this, n"OnRemoveLaserGunInteractionActivated");

		EnterUFOTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterUFO");

		RocketImpactComp.OnHitByRocket.AddUFunction(this, n"HitByRocket");

		MayRocket.OnSpaceRocketExploded.AddUFunction(this, n"PrepareNewMayMissile");
		CodyRocket.OnSpaceRocketExploded.AddUFunction(this, n"PrepareNewCodyMissile");

		ChangeSizeCallbackComp.OnCharacterChangedSize.AddUFunction(this, n"CodyChangedSize");

		if(StartUFOLoopingEvent != nullptr)
		{
			StartUFOLoopingEventInstance = HazeAkComp.HazePostEvent(StartUFOLoopingEvent);
		}

		AddCapability(n"MoonBaboonSlamFollowCapability");
		AddCapability(n"MoonBaboonSlamCapability");

		AttachToFloor();

		Rockets.Add(MayRocket);
		Rockets.Add(CodyRocket);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.EnableOutlineByInstigator(this);
	}

	UFUNCTION()
	void DisablePlayerOutlines()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.DisableOutlineByInstigator(this);
	}

	UFUNCTION()
	void StartLookingAtPlayer(AHazePlayerCharacter Player)
	{
		PlayerToLookAt = Player;
	}

	UFUNCTION()
	void StopLookingAtPlayer()
	{
		PlayerToLookAt = nullptr;
	}

	UFUNCTION()
	void BindPlayerDeathAndRespawnEvents()
	{
		FOnPlayerDied PlayerDiedDelegate;
		PlayerDiedDelegate.BindUFunction(this, n"PlayerDied");
		BindOnPlayerDiedEvent(PlayerDiedDelegate);
		
		FOnRespawnTriggered RespawnDelegate;
		RespawnDelegate.BindUFunction(this, n"PlayerRespawned");
		BindOnPlayerRespawnedEvent(RespawnDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerDied(AHazePlayerCharacter Player)
	{
		if (CurrentAttackMode == EMoonBaboonAttackMode::LaserPointer)
		{
			SetCapabilityActionState(n"FoghornLaserPointerKillTaunt", EHazeActionState::ActiveForOneFrame);
			LaserPointer.IgnorePlayer(Player);
		}
		else if (CurrentAttackMode == EMoonBaboonAttackMode::Slam)
		{
			if (!Player.IsMay())
				return;

			SetCapabilityActionState(n"FoghornSlamLaserKillTaunt", EHazeActionState::ActiveForOneFrame);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		if (CurrentAttackMode == EMoonBaboonAttackMode::LaserPointer)
		{
			SetCapabilityActionState(n"FoghornLaserPointerRespawnTaunt", EHazeActionState::ActiveForOneFrame);
			LaserPointer.UnignorePlayer(Player);
		}
		else if (CurrentAttackMode == EMoonBaboonAttackMode::Slam)
		{
			if (!Player.IsMay())
				return;

			SetCapabilityActionState(n"FoghornSlamLaserRespawnTaunt", EHazeActionState::ActiveForOneFrame);
		}
		else if (CurrentAttackMode == EMoonBaboonAttackMode::Rockets)
		{
			if (Player.IsMay())
				SpawnMayMissile();
			else
				SpawnCodyMissile();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void CodyChangedSize(FChangeSizeEventTempFix Size)
	{
		if (Size.NewSize == ECharacterSize::Small)
		{
			TArray<AActor> Actors;
			EnterUFOTrigger.GetOverlappingActors(Actors, AHazePlayerCharacter::StaticClass());
			for (AActor CurActor : Actors)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurActor);
				if (Player != nullptr && !bCodyEnteredUfo && bRocketPhaseCompleted && Player == Game::GetCody() && Player.HasControl())
				{
					NetCodyEnteredUFO();
					return;
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterUFO(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && !bCodyEnteredUfo && bRocketPhaseCompleted && Player == Game::GetCody() && Player.HasControl())
		{
			UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
			if (ChangeSizeComp != nullptr && ChangeSizeComp.CurrentSize == ECharacterSize::Small)
				NetCodyEnteredUFO();
		}	
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetCodyEnteredUFO()
	{
		bCodyEnteredUfo = true;
		FHazeJumpToData JumpToData;
		JumpToData.TargetComponent = EnterUFOJumpToPoint;
		JumpToData.AdditionalHeight = 25.f;
		JumpToData.SmoothTeleportRange = 0.f;
		FHazeDestinationEvents Events;
		Events.OnDestinationReached.BindUFunction(this, n"EnterUFOJumpToFinished");
		JumpTo::ActivateJumpTo(Game::GetCody(), JumpToData, Events);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterUFOJumpToFinished(AHazeActor Actor)
	{
		SetAnimBoolParamOnSkeletalMeshes(n"CodyEnterUFO");
		bCodyEnteredUfo = true;
		OnCodyEnteredUFO.Broadcast();
		bBossStunned = false;

		HazeAudio::SetGlobalRTPC(HazeAudio::RTPC::SpaceStationMoonBaboonHangarAlarmLowPassRight, 1.f, 1000.f);

		UFOSkelMesh.RemoveTag(ComponentTags::Walkable);
	}

	UFUNCTION()
	void UfoPhaseFinished()
	{
		DisableActor(this);	
		StopAllAlarmSounds();			
	}	

	UFUNCTION(NotBlueprintCallable, NetFunction, DevFunction)
	void HitByRocket()
	{
		CurRocketHits++;

		TakeDamage((1.f/3.f)/RocketHitsNeeded);

		if(UFoHitByRocketEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(UFoHitByRocketEvent);
		}

		if (CurRocketHits >= RocketHitsNeeded && !bRocketPhaseCompleted)
		{
			OnRocketPhaseCompleted.Broadcast();
			bRocketPhaseCompleted = true;
			bBossStunned = true;
			HoverEffectComp.Deactivate();
		}
		else
		{
			// IMPLEMENT ROCKET HIT DIRECTION
			// SetAnimFloatParamOnSkeletalMeshes(n"RocketHitDirection", 0.f);

			SetAnimBoolParamOnSkeletalMeshes(n"HitByRocket");
		}
	}

	UFUNCTION()
    void OnGrabInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);

		Component.Disable(n"Held");

		FHazeAnimationDelegate OnAnimFinished;
		OnAnimFinished.BindUFunction(this, n"FailedLiftFinished");

		if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
		{
			bLifted = true;
			Game::GetCody().SetCapabilityAttributeObject(n"UFO", this);
			Game::GetCody().SetCapabilityActionState(n"LiftUFO", EHazeActionState::Active);
			SetAnimBoolParamOnSkeletalMeshes(n"CodyPickupUFO");
		}
		else if (ChangeSizeComp.CurrentSize == ECharacterSize::Medium)
		{
			Player.PlayEventAnimation(OnBlendingOut = OnAnimFinished, Animation = MediumLiftAnimation);
		}
		else if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
		{
			Player.PlayEventAnimation(OnBlendingOut = OnAnimFinished, Animation = SmallLiftAnimation);
		}
    }

	void EnableLaserGunInteraction()
	{
		if (RemoveLaserGunInteraction.IsDisabled(n"LiftUFO"))
			NetEnableLaserGunInteraction();
	}

	void DisableLaserGunInteraction()
	{
		if (!RemoveLaserGunInteraction.IsDisabled(n"LiftUFO"))
			NetDisableLaserGunInteraction();
	}

	UFUNCTION(NetFunction)
	void NetEnableLaserGunInteraction()
	{
		RemoveLaserGunInteraction.Enable(n"LiftUFO");
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightUfoPickup");
	}

	UFUNCTION(NetFunction)
	void NetDisableLaserGunInteraction()
	{
		RemoveLaserGunInteraction.Disable(n"LiftUFO");
	}

	UFUNCTION()
	void FailedLiftFinished()
	{
		GrabInteraction.Enable(n"Held");
	}

	UFUNCTION()
    void OnRemoveLaserGunInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Game::GetCody().SetCapabilityActionState(n"LiftUFO", EHazeActionState::Inactive);
		Component.Disable(n"RippedOff");
		RipOffLaserGun();
	}

	UFUNCTION()
	void RipOffLaserGun()
	{
		OnLaserGunRippedOff.Broadcast();
		SetAnimBoolParamOnSkeletalMeshes(n"RipOffLaser");
		SetAttackMode(EMoonBaboonAttackMode::Rockets);
		StartLookingAtPlayer(Game::GetMay());
	}

	UFUNCTION()
	void LaserGunRippedOff()
	{
		bLifted = false;
		UnstunBoss();
		StartFollowingSpline();
	}

	UFUNCTION()
	void SetHoverEffectVisibility(bool bHide)
	{
		if (bHide)
			HoverEffectComp.Deactivate();
		else
			HoverEffectComp.Activate(true);
	}

	UFUNCTION()
	void SetLaserGunVisibility(bool bHide = true)
	{
		if (bHide)
			UFOSkelMesh.HideBoneByName(n"LaserBase", EPhysBodyOp::PBO_None);
		else
			UFOSkelMesh.UnHideBoneByName(n"LaserBase");
	}

	UFUNCTION()
	void StartSlamMode()
	{
		SetControlSide(Game::GetMay());
		SetAttackMode(EMoonBaboonAttackMode::Slam);
		StartFollowingPlayerForSlam();
	}

	UFUNCTION()
	void StartFollowingPlayerForSlam()
	{
		bFollowPlayerForSlam = true;
	}

	UFUNCTION()
	void PerformSlam()
	{
		if (!bAllowSlamming)
			return;

		SetActorEnableCollision(false);

		bFollowPlayerForSlam = false;
		bSlamming = true;

		SlamTimer = System::SetTimer(this, n"StartFollowingPlayerForSlam", DelayBetweenSlams, false);
	}

	UFUNCTION()
	void DisableSlamming()
	{
		System::ClearAndInvalidateTimerHandle(SlamTimer);
		bAllowSlamming = false;
	}

	void SpawnSlamCircle()
	{
		FVector Loc = ActorLocation;
		Loc.Z = FloorActor.ActorLocation.Z + 26.f;
		AMoonBaboonLaserCircle NewLaserCircle = Cast<AMoonBaboonLaserCircle>(SpawnActor(SlamCircleClass, Loc));
		NewLaserCircle.ActivateLaserCircle();
		Game::GetCody().PlayCameraShake(SlamCamShake, 0.5f);
		Game::GetCody().PlayForceFeedback(SlamForceFeedback, false, true, n"Slam");
		HazeAkComp.HazePostEvent(UfoGroundSlamImpactSweetenerEvent);
	}

	void UpdateAudioParameters(float DeltaTime)
	{
		float Velocity = FVector(UFOSkelMesh.GetPhysicsLinearVelocity().X, UFOSkelMesh.GetPhysicsLinearVelocity().Y, 0.f).Size();	

		float RotationDelta = UFOSkelMesh.GetWorldRotation().Yaw - LastRotationDelta;
		LastRotationDelta = UFOSkelMesh.GetWorldRotation().Yaw;

		float AbsRotationDelta = FMath::Abs(RotationDelta);
		float NormalizedRotationDelta = HazeAudio::NormalizeRTPC01(AbsRotationDelta, 0.f, 0.6f);

		float AbsVelocityDelta = FMath::Abs(Velocity);
		float NormalizedVelocity = HazeAudio::NormalizeRTPC01(Velocity, 100.f, 5000.f);

		float ElevationDelta = UFOSkelMesh.GetWorldLocation().Z - LastElevationDelta;		
		LastElevationDelta = UFOSkelMesh.GetWorldLocation().Z;

		float TiltAngle = UFOSkelMesh.GetWorldRotation().Roll + UFOSkelMesh.GetWorldRotation().Pitch;			

		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoonBaboonUFORotationDelta, FMath::Clamp(NormalizedRotationDelta, 0.f, 1.f), 0.f);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoonBaboonUFOElevationDelta, FMath::Clamp(ElevationDelta, -10.f, 10.f), 0.f);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoonBaboonUFOVelocityDelta, FMath::Clamp(FMath::Clamp(NormalizedVelocity, 0.f, 1.f), 0.f, 1.f), 0.f);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoonBaboonUFOTiltAngle, TiltAngle, 0.f);
	}

	void StopAllAlarmSounds()
	{
		AggressiveAlarmAmbientSound.StopAmbientSoundEvent(n"Alarm");
		SweepingAlarmAmbientSound.StopAmbientSoundEvent(n"Alarm");
		InsideUFOHighAlarmAmbientSound.StopAmbientSoundEvent(n"Alarm");
		InsideUFOMediumAlarmAmbientSound.StopAmbientSoundEvent(n"Alarm");
		InsideUFOSweepingAlarmAmbientSound.StopAmbientSoundEvent(n"Alarm");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bBossStunned)
			return;

		if (CurrentAttackMode == EMoonBaboonAttackMode::Rockets)
		{
			CurrentSplineDistance += 1300 * DeltaTime;
			if (CurrentSplineDistance < SplineToFollow.SplineLength)
			{
				FVector NewLoc = FMath::VInterpTo(ActorLocation, SplineToFollow.GetLocationAtDistanceAlongSpline(CurrentSplineDistance, ESplineCoordinateSpace::World), DeltaTime, 5.f);
				SetActorLocation(NewLoc);
			}
			else
				CurrentSplineDistance = 0.f;

			for (ASpaceRocket Rocket : Rockets)
			{
				if (Rocket.MountedPlayer != nullptr)
				{
					if (GetDistanceTo(Rocket) <= RocketProximityBarkDistance)
					{
						SetCapabilityActionState(n"FoghornRocketApproach", EHazeActionState::ActiveForOneFrame);
					}
				}
			}

			FVector DirToMiddle = FloorActor.ActorLocation - ActorLocation;
			DirToMiddle = Math::ConstrainVectorToPlane(DirToMiddle, FVector::UpVector);
			DirToMiddle = DirToMiddle.GetSafeNormal();
			FRotator TargetRot = FMath::RInterpTo(ActorRotation, DirToMiddle.Rotation(), DeltaTime, 2.5f);
			SetActorRotation(TargetRot);
		}
		else if (CurrentAttackMode == EMoonBaboonAttackMode::LaserPointer)
		{
			LaserImpactLocation = LaserPointer.CurrentImpactLocation;
		}

		if (PlayerToLookAt != nullptr)
		{
			AHazePlayerCharacter TargetPlayer = PlayerToLookAt;
			if (TargetPlayer.IsPlayerDead())
				TargetPlayer = PlayerToLookAt.OtherPlayer;

			FVector DirToPlayer = TargetPlayer.ActorLocation - ActorLocation;
			DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
			DirToPlayer = DirToPlayer.GetSafeNormal();
			FRotator TargetRot = FMath::RInterpTo(ActorRotation, DirToPlayer.Rotation(), DeltaTime, 2.5f);
			SetActorRotation(TargetRot);
		}

		UpdateAudioParameters(DeltaTime);
	}

	UFUNCTION()
	void AttachToFloor()
	{
		AttachToActor(FloorActor, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	void DetachFromFloor()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	void PrepareLaserPointer()
	{
		LaserChargeEffect.Activate(true);
		System::SetTimer(this, n"ActivateLaserPointer", 5.f, false);
		MoonBaboon.SkelMesh.SetAnimBoolParam(n"PrepareLaserPointer", true);
		LaserPointer.ChargeUpLaserPointer();
		SetCapabilityActionState(n"FoghornChargeUpLaserPointer", EHazeActionState::ActiveForOneFrame);

		if (LaserPointer.PlayerTarget == EHazePlayer::May)
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightLaserMayTargeted");
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivateLaserPointer()
	{
		LaserPointer.TraceStartLocation = ActorLocation;
		LaserPointer.EnableLaserPointer();
		LaserPointer.OnPowerCoreDestroyed.AddUFunction(this, n"PowerCoreDestroyed");
		bLaserActive = true;
		LaserPointerTauntTimerHandle = System::SetTimer(this, n"PlayLaserPointerTaunt", LaserPointerTauntDelay, true);

		if (LaserPointer.PlayerTarget == EHazePlayer::Cody)
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationBossFightLaserCodyTargeted");
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayLaserPointerTaunt()
	{
		SetCapabilityActionState(n"FoghornLaserPointerTaunt", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	void LaserPointerDisabled()
	{
		// bLaserActive = false;
	}

	UFUNCTION()
	void PowerCoreDestroyed()
	{
		PowerCoresDestroyed++;
		TakeDamage(1.f/9.f);
		if (PowerCoresDestroyed >= 3)
		{
			bBossStunned = true;
			bAllPowerCoresDestroyed = true;
			HoverEffectComp.Deactivate();
		}
		else
		{
			SetAnimBoolParamOnSkeletalMeshes(n"HitByLaser");
		}

		bLaserActive = false;

		System::ClearAndInvalidateTimerHandle(LaserPointerTauntTimerHandle);
	}

	UFUNCTION()
	void LaserSpinnerStarts()
	{
		SetCapabilityActionState(n"FoghornLaserSpinnerStarts", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void LaserSpinnerFinalStarts()
	{
		SetCapabilityActionState(n"FoghornLaserSpinnerFinalStarts", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void StartSpawningBombs()
	{
		LaserBombTimerHandle = System::SetTimer(this, n"LaunchBomb", BombDelay, true);
		SetCapabilityActionState(n"FoghornLaserBombsStart", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void StopSpawningBombs()
	{
		System::ClearAndInvalidateTimerHandle(LaserBombTimerHandle);
	}

	UFUNCTION()
	void LaunchBomb()
	{
		if (LastBombPlayer == Game::GetMay())
			LastBombPlayer = Game::GetCody();
		else
			LastBombPlayer = Game::GetMay();

		if (LastBombPlayer.IsPlayerDead())
			return;

		AMoonBaboonLaserBomb Bomb;

		for (AMoonBaboonLaserBomb CurBomb : LaserBombPool)
		{
			if (CurBomb.bExpired)
			{
				Bomb = CurBomb;
				continue;
			}
		}

		if (Bomb == nullptr)
		{
			Bomb = Cast<AMoonBaboonLaserBomb>(SpawnActor(LaserBombClass, ActorLocation));
			Bomb.AttachToActor(FloorActor);
			Bomb.TeleportActor(ActorLocation, ActorRotation);
		}


		Bomb.LaunchBomb(LastBombPlayer);
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		CurrentSplineDistance = SplineToFollow.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		CurrentAttackMode = EMoonBaboonAttackMode::Rockets;
	}

	UFUNCTION()
	void StopFollowingSpline()
	{
		
	}

	UFUNCTION()
	void StartSpawningMissiles()
	{
		SpawnMayMissile();
		SpawnCodyMissile();
	}

	UFUNCTION(NotBlueprintCallable)
	void SpawnMayMissile()
	{
		if (!bRocketPhaseCompleted)
		{
			FRotator Rot = FRotator::ZeroRotator;
			Rot.Yaw = UFOSkelMesh.GetSocketRotation(n"LeftFrontRocketHatch").Yaw;
			MayRocket.TeleportActor(UFOSkelMesh.GetSocketLocation(n"LeftFrontRocketHatch"), Rot);
			MayRocket.StartFollowingPlayer();
			UFOSkelMesh.SetAnimBoolParam(n"FireRocketLeft", true);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void SpawnCodyMissile()
	{
		if (!bRocketPhaseCompleted)
		{
			FRotator Rot = FRotator::ZeroRotator;
			Rot.Yaw = UFOSkelMesh.GetSocketRotation(n"RightFrontRocketHatch").Yaw;
			CodyRocket.TeleportActor(UFOSkelMesh.GetSocketLocation(n"RightFrontRocketHatch"), Rot);
			CodyRocket.StartFollowingPlayer();
			UFOSkelMesh.SetAnimBoolParam(n"FireRocketRight", true);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PrepareNewMayMissile()
	{
		if (!Game::GetMay().HasControl())
			return;

		if (Game::GetMay().IsPlayerDead())
			return;

		NetPrepareMayMissile();
	}

	UFUNCTION(NetFunction)
	void NetPrepareMayMissile()
	{
		MoonBaboon.SkelMesh.SetAnimBoolParam(n"PrepareFireRocketLeft", true);
		System::SetTimer(this, n"SpawnMayMissile", 2.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void PrepareNewCodyMissile()
	{
		if (!Game::GetCody().HasControl())
			return;

		if (Game::GetCody().IsPlayerDead())
			return;		

		NetPrepareCodyMissile();
	}

	UFUNCTION(NetFunction)
	void NetPrepareCodyMissile()
	{
		MoonBaboon.SkelMesh.SetAnimBoolParam(n"PrepareFireRocketRight", true);
		System::SetTimer(this, n"SpawnCodyMissile", 2.f, false);
	}

	UFUNCTION()
	void EnableGrabInteraction()
	{
		GrabInteraction.Enable(n"Stunned");
	}

	UFUNCTION()
	void UnstunBoss()
	{
		bBossStunned = false;

		if(StartUFOLoopingEvent != nullptr && !HazeAkComp.HazeIsEventActive(StartUFOLoopingEventInstance.EventID))
		{
			StartUFOLoopingEventInstance = HazeAkComp.HazePostEvent(StartUFOLoopingEvent);
		}
		if(HazeAkComp.HazeIsEventActive(BrokenUfOLoopingEventInstance.EventID))
		{
			HazeAkComp.HazeStopEvent(BrokenUfOLoopingEventInstance.PlayingID, 1000.f, EAkCurveInterpolation::Log1, true);
		}
	}

	UFUNCTION()
	void ShowHealthBar(float InitialHealth = 1.f)
	{
		if (!HealthBarClass.IsValid())
			return;

		CurrentHealth = InitialHealth;

		FText BossName = NSLOCTEXT("MoonBaboon", "Name", "Moon Baboon");
		HealthBarWidget = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarClass));
		HealthBarWidget.InitBossHealthBar(BossName, 1.f, 3);
		HealthBarWidget.SnapHealthTo(InitialHealth);
	}

	UFUNCTION()
	void HideHealthBar()
	{
		if (HealthBarWidget == nullptr)
			return;

		Widget::RemoveFullscreenWidget(HealthBarWidget);
	}

	UFUNCTION()
	void SetHealth(float Health)
	{
		CurrentHealth = Health;

		if (HealthBarWidget == nullptr)
			return;

		HealthBarWidget.Health = CurrentHealth;
	}

	UFUNCTION()
	void TakeDamage(float Damage)
	{
		if (HealthBarWidget == nullptr)
			return;

		CurrentHealth -= Damage;
		HealthBarWidget.SetHealthAsDamage(CurrentHealth);
	}

	UFUNCTION()
	void SetAttackMode(EMoonBaboonAttackMode NewMode)
	{
		CurrentAttackMode = NewMode;
	}

	void SetAnimBoolParamOnSkeletalMeshes(FName BoneName, bool bValue = true)
	{
		UFOSkelMesh.SetAnimBoolParam(BoneName, bValue);
		MoonBaboon.SkelMesh.SetAnimBoolParam(BoneName, true);
	}

	void SetAnimFloatParamOnSkeletalMeshes(FName BoneName, float Value)
	{
		UFOSkelMesh.SetAnimFloatParam(BoneName, Value);
		MoonBaboon.SkelMesh.SetAnimFloatParam(BoneName, Value);
	}
}

enum EMoonBaboonAttackMode
{
	LaserPointer,
	Rockets,
	Slam
}