import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;
import Cake.LevelSpecific.Music.Classic.MusicalFollowerKeyCommon;

import void Handle_OnPickedUp(AActor, AMusicalFollowerKey) from "Cake.LevelSpecific.Music.Classic.MusicKeyComponent";
import void Handle_OnLost(AActor, AMusicalFollowerKey) from "Cake.LevelSpecific.Music.Classic.MusicKeyComponent";
import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollowerKeyDestination;
import Cake.SteeringBehaviors.BoidShapeVisualizer;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdCombatArea;

event void FOnPickedUpByActor(AHazeActor PickedUpBy);

#if !RELEASE
const FConsoleVariable CVar_KeyFollowerDebugDraw("Music.KeyFollowerDebugDraw", 0);
#endif // !RELEASE

event void FOnMusicalKeyReachedTargetDestination();
event void FOnMusicalKeyFoundTargetDestination(AMusicalFollower Follower);
event void FMusicalFollower_OnNewFollowTarget(AHazeActor NewOwner);

enum EMusicalKeyState
{
	Idle,	// Do nothing
	FollowTarget, // Follow a target actor, if we have one
	GoToLocation // Go to a target location actor, such as the keyhole, and broadcast when we have reached that destination.
}

class UMusicKeyVisualizerDummyComponent : UActorComponent {}

#if EDITOR

class UMusicKeyComponentVisualizer : UBoidObstacleShapeVisualizer
{
    default VisualizedClass = UMusicKeyVisualizerDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        if (!ensure((Component != nullptr) && (Component.Owner != nullptr)))
			return;

		AMusicalFollowerKey Key = Cast<AMusicalFollowerKey>(Component.Owner);

		if(Key == nullptr)
			return;

		if(Key.CombatArea == nullptr)
			return;

		UBoidShapeComponent BoidShape = UBoidShapeComponent::Get(Key.CombatArea);

		DrawBoidShape(BoidShape);
    }
}

#endif // EDITOR

class AMusicalFollowerKey : AHazeActor
{
	UPROPERTY()
	FOnMusicalKeyReachedTargetDestination OnReachedTargetDestination;

	UPROPERTY()
	FOnMusicalKeyFoundTargetDestination OnFoundTargetDestination;

	UPROPERTY()
	FMusicalFollower_OnNewFollowTarget OnNewFollowTarget;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	default Mesh.RelativeRotation = FRotator(0.0f, 90.0f, 0.0f);
	default Mesh.CollisionProfileName = n"NoCollision";

	// Used in idle movement state
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent MovementReplication;

	UPROPERTY(DefaultComponent, NotVisible)
	UMusicalKeyBehaviorComponent KeyBehavior;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent KeyTrail;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent KeyTrailTwo;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent KeyGlow;
	default KeyGlow.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 35000.f;

	UPROPERTY(DefaultComponent, NotEditable)
	UMusicKeyVisualizerDummyComponent VisualizerDummy;
	default VisualizerDummy.bIsEditorOnly = true;

	UPROPERTY(Category = FollowSetup)
	float FollowLag = 10.0f;

	UPROPERTY(Category = FollowSetup)
	FVector FollowTargetLocalOffset = FVector(-20.0f, 250.0f, 150.0f);

	// Roughly how far behind the key will be when following a devil bird.
	UPROPERTY(Category = DevilBird)
	float DevilBirdOffsetDistance = 400.0f;

	// How far away from the player the key will be.
	UPROPERTY(Category = Player)
	float PlayerOffsetDistance = 400.0f;

	// How fast the key will rotate around the player
	UPROPERTY(Category = Player)
	float RotationSpeed = 0.45f;

	UPROPERTY(Category = FollowSetup)
	float LocalRotationSpeed = 90.0f;

	UPROPERTY(Category = FollowSetup)
	float UpDownSpeed = 0.45f;

	UPROPERTY(Category = FollowSetup)
	float UpDownLength = 35.0f;

	UPROPERTY(Category = ApproachTargetLocation)
	float ApproachTargetLocationSpeed = 700.0f;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartKeyMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopKeyMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KeyFollowPlayerAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KeyFollowDevilAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KeyInsertAudioEvent;

	// Played when the key has reached its destination.
	UPROPERTY(Category = VFX)
	UNiagaraSystem UnlockVFX;

	UPROPERTY()
	AKeyBirdCombatArea CombatArea;

	UPROPERTY()
	FOnPickedUpByActor OnPickedUp;

	UPROPERTY()
	int TempID = 0;

	// If an actor has MusicKeyLocatorCapability, this key can be picked up automatically.
	UPROPERTY()
	bool bAllowAutoPickup = true;

	UPROPERTY()
	bool bShouldHaveBeam = false;

	AHazeActor HazeOwner;

	AHazeActor KeyOwner;	// The Actor that is currently owning this key.

	TArray<AHazeActor> WantedOwnerList;	// Fill this list with owners that wants to own this key, select the first one if none exists from Control.

	// A location that the key will move towards
	UPROPERTY(Category = Objective)
	AMusicalKeyDestination TargetLocationActor;

	// And actor that the key will follow
	UPROPERTY(Category = Objective)
	AHazeActor FollowTarget;

	EMusicalKeyState MusicKeyState = EMusicalKeyState::Idle;

	private TArray<AHazeActor> PendingFollowTargets;

	private bool bHasReachedTargetLocation = false;
	bool HasReachedTargetLocation() const { return bHasReachedTargetLocation; }

	bool bDisableKey = false;
	bool bIsUsed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"MusicKeyFollowPlayerCapability");
		AddCapability(n"MusicKeyFollowCapability");
		AddCapability(n"MusicKeyApproachLocationCapability");
		AddCapability(n"MusicKeyIdleMovementCapability");

		SetupMusicalFollowerKey(this);

		devEnsure(CombatArea != nullptr, "Unable to locate a combat area. Please place at least one KeyBirdCombatArea somewhere in the level.");

		KeyTrail.SetTranslucentSortPriority(4);
		KeyGlow.SetTranslucentSortPriority(4);
		KeyTrailTwo.SetTranslucentSortPriority(4);
	}

	void SetTrailActive(bool bActive, bool bEffectAllTrails)
	{
		if(bActive)
		{
			if(bEffectAllTrails)
				KeyTrail.Activate();

			KeyTrailTwo.Activate();
		}
		else
		{
			if(bEffectAllTrails)
				KeyTrail.Deactivate();
				
			KeyTrailTwo.Deactivate();
		}

	}

	void SetGlowActive(bool bActive)
	{
		if(bActive)
		{
			KeyGlow.Activate();
		}
			
		else
			KeyGlow.Deactivate();
	}

	void PlayUnlockVFX()
	{
		if(UnlockVFX != nullptr)
		{
			Niagara::SpawnSystemAtLocation(UnlockVFX, ActorCenterLocation);
			HazeAkComp.HazePostEvent(KeyInsertAudioEvent);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(CombatArea == nullptr)
			CombatArea = Cast<AKeyBirdCombatArea>(FindClosestBoidArea(ActorLocation));
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		LeaveTeam(n"MusicalKeyTeam");
	}

	UFUNCTION(BlueprintCallable)
	void ActivateFollower()
	{

	}

	void ClearPendingTarget_Local(AHazeActor InPendingFollowTarget)
	{
		PendingFollowTargets.Remove(InPendingFollowTarget);
	}

	bool ContainsPendingTarget(AHazeActor PendingFollowTarget) const
	{
		return PendingFollowTargets.Contains(PendingFollowTarget);
	}

	UFUNCTION()
	void AddPendingFollowTarget(AHazeActor NewPendingTarget)
	{
		if(bHasReachedTargetLocation)
			return;

		NetAddPendingFollowTarget(NewPendingTarget);
	}

	UFUNCTION(NetFunction)
	private void NetAddPendingFollowTarget(AHazeActor NewPendingTarget)
	{
		PendingFollowTargets.AddUnique(NewPendingTarget);

		if(IsActorDisabled())
			EnableActor(nullptr);
	}

	bool HasPendingTargets() const
	{
		return PendingFollowTargets.Num() > 0;
	}

	void ClearFollowTarget()
	{
		if(!HasControl())
			return;

		if(FollowTarget == nullptr)
			return;

		NetClearFollowTarget(FollowTarget);
	}

	bool IsUsed() const { return bIsUsed; }

	UFUNCTION(NetFunction)
	private void NetClearFollowTarget(AHazeActor InFollowTarget)
	{
		FollowTarget = InFollowTarget;
		Handle_OnLost(FollowTarget, this);
		FollowTarget = nullptr;
		MusicKeyState = EMusicalKeyState::Idle;
	}

	private void SetFollowTarget(AHazeActor NewFollowTarget)
	{
		NetSetFollowTarget(NewFollowTarget);
	}

	void ClearFollowTarget_Local()
	{
		if(FollowTarget == nullptr)
			return;

		Handle_OnLost(FollowTarget, this);
		FollowTarget = nullptr;
		MusicKeyState = EMusicalKeyState::Idle;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetSetFollowTarget(AHazeActor NewFollowTarget)
	{
		if(IsActorDisabled())
			EnableActor(nullptr);

		if(HasFollowTarget())
		{
			Handle_OnLost(FollowTarget, this);
			FollowTarget = nullptr;
		}

		Handle_OnPickedUp(NewFollowTarget, this);
		FollowTarget = NewFollowTarget;
		PendingFollowTargets.Reset();
		MusicKeyState = EMusicalKeyState::FollowTarget;
		SetControlSide(NewFollowTarget);
		//OnNewFollowTarget.Broadcast(NewFollowTarget);

		AHazePlayerCharacter PlayerFollower = Cast<AHazePlayerCharacter>(NewFollowTarget);
		if(PlayerFollower != nullptr)
		{
			PlayerFollower.PlayerHazeAkComp.HazePostEvent(KeyFollowPlayerAudioEvent);
		}
		// If following Devil
		else
		{
			HazeAkComp.HazePostEvent(KeyFollowDevilAudioEvent);
		}
	}

	void SetActivateFollower(AHazeActor NewTargetToFollow)
	{
		
	}

	void HandleFoundTargetDestination()
	{

	}

	bool HasFollowTarget() const
	{
		return FollowTarget != nullptr;
	}

	UFUNCTION()
	void AddWantedKeyOwner(AHazeActor WantedOwner)
	{
		NetAddWantedOwner(WantedOwner);
	}

	UFUNCTION(NetFunction)
	private void NetAddWantedOwner(AHazeActor WantedOwner)
	{
		if(!WantedOwnerList.Contains(WantedOwner))
		{
			WantedOwnerList.Add(WantedOwner);
		}
	}

	void RemoveWantedOwner(AHazeActor WantedOwner)
	{
		NetRemoveWantedOwner(WantedOwner);
	}

	UFUNCTION(NetFunction)
	void NetRemoveWantedOwner(AHazeActor WantedOwner)
	{
		WantedOwnerList.Remove(WantedOwner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl() && HasFollowTarget())
		{
			if(FollowTarget.IsActorBeingDestroyed())
				ClearFollowTarget();
		}
		
		if(HasControl() && HasPendingTargets() && MusicKeyState == EMusicalKeyState::Idle && !bDisableKey)
		{
			AHazeActor PendingTarget = PendingFollowTargets[0];
			SetFollowTarget(PendingTarget);
		}
	}

	bool IsKeyOwnerPlayer() const
	{
		return Cast<AHazePlayerCharacter>(KeyOwner) != nullptr;
	}

	UFUNCTION()
	void MoveToTargetLocation()
	{
		HandleFoundTargetDestination();
		
		//Trigger something in a capability and state to make it move to a target location.
	}

	void ReachedTargetLocation()
	{
		if(bHasReachedTargetLocation)
			return;

		if(TargetLocationActor != nullptr)
			SetActorLocationAndRotation(TargetLocationActor.ActorLocation, TargetLocationActor.ActorRotation);

		OnReachedTargetDestination.Broadcast();
		bHasReachedTargetLocation = true;
		PlayUnlockVFX();
		DisableComp.SetbRenderWhileDisabled(true);
		if(!IsActorDisabled())
			DisableActor(nullptr);
	}

	// Only used in debug, testing purposes
	void DestroyKey()
	{
		bDisableKey = true;
		ClearFollowTarget();
		SetLifeSpan(1.0f);
	}
}
