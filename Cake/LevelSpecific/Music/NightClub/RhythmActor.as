import Cake.LevelSpecific.Music.NightClub.RhythmComponent;
import Cake.LevelSpecific.Music.NightClub.RhythmData;
import Peanuts.Animation.Features.Music.LocomotionFeatureMusicDance;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Music.NightClub.BassDropOMeter;

void TempoHit(AHazeActor RhythmActor, ARhythmTempoActor TempoActor)
{
	ARhythmActor Rhythm = Cast<ARhythmActor>(RhythmActor);

	if(Rhythm != nullptr)
	{
		Rhythm.OnTempoHit(TempoActor);
	}
}

#if EDITOR

class URhythmActorDummyComponent : UActorComponent
{
	float RhythmActorDummyComponentVisualizerTime = 0.0f;
}

class URhythActorDummyComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = URhythmActorDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        URhythmActorDummyComponent Comp = Cast<URhythmActorDummyComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
		{
			return;
		}

		Comp.RhythmActorDummyComponentVisualizerTime += 0.1f;

		// Just visual fluff
		float R = FMath::MakePulsatingValue(Comp.RhythmActorDummyComponentVisualizerTime, 0.1f);
		float G = FMath::MakePulsatingValue(Comp.RhythmActorDummyComponentVisualizerTime, 0.2f);
		float B = FMath::MakePulsatingValue(Comp.RhythmActorDummyComponentVisualizerTime, 0.3f);

		ARhythmActor RhythmActor = Cast<ARhythmActor>(Comp.Owner);
		DrawWireSphere(RhythmActor.SphereTrigger.WorldLocation, RhythmActor.SphereTrigger.SphereRadius, FLinearColor(R, G, B), 3.0f, 12);

		const FVector DanceLocationWorldSpace = RhythmActor.ActorTransform.TransformPosition(RhythmActor.DanceLocation);
		DrawArrow(DanceLocationWorldSpace, DanceLocationWorldSpace - (FVector::UpVector * 500.0f), FLinearColor::Green, 20.0f, 5.0f);
    }   
}

#endif // EDITOR

UCLASS(Abstract)
class UPlayerRhythmComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	ARhythmActor RhythmDanceArea;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UPROPERTY()
	TArray<UAnimSequence> MayHitFailAnimations;

	UPROPERTY()
	TArray<UAnimSequence> CodyHitFailAnimations;

	UPROPERTY()
	UForceFeedbackEffect SuccessForceFeedback;

	void StartDancing()
	{
		bIsDancing = true;
		SetComponentTickEnabled(true);
	}

	void StopDancing()
	{
		bIsDancing = false;
		SetComponentTickEnabled(false);
	}

	UAnimSequence GetRandomHitFailAnimation() const property
	{
		TArray<UAnimSequence> HitFailAnimations = Player.IsMay() ? MayHitFailAnimations : CodyHitFailAnimations;

		if(HitFailAnimations.Num() == 0)
			return nullptr;

		if(HitFailAnimations.Num() == 1)
			return HitFailAnimations[0];

		int RandomIndex = FMath::RandRange(0, HitFailAnimations.Num() - 1);
		return HitFailAnimations[RandomIndex];
	}

	float DanceFailCooldown = 0.0f;

	UPROPERTY(EditDefaultsOnly, Category = ButtonSettings)
	TSubclassOf<ARhythmTempoActor> LeftFaceButton;

	UPROPERTY(EditDefaultsOnly, Category = ButtonSettings)
	TSubclassOf<ARhythmTempoActor> TopFaceButton;

	UPROPERTY(EditDefaultsOnly, Category = ButtonSettings)
	TSubclassOf<ARhythmTempoActor> RightFaceButton;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bLeftMiss = false;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bLeftHit = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bTopMiss = false;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bTopHit = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bRightMiss = false;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bRightHit = false;

	UPROPERTY()
	bool bRhythmActive = true;
	
	// Set to true in the rhythm capability, allowing dance moves to be activated.
	bool bIsDancing = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DanceFailCooldown -= DeltaTime;
	}

	UPROPERTY(Category = Animation)
	ULocomotionFeatureMusicDance CodyDance;

	UPROPERTY(Category = Animation)
	ULocomotionFeatureMusicDance MayDance;

	UFUNCTION(BlueprintPure)
	bool HasPressedAnyButton() const
	{
		return bLeftHit ||
		bLeftMiss ||
		bRightHit ||
		bRightMiss ||
		bTopHit ||
		bTopMiss;
	}
}

struct FRhythmTempoInfo
{
	// The actor that was hit successfully.
	UPROPERTY()
	ARhythmTempoActor HitActor;
}

struct FRhythmTempoFailInfo
{
	UPROPERTY()
	URhythmComponent Comp = nullptr;
	UPROPERTY()
	FName ActionName;
}

event void FOnRhythmTempoSuccess(FRhythmTempoInfo TempoInfo);
// This is whenever a tempo passes through.
event void FOnRhythmTempoFail(FRhythmTempoFailInfo FailInfo);

// For whenever the player presses the dance button but no valid tempo to hit is present.
event void FOnRhythmHitFail(URhythmComponent RhythmComponent);
event void FOnStopDancingSignature(ARhythmActor RhythmActor);

AHazePlayerCharacter GetCurrentDancer(AActor Owner)
{
	ARhythmActor RhythmActor = Cast<ARhythmActor>(Owner);
	if(RhythmActor != nullptr )
	{
		return RhythmActor.CurrentDancer;
	}

	return nullptr;
}

AHazePlayerCharacter GetLastDancer(AActor Owner)
{
	ARhythmActor RhythmActor = Cast<ARhythmActor>(Owner);
	if(RhythmActor != nullptr )
	{
		return RhythmActor.LastDancer;
	}

	return nullptr;
}

class ARhythmActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	URhythmComponent LeftFaceButton;
	default LeftFaceButton.RelativeLocation = FVector(-400.0f, 0.0f, 0.0f);
	default LeftFaceButton.ActionName = n"DanceLeft";

	UPROPERTY(meta = (MakeEditWidget))
	FVector LeftFaceButtonLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	URhythmComponent TopFaceButton;
	default TopFaceButton.RelativeLocation = FVector(0.0f, 0.0f, 0.0f);
	default TopFaceButton.ActionName = n"DanceTop";

	UPROPERTY(meta = (MakeEditWidget))
	FVector TopFaceButtonLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	URhythmComponent RightFaceButton;
	default RightFaceButton.RelativeLocation = FVector(400.0f, 0.0f, 0.0f);
	default RightFaceButton.ActionName = n"DanceRight";

	UPROPERTY(meta = (MakeEditWidget))
	FVector RightFaceButtonLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent SphereTrigger;
	default SphereTrigger.SetCollisionProfileName(n"PlayerCharacterOverlapOnly");
	default SphereTrigger.bAbsoluteScale = true;

	UPROPERTY()
	ABassDropOMeter BassDropOMeter;

	UPROPERTY()
	float SuccessValue = 0.004;

	UPROPERTY()
	float FailureValue = 0.01;

	int Internal_TempoID = 0;

	float PushTempoCooldown = 0.35f;
	float PushTempoElapsed = 0.0f;

	float TempoPushElapsed = 0.0f;

#if EDITOR
	UPROPERTY(DefaultComponent, Transient, NotVisible)
	URhythmActorDummyComponent RhythmActorComponentVisualizer;
#endif // EDITOR

	UPROPERTY()
	FOnRhythmTempoSuccess OnTempoSuccess;

	UPROPERTY()
	FOnRhythmTempoFail OnTempoFailed;

	UPROPERTY()
	FOnRhythmHitFail OnRhythmHitFailed;

	UPROPERTY()
	FOnStopDancingSignature OnStopDancing;

	UPROPERTY()
	FOnTempoStart OnTempoStart;

	UPROPERTY()
	FOnTempoSpawned OnTempoSpawned;

	UPROPERTY(meta = (MakeEditWidget))
	FVector DanceLocation;

	AHazePlayerCharacter CurrentDancer;
	AHazePlayerCharacter LastDancer;

	// for ease of use
	TArray<URhythmComponent> RhythmComponents;

	UPROPERTY()
	URhythmData RythmData;

	int CurrentIndex = 0;
	float PendingExitElapsed = 0.0f;

	FTimerHandle OverlapTimerHandle;

	// set this to false to disable spawning new tempo.
	private bool bRhytmActorActive = true;
	private bool bPendingStop = false;
	private bool bHasSentHandShake = false;
	int NetPendingStopCount = 0;

	UFUNCTION(BlueprintPure)
	bool IsRhythmActorActive() const
	{
		return bRhytmActorActive;
	}

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnHitLeftNote;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnHitMiddleNote;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnHitRightNote;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnMissNote;

	bool bCheckOverlap = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RhythmComponents.Add(LeftFaceButton);
		RhythmComponents.Add(TopFaceButton);
		RhythmComponents.Add(RightFaceButton);

		DanceLocation = ActorTransform.TransformPosition(DanceLocation);

		if(bCheckOverlap)
			OverlapTimerHandle = System::SetTimer(this, n"HandleOverlapTimerEnd", 0.25f, true);

		for(URhythmComponent Comp : RhythmComponents)
			Comp.OnTempoSpawned.AddUFunction(this, n"Handle_OnTempoSpawned");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		System::ClearAndInvalidateTimerHandle(OverlapTimerHandle);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TempoPushElapsed += DeltaTime;
		PushTempoElapsed -= DeltaTime;

		for(URhythmComponent CurrentRhythm : RhythmComponents)
		{
			if(CurrentRhythm.Failures > 0)
			{
				FRhythmTempoFailInfo FailInfo;
				FailInfo.Comp = CurrentRhythm;
				FailInfo.ActionName = CurrentRhythm.ActionName;

				BP_OnTempoFailed(FailInfo);
				OnTempoFailed.Broadcast(FailInfo);
				CurrentRhythm.Failures = 0;
				
				//These two lines were added by Per for BirdStar
				if (BassDropOMeter != nullptr)
					BassDropOMeter.RemoveFromMasterMeter(FailureValue);
			}
		}

		if(bPendingStop)
		{
			const bool bCanStopPending = CanStopPending();

			if(!bHasSentHandShake && Network::IsNetworked())
			{
				NetHandshakePendingStop();
				bHasSentHandShake = true;
			}

			PendingExitElapsed -= DeltaTime;
			if(PendingExitElapsed < 0.0f && bCanStopPending)
			{
				bPendingStop = false;
				bRhytmActorActive = false;
				OnStopDancing.Broadcast(this);
				SetActorTickEnabled(false);
				CleanupTempoActors();
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetHandshakePendingStop()
	{
		NetPendingStopCount--;
	}

	bool CanStopPending() const
	{
		if(Network::IsNetworked())
		{
			return NetPendingStopCount <= 0;
		}

		return true;
	}

	UFUNCTION(BlueprintCallable, Category = Rhythm)
	void PushNextTempo(float Tempo = 1.0f)
	{
		if(RythmData != nullptr)
		{
			TSubclassOf<ARhythmTempoActor> NewTempoClass = RythmData.GetRhythmTempoActor(CurrentIndex);
			CurrentIndex++;

			if(CurrentIndex >= RythmData.NumTempos - 1)
			{
				CurrentIndex = 0;
			}

			PushTempo(NewTempoClass, Tempo);
		}
	}

	UFUNCTION(BlueprintCallable, Category = Rhythm)
	void PushTempo(TSubclassOf<ARhythmTempoActor> TempoClass, float Tempo = 1.0f)
	{
		if(!HasControl())
			return;

		if(!TempoClass.IsValid() || !bRhytmActorActive || bPendingStop || PushTempoElapsed > 0.0f)
			return;

		NetPushTempo(TempoClass, Tempo);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetPushTempo(TSubclassOf<ARhythmTempoActor> TempoClass, float Tempo)
	{
		for(URhythmComponent CurrentRhythm : RhythmComponents)
		{
			if(CurrentRhythm.TempoClass.Get() == TempoClass.Get())
			{
				CurrentRhythm.PushTempo(Tempo);
			}
		}

		PushTempoElapsed = PushTempoCooldown;
		TempoPushElapsed = 0.0f;
	}

	ARhythmTempoActor TestTempo(TSubclassOf<ARhythmTempoActor> TempoClass)
	{
		for(URhythmComponent CurrentRhythm : RhythmComponents)
		{
			if(CurrentRhythm.TempoClass.Get() == TempoClass.Get())
			{
				return CurrentRhythm.TestTempo();
			}
		}

		return nullptr;
	}

	void OnTempoHit(ARhythmTempoActor TempoActor)
	{
		if(TempoActor == nullptr)
			return;

		NetOnTempoHit(TempoActor);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetOnTempoHit(ARhythmTempoActor TempoActor)
	{
		if(TempoActor == nullptr)
			return;

		FRhythmTempoInfo TempoInfo;
		TempoInfo.HitActor = TempoActor;
		OnTempoSuccess.Broadcast(TempoInfo);
		BP_OnTempoSuccess(TempoInfo);

		TempoActor.StopTempo();
		TempoActor.Handshake();
		
		//Added by Per for BirdStar
		if (BassDropOMeter != nullptr)
		{
			BassDropOMeter.AddToMasterMeter(SuccessValue);
		}
			

		for(URhythmComponent CurrentRhythm : RhythmComponents)
		{
			if(TempoActor.IsA(CurrentRhythm.TempoClass))
			{
				CurrentRhythm.OnTempoHit.Broadcast(TempoActor);
				break;
			}
		}
	}
	
	// From RhythmComponent
	UFUNCTION(NotBlueprintCallable)
	private void Handle_OnTempoSpawned(ARhythmTempoActor NewTempoActor)
	{
		OnTempoSpawned.Broadcast(NewTempoActor);
	}

	UFUNCTION()
	void CleanupTempoActors()
	{
		for(URhythmComponent CurrentRhythm : RhythmComponents)
		{
			CurrentRhythm.CleanupRhythmTempoActors();
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartRhythm()
	{
		bRhytmActorActive = true;
		NetPendingStopCount = 2;
		bHasSentHandShake = false;
		bPendingStop = false;

		SetActorTickEnabled(true);
	}

	// Prevents new tempo actors from spawning and waits until existing ones are cleared.
	UFUNCTION(BlueprintCallable)
	void StopRhythm()
	{
		if(!bPendingStop)
			PendingExitElapsed = 4.0f;

		bPendingStop = true;
	}

	UFUNCTION()
	void HandleOverlapTimerEnd()
	{		
		if(!HasControl())
		{
			return;
		}

		if(CurrentDancer == nullptr)
		{
			if(SphereTrigger.IsOverlappingActor(Game::GetMay()) && HasRhythmComponent(Game::GetMay()))
			{
				NetHandlePlayerOverlap(Game::GetMay());
			}
			else if(SphereTrigger.IsOverlappingActor(Game::GetCody()) && HasRhythmComponent(Game::GetCody()))
			{
				NetHandlePlayerOverlap(Game::GetCody());
			}
		}
		else
		{
			if(!SphereTrigger.IsOverlappingActor(CurrentDancer) && HasRhythmComponent(CurrentDancer))
			{
				// Quit dancing
				NetHandlePlayerOverlapEnd(CurrentDancer);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetHandlePlayerOverlap(AHazePlayerCharacter Player)
	{
		UPlayerRhythmComponent PlayerRhythmComponent = UPlayerRhythmComponent::Get(Player);
		if(!devEnsure(PlayerRhythmComponent != nullptr))
			return;

		CurrentDancer = Player;
		LastDancer = Player;
		PlayerRhythmComponent.RhythmDanceArea = this;

		SetControlSide(Player);
		
		LeftFaceButton.OnNewDancer(Player, ToWorldLocation(LeftFaceButtonLocation));
		RightFaceButton.OnNewDancer(Player, ToWorldLocation(RightFaceButtonLocation));
		TopFaceButton.OnNewDancer(Player, ToWorldLocation(TopFaceButtonLocation));
	}

	UFUNCTION(NetFunction)
	void NetHandlePlayerOverlapEnd(AHazePlayerCharacter Player)
	{
		UPlayerRhythmComponent PlayerRhythmComponent = UPlayerRhythmComponent::Get(Player);
		if(!devEnsure(PlayerRhythmComponent != nullptr))
			return;

		for(URhythmComponent CurrentRhythm : RhythmComponents)
		{
			CurrentRhythm.OnDancerLeft(Player);
		}	

		CurrentDancer = nullptr;
		PlayerRhythmComponent.RhythmDanceArea = nullptr;
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Tempo Success"))
	void BP_OnTempoSuccess(FRhythmTempoInfo TempoInfo){}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Tempo Failed"))
	void BP_OnTempoFailed(FRhythmTempoFailInfo FailInfo){}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Rhythm Hit Failed"))
	void BP_OnRhythmHitFailed(URhythmComponent RhythmComponent){}

	void RhythmHitFailed(FName InActionName)
	{
		URhythmComponent RhythmComp = GetRhythmComponentFromActionName(InActionName);
		OnRhythmHitFailed.Broadcast(RhythmComp);
		BP_OnRhythmHitFailed(RhythmComp);
	}

	URhythmComponent GetRhythmComponentFromActionName(FName InActionName) const
	{
		for(URhythmComponent Comp : RhythmComponents)
		{
			if(Comp.ActionName == InActionName)
				return Comp;
		}

		return nullptr;
	}

	bool HasRhythmComponent(AHazeActor TargetActor) const
	{
		UPlayerRhythmComponent RhythmComp = UPlayerRhythmComponent::Get(TargetActor);
		return RhythmComp != nullptr;
	}

	FVector ToWorldLocation(FVector WidgetLocalLocation) const
	{
		return ActorTransform.TransformPosition(WidgetLocalLocation);
	}

	bool HasAnyTempoActors() const
	{
		bool bActiveTempo = false;

		for(URhythmComponent RhythmComp : RhythmComponents)
		{
			if(RhythmComp.HasActiveTempos())
			{
				bActiveTempo = true;
				break;
			}
		}

		return bActiveTempo;
	}
}
