import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Peanuts.Aiming.AutoAimTarget;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Tutorial.AimTutorialCapability;
import Cake.LevelSpecific.Garden.LevelActors.GardenBulb_AnimNotify;
import Vino.ActivationPoint.DummyActivationPoint;

event void FOnDoubleInteractBulbStartedDyingSignature();
event void FOnDoubleInteractBulbFinishedDyingSignature();
event void FOnDoubleInteractBulbTutorialFirstSickleHitSignature();
event void FOnDoubleInteractBulbTutorialFirstWhipConnectSignature();


class AGardenBulbDoubleInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase PodSkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PodMeshCollision;

	UPROPERTY(DefaultComponent, Attach = PodSkeletalMesh, AttachSocket = HatchSocket)
	UBoxComponent HatchImpactTrigger;

	UPROPERTY(DefaultComponent, Attach = PodSkeletalMesh, AttachSocket = HatchSocket)
	UHazeAkComponent HazeAkLeaf;

	UPROPERTY(DefaultComponent, Attach = HatchImpactTrigger)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(DefaultComponent, Attach = VineImpactComp)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent DmgCollider;
	default DmgCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, Attach = DmgCollider)
	USickleCuttableHealthComponent SickleCuttableHealthComp;

	UPROPERTY(DefaultComponent, Attach = PodSkeletalMesh)
	USceneComponent HatchLocationRoot;

	UPROPERTY(DefaultComponent, Attach = HatchLocationRoot)
	USceneComponent HatchRotationRoot;

	UPROPERTY(DefaultComponent, Attach = HatchRotationRoot)
	UStaticMeshComponent HatchMeshWalkableCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HatchMeshClosedCollision;

	UPROPERTY(DefaultComponent, Attach = HatchMeshWalkableCollision)
	UStaticMeshComponent HatchCrushPlayerTrigger;
	default HatchCrushPlayerTrigger.SetRelativeLocation(FVector(0.f, -65.f, -20.f));
	default HatchCrushPlayerTrigger.SetRelativeScale3D(FVector(0.9f, 0.9f, 0.9f));
	default HatchCrushPlayerTrigger.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default HatchCrushPlayerTrigger.GenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent StalkCollider;
	default StalkCollider.HazeSetCapsuleHalfHeight(2200.f);
	default StalkCollider.HazeSetCapsuleRadius(220.f);
	default StalkCollider.SetCollisionProfileName(n"BlockAllDynamic");
	default StalkCollider.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagarCompOnHitEffect;

	UPROPERTY(DefaultComponent, Attach = VineImpactComp)
	UDummyActivationPointBase DummyVinePoint;
	default DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::May);

	UPROPERTY(DefaultComponent, Attach = SickleCuttableHealthComp)
	UDummyActivationPointBase DummySicklePoint;
	default DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);

	//Using HazeLazyOverlap seems to slow as player more often then not doesnt get killed on hatch closing.
	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent KillCollider;
	default KillCollider.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.UseAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UPlayerDeathEffect> KilledByClosingLeafEffect;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineConnectedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VineDisconnectedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CutWithSickleAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HatchClosedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DeathAudioEvent;

	UPROPERTY(Category = "Setup")
	TArray<AHazeNiagaraActor> EnvEffects;

	UPROPERTY()
	FOnDoubleInteractBulbStartedDyingSignature StartedDyingEvent;

	UPROPERTY()
	FOnDoubleInteractBulbFinishedDyingSignature FinishedDyingEvent;

	UPROPERTY()
	FOnDoubleInteractBulbTutorialFirstSickleHitSignature FirstHitEvent;

	UPROPERTY()
	FOnDoubleInteractBulbTutorialFirstWhipConnectSignature FirstWhipEvent;

	UPROPERTY(Category = "Settings")
	FHazeTimeLike HatchOpenTimeLike;

	UPROPERTY(Category = "Settings")
	float TargetPitch = -80.f;

	UPROPERTY(Category = "Settings")
	bool bPlayMusicStingerOnFinishedDying = false;

	UPROPERTY(Category = "Settings", meta = (EditCondition = "bPlayMusicStingerOnFinishedDying"))
	FString StingerTrigger;

	UPROPERTY(Category = "Settings")
	bool bShouldShowTutorial = false;

	UPROPERTY(Category = "Settings")
	bool bIsFountainVariant = false;

	UPROPERTY(Category = "Settings")
	bool bIsVegetablePatchSpecial = false;

	UPROPERTY(Category = "Settings")
	bool bIsNoFlowerStalkVariant = false;

	UPROPERTY(Category = "Settings", meta = (EditCondition = "bShouldShowTutorial"))
	APlayerTrigger TutorialTrigger;

	UPROPERTY(Category = "Settings", meta = (EditCondition = "bShouldShowTutorial"))
	FTutorialPrompt MayTutorialPrompt;

	UPROPERTY(Category = "Settings", meta = (EditCondition = "bShouldShowTutorial"))
	UAimTutorialDataAsset AimTutorialAsset;

	UPROPERTY(Category = "Settings")
	bool bUseDummyVinePoint = false;
	UPROPERTY(Category = "Settings")
	bool bUseDummySicklePoint = false;

	int CurrentHealth = 0;
	float DefaultPitch = 0.f;
	bool IsDying = false;
	bool CodyTutorialShown = false;
	bool bHasTriggeredFirstHitVO = false;
	bool bHasTriggeredFirstWhipVO = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DummyVinePoint.InitializeDistances(VineImpactComp.GetDistance(EHazeActivationPointDistanceType::Visible),
											 VineImpactComp.GetDistance(EHazeActivationPointDistanceType::Targetable),
												 VineImpactComp.GetDistance(EHazeActivationPointDistanceType::Selectable));
		
		DummySicklePoint.InitializeDistances(SickleCuttableHealthComp.GetDistance(EHazeActivationPointDistanceType::Visible),
												 SickleCuttableHealthComp.GetDistance(EHazeActivationPointDistanceType::Targetable),
													 SickleCuttableHealthComp.GetDistance(EHazeActivationPointDistanceType::Selectable));

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VineImpactComp.OnVineConnected.AddUFunction(this, n"OnVineAttached");
		VineImpactComp.OnVineDisconnected.AddUFunction(this, n"OnVineDetached");
		SickleCuttableHealthComp.OnCutWithSickle.AddUFunction(this, n"OnCutWithSickle");
		KillCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnKillColliderOverlap");
		HatchOpenTimeLike.BindUpdate(this, n"OnHatchOpenTimeLikeUpdate");
		HatchOpenTimeLike.BindFinished(this, n"OnHatchOpenTimeLikeFinished");
		HatchCrushPlayerTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnKillColliderOverlap");

		CurrentHealth = SickleCuttableHealthComp.MaxHealth;

		SickleCuttableHealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		HatchMeshClosedCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		HatchMeshWalkableCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DmgCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		DummySicklePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		if(!bUseDummyVinePoint)
			DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		if(HasControl())
		{
			FHazeAnimNotifyDelegate BulbFinishedDyingDelegate;
			BulbFinishedDyingDelegate.BindUFunction(this, n"OnBulbFinishedDying");
			BindAnimNotifyDelegate(UAnimNotify_BulbFinishedDying::StaticClass(), BulbFinishedDyingDelegate);
		}

		FHazeAnimNotifyDelegate BulbDiedDisableCollisionDelegate;
		BulbDiedDisableCollisionDelegate.BindUFunction(this, n"OnBulbDyingDisableCollision");
		BindAnimNotifyDelegate(UAnimNotify_BulbDyingRemoveWalkableCollision::StaticClass(), BulbDiedDisableCollisionDelegate);

		if(bShouldShowTutorial)
		{
			if(TutorialTrigger != nullptr)
				TutorialTrigger.OnPlayerEnter.AddUFunction(this, n"OnTutorialTriggerOverlap");
		}

		if(bIsFountainVariant)
		{
			PodSkeletalMesh.SetAnimBoolParam(n"bIsFountain", bIsFountainVariant);
			StalkCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
		else if(bIsVegetablePatchSpecial)
			PodSkeletalMesh.SetAnimBoolParam(n"bIsVegPatch", bIsVegetablePatchSpecial);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	UFUNCTION()
	void OnVineAttached()
	{
		PodSkeletalMesh.SetAnimBoolParam(n"bIsAttach", true);
		KillCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DmgCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		SickleCuttableHealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);

		if(bUseDummyVinePoint)
			DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		if(bUseDummySicklePoint)
			DummySicklePoint.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);

		HazeAkLeaf.HazePostEvent(VineConnectedAudioEvent);

		HatchMeshClosedCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		HatchMeshWalkableCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		HatchCrushPlayerTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		HatchOpenTimeLike.Play();

		if(bShouldShowTutorial && !IsDying)
		{
			ShowTutorialPrompt(Game::GetMay(), MayTutorialPrompt, this);
		}

		if(bShouldShowTutorial && !bHasTriggeredFirstWhipVO)
		{
			FirstWhipEvent.Broadcast();
			bHasTriggeredFirstWhipVO = true;
		}
	}

	UFUNCTION()
	void OnVineDetached()
	{
		PodSkeletalMesh.SetAnimBoolParam(n"bIsAttach", false);
		DmgCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		HatchCrushPlayerTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		SickleCuttableHealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		if(bUseDummySicklePoint)
			DummySicklePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		if(bUseDummyVinePoint)
			DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::May);

		HazeAkLeaf.HazePostEvent(VineDisconnectedAudioEvent);

		if(!IsDying)
		{
			KillCollider.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
			HatchOpenTimeLike.Reverse();
		}

		if(bShouldShowTutorial && !IsDying)
		{
			RemoveTutorialPromptByInstigator(Game::GetMay(), this);
		}
	}

	UFUNCTION()
	void OnCutWithSickle(int DmgAmount)
	{
		if(IsDying)
			return;

		if(CutWithSickleAudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(CutWithSickleAudioEvent, GetActorTransform());

		if(bShouldShowTutorial && !bHasTriggeredFirstHitVO)
		{
			FirstHitEvent.Broadcast();
			bHasTriggeredFirstHitVO = true;
		}

		CurrentHealth -= DmgAmount;

		if(CurrentHealth >= 1)
		{
			PodSkeletalMesh.SetAnimBoolParam(n"bIsHit", true);
		}
		else if(CurrentHealth < 1 && !IsDying)
		{
			if(DeathAudioEvent != nullptr)
			{
				UHazeAkComponent::HazePostEventFireForget(DeathAudioEvent, GetActorTransform());
			}				

			IsDying = true;

			if(bShouldShowTutorial)
				RemoveTutorialPromptByInstigator(Game::GetMay(), this);

			PodSkeletalMesh.SetAnimBoolParam(n"bIsDead", true);
			DmgCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			//HatchMeshWalkableCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			HatchRotationRoot.SetRelativeRotation(FRotator(-100.f, HatchRotationRoot.RelativeRotation.Yaw, HatchRotationRoot.RelativeRotation.Roll));
			PodMeshCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			HatchMeshClosedCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			StalkCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);

			SickleCuttableHealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			DummyVinePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			DummySicklePoint.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			VineImpactComp.SetCanActivate(false);

			if(TutorialTrigger != nullptr)
			{
				TutorialTrigger.SetTriggerEnabled(false);
				HideAimTutorial(Game::Cody);
			}

			for(auto EffectActor : EnvEffects)
			{
				EffectActor.DisableActor(this);
			}

			if(HasControl())
				OnDeath();
		}

		NiagarCompOnHitEffect.Activate();
	}

	UFUNCTION(NetFunction)
	void OnDeath()
	{
		StartedDyingEvent.Broadcast();
	}

	UFUNCTION()
	void OnKillColliderOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(!IsDying)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

			if(Player != nullptr)
			{
				if(KilledByClosingLeafEffect.IsValid())
					Player.KillPlayer(KilledByClosingLeafEffect);
			}
		}
	}

	UFUNCTION()
	void OnHatchOpenTimeLikeUpdate(float Value)
	{
		float CurrentPitch = FMath::Lerp(DefaultPitch, TargetPitch, Value);
		HatchRotationRoot.SetRelativeRotation(FRotator(CurrentPitch, HatchRotationRoot.RelativeRotation.Yaw, HatchRotationRoot.RelativeRotation.Roll));

		float LeafRotation = FMath::Abs(HatchRotationRoot.RelativeRotation.Pitch);
		HazeAkLeaf.SetRTPCValue("Rtpc_Garden_Shared_Interactable_InfectedBulb_Leaf_Rotation", LeafRotation);
	}

	UFUNCTION()
	void OnHatchOpenTimeLikeFinished()
	{
		if(HatchOpenTimeLike.IsReversed())
		{
			HazeAkLeaf.HazePostEvent(HatchClosedAudioEvent);
			HatchMeshWalkableCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			HatchMeshClosedCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			HatchCrushPlayerTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	UFUNCTION()
	void OnTutorialTriggerOverlap(AHazePlayerCharacter Player)
	{
		if(!CodyTutorialShown && Player.IsCody() && Player.HasControl())
			ShowCodyTutorial(Player);
	}

	UFUNCTION(NetFunction)
	void ShowCodyTutorial(AHazePlayerCharacter Player)
	{
		CodyTutorialShown = true;
		ShowAimTutorial(Player, AimTutorialAsset);
	}

	UFUNCTION()
	void OnBulbDyingDisableCollision(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		HatchMeshWalkableCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void OnBulbFinishedDying(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		NetSendBulbFinishedDying();
	}

	UFUNCTION(NetFunction)
	void NetSendBulbFinishedDying()
	{
		PlayMusicStinger();
		FinishedDyingEvent.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void PlayMusicStinger()
	{

	}
}