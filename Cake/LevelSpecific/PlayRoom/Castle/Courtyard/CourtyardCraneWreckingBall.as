import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardDestroyableActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneAttachedActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleWreckingDoor;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;

event void FOnGateDestroyed();
event void FOnAttachComplete();

class ACourtyardCraneWreckingBall : ACourtyardCraneAttachedActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MagnetMesh;
	default MagnetMesh.SetRelativeLocation(FVector(0,0,445));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachPointMagnet;
	default AttachPointMagnet.SetRelativeLocation(FVector(0,0,465));

	UPROPERTY(DefaultComponent, Attach = AttachPointMagnet)
	UStaticMeshComponent EditorMagnetMesh;
	default EditorMagnetMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent LeftInteractComp;
	default LeftInteractComp.SetRelativeLocation(FVector(-445.f, -150.f, -105.f));
	default LeftInteractComp.SetRelativeRotation(FRotator(0.f, 15.f, 0.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent RightInteractComp;
	default RightInteractComp.SetRelativeLocation(FVector(-435.f, 140.f, -100.f));
	default RightInteractComp.SetRelativeRotation(FRotator(0.f, -15.f, 0.f));

	UPROPERTY(DefaultComponent, Attach = LeftInteractComp)
	USkeletalMeshComponent EditorMeshLeft;
	default EditorMeshLeft.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = RightInteractComp)
	USkeletalMeshComponent EditorMeshRight;
	default EditorMeshRight.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent CollisionTrigger;
	default CollisionTrigger.SphereRadius = 440;
	default CollisionTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CollisionTrigger.SetCollisionResponseToChannel(ECollisionChannel::ECC_Destructible, ECollisionResponse::ECR_Overlap);
	default CollisionTrigger.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent MayAccelerationStrengthSyncFloat;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent CodyAccelerationStrengthSyncFloat;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent MayBSSyncFloat;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent CodyBSSyncFloat;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	TPerPlayer<bool> PlayersInteractingWithCrane;

	UPROPERTY()
	AActor CancelJumpToLocation;
	
	default SphereTrigger.SetRelativeLocation(FVector(0,0,400));

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeCapability> CourtyardCraneWreckingBallCapability;

	UPROPERTY()
	FOnGateDestroyed OnGateDestroyedEvent;
	UPROPERTY()
	FOnAttachComplete OnAttachComplete;

	AHazePlayerCharacter LeftPlayer;
	AHazePlayerCharacter RightPlayer;

	UPROPERTY()
	UForceFeedbackEffect HitDoorForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HitDoorCameraShake;

	bool bCutsceneStarted = false;

	int DoorHits = 0;
	const int RequiredDoorHits = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		LeftInteractComp.OnActivated.AddUFunction(this, n"OnLeftInteracted");
		RightInteractComp.OnActivated.AddUFunction(this, n"OnRightInteracted");

		LeftInteractComp.Disable(n"Connected");
		RightInteractComp.Disable(n"Connected");

		MayAccelerationStrengthSyncFloat.OverrideControlSide(Game::GetMay());
		CodyAccelerationStrengthSyncFloat.OverrideControlSide(Game::GetCody());
		MayBSSyncFloat.OverrideControlSide(Game::GetMay());
		CodyBSSyncFloat.OverrideControlSide(Game::GetCody());
	}

	void AttachToCrane(AHazeActor CraneActor, USceneComponent ConstraintPoint)
	{
		Super::AttachToCrane(CraneActor, ConstraintPoint);

		// Disable overlap events once it's been attached to save performance.
		CollisionTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		SphereTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		SetCapabilityActionState(n"Attached", EHazeActionState::Active);

		SetActorTickEnabled(true);

		if(HasControl())
			OnAttachComplete.Broadcast();
	}

	UFUNCTION()
	void OnLeftInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapability(CourtyardCraneWreckingBallCapability);
		Player.SetCapabilityActionState(n"SwingingWreckingBall", EHazeActionState::Active);
		Player.SetCapabilityAttributeObject(n"BallActor", this);
		Player.SetCapabilityAttributeObject(n"AttachComp", LeftInteractComp);
		Player.SetCapabilityAttributeObject(n"InteractComp", InteractComp);
		LeftInteractComp.Disable(n"InUse");

		LeftPlayer = Player;
	}

	UFUNCTION()
	void OnRightInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapability(CourtyardCraneWreckingBallCapability);
		Player.SetCapabilityActionState(n"SwingingWreckingBall", EHazeActionState::Active);
		Player.SetCapabilityAttributeObject(n"BallActor", this);
		Player.SetCapabilityAttributeObject(n"AttachComp", RightInteractComp);
		Player.SetCapabilityAttributeObject(n"InteractComp", InteractComp);
		RightInteractComp.Disable(n"InUse");

		RightPlayer = Player;
	}

	void BallDeactivated(UInteractionComponent InteractComp)
	{
		InteractComp.Enable(n"InUse");		
	}

	UFUNCTION()
	void BroadcastCutscene()
	{
		if (!bCutsceneStarted)
		{
			bCutsceneStarted = true;
			OnGateDestroyedEvent.Broadcast();
		}
	}

	UFUNCTION(NetFunction)
	void NetHitDoor(ACastleWreckingDoor WreckingDoor, float Scale)
	{
		WreckingDoor.HitByWreckingBall(Scale);
		AngularVelocity = -AngularVelocity;
		AngularVelocity *= 0.75f;

		if (HitDoorForceFeedback != nullptr)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayForceFeedback(HitDoorForceFeedback, false, false, NAME_None, Scale * 1.4f);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetBreakActor(ACastleCourtyardDestroyableActor BreakActor, FBreakableHitData BreakData)
	{
		for (ACastleCourtyardDestroyableActor Destroyable : BreakActor.MutuallyDestroyed)
		{
			if (Destroyable == nullptr)
				continue;
				
			if (!Destroyable.BreakComp.Broken)
				Destroyable.BreakComp.Break(BreakData);
		}

		if (!BreakActor.BreakComp.Broken)
			BreakActor.BreakComp.Break(BreakData);
	}
}