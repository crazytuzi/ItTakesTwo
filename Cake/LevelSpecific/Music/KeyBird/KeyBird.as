import Cake.LevelSpecific.Music.KeyBird.KeyBirdKey;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;
import Peanuts.Aiming.AutoAimTarget;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;
import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;
import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdSettings;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdCommon;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdCombatArea;

import void ReturnKeyBird(AKeyBird) from "Cake.LevelSpecific.Music.KeyBird.KeyBirdSpawner";
import Cake.SteeringBehaviors.BoidObstacleStatics;
import Cake.SteeringBehaviors.BoidShapeVisualizer;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Music.KeyBird.Capabilities.KeyBirdAction;
import Cake.LevelSpecific.Music.KeyBird.Capabilities.KeyBirdActionDie;
import Vino.PlayerHealth.PlayerDamageEffect;
import Vino.PlayerHealth.PlayerDeathEffect;
import Peanuts.Audio.VO.PatrolActorAudioComponent;

#if !RELEASE
const FConsoleVariable CVar_KeyBirdDebugDraw("Music.KeyBirdDebugDraw", 0);
#endif // !RELEASE

event void OnKeybirdSpawnedFollower(AMusicalFollower Follower, AHazePlayerCharacter Instigator);
event void FOnKeyHolderDied(AMusicalFollowerKey Follower, AHazePlayerCharacter KillerPlayer);

settings KeyBirdSettingsDefault for UKeyBirdSettings
{
	
}

bool EqualsCombatArea(AHazeActor KeyBirdActor, const AKeyBirdCombatArea CombatArea)
{
	AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

	if(KeyBird != nullptr)
	{
		return KeyBird.CombatArea == CombatArea;
	}

	return false;
}

bool IsKeyBirdDead(AHazeActor KeyBirdActor)
{
	AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

	if(KeyBird != nullptr)
	{
		return KeyBird.IsDead();
	}

	return true;
}

void KillKeyBirdAtLocation(AHazeActor KeyBirdActor, AActor TargetActor)
{
	AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

	if(KeyBird != nullptr)
	{
		KeyBird.MoveToActorAndDie(TargetActor);
	}
}

// Use case scenario: cutscene. Not networked by itself so you need to make sure this is called on both sides.
UFUNCTION()
void KillAllKeyBirdsWithinRadius(FVector Origin, float Radius = 50000.0f)
{
	UHazeAITeam AITeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

	if(AITeam == nullptr)
		return;

	TSet<AHazeActor> TeamMembers = AITeam.GetMembers();

	const float RadiusSq = FMath::Square(Radius);

	AHazePlayerCharacter PlayerInstigator = Game::GetMay();

	for(AHazeActor Member : TeamMembers)
	{
		if(Member.ActorLocation.DistSquared(Origin) > RadiusSq || !Member.HasControl())
			continue;



		AKeyBird KeyBird = Cast<AKeyBird>(Member);
		KeyBird.DestroyActorFunction(PlayerInstigator, FVector::ForwardVector);
	}
}

UFUNCTION()
void KillKeyBirds(TArray<AKeyBird> ListOfKeyBirds)
{
	AHazePlayerCharacter PlayerInstigator = Game::GetMay();

	for(AKeyBird KeyBird : ListOfKeyBirds)
	{
		if(KeyBird.HasControl())
			KeyBird.DestroyActorFunction(PlayerInstigator, FVector::ForwardVector);
	}
}

void KillKeyBird(AHazeActor KeyBirdActor)
{
	AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

	if(KeyBird != nullptr)
	{
		KeyBird.Kill();
	}
}

void KillKeyBird_NoEffect(AHazeActor KeyBirdActor)
{
	AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

	if(KeyBird != nullptr)
	{
		KeyBird.Kill_NoEffect();
	}
}

class UKeyBirdDummyVisualizerComponent : UActorComponent {}

#if EDITOR

class UKeyBirdComponentVisualizer : UBoidObstacleShapeVisualizer
{
    default VisualizedClass = UKeyBirdDummyVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        if (!ensure((Component != nullptr) && (Component.Owner != nullptr)))
			return;

		AKeyBird KeyBird = Cast<AKeyBird>(Component.Owner);

		if(KeyBird == nullptr)
			return;

		if(KeyBird.CombatArea == nullptr)
			return;

		UBoidShapeComponent BoidShape = UBoidShapeComponent::Get(KeyBird.CombatArea);

		DrawBoidShape(BoidShape);
    }
}

#endif // EDITOR

UCLASS(hidecategories = "Rendering Input LOD Cooking Actor Replication")
class AKeyBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeOffsetComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	UHazeCharacterSkeletalMeshComponent MeshBody;
	default MeshBody.CollisionProfileName = n"NoCollision";
	default MeshBody.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KeybirdDeathAudioEvent;

	UPROPERTY()
	UNiagaraSystem HitEffect;
	UPROPERTY(DefaultComponent, Attach = MeshBody, AttachSocket = Spine2)
	UNiagaraComponent DeathEffectAttached;
	default DeathEffectAttached.bAutoActivate = false;

	UPROPERTY()
	UNiagaraSystem DeathEffect;
	UPROPERTY()
	FOnKeyHolderDied OnKeyHolderDied;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = MeshBody)
	USteeringBehaviorComponent SteeringBehavior;
	default SteeringBehavior.bEnableSeekBehavior = false;
	default SteeringBehavior.bEnableAvoidanceBehavior = true;
	default SteeringBehavior.Avoidance.InsideSize = 15.0f;
	default SteeringBehavior.Avoidance.AheadNear = 1000.0f;
	default SteeringBehavior.Avoidance.AheadFar = 2000.0f;
	default SteeringBehavior.Avoidance.AheadNearSize = 9.0f;
	default SteeringBehavior.Avoidance.AheadFarSize = 6.0f;
	default SteeringBehavior.Avoidance.bCheckFar = false;
	default SteeringBehavior.Avoidance.bCheckNear = true;
	default SteeringBehavior.Avoidance.bCheckInside = false;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UCymbalImpactComponent CymbalImpactComponent;
	default CymbalImpactComponent.bCanBeTargeted = false;
	default CymbalImpactComponent.bPlayVFXOnHit = false;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	USongReactionComponent SongReaction;

	UPROPERTY(DefaultComponent)
	UKeyBirdBehaviorComponent KeyBirdBehavior;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UAutoAimTargetComponent AutoAimTargetComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent ReplicatedDirection;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent ReplicatedLocation;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMusicKeyComponent KeyComponent;
	default KeyComponent.bPickupKeys = false;
	default KeyComponent.MaxNumKeys = 1;
	default KeyComponent.bLimitMaxKeys = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 35000.f;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent ReplicatedVelocity;

	UPROPERTY(DefaultComponent)
	UPatrolActorAudioComponent PatrolAudioComp;
	default PatrolAudioComp.bAutoRegister = false;

	UPROPERTY()
	AKeyBirdCombatArea CombatArea = nullptr;

	ASplineActor CurrentSplineActor = nullptr;

	// If a spawner spawned this keybird this pointer will be set.
	AHazeActor Spawner = nullptr;

	UPROPERTY(Category = "AttackPlayer|Animation")
	UAnimSequence HitCodyAnim;
	UPROPERTY(Category = "AttackPlayer|Animation")
	UAnimSequence HitMayAnim;
	UPROPERTY(Category = AttackPlayer)
	UForceFeedbackEffect HitPlayerFeedback;
	UPROPERTY(Category = AttackPlayer)
	float HitRadius = 180.0f;
	UPROPERTY(Category = Attackplayer)
	TSubclassOf<UPlayerDamageEffect> PlayerDamageEffect;
	UPROPERTY(Category = Attackplayer)
	TSubclassOf<UPlayerDeathEffect> PlayerDeathEffect;
	UPROPERTY(Category = Attackplayer)
	float DamageAmount = 0.5f;

	// This is the key that the bird will start with
	UPROPERTY()
	protected AMusicalFollowerKey Key;

	UPROPERTY(Category = "AttackPlayer|Animation")
	UAnimSequence AttackAnim;

	UPROPERTY(Category = Animation)
	UBlendSpace FlyingBlendSpace;
	
	AHazePlayerCharacter TargetPlayer;

	private TArray<UKeyBirdAction> ActionCollection;

	UPROPERTY(Category = Settings)
	UKeyBirdSettings KeyBirdSettings = KeyBirdSettingsDefault;
	UPROPERTY(Category = Settings, meta = (DisplayName = "SeekKeySettings"))
	UKeyBirdSettings KeyBirdSeekKeySettings = KeyBirdSettingsDefault;
	UPROPERTY(Category = Settings, meta = (DisplayName = "StealKeySettings"))
	UKeyBirdSettings KeyBirdStealKeySettings = KeyBirdSettingsDefault;
	UPROPERTY(Category = Settings, meta = (DisplayName = "SplineMovementSettings"))
	UKeyBirdSettings KeyBirdSplineSettings = KeyBirdSettingsDefault;
	UPROPERTY(Category = Settings)
	UKeyBirdSettings ActionLocationSettings = KeyBirdSettingsDefault;
	
	UKeyBirdSettings DefaultKeyBirdSettings;

	UPROPERTY()
	OnKeybirdSpawnedFollower OnFollowerSpawned;

	FVector CurrentVelocity;
	private FVector MeshRelativeLocation;

	UPROPERTY(Category = Death)
	float DeathImpulse = 50000.0f;

	bool bPreDestroyed = false;
	bool bStartAttack = false;
	bool bCustomFacingDirection = false;

	FVector FacingDirection;

	FVector GetTargetFacingDirection() const property
	{
		return bCustomFacingDirection ? FacingDirection : SteeringBehavior.DirectionToTarget;
	}

	// Time that needs to pass before this KeyBird is allowed to change target again.
	UPROPERTY(Category = AI)
	float ChangeTargetCooldown = 2.0f;

	float ChangeTargetElapsed = 0.0f;

	float SplineDistanceTotal = 0.0f;
	float SplineDistanceCurrent = 0.0f;

	bool CanChangeTarget() const
	{
		return ChangeTargetElapsed <= 0.0f;
	}

	UPROPERTY()
	protected bool bKeyBirdEnabled = false;

	AHazePlayerCharacter OriginalControlSide;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(HasControl())
			OriginalControlSide = Game::FirstLocalPlayer;
		else
			OriginalControlSide = Game::FirstLocalPlayer.OtherPlayer;
		SteeringBehavior.BoidArea = CombatArea;
		MeshRelativeLocation = MeshBody.RelativeLocation;
		ApplyDefaultSettings(KeyBirdSettings);
		DefaultKeyBirdSettings = UKeyBirdSettings::GetSettings(this);

		AddCapability(n"KeyBirdMovementCapability");
		AddCapability(n"KeyBirdChangeSeekLocationCapability");
		AddCapability(n"KeyBirdStealKeyCapability");
		AddCapability(n"KeyBirdApproachKeyCapability");
		AddCapability(n"KeyBirdApproachPlayerCapability");
		AddCapability(n"KeyBirdSplineMovementCapability");
		AddCapability(n"KeyBirdMoveToActionLocationCapability");

		CymbalImpactComponent.OnCymbalHit.AddUFunction(this, n"HandleCymbalImpact");
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"HandlePowerfulSongImpact");

		if(Key != nullptr && HasControl())
			Key.AddPendingFollowTarget(this);

		SetNewTargetLocation();

		if(!bKeyBirdEnabled)
			SetKeyBirdEnabled(false);
		else
			SetKeyBirdEnabled(true);

		KeyBirdCommon::SetupKeyBird(this);

		if(MeshBody.SkeletalMesh != nullptr && FlyingBlendSpace != nullptr)
		{
			FHazePlayBlendSpaceParams Params;
			Params.BlendSpace = FlyingBlendSpace;
			Params.PlayRate = 1.0f;
			MeshBody.PlayBlendSpace(Params);
		}

		ReplicatedLocation.Value = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(CombatArea == nullptr)
		{
			AKeyBirdCombatArea NewCombatArea = Cast<AKeyBirdCombatArea>(FindClosestBoidArea(ActorLocation));
			SetCombatArea(NewCombatArea);
		}

		ReplicatedLocation.Value = ActorLocation;
	}

	bool HasActions() const { return ActionCollection.Num() > 0; }
	void ConsumeActions()
	{
		for(UKeyBirdAction Action : ActionCollection)
			Action.Execute();

		ActionCollection.Empty();
	}

	void SetCombatArea(AKeyBirdCombatArea NewCombatArea)
	{
		CombatArea = CombatArea;
		SteeringBehavior.BoidArea = NewCombatArea;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		LeaveTeam(n"KeyBirdTeam");
		System::ClearAndInvalidateTimerHandle(ReturnKeyBirdHandle);
		PatrolAudioComp.BP_UnregisterToManager();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ChangeTargetElapsed -= DeltaTime;

		if(HasControl())
		{
			float VelocityFraction = SteeringBehavior.VelocityMagnitude / DefaultKeyBirdSettings.VelocityMaximum;
			MeshBody.SetBlendSpaceValues(VelocityFraction, VelocityFraction, false);
			ReplicatedVelocity.SetValue(SteeringBehavior.VelocityMagnitude);
		}
		else
		{
			float VelocityFraction = ReplicatedVelocity.Value / DefaultKeyBirdSettings.VelocityMaximum;
			MeshBody.SetBlendSpaceValues(VelocityFraction, VelocityFraction, false);
		}

		AHazePlayerCharacter FirstLocal = Game::FirstLocalPlayer;

		if(Network::IsNetworked() && HasControl())
		{
			const bool bIsDead = IsDead();
			const bool bIsStateRandomMovement = CurrentState == EKeyBirdState::RandomMovement;
			const bool bIsControlSideDifferentFromOriginal = OriginalControlSide != Game::FirstLocalPlayer;
			if(!bIsDead
			&& bIsStateRandomMovement
			&& bIsControlSideDifferentFromOriginal)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"Crumb_ChangeControlSide"), CrumbParams);
			}
		}

		//System::DrawDebugArrow(SteeringBehavior.WorldLocation, SteeringBehavior.WorldLocation + SteeringBehavior.RightVector * 1500, 50, FLinearColor::Red, 0, 15);
		//System::DrawDebugArrow(SteeringBehavior.WorldLocation, SteeringBehavior.WorldLocation + SteeringBehavior.ForwardVector * 1500, 50, FLinearColor::Green, 0, 15);
		//System::DrawDebugArrow(SteeringBehavior.WorldLocation, SteeringBehavior.WorldLocation + Cross * 1500, 50, FLinearColor::Blue, 0, 15);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_ChangeControlSide(FHazeDelegateCrumbData CrumbData)
	{
		if(!IsDead())
			SetControlSide(OriginalControlSide);
	}

	bool IsHoldingKey() const
	{
		return KeyComponent.HasKey();
	}

	int NumKeys() const
	{
		return KeyComponent.NumKeys();
	}

	void SetNewTargetLocation()
	{
		int NumTries = 10;
		int NumTriesCurrent = 0;
		FVector NewRandomLocation = SteeringBehavior.RandomLocationInBoidArea;

		while(IsPointOverlappingBoidObstacle(NewRandomLocation) && NumTriesCurrent < NumTries)
		{
			NewRandomLocation = SteeringBehavior.RandomLocationInBoidArea;
			NumTriesCurrent++;
		}

		SteeringBehavior.Seek.SetTargetLocation(NewRandomLocation);
	}

	void SetNewTargetPlayer(AHazePlayerCharacter InTargetPlayer)
	{
		if(!HasControl())
			return;

		if(CurrentState != EKeyBirdState::RandomMovement)
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"TargetPlayer", InTargetPlayer);
		if(HasControl() != InTargetPlayer.HasControl())
			CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"Crumb_TargetPlayer"), CrumbParams);
		else
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_TargetPlayer"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_TargetPlayer(FHazeDelegateCrumbData CrumbData)
	{
		if(IsDead())
			return;

		AHazePlayerCharacter NewPlayerTarget = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"TargetPlayer"));
		SteeringBehavior.Seek.SetTargetActor(NewPlayerTarget);
		UpdateControlSide(NewPlayerTarget);
		KeyBirdBehavior.SetCurrentState(EKeyBirdState::StealKey);
		TargetPlayer = NewPlayerTarget;
	}

	// When we want this bird to target a key that it will move towards
	void SetNewSeekTarget(AHazeActor SeekTarget, int NewState)
	{
		if(!HasControl())
			return;

		if(CurrentState != EKeyBirdState::RandomMovement)
			return;

		if(IsDead())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"SeekTarget", SeekTarget);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetNewKeyTarget"), CrumbParams);
	}

	UFUNCTION()
	void SetKeyBirdEnabled(bool bEnabled)
	{
		bKeyBirdEnabled = bEnabled;

		if(bKeyBirdEnabled)
		{
			SteeringBehavior.bEnableAvoidanceBehavior = true;
			SteeringBehavior.bEnableSeekBehavior = true;
			SteeringBehavior.bEnableLimitsBehavior = true;
			CymbalImpactComponent.bCanBeTargeted = true;
			SongReaction.bCanBeTargeted = true;
			if(CurrentState == EKeyBirdState::None)
				StartRandomMovement();
			if(IsActorDisabled())
				EnableActor(nullptr);

			PatrolAudioComp.BP_RegisterToManager();
		}
		else
		{
			SteeringBehavior.DisableAllBehaviors();
			CymbalImpactComponent.bCanBeTargeted = false;
			SongReaction.bCanBeTargeted = false;
			if(!IsActorDisabled())
				DisableActor(nullptr);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_SetNewKeyTarget(FHazeDelegateCrumbData CrumbData)
	{
		if(IsDead())
			return;

		AHazeActor SeekTarget = Cast<AHazeActor>(CrumbData.GetObject(n"SeekTarget"));
		SteeringBehavior.Seek.SetTargetActor(SeekTarget);
		KeyBirdBehavior.SetCurrentState(EKeyBirdState::SeekKey);
	}

	private void UpdateControlSide(AHazeActor NewControlSide)
	{
		if(NewControlSide.HasControl() != HasControl())
			SetControlSide(NewControlSide);
	}

	UFUNCTION()
	void Handle_RandomizeTimerDone()
	{
	}

	UFUNCTION()
	void HandleCymbalImpact(FCymbalHitInfo HitInfo)
	{
		HandleImpact(HitInfo.Instigator, HitInfo.DeltaMovement.GetSafeNormal());
	}

	UFUNCTION()
	void HandlePowerfulSongImpact(FPowerfulSongInfo HitInfo)
	{
		HandleImpact(HitInfo.Instigator, HitInfo.Direction.GetSafeNormal());
	}

	void ReviveKeyBird()
	{
		SetKeyBirdEnabled(true);
		KeyBirdBehavior.bIsDead = false;
		UnblockCapabilities(n"KeyBird", this);
		UnblockCapabilities(CapabilityTags::LevelSpecific, this);
		SetActorHiddenInGame(false);
		CymbalImpactComponent.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
		SongReaction.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		bPreDestroyed = false;
		CrumbComponent.UnlockTrail(this);
	}

	// Called when hit by powerful song or Cymbal
	UFUNCTION()
	void DestroyActorFunction(AHazeActor InInstigator, FVector HitDirection)
	{
		if(IsDead())
			return;

		// Can be hit first by a player that is locally control while this actor is remote so we need to simlate that we are killed.
		PreDestroyActor(true, true);

		if(KeyComponent.HasKey())
		{
			OnKeyHolderDied.Broadcast(KeyComponent.FirstKey, Cast<AHazePlayerCharacter>(Instigator));
			KeyComponent.DropAllKeys();
		}
		
		FinishDestroyActor(true, true);
	}

	private void PreDestroyActor(bool bPlayEffect, bool bApplyPhysics)
	{
		if(bPreDestroyed)
			return;

		BlockCapabilities(n"KeyBird", this);
		BlockCapabilities(CapabilityTags::LevelSpecific, this);
		CleanupCurrentMovementTrail(true);
		// This one is for the future...And the future is now! (J.S)

		if(bApplyPhysics)
		{
			MeshBody.SetCollisionProfileName(n"Ragdoll");
			MeshBody.SetAllPhysicsLinearVelocity(MeshBody.ForwardVector * 3000 + MeshBody.UpVector * 2000 );
			MeshBody.SetCollisionEnabled(ECollisionEnabled::PhysicsOnly);
			MeshBody.SetSimulatePhysics(true);
			MeshBody.bUseBoundsFromMasterPoseComponent = true;
			MeshBody.AddImpulse(-FVector::UpVector * DeathImpulse, NAME_None, true);
		}

		if(bPlayEffect)
		{
			UNiagaraComponent DeathEffectComp = Niagara::SpawnSystemAtLocation(DeathEffect, MeshBody.GetSocketLocation(n"Spine2"), ActorRotation);
			DeathEffectComp.SetTranslucentSortPriority(3);
			DeathEffectAttached.Activate();
			PatrolAudioComp.HandleDeath();
			HazeAkComp.HazePostEvent(KeybirdDeathAudioEvent);
		}

		if(!bPlayEffect && !bApplyPhysics)
		{
			SetActorHiddenInGame(true);
		}

		CymbalImpactComponent.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		SongReaction.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		bPreDestroyed = true;
		SteeringBehavior.Seek.SetTargetActor(nullptr);
		TargetPlayer = nullptr;
		SetActorTickEnabled(false);
		CrumbComponent.LockTrail(this, false, true);
	}

	private void FinishDestroyActor(bool bPlayEffect, bool bApplyPhysics)
	{
		PreDestroyActor(bPlayEffect, bApplyPhysics);
		KeyBirdBehavior.bIsDead = true;
		KeyBirdBehavior.OnKeyBirdDestroyed.Broadcast(this);
		KeyComponent.SetIsOwnerDisabled(true);

		const float TimeUntilDisappear = 5.0f;

		if(Spawner == nullptr)
			SetLifeSpan(TimeUntilDisappear);
		else
			ReturnKeyBirdHandle = System::SetTimer(this, n"Timer_ReturnKeyBird", TimeUntilDisappear, false);
	}

	private FTimerHandle ReturnKeyBirdHandle;

	UFUNCTION()
	private void Timer_ReturnKeyBird()
	{
		DeathEffectAttached.Deactivate();
		MeshBody.SetSimulatePhysics(false);
		MeshBody.SetCollisionProfileName(n"NoCollision");
		MeshBody.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		MeshBody.SetRelativeLocationAndRotation(MeshRelativeLocation, FRotator::ZeroRotator);
		SetActorHiddenInGame(true);
		MeshBody.AttachToComponent(MeshOffset);
		ReturnKeyBird(this);
		CleanupCurrentMovementTrail(true);
		SetActorTickEnabled(true);
	}

	void HandleImpact(AHazeActor InInstigator, FVector HitDirection)
	{
		Niagara::SpawnSystemAtLocation(HitEffect, ActorLocation, ActorRotation);
		DestroyActorFunction(InInstigator, HitDirection);
	}

	void Kill_NoEffect()
	{
		FinishDestroyActor(false, false);
	}

	void Kill()
	{
		FinishDestroyActor(true, true);
	}

	EKeyBirdState GetCurrentState() const property
	{
		return KeyBirdBehavior.CurrentState;
	}

	private void SetCurrentState(EKeyBirdState NewState) property
	{
		KeyBirdBehavior.SetCurrentState(NewState);
	}

	UFUNCTION(BlueprintPure)
	bool IsKeyBirdEnabled() const
	{
		return bKeyBirdEnabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsDead() const
	{
		return KeyBirdBehavior.bIsDead;
	}

	UFUNCTION(BlueprintPure)
	bool HasKey() const
	{
		return KeyComponent.HasKey();
	}

	bool IsPointInsideCombatArea(FVector Point) const
	{
		if(CombatArea == nullptr)
			return true;

		return CombatArea.IsInsideCombatArea(Point);
	}

	UFUNCTION()
	void MoveAlongSpline(ASplineActor SplineActor)
	{
		if(!devEnsure(SplineActor != nullptr))
			return;

		if(!IsKeyBirdEnabled())
			SetKeyBirdEnabled(true);	

		SetCurrentState(EKeyBirdState::SplineMovement);
		SteeringBehavior.Seek.SetTargetActor(nullptr);
		CurrentSplineActor = SplineActor;
		TargetPlayer = nullptr;
		SteeringBehavior.bEnableLimitsBehavior = false;
		SteeringBehavior.bEnableAvoidanceBehavior = false;
		SteeringBehavior.bEnableSeekBehavior = true;
	}

	UFUNCTION()
	void StartRandomMovement()
	{
		if(IsDead())
			return;

		if(!IsKeyBirdEnabled())
			SetKeyBirdEnabled(true);

		SetCurrentState(EKeyBirdState::RandomMovement);
		SteeringBehavior.Seek.SetTargetActor(nullptr);
		CurrentSplineActor = nullptr;
		TargetPlayer = nullptr;
		SteeringBehavior.bEnableLimitsBehavior = true;
		SteeringBehavior.bEnableAvoidanceBehavior = true;
	}

	UFUNCTION()
	void MoveToActorAndDie(AActor TargetActor)
	{
		if(IsDead())
			return;

		if(!devEnsure(TargetActor != nullptr))
			return;

		MoveToLocationAndDie(TargetActor.ActorLocation);
	}

	UFUNCTION()
	void MoveToLocationAndDie(FVector TargetLocation)
	{
		if(IsDead())
			return;

		if(!IsKeyBirdEnabled())
			SetKeyBirdEnabled(true);

		SetCurrentState(EKeyBirdState::MoveToActionLocation);
		SteeringBehavior.Seek.SetTargetActor(nullptr);
		SteeringBehavior.Seek.SetTargetLocation(TargetLocation);
		SteeringBehavior.bEnableLimitsBehavior = false;
		SteeringBehavior.bEnableAvoidanceBehavior = true;
		SteeringBehavior.bEnableSeekBehavior = true;
		AddAction(UKeyBirdActionDie::StaticClass());
	}

	void AddAction(UClass InActionClass)
	{
		TSubclassOf<UKeyBirdAction> ActionClass = InActionClass;
		AddAction(ActionClass);
	}

	void AddAction(TSubclassOf<UKeyBirdAction> ActionClass)
	{
		if(!devEnsure(ActionClass.IsValid()))
			return;

		UKeyBirdAction Action = Cast<UKeyBirdAction>(NewObject(this, ActionClass));

		if(!devEnsure(Action != nullptr))
			return;

		Action.Owner = this;
		ActionCollection.Add(Action);
	}
}
