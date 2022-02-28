import Vino.Pickups.PickupActor;

event void FPlayAnimationEventSignature();

class ATrainstationFigure : APickupActor
{
	default InteractionComponent.FocusShapeTransform.Scale3D = FVector(12.f, 12.f, 12.f);

	// Add little carry offset for Cody
	default PickupOffsetCody.SetLocation(FVector(-20.f, 0.f, 0.f));

	UPROPERTY()
	UAnimSequence Enter;

	UPROPERTY()
	UAnimSequence MH;

	UPROPERTY()
	UAnimSequence Exit;

	UPROPERTY()
	FPlayAnimationEventSignature OnPlayAnimation;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent KissingStream;
	default KissingStream.bAutoActivate = false;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PickedUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DroppedAudioEvent;

	UPROPERTY()
	UMaterialInterface OverrideMHMaterial;

	UPROPERTY()
	FPlayAnimationEventSignature OnReverseAnimation;

	UPROPERTY()
	UHazeCapabilitySheet SheetToPushWhenPickedUp;

	UMaterialInterface StartMaterial;

	UHazeSkeletalMeshComponentBase FigureMesh;

	UPROPERTY()
	TArray<AHazeActor> InteractionsToDisable;

	UBoxComponent BoxComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		FigureMesh = Cast<UHazeSkeletalMeshComponentBase>(Mesh);

		StartMaterial = FigureMesh.GetMaterial(0);

		KissingStream.Deactivate();
		OnPickedUpEvent.AddUFunction(this, n"OnPickup");
		OnPlacedOnFloorEvent.AddUFunction(this, n"OnDropped");

		// This is the box component created in BP
		BoxComponent = UBoxComponent::Get(this, n"Box");
	}

	UFUNCTION()
	void OnPickup(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		PlayerCharacter.AddCapabilitySheet(SheetToPushWhenPickedUp, Instigator = this);
		UHazeAkComponent::HazePostEventFireForget(PickedUpAudioEvent, this.GetActorTransform());

		// Turn off pickup collisions when picking up
		BoxComponent.SetCollisionProfileName(n"NoCollision");

		for (auto i : InteractionsToDisable)
		{
			for (auto j : i.GetComponentsByClass(UInteractionComponent::StaticClass()))
			{
				UInteractionComponent Interaction = Cast<UInteractionComponent>(j);
				Interaction.DisableForPlayer(PlayerCharacter, n"CarryingFigure");
			}


			AHazeInteractionActor InteractionActor = Cast<AHazeInteractionActor>(i);
			if (InteractionActor != nullptr)
			{
				InteractionActor.DisableInteractionForPlayer(PlayerCharacter, n"CarryingFigure");
			}
		}
	}

	UFUNCTION()
	void OnDropped(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		PlayerCharacter.RemoveCapabilitySheet(SheetToPushWhenPickedUp, this);

		// Turn on pickup collisions when it reaches floor
		BoxComponent.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");

		UHazeAkComponent::HazePostEventFireForget(DroppedAudioEvent, this.GetActorTransform());

		for (auto i : InteractionsToDisable)
		{
			for (auto j : i.GetComponentsByClass(UInteractionComponent::StaticClass()))
			{
				UInteractionComponent Interaction = Cast<UInteractionComponent>(j);
				Interaction.EnableForPlayer(PlayerCharacter, n"CarryingFigure");
			}

			AHazeInteractionActor InteractionActor = Cast<AHazeInteractionActor>(i);
			if (InteractionActor != nullptr)
			{
				InteractionActor.EnableInteractionForPlayer(PlayerCharacter, n"CarryingFigure");
			}
		}
	}

	UFUNCTION()
	void PlayAnimation()
	{
		FHazeAnimationDelegate OnEnter;
		FHazeAnimationDelegate OnExit;
		FHazePlaySlotAnimationParams SlotAnimParams;
		SlotAnimParams.Animation = Enter;
		SlotAnimParams.bLoop = false;
		OnExit.BindUFunction(this, n"PlayMH");
		FigureMesh.PlaySlotAnimation(OnEnter, OnExit, SlotAnimParams);

		if (OverrideMHMaterial != nullptr)
		{
			FigureMesh.SetMaterial(0, OverrideMHMaterial);
		}
		
		OnPlayAnimation.Broadcast();
	}
	
	UFUNCTION(NotBlueprintCallable)
	void PlayMH()
	{
		FHazeAnimationDelegate Delegate;
		FHazePlaySlotAnimationParams SlotAnimParams;
		SlotAnimParams.Animation = MH;
		SlotAnimParams.bLoop = true;
		FigureMesh.PlaySlotAnimation(Delegate, Delegate, SlotAnimParams);
		KissingStream.Activate();
	}

	UFUNCTION()
	void PlayAnimationReverse()
	{
		FHazeAnimationDelegate Delegate;
		FHazePlaySlotAnimationParams SlotAnimParams;
		SlotAnimParams.Animation = Exit;
		SlotAnimParams.bPauseAtEnd = true;
		SlotAnimParams.bLoop = false;

		FigureMesh.PlaySlotAnimation(Delegate, Delegate, SlotAnimParams);

		if (FigureMesh.GetMaterial(0) != StartMaterial)
		{
			FigureMesh.SetMaterial(0, StartMaterial);
		}
		
		KissingStream.Deactivate();
		OnReverseAnimation.Broadcast();
	}
}