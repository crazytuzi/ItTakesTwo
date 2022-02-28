import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Peanuts.Audio.AudioStatics;

import void TrigerFlyingBoostOnActor(AActor) from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent";
import void ActivateNote(AHazeActor) from "Cake.LevelSpecific.Music.Classic.MusicalFollowerNote";

event void FOnBubbleBurst(AHazePlayerCharacter Player, AHazeActor NoteToActivate, float LookAtTime);

class UClassicBubbleDisable : UActorComponent
{
	UPROPERTY(Category = "Disabling")
	FHazeMinMax DisableRange = FHazeMinMax(2000.f, 25000.f);

	UPROPERTY(Category = "Disabling")
	float ViewRadius = 900.f;

	UPROPERTY(Category = "Disabling")
	float DontDisableWhileVisibleTime = 1.f;

	AClassicBubble BubbleOwner;
	bool bIsAutoDisabled = false;
	float ClosestPlayerDistSq = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// This component never disables
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateAutoDisable();
	}

	void UpdateAutoDisable()
	{
		const bool bShouldBeAutoDisabled = ShouldAutoDisable();
		if(bIsAutoDisabled != bShouldBeAutoDisabled)
		{
			bIsAutoDisabled = bShouldBeAutoDisabled;
			SetActorDisabledInternal(bIsAutoDisabled);
		}
	}

	private bool ShouldAutoDisable()
	{	
		if(BubbleOwner.BubbleHasBurst)
			return false;

		const FVector WorldLocation = BubbleOwner.GetActorLocation();
		if(bIsAutoDisabled && ClosestPlayerDistSq >= FMath::Square(DisableRange.Max))
		{
			ClosestPlayerDistSq = BIG_NUMBER;
			for(auto Player : Game::GetPlayers())
			{
				const float Dist = Player.GetActorLocation().DistSquared(WorldLocation);
				if(Dist < ClosestPlayerDistSq)
					ClosestPlayerDistSq = Dist;
			}
		}
		else
		{
			ClosestPlayerDistSq = BIG_NUMBER;
			for(auto Player : Game::GetPlayers())
			{
				const float Dist = Player.GetActorLocation().DistSquared(WorldLocation);
				if(Dist < ClosestPlayerDistSq)
					ClosestPlayerDistSq = Dist;

				if(BubbleOwner.MeshBody.WasRecentlyRendered(DontDisableWhileVisibleTime))
					return false;

				if(Dist < FMath::Square(DisableRange.Min))
					return false;

				if(SceneView::ViewFrustumPointRadiusIntersection(Player, WorldLocation, ViewRadius))
					return false;
			}
		}

		return true;
	}

	private void SetActorDisabledInternal(bool bStatus)
	{
		if(bStatus)
			BubbleOwner.DisableActor(this);
		else
			BubbleOwner.EnableActor(this);
	}
}

class AClassicBubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeStaticMeshComponent MeshBody;
	default MeshBody.CollisionProfileName = n"NoCollision";
	default MeshBody.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UHazeLazyPlayerOverlapComponent PlayerOverlap;

	UPROPERTY(DefaultComponent, Attach = MeshBodyComp)
	UNiagaraComponent NiagaraGlowEffect;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UClassicBubbleDisable DisableCompExtension;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BubbleBurstAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BubbleIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopBubbleIdleAudioEvent;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackImpact;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeImpact;

	UPROPERTY()
	AHazeActor NoteToActivate;
	UPROPERTY()
	FOnBubbleBurst OnBubbleBurst;
	UPROPERTY()
	UNiagaraSystem BubbleBurstEffect;
	bool BubbleHasBurst = false;
	FVector StartLocation;
	UPROPERTY()
	float TimeStartOffset;
	UPROPERTY()
	float OverlapRadius = 50.0f;
	UPROPERTY()
	float LookAtTime = 6.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{	
		PlayerOverlap.Shape.InitializeAsSphere(OverlapRadius);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableCompExtension.BubbleOwner = this;
		PlayerOverlap.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		HazeAkComp.HazePostEvent(BubbleIdleAudioEvent);

		if(NoteToActivate != nullptr)
			NoteToActivate.AttachToComponent(MeshBody, NAME_None, EAttachmentRule::SnapToTarget);

		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector RelativeLocation;
		const float Time = Time::GameTimeSeconds;
		RelativeLocation.X = FMath::Sin(Time * 2.f + TimeStartOffset) * 80.f;
		RelativeLocation.Y = FMath::Sin(Time * 3.f + TimeStartOffset) * 130.f;
		RelativeLocation.Z = FMath::Sin(Time * 5.f + TimeStartOffset) * 80.f;
		RelativeLocation = FMath::VInterpTo(GetActorLocation(), StartLocation + RelativeLocation, DeltaSeconds, 7.f);
		SetActorLocation(RelativeLocation);
	}

	UFUNCTION()
	void StartMoving()
	{

	}

	UFUNCTION(NetFunction)
	void NetStartMoving()
	{
		
	}
	
	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor == Game::GetCody())
		{
			Game::GetCody().PlayForceFeedback(ForceFeedbackImpact, false, false, n"ForceFeedbackImpact");
			Game::GetCody().PlayCameraShake(CameraShakeImpact, 1.f);

			if(Game::GetCody().HasControl())
			{
				NetBubbleBurst(Game::GetCody());
				return;
			}


		}
		if(OtherActor == Game::GetMay())
		{
			Game::GetMay().PlayForceFeedback(ForceFeedbackImpact, false, false, n"ForceFeedbackImpact");
			Game::GetMay().PlayCameraShake(CameraShakeImpact, 1.f);

			if(Game::GetMay().HasControl())
			{
				NetBubbleBurst(Game::GetMay());
				return;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetBubbleBurst(AHazePlayerCharacter Player)
	{
		BubbleBurst(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorPostDisabled()
	{
		if(NoteToActivate != nullptr)
			NoteToActivate.DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(NoteToActivate != nullptr)
			NoteToActivate.EnableActor(this);
	}

	private void BubbleBurst(AHazePlayerCharacter Player)
	{
		if(BubbleHasBurst == true)
			return;
		
		BubbleHasBurst = true;
		DisableCompExtension.UpdateAutoDisable();

		NiagaraGlowEffect.Deactivate();
		Player.PlayerHazeAkComp.HazePostEvent(BubbleBurstAudioEvent);
		HazeAkComp.HazePostEvent(StopBubbleIdleAudioEvent);
		OnBubbleBurst.Broadcast(Player, NoteToActivate, LookAtTime);
		Niagara::SpawnSystemAtLocation(BubbleBurstEffect, GetActorLocation(), GetActorRotation());
		
		if(NoteToActivate != nullptr)
		{
			NoteToActivate.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			//NoteToActivate.DistanceMinimum = 1000000.f;
			//NoteToActivate.MoveToTargetLocation();
			ActivateNote(NoteToActivate);
		}
		
		DestroyActor();
	}

	UFUNCTION()
	void CompleteInstantly()
	{
		BubbleHasBurst = true;
		DisableCompExtension.UpdateAutoDisable();
		DestroyActor();
	}
}

