import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Cake.LevelSpecific.Garden.Greenhouse.BossGooBeamPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent;
import Cake.LevelSpecific.Garden.Greenhouse.BossDestroyableBeamPlant_AnimNotify;
import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Cake.LevelSpecific.Garden.Greenhouse.Audio.GardenBossPurpleSapAudioComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;

event void FOnPlantDestroyed();
event void FOnEnterAnimFinished();

class ABossDestroyableBeamPlant : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UTomatoDashTargetComponent TomatoComponent;
	default TomatoComponent.bValidTarget = false;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UHazeSkeletalMeshComponentBase SkeletalMeshBark;

	UPROPERTY(DefaultComponent)
	USickleCuttableHealthComponent SickleComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	UPROPERTY(DefaultComponent)
	UBillboardComponent NiagaraEnterSpawnLocation;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent LoopingDirtEffect;

	UPROPERTY(DefaultComponent)
	USceneComponent BarkExplosionLocationOne;
	UPROPERTY(DefaultComponent)
	USceneComponent BarkExplosionLocationTwo;
	UPROPERTY(DefaultComponent)
	USceneComponent BarkExplosionLocationThree;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	UPROPERTY(DefaultComponent)
	UHazeAkComponent GooImpactHazeAkComp;

	UPROPERTY()
	FOnPlantDestroyed OnPlantDestroyed;
	UPROPERTY()
	FOnEnterAnimFinished OnEnterAnimFinished;

	UPROPERTY()
	UNiagaraSystem HitReactionEffect;
	UPROPERTY()
	UNiagaraSystem EnterEffect;
	UPROPERTY()
	UNiagaraSystem GooEnterEffect;
	UPROPERTY()
	UNiagaraSystem ExitEffect;

	UPROPERTY()
	UNiagaraSystem BarkExplosionOne;
	UPROPERTY()
	UNiagaraSystem BarkExplosionTwo;
	UPROPERTY()
	UNiagaraSystem BarkExplosionThree;

 	UPROPERTY(EditInstanceOnly)
	APaintablePlane PaintablePlane;

	UPROPERTY(Category = "Goo")
	FLinearColor GooColor = FLinearColor(.0f, 0.f, 1.0f, 0.f);

	UPROPERTY(Category = "Goo")
	float EnterImpactRadius = 800.f;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeSpawn;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackSpawn;

	UPROPERTY()
	ABossGooBeamPlant BossBeamPlant;
	UPROPERTY()
	AJoy Joy;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VOBank;
	
	//UGardenBossPurpleSapAudioComponent SapAudioComp;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapability;

	AActor ActorForBeamToFollow;

	int HitsRequired = 3;
	int TimesHit;
	bool DoOnce = false;

	bool bPlantActive = false;
	bool bDrawIntialPaintablePlane = false;

	FVector FollowTargetLocation;
	FVector ForwardVectorToTarget;
	float DistanceToTarget;
	float HeadTiltOffset;
	UPROPERTY()
	bool bSpawnInitialGooOnSpawn = true;
	float VOReactivateTimerForSickleHit = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlantDestroyed.AddUFunction(this, n"OnThisPlantDestroyed");
		TomatoComponent.OnHitByTomato.AddUFunction(this, n"OnHitByTomatoDash");
		BossBeamPlant.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"UpperJaw"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		BossBeamPlant.AddActorLocalOffset(FVector(0, 0, 15));
		FHazeAnimNotifyDelegate JoySproutEnterFinishedDelegate;
		JoySproutEnterFinishedDelegate.BindUFunction(this, n"EnterAnimFinished");
		BindAnimNotifyDelegate(UAnimNotify_JoySproutEnterFinish::StaticClass(), JoySproutEnterFinishedDelegate);
		SickleComponent.bOwnerForcesDeactivation = true;
		SickleComponent.OnCutWithSickle.AddUFunction(this, n"OnCutWithSickle");

		UClass AudioCapabilityClass = AudioCapability.Get();
		if(AudioCapabilityClass != nullptr)
		{
			AddCapability(AudioCapabilityClass);
		}

		HazeAkComp.AttachTo(Mesh, n"LowerJaw", EAttachLocation::SnapToTarget);

		//SapAudioComp = UGardenBossPurpleSapAudioComponent::Get(Joy);
	}

	UFUNCTION()
	void OnCutWithSickle(int DamageAmount)
	{
		if(Game::GetMay().HasControl())
		{
			if(VOReactivateTimerForSickleHit <= 0)
			{
				PlayVOLineMayHitPlant();
			}
		}
	}
	UFUNCTION(NetFunction)
	void PlayVOLineMayHitPlant()
	{
		FName EventName = n"FoghornDBGardenGreenhouseBossFightGooSpitterSickle";
		PlayFoghornVOBankEvent(VOBank, EventName);
		VOReactivateTimerForSickleHit = 10;
	}


	UFUNCTION()
	void OnHitByTomatoDash()
	{
		PrintToScreen("VFX spawned", 3.f);PrintToScreen("VFX spawned", 3.f);
		Niagara::SpawnSystemAtLocation(HitReactionEffect, GetActorLocation(), GetActorRotation(), bAutoDestroy=true);

		if(!bPlantActive)
			return;

		//PrintToScreen("Hit", 3.f);
		TimesHit += 1;
		if(TimesHit >= 3)
		{
			OnThisPlantDestroyed();
		}
		else
		{
			SetAnimBoolParam(n"TookDamage", true);
			SkeletalMeshBark.SetAnimBoolParam(n"TookDamage", true);
		}

		if(TimesHit == 1)
		{
			SkeletalMeshBark.SetColorParameterValueOnMaterialIndex(1, n"BlendValue", FLinearColor(1,1,1,0));
			Niagara::SpawnSystemAtLocation(BarkExplosionOne, BarkExplosionLocationOne.GetWorldLocation(), BarkExplosionLocationOne.GetWorldRotation(), bAutoDestroy=true);
		}
		if(TimesHit == 2)
		{
			SkeletalMeshBark.SetColorParameterValueOnMaterialIndex(1, n"BlendValue", FLinearColor(1,0,1,0));
			Niagara::SpawnSystemAtLocation(BarkExplosionTwo, BarkExplosionLocationTwo.GetWorldLocation(), BarkExplosionLocationTwo.GetWorldRotation(), bAutoDestroy=true);
		}
		if(TimesHit == 3)
		{
			SkeletalMeshBark.SetColorParameterValueOnMaterialIndex(1, n"BlendValue", FLinearColor(0,0,1,0));
			Niagara::SpawnSystemAtLocation(BarkExplosionThree, BarkExplosionLocationThree.GetWorldLocation(), BarkExplosionLocationThree.GetWorldRotation(), bAutoDestroy=true);
		}
	}

	UFUNCTION()
	void OnThisPlantDestroyed()
	{
		if(DoOnce == false)
		{
			DoOnce = true;
			SickleComponent.bOwnerForcesDeactivation = true;
			bPlantActive = false;
			OnPlantDestroyed.Broadcast();	
			BossBeamPlant.StopGooBeam();
			Niagara::SpawnSystemAtLocation(ExitEffect, GetActorLocation(), GetActorRotation(), bAutoDestroy=true);

			//Hack to make component not targaetable by tomato
			TomatoComponent.bValidTarget = false;
			System::SetTimer(this, n"DisableLoopingDirtEffect", 0.7f, false);	
			System::SetTimer(this, n"DisablePlant", 3.0f, false);
			
			FSapAudioLocation SapLocation = FSapAudioLocation();
			SapLocation.Location = GetActorLocation();
			
			//SapAudioComp.RemoveSapAudioLocation(SapLocation, true);
		}
	}
	UFUNCTION()
	void DisableLoopingDirtEffect()
	{
		LoopingDirtEffect.Deactivate();
	}
	UFUNCTION()
	void DisablePlant()
	{
		DisableActor(nullptr);
	}
	

	UFUNCTION()
	void EnablePlant(AActor FollowActor)
	{
		if(this.HasControl())
		{
			NetEnablePlant(FollowActor);
		}
	}
	UFUNCTION(NetFunction)
	void NetEnablePlant(AActor FollowActor)
	{
		EnableActor(nullptr);
		ActorForBeamToFollow = FollowActor;
		TimesHit = 0;
		LoopingDirtEffect.Activate();
		System::SetTimer(this, n"StartPlant", 1.0, false);	
		System::SetTimer(this, n"EnableTargeting", 2.5, false);	
		System::SetTimer(this, n"StopDrawIntialPaintablePlane", 2.0f, false);	
		FSapAudioLocation SapLocation = FSapAudioLocation();
		SapLocation.Location = GetActorLocation();

		//SapAudioComp.AddSapAudioLocation(SapLocation, true);
	}

	UFUNCTION()
	void StartPlant()
	{
		Niagara::SpawnSystemAtLocation(EnterEffect, GetActorLocation(), GetActorRotation(), bAutoDestroy=true);
		Niagara::SpawnSystemAtLocation(GooEnterEffect, GetActorLocation(), GetActorRotation(), bAutoDestroy=true);
		Game::GetMay().PlayCameraShake(CameraShakeSpawn, 1.f);
		Game::GetCody().PlayCameraShake(CameraShakeSpawn, 1.f);
		Game::GetCody().PlayForceFeedback(ForceFeedbackSpawn, false, false, n"PlantSpawn");
		Game::GetMay().PlayForceFeedback(ForceFeedbackSpawn, false, false, n"PlantSpawn");

		bPlantActive = true;
		DoOnce = false;	

		if(bSpawnInitialGooOnSpawn)
			bDrawIntialPaintablePlane = true;
	}

	UFUNCTION()
	void EnableTargeting()
	{
		SickleComponent.bOwnerForcesDeactivation = false;
		TomatoComponent.bValidTarget = true;
	}
	UFUNCTION()
	void StopDrawIntialPaintablePlane()
	{
		bDrawIntialPaintablePlane = false;
		TomatoComponent.bValidTarget = true;
	}

	UFUNCTION()
	void EnterAnimFinished(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		OnEnterAnimFinished.Broadcast();
		System::SetTimer(this, n"StartGooBeamNiagara", 0.15f, false);	
	}
	UFUNCTION()
	void StartGooBeamNiagara()
	{
		BossBeamPlant.StartGooPattern(ActorForBeamToFollow);
		SetCapabilityActionState(n"AudioStartedGooBeam", EHazeActionState::ActiveForOneFrame);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//PrintToScreen("bPlantActive " + bPlantActive, 0.5f);
		if(bPlantActive == true)
		{

		}
			//PrintToScreen("ImActive");

		if(bDrawIntialPaintablePlane)
		{
			//PaintablePlane.LerpAndDrawTexture(GetActorLocation(), EnterImpactRadius, GooColor, FLinearColor(4.0f, 0.f, 0.f, 0.f) * DeltaTime, true, nullptr, true, FLinearColor(0.2f,0.2f,0.2f));
		//	if(EnterImpactRadius < 1500)
		//		EnterImpactRadius += DeltaTime * 150;
			//PrintToScreen("EnterImpactRadius " + EnterImpactRadius);
			PaintablePlane.LerpAndDrawTexture(GetActorLocation(), EnterImpactRadius, GooColor,  FLinearColor(0.f, 0.f, 25.0f, 0.f) * DeltaTime, true, nullptr, true, FLinearColor(1.45f,1.45f,1.45f));
		}

		if(!bPlantActive)
			return;

		if(VOReactivateTimerForSickleHit > 0)
			VOReactivateTimerForSickleHit -= DeltaTime;

		FollowTargetLocation = ActorForBeamToFollow.GetActorLocation();
		DistanceToTarget = (GetActorLocation() - FollowTargetLocation).Size();

		ForwardVectorToTarget = (GetActorLocation() - FollowTargetLocation);
		ForwardVectorToTarget.Normalize();
		HeadTiltOffset = 1;//DistanceToTarget/3500;

		//Print("HeadTiltOffset   " + HeadTiltOffset);
		//Print("ForwardVectorToTarget   " + ForwardVectorToTarget);
		//Print("DistanceToTarget  " + DistanceToTarget);
		//System::DrawDebugSphere(FollowTargetLocation, 100.f, LineColor = FLinearColor::DPink);  
	}
}

