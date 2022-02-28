import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Cake.LevelSpecific.Clockwork.TimeBomb.TimeBombActivationpoint;
import Vino.PointOfInterest.PointOfInterestComponent;
import Cake.LevelSpecific.Clockwork.TimeBomb.TimeBombNiagaraPathFollow;
import Peanuts.Audio.AudioStatics;

enum ETimeBombPlayerTarget
{
	May,
	Cody,
	Both 
};

event void FOverlappedPlayer(AHazePlayerCharacter Player);
event void FDisableRegenPoint(ABombRegenPoint BombRegenPoint);
event void FTimeIncreased(AHazePlayerCharacter Player);

class ABombRegenPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp2;
	default MeshComp2.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp3;
	default MeshComp3.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp4;
	default MeshComp3.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap); 

	float Radius = 310.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ArrowAnchor;

	UPROPERTY(DefaultComponent, Attach = ArrowAnchor)
	UStaticMeshComponent MeshCompArrow;
	default MeshCompArrow.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraPuffOut;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraInitiate;
	default NiagaraInitiate.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent InitiateEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EnterEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartLoopEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EndLoopEvent;

	FTimeIncreased OnTimeIncreased;

	UPROPERTY(Category = "Setup")
	ETimeBombPlayerTarget TimeBombPlayerTarget;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeCapability> RegenCapability;

	UPROPERTY()
	AActor PointOfInterestTarget;

	UPROPERTY(Category = "Setup")
	ABombRegenPoint NextPointToActivate;

	UPROPERTY(Category = "For Testing")
	UMaterial MaterialCody;

	UPROPERTY(Category = "For Testing")
	UMaterial MaterialMay;

	UPROPERTY(Category = "For Testing")
	UMaterial MaterialBoth;

	UPROPERTY()
	TPerPlayer<bool> bHaveActivated;

	UPROPERTY()
	TPerPlayer<bool> bHaveRenderedNext;

	UPROPERTY()
	TPerPlayer<bool> bOurPreviousRegenHasActivated;

	FDisableRegenPoint EventDisableRegenPoint; 

	float MinDistance = 2000.f;

	UPROPERTY()
	TPerPlayer<bool> bHaveBeenAcquired;

	ATimeBombNiagaraPathFollow NiagaraPathFollowMay;
	ATimeBombNiagaraPathFollow NiagaraPathFollowCody;

	UPROPERTY(Category = "Setup")
	TSubclassOf<ATimeBombNiagaraPathFollow> NiagaraPathFollowClass;

	FVector A;
	FVector B;
	FVector ControlPoint;

	bool bActivateNiagaraMay;
	bool bActivateNiagaraCody;

	float AlphaMay;
	float AlphaCody;
	float Speed = 1.8f;
	float DistanceToNextPoint;

	UPROPERTY(Category = "BezierCurve")
	float ControlPointHeight = 1000.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp) * CullDistanceMultiplier);
		MeshComp2.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp2) * CullDistanceMultiplier);
		MeshComp3.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp3) * CullDistanceMultiplier);
		MeshCompArrow.SetCullDistance(Editor::GetDefaultCullingDistance(MeshCompArrow) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		NiagaraPuffOut.SetActive(false, true);
		NiagaraPuffOut.Deactivate();

		AddCapability(RegenCapability);

		MeshComp.SetHiddenInGame(false);
		MeshComp2.SetHiddenInGame(false);
		MeshComp3.SetHiddenInGame(false);
		MeshComp4.SetHiddenInGame(false);
		MeshCompArrow.SetHiddenInGame(false);

		if (NextPointToActivate != nullptr)
		{
			A = ActorLocation;
			B = NextPointToActivate.ActorLocation;

			FVector Direction = NextPointToActivate.ActorLocation - ActorLocation;
			Direction.Normalize();

			float FlatDistance = (B - A).Size();

			ControlPoint = (A + B) * 0.5f;
			ControlPoint += FVector(0.f, 0.f, ControlPointHeight);
			ControlPoint -= Direction * (FlatDistance * 0.3f);

			DistanceToNextPoint = Math::CalculateCubicBezierSegmentLength(A, ControlPoint, ControlPoint, B);
			Speed *= 1 - DistanceToNextPoint / 12800;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float MayDistance = (Game::GetMay().ActorLocation - ActorLocation).Size();
		float CodyDistance = (Game::GetCody().ActorLocation - ActorLocation).Size();

		CheckDist(MayDistance, CodyDistance);

		if (bActivateNiagaraMay)
		{
			if (AlphaMay < 1.f)
			{
				AlphaMay += Speed * DeltaTime;
				NiagaraPathFollowMay.SetActorLocation(Math::GetPointOnCubicBezierCurveConstantSpeed(A, ControlPoint, ControlPoint, B, AlphaMay));
			}
			else
			{
				AlphaMay = 0.f;
				System::SetTimer(this, n"TimedNiagaraFollowDisableMay", 1.f, false);
				NiagaraPathFollowMay.AudioEndTrail();

				if (NextPointToActivate != nullptr && HasControl())
					NextPointToActivate.LightUpForPlayer(Game::May);
				
				bActivateNiagaraMay = false;
			}
		}

		if (bActivateNiagaraCody)
		{
			if (AlphaCody < 1.f)
			{
				AlphaCody += Speed * DeltaTime;
				NiagaraPathFollowCody.SetActorLocation(Math::GetPointOnCubicBezierCurveConstantSpeed(A, ControlPoint, ControlPoint, B, AlphaCody));
			}
			else
			{
				AlphaCody = 0.f;
				System::SetTimer(this, n"TimedNiagaraFollowDisableCody", 1.f, false);
				NiagaraPathFollowCody.AudioEndTrail();

				if (NextPointToActivate != nullptr && HasControl())
					NextPointToActivate.LightUpForPlayer(Game::Cody);
				
				bActivateNiagaraCody = false;
			}
		}

		PointArrow();
	}

	UFUNCTION()
	void CheckDist(float MayDist, float CodyDist)
	{
		if (MayDist <= Radius && !bHaveBeenAcquired[0] && bHaveActivated[0])
			RegenPointActivated(Game::May);

		if (CodyDist <= Radius && !bHaveBeenAcquired[1] && bHaveActivated[1])
			RegenPointActivated(Game::Cody);
	}

	UFUNCTION()
	void RegenPointActivated(AHazePlayerCharacter Player)
	{
		SetControlSide(Player);

		if (Player == Game::GetMay() && !bHaveBeenAcquired[0] && bHaveActivated[0])
		{
			bHaveBeenAcquired[0] = true;
			NiagaraPuffOut.SetRenderedForPlayer(Game::Cody, false);
			PlayerEnteredVolume(Player);
		}
		else if (Player == Game::GetCody() && !bHaveBeenAcquired[1] && bHaveActivated[1])
		{
			bHaveBeenAcquired[1] = true;
			NiagaraPuffOut.SetRenderedForPlayer(Game::May, false);
			PlayerEnteredVolume(Player);
		}
	}

	UFUNCTION()
	void PointArrow()
	{
		if (NextPointToActivate == nullptr)
			return;

		FVector LookDir = NextPointToActivate.ActorLocation - ArrowAnchor.WorldLocation;
		LookDir.ConstrainToPlane(FVector::UpVector);
		LookDir.Normalize();

		FRotator LookRot = FRotator::MakeFromX(LookDir);

		ArrowAnchor.SetWorldRotation(LookRot);
	}

	UFUNCTION()
	void TimedNiagaraFollowDisableMay()
	{
		NiagaraPathFollowMay.DestroyActor();
	}

	UFUNCTION()
	void TimedNiagaraFollowDisableCody()
	{
		NiagaraPathFollowCody.DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void PointOfInterestWidgetSet(AHazePlayerCharacter Player, bool bIsVisible) {}
	
	UFUNCTION()
	void ResetBools()
	{
		bHaveRenderedNext[0] = false;
		bHaveRenderedNext[1] = false;
		bHaveBeenAcquired[0] = false;
		bHaveBeenAcquired[1] = false;
		bHaveActivated[0] = false;
		bHaveActivated[1] = false;
		bOurPreviousRegenHasActivated[0] = false;
		bOurPreviousRegenHasActivated[1] = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		NiagaraPuffOut.SetActive(false, true);
		NiagaraPuffOut.Deactivate();

		MeshComp.SetHiddenInGame(false);
		MeshComp2.SetHiddenInGame(false);
		MeshComp3.SetHiddenInGame(false);
		MeshComp4.SetHiddenInGame(false);
		MeshCompArrow.SetHiddenInGame(false);

		bHaveBeenAcquired[0] = false;
		bHaveBeenAcquired[1] = false;
	}

	UFUNCTION(NetFunction)
	void LightUpForPlayer(AHazePlayerCharacter Player)
	{
		bHaveActivated[Player] = true;
		PointOfInterestWidgetSet(Player, true);

		NiagaraInitiate.SetRenderedForPlayer(Player.OtherPlayer, false);
		NiagaraInitiate.SetRenderedForPlayer(Player, true);
		NiagaraInitiate.Activate();

		HazeAudio::SetPlayerPanning(AkComp, Player);
		AkComp.HazePostEvent(InitiateEvent);
		AkComp.HazePostEvent(StartLoopEvent);

		System::SetTimer(this, n"DelayedDeactivateNiagara", 1.5f, false);
		MeshComp3.SetRenderedForPlayer(Player, true);
		MeshCompArrow.SetRenderedForPlayer(Player, true);
	}

	UFUNCTION()
	void DelayedDeactivateNiagara()
	{
		NiagaraInitiate.SetRenderedForPlayer(Game::May, true);
		NiagaraInitiate.SetRenderedForPlayer(Game::Cody, true);
		NiagaraInitiate.Deactivate();
	}

	UFUNCTION(NetFunction)
	void UnlightForPlayer(AHazePlayerCharacter Player)
	{
		PointOfInterestWidgetSet(Player, false);
		bHaveActivated[Player] = false;

		HazeAudio::SetPlayerPanning(AkComp, Player);
		AkComp.HazePostEvent(EndLoopEvent);
		
		MeshComp3.SetRenderedForPlayer(Player, false);
		MeshCompArrow.SetRenderedForPlayer(Player, false);
	}

	UFUNCTION()
	void Disappear()
	{
		NiagaraPuffOut.SetActive(false, true);
		NiagaraPuffOut.Deactivate();

		MeshComp.SetHiddenInGame(true);
		MeshComp2.SetHiddenInGame(true);
		MeshComp3.SetHiddenInGame(true);
		MeshComp4.SetHiddenInGame(true);
		MeshCompArrow.SetHiddenInGame(true);
	}

	void FocusOnPointOfInterest(AHazePlayerCharacter Player)
	{
		if (PointOfInterestTarget != nullptr)
		{
			FHazePointOfInterest PoISettings;
			PoISettings.FocusTarget.Actor = PointOfInterestTarget;
			PoISettings.Duration = 1.5f;
			PoISettings.Blend.BlendTime = 2.f;
			Player.ApplyPointOfInterest(PoISettings, this);
		}
	}

	UFUNCTION(NetFunction)
	void NiagaraFollowPathActivation(AHazePlayerCharacter Player)
	{
		if (NextPointToActivate == nullptr)
			return;

		if (Player == Game::May)
		{
			AlphaMay = 0.f;
			bActivateNiagaraMay = true;
			NiagaraPathFollowMay = Cast<ATimeBombNiagaraPathFollow>(SpawnActor(NiagaraPathFollowClass, ActorLocation, ActorRotation)); 
			HazeAudio::SetPlayerPanning(NiagaraPathFollowMay.AkComp, Player);
			NiagaraPathFollowMay.RenderForPlayer(Player);
			NiagaraPathFollowMay.AudioStartTrail();
		}
		else
		{
			AlphaCody = 0.f;
			bActivateNiagaraCody = true;
			NiagaraPathFollowCody = Cast<ATimeBombNiagaraPathFollow>(SpawnActor(NiagaraPathFollowClass, ActorLocation, ActorRotation)); 
			HazeAudio::SetPlayerPanning(NiagaraPathFollowCody.AkComp, Player);
			NiagaraPathFollowCody.RenderForPlayer(Player);
			NiagaraPathFollowCody.AudioStartTrail();
		}
	}

	UFUNCTION()
	void PlayerEnteredVolume(AHazePlayerCharacter Player)
	{
		OnTimeIncreased.Broadcast(Player);

		HazeAudio::SetPlayerPanning(AkComp, Player);
		AkComp.HazePostEvent(EnterEvent);

		FocusOnPointOfInterest(Player);

		if (HasControl())
		{
			UnlightForPlayer(Player);
			NiagaraFollowPathActivation(Player);
		}

		NiagaraPuffOut.SetActive(false, true);
		NiagaraPuffOut.Activate();
	}
}