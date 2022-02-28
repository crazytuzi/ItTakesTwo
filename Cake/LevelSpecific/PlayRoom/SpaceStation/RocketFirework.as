import Peanuts.Spline.SplineComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

UCLASS(Abstract)
class ARocketFirework : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase RocketRoot;

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	UStaticMeshComponent RocketMesh;

	UPROPERTY(DefaultComponent, Attach = RocketMesh)
	UNiagaraComponent ThrusterComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent PlayerCollision;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 6000.f;

	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RocketActivatedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RocketExplodeAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayAnimation;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyAnimation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ExplosionCamShake;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY()
	UAnimSequence RocketAnimation;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionEffect;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	bool bRocketActive = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
    }

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		if (Player.IsCody())
			ForceCodyMediumSize();

		InteractionComp.Disable(n"Used");

		AnimNotifyDelegate.BindUFunction(this, n"RocketActivated");
        Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
		
		UAnimSequence Animation = Player.IsMay() ? MayAnimation : CodyAnimation;
		Player.PlayEventAnimation(Animation = Animation);

		FVector DirToPlayer = Player.ActorLocation - ActorLocation;
		DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
		DirToPlayer = DirToPlayer.GetSafeNormal();

		Player.SmoothSetLocationAndRotation(ActorLocation + (DirToPlayer * 160.f), DirToPlayer.Rotation() + FRotator(0.f, 180.f, 0.f));

		HazeAkComp = UHazeAkComponent::GetOrCreate(this);

		FName EventName = Player.IsMay() ? n"FoghornDBPlayRoomSpaceStationTriggerRocketMay" : n"FoghornDBPlayRoomSpaceStationTriggerRocketCody";
		VOBank.PlayFoghornVOBankEvent(EventName);
    }

	UFUNCTION(NotBlueprintCallable)
	void RocketActivated(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		SetActorEnableCollision(false);
		bRocketActive = true;
		SetActorTickEnabled(true);
		ThrusterComp.Activate(true);

		FHazePlaySlotAnimationParams Params;
		Params.Animation = RocketAnimation;
		Params.BlendTime = 0.f;

		RocketRoot.PlaySlotAnimation(Params);

		System::SetTimer(this, n"ExplodeRocket", RocketAnimation.PlayLength - 0.25f, false);

		if (RocketActivatedAudioEvent != nullptr)
			HazeAkComp.HazePostEvent(RocketActivatedAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void ExplodeRocket()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ExplosionCamShake, RocketMesh.WorldLocation, 1600.f, 2500.f);

		ForceFeedbackComp.Play();
		bRocketActive = false;
		Niagara::SpawnSystemAtLocation(ExplosionEffect, RocketRoot.WorldLocation);
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);

		if (RocketExplodeAudioEvent != nullptr)
			HazeAkComp.HazePostEvent(RocketExplodeAudioEvent);
	}
}