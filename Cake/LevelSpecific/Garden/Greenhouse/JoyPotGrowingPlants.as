import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenGroundVines;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotBaseActor;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotGrowingPlants_AnimNotify;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotGrowingPlantsImpactFall_AnimNotify;

class AJoyPotGrowingPlants : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent DirtEffectComp;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent DirtEffectCompExit;

	UPROPERTY()
	ULocomotionFeatureGardenGroundVines GardenGroundVinesFeature;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;


	UPROPERTY()
	AJoyPotBaseActor PotBase;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent FallingPlate;

	UPROPERTY()
	bool bPlateFallDown = false;
	UPROPERTY()
	bool bRisePlateFromGround = false;
	UPROPERTY()
	bool bExit = false;
	UPROPERTY()
	bool bPlateDestroyed = false;

	UPROPERTY()
	bool DevPrint = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeAnimNotifyDelegate JoyPotGrowingPlantsFallingDownCompleteDelegate;
		JoyPotGrowingPlantsFallingDownCompleteDelegate.BindUFunction(this, n"DisableDeathVolumePotBase");
		BindAnimNotifyDelegate(UAnimNotify_JoyPotGrowingPlants::StaticClass(), JoyPotGrowingPlantsFallingDownCompleteDelegate);

		FHazeAnimNotifyDelegate JoyPotGrowingPlantsImpactFallDelegate;
		JoyPotGrowingPlantsImpactFallDelegate.BindUFunction(this, n"PlayCameraShake");
		BindAnimNotifyDelegate(UAnimNotify_JoyPotGrowingPlantsImpactFall::StaticClass(), JoyPotGrowingPlantsImpactFallDelegate);
		PotBase.OnPlateDestroyed.AddUFunction(this, n"OnPlateDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!DevPrint)
			return;
	}

	UFUNCTION()
	void StartFallingDownAnimation()
	{	
		if(this.HasControl())
		{
			NetStartFallingDownAnimation();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartFallingDownAnimation()
	{	
		PotBase.AttachToComponent(SkeletalMeshComponent, SkeletalMeshComponent.GetSocketBoneName(n"PotLid"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		//PotBase.AddActorLocalOffset(FVector(0, 0, 50));
		PotBase.SetDeathVolume(true);
		System::SetTimer(this, n"ForRealStartFallingDown", 2.f, false);
		HazeAkComp.HazePostEvent(FallingPlate);
	}

	UFUNCTION()
	void SkipBeginning()
	{
		PotBase.AttachToComponent(SkeletalMeshComponent, SkeletalMeshComponent.GetSocketBoneName(n"PotLid"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		SetAnimBoolParam(n"SkipBeginning", true);
	}

	UFUNCTION()
	void ForRealStartFallingDown()
	{
		bPlateFallDown = true;
	}

	UFUNCTION()
	void StartRiseAnimation()
	{	
		if(this.HasControl())
		{
			NetStartRiseAnimation();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartRiseAnimation()
	{	
		DirtEffectComp.Activate();
		System::SetTimer(this, n"StopDirtEffect", 3.f, true);
		bRisePlateFromGround = true;
	}
	UFUNCTION()
	void StopDirtEffect()
	{
		DirtEffectComp.Deactivate();
		//DirtEffectComp.SetVisibility(false);
	}

	UFUNCTION()
	void StartExitAnimation()
	{	
		if(this.HasControl())
		{
			NetStartExitAnimation();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartExitAnimation()
	{	
		bExit = true;
		DirtEffectCompExit.Activate();
		System::SetTimer(this, n"StopDirtEffectExit", 1.5f, false);
		System::SetTimer(this, n"DestroyPlantActor", 5.0f, false);
	}
	UFUNCTION()
	void StopDirtEffectExit()
	{
		DirtEffectCompExit.Deactivate();
		//DirtEffectComp.SetVisibility(false);
	}


	UFUNCTION()
	void DestroyPlantActor()
	{
		DestroyActor();
	}
	UFUNCTION()
	void DisableDeathVolumePotBase(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		PotBase.SetDeathVolume(false);
	}

	UFUNCTION()
	void PlayCameraShake(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		Game::GetMay().PlayCameraShake(CameraShake, 1.f);
		Game::GetCody().PlayCameraShake(CameraShake, 1.f);
		Game::GetCody().PlayForceFeedback(ForceFeedback, false, false, n"HammerHit");
		Game::GetMay().PlayForceFeedback(ForceFeedback, false, false, n"HammerHit");
	}

	UFUNCTION()
	void PlayImpactAnimation()
	{
		SetAnimBoolParam(n"TookDamage", true);
	}
	UFUNCTION()
	void OnPlateDestroyed()
	{
		bPlateDestroyed = true;
	}
}

