import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractComponent;
import void SetNewSwivelDoor(AHazePlayerCharacter, AHopscotchDungeonSwivelDoor) from "Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSwiverDoorComponent";
import Peanuts.AutoMove.CharacterAutoMoveComponent;

event void FDoorRotationEvent();

class AHopscotchDungeonSwivelDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BlockingBox;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent MayInteraction;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent CodyInteraction;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteractComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent MayPlacement;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent RotatePoi;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MayPoiComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CodyPoiComp;

	UPROPERTY(DefaultComponent, Attach = MayPlacement)
	UHazeSkeletalMeshComponentBase MayPreviewLocation;
	default MayPreviewLocation.bIsEditorOnly = true;
	default MayPreviewLocation.bHiddenInGame = true;
	default MayPreviewLocation.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent CodyPlacement;

	UPROPERTY(DefaultComponent, Attach = CodyPlacement)
	UHazeSkeletalMeshComponentBase CodyPreviewLocation;
	default CodyPreviewLocation.bIsEditorOnly = true;
	default CodyPreviewLocation.bHiddenInGame = true;
	default CodyPreviewLocation.CollisionEnabled = ECollisionEnabled::NoCollision;	

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SeqLocation;

	UPROPERTY()
	FHazeTimeLike RotateDoorTimeline;
	default RotateDoorTimeline.Duration = RotateDoorDuration;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorRotateAudioEvent;

	UPROPERTY()
	FDoorRotationEvent DoorAboutToRotate;

	UPROPERTY()
	FDoorRotationEvent DoorRotated;	

	// Duration of the RotateDoor Timeline.
	UPROPERTY()
	float RotateDoorDuration = 0.75f;

	// Delay between when both players interacting and when the door starts rotating.
	UPROPERTY()
	float RotationDelay = 1.f;

	bool bShouldTickRotationDelay = false;

	// Delay between when the door is finished rotating and when the players get control.
	UPROPERTY()
	float DisableDelay = 0.15f;

	UPROPERTY()
	float AutoMoveDuration = 1.5f;

	UPROPERTY()
	bool bStartDisabled = false;

	float CoolDownTimer = AutoMoveDuration;
	bool bShouldTickCooldownTimer = false;
	
	float RotateDoorTimer = RotateDoorDuration + DisableDelay;
	bool bShouldTickRotationTimer = false;

	bool bDoorHasRotated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		MayInteraction.OnActivated.AddUFunction(this, n"OnInteracted");
		CodyInteraction.OnActivated.AddUFunction(this, n"OnInteracted");

		DoubleInteractComp.OnTriggered.AddUFunction(this, n"BothPlayersOnDoor");
		
		RotateDoorTimeline.BindUpdate(this, n"RotateDoorTimelineUpdate");

		if (bStartDisabled)
		{
			MayInteraction.Disable(n"StartedDisabled");
			CodyInteraction.Disable(n"StartedDisabled");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickRotationDelay)
		{
			RotationDelay -= DeltaTime;
			if (RotationDelay <= 0.f)
			{
				bShouldTickRotationDelay = false;
				bShouldTickRotationTimer = true;
				RotateDoorTimeline.PlayFromStart();
				UHazeAkComponent::HazePostEventFireForget(DoorRotateAudioEvent, this.GetActorTransform());
			}
		}

		if (bShouldTickRotationTimer)
		{
			RotateDoorTimer -= DeltaTime;
			if (RotateDoorTimer <= 0.f)
			{
				bShouldTickRotationTimer = false;
				bShouldTickCooldownTimer = true;
				for(auto Player : Game::GetPlayers())
					Player.SetCapabilityActionState(n"DoneWithDoor", EHazeActionState::Active);
				
			}
		}

		if (bShouldTickCooldownTimer)
		{
			CoolDownTimer -= DeltaTime;
			if (CoolDownTimer <= 0.f)
			{
				bShouldTickRotationTimer = false;
				DoorRotated.Broadcast();
			}
		}
	}

	UFUNCTION(CallInEditor)
	void TestFunctionHello()
	{
		TArray<AActor> Actors;
		Gameplay::GetAllActorsWithTag(n"Seq", Actors);

		for (auto Actor : Actors)
			Actor.SetActorLocation(SeqLocation.WorldLocation);
	}

	UFUNCTION()
	void RotateDoorTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(0.f, 180.f, 0.f), CurrentValue));
	}

	UFUNCTION()
	void RotateDoor()
	{
		bShouldTickRotationDelay = true;
		bDoorHasRotated = true;
		DoorAboutToRotate.Broadcast();

		FHazePointOfInterest PoiCody;
		PoiCody.FocusTarget.Component = RotatePoi;
		PoiCody.Duration = 2.5f;
		PoiCody.Blend = 0.5f;
		Game::GetCody().ApplyPointOfInterest(PoiCody, this);

		FHazePointOfInterest PoiMay;
		PoiMay.FocusTarget.Component = RotatePoi;
		PoiMay.Duration = 2.5f;
		PoiMay.Blend = 0.5f;
		Game::GetMay().ApplyPointOfInterest(PoiMay, this);
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		DoubleInteractComp.StartInteracting(Player);
		Component.Disable(n"PlayerInteracted");
		SetNewSwivelDoor(Player, this);
	}

	UFUNCTION()
	void BothPlayersOnDoor()
	{
		Sync::FullSyncPoint(this, n"EnableDoorRotation");
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableDoorRotation()
	{
		RotateDoor();
	}

	UFUNCTION()
	void PlayerStoppedUsingDoor(AHazePlayerCharacter Player)
	{
		DoubleInteractComp.CancelInteracting(Player);

		if (!bDoorHasRotated)
		{
			if (Player.IsCody())
				CodyInteraction.EnableAfterFullSyncPoint(n"PlayerInteracted");
			else
				MayInteraction.EnableAfterFullSyncPoint(n"PlayerInteracted");
		}
	}

	UFUNCTION()
	void EnableDoor()
	{
		MayInteraction.Enable(n"StartedDisabled");
		CodyInteraction.Enable(n"StartedDisabled");
	}
}