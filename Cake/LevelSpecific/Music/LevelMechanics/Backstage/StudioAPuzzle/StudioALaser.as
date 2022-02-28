import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioABlockingPlatform;
import Vino.Movement.Dash.CharacterDashSettings;
import Vino.Movement.Dash.CharacterDashComponent;

event void FLaserDeflected(bool bDeflected);

class AStudioALaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent MainLaser;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaserStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaserDeflectedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaserStopDeflectingAudioEvent;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect FeedbackEffect = Asset("/Game/Blueprints/ForceFeedback/FF_MediumConstant.FF_MediumConstant");

	UPROPERTY()
	float MainLaserDefaultLength = 200.f;

	float CurrentLaserLength = 0.f;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	bool bStartActive = false;

	UPROPERTY()
	bool bShouldMove = false;

	UPROPERTY(Category = Debug)
	bool bDebugMode = false;

	UPROPERTY(Category = Debug)
	bool bKillPlayer = true;

	// Can't harm the player, won't perform any traces etc. Used for beams high up which the player is unable to reach.
	UPROPERTY()
	bool bOnlyVisual = false;

	UPROPERTY()
	FHazeTimeLike MoveLaserTimeline;
	default MoveLaserTimeline.bFlipFlop = true;
	default MoveLaserTimeline.bLoop = true;

	UPROPERTY()
	FLaserDeflected LaserDeflectedEvent;

	bool bHasPostedDeflectedEvent = false;

	FVector StartLocation = FVector::ZeroVector;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	FVector TargetWorldLoc;

	bool bShouldBeActive = true;

	float ActivationDelay = 0.f;
	bool bShouldTickActivationDelay = false;

	TArray<AActor> ActorsToIgnore;

	private bool bWasCymbalHit = false;

	FHazeIntersectionCapsule Capsule;
	FHazeIntersectionLineSegment Line;
	FHazeIntersectionResult Intersection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveLaserTimeline.BindUpdate(this, n"MoveLaserTimelineUpdate");
		TargetWorldLoc = GetActorTransform().TransformPosition(TargetLocation);
		HazeAkComp.HazePostEvent(LaserStartAudioEvent);

		if (bShouldMove)
			MoveLaserTimeline.PlayFromStart();
		
		if (!bStartActive)
			SetLaserEnabled(false, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		RemoveFromCymbalComponent();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector(0.f, 0.f, MainLaserDefaultLength));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickActivationDelay)
		{
			ActivationDelay -= DeltaTime;
			if (ActivationDelay <= 0.f)
			{
				bShouldTickActivationDelay = false;
				if (bShouldBeActive)
					MainLaser.Activate();
				else
					MainLaser.Deactivate();
			}
		}

		if (!bShouldBeActive)
			return;
		
		FVector Start = MeshRoot.WorldLocation;
		FVector End = Start + Arrow.ForwardVector * MainLaserDefaultLength;
		Line.Start = Start;
		Line.End = End;

		// First, let's try against the cymbal
		FHazeHitResult Hit;
		const bool bHitCymbal = TraceAgainstCymbal(Hit);
		float LaserLength = MainLaserDefaultLength;
		float HitDistance = FMath::Max(Hit.Distance, 10.0f);
		if(bHitCymbal)
		{
			Line.End = Start + Arrow.ForwardVector * HitDistance;
			LaserLength = HitDistance;
		}

		MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector(0.f, 0.f, LaserLength));

		// Test if this beam hits any player

		if(
			!bHitCymbal &&
			IntersectsWithPlayer(Game::GetCody())
#if TEST
			&& bKillPlayer
#endif // TEST
		)
		{
			KillPlayer(Game::GetCody(), DeathEffect);
		}

		if(IntersectsWithPlayer(Game::GetMay()) && LaserLength >= 10.f
#if TEST
			&& bKillPlayer
#endif // TEST
		)
		{
			KillPlayer(Game::GetMay(), DeathEffect);
		}

		if(bHitCymbal && !bWasCymbalHit)
		{
			OnLaserDeflectBegin(Hit);
		}
		else if(!bHitCymbal && bWasCymbalHit)
		{
			OnLaserDeflectEnd();
		}
		else if(bHitCymbal)
		{
			OnLaserDeflectUpdate(DeltaTime, Hit);
		}

		bWasCymbalHit = bHitCymbal;
	}

	private bool TraceAgainstCymbal(FHazeHitResult& OutHit)
	{
		UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());

		if(CymbalComp == nullptr)
			return false;

		// Check if this line is intersecting the cymbal.
		FHazeIntersectionSphere Sphere;
		Sphere.Origin = CymbalComp.CymbalActor.ActorCenterLocation;
		const float CymbalRadius = 70.0f;
		Sphere.Radius = CymbalRadius;
		Intersection.QueryLineSegmentSphere(Line, Sphere);

		if(!Intersection.bIntersecting)
			return false;

		// Next lets see if the angle is aligned enough to block the laser. 
		const float DirDot = CymbalComp.CymbalActor.CymbalMesh.ForwardVector.DotProduct(Arrow.ForwardVector);

		if(DirDot > -0.5f)
		{
			// We are facing the laser so let's get a final detailed trace on it.
			TraceAgainstPrimitive(CymbalComp.CymbalActor.CymbalMesh, OutHit);
			return OutHit.bBlockingHit;
		}

		return false;
	}

	private bool IntersectsWithPlayer(AHazePlayerCharacter Player)
	{
		FVector CapsuleLoc = Player.ActorCenterLocation;
		float CapsuleRadius = 38.0f;
		float CapsuleHalfHeight = 88.0f;

		if(Player.IsCody() && IsCodyHoldingShield())
		{
			// Since we increase the capsule size it will clip through the shield, so let's move it back a bit if cody is blocking.
			CapsuleLoc -= Player.ActorForwardVector * 20.0f;
			const float FacingDot = Player.ActorForwardVector.GetSafeNormal2D().DotProduct(Arrow.ForwardVector);
			if(FacingDot < -0.95f)
			{
				return false;
			}
		}

		Capsule.MakeUsingOrigin(CapsuleLoc, FRotator::ZeroRotator, CapsuleHalfHeight, CapsuleRadius);
		Intersection.QueryLineSegmentCapsule(Line, Capsule);
		//System::DrawDebugCapsule(CapsuleLoc, CapsuleHalfHeight, CapsuleRadius, FRotator::ZeroRotator, FLinearColor::Green);

#if TEST
		if(GetGodMode(Player) != EGodMode::Mortal)
			return false;
#endif // TEST

		return Intersection.bIntersecting;
	}

	private void TraceAgainstPrimitive(UPrimitiveComponent Primitive, FHazeHitResult& OutHit) const
	{
		Primitive.LineTraceAtComponent(Line.Start, Line.End, OutHit);
	}

	UFUNCTION()
	void MoveLaserTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	void SetLaserEnabled(bool bEnabled, float NewActivationDelay)
	{
		ActivationDelay = NewActivationDelay;
		bShouldBeActive = bEnabled;
		bShouldTickActivationDelay = true;

		if (!bEnabled && MoveLaserTimeline.IsPlaying())
			MoveLaserTimeline.StopWithDeceleration(2.f);

		if(bEnabled)
			BP_OnLaserEnabled();
		else
			BP_OnLaserDisabled();
	}

	void OnLaserDeflectBegin(FHazeHitResult Hit)
	{
		AddToCymbalComponent();
		const FVector ReflectionVector = FMath::GetReflectionVector(Arrow.ForwardVector, Hit.ImpactNormal);
		BP_OnLaserDeflectBegin(ReflectionVector, Hit.ImpactPoint);
		LaserDeflectedEvent.Broadcast(true);
		HazeAkComp.HazePostEvent(LaserDeflectedAudioEvent);
		
		if(FeedbackEffect != nullptr)
			Game::GetCody().PlayForceFeedback(FeedbackEffect, true, true, n"CymbalLaserDeflect");
	}

	void OnLaserDeflectEnd()
	{
		RemoveFromCymbalComponent();
		BP_OnLaserDeflectEnd();
		LaserDeflectedEvent.Broadcast(false);
		HazeAkComp.HazePostEvent(LaserStopDeflectingAudioEvent);

		if(FeedbackEffect != nullptr)
			Game::GetCody().StopForceFeedback(FeedbackEffect, n"CymbalLaserDeflect");
	}

	void OnLaserDeflectUpdate(float DeltaTime, FHazeHitResult Hit)
	{
		const FVector ReflectionVector = FMath::GetReflectionVector(Arrow.ForwardVector, Hit.ImpactNormal);
		BP_OnLaserDeflectUpdate(DeltaTime, ReflectionVector, Hit.ImpactPoint);
		//System::DrawDebugArrow(Hit.ImpactPoint, Hit.ImpactPoint + ReflectionVector * 1000.0f, 10, FLinearColor::Green, 0, 10);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Laser Deflect Begin"))
	void BP_OnLaserDeflectBegin(FVector Direction, FVector ImpactPoint) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Laser Deflect End"))
	void BP_OnLaserDeflectEnd() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Laser Deflect Update"))
	void BP_OnLaserDeflectUpdate(float DeltaTime, FVector Direction, FVector ImpactPoint) {}

	private bool IsCodyHoldingShield() const
	{
		UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());

		if(CymbalComp != nullptr)
		{
			return CymbalComp.bShieldActive;
		}

		return false;
	}

	private bool IsCodyDashing() const
	{
		AHazePlayerCharacter Cody = Game::GetCody();

		if(!Cody.HasControl())
			return false;

		UCharacterDashComponent DashComp = UCharacterDashComponent::Get(Cody);

		if(DashComp == nullptr)
			return false;

		const bool bIsDashing = !(DashComp.DashDeactiveDuration > 0.0f);

		return bIsDashing;
	}

	private void AddToCymbalComponent()
	{
		UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());
		if(CymbalComp != nullptr)
			CymbalComp.ShieldImpactingActors.AddUnique(this);
	}

	private void RemoveFromCymbalComponent()
	{
		UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());
		if(CymbalComp != nullptr)
			CymbalComp.ShieldImpactingActors.Remove(this);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Laser Enabled"))
	void BP_OnLaserEnabled() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Laser Disable"))
	void BP_OnLaserDisabled() {}
}
