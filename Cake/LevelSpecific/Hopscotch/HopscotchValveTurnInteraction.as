import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Cake.LevelSpecific.Hopscotch.BallFallTube;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Spline.SplineComponentActor;
import Peanuts.Audio.AudioStatics;

class AHopscotchValveTurnInteraction : AValveTurnInteractionActor
{
	UPROPERTY()
	AHazeCameraActor ConnectedCamera;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	UPROPERTY()
	UAkAudioEvent InteractionStart;
	UPROPERTY()
	UAkAudioEvent InteractionCancelled;
	UPROPERTY()
	UAkAudioEvent InteractionFinished;

	FHazeAkRTPC AudioDeltaRTPC = FHazeAkRTPC("Rtpc_Hopscotch_BallFall_Valve_Turn_Delta");
	FHazeAkRTPC AudioProgressionRTPC = FHazeAkRTPC("Rtpc_Hopscotch_BallFall_Valve_Turn_Progression");

	UPROPERTY(DefaultComponent, Attach = EnterInteraction)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY()
	float CurrentLerpValue = 0.f;
	
	UPROPERTY()
	FRotator InitRot = FRotator::ZeroRotator;
	
	UPROPERTY()
	FRotator TargetRot = FRotator(0.f, 720.f, 0.f);

	UPROPERTY()
	UCurveFloat BallfallSpawnCurve;

	UPROPERTY()
	ABallFallTube ConnectedBallFall;

	UPROPERTY()
	TArray<ABallFallTube> ConnectedBallFallArray;

	UPROPERTY()
	EValveColor ValveColor;

	UPROPERTY()
	ASplineNiagaraSystemActor ConnectedNiagaraSpline;

	UPROPERTY()
	AActor ConnectedPointOfInterestActor;

	TArray<UNiagaraComponent> NiagaraArray;

	float SyncValueLastTick = 0.f;

	AHazePlayerCharacter PlayerInteracting;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// NOTE (GK) This property seems to be broken in cooks, can't see if it's been in the BP before then moved to as
		// And therefore being broken, but rather then resaving the asset I get the component, thus preserving the settings of HazeAkComp.
		// Maybe the asset should be resaved with a different name, but this should be a quick fix for the crashes in cooks.
		if (HazeAkComp == nullptr)
		{
			UHazeAkComponent ExistingHazeAkComp = UHazeAkComponent::Get(this);
			HazeAkComp = ExistingHazeAkComp;
		}

		EnterInteraction.AddActionPrimitive(EnterInteractionActionShape);
		EnterInteraction.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		SetActorTickEnabled(false);
		Capability::AddPlayerCapabilityRequest(n"ValveTurnInteractionCapability", EHazeSelectPlayer::Both);

		TArray<UActorComponent> TempNiagaraArray;
		if (ConnectedNiagaraSpline != nullptr)
			ConnectedNiagaraSpline.GetAllComponents(UNiagaraComponent::StaticClass(), TempNiagaraArray);

		for (UActorComponent Comp : TempNiagaraArray)
		{
			UNiagaraComponent FXComp = Cast<UNiagaraComponent>(Comp);
			if (FXComp != nullptr)
				NiagaraArray.Add(FXComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason) override
	{
		Capability::RemovePlayerCapabilityRequest(n"ValveTurnInteractionCapability", EHazeSelectPlayer::Both);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentLerpValue = SyncComponent.Value / MaxValue;
		// Doing the MeshRotation in BP
	
		if (ConnectedBallFall != nullptr && PlayerInteracting != nullptr)
			ConnectedBallFall.SetBallFallSpawnRate(ValveColor, CurrentLerpValue, PlayerInteracting);

		if (ConnectedBallFallArray.Num() > 0 && PlayerInteracting != nullptr)
		{
			for(auto BallFall : ConnectedBallFallArray)
				BallFall.SetBallFallSpawnRate(ValveColor, CurrentLerpValue, PlayerInteracting);
		}

		
		float NiagaraSplineSpawnRate = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(100.f, 0.f), CurrentLerpValue);

		AudioValveTurnProgression(SyncComponent.Value / MaxValue);
		
		for (UNiagaraComponent Comp : NiagaraArray)
			Comp.SetFloatParameter(n"User.SpawnRate", NiagaraSplineSpawnRate);
		

		AudioValveTurnDelta(SyncComponent.Value - SyncValueLastTick);
		SyncValueLastTick = SyncComponent.Value;
	}

    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Super::OnInteractionActivated(Component, Player);
		PlayerInteracting = Player;
		HazeAudio::SetPlayerPanning(HazeAkComp, Player);
		AudioInteractionStart();
		SetActorTickEnabled(true);
		ShowCancelPrompt(Player, this);
		
		if (ConnectedCamera == nullptr)
			return;

		FHazeCameraBlendSettings Blend;
		ConnectedCamera.ActivateCamera(PlayerInteracting, Blend, this); 
    }

	void EndInteraction(AHazePlayerCharacter Player) override
	{
		Super::EndInteraction(Player);
		RemoveCancelPromptByInstigator(Player, this);

		if (CurrentLerpValue == 1.f)
		{
			FHazePointOfInterest PointOfInterest;
			PointOfInterest.Duration = 2.f;
			PointOfInterest.FocusTarget.Actor = ConnectedPointOfInterestActor;
			Player.ApplyPointOfInterest(PointOfInterest, this);
			AudioInteractionFinished();
		}
		else
			AudioInteractionCanceled();

		if (ConnectedCamera != nullptr)
		{
			PlayerInteracting.DeactivateCameraByInstigator(this);
		}

		PlayerInteracting = nullptr;
		SetActorTickEnabled(false);
	}

	// UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioInteractionStart()
	{
		if (InteractionStart != nullptr)
			HazeAkComp.HazePostEvent(InteractionStart);
	}

	// UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioInteractionCanceled()
	{
		if (InteractionCancelled != nullptr)
			HazeAkComp.HazePostEvent(InteractionCancelled);
	}

	// UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioInteractionFinished()
	{
		if (InteractionFinished != nullptr)
			HazeAkComp.HazePostEvent(InteractionFinished);
	}

	// UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioValveTurnDelta(float TurnDelta)
	{
		HazeAkComp.SetRTPCValue(AudioDeltaRTPC, TurnDelta);
	}

	// UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioValveTurnProgression(float Value)
	{
		HazeAkComp.SetRTPCValue(AudioProgressionRTPC, Value);
	}
}