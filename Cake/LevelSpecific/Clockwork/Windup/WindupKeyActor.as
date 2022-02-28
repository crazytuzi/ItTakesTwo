import Cake.Interactions.Windup.WindupActor;
import Cake.Interactions.Windup.LocomotionFeatureWindup;
import Vino.Pickups.PlayerPickupComponent;
import Vino.Pickups.PickupActor;

event void FOnKeyInsertedEvent(AWindupActor WindupActor);

class AWindupKeyActor : AWindupActor
{
	UPROPERTY(Category = "Windup")
	bool bStartWithKeyInserted = true;

	UPROPERTY(Category = "Windup")
	bool bAnyInputIsValidInput = false;

	// If true, this actor will count as 'Finished' when it has been winded up
	UPROPERTY(Category = "Windup")
	bool bFinishAtEnd = true;

	UPROPERTY(Category = "Windup", meta = (EditCondition = "!bStartWithKeyInserted", EditConditionHides))
	FName RequiredPickupableComponentTag = NAME_None;

	UPROPERTY(Category = "Windup", AdvancedDisplay)
	ULocomotionFeatureWindup CodyFeature;

	UPROPERTY(Category = "Windup", AdvancedDisplay)
	ULocomotionFeatureWindup MayFeature;

	// The effect that is played when trying to move but can't
	UPROPERTY(Category = "Windup", AdvancedDisplay)
	UForceFeedbackEffect TryMovingEffect = nullptr;

	// The effect that is played when moving
	UPROPERTY(Category = "Windup", AdvancedDisplay)
	UForceFeedbackEffect MovingEffect = nullptr;

	// The effect that is played when reached the end
	UPROPERTY(Category = "Windup", AdvancedDisplay)
	UForceFeedbackEffect FinishedEffect = nullptr;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem OnKeyInsertedEffect;
	
	/** When the key is putdown, there is a delay when it lerps to the correct location
	 * @bPlayKeyInsertedEffectWhenTheKeyInserts: 
	 * true; will fire the 'OnKeyInsertedEffect' when the key has finished lerping and the 'OnKeyInsertedEvent' fires
	 * false; will fire the 'OnKeyInsertedEffect' as soon as the player put down the key
	*/
	UPROPERTY(Category = "Effects")
	bool bPlayKeyInsertedEffectWhenTheKeyInserts = true;

	UPROPERTY()
	FOnWindupFinishedEvent OnKeyInsertedEvent;
	
	// Attach Key
	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent AttachKeyInteraction;
	default AttachKeyInteraction.ActionShape.InitializeAsBox(FVector(300.f, 300.f, 200.f));
	default AttachKeyInteraction.FocusShape.InitializeAsBox(FVector(300.f, 300.f, 200.f));

	AActor KeyToMove;
	FVector StartScale = FVector::OneVector;
	FVector TargetScale = FVector::OneVector;
	FHazeMinMax ScaleTimeLeft;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()override
	{
		Super::ConstructionScript();
		Mesh.SetVisibility(bStartWithKeyInserted);
	}

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		Super::BeginPlay();

		Mesh.SetVisibility(true);
		if(bStartWithKeyInserted)
		{
			AttachKey();
		}
		else
		{
			Mesh.SetHiddenInGame(true);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
				
		FHazeTriggerCondition PushPullCondition;
		PushPullCondition.Delegate.BindUFunction(this, n"CanPlayerInteract");

		PushLeft.AddTriggerCondition(n"ActivationPoint", PushPullCondition);
		PullLeft.AddTriggerCondition(n"ActivationPoint", PushPullCondition);
		PushRight.AddTriggerCondition(n"ActivationPoint", PushPullCondition);
		PullRight.AddTriggerCondition(n"ActivationPoint", PushPullCondition);
		PushPullAll.AddTriggerCondition(n"ActivationPoint", PushPullCondition);

		FHazeTriggerCondition KeyInteractionCondition;
		KeyInteractionCondition.Delegate.BindUFunction(this, n"CanPlayerInteractWithKey");
		AttachKeyInteraction.AddTriggerCondition(n"ActivationKeyPoint", KeyInteractionCondition);
		
		FHazeTriggerActivationDelegate AttachKeyDelegate;
		AttachKeyDelegate.BindUFunction(this, n"OnKeyInserted");
		AttachKeyInteraction.AddActivationDelegate(AttachKeyDelegate);
	}

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		if(KeyToMove != nullptr)
		{
			const FTransform TargetTransform = Mesh.GetWorldTransform();

			FVector KeyLocation = KeyToMove.GetActorLocation();
			KeyLocation = FMath::VInterpTo(KeyLocation, TargetTransform.GetLocation(), DeltaTime, 1.f / 0.15f);

			FRotator KeyRotation = KeyToMove.GetActorRotation();
			KeyRotation = FMath::RInterpTo(KeyRotation, TargetTransform.Rotator(), DeltaTime, 1.f / 0.15f);	

			if(KeyLocation.DistSquared(TargetTransform.GetLocation()) < 1.f)
			{
				KeyToMove.SetActorLocationAndRotation(TargetTransform.GetLocation(), TargetTransform.Rotator());
				AttachKey(0.5f);
				KeyToMove.DestroyActor();
				KeyToMove = nullptr;
				SetActorTickEnabled(ScaleTimeLeft.Max > 0);

				if(OnKeyInsertedEvent.IsBound())
				{
					OnKeyInsertedEvent.Broadcast(this);
					if(bPlayKeyInsertedEffectWhenTheKeyInserts)
						Niagara::SpawnSystemAtLocation(OnKeyInsertedEffect, GetActorLocation(), GetActorRotation());
				}
			}
			else
			{
				KeyToMove.SetActorLocationAndRotation(KeyLocation, KeyRotation);
			}
		}
		else
		{
			Super::Tick(DeltaTime);
			if(ScaleTimeLeft.Max > 0)
			{
				ScaleTimeLeft.Min = FMath::Max(ScaleTimeLeft.Min - DeltaTime, 0.f);
				Mesh.SetRelativeScale3D(FMath::Lerp(TargetScale, StartScale, ScaleTimeLeft.Min / ScaleTimeLeft.Max));
				if(ScaleTimeLeft.Min <= 0)
				{
					ScaleTimeLeft = FHazeMinMax();
					SetActorTickEnabled(false);
				}
			}
		}
	}

	bool IsFinished(bool bIncludeTimeLeft = false) const override
	{
		if(!bFinishAtEnd)
			return false;
		
		return Super::IsFinished(bIncludeTimeLeft);
	}

	UFUNCTION()
	void AttachKey(float LerpTime = 0)
	{
		if(LerpTime > 0)
		{
			ScaleTimeLeft = FHazeMinMax(LerpTime, LerpTime);
			Mesh.SetRelativeScale3D(StartScale);
		}

		Mesh.SetHiddenInGame(false);
		Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerInteract(UHazeTriggerComponent TriggerComponet, AHazePlayerCharacter PlayerCharacter)
	{
		return !Mesh.bHiddenInGame;
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerInteractWithKey(UHazeTriggerComponent TriggerComponet, AHazePlayerCharacter PlayerCharacter)
	{
		if(RequiredPickupableComponentTag != NAME_None)
		{
			UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(PlayerCharacter);
			APickupActor PickupActor = Cast<APickupActor>(PickupComp.CurrentPickup);
			if(PickupActor == nullptr)
				return false;

			if(!PickupActor.ActorHasTag(RequiredPickupableComponentTag))
				return false;
		}

		// If the key is inserted, we can no longer interact with the key
		return !CanPlayerInteract(TriggerComponet, PlayerCharacter);
	}

	UFUNCTION(NotBlueprintCallable)
    void OnKeyInserted(UHazeTriggerComponent Component, AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(PlayerCharacter);
		APickupActor PickupActor = Cast<APickupActor>(PickupComp.CurrentPickup);
		PickupComp.ForceDrop(true);
		PickupActor.bCodyCanPickUp = false;
		PickupActor.bMayCanPickUp = false;
		PickupComp.OnPutDownEvent.AddUFunction(this, n"OnKeyPutDown");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnKeyPutDown(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(PlayerCharacter);
		PickupComp.OnPutDownEvent.UnbindObject(this);
		KeyToMove = PickupableActor;
		StartScale = PickupableActor.Mesh.GetRelativeScale3D();
		TargetScale = Mesh.GetRelativeScale3D();
		SetActorTickEnabled(true);

		if(!bPlayKeyInsertedEffectWhenTheKeyInserts)
			Niagara::SpawnSystemAtLocation(OnKeyInsertedEffect, GetActorLocation(), GetActorRotation());
	}
};