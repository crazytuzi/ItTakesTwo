import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

event void FOnAngelBabyKilled(AHazePlayerCharacter Player);

class UClassicSplineAngelBabyMovementComponent : UHazeSplineFollowComponent
{
	// Make sure that we are ticking before gameplay and after the player has moved
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeAnimation;

	UPROPERTY(Transient, EditConst)
	bool bHasDeactivatedActor = false;

	AClassicSplineAngelBabies OwnerAngel;
	EHazeUpdateSplineStatusType SplineFollowMovementStatus = EHazeUpdateSplineStatusType::Invalid;
	FTransform CurrentTransformOnSpline;
	float CurrentDistanceAlongSpline;

	AHazePlayerCharacter LastPlayerThatCouldSee;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LastPlayerThatCouldSee = Game::GetMay();
		OwnerAngel = Cast<AClassicSplineAngelBabies>(Owner);
		bHasDeactivatedActor = true;
		OwnerAngel.DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Never disable
		OwnerAngel.SkeletalMesh.SetHiddenInGame(true);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		OwnerAngel.SkeletalMesh.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bShouldDisable = UpdateShouldBeDisabled();
		if(bShouldDisable != bHasDeactivatedActor)
		{
			if(bShouldDisable)
			{
				bHasDeactivatedActor = true;
				OwnerAngel.DisableActor(this);
			}
			else
			{
				bHasDeactivatedActor = false;
				OwnerAngel.EnableActor(this);
			}
		}

		if(OwnerAngel.CanUpdateMovement())
		{
			UpdateMovement(DeltaSeconds);
		}

		OwnerAngel.UpdateDeathGroundCollision(DeltaSeconds);

		//System::DrawDebugSphere(CurrentTransformOnSpline.Location, 500.f, LineColor = FLinearColor::Red, Thickness = 5.f);
	}

	void UpdateMovement(float DeltaSeconds)
	{
		float MoveAmount = OwnerAngel.FollowSpeed * DeltaSeconds;
		ApplySplineMoveAmount(MoveAmount);
	}

	void ApplySplineMoveAmount(float MoveAmount)
	{
		FHazeSplineSystemPosition CurrentSplinePosition;
		bool bWarped;
		SplineFollowMovementStatus = UpdateSplineMovementAndRestartAtEnd(MoveAmount, CurrentSplinePosition, bWarped);
		CurrentTransformOnSpline = CurrentSplinePosition.GetWorldTransform();
		CurrentDistanceAlongSpline = CurrentSplinePosition.DistanceAlongSpline;

		if(!bHasDeactivatedActor)
		{
			OwnerAngel.SetActorLocationAndRotation(CurrentTransformOnSpline.Location, CurrentTransformOnSpline.Rotation);
		}
	}

	bool UpdateShouldBeDisabled()
	{
		auto Cody = Game::Cody;
		auto May = Game::May;
		const FVector CurrentSplineLocation = CurrentTransformOnSpline.Location;
	
		bool bAnyPlayerCanSee = OwnerAngel.SkeletalMesh.WasRecentlyRendered(1.f);
		if(!bAnyPlayerCanSee)
		{	
			const float VisibilityDistance = 45000.f;
			const float ViewSize = 1100.f;
			if(SceneView::ViewFrustumPointRadiusIntersection(LastPlayerThatCouldSee, CurrentSplineLocation, ViewSize, VisibilityDistance))
			{
				bAnyPlayerCanSee = true;
			}
			else if(SceneView::ViewFrustumPointRadiusIntersection(LastPlayerThatCouldSee.GetOtherPlayer(), CurrentSplineLocation, ViewSize, VisibilityDistance))
			{
				bAnyPlayerCanSee = true;
				LastPlayerThatCouldSee = LastPlayerThatCouldSee.GetOtherPlayer();
			}
		}

		if(!bAnyPlayerCanSee)
		{
			const float DistanceToCody = CurrentSplineLocation.DistSquared(Cody.GetActorLocation());
			const float DistanceToMay = CurrentSplineLocation.DistSquared(May.GetActorLocation());

			float ClosestDistance;
			AHazePlayerCharacter ClosestPlayer;
			if(DistanceToCody < DistanceToMay)
			{
				ClosestPlayer = Cody;
				ClosestDistance = DistanceToCody;
			}
			else
			{
				ClosestPlayer = May;
				ClosestDistance = DistanceToMay;
			}

			if(ClosestDistance < FMath::Square(1000.f))
			{
				bAnyPlayerCanSee = true;
				LastPlayerThatCouldSee = ClosestPlayer;
			}
		}

		return !bAnyPlayerCanSee;
	}
}

UCLASS(Abstract)
class AClassicSplineAngelBabies : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.CollisionProfileName = n"NoCollision";
	default SkeletalMesh.bUseDisabledTickOptimizations = true;
	default SkeletalMesh.DisabledVisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
	default SkeletalMesh.bEnableUpdateRateOptimizations = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeLazyPlayerOverlapComponent PlayerOverlap;
	default PlayerOverlap.RelativeLocation = FVector(60.0f, -50.0f, 130.0f);
	default PlayerOverlap.Shape.Type = EHazeShapeType::Sphere;
	default PlayerOverlap.Shape.SphereRadius = 380.0f;
	default PlayerOverlap.ResponsiveDistanceThreshold = 4000.0f;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh)
	USceneComponent ImpactNode;

	UPROPERTY(DefaultComponent, Attach = ImpactNode)
	UCymbalImpactComponent CymbalImpactComp;
	default CymbalImpactComp.bUseWidget = false;
	default CymbalImpactComp.bPlayVFXOnHit = false;

	UPROPERTY(DefaultComponent, Attach = ImpactNode)
	USongReactionComponent SongReaction;
	default SongReaction.bUseWidget = false;

	UPROPERTY(DefaultComponent, Attach = ImpactNode)
	UAutoAimTargetComponent AutoAimTargetComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;

	UPROPERTY(DefaultComponent)
	UClassicSplineAngelBabyMovementComponent MovementComponent;

	UPROPERTY()
	FOnAngelBabyKilled OnAngelBabyKilled;

	UPROPERTY(Category = VFX)
	UNiagaraSystem DeathVFX;

	UPROPERTY(Category = VFX)
	UNiagaraSystem RespawnVFX;

	// Will be invisible, awaiting respawn after killed after this duration has elapsed.
	UPROPERTY()
	float TimeUntilRemoved = 4.0f;

	// Respawn after being removed when this duration has elapsed.
	UPROPERTY()
	float TimeUntilRespawn = 4.0f;

	UPROPERTY()
	float TimeUntilResumeMovement = 1.0f;

	UPROPERTY()
	float DeathImpulse = 15000.0f;

	UPROPERTY()
	UAnimSequence MH;
	UPROPERTY()
	UAnimSequence HitReaction;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent KillAngelBabyAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HideAngelBabyAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReviveAngelBabyAudioEvent;

	UPROPERTY()
	ASplineActor SplineToFollow;
	float FollowSpeed = 1700;

	private bool bPlayingImpactAnimation = false;
	private bool bFollowingSpline = false;
	private bool bIsKilled = false;
	private bool bDeathHasHitGround = false;
	private bool bHasBlockedMovement = false;

	private FVector StartLocation;
	private FRotator StartRotation;
	private bool bIsForwardOnSpline;
	private bool bHasPendingStartMoving = false;

	private FTimerHandle RespawnTimerHandle;
	private FTimerHandle WaitTickActivateHandle;

	TArray<AActor> IgnoreActors;
	float DeathTimer = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = GetActorLocation();
		StartRotation = GetActorRotation();
		PlayerOverlap.OnPlayerBeginOverlap.AddUFunction(this, n"Handle_PlayerBeginOverlap");

		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"Handle_CymbalImpact");
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"Handle_PowerfulSongImpact");
		IgnoreActors.Add(this);

		DisableActor(this, n"NoMovement");

		if(bHasPendingStartMoving)
		{
			bHasPendingStartMoving = false;
			StartFollowingSpline();
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		System::ClearAndInvalidateTimerHandle(RespawnTimerHandle);
		System::ClearAndInvalidateTimerHandle(WaitTickActivateHandle);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_RemoveTimerDone()
	{
		if(!HasControl())
			return;

		NetHideAngelBaby();
	}

	UFUNCTION(NetFunction)
	private void NetHideAngelBaby()
	{
		if(DeathVFX != nullptr)
			Niagara::SpawnSystemAtLocation(DeathVFX, SkeletalMesh.GetSocketLocation(n"Spine1"), ActorRotation);
		
		UHazeAkComponent::HazePostEventFireForget(HideAngelBabyAudioEvent, this.GetActorTransform());
		System::ClearAndInvalidateTimerHandle(RespawnTimerHandle);
		RespawnTimerHandle = System::SetTimer(this, n"Handle_RespawnTimerDone", TimeUntilRespawn, false);
		DisableActor(this, n"Death");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_RespawnTimerDone()
	{
		ReviveAngelBaby();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_WaitTickActivate()
	{
		bHasBlockedMovement = false;
		UHazeSplineComponent Spline = SplineToFollow.Spline;
		MovementComponent.ActivateSplineMovement(Spline, bIsForwardOnSpline);
	}

	private void ReviveAngelBaby()
	{
		if(!bIsKilled)
			return;

		if(DeathVFX != nullptr)
			Niagara::SpawnSystemAtLocation(RespawnVFX, StartLocation, StartRotation);

		System::ClearAndInvalidateTimerHandle(RespawnTimerHandle);
		RespawnTimerHandle = System::SetTimer(this, n"Handle_WaitTickActivate", TimeUntilResumeMovement, false);
		EnableActor(this, n"Death");

		UHazeAkComponent::HazePostEventFireForget(ReviveAngelBabyAudioEvent, this.GetActorTransform());
		SetActorLocationAndRotation(StartLocation, StartRotation);
		SkeletalMesh.SetSimulatePhysics(false);
		SkeletalMesh.SetCollisionProfileName(n"NoCollision");
		SkeletalMesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		SkeletalMesh.AttachToComponent(RootComp);
	
		DeathTimer = 0.f;
		bDeathHasHitGround = false;
		PlayFlyAnimation();
		CymbalImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
		SongReaction.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		
		// Both sides need to have respawned before we can kill the angel again
		Sync::FullSyncPoint(this, n"EnableDeath");
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableDeath()
	{
		bIsKilled = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void Handle_CymbalImpact(FCymbalHitInfo HitInfo)
	{
		if(bIsKilled)
			return;

		KillAngelBaby(HitInfo.DeltaMovement);
		OnAngelBabyKilled.Broadcast(Game::GetCody());
	}

	UFUNCTION()
	void Handle_PowerfulSongImpact(FPowerfulSongInfo HitInfo)
	{
		if(bIsKilled)
			return;

		KillAngelBaby(HitInfo.Direction);
		OnAngelBabyKilled.Broadcast(Game::GetMay());
	}

	void UpdateDeathGroundCollision(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(!bIsKilled)
			return;

		if(bDeathHasHitGround)
			return;

		DeathTimer += DeltaTime;
		if(DeathTimer > 10)
		{
			bDeathHasHitGround = true;
			NetHideAngelBaby();
			return;
		}

		const FVector Start = SkeletalMesh.GetSocketLocation(n"Spine1");
		const FVector End = Start - FVector::UpVector * 500.0f;
		FHitResult Hit;
		System::LineTraceSingle(Start, End, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
		if(Hit.bBlockingHit)
		{
			bDeathHasHitGround = true;
			NetHideAngelBaby();
		}
	}

	bool CanUpdateMovement() const
	{
		if(!bFollowingSpline
			|| bIsKilled
			|| bPlayingImpactAnimation
			|| bHasBlockedMovement)
			return false;

		return true;
	}

	private void KillAngelBaby(FVector HitNormal)
	{
		if(DeathVFX != nullptr)
			Niagara::SpawnSystemAtLocation(DeathVFX, SkeletalMesh.GetSocketLocation(n"Spine1"), ActorRotation);

		UHazeAkComponent::HazePostEventFireForget(KillAngelBabyAudioEvent, this.GetActorTransform());
		
		SkeletalMesh.StopAllSlotAnimations();

		SkeletalMesh.SetCollisionProfileName(n"Ragdoll");
		SkeletalMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		SkeletalMesh.SetSimulatePhysics(true);

		FVector Impulse = -FVector::UpVector * DeathImpulse;
		SkeletalMesh.AddImpulse(Impulse, n"Spine1", true);
		SkeletalMesh.AddAngularImpulseInDegrees(FMath::VRand() * DeathImpulse, n"Spine1", true);
	

		bIsKilled = true;
		bHasBlockedMovement = true;

		CymbalImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		SongReaction.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_PlayerBeginOverlap(AHazePlayerCharacter InPlayer)
	{
		if(InPlayer.HasControl())
			NetPlayImpactAnimation(MovementComponent.CurrentDistanceAlongSpline);
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		if(!HasActorBegunPlay())
		{
			bHasPendingStartMoving = true;
			return;
		}
	
		if(bFollowingSpline || bIsKilled)
			return;

		EnableActor(this, n"NoMovement");
		UHazeSplineComponent Spline = SplineToFollow.Spline;
		const float SplineDistance = Spline.GetDistanceAlongSplineAtWorldLocation(GetActorLocation());
		const FVector SplineDir = Spline.GetDirectionAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
		const FVector SplineLocation = Spline.GetLocationAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
		bIsForwardOnSpline = SplineDir.DotProduct(GetActorForwardVector()) >= 0;
		
		FRotator SplineRotation;
		if(bIsForwardOnSpline)
			SplineRotation = SplineDir.Rotation();
		else
			SplineRotation = (-SplineDir).Rotation();

		StartLocation = SplineLocation;
		StartRotation = SplineRotation;

		SetActorLocationAndRotation(SplineLocation, SplineRotation);
		MovementComponent.ActivateSplineMovement(Spline, bIsForwardOnSpline);
		MovementComponent.CurrentDistanceAlongSpline = SplineDistance;
		MovementComponent.CurrentTransformOnSpline = FTransform(SplineRotation, SplineLocation);
		bFollowingSpline = true;
		PlayFlyAnimation();
	}

	void PlayFlyAnimation()
	{
		if(SkeletalMesh.IsPlayingAnimAsSlotAnimation(MH))
			return;

		FHazePlaySlotAnimationParams AnimSettings;
		AnimSettings.Animation = MH;
		AnimSettings.bLoop = true;
		AnimSettings.BlendTime = 0.2f;
		AnimSettings.StartTime = 0.f;
		AnimSettings.PlayRate = 1.f;
		SkeletalMesh.PlaySlotAnimation(AnimSettings);
	}
	
	UFUNCTION(NetFunction)
	void NetPlayImpactAnimation(float ControlSideDistanceAlongSpline)
	{
		if(bPlayingImpactAnimation || bIsKilled)
			return;

		bPlayingImpactAnimation = true;

		// Make sure the impact happens on the same position
		float MoveAmount = ControlSideDistanceAlongSpline - MovementComponent.CurrentDistanceAlongSpline;
		MovementComponent.ApplySplineMoveAmount(MoveAmount);

		FHazePlaySlotAnimationParams AnimSettings = FHazePlaySlotAnimationParams();
		AnimSettings.Animation = HitReaction;
		AnimSettings.bLoop = false;
		AnimSettings.BlendTime = 0.2f;
		AnimSettings.StartTime = 0.f;
		AnimSettings.PlayRate = 1.f;
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"AnimFinished");
		SkeletalMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, AnimSettings);
	}

	UFUNCTION()
	void AnimFinished()
	{
		FHazePlaySlotAnimationParams AnimSettings = FHazePlaySlotAnimationParams();
		AnimSettings.Animation = MH;
		AnimSettings.bLoop = true;
		AnimSettings.BlendTime = 0.2f;
		AnimSettings.StartTime = 0.f;
		AnimSettings.PlayRate = 1.f;
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		SkeletalMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, AnimSettings);

		System::SetTimer(this, n"ReAllowImpactAnimation", 2.f, false);
	}
	UFUNCTION()
	void ReAllowImpactAnimation()
	{
		bPlayingImpactAnimation = false;
	}
}
